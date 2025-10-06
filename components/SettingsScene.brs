' [FaithSaver] SettingsScene.brs

sub init()
    m.title  = m.top.findNode("title")
    m.list   = m.top.findNode("list")
    m.hilite = m.top.findNode("hilite")

    m.categories = [
        "animals","fall","geology","scenery","space","spring","summer","textures","winter"
    ]
    m.index = getSelectedIndex(getSavedCategory())

    ' Build labels
    y = 0
    for each cat in m.categories
        lbl = CreateObject("roSGNode","Label")
        lbl.text = cat
        lbl.translation = [0, y]
        lbl.font = "Medium"
        m.list.appendChild(lbl)
        y = y + 54
    end for

    updateTitle()
    updateHilite()

    m.top.observeField("keyEvent","onKey")
end sub

function getSavedCategory() as string
    defaultCat = "animals"
    sec = CreateObject("roRegistrySection","FaithSaver")
    if sec = invalid then return defaultCat
    if sec.Exists("category") then
        cat = sec.Read("category")
        if cat <> invalid and cat <> "" then return cat
    end if
    return defaultCat
end function

function getSelectedIndex(cat as string) as integer
    for i = 0 to m.categories.count()-1
        if m.categories[i] = cat then return i
    end for
    return 0
end function

sub updateTitle()
    m.title.text = "Category: " + m.categories[m.index]
end sub

sub updateHilite()
    m.hilite.translation = [410, 240 + (m.index * 54)]
end sub

sub saveAndExit()
    sec = CreateObject("roRegistrySection","FaithSaver")
    if sec <> invalid then
        sec.Write("category", m.categories[m.index])
        sec.Flush()
    else
        print "[FaithSaver] Registry section invalid; cannot save category."
    end if
    m.top.saved = true
    m.top.close = true
end sub

function onKey(e as Object) as boolean
    if e.key = "back" then
        m.top.close = true
        return true
    else if e.key = "up" then
        if m.index > 0 then m.index = m.index - 1
        updateTitle() : updateHilite()
        return true
    else if e.key = "down" then
        if m.index < m.categories.count()-1 then m.index = m.index + 1
        updateTitle() : updateHilite()
        return true
    else if e.key = "OK" then
        saveAndExit()
        return true
    end if
    return false
end function
