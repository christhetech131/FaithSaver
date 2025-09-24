' SettingsScene — plain labels + custom highlight (RGBA colors). No roFileSystem.

sub init()
    m.bg    = m.top.findNode("bg")
    m.menu  = m.top.findNode("menu")
    m.title = m.top.findNode("title")
    m.about = m.top.findNode("about")
    m.aboutVisible = false

    ' RGBA colors (0xRRGGBBAA)
    m.colorNavy  = &h103A57FF   ' navy #103A57, fully opaque
    m.colorWhite = &hFFFFFFFF   ' white
    m.colorBlack = &h000000FF   ' black

    ' Layout
    m.rowH  = 72
    m.rowW  = 1680
    m.textX = 16

    print "SettingsScene.init"

    BuildOptions()

    ' Load saved category; default to animals
    reg = CreateObject("roRegistrySection","FaithSaver")
    saved = reg.Read("category")
    if saved = invalid then saved = ""
    m.savedKey = LCase(saved)
    if m.savedKey = "" then m.savedKey = "animals"
    print "Saved key: "; m.savedKey

    ' Resolve saved index
    m.selected = 0
    i = 0
    while i < m.keys.count()
        if LCase(m.keys[i]) = m.savedKey then
            m.selected = i
            exit while
        end if
        i = i + 1
    end while

    ' Start focus on saved
    m.focus = m.selected
    print "Initial focus index: "; m.focus

    BuildRows()
    Paint()

    m.top.setFocus(true)
end sub

sub BuildOptions()
    ' Titles
    m.titles = CreateObject("roArray", 10, true)
    season = CurrentSeasonName()
    m.titles.push("Seasonal (auto - " + season + ")")
    m.titles.push("Animals")
    m.titles.push("Fall")
    m.titles.push("Geology")
    m.titles.push("Scenery")
    m.titles.push("Space")
    m.titles.push("Spring")
    m.titles.push("Summer")
    m.titles.push("Textures")
    m.titles.push("Winter")

    ' Keys (parallel)
    m.keys = CreateObject("roArray", 10, true)
    m.keys.push("seasonal")
    m.keys.push("animals")
    m.keys.push("fall")
    m.keys.push("geology")
    m.keys.push("scenery")
    m.keys.push("space")
    m.keys.push("spring")
    m.keys.push("summer")
    m.keys.push("textures")
    m.keys.push("winter")
end sub

function CurrentSeasonName() as String
    dt = CreateObject("roDateTime")
    mth = dt.GetMonth()

    if mth = 3 or mth = 4 or mth = 5 then
        return "spring"
    else if mth = 6 or mth = 7 or mth = 8 then
        return "summer"
    else if mth = 9 or mth = 10 or mth = 11 then
        return "fall"
    else
        return "winter"
    end if
end function

sub BuildRows()
    ' Clear menu children
    kids = m.menu.getChildren(-1, 0)
    if kids <> invalid then
        for each k in kids
            if k <> invalid then m.menu.removeChild(k)
        end for
    end if

    ' Highlight bar behind focused row
    m.hl = CreateObject("roSGNode","Rectangle")
    m.hl.width  = m.rowW
    m.hl.height = m.rowH - 8
    m.hl.opacity = 1.0
    m.hl.color  = m.colorNavy
    m.hl.translation = [0, 0]
    m.menu.appendChild(m.hl)

    ' Labels for each row
    m.labels = CreateObject("roArray", m.titles.count(), true)
    y = 0
    i = 0
    while i < m.titles.count()
        lbl = CreateObject("roSGNode","Label")
        lbl.translation = [m.textX, y]
        lbl.opacity = 1.0
        lbl.text  = m.titles[i]
        lbl.color = m.colorBlack        ' unfocused default = black
        m.menu.appendChild(lbl)
        m.labels.push(lbl)
        y = y + m.rowH
        i = i + 1
    end while
end sub

sub Paint()
    ' Position highlight and force colors (every repaint)
    newY = m.focus * m.rowH
    m.hl.translation = [0, newY]
    m.hl.color = m.colorNavy
    m.hl.opacity = 1.0

    i = 0
    while i < m.labels.count()
        if i = m.focus then
            m.labels[i].color = m.colorWhite    ' focused
        else
            m.labels[i].color = m.colorBlack    ' unfocused
        end if
        m.labels[i].opacity = 1.0
        i = i + 1
    end while

    m.title.color = m.colorBlack
    m.title.text  = "FaithSaver Settings — Saved: " + m.titles[m.selected]
end sub

sub ShowAbout()
    if m.about <> invalid then
        m.about.visible = true
    end if
    m.aboutVisible = true
end sub

sub HideAbout()
    if m.about <> invalid then
        m.about.visible = false
    end if
    m.aboutVisible = false
end sub

function onKeyEvent(key as String, press as Boolean) as Boolean
    if not press then return false

    lower = LCase(key)

    if m.aboutVisible then
        if lower = "back" or lower = "ok" or lower = "options" or lower = "info" then
            HideAbout()
            return true
        end if
        return true
    end if

    if lower = "options" or lower = "info" then
        ShowAbout()
        return true
    end if

    if lower = "up" then
        if m.focus > 0 then
            m.focus = m.focus - 1
            Paint()
        end if
        return true

    else if lower = "down" then
        if m.focus < m.titles.count() - 1 then
            m.focus = m.focus + 1
            Paint()
        end if
        return true

    else if lower = "ok" then
        m.selected = m.focus
        reg = CreateObject("roRegistrySection","FaithSaver")
        reg.Write("category", LCase(m.keys[m.selected]))
        reg.Flush()
        print "Saved selection: "; m.keys[m.selected]
        Paint()
        return true

    else if lower = "back" then
        m.top.close = true
        return true
    end if

    return false
end function
