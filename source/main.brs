' ========== FaithSaver main.brs (single production path) ==========
sub FSLogMain(msg as string)
    print "[FaithSaver][Main] " ; msg
end sub

' --- Dev/Channel entry: run the production saver so behavior matches system Preview ---
sub RunUserInterface()
    FSLogMain("RunUserInterface: enter (PRODUCTION saver)")
    RunScreenSaver()
    FSLogMain("RunUserInterface: exit")
end sub

' --- Screensaver entry (Roku calls this for real saver and system Preview) ---
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

    scene = screen.CreateScene("SettingsScene")
    if scene = invalid then
        FSLogMain("ERROR: SettingsScene failed to create")
        return
    end if

    screen.Show()  ' show the SCREEN (not the scene)
    scene.setFocus(true)
    FSLogMain("Settings screen shown")

    while true
        msg = wait(0, port)
        if type(msg) = "roSGScreenEvent" and msg.IsScreenClosed() then exit while
        if type(msg) = "roSGNodeEvent" then
            if msg.GetNode() = scene and LCase(msg.GetField()) = "close" then
                if msg.GetData() = true then exit while
            end if
        end if
    end while

    FSLogMain("RunScreenSaverSettings: exit")
end sub

' --- Common saver host (production behavior only) ---
sub ShowSaver()
    screen = CreateObject("roSGScreen")
    port   = CreateObject("roMessagePort")
    screen.SetMessagePort(port)

    saver = screen.CreateScene("SaverScene")
    if saver = invalid then
        FSLogMain("ERROR: SaverScene failed to create")
        return
    end if

    screen.Show()
    saver.SetFocus(true)
    FSLogMain("SaverScene shown")

    while true
        msg = wait(0, port)
        if type(msg) = "roSGScreenEvent" and msg.IsScreenClosed() then exit while
        if type(msg) = "roSGNodeEvent" then
            if msg.GetNode() = saver and LCase(msg.GetField()) = "close" then
                if msg.GetData() = true then exit while
            end if
        end if
    end while

    FSLogMain("ShowSaver: done")
end sub
