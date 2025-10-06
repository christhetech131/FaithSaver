sub init()
  m.bg        = m.top.findNode("bg")
  m.title     = m.top.findNode("title")
  m.focusBar  = m.top.findNode("focusBar")
  m.list      = m.top.findNode("listGroup")
  m.aboutGrp  = m.top.findNode("aboutGroup")
  m.aboutText = m.top.findNode("aboutText")

  m.options = [
    "animals", "fall", "geology", "scenery", "space",
    "spring", "summer", "textures", "winter", "seasonal"
  ]

  m.rows = []
  for i = 0 to m.options.count() - 1
    id = "row" + i.tostr()
    m.rows.push(m.top.findNode(id))
  end for

  current = normalizeCategory(m.top.category)
  m.sel = 0
  for i = 0 to m.options.count() - 1
    if m.options[i] = current then
      m.sel = i
      exit for
    end if
  end for

  m.top.ObserveField("keyEvent", "onKeyEvent")

  applyFocus()
  updateTitle()
end sub

function onKeyEvent(key as String, press as Boolean) as Boolean
  if not press then return false

  lowerKey = LCase(key)

  if lowerKey = "back" then
    m.top.close = true
    return true
  else if lowerKey = "up" then
    adjustSelection(-1)
    return true
  else if lowerKey = "down" then
    adjustSelection(1)
    return true
  else if lowerKey = "ok" then
    saveSelection()
    if m.sel >= 0 and m.sel < m.options.count() then
      m.top.category = m.options[m.sel]
    end if
    m.top.saved = true
    m.top.close = true
    return true
  else if lowerKey = "options" or lowerKey = "info" then
    toggleAbout()
    return true
  end if

  return false
end function

sub adjustSelection(delta as Integer)
  if m.options.count() = 0 then return
  m.sel = (m.sel + delta + m.options.count()) mod m.options.count()
  applyFocus()
  updateTitle()
end sub

sub applyFocus()
  for i = 0 to m.rows.count() - 1
    node = m.rows[i]
    if node <> invalid then
      if i = m.sel then
        node.color = "0xFFFFFFFF"
      else
        node.color = "0xCCFFFFFF"
      end if
    end if
  end for

  if m.focusBar <> invalid then
    y = 320 + (m.sel * 70)
    m.focusBar.translation = [140, y]
  end if
end sub

sub updateTitle()
  if m.title <> invalid then
    m.title.text = "Category: " + m.options[m.sel]
  end if
end sub

sub saveSelection()
  if m.sel < 0 or m.sel >= m.options.count() then return

  sec = CreateObject("roRegistrySection", "FaithSaver")
  if sec = invalid then return

  reg = sec.GetInterface("ifRegistrySection")
  if reg = invalid then return

  cat = m.options[m.sel]
  if type(cat) <> "String" then return

  normalized = LCase(TrimString(cat))
  if normalized = "" then return

  success = reg.Write("category", normalized)
  if success then
    reg.Flush()
  end if
end sub

sub toggleAbout()
  if m.aboutGrp = invalid then return
  m.aboutGrp.visible = not m.aboutGrp.visible
end sub

function TrimString(value as Dynamic) as String
  if type(value) <> "String" then return ""
  return LTrim(RTrim(value))
end function

function normalizeCategory(value as Dynamic) as String
  if type(value) <> "String" then return "animals"
  v = LCase(LTrim(RTrim(value)))
  if v = "" then return "animals"
  return v
end function
