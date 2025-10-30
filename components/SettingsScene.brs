' SettingsScene — Labels + highlight bar; registry save; About overlay

sub init()
  m.menu        = m.top.findNode("menu")
  m.title       = m.top.findNode("title")
  m.hl          = m.top.findNode("hl")
  m.sepHeader   = m.top.findNode("sepHeader")
  m.sepAbout    = m.top.findNode("sepAbout")
  m.overlayHost = m.top.findNode("overlayHost")

  ' colors (0xRRGGBBAA)
  m.colorNavy  = &h103A57FF
  m.colorWhite = &hFFFFFFFF
  m.colorBlack = &h000000FF

  ' layout
  m.rowH  = 72
  m.rowW  = 1680
  m.textX = 16

  BuildOptions()

  ' registry (guarded)
  m.savedKey = "animals"
  sec = CreateObject("roRegistrySection","FaithSaver")
  if sec <> invalid then
    saved = sec.Read("category")
    if saved <> invalid and saved <> "" then m.savedKey = LCase(saved)
  end if

  ' resolve saved index
  m.selected = 0
  i = 0
  while i < m.keys.count()
    if LCase(m.keys[i]) = m.savedKey then
      m.selected = i
      exit while
    end if
    i = i + 1
  end while

  ' initial focus = saved
  m.focus = m.selected

  ' separator above About row
  if m.sepAbout <> invalid then
    aboutY = 144 + (m.rowH * (m.titles.count() - 1)) - 8
    m.sepAbout.translation = [96, aboutY]
    m.sepAbout.visible = true
  end if

  ' header
  if m.sepHeader <> invalid then m.sepHeader.visible = true
  if m.title <> invalid then
    m.title.visible = true
    m.title.opacity = 1.0
  end if

  UpdateTitle()
  Paint()

  m.top.focusable = true
  m.top.setFocus(true)

  ' NOTE: Do NOT call m.top.signalBeacon("AppLaunchComplete") here.
  ' The system emits AppLaunchComplete automatically when the first frame renders.

  print "SettingsScene.init"
  print "Saved key: " ; m.savedKey
  print "Initial focus index:  " ; m.focus
end sub

sub BuildOptions()
  ' order: Animals, Fall, Geology, Scenery, Seasonal, Space, Spring, Summer, Textures, Winter, About
  m.titles = CreateObject("roArray", 11, true)
  m.titles.push("Animals")
  m.titles.push("Fall")
  m.titles.push("Geology")
  m.titles.push("Scenery")
  season = CurrentSeasonName()
  m.titles.push("Seasonal (auto - " + season + ")")
  m.titles.push("Space")
  m.titles.push("Spring")
  m.titles.push("Summer")
  m.titles.push("Textures")
  m.titles.push("Winter")
  m.titles.push("About")

  m.keys = CreateObject("roArray", 11, true)
  m.keys.push("animals")
  m.keys.push("fall")
  m.keys.push("geology")
  m.keys.push("scenery")
  m.keys.push("seasonal")
  m.keys.push("space")
  m.keys.push("spring")
  m.keys.push("summer")
  m.keys.push("textures")
  m.keys.push("winter")
  m.keys.push("about")

  ' build list labels
  i = 0 : y = 0
  m.labels = CreateObject("roArray", m.titles.count(), true)
  while i < m.titles.count()
    lbl = CreateObject("roSGNode","Label")
    lbl.translation = [m.textX, y + 16]
    lbl.width  = m.rowW
    lbl.height = m.rowH
    lbl.horizAlign = "left"
    lbl.vertAlign  = "center"
    lbl.text  = m.titles[i]
    lbl.color = m.colorBlack
    m.menu.appendChild(lbl)
    m.labels.push(lbl)
    y = y + m.rowH
    i = i + 1
  end while
end sub

function CurrentSeasonName() as String
  dt = CreateObject("roDateTime")
  mth = dt.GetMonth()
  if mth = 12 or mth <= 2 then return "winter"
  if mth >= 3 and mth <= 5 then return "spring"
  if mth >= 6 and mth <= 8 then return "summer"
  return "fall"
end function

sub UpdateTitle()
  display = "Unknown"
  i = 0
  while i < m.keys.count()
    if LCase(m.keys[i]) = m.savedKey then
      display = m.titles[i]
      exit while
    end if
    i = i + 1
  end while

  if m.title <> invalid then
    m.title.visible = true
    m.title.opacity = 1.0
    if m.savedKey <> "about" then
      m.title.color = m.colorBlack
      m.title.text  = "FaithSaver Settings — Saved: " + display
    else
      m.title.text  = "FaithSaver Settings"
    end if
    print "[FaithSaver][Settings] Header set to: " + m.title.text
  else
    print "[FaithSaver][Settings] ERROR: title node not found"
  end if
end sub

sub Paint()
  ' highlight bar
  newY = m.focus * m.rowH
  m.hl.translation = [96, 144 + newY]
  m.hl.color = m.colorNavy
  m.hl.opacity = 1.0

  ' label colors
  i = 0
  while i < m.labels.count()
    if i = m.focus then
      m.labels[i].color = m.colorWhite
    else
      m.labels[i].color = m.colorBlack
    end if
    m.labels[i].opacity = 1.0
    i = i + 1
  end while

  UpdateTitle()
end sub

sub ShowAbout()
  if m.overlayHost = invalid then return
  while m.overlayHost.getChildCount() > 0
    m.overlayHost.removeChildIndex(m.overlayHost.getChildCount() - 1)
  end while
  overlay = CreateObject("roSGNode", "AboutOverlay")
  if overlay = invalid then return
  overlay.ObserveField("close", "onOverlayClose")
  m.overlayHost.appendChild(overlay)
  m.overlayHost.visible = true
  overlay.setFocus(true)
end sub

sub onOverlayClose()
  if m.overlayHost = invalid then return
  while m.overlayHost.getChildCount() > 0
    m.overlayHost.removeChildIndex(m.overlayHost.getChildCount() - 1)
  end while
  m.overlayHost.visible = false
  m.top.setFocus(true)
end sub

function onKeyEvent(key as string, press as boolean) as boolean
  if not press then return false
  key = LCase(key)
  print "[FaithSaver][Settings] onKeyEvent key=" + key

  ' Block keys while About overlay is open
  if m.overlayHost <> invalid and m.overlayHost.visible and m.overlayHost.getChildCount() > 0 then
    return true
  end if

  c = m.titles.count()

  if key = "up" then
    ' wrap-around navigation
    m.focus = (m.focus + c - 1) mod c
    Paint()
    return true

  else if key = "down" then
    ' wrap-around navigation
    m.focus = (m.focus + 1) mod c
    Paint()
    return true

  else if key = "ok" then
    if m.keys[m.focus] = "about" then
      ShowAbout()
      return true
    end if

    m.selected = m.focus
    m.savedKey = LCase(m.keys[m.selected])

    sec = CreateObject("roRegistrySection","FaithSaver")
    if sec <> invalid then
      sec.Write("category", m.savedKey)
      sec.Flush()
      print "[FaithSaver][Settings] Saved category=" + m.savedKey
    else
      print "[FaithSaver][Settings] ERROR: registry section invalid"
    end if

    UpdateTitle()
    Paint()
    return true

  else if key = "back" then
    return false
  end if

  return false
end function
