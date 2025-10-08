' ===== SettingsScene.brs =====
sub init()
    m.top.setFocus(true)
    m.list = m.top.findNode("list")

    if m.list <> invalid then
        ' White text, Navy highlight requirements
        ' Use blend color to tint the default highlight bar.
        m.list.itemTextColor         = "0xFFFFFFFF" ' white
        m.list.focusBitmapBlendColor = "0xFF001F3F" ' opaque navy
        m.list.focusBitmapUri        = ""            ' default highlight bar with our blend color

        ' minimal example items
        m.list.content = CreateSettingsContent()

        ' ensure the list can receive keys
        m.list.setFocus(true)
    end if
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

    key = LCase(key)

    if key = "back" or key = "home" then
        ' Signal our parent loop to exit settings cleanly
        m.top.closeRequested = true
        return true
    end if

    if key = "ok"
        if m.list <> invalid then
            idx = m.list.itemFocused
            content = m.list.content
            if content <> invalid then
                backIndex = content.GetChildCount() - 1
                if idx = backIndex then
                    m.top.closeRequested = true
                    return true
                end if
            end if
        end if
    end if

    return false
end function
