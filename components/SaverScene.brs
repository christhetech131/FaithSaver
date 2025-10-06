' [FaithSaver] SaverScene.brs

sub init()
    m.bg      = m.top.findNode("bg")
    m.overlay = m.top.findNode("overlay")
    m.cycler  = m.top.findNode("cycler")
    m.feed    = m.top.findNode("feed")

    ' Normalize mode
    mode = LCase(m.top.mode)
    if mode = "screensaver" then mode = "saver"
    if mode <> "saver" and mode <> "preview" then mode = "preview"
    m.top.mode = mode

    ' Read category (fallback to registry in case field is empty)
    cat = m.top.category
    if cat = invalid or cat = "" then
        cat = getSavedCategory()
        m.top.category = cat
    end if

    ' Show overlay only in preview
    m.overlay.visible = (mode = "preview")

    ' Immediately show first offline image (no grey flash)
    showImmediateOffline(cat)

    ' Kick off feed task
    m.feed.category = cat
    m.feed.ObserveField("items", "onFeedItems")
    m.feed.control = "run"

    ' Start cycling
    m.idx = 0
    m.items = [] ' will be populated by task
    m.cycler.ObserveField("fire", "onTick")
    m.cycler.control = "start"

    ' Close behavior
    m.top.observeField("keyEvent", "onKey")
end sub

function getSavedCategory() as string
    defaultCat = "animals"
    sec = CreateObject("roRegistrySection", "FaithSaver")
    if sec = invalid then return defaultCat
    if sec.DoesExist("category") then
        cat = sec.Read("category")
        if cat <> invalid and cat <> "" then return cat
    end if
    return defaultCat
end function

sub showImmediateOffline(cat as string)
    uri = getFirstOffline(cat)
    if uri <> "" then
        m.bg.uri = uri
    else
        ' Absolute fallback
        m.bg.uri = "pkg:/images/offline/default.jpg"
    end if
end sub

function getFirstOffline(cat as string) as string
    fs = CreateObject("roFileSystem")
    if fs <> invalid then
        ' Preferred structure: pkg:/images/offline/<category>/
        p = "pkg:/images/offline/" + cat
        if fs.Exists(p) then
            list = fs.GetDirectoryListing(p)
            if list <> invalid and list.Count() > 0 then
                ' pick first *.jpg
                for each f in list
                    if LCase(right(f,4)) = ".jpg" then
                        return p + "/" + f
                    end if
                end for
            end if
        end if
        ' Legacy single file fallback: pkg:/images/offline/<category>.jpg
        legacy = "pkg:/images/offline/" + cat + ".jpg"
        if fs.Exists(legacy) then return legacy
    end if
    return ""
end function

sub onFeedItems()
    it = m.feed.items
    if it = invalid or it.Count() = 0 then
        ' keep showing the offline image
        return
    end if
    m.items = it
    m.idx = 0
    m.bg.uri = m.items[m.idx]
end sub

sub onTick()
    if m.items = invalid or m.items.Count() = 0 then return
    m.idx = (m.idx + 1) mod m.items.Count()
    m.bg.uri = m.items[m.idx]
end sub

function onKey(e as Object) as boolean
    if m.top.mode = "saver" then
        ' Close on ANY key
        m.top.close = true
        return true
    else
        ' Preview: Back/Up/Down close as requested
        if e.key = "back" or e.key = "up" or e.key = "down" then
            m.top.close = true
            return true
        end if
    end if
    return false
end function
