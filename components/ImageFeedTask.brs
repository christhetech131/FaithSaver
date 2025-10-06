' [FaithSaver] ImageFeedTask.brs
' Produces a list of URIs to rotate through. Uses local pkg:/ images.

sub init()
    m.top.functionName = "runTask"
end sub

sub runTask()
    cat = m.top.category
    if cat = invalid or cat = "" then cat = "animals"

    items = getLocalItems(cat)
    if items.count() = 0 then
        ' absolute fallback to default
        items.push("pkg:/images/offline/default.jpg")
    end if

    m.top.items  = items
    m.top.status = "ok"
end sub

function getLocalItems(cat as string) as object
    arr = []
    fs = CreateObject("roFileSystem")
    if fs = invalid then return arr

    ' Preferred folder structure
    base = "pkg:/images/offline/" + cat
    if fs.Exists(base) then
        list = fs.GetDirectoryListing(base)
        if list <> invalid then
            ' collect jpgs, simple sort for stability
            jpgs = []
            for each f in list
                if LCase(right(f,4)) = ".jpg" then jpgs.push(f)
            end for
            jpgs.Sort()
            for each f in jpgs
                arr.push(base + "/" + f)
            end for
        end if
    else
        ' Legacy single file fallback
        legacy = "pkg:/images/offline/" + cat + ".jpg"
        if fs.Exists(legacy) then
            arr.push(legacy)
        end if
    end if

    return arr
end function

' Future-friendly HTTP fetcher (not used when offline)
function httpGet(url as string, timeoutSeconds = 10 as integer) as object
    xfer = CreateObject("roUrlTransfer")
    if xfer = invalid then
        print "[EP] roUrlTransfer invalid"
        return invalid
    end if
    xfer.SetUrl(url)
    xfer.SetCertificatesFile("common:/certs/ca-bundle.crt")
    xfer.InitClientCertificates()

    rsp = xfer.GetToString()
    return rsp
end function
