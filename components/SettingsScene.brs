' components/SettingsScene.brs

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
    print "[FaithSaver][Settings] init()"
    m.list   = m.top.findNode("list")
    m.header = m.top.findNode("header")

    ' Focus behavior
    m.top.setFocus(true)
    if m.list <> invalid then m.list.setFocus(true)

    ' Colors per spec
    if m.list <> invalid then
        m.list.itemTextColor         = "0xFF26709D" ' rgba(38,112,157)
        m.list.itemFocusedTextColor  = "0xFFFFFFFF" ' white
        m.list.focusBitmapBlendColor = "0xFF0B3754" ' rgba(11,55,84)
    end if

    ' Categories
    m.categories = [
        "animals", "fall", "geology", "scenery",
        "space", "spring", "summer", "textures",
        "winter", "seasonal"
    ]

    ' Populate content
    content = createObject("roSGNode", "ContentNode")
    for each name in m.categories
        item = createObject("roSGNode", "ContentNode")
        item.title = UCase(Left(name,1)) + Mid(name,2)
        item.shortDescriptionLine1 = name
        content.appendChild(item)
    end for
    if m.list <> invalid then m.list.content = content

    updateHeader()
end sub

sub updateHeader()
    cat = getStoredCategory()
    m.header.text = "Current category: " + UCase(Left(cat,1)) + Mid(cat,2)
end sub

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

function resolveSeasonal() as string
    d = CreateObject("roDateTime")
    m = d.GetMonth()
    if m = 12 or m <= 2 then return "winter"
    if m >= 3 and m <= 5 then return "spring"
    if m >= 6 and m <= 8 then return "summer"
    return "fall"
end function

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false

    k = LCase(key)
    if k = "back" or k = "home" then
        print "[FaithSaver][Settings] Back/Home -> closeRequested"
        m.top.closeRequested = true
        return true
    end if

    if k = "ok" then
        if m.list = invalid then return true
        idx = m.list.itemFocused
        if idx <> invalid and idx >= 0 and idx < m.categories.count()
            sel = m.categories[idx]
            if sel = "seasonal" then sel = resolveSeasonal()
            print "[FaithSaver][Settings] Selected: " + S(sel)
            setStoredCategory(sel)
            updateHeader()
        end if
        return true
    end if

    ' Arrow keys: let LabelList handle navigation
    return false
end function
