' ==========================
' FaithSaver - source/main.brs
' ==========================

' -------- Logging helpers --------
sub FSLogMain(msg as string)
    print "[FaithSaver][Main] " + msg
end sub

' Safe string conversion
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

' -------- Entry points declared in manifest --------
' manifest:
'   run_screen_saver=RunScreenSaver
'   run_screen_saver_preview=RunScreenSaverPreview
'   run_screen_saver_settings=RunScreenSaverSettings

' Called by Roku when the actual screensaver runs due to inactivity.
sub RunScreenSaver()
    FSLogMain("RunScreenSaver: enter")
    ShowSaver(false)
end sub

' Called by Roku when the user selects "Preview" from Settings > Theme > Screensavers.
sub RunScreenSaverPreview()
    FSLogMain("RunScreenSaverPreview: enter")
    ShowSaver(true)
end sub

' Called when the user chooses Settings > Theme > Screensavers > FaithSaver > Change screensaver settings.
sub RunScreenSaverSettings()
    FSLogMain("Settings: enter")

    screen = CreateObject("roSGScreen")
    port   = CreateObject("roMessagePort")
    screen.SetMessagePort(port)

    scene = screen.CreateScene("SettingsScene")
    if scene = invalid then
        FSLogMain("ERROR: SettingsScene failed to create")
        return
    end if

    ' Observe a simple boolean field that the scene will flip when the user wants to exit.
    scene.ObserveField("closeRequested", port)

    screen.Show()
    FSLogMain("Settings: shown (entering loop)")

    ' Block here until either the screen is closed or the scene requests close.
    while true
        msg = wait(0, port)
        mt = type(msg)

        if mt = "roSGScreenEvent" then
            FSLogMain("Settings: roSGScreenEvent")
            if msg.isScreenClosed() then
                FSLogMain("Settings: screen closed")
                exit while
            end if

        else if mt = "roSGNodeEvent" then
            nodeName = ""
            fName    = ""
            if msg <> invalid then
                n = msg.GetNode()
                if n <> invalid then nodeName = n.GetName()
                fName = msg.GetField()
            end if
            FSLogMain("Settings: roSGNodeEvent node=" + SafeToString(nodeName) + " field=" + SafeToString(fName))
            if msg.GetNode() = scene and msg.GetField() = "closeRequested" then
                if scene.closeRequested = true then
                    FSLogMain("Settings: closeRequested=true")
                    exit while
                end if
            end if
        else
            FSLogMain("Settings: unexpected msg type " + SafeToString(mt))
        end if
    end while

    FSLogMain("Settings: exit")
end sub

' Dev/side-load entry (app tile on Home screen). Per your spec: run the PRODUCTION saver here.
sub RunUserInterface()
    FSLogMain("RunUserInterface: enter (PRODUCTION saver)")
    RunScreenSaver()
    FSLogMain("RunUserInterface: exit")
end sub

' -------- Shared UI runner --------
sub ShowSaver(isPreview as boolean)
    FSLogMain("ShowSaver: enter; isPreview=" + SafeToString(isPreview))

    screen = CreateObject("roSGScreen")
    port   = CreateObject("roMessagePort")
    screen.SetMessagePort(port)

    ' Create the main Saver scene
    saver = screen.CreateScene("SaverScene")
    if saver = invalid then
        FSLogMain("ERROR: SaverScene failed to create via CreateScene")
        return
    end if
    FSLogMain("SaverScene created OK")

    ' Set mode/isPreview fields if the scene exposes them.
    if isPreview = true then
        saver.SetField("mode", "preview")
        saver.SetField("isPreview", true)
    else
        saver.SetField("mode", "saver")
        saver.SetField("isPreview", false)
    end if

    ' Optional: observe "close" if SaverScene emits it.
    saver.ObserveField("close", port)

    screen.Show()
    FSLogMain("ShowSaver: Show done, entering loop")

    ' Standard SG loop: exit when the screen closes, or when the scene toggles "close".
    while true
        msg = wait(0, port)
        mt = type(msg)

        if mt = "roSGScreenEvent" then
            if msg.isScreenClosed() then
                FSLogMain("ShowSaver: screen closed")
                exit while
            end if

        else if mt = "roSGNodeEvent" then
            if msg.GetNode() = saver and msg.GetField() = "close" then
                if saver.close = true then
                    FSLogMain("ShowSaver: saver requested close")
                    exit while
                end if
            end if
        end if
    end while
end sub
