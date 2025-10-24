' SettingsScene — Labels + highlight bar; registry save; About overlay

sub init()
  m.bg    = m.top.findNode("bg")
  m.menu  = m.top.findNode("menu")
  m.title = m.top.findNode("title")
  m.hl    = m.top.findNode("hl")
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

  ' load registry with guard; default animals
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

  ' focus begins at saved selection
  m.focus = m.selected
  Paint()

  ' Ensure focus for key handling
  m.top.setFocus(true)

  print "SettingsScene.init"
  print "Saved key: " ; m.savedKey
  print "Initial focus index:  " ; m.focus
end sub

sub BuildOptions()
  ' titles (add About at end)
  m.titles = CreateObject("roArray", 11, true)
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
  m.titles.push("About")

  ' keys (parallel) — use "about" sentinel for the last row
  m.keys = CreateObject("roArray", 11, true)
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
  m.keys.push("about")

  ' build label nodes
  i = 0
  y = 0
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

sub Paint()
  ' highlight bar stays in sync with focus
  newY = m.focus * m.rowH
  m.hl.translation = [96, 144 + newY]
  m.hl.color = m.colorNavy
  m.hl.opacity = 1.0

  ' toggle label colors
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

  ' Title shows saved selection if not on About
  if m.keys[m.selected] <> "about" then
    m.title.color = m.colorBlack
    m.title.text  = "FaithSaver Settings — Saved: " + m.titles[m.selected]
  else
    m.title.text  = "FaithSaver Settings"
  end if
end sub

' Open the About overlay as a child under overlayHost
sub ShowAbout()
  if m.overlayHost = invalid then return
  ' Clear any previous overlay
  while m.overlayHost.getChildCount() > 0
    m.overlayHost.removeChildIndex(m.overlayHost.getChildCount() - 1)
  end while
  overlay = CreateObject("roSGNode", "AboutOverlay")
  if overlay = invalid then return
  ' Observe close to remove overlay and return focus
  overlay.ObserveField("close", "onOverlayClose")
  m.overlayHost.appendChild(overlay)
  m.overlayHost.visible = true
  overlay.setFocus(true)
end sub

sub onOverlayClose()
  if m.overlayHost = invalid then return
  ' Remove overlay and restore focus to the menu
  while m.overlayHost.getChildCount() > 0
    m.overlayHost.removeChildIndex(m.overlayHost.getChildCount() - 1)
  end while
  m.overlayHost.visible = false
  m.top.setFocus(true)
end sub

function onKeyEvent(key as string, press as boolean) as boolean
  if not press then return false

  ' If overlay is visible, let overlay handle keys (we still swallow here)
  if m.overlayHost <> invalid and m.overlayHost.visible then
    return true
  end if

  if key = "up" then
    if m.focus > 0 then
      m.focus = m.focus - 1
      Paint()
    end if
    return true

  else if key = "down" then
    if m.focus < m.titles.count() - 1 then
      m.focus = m.focus + 1
      Paint()
    end if
    return true

  else if key = "ok" then
    ' If About row selected, open overlay instead of saving
    if m.keys[m.focus] = "about" then
      ShowAbout()
      return true
    end if

    ' Save category choice
    m.selected = m.focus
    sec = CreateObject("roRegistrySection","FaithSaver")
    if sec <> invalid then
      sec.Write("category", LCase(m.keys[m.selected]))
      sec.Flush()
      print "[FaithSaver][Settings] Saved category=" + m.keys[m.selected]
    else
      print "[FaithSaver][Settings] ERROR: registry section invalid"
    end if
    Paint()
    return true

  else if key = "back" then
    ' Let host exit settings (no m.top.close here)
    return false
  end if

  return false
end function
