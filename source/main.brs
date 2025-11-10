' ========== FaithSaver main.brs (stand-alone screensaver) ==========

' Include shared logger helpers (must be first non-comment line)
Library "pkg:/source/logger.brs"

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
' Memory monitor hooks (guarded)
' -------------------------------------------------------------------
sub InitMemoryMonitor(port as object)
    m.appMem = CreateObject("roAppMemoryMonitor")
    if m.appMem <> invalid then
        m.appMem.EnableMemoryWarningEvent(true)
        _limit  = m.appMem.GetChannelMemoryLimit()
        _pct    = m.appMem.GetMemoryLimitPercent()
        _avail  = m.appMem.GetChannelAvailableMemory()
        FSLogMain("Mem hooks active: limit=" + ToStr(_limit) + " pct=" + ToStr(_pct) + " avail=" + ToStr(_avail))
    else
        FSLogMain("roAppMemoryMonitor not available (skipping)")
    end if

    m.devInfo = CreateObject("roDeviceInfo")
    if m.devInfo <> invalid then
        if port <> invalid then m.devInfo.SetMessagePort(port)
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
    FS_Log("boot: RunScreenSaver entry")

    screen = CreateObject("roSGScreen")
    m.port = CreateObject("roMessagePort")
    screen.SetMessagePort(m.port)

    InitMemoryMonitor(m.port)

    ' Attach system network logging (http.*) to our port; forwarded to file when armed
    sys = FS_SyslogAttach(m.port)

    saver = screen.CreateScene("SaverScene")
    screen.Show()
    FS_Log("init: SGScreen shown")

    while true
        msg = wait(0, m.port)

        if type(msg) = "roSGScreenEvent" and msg.IsScreenClosed() then exit while

        if type(msg) = "roSGNodeEvent" then
            if msg.GetNode() = saver and LCase(msg.GetField()) = "close" then
                if msg.GetData() = true then exit while
            end if

        else if type(msg) = "roDeviceInfoEvent" then
            FSLogMain("roDeviceInfoEvent received")
            FS_Log("mem: roDeviceInfoEvent")

        else if type(msg) = "roSystemLogEvent" then
            FS_Log("syslog: event")
        end if
    end while

    FS_Log("exit: RunScreenSaver done")
    FSLogMain("RunScreenSaver: done")
end sub

' -------------------------------------------------------------------
' Entry: Settings from OS UI
' -------------------------------------------------------------------
sub RunScreenSaverSettings()
    FSLogMain("RunScreenSaverSettings: start")
    FS_Log("settings: start")

    screen = CreateObject("roSGScreen")
    m.port = CreateObject("roMessagePort")
    screen.SetMessagePort(m.port)

    InitMemoryMonitor(m.port)

    sys = FS_SyslogAttach(m.port)

    settings = screen.CreateScene("SettingsScene")
    screen.Show()
    FS_Log("settings: SGScreen shown")

    while true
        msg = wait(0, m.port)

        if type(msg) = "roSGScreenEvent" and msg.IsScreenClosed() then exit while

        if type(msg) = "roSGNodeEvent" then
            if msg.GetNode() = settings and LCase(msg.GetField()) = "close" then
                if msg.GetData() = true then exit while
            end if

        else if type(msg) = "roDeviceInfoEvent" then
            FSLogMain("roDeviceInfoEvent received (settings)")
            FS_Log("mem: roDeviceInfoEvent (settings)")

        else if type(msg) = "roSystemLogEvent" then
            FS_Log("syslog: event (settings)")
        end if
    end while

    FS_Log("settings: done")
    FSLogMain("RunScreenSaverSettings: done")
end sub
