' ========== FaithSaver main.brs (screensaver + settings; no in-channel saver) ==========

sub FSLogMain(msg as string)
    print "[FaithSaver][Main] " ; msg
end sub

function ToStr(v as dynamic) as string
    if v = invalid then return ""
    t = type(v)
    if t = "roString" or t = "String" then return v
    if t = "Boolean" then return (v and "true" or "false")
    if t = "Integer" or t = "LongInteger" then return StrI(v)
    if t = "Float" or t = "Double" then return Str(v)
    return "<" + t + ">"
end function

' --- Channel entry: SHOW SETTINGS (no in-channel screensaver) ---
sub RunUserInterface()
    FSLogMain("RunUserInterface: enter (Settings UI)")
    RunScreenSaverSettings()
    FSLogMain("RunUserInterface: exit")
end sub

' --- System screensaver entry (Roku calls this when saver runs) ---
sub RunScreenSaver()
    FSLogMain("RunScreenSaver: enter")
    ShowSaver()
    FSLogMain("RunScreenSaver: exit")
end sub

' --- Settings entry (exposed from the device’s Screensavers menu) ---
sub RunScreenSaverSettings()
    FSLogMain("RunScreenSaverSettings: enter")

    screen = CreateObject("roSGScreen")
    port   = CreateObject("roMessagePort")
    screen.SetMessagePort(port)

    ' Deep linking events (cert requirement: flag + handler)
    ' supports_input_launch=1 is in the manifest; this listener satisfies the handler part.
    input = CreateObject("roInput")
    input.SetMessagePort(port)   ' 

    scene = screen.CreateScene("SettingsScene")
    if scene = invalid then
        FSLogMain("ERROR: SettingsScene failed to create")
        return
    end if

    screen.Show()
    scene.setFocus(true)

    ' Certification/perf beacon once the UI is up (emit from a SceneGraph node).
    ' This is the recommended/working pattern to clear the “AppLaunchComplete” check.
    scene.signalBeacon("AppLaunchComplete")  ' 

    FSLogMain("Settings screen shown")

    while true
        msg = wait(0, port)

        if type(msg) = "roSGScreenEvent" and msg.IsScreenClosed() then exit while

        if type(msg) = "roSGNodeEvent" then
            if msg.GetNode() = scene and LCase(msg.GetField()) = "close" then
                if msg.GetData() = true then exit while
            end if

        else if type(msg) = "roInputEvent" then
            FSLogMain("Deep link roInputEvent received (Settings)")
            ' Optional: dl = msg.GetInfo() : FSLogMain("roInput payload=" + ToStr(dl))

        end if
    end while

    FSLogMain("RunScreenSaverSettings: exit")
end sub

' --- Saver host (invoked only by the system screensaver entry) ---
sub ShowSaver()
    screen = CreateObject("roSGScreen")
    port   = CreateObject("roMessagePort")
    screen.SetMessagePort(port)

    ' Not strictly needed for a saver, but harmless to keep the roInput hook consistent.
    input = CreateObject("roInput")
    input.SetMessagePort(port)

    saver = screen.CreateScene("SaverScene")
    if saver = invalid then
        FSLogMain("ERROR: SaverScene failed to create")
        return
    end if

    screen.Show()
    saver.SetFocus(true)

    while true
        msg = wait(0, port)

        if type(msg) = "roSGScreenEvent" and msg.IsScreenClosed() then exit while

        if type(msg) = "roSGNodeEvent" then
            if msg.GetNode() = saver and LCase(msg.GetField()) = "close" then
                if msg.GetData() = true then exit while
            end if

        else if type(msg) = "roInputEvent" then
            FSLogMain("Deep link roInputEvent received (Saver)")
            ' No action for a saver; just acknowledging the event is fine.

        end if
    end while

    FSLogMain("ShowSaver: done")
end sub
