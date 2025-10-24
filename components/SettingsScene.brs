' ========== FaithSaver — SaverScene (no animations; immediate swap) ==========

sub FSLogSaver(msg as string)
    print "[FaithSaver][Saver] "; ToStr(msg)
end sub

function ToStr(v as dynamic) as string
    if v = invalid then return ""
    t = type(v)
    if t = "Boolean" then return (v and "true" or "false")
    if t = "roString" or t = "String" then return v
    if t = "Integer" or t = "LongInteger" then return StrI(v)
    if t = "Float" or t = "Double" then return Str(v)
    if t = "roArray" then return "Array(" + StrI(v.count()) + ")"
    if t = "roAssociativeArray" then return "AA(" + StrI(v.count()) + ")"
    return "<" + t + ">"
end function

sub init()
    FSLogSaver("init()")

    m.bgA    = m.top.findNode("bgA")
    m.bgB    = m.top.findNode("bgB")
    m.cycler = m.top.findNode("cycler")
    m.feed   = m.top.findNode("feed")

    FSLogSaver("nodes: bgA=" + ToStr(m.bgA <> invalid) + " bgB=" + ToStr(m.bgB <> invalid) + " cycler=" + ToStr(m.cycler <> invalid) + " feed=" + ToStr(m.feed <> invalid))

    ' state
    m.activeIsA = true
    m.index = 0
    m.items = CreateObject("roArray", 0, true)

    ' read category with guard; default animals
    m.category = "animals"
    sec = CreateObject("roRegistrySection", "FaithSaver")
    if sec <> invalid then
        val = sec.Read("category")
        if val <> invalid and val <> "" then m.category = LCase(val)
    end if
    FSLogSaver("Registry category=" + m.category)

    ' Ensure initial visibility (A on, B off)
    if m.bgA <> invalid then m.bgA.visible = true
    if m.bgB <> invalid then m.bgB.visible = false

    ' Show the first offline frame immediately (no preload, no animation)
    ShowFirstFrameForCategory(m.category)

    ' Wire online feed (start once and let it populate)
    if m.feed <> invalid then
        m.feed.category = m.category
        m.feed.ObserveField("items", "onFeedItems")
        m.feed.ObserveField("status", "onFeedStatus")
        m.feed.control = "run"
        FSLogSaver("ImageFeedTask started (category=" + m.category + ")")
    else
        FSLogSaver("ERROR: feed task node not found")
    end if

    ' Wire timer; only start when we actually have items
    if m.cycler <> invalid then
        m.cycler.ObserveField("fire", "onCycle")
        FSLogSaver("cycler wired (duration= " + ToStr(m.cycler.duration) + "s)")
    end if

    FSLogSaver("SaverScene shown")
end sub

' Pick offline image for first paint
sub ShowFirstFrameForCategory(cat as string)
    localMap = {
        "animals":  "pkg:/images/offline/animals.jpg",
        "fall":     "pkg:/images/offline/fall.jpg",
        "geology":  "pkg:/images/offline/geology.jpg",
        "scenery":  "pkg:/images/offline/scenery.jpg",
        "space":    "pkg:/images/offline/space.jpg",
        "spring":   "pkg:/images/offline/spring.jpg",
        "summer":   "pkg:/images/offline/summer.jpg",
        "textures": "pkg:/images/offline/textures.jpg",
        "winter":   "pkg:/images/offline/winter.jpg",
        "seasonal": "pkg:/images/offline/default.jpg",
        "default":  "pkg:/images/offline/default.jpg"
    }
    key = LCase(cat)
    uri = localMap[key]
    if uri = invalid then uri = localMap["default"]
    ShowImage(uri)
end sub

' Feed status passthrough (optional logs)
sub onFeedStatus()
    s = ToStr(m.feed.status)
    if s <> "" then FSLogSaver("feed status: " + s)
end sub

' Feed items ready → keep list and start cycler
sub onFeedItems(evt as object)
    if evt = invalid then return
    arr = evt.GetData()
    if type(arr) <> "roArray" or arr.count() = 0 then
        FSLogSaver("Feed returned empty; staying on offline image")
        return
    end if
    m.items = arr
    FSLogSaver("Feed items count=" + StrI(m.items.count()))
    if m.cycler <> invalid then
        m.cycler.control = "start"
        FSLogSaver("Cycler started")
    end if
end sub

' Timer tick → advance and show
sub onCycle()
    if m.items <> invalid and m.items.count() > 0 then
        m.index = (m.index + 1) mod m.items.count()
        ShowImage(m.items[m.index])
    end if
end sub

' Immediate swap: set URI on hidden buffer, then flip visibility (no animation)
sub ShowImage(uri as string)
    if uri = invalid or uri = "" then return
    if m.activeIsA then
        ' A is visible; load B then flip
        if m.bgB <> invalid then m.bgB.uri = uri
        if m.bgB <> invalid then m.bgB.visible = true
        if m.bgA <> invalid then m.bgA.visible = false
        m.activeIsA = false
    else
        ' B is visible; load A then flip
        if m.bgA <> invalid then m.bgA.uri = uri
        if m.bgA <> invalid then m.bgA.visible = true
        if m.bgB <> invalid then m.bgB.visible = false
        m.activeIsA = true
    end if
    FSLogSaver("Load: " + uri)
end sub

' Production saver swallows keys
function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false
    if key = "back" or key = "home" then return true
    return true
end function
