' [FaithSaver] SaverScene.brs
' Roku SDK 10+ — exit on ANY key, no render-thread FS calls, defensive guards

sub init()
    m.bg      = m.top.findNode("bg")
    m.overlay = m.top.findNode("overlay")
    m.cycler  = m.top.findNode("cycler")
    m.feed    = m.top.findNode("feed")

    if m.bg = invalid or m.overlay = invalid or m.cycler = invalid or m.feed = invalid then
        print "[FaithSaver] SaverScene nodes missing; aborting init."
        return
    end if

    ' Normalize mode
    mode = LCase(m.top.mode)
    if mode = "screensaver" then mode = "saver"
    if mode <> "saver" and mode <> "preview" then mode = "preview"
    m.top.mode = mode

    ' Category (fallback to registry)
    cat = m.top.category
    if cat = invalid or cat = "" then
        cat = getSavedCategory()
        m.top.category = cat
    end if

    ' Overlay only in preview
    m.overlay.visible = (mode = "preview")

    ' Immediate first frame (no filesystem calls on render thread)
    showImmediateOffline(cat)

    ' Feed task (off render thread)
    m.feed.category = cat
    m.feed.ObserveField("items", "onFeedItems")
    m.feed.control = "run"

    ' Cycle
    m.idx = 0
    m.items = []
    m.cycler.ObserveField("fire", "onTick")
    m.cycler.control = "start"

    ' Ensure the Scene actually receives key events
    m.top.setFocus(true)
end sub

function getSavedCategory() as string
    defaultCat = "animals"
    sec = CreateObject("roRegistrySection", "FaithSaver")
    if sec = invalid then return defaultCat
    if sec.Exists("category") then
        cat = sec.Read("category")
        if cat <> invalid and cat <> "" then return cat
    end if
    return defaultCat
end function

sub showImmediateOffline(cat as string)
    ' Try canonical locations without touching filesystem APIs on the render thread
    p1 = "pkg:/images/offline/" + cat + "/001.jpg"
    p2 = "pkg:/images/offline/" + cat + ".jpg"
    p3 = "pkg:/images/offline/default.jpg"

    ' Poster silently ignores missing URIs; build script aims to ensure animals/001.jpg exists
    if cat <> "" then
        m.bg.uri = p1
        if m.bg.uri <> p1 then m.bg.uri = p2
    end if
    if m.bg.uri <> p1 and m.bg.uri <> p2 then m.bg.uri = p3
end sub

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

' Close on ANY key in both saver and preview modes
function onKeyEvent(key as string, press as boolean) as boolean
    if press and key <> "" then
        m.top.close = true
        return true
    end if
    return false
end function
