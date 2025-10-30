' ========== FaithSaver main.brs (channel -> Settings; saver via screensaver entry) ==========

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

' --- Channel entry: SHOW SETTINGS (no in-channel saver) ---
sub RunUserInterface()
    FSLogMain("RunUserInterface: enter (Settings UI)")
    RunScreenSaverSettings()
    FSLogMain("RunUserInterface: exit")
end sub

' --- System screensaver entry ---
sub RunScreenSaver()
    FSLogMain("RunScreenSaver: enter")
    ShowSaver()
    FSLogMain("RunScreenSaver: exit")
end sub

' --- Settings entry ---
sub RunScreenSaverSettings()
    FSLogMain("RunScreenSaverSettings: enter")

    screen = CreateObject("roSGScreen")
    port   = CreateObject("roMessagePort")
    screen.SetMessagePort(port)

    ' Deep linking events (cert requirement)
    input = CreateObject("roInput")
    input.SetMessagePort(port)

    scene = screen.CreateScene("SettingsScene")
    if scene = invalid then
        FSLogMain("ERROR: SettingsScene failed to create")
        return
    end if

    screen.Show()
    scene.setFocus(true)
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
            ' Optional: parse msg.GetInfo()

        end if
    end while

    FSLogMain("RunScreenSaverSettings: exit")
end sub

' --- Common saver host (used only by system screensaver entry) ---
sub ShowSaver()
    screen = CreateObject("roSGScreen")
    port   = CreateObject("roMessagePort")
    screen.SetMessagePort(port)

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

        end if
    end while

    FSLogMain("ShowSaver: done")
end sub
