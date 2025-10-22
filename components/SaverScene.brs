' *********** FaithSaver — SaverScene.brs ***********

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
    else
        ' fallback: show the type so we can debug without crashing
        return "<" + t + ">"
    end if
end function

sub init()
    FSLogSaver("init()")

    m.bgA    = m.top.findNode("bgA")
    m.bgB    = m.top.findNode("bgB")
    m.cycler = m.top.findNode("cycler")
    m.feed   = m.top.findNode("feed") ' placeholder for later

    if m.bgA = invalid or m.bgB = invalid then
        FSLogSaver("ERROR: bgA/bgB not found")
        return
    end if

    if m.cycler <> invalid then
        m.cycler.repeat = true
        if m.cycler.duration = invalid or m.cycler.duration <= 0 then
            m.cycler.duration = 180.0
        end if
        m.cycler.ObserveField("fire", "onCycle")
        FSLogSaver("cycler ready; duration=" + ToStr(m.cycler.duration))
    else
        FSLogSaver("WARN: cycler timer not found")
    end if

    ' Resolve category and set the first offline image immediately
    cat = ReadCategory()
    if cat = "" then cat = "scenery"
    m.category = LCase(cat)

    firstUri = "pkg:/images/offline/" + m.category + ".jpg"
    m.bgA.uri = firstUri
    m.bgA.visible = true
    m.bgB.visible = false
    m.curIsA = true
    FSLogSaver("first image set: " + firstUri)

    ' Start/stop cycler based on mode
    mode = LCase(ToStr(m.top.mode))
    if mode = "saver" then
        if m.cycler <> invalid then
            m.cycler.control = "start"
            FSLogSaver("cycler started")
        end if
    else
        if m.cycler <> invalid then m.cycler.control = "stop"
        FSLogSaver("preview mode; cycler stopped")
    end if
end sub

' Timer rotate callback
sub onCycle(event as object)
    ' TODO: when you wire the online/cache feed, choose nextUri from the shuffled list.
    nextUri = "pkg:/images/offline/" + m.category + ".jpg"
    FSLogSaver("rotate -> next: " + nextUri)

    if m.curIsA then
        m.bgB.uri = nextUri
        m.bgB.visible = true
        m.bgA.visible = false
        m.curIsA = false
        FSLogSaver("swap -> B")
    else
        m.bgA.uri = nextUri
        m.bgA.visible = true
        m.bgB.visible = false
        m.curIsA = true
        FSLogSaver("swap -> A")
    end if
end sub

function ReadCategory() as string
    sec = CreateObject("roRegistrySection", "FaithSaver")
    if sec = invalid then return "scenery"
    v = sec.Read("category")
    if v = invalid or v = "" then return "scenery"
    return LCase(v)
end function

' Key handling:
' - saver: any key exits (your requested production behavior)
' - preview: only back/home exit (so arrows can be repurposed)
function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false

    mode = LCase(ToStr(m.top.mode))
    if mode = "saver" then
        m.top.close = true
        return true
    else
        if key = "back" or key = "home" then
            m.top.close = true
            return true
        end if
        ' arrows/OK are intentionally left for preview navigation later
        return false
    end if
end function
