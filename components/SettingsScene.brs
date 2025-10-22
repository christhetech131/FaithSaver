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
    "Scenery","Space","Spring","Summer","Textures",
    "Winter","Seasonal","Animals","Fall","Geology"
  ]

  content = CreateObject("roSGNode", "ContentNode")
  for each title in m.categories
    node = CreateObject("roSGNode", "ContentNode")
    node.title = title
    content.appendChild(node)
  end for

  if m.list <> invalid then m.list.content = content
  print "[FS][SettingsScene] content assigned (count="; m.categories.count(); ")"

  storedLower = ReadCategory()
  if storedLower = "" then storedLower = "scenery"

  storedIndex = findIndexCI(m.categories, storedLower)
  if storedIndex < 0 then storedIndex = 0

  m.savedIndex = storedIndex
  m.savedValue = m.categories[storedIndex]

  if m.list <> invalid then
    m.list.jumpToItem = storedIndex
    m.list.ObserveField("itemFocused", "onListFocusChanged")
    m.list.ObserveField("itemSelected", "onListItemSelected")
  end if

  updateHeader(storedIndex, m.savedValue)
end sub

sub onListFocusChanged()
  if m.list = invalid then return
  focusedIndex = m.list.itemFocused
  print "[FS][SettingsScene] itemFocused -> "; focusedIndex
  if focusedIndex < 0 then return
  updateHeader(focusedIndex, getSelectedCurrent())
end sub

sub onListItemSelected()
  if m.list = invalid then return
  selectedIndex = m.list.itemSelected
  print "[FS][SettingsScene] itemSelected -> "; selectedIndex
  commitSelection(selectedIndex)
end sub

function onKeyEvent(key as string, press as boolean) as boolean
  if not press then return false

  if key = "back" or key = "home" then
    m.top.closeRequested = true
    return true
  else if key = "ok" then
    if m.list = invalid then return false
    focusedIndex = m.list.itemFocused
    print "[FS][SettingsScene] onKeyEvent ok (focusedIndex="; focusedIndex; ")"
    commitSelection(focusedIndex)
    return true
  end if

  return false
end function

sub commitSelection(idx as integer)
  if m.categories = invalid then return
  if idx < 0 or idx >= m.categories.count() then return

  selectedName = m.categories[idx]
  SaveCategory(selectedName)
  m.savedIndex = idx
  m.savedValue = selectedName
  updateHeader(idx, selectedName)
end sub

' ---- helpers ----
function getSelectedCurrent() as string
  if m.savedValue <> invalid then return m.savedValue
  return ""
end function

function findIndexCI(arr as object, val as string) as integer
  if arr = invalid then return -1
  lookup = lcase(val)
  for i = 0 to arr.count() - 1
    if lcase(arr[i]) = lookup then return i
  end for
  return -1
end function

sub updateHeader(focusedIdx as integer, selectedVal as string)
  displayValue = "(none)"
  if selectedVal <> "" then
    displayValue = selectedVal
  end if
  if m.header <> invalid then
    m.header.text = "Current: " + displayValue
    print "[FS][SettingsScene] header='"; m.header.text; "' (focusedIdx="; focusedIdx; ")"
  else
    print "[FS][SettingsScene] header update skipped (header invalid)"
  end if
end sub

function ReadCategory() as string
  section = CreateObject("roRegistrySection", "FaithSaver")
  if section = invalid then return ""
  value = section.Read("category")
  if value = invalid then return ""
  return value
end function

sub SaveCategory(cat as string)
  lower = lcase(cat)
  section = CreateObject("roRegistrySection", "FaithSaver")
  if section <> invalid then
    section.Write("category", lower)
    section.Flush()
    print "[FS][SettingsScene][REG] write 'category'="; lower; " flush=true"
  else
    print "[FS][SettingsScene][REG] write 'category'="; lower; " flush=false (section invalid)"
  end if
end sub
