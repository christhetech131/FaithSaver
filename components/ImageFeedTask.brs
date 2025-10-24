' ImageFeedTask.brs — GitHub folder listing → shuffled image URLs (portable API set)

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
function BuildListUrl(cat as string) as string
    owner = RepoOwner()
    repo  = RepoName()
    ref   = RepoBranch()
    c = LCase(FSStr(cat))
    if c = "" then c = "seasonal"
    ' https://api.github.com/repos/:owner/:repo/contents/:path?ref=:branch
    return "https://api.github.com/repos/" + owner + "/" + repo + "/contents/" + c + "?ref=" + ref
end function

function BuildRawUrl(pathInRepo as string) as string
    p = pathInRepo
    if Left(p, 1) = "/" then p = Mid(p, 2)
    return "https://raw.githubusercontent.com/" + RepoOwner() + "/" + RepoName() + "/" + RepoBranch() + "/" + p
end function

' ====== Shuffle (no Randomize; use current RNG state) ======
sub ShuffleArray(a as object)
    if a = invalid then return
    n = a.count()
    if n <= 1 then return

    ' Lightly stir the RNG without Randomize:
    ' burn a few values based on current time to reduce repeatability across runs
    burn = CreateObject("roTimespan").TotalMilliseconds() mod 17
    k = 0
    while k < burn
        ignore = Rnd(1)
        k = k + 1
    end while

    i = n - 1
    while i > 0
        r = Rnd(i) ' returns 0..i
        if r > i then r = i
        t = a[i] : a[i] = a[r] : a[r] = t
        i = i - 1
    end while
end sub

' ====== Parse GitHub Contents API JSON → URLs (ParseJson only) ======
function ParseGitHubContents(jsonStr as string) as object
    urls = CreateObject("roArray", 0, true)
    if jsonStr = invalid or jsonStr = "" then return urls

    data = ParseJson(jsonStr)

    if type(data) = "roArray"
        i = 0
        while i < data.count()
            e = data[i]
            if type(e) = "roAssociativeArray"
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

' ====== HTTP (portable) ======
' Returns body string or invalid on failure.
function HttpGetBody(url as string) as dynamic
    x = CreateObject("roUrlTransfer")
    if x = invalid then
        SetStatus("ERROR: roUrlTransfer invalid")
        return invalid
    end if
    x.setUrl(url)
    x.setCertificatesFile("common:/certs/ca-bundle.crt")
    x.initClientCertificates()
    x.AddHeader("User-Agent", "FaithSaver/1.0 (+roku)")
    x.AddHeader("Accept", "application/vnd.github+json")

    body = x.GetToString()
    if body = invalid then
        SetStatus("ERROR: empty/invalid body")
        return invalid
    end if
    SetStatus("HTTP ok, bodyLen=" + StrI(Len(body)))
    return body
end function

' ====== Task entry ======
sub Run()
    cat = LCase(FSStr(m.top.category))
    if cat = "" then cat = "seasonal"

    url = BuildListUrl(cat)
    SetStatus("init: category=" + cat + " listUrl=" + url)

    body = HttpGetBody(url)
    if body = invalid then
        m.top.items = []
        return
    end if

    urls = ParseGitHubContents(body)
    SetStatus("parsed " + StrI(urls.count()) + " file(s) from listing")
    if urls.count() = 0 then
        SetStatus("no images found in /" + cat + " on GitHub")
        m.top.items = []
        return
    end if

    ShuffleArray(urls)

    maxN = MaxItems()
    if urls.count() > maxN then
        while urls.count() > maxN
            urls.pop()
        end while
        SetStatus("clamped to " + StrI(maxN) + " items")
    end if

    ' keep only plausible URIs
    filtered = CreateObject("roArray", 0, true)
    i = 0
    while i < urls.count()
        u = FSStr(urls[i])
        if u <> "" and (Left(u, 5) = "http:" or Left(u, 6) = "https:" or Left(u, 5) = "pkg:/") then
            filtered.push(u)
        end if
        i = i + 1
    end while

    SetStatus("ok: " + StrI(filtered.count()) + " images, shuffled")
    m.top.items = filtered
end sub
