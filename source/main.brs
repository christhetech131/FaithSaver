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

'
' RunScreenSaver – entry from system screensaver
'
sub RunScreenSaver()
    FSLogMain("RunScreenSaver: start")

    screen = CreateObject("roSGScreen")
    m.port = CreateObject("roMessagePort")
    screen.SetMessagePort(m.port)

    scene = screen.CreateScene("SaverScene")
    screen.Show()

    ' Event loop (no deep linking here)
    while true
        msg = wait(0, m.port)

        if type(msg) = "roSGScreenEvent" and msg.IsScreenClosed() then exit while

        if type(msg) = "roSGNodeEvent" then
            if msg.GetNode() = scene and LCase(msg.GetField()) = "close" then
                if msg.GetData() = true then exit while
            end if
        end if
    end while

    FSLogMain("RunScreenSaver: done")
end sub

'
' RunScreenSaverSettings – entry from Settings ▸ Theme ▸ Screensavers ▸ Change settings
'
sub RunScreenSaverSettings()
    FSLogMain("RunScreenSaverSettings: start")

    screen = CreateObject("roSGScreen")
    m.port = CreateObject("roMessagePort")
    screen.SetMessagePort(m.port)

    settings = screen.CreateScene("SettingsScene")
    screen.Show()

    ' AppLaunchComplete beacon (after first paint)
    settings.signalBeacon("AppLaunchComplete")

    while true
        msg = wait(0, m.port)
        if type(msg) = "roSGScreenEvent" and msg.IsScreenClosed() then exit while

        if type(msg) = "roSGNodeEvent" then
            if msg.GetNode() = settings and LCase(msg.GetField()) = "close" then
                if msg.GetData() = true then exit while
            end if
        end if
    end while

    FSLogMain("RunScreenSaverSettings: done")
end sub
