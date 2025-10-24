' ImageFeedTask.brs — Pull image list from GitHub /<category> at repo root,
' shuffle locally, expose as items. Uses optional ETag to reduce bandwidth.

' ====== Helpers ======
function FSStr(v as dynamic) as string
    if v = invalid then return ""
    t = type(v)
    if t = "roString" or t = "String" then return v
    if t = "Boolean" then return (v and "true" or "false")
    if t = "Integer" or t = "LongInteger" then return StrI(v)
    if t = "Float" or t = "Double" then return Str(v)
    return ""
end function

sub SetStatus(msg as string)
    m.top.status = msg
    print "[FaithSaver][Feed] " ; msg
end sub

' ====== CONFIG: your public repo/branch ======
function RepoOwner()  as string : return "christhetech131" : end function
function RepoName()   as string : return "FaithSaver" : end function
function RepoBranch() as string : return "main" : end function

' Optional clamp to keep rotation reasonable on huge folders
function MaxItems() as integer : return 200 : end function

' ====== GitHub API URL builders ======
' List contents of /<category> at repo root
function BuildListUrl(cat as string) as string
    owner = RepoOwner()
    repo  = RepoName()
    ref   = RepoBranch()
    c = LCase(FSStr(cat))
    if c = "" then c = "seasonal"
    ' https://api.github.com/repos/:owner/:repo/contents/:path?ref=:branch
    return "https://api.github.com/repos/" + owner + "/" + repo + "/contents/" + c + "?ref=" + ref
end function

' Fallback raw URL if download_url missing (rare)
function BuildRawUrl(pathInRepo as string) as string
    p = pathInRepo
    if Left(p, 1) = "/" then p = Mid(p, 2)
    return "https://raw.githubusercontent.com/" + RepoOwner() + "/" + RepoName() + "/" + RepoBranch() + "/" + p
end function

' ====== Shuffle ======
' Fisher–Yates in-place shuffle
sub ShuffleArray(a as object)
    if a = invalid then return
    n = a.count()
    if n <= 1 then return
    ' Seed the RNG once per run; BrightScript’s Rnd uses prior state.
    seed = CreateObject("roTimespan").TotalMilliseconds()
    Randomize(seed)
    i = n - 1
    while i > 0
        ' Rnd(i) returns 0..i
        r = Rnd(i)
        if r > i then r = i
        t = a[i]
        a[i] = a[r]
        a[r] = t
        i = i - 1
    end while
end sub

' ====== Parse GitHub Contents API JSON → URLs ======
function ParseGitHubContents(jsonStr as string) as object
    urls = CreateObject("roArray", 0, true)
    if jsonStr = invalid or jsonStr = "" then return urls

    parser = CreateObject("roJSONParser")
    data = invalid
    if parser <> invalid then
        data = parser.parse(jsonStr)
    else
        data = ParseJson(jsonStr)
    end if

    if type(data) = "roArray"
        i = 0
        while i < data.count()
            e = data[i]
            if type(e) = "roAssociativeArray"
                ' Only files; skip subfolders
                name = LCase(FSStr(e.lookup("name")))
                if Right(name, 4) = ".jpg" or Right(name, 5) = ".jpeg" or Right(name, 4) = ".png"
                    du = FSStr(e.lookup("download_url"))
                    if du <> "" then
                        urls.push(du)
                    else
                        path = FSStr(e.lookup("path"))
                        if path <> "" then urls.push(BuildRawUrl(path))
                    end if
                end if
            end if
            i = i + 1
        end while
    else if type(data) = "roAssociativeArray"
        msg = FSStr(data.lookup("message"))
        if msg <> "" then SetStatus("GitHub API error: " + msg)
    end if

    return urls
end function

