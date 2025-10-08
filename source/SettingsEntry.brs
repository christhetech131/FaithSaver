' Entry point used by Roku Settings > Themes > Screensavers > <Your Saver> > Change screensaver settings
' NOTE: This is separate from your app-launch path. It won’t affect saver startup.

sub RunScreenSaverSettings()
    screen = CreateObject("roSGScreen")
    port   = CreateObject("roMessagePort")
    screen.SetMessagePort(port)

    scene = screen.CreateScene("SettingsScene")
    screen.Show()

    ' Keep the settings UI open until the scene sets close=true or the screen is closed.
    while true
        msg = wait(0, port)
        if type(msg) = "roSGScreenEvent" then
            if msg.isScreenClosed() then return
        end if
        if scene <> invalid and scene.close = true then exit while
    end while
end sub
