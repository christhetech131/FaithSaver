' ========== FaithSaver main.brs (with extra debug for Settings) ==========

sub FSLogMain(msg as string)
    print "[FaithSaver][Main] " ; msg
end sub

sub RunUserInterface()
    FSLogMain("RunUserInterface: enter (PRODUCTION saver)")
    RunScreenSaver()
    FSLogMain("RunUserInterface: exit")
end sub

sub RunScreenSaver()
    FSLogMain("RunScreenSaver: enter")
    ShowSaver(false)
    FSLogMain("RunScreenSaver: exit")
end sub

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

    ' Mirror current registry value in the scene header once it mounts
    ' (scene handles its own header too; this is just extra visibility)
    screen.Show()
    FSLogMain("Settings screen shown")

    while true
        msg = wait(0, port)
        if type(msg) = "roSGScreenEvent" then
            FSLogMain("roSGScreenEvent: IsScreenClosed=" + (msg.IsScreenClosed()).ToStr())
            if msg.IsScreenClosed() then exit while

        else if type(msg) = "roSGNodeEvent" then
            n = msg.GetNode()
            if n <> invalid then
                FSLogMain("roSGNodeEvent: node=" + n.GetFieldString("id"))
                if n.DoesExist("closeRequested") and n.closeRequested = true then
                    FSLogMain("SettingsScene requested close")
                    exit while
                end if
            end if
        else
            FSLogMain("Other message type: " + type(msg))
        end if
    end while

    FSLogMain("RunScreenSaverSettings: exit")
end sub

sub ShowSaver(isPreview as boolean)
    FSLogMain("ShowSaver: enter; isPreview=" + (isPreview=true).ToStr())

    screen = CreateObject("roSGScreen")
    port   = CreateObject("roMessagePort")
    screen.SetMessagePort(port)

    saver = screen.CreateScene("SaverScene")
    if saver = invalid then
        FSLogMain("ERROR: SaverScene failed to create")
        return
    end if
    FSLogMain("SaverScene created OK")

    if isPreview then
        saver.SetField("mode", "preview")
    else
        saver.SetField("mode", "saver")
    end if
    saver.SetField("isPreview", isPreview)

    saver.ObserveField("close", port)
    screen.Show()

    while true
        msg = wait(0, port)
        if type(msg) = "roSGScreenEvent" and msg.IsScreenClosed() then exit while
        if type(msg) = "roSGNodeEvent" then
            n = msg.GetNode()
            if n = saver and n.DoesExist("close") and n.close = true then
                exit while
            end if
        end if
    end while

    FSLogMain("ShowSaver: done")
end sub
