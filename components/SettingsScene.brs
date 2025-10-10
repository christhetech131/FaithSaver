' components/SettingsScene.brs
' Minimal, stable settings scene with explicit focus and colors

function S(v as dynamic) as string
    if v = invalid then return ""
    t = type(v)
    if t = "roString" or t = "String" then return v
    if t = "Boolean" then
        if v = true then return "true" else return "false"
    end if
    if t = "Integer" or t = "LongInteger" then return StrI(v)
    if t = "Float" or t = "Double" then return Str(v)
    return Str(v)
end function

sub init()
    m.list   = m.top.findNode("list")
    m.header = m.top.findNode("header")

    ' Roku sometimes closes the screen if nothing has focus; make it explicit.
    m.top.setFocus(true)
    if m.list <> invalid then m.list.setFocus(true)

    ' Apply your color scheme from code (more consistent across firmware)
    ' Unfocused text = rgba(38,112,157) => 0xFF26709D, Focused text = white, highlight bar = rgba(11,55,84) => 0xFF0B3754
    if m.list <> invalid then
        m.list.itemTextColor = "0xFF26709D"
        m.list.itemFocusedTextColor = "0xFFFFFFFF"
        m.list.focusBitmapBlendColor = "0xFF0B3754"
    end if

    ' Categories per your spec
    m.categories = [
        "animals", "fall", "geology", "scenery",
        "space", "spring", "summer", "textures",
        "winter", "seasonal"
    ]

    ' Initial label text
    updateHeader()

    ' Build list content
    content = createObject("roSGNode", "ContentNode")
    for each name in m.categories
        item = createObject("roSGNode", "ContentNode")
        item.title = capitalize(name)
        item.shortDescriptionLine1 = name
        content.appendChild(item)
    end for
    if m.list <> invalid then m.list.content = content
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
    return LCase(val)
end function

sub setStoredCategory(cat as string)
    reg = CreateObject("roRegistrySection", "FaithSaver")
    reg.Write("category", LCase(cat))
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
        if m.list = invalid then return true
        idx = m.list.itemFocused
        if idx <> invalid and idx >= 0 and idx < m.categories.count()
            sel = m.categories[idx]
            if sel = "seasonal" then sel = resolveSeasonal()
            setStoredCategory(sel)
            updateHeader()
            ' stays on screen; user exits with Back/Home
        end if
        return true
    end if

    ' Arrows navigate the list naturally
    return false
end function
