' ==========================
' FaithSaver - source/main.brs
' ==========================

' -------- Logging helpers --------
sub FSLogMain(msg as string)
    print "[FaithSaver][Main] " + msg
end sub

function SafeToString(v as dynamic) as string
    if v = invalid then return ""
    t = type(v)
    if t = "roString" or t = "String" then return v
    if t = "Boolean" then
        if v = true then return "true" else return "false"
    end if
    if t = "Integer" or t = "LongInteger" then return StrI(v)
    if t = "Float" or t = "Double" then return Str(v)
    return Str(v)
end function

' ---------- Saver entry points ----------
sub RunScreenSaver()
    FSLogMain("RunScreenSaver: enter")
    ShowSaver(false)
end sub

sub RunScreenSaverPreview()
    FSLogMain("RunScreenSaverPreview: enter")
    ShowSaver(true)
end sub

' ---------- Settings entry point (called by Roku Settings) ----------
sub RunScreenSaverSettings()
    FSLogMain("Settings: enter")

    screen = CreateObject("roSGScreen")
    port   = CreateObject("roMessagePort")
    screen.SetMessagePort(port)

    scene = screen.CreateScene("SettingsScene")
    if scene = invalid then
        FSLogMain("Settings: ERROR create SettingsScene failed")
        return
    end if

    ' Observe a field the scene raises ONLY on Back/Home
    scene.ObserveField("closeRequested", port)

    screen.Show()
    FSLogMain("Settings: shown (loop start)")

    while true
        msg = wait(0, port)
        mt  = type(msg)

        if mt = "roSGScreenEvent" then
            FSLogMain("Settings: roSGScreenEvent")
            if msg.isScreenClosed() then
                FSLogMain("Settings: screen closed -> exit loop")
                exit while
            end if

        else if mt = "roSGNodeEvent" then
            n = msg.GetNode()
            f = msg.GetField()
            nName = ""
            if n <> invalid then nName = n.GetName()
            FSLogMain("Settings: roSGNodeEvent node=" + SafeToString(nName) + " field=" + SafeToString(f))

            if n = scene and f = "closeRequested" then
                if scene.closeRequested = true then
                    FSLogMain("Settings: closeRequested=true -> exit loop")
                    exit while
                end if
            end if

        else
            FSLogMain("Settings: unexpected msg type " + SafeToString(mt))
        end if
    end while

    FSLogMain("Settings: exit")
end sub

' ---------- App tile (dev / user launched) ----------
sub RunUserInterface()
    FSLogMain("RunUserInterface: enter (PRODUCTION saver)")
    RunScreenSaver()
    FSLogMain("RunUserInterface: exit")
end sub

' ---------- Shared saver ----------
sub ShowSaver(isPreview as boolean)
    FSLogMain("ShowSaver: enter; isPreview=" + SafeToString(isPreview))

    screen = CreateObject("roSGScreen")
    port   = CreateObject("roMessagePort")
    screen.SetMessagePort(port)

    saver = screen.CreateScene("SaverScene")
    if saver = invalid then
        FSLogMain("ERROR: SaverScene failed to create")
        return
    end if
    FSLogMain("SaverScene created OK")

    modeStr = "saver"
    if isPreview = true then modeStr = "preview"
    saver.SetField("mode", modeStr)
    saver.SetField("isPreview", isPreview)

    saver.ObserveField("close", port)

    screen.Show()
    FSLogMain("ShowSaver: Show done, entering loop")

    while true
        msg = wait(0, port)
        if type(msg) = "roSGScreenEvent" and msg.isScreenClosed() then
            FSLogMain("ShowSaver: screen closed")
            exit while
        else if type(msg) = "roSGNodeEvent" and msg.GetNode() = saver and msg.GetField() = "close" then
            if saver.close = true then
                FSLogMain("ShowSaver: saver requested close")
                exit while
            end if
        end if
    end while
end sub
