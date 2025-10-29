' ========== FaithSaver main.brs (unified saver; no SetScene) ==========
sub FSLogMain(msg as string)
    print "[FaithSaver][Main] " ; msg
end sub

' --- Channel (production) entry ---
sub RunUserInterface()
    FSLogMain("RunUserInterface: enter (PRODUCTION saver)")
    RunScreenSaver()
    FSLogMain("RunUserInterface: exit")
end sub

' --- Screensaver entry (Roku calls this when the saver actually runs) ---
sub RunScreenSaver()
    FSLogMain("RunScreenSaver: enter")
    ShowSaver(false) ' production
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

    screen.Show()            ' show SCREEN, not scene
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

' --- Preview launcher (DEV) — intentionally routes to production saver (no separate preview) ---
sub RunScreenSaverPreview()
    FSLogMain("RunScreenSaverPreview: enter (routes to production saver)")
    ShowSaver(false) ' no separate preview behavior by design
    FSLogMain("RunScreenSaverPreview: exit")
end sub

' --- Common saver host ---
sub ShowSaver(isPreview as boolean)
    screen = CreateObject("roSGScreen")
    port   = CreateObject("roMessagePort")
    screen.SetMessagePort(port)

    saver = screen.CreateScene("SaverScene")
    if saver = invalid then
        FSLogMain("ERROR: SaverScene failed to create")
        return
    end if

    ' Always production behavior (preview removed)
    saver.mode = "saver"
    FSLogMain("Mode: saver (production)")

    screen.Show()
    saver.SetFocus(true)

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
