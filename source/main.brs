' ===== FaithSaver main.brs =====

' --- helpers ---
sub Log(tag as string, message as string)
    print "[FaithSaver][" + tag + "] " + message
end sub

function SafeToString(x as dynamic) as string
    if x = invalid then return ""
    ' avoid any accidental variable shadowing of tostr()
    return "" + x
end function

function SafeLower(value as dynamic) as string
    return LCase(SafeToString(value))
end function

function GetRunParams() as object
    am = CreateObject("roAppManager")
    if am = invalid then return {}
    p = am.GetRunParams()
    if p = invalid then return {}
    return p
end function

function GetParam(key as string) as string
    p = GetRunParams()
    if GetInterface(p, "ifAssociativeArray") = invalid then return ""
    v = p.Lookup(key)
    return SafeToString(v)
end function

function GetArgValue(args as dynamic, key as string) as string
    if args = invalid then return ""
    if GetInterface(args, "ifAssociativeArray") = invalid then return ""

    value = invalid
    if args[key] <> invalid then value = args[key]
    if value = invalid then value = args.Lookup(key)
    return SafeToString(value)
end function

' --- entrypoints required by manifest ---
sub RunScreenSaver()
    ShowSaverScene(false)
end sub

sub RunScreenSaverPreview()
    ShowSaverScene(true)
end sub

sub RunScreenSaverSettings()
    Log("Settings", "RunScreenSaverSettings invoked")

    screen = CreateObject("roSGScreen")
    port = CreateObject("roMessagePort")
    screen.SetMessagePort(port)

    scene = screen.CreateScene("SettingsScene")
    if scene <> invalid then
        scene.SetFocus(true)
        scene.ObserveField("closeRequested", m.port)
    end if

    screen.Show()
    scene.control = "RUN"
    scene.SetFocus(true)

    if scene <> invalid then
        scene.SetFocus(true)
    end if

    while true
        msg = wait(0, port)
        if msg = invalid then
            ' nothing to do
        else if type(msg) = "roSGScreenEvent" then
            if msg.isScreenClosed() then exit while
        else if type(msg) = "roSGNodeEvent" then
            node = msg.GetNode()
            if node <> invalid and node = scene and msg.GetField() = "closeRequested" and msg.GetData() = true then
                exit while
            end if
        end if
    end while

    screen.Close()
end sub

' --- dev launcher / channel launch router ---
sub RunUserInterface(optional args as dynamic)
    ' Only for dev channel preview. DO NOT route to settings here unless actually launched by Settings.
    argSource = SafeLower(GetArgValue(args, "source"))
    argEntry  = SafeLower(GetArgValue(args, "entry"))
    argReason = SafeLower(GetArgValue(args, "reason"))

    paramSource = SafeLower(GetParam("source"))
    paramEntry  = SafeLower(GetParam("entry"))
    paramReason = SafeLower(GetParam("reason"))

    Log("Router", "args source=" + argSource + " entry=" + argEntry + " reason=" + argReason)
    Log("Router", "params source=" + paramSource + " entry=" + paramEntry + " reason=" + paramReason)

    ' If Roku Settings launched us, go to settings; otherwise show the preview saver
    if shouldShowSettings(argSource, argEntry, argReason, paramSource, paramEntry, paramReason) then
        Log("Router", "Routing to settings from RunUserInterface")
        RunScreenSaverSettings()
    else
        Log("Router", "Routing to preview from RunUserInterface")
        RunScreenSaverPreview()
    end if
end sub

function shouldShowSettings(argSource as string, argEntry as string, argReason as string, paramSource as string, paramEntry as string, paramReason as string) as boolean
    if instr(1, argSource, "settings") > 0 then return true
    if instr(1, argEntry, "settings") > 0 then return true
    if instr(1, argReason, "settings") > 0 then return true

    if instr(1, paramSource, "settings") > 0 then return true
    if instr(1, paramEntry, "settings") > 0 then return true
    if instr(1, paramReason, "settings") > 0 then return true

    return false
end function

' --- shared saver scene launcher ---
sub ShowSaverScene(isPreview as boolean)
    screen = CreateObject("roSGScreen")
    m.port = CreateObject("roMessagePort")
    screen.SetMessagePort(m.port)

    scene = screen.CreateScene("SaverScene")
    if scene <> invalid then
        scene.isPreview = isPreview
    end if

    screen.Show()

    if isPreview then
        Log("Saver", "Preview mode launched")
    else
        Log("Saver", "Saver mode launched")
    end if

    ' Let the SaverScene control exit behavior. (You said Home-only exit is acceptable.)
    while true
        msg = wait(0, m.port)
        if type(msg) = "roSGScreenEvent" and msg.isScreenClosed() then
            exit while
        end if
    end while
end sub

' Roku calls main for legacy. Keep minimal.
sub main(args as dynamic)
    if args <> invalid then : end if ' suppress unused warning from compiler
    RunUserInterface()
end sub
