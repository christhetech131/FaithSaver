' ===== SettingsScene controller =====
sub init()
  m.bg     = m.top.findNode("bg")
  m.scrim  = m.top.findNode("scrim")
  m.header = m.top.findNode("header")
  m.list   = m.top.findNode("list")

  print "[FS][SettingsScene] init: bg="; (m.bg <> invalid); ", scrim="; (m.scrim <> invalid); ", header="; (m.header <> invalid); ", list="; (m.list <> invalid)

  if m.list <> invalid then
    m.list.itemSpacing = [0, 8]
    m.list.AddReplace("drawFocusFeedback", false)
    m.list.focusable = true
    m.list.setFocus(true)
    print "[FS][SettingsScene] list.itemSpacing="; m.list.itemSpacing; ", drawFocusFeedback="; m.list.drawFocusFeedback
  end if

  m.categories = [
    "Scenery", "Space", "Spring", "Summer", "Textures",
    "Winter", "Seasonal", "Animals", "Fall", "Geology"
  ]

  content = CreateObject("roSGNode", "ContentNode")
  for each title in m.categories
    node = CreateObject("roSGNode", "ContentNode")
    node.title = title
    content.appendChild(node)
  end for
  if m.list <> invalid then m.list.content = content
  print "[FS][SettingsScene] content assigned (count= "; m.categories.count(); ")"

  stored = ReadCategory()
  if stored = "" then stored = "Scenery"
  idx = findIndexCI(m.categories, stored)
  if m.categories.count() > 0 then
    if idx < 0 or idx >= m.categories.count() then idx = 0
    if m.list <> invalid then
      m.list.jumpToItem = idx
      m.list.setFocus(true)
    end if
    m.currentSelection = m.categories[idx]
  else
    idx = -1
    m.currentSelection = ""
  end if
  updateHeader(idx, m.currentSelection)

  if m.list <> invalid then m.list.ObserveField("itemFocused", "onListFocusChanged")
end sub

sub onListFocusChanged()
  if m.list = invalid then return
  i = m.list.itemFocused
  print "[FS][SettingsScene] itemFocused -> "; i
  if i < 0 then return
  updateHeader(i, getSelectedCurrent())
end sub

function onKeyEvent(key as string, press as boolean) as boolean
  if not press then return false

  if key = "back" or key = "home" then
    m.top.closeRequested = true
    return true
  else if key = "ok" then
    if m.list = invalid then return false
    i = m.list.itemFocused
    if i < 0 then i = 0
    if i >= 0 and i < m.categories.count() then
      sel = m.categories[i]
      SaveCategory(sel)
      m.currentSelection = sel
      updateHeader(i, sel)
    end if
    return true
  end if

  return false
end function

' ---- helpers ----
function getSelectedCurrent() as string
  if m.currentSelection <> invalid and Type(m.currentSelection) = "String" then
    return m.currentSelection
  end if

  stored = ReadCategory()
  if stored = "" then return ""

  idx = findIndexCI(m.categories, stored)
  if idx >= 0 and idx < m.categories.count() then
    result = m.categories[idx]
    m.currentSelection = result
    return result
  end if

  result = capitalizeCategory(stored)
  if result <> "" then m.currentSelection = result
  return result
end function

function findIndexCI(arr as object, val as string) as integer
  if arr = invalid then return -1
  lv = lcase(val)
  for i = 0 to arr.count() - 1
    if lcase(arr[i]) = lv then return i
  end for
  return -1
end function

function capitalizeCategory(value as string) as string
  if value = invalid then return ""
  if value = "" then return ""

  lowerValue = lcase(value)
  firstChar = left(lowerValue, 1)
  rest = ""
  if Len(lowerValue) > 1 then rest = mid(lowerValue, 1)

  return ucase(firstChar) + rest
end function

sub updateHeader(focusedIdx as integer, selectedVal as string)
  display = "(none)"
  if selectedVal <> "" then
    display = selectedVal
  end if

  if m.header <> invalid then
    m.header.text = "Current: " + display
    print "[FS][SettingsScene] header='"; m.header.text; "'"
  else
    print "[FS][SettingsScene] header update skipped (header invalid)"
  end if
end sub

function ReadCategory() as string
  sec = CreateObject("roRegistrySection", "FaithSaver")
  if sec = invalid then return ""
  v = sec.Read("category")
  if v = invalid then return ""
  return lcase(v)
end function

sub SaveCategory(cat as string)
  lc = lcase(cat)
  sec = CreateObject("roRegistrySection", "FaithSaver")
  if sec <> invalid then
    sec.Write("category", lc)
    flushed = sec.Flush()
    flushText = "false"
    if flushed then flushText = "true"
    print "[FS][SettingsScene][REG] write 'category'="; lc; " flush="; flushText
  else
    print "[FS][SettingsScene][REG] write 'category'="; lc; " flush=false (section invalid)"
  end if
end sub
