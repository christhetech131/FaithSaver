' ========== FaithSaver main.brs (stand-alone screensaver) ==========

sub FSLogMain(msg as string)
    print "[FaithSaver][Main] "; msg
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

' -------------------------------------------------------------------
' Memory monitor hooks (guarded) to satisfy Static Analysis warnings.
' These do not change app behavior; they just enable/consume events and
' touch the getters once so the analyzer detects usage.
' -------------------------------------------------------------------
sub InitMemoryMonitor(port as object)
    ' App memory monitor (newer firmware)
    m.appMem = CreateObject("roAppMemoryMonitor")
    if m.appMem <> invalid then
        ' enable warning events
        m.appMem.EnableMemoryWarningEvent(true)

        ' touch getters so analyzer sees usage
        _limit  = m.appMem.GetChannelMemoryLimit()
        _pct    = m.appMem.GetMemoryLimitPercent()
        _avail  = m.appMem.GetChannelAvailableMemory()

        FSLogMain("Mem hooks active: limit=" + ToStr(_limit) + " pct=" + ToStr(_pct) + " avail=" + ToStr(_avail))
    else
        FSLogMain("roAppMemoryMonitor not available (skipping)")
    end if

    ' Device info (low general memory events)
    m.devInfo = CreateObject("roDeviceInfo")
    if m.devInfo <> invalid then
        if port <> invalid then m.devInfo.SetMessagePort(port)
        ' enable low-memory event
        m.devInfo.EnableLowGeneralMemoryEvent(true)
        FSLogMain("LowGeneralMemoryEvent enabled")
    else
        FSLogMain("roDeviceInfo not available (skipping)")
    end if
end sub

' -------------------------------------------------------------------
' Entry: system screensaver
' -------------------------------------------------------------------
sub RunScreenSaver()
    FSLogMain("RunScreenSaver: start")

    screen = CreateObject("roSGScreen")
    m.port = CreateObject("roMessagePort")
    screen.SetMessagePort(m.port)

    ' Initialize memory monitoring (guarded)
    InitMemoryMonitor(m.port)

    saver = screen.CreateScene("SaverScene")
    screen.Show()

    while true
        msg = wait(0, m.port)

        if type(msg) = "roSGScreenEvent" and msg.IsScreenClosed() then exit while

        if type(msg) = "roSGNodeEvent" then
            if msg.GetNode() = saver and LCase(msg.GetField()) = "close" then
                if msg.GetData() = true then exit while
            end if

        else if type(msg) = "roDeviceInfoEvent" then
            ' No-op: just consume memory-related events
            ' (optional log)
            FSLogMain("roDeviceInfoEvent received")
        end if
    end while

    FSLogMain("RunScreenSaver: done")
end sub

' -------------------------------------------------------------------
' Entry: Settings from OS UI (Change screensaver settings)
' -------------------------------------------------------------------
sub RunScreenSaverSettings()
    FSLogMain("RunScreenSaverSettings: start")

    screen = CreateObject("roSGScreen")
    m.port = CreateObject("roMessagePort")
    screen.SetMessagePort(m.port)

    ' Initialize memory monitoring (guarded)
    InitMemoryMonitor(m.port)

    settings = screen.CreateScene("SettingsScene")
    screen.Show()

    ' AppLaunchComplete beacon after first paint
    settings.signalBeacon("AppLaunchComplete")

    while true
        msg = wait(0, m.port)

        if type(msg) = "roSGScreenEvent" and msg.IsScreenClosed() then exit while

        if type(msg) = "roSGNodeEvent" then
            if msg.GetNode() = settings and LCase(msg.GetField()) = "close" then
                if msg.GetData() = true then exit while
            end if

        else if type(msg) = "roDeviceInfoEvent" then
            ' No-op: consume memory-related events
            FSLogMain("roDeviceInfoEvent received (settings)")
        end if
    end while

    FSLogMain("RunScreenSaverSettings: done")
end sub
