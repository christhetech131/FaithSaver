' ===== SettingsScene.brs =====
sub init()
    log("init start")

    m.top.closeRequested = false
    m.top.setFocus(true)
    m.list = m.top.findNode("list")

    if m.list = invalid then
        log("LabelList node not found; settings UI cannot receive focus")
        return
    end if

    ' White text, Navy highlight requirements
    m.list.itemTextColor         = "0xFFFFFFFF" ' white
    m.list.focusBitmapUri        = ""            ' ensure blend color applies
    m.list.focusBitmapBlendColor = "0xFF001F3F" ' opaque navy

    ' populate list content
    m.list.content = CreateSettingsContent()

    ' give focus to the list so keys are handled
    m.list.setFocus(true)

    log("LabelList configured; settings scene ready")
end sub

function CreateSettingsContent() as object
    rows = [
        { title: "Theme: Classic" },
        { title: "Show Verse: On" },
        { title: "Rotation Speed: Normal" },
        { title: "Clock: Off" },
        { title: "Reset to Defaults" },
        { title: "About FaithSaver" },
        { title: "Back" }
    ]

    root = CreateObject("roSGNode", "ContentNode")
    for each r in rows
        n = CreateObject("roSGNode", "ContentNode")
        n.title = r.title
        root.appendChild(n)
    end for
    return root
end function

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false

    lower = LCase(key)
    log("onKeyEvent press key=" + lower)

    if lower = "back" or lower = "home" then
        ' Signal our parent loop to exit settings cleanly
        m.top.closeRequested = true
        log("closeRequested set from back/home")
        return true
    end if

    if lower = "ok"
        if m.list <> invalid then
            idx = m.list.itemFocused
            content = m.list.content
            if content <> invalid then
                backIndex = content.GetChildCount() - 1
                log("OK pressed on index=" + StrI(idx) + " backIndex=" + StrI(backIndex))
                if idx = backIndex then
                    m.top.closeRequested = true
                    log("closeRequested set from Back menu item")
                    return true
                end if
            else
                log("LabelList content invalid on OK press")
            end if
        else
            log("LabelList missing during OK press")
        end if
    end if

    return false
end function

sub log(message as string)
    print "[FaithSaver][SettingsScene] " + message
end sub
