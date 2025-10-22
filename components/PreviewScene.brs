' ===== Minimal preview scene (offline only) =====

sub init()
    m.img = m.top.findNode("img")

    ' Cycle the same offline first-frame images you already ship
    m.images = [
        "pkg:/images/offline/animals.jpg",
        "pkg:/images/offline/fall.jpg",
        "pkg:/images/offline/geology.jpg",
        "pkg:/images/offline/scenery.jpg",
        "pkg:/images/offline/space.jpg",
        "pkg:/images/offline/spring.jpg",
        "pkg:/images/offline/summer.jpg",
        "pkg:/images/offline/textures.jpg",
        "pkg:/images/offline/winter.jpg"
    ]

    ' start on saved category if present
    idx = 3
    cur = ReadCategory()
    if cur <> "" then
        for i = 0 to m.images.count()-1
            if instr(1, m.images[i], cur + ".jpg") > 0 then idx = i : exit for
        end for
    end if
    m.idx = idx

    showIdx()

    m.top.setFocus(true)
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false

    if key = "back" or key = "home" then
        m.top.closeRequested = true
        return true
    else if key = "up" then
        m.idx = (m.idx - 1 + m.images.count()) mod m.images.count()
        showIdx() : return true
    else if key = "down" then
        m.idx = (m.idx + 1) mod m.images.count()
        showIdx() : return true
    end if

    return false
end function

sub showIdx()
    m.img.uri = m.images[m.idx]
end sub

function ReadCategory() as string
    sec = CreateObject("roRegistrySection", "FaithSaver")
    if sec = invalid then return ""
    v = sec.Read("category")
    if v = invalid then return ""
    return lcase(v)
end function
