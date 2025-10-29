' *********** FaithSaver — SaverScene.brs (production only; preview removed) ***********

sub FSLogSaver(msg as string)
    print "[FaithSaver][Saver] "; ToStr(msg)
end sub

function ToStr(v as dynamic) as string
    if v = invalid then return ""
    t = type(v)
    if t = "Boolean" then
        if v then return "true" else return "false"
    else if t = "roString" or t = "String" then
        return v
    else if t = "Integer" or t = "LongInteger" then
        return StrI(v)
    else if t = "Float" or t = "Double" then
        return Str(v)
    else if t = "roArray" then
        return "Array(" + StrI(v.count()) + ")"
    else if t = "roAssociativeArray" then
        return "AA(" + StrI(v.count()) + ")"
    else
        return "<" + t + ">"
    end if
end function

sub init()
    FSLogSaver("init()")

    m.bgA    = m.top.findNode("bgA")
    m.bgB    = m.top.findNode("bgB")
    m.cycler = m.top.findNode("cycler")
    m.feed   = m.top.findNode("feed")

    m.activeIsA = true
    m.index = 0
    m.items = CreateObject("roArray", 0, true)

    ' read category from registry with guard; default "animals"
    m.category = "animals"
    sec = CreateObject("roRegistrySection", "FaithSaver")
    if sec <> invalid then
        val = sec.Read("category")
        if val <> invalid and val <> "" then m.category = LCase(val)
    end if
    FSLogSaver("Registry category=" + m.category)

    ' Wire feed
    if m.feed <> invalid then
        m.feed.category = m.category
        m.feed.ObserveField("items", "onFeedItems")
        m.feed.control = "run"
        FSLogSaver("ImageFeedTask started")
    else
        FSLogSaver("ERROR: feed task node not found")
    end if

    ' Wire cycler
    if m.cycler <> invalid then
        m.cycler.ObserveField("fire", "onCycle")
    end if

    ' Show initial offline frame (fallback)
    ShowFirstFrameForCategory(m.category)
end sub

' Show initial offline frame for a chosen category (e.g., animals → animals.jpg)
sub ShowFirstFrameForCategory(cat as string)
    localMap = {
        "animals":  "pkg:/images/offline/animals.jpg",
        "fall":     "pkg:/images/offline/fall.jpg",
        "geology":  "pkg:/images/offline/geology.jpg",
        "scenery":  "pkg:/images/offline/scenery.jpg",
        "seasonal": "pkg:/images/offline/default.jpg",
        "space":    "pkg:/images/offline/space.jpg",
        "spring":   "pkg:/images/offline/spring.jpg",
        "summer":   "pkg:/images/offline/summer.jpg",
        "textures": "pkg:/images/offline/textures.jpg",
        "winter":   "pkg:/images/offline/winter.jpg",
        "default":  "pkg:/images/offline/default.jpg"
    }

    key = LCase(cat)
    uri = localMap[key]
    if uri = invalid then uri = localMap["default"]

    ShowImage(uri)
end sub

' Handle ImageFeedTask completion
sub onFeedItems(evt as Object)
    if evt = invalid then return
    arr = evt.GetData()
    if type(arr) <> "roArray" or arr.count() = 0 then
        FSLogSaver("Feed returned empty; staying on offline frame")
        return
    end if
    m.items = arr
    FSLogSaver("Feed items=" + ToStr(m.items))
    if m.cycler <> invalid then
        m.index = 0
        ShowImage(m.items[m.index])
        m.cycler.control = "start"
        FSLogSaver("Cycler started")
    end if
end sub

' Timer: rotate images (online list if available)
sub onCycle()
    if m.items <> invalid and m.items.count() > 0 then
        m.index = (m.index + 1) mod m.items.count()
        ShowImage(m.items[m.index])
    end if
end sub

' Swap double-buffered background with a quick visible flip
sub ShowImage(uri as string)
    if uri = invalid or uri = "" then return
    target = invalid
    if m.activeIsA then
        target = m.bgB
    else
        target = m.bgA
    end if
    if target <> invalid then
        FSLogSaver("Load: " + uri)
        target.uri = uri
        target.visible = true
        if m.activeIsA then
            m.bgA.visible = false
            m.activeIsA = false
        else
            m.bgB.visible = false
            m.activeIsA = true
        end if
    end if
end sub

' Swallow keys in saver mode
function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false
    return true
end function
