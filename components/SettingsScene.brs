' components/SettingsScene.brs
' Minimal, stable settings scene

function S(v as dynamic) as string
    if v = invalid then return ""
    t = type(v)
    if t = "roString" or t = "String" then return v
    if t = "Boolean" then return (v = true) and "true" or "false"
    if t = "Integer" or t = "LongInteger" then return StrI(v)
    return Str(v)
end function

sub init()
    m.list   = m.top.findNode("list")
    m.header = m.top.findNode("header")

    m.categories = [
        "animals", "fall", "geology", "scenery",
        "space", "spring", "summer", "textures",
        "winter", "seasonal"
    ]

    ' initial label text
    updateHeader()

    ' build list content
    content = createObject("roSGNode", "ContentNode")
    for each name in m.categories
        item = createObject("roSGNode", "ContentNode")
        item.title = capitalize(name)
        item.shortDescriptionLine1 = name
        content.appendChild(item)
    end for
    m.list.content = content

    ' give focus so keys work and the screen stays visible
    m.top.setFocus(true)
    m.list.setFocus(true)
end sub

sub updateHeader()
    sel = getStoredCategory()
    m.header.text = "Current category: " + capitalize(sel)
end sub

function capitalize(s as string) as string
    if s = invalid or Len(s) = 0 then return ""
    return UCase(Left(s,1)) + Mid(s,2)
end function

' Read/write selected category from registry (or default)
function getStoredCategory() as string
    reg = CreateObject("roRegistrySection", "FaithSaver")
    val = reg.Read("category")
    if val = invalid or val = "" then return "scenery"
    return val
end function

sub setStoredCategory(cat as string)
    reg = CreateObject("roRegistrySection", "FaithSaver")
    reg.Write("category", cat)
    reg.Flush()
end sub

' Resolve "seasonal" to concrete category by date
function resolveSeasonal() as string
    d = CreateObject("roDateTime")
    month = d.GetMonth() ' 1..12
    if month = 12 or month <= 2 then return "winter"
    if month >= 3 and month <= 5 then return "spring"
    if month >= 6 and month <= 8 then return "summer"
    return "fall"
end function

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false

    if key = "back" or key = "home" then
        m.top.closeRequested = true
        return true
    end if

    if key = "OK" then
        idx = m.list.itemFocused
        if idx <> invalid and idx >= 0 and idx < m.categories.count()
            sel = m.categories[idx]
            if sel = "seasonal" then sel = resolveSeasonal()
            setStoredCategory(sel)
            updateHeader()
            ' stay on screen; user exits with Back/Home
        end if
        return true
    end if

    return false
end function
