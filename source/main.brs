' ===== FaithSaver main.brs =====

' --- helpers ---
function SafeToString(x as dynamic) as string
    if x = invalid then return ""
    ' avoid any accidental variable shadowing of tostr()
    return "" + x
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

' --- entrypoints required by manifest ---
sub RunScreenSaver()
    ShowSaverScene(false)
end sub

sub RunScreenSaverPreview()
    ShowSaverScene(true)
end sub

sub RunScreenSaverSettings()
    ' dedicated settings screen that blocks until Back/Home
    screen = CreateObject("roSGScreen")
    port = CreateObject("roMessagePort")
    screen.SetMessagePort(port)

    scene = screen.CreateScene("SettingsScene")
    if scene <> invalid then
        scene.SetFocus(true)
        scene.ObserveField("closeRequested", m.port)
    end if

    screen.Show()

    if scene <> invalid then
        scene.SetFocus(true)
    end if

    ' wait until user exits
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

    ' screen auto-closes on exit of sub
end sub

' --- dev launcher / channel launch router ---
sub RunUserInterface()
    ' Only for dev channel preview. DO NOT route to settings here unless actually launched by Settings.
    src   = LCase(GetParam("source"))        ' e.g. "auto-run-dev", "homescreen", or "settings"
    entry = LCase(GetParam("entry"))         ' sometimes "settings" on some OS builds, but "source" is the reliable one

    ' If Roku Settings launched us, go to settings; otherwise show the preview saver
    if instr(1, src, "settings") > 0 or instr(1, entry, "settings") > 0 then
        RunScreenSaverSettings()
    else
        RunScreenSaverPreview()
    end if
end sub

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
