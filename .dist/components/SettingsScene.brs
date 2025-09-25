' SettingsScene - simple label list with blue highlight. ASCII only.

sub init()
  m.bg         = m.top.findNode("bg")
  m.menu       = m.top.findNode("menu")
  m.title      = m.top.findNode("title")
  m.about      = m.top.findNode("about")
  m.aboutText  = m.top.findNode("aboutText")
  m.aboutTitle = m.top.findNode("aboutTitle")

  m.aboutVisible = false
  m.aboutLoaded  = false

  m.colorNavy  = &h103A57FF
  m.colorWhite = &hFFFFFFFF
  m.colorBlack = &h000000FF

  m.rowH  = 72
  m.rowW  = 1680
  m.textX = 16

  if m.bg <> invalid then
    m.bg.uri = "pkg:/images/FaithSaver-Splash-1920x1080.jpg"
    m.bg.loadDisplayMode = "scaleToFill"
  end if

  BuildOptions()

  reg = CreateObject("roRegistrySection","FaithSaver")
  saved = reg.Read("category") : if saved = invalid then saved = ""
  m.savedKey = LCase(saved) : if m.savedKey = "" then m.savedKey = "animals"

  m.selected = 0
  i = 0 : while i < m.keys.count()
    if LCase(m.keys[i]) = m.savedKey then m.selected = i : exit while
    i = i + 1
  end while
  m.focus = m.selected

  BuildRows()
  Paint()
  m.top.setFocus(true)
end sub

sub BuildOptions()
  m.titles = []
  season = CurrentSeasonName()
  m.titles.push("Seasonal (auto " + season + ")")
  m.titles.push("Animals")
  m.titles.push("Fall")
  m.titles.push("Geology")
  m.titles.push("Scenery")
  m.titles.push("Space")
  m.titles.push("Spring")
  m.titles.push("Summer")
  m.titles.push("Textures")
  m.titles.push("Winter")
  m.keys = ["seasonal","animals","fall","geology","scenery","space","spring","summer","textures","winter"]
end sub

function CurrentSeasonName() as String
  dt = CreateObject("roDateTime")
  mth = dt.GetMonth()
  if mth = 3 or mth = 4 or mth = 5 then return "spring"
  if mth = 6 or mth = 7 or mth = 8 then return "summer"
  if mth = 9 or mth = 10 or mth = 11 then return "fall"
  return "winter"
end function

sub BuildRows()
  if m.menu = invalid then m.labels = [] : m.hl = invalid : return

  kids = m.menu.getChildren(-1, 0)
  if kids <> invalid then
    for each k in kids
      if k <> invalid then m.menu.removeChild(k)
    end for
  end if

  m.hl = CreateObject("roSGNode","Rectangle")
  m.hl.width  = m.rowW
  m.hl.height = m.rowH - 8
  m.hl.opacity = 1.0
  m.hl.color  = m.colorNavy
  m.hl.translation = [0, 0]
  m.menu.appendChild(m.hl)

  m.labels = []
  y = 0
  i = 0
  while i < m.titles.count()
    lbl = CreateObject("roSGNode","Label")
    lbl.translation = [m.textX, y]
    lbl.opacity = 1.0
    lbl.text  = m.titles[i]
    lbl.color = m.colorBlack
    m.menu.appendChild(lbl)
    m.labels.push(lbl)
    y = y + m.rowH
    i = i + 1
  end while
end sub

sub Paint()
  if m.hl <> invalid then
    m.hl.translation = [0, m.focus * m.rowH]
    m.hl.color = m.colorNavy
  end if

  i = 0 : while i < m.labels.count()
    if i = m.focus then
      m.labels[i].color = m.colorWhite
    else
      m.labels[i].color = m.colorBlack
    end if
    i = i + 1
  end while

  if m.title <> invalid then
    m.title.color = m.colorBlack
    m.title.text  = "FaithSaver Settings  Saved: " + m.titles[m.selected]
  end if
end sub

sub ShowAbout()
  if not m.aboutLoaded then
    if m.aboutTitle <> invalid then m.aboutTitle.text = "About FaithSaver"
    if m.aboutText  <> invalid then m.aboutText.text  = LoadAboutText()
    m.aboutLoaded = true
  end if
  if m.about <> invalid then m.about.visible = true
  m.aboutVisible = true
end sub

sub HideAbout()
  if m.about <> invalid then m.about.visible = false
  m.aboutVisible = false
end sub

function onKeyEvent(key as String, press as Boolean) as Boolean
  if not press then return false
  k = LCase(key)

  if m.aboutVisible then
    if k = "back" or k = "ok" or k = "options" or k = "info" then
      HideAbout() : return true
    end if
    return true
  end if

  if k = "up" then
    if m.focus > 0 then m.focus = m.focus - 1 : Paint()
    return true
  else if k = "down" then
    if m.focus < m.titles.count() - 1 then m.focus = m.focus + 1 : Paint()
    return true
  else if k = "ok" then
    m.selected = m.focus : Paint()
    SaveSelection(m.keys[m.selected])
    return true
  else if k = "back" then
    m.top.close = true
    return true
  else if k = "options" or k = "info" then
    if m.aboutVisible then HideAbout() else ShowAbout()
    return true
  end if

  return false
end function

sub SaveSelection(key as String)
  reg = CreateObject("roRegistrySection","FaithSaver")
  reg.Write("category", LCase(key))
  reg.Flush()
end sub

function LoadAboutText() as String
  path = "pkg:/README.md"
  fs = CreateObject("roFileSystem")
  if fs.Exists(path) then
    p = CreateObject("roByteArray")
    if p.ReadFile(path) then
      return p.ToAsciiString()
    end if
  end if
  return "FaithSaver rotates beautiful imagery. Select a category and press OK to save."
end function
