' *********** FaithSaver — SaverScene.brs (production-only, with state+status visibility) ***********

sub FSLogSaver(msg as string)
    print "[FaithSaver][Saver] " ; ToStr(msg)
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

    FSLogSaver("nodes: bgA=" + ToStr(m.bgA <> invalid) + " bgB=" + ToStr(m.bgB <> invalid) + " cycler=" + ToStr(m.cycler <> invalid) + " feed=" + ToStr(m.feed <> invalid))

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

    ' show offline first frame immediately
    ShowFirstFrameForCategory(m.category)

    ' wire timer
    if m.cycler <> invalid then
        m.cycler.ObserveField("fire", "onCycle")
        FSLogSaver("cycler wired (duration=" + ToStr(m.cycler.duration) + "s)")
    else
        FSLogSaver("ERROR: cycler missing")
    end if

    ' start task
    if m.feed <> invalid then
        ' make entrypoint explicit and watch both state and status
        m.feed.functionName = "Run"
        m.feed.ObserveField("state", "onFeedState")
        m.feed.ObserveField("status", "onFeedStatus")
        m.feed.ObserveField("items", "onFeedItems")
        m.feed.category = m.category
        m.feed.control = "run"
        FSLogSaver("ImageFeedTask started (category=" + m.category + ")")
    else
        FSLogSaver("ERROR: feed task node not found")
    end if
end sub

sub onFeedState()
    FSLogSaver("feed state: " + ToStr(m.feed.state))
end sub

sub onFeedStatus()
    s = m.feed.status
    if s = invalid then s = ""
    FSLogSaver("feed status: " + s)
end sub

' Show initial offline frame for a chosen category
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

' Handle ImageFeedTask completion
sub onFeedItems(evt as Object)
    if evt = invalid then
        FSLogSaver("onFeedItems: evt invalid")
        return
    end if

    arr = evt.GetData()
    if type(arr) <> "roArray" or arr.count() = 0 then
        FSLogSaver("Feed returned empty; staying on offline first frame")
        return
    end if

    ' defensively keep only string URIs
    safe = CreateObject("roArray", 0, true)
    i = 0
    while i < arr.count()
        u = arr[i]
        if type(u) = "roString" or type(u) = "String"
            su = u
            if su <> "" and (Left(su, 5) = "http:" or Left(su, 6) = "https:" or Left(su, 5) = "pkg:/")
                safe.push(su)
            end if
        end if
        i = i + 1
    end while

    if safe.count() = 0 then
        FSLogSaver("Feed items not usable; staying on offline first frame")
        return
    end if

    m.items = safe
    FSLogSaver("Feed items count=" + StrI(m.items.count()))
    if m.cycler <> invalid then
        m.cycler.control = "start"
        FSLogSaver("Cycler started")
    else
        FSLogSaver("ERROR: cycler missing; cannot start rotation")
    end if
end sub

' Timer: rotate images in saver mode (online list if available)
sub onCycle()
    if m.items = invalid or m.items.count() = 0 then
        FSLogSaver("onCycle: no items yet")
        return
    end if

    m.index = (m.index + 1) mod m.items.count()
    uri = m.items[m.index]
    if type(uri) <> "roString" and type(uri) <> "String" then
        FSLogSaver("onCycle: bad uri type")
        return
    end if
    if uri = "" then
        FSLogSaver("onCycle: empty uri")
        return
    end if

    ShowImage(uri)
end sub

' Swap double-buffered background with a quick visible flip
sub ShowImage(uri as string)
    if uri = invalid or uri = "" then
        FSLogSaver("ShowImage: invalid uri")
        return
    end if
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
    else
        FSLogSaver("ShowImage: target invalid")
    end if
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false
    if key = "back" or key = "home" then return true
    return true
end function
