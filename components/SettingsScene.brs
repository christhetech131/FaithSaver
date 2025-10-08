' ===== SettingsScene.brs =====
sub init()
    m.top.setFocus(true)
    m.list = m.top.findNode("list")

    ' White text, Navy highlight requirements
    ' (Use built-in fields for readability; keep it simple and consistent.)
    m.list.itemTextColor        = "0xFFFFFFFF" ' white
    m.list.focusBitmapBlendColor = "0x001F3FFF" ' navy-ish focus bar (ARGB -> 0xAARRGGBB; here AA=00 means we rely on built-in opacity)
    m.list.focusBitmapUri       = ""           ' default highlight bar with our blend color

    ' minimal example items
    m.list.content = CreateSettingsContent()

    ' ensure the list can receive keys
    m.list.setFocus(true)
end sub

function CreateSettingsContent() as object
    rows = [
        { title: "Theme: Classic" }
        { title: "Show Verse: On" }
        { title: "Rotation Speed: Normal" }
        { title: "Clock: Off" }
        { title: "Reset to Defaults" }
        { title: "About FaithSaver" }
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

    if key = "back" or key = "home" then
        ' Signal our parent loop to exit settings cleanly
        m.top.closeRequested = true
        return true
    end if

    if key = "OK"
        if m.list <> invalid then
            idx = m.list.itemFocused
            ' Example: last item exits
            if idx = m.list.content.GetChildCount() - 1
                m.top.closeRequested = true
                return true
            end if
        end if
    end if

    return false
end function
