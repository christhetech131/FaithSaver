' FaithSaver — Screensaver entrypoints (focus-safe + close polling)

sub RunScreenSaver()
    screen = CreateObject("roSGScreen")
    port   = CreateObject("roMessagePort")
    screen.SetMessagePort(port)

    scene = screen.CreateScene("FaithSaverScene")
    ' Scene will take focus in its init()
    screen.Show()

    while true
        msg = wait(100, port) ' short poll so we can also check scene.close
        if type(msg) = "roSGScreenEvent" and msg.isScreenClosed() then return
        ' Poll the scene's close flag (set by onKeyEvent Back)
        if scene.close = true then
            screen.Close()
            return
        end if
    end while
end sub

sub RunScreenSaverSettings()
    screen = CreateObject("roSGScreen")
    port   = CreateObject("roMessagePort")
    screen.SetMessagePort(port)

    scene = screen.CreateScene("SettingsScene")
    screen.Show()

    while true
        msg = wait(100, port)
        if type(msg) = "roSGScreenEvent" and msg.isScreenClosed() then return
        if scene.close = true then
            screen.Close()
            return
        end if
    end while
end sub
