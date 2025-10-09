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
    screen = CreateObject("roSGScreen")
    if type(screen) <> "roSGScreen" then
        Log("Settings", "Failed to create roSGScreen")
        return
    end if

    port = CreateObject("roMessagePort")
    if type(port) <> "roMessagePort" then
        Log("Settings", "Failed to create roMessagePort")
        return
    end if
    screen.SetMessagePort(port)

    scene = screen.CreateScene("SettingsScene")
    if scene = invalid then
        Log("Settings", "Unable to create SettingsScene")
        return
    end if

    scene.closeRequested = false
    scene.ObserveField("closeRequested", port)

    screen.SetScene(scene)

    screen.Show()

    while true
        msg = wait(0, port)

        if msg = invalid then
            ' continue waiting
        elseif type(msg) = "roSGScreenEvent" then
            if msg.isScreenClosed() then exit while
        elseif type(msg) = "roSGNodeEvent" then
            if msg.GetNode() = scene and msg.GetField() = "closeRequested" then
                if scene.closeRequested = true or msg.GetData() = true then
                    exit while
                end if
            end if
        end if
    end while

    scene.UnobserveField("closeRequested")
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
    port = CreateObject("roMessagePort")
    screen.SetMessagePort(port)

    scene = screen.CreateScene("SaverScene")
    if scene <> invalid then
        scene.isPreview = isPreview
    end if

    screen.Show()

    while true
        msg = wait(0, port)
        if type(msg) = "roSGScreenEvent" and msg.isScreenClosed() then
            exit while
        end if
    end while
end sub

' Roku calls main for legacy. Keep minimal.
sub main(args as dynamic)
    if args <> invalid then
        Log("Main", "main() received args")
    else
        Log("Main", "main() received invalid args")
    end if
    RunUserInterface(args)
end sub
