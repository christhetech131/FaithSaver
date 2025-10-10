' *********** FaithSaver — ImageFeedTask.brs ***********

sub FSLogFeed(msg as string)
    print "[FaithSaver][Feed] "; "" + msg
end sub

function S(v as dynamic) as string
    if v = invalid then return ""
    return "" + v
end function

sub init()
    m.top.functionName = "runTask"
    FSLogFeed("init: functionName=runTask set")
    m.cache = {} ' per-session cache: { "category" : [array of URIs] }
end sub

sub runTask()
    FSLogFeed("runTask: start")
    safeSetStatus("starting")

    cat = ""
    if m.top.getFields() <> invalid and m.top.getFields().DoesExist("category") then
        cat = LCase("" + m.top.category)
    end if
    FSLogFeed("category=" + S(cat))

    items = []
    if cat = "preview-all-offline" then
        items = buildAllOffline()
    else
        items = buildOfflinePreface(cat)
        ' try online enrichment
        online = fetchGithubList(cat)
        if Type(online) = "roArray" and online.Count() > 0 then
            ' shuffle once per session and append after the first offline
            shuffleArray(online)
            for each u in online
                items.push(u)
            end for
        end if
    end if

    FSLogFeed("final items count=" + S(items.Count()))
    m.top.items = items
    safeSetStatus("done")
    FSLogFeed("runTask: end")
end sub

' ===== Offline builders =====

function buildAllOffline() as object
    base = "pkg:/images/offline/"
    files = [
        "animals.jpg","fall.jpg","geology.jpg","scenery.jpg","space.jpg",
        "spring.jpg","summer.jpg","textures.jpg","winter.jpg","default.jpg"
    ]
    arr = []
    for each f in files
        arr.push(base + f)
    end for
    FSLogFeed("buildAllOffline: count=" + S(arr.Count()))
    return arr
end function

function buildOfflinePreface(cat as string) as object
    base = "pkg:/images/offline/"
    files = [
        "animals.jpg","fall.jpg","geology.jpg","scenery.jpg","space.jpg",
        "spring.jpg","summer.jpg","textures.jpg","winter.jpg","default.jpg"
    ]
    arr = []
    if cat <> invalid and cat <> "" then
        want = cat + ".jpg"
        for each f in files
            if LCase(f) = want then
                arr.push(base + f)
            end if
        end for
    end if
    ' add the rest (no duplicates)
    for each f in files
        uri = base + f
        if arr.Lookup(uri) = invalid then arr.push(uri)
    end for
    FSLogFeed("buildOfflinePreface: count=" + S(arr.Count()))
    return arr
end function

' ===== GitHub fetch =====

function fetchGithubList(cat as string) as dynamic
    if cat = invalid or cat = "" then return invalid
    if cat = "default" then return invalid

    if m.cache.DoesExist(cat) then
        FSLogFeed("fetchGithubList: cache hit for " + cat)
        return m.cache[cat]
    end if

    ' Map category to folder (same names per your repo)
    folder = cat
    url = "https://api.github.com/repos/christhetech131/FaithSaver/contents/" + folder
    FSLogFeed("fetchGithubList: " + url)

    rsp = httpGet(url, 6)
    j = tryParseJson(rsp)
    if Type(j) <> "roArray" then
        FSLogFeed("fetchGithubList: not an array (fallback to offline only)")
        return invalid
    end if

    arr = []
    for each it in j
        if Type(it) = "roAssociativeArray" then
            name = LCase(S(it.name))
            t    = LCase(S(it.type))
            if t = "file" and Right(name, 4) = ".jpg" and name <> ".gitkeep" then
                ' Convert to raw URL
                raw = "https://raw.githubusercontent.com/christhetech131/FaithSaver/HEAD/" + folder + "/" + it.name
                arr.push(raw)
            end if
        end if
    end for

    FSLogFeed("fetchGithubList: jpg count=" + S(arr.Count()))
    m.cache[cat] = arr
    return arr
end function

' ===== Utils =====

sub shuffleArray(a as object)
    ' Fisher–Yates
    n = a.Count()
    for i = n - 1 to 1 step -1
        j = Rnd(i + 1) - 1 ' Rnd(upper) returns 1..upper
        tmp = a[i]
        a[i] = a[j]
        a[j] = tmp
    end for
end sub

sub safeSetStatus(s as dynamic)
    m.top.status = s
    FSLogFeed("status=" + S(s))
end sub

function httpGet(url as string, timeoutSeconds as integer) as dynamic
    xfer = CreateObject("roUrlTransfer")
    if xfer = invalid then
        FSLogFeed("httpGet: roUrlTransfer invalid")
        return invalid
    end if
    xfer.SetUrl(url)
    xfer.SetCertificatesFile("common:/certs/ca-bundle.crt")
    xfer.AddHeader("User-Agent", "FaithSaver/1.0")
    if GetInterface(xfer, "ifUrlTransfer") <> invalid then
        xfer.SetRequestTimeout(timeoutSeconds * 1000)
    end if
    rsp = xfer.GetToString()
    if rsp = invalid then
        FSLogFeed("httpGet: invalid response")
    else
        FSLogFeed("httpGet: bytes=" + S(Len(rsp)))
    end if
    return rsp
end function

function tryParseJson(s as dynamic) as dynamic
    if s = invalid or Len(s) = 0 then return invalid
    parser = CreateObject("roJSONParser")
    if parser = invalid then return invalid
    return parser.Parse(s)
end function