' ====== HTTP with optional ETag ======
' Returns { code: int, body: string|invalid, etag: string|"" }
function HttpGetWithETag(url as string, priorETag as string) as object
    x = CreateObject("roUrlTransfer")
    if x = invalid then return { code: -1, body: invalid, etag: "" }
    x.setUrl(url)
    x.setCertificatesFile("common:/certs/ca-bundle.crt")
    x.initClientCertificates()
    ' GitHub requires a UA; Accept recommended
    x.SetUserAgent("FaithSaver/1.0 (+roku)")
    x.AddHeader("Accept", "application/vnd.github+json")
    if priorETag <> "" then x.AddHeader("If-None-Match", priorETag)

    mp = CreateObject("roMessagePort")
    x.setPort(mp)

    body = x.GetToString()
    code = -1
    etag = ""

    if x.Lookup("GetResponseCode") <> invalid then
        code = x.GetResponseCode()
    end if

    ' Headers may or may not be accessible; try both methods
    headers = invalid
    if x.Lookup("GetResponseHeaders") <> invalid then
        headers = x.GetResponseHeaders()
        if type(headers) = "roAssociativeArray" then
            ' Dropbox/GitHub usually send ETag; header keys may vary in case
            if headers.doesexist("ETag") then etag = FSStr(headers.ETag)
            if etag = "" and headers.doesexist("etag") then etag = FSStr(headers.etag)
        end if
    end if

    return { code: code, body: body, etag: etag }
end function

' ====== Registry helpers for per-category ETag ======
function ReadCategoryETag(cat as string) as string
    sec = CreateObject("roRegistrySection", "FaithSaver")
    if sec = invalid then return ""
    key = "etag_" + LCase(FSStr(cat))
    val = sec.Read(key)
    if val = invalid then return ""
    return FSStr(val)
end function

sub WriteCategoryETag(cat as string, etag as string)
    if etag = invalid or etag = "" then return
    sec = CreateObject("roRegistrySection", "FaithSaver")
    if sec = invalid then return
    key = "etag_" + LCase(FSStr(cat))
    sec.Write(key, etag)
    sec.Flush()
end sub

' ====== Task entry ======
sub Run()
    cat = LCase(FSStr(m.top.category))
    if cat = "" then cat = "seasonal"

    url = BuildListUrl(cat)
    SetStatus("init: category=" + cat + " listUrl=" + url)

    ' Strategy:
    ' 1) If we ALREADY have items in memory from this process AND we have an ETag,
    '    do a conditional GET. On 304, reuse current items (zero bytes).
    ' 2) Otherwise, do a normal GET (we need the listing once per launch anyway).

    priorItemsCount = 0
    if m.top.items <> invalid then priorItemsCount = m.top.items.count()

    priorETag = ReadCategoryETag(cat)
    rsp = invalid

    if priorETag <> "" and priorItemsCount > 0 then
        rsp = HttpGetWithETag(url, priorETag)
        if rsp.code = 304 then
            SetStatus("304 Not Modified; reusing " + StrI(priorItemsCount) + " cached URLs")
            return
        end if
    end if

    ' If we didn’t try conditional, or conditional wasn’t usable, do a normal GET
    if rsp = invalid or rsp.code = -1 or rsp.body = invalid then
        rsp = HttpGetWithETag(url, "")
    end if

    if rsp.body = invalid or rsp.code < 200 or rsp.code >= 300 then
        SetStatus("ERROR: HTTP " + StrI(rsp.code) + " fetching list")
        m.top.items = []
        return
    end if

    urls = ParseGitHubContents(rsp.body)
    if urls.count() = 0 then
        SetStatus("no images found in /" + cat + " on GitHub")
        m.top.items = []
        return
    end if

    ShuffleArray(urls)

    ' Optional clamp
    maxN = MaxItems()
    if urls.count() > maxN then
        ' Trim without re-shuffling; we already randomized order
        while urls.count() > maxN
            urls.pop()
        end while
    end if

    SetStatus("ok: " + StrI(urls.count()) + " images, shuffled")
    m.top.items = urls

    ' Persist new ETag if provided
    if rsp.etag <> "" then WriteCategoryETag(cat, rsp.etag)
end sub
