' ===== SettingsScene controller =====
sub init()
  m.bg     = m.top.findNode("bg")
  m.scrim  = m.top.findNode("scrim")
  m.header = m.top.findNode("header")
  m.list   = m.top.findNode("list")

  ' Ensure spacing & use our own focus visuals (disable Roku pink)
  if m.list <> invalid then
    m.list.itemSpacing = [0, 8]
    m.list.AddReplace("drawFocusFeedback", false)
    m.list.focusable = true
    m.list.setFocus(true)
  end if
  print "[FS][SettingsScene] list.itemSpacing="; m.list.itemSpacing; ", drawFocusFeedback="; getFieldSafe(m.list, "drawFocusFeedback")

  ' Display strings (capitalized)
  m.categories = [ "Scenery","Space","Spring","Summer","Textures","Winter","Seasonal","Animals","Fall","Geology" ]

  content = CreateObject("roSGNode", "ContentNode")
  for each t in m.categories
    n = CreateObject("roSGNode", "ContentNode")
    n.title = t
    content.appendChild(n)
  end for
  m.list.content = content
  print "[FS][SettingsScene] content assigned (count= "; m.categories.count(); ")"

  ' Restore selection
  cur = ReadCategory()
  if cur = "" then cur = "Scenery"
  idx = findIndexCI(m.categories, cur)
  if idx < 0 then idx = 0
  m.list.jumpToItem = idx

  updateHeader(idx, m.categories[idx])

  ' React to focus change
  m.list.ObserveField("itemFocused", "onListFocusChanged")

  print "[FS][SettingsScene] init done; selected="; m.categories[idx]; " startIdx="; idx
end sub

sub onListFocusChanged()
  i = m.list.itemFocused
  if i < 0 then return
  updateHeader(i, getSelectedCurrent())
end sub

function onKeyEvent(key as string, press as boolean) as boolean
  if not press then return false

  if key = "back" or key = "home" then
    m.top.closeRequested = true
    return true
  else if key = "ok" then
    i = m.list.itemFocused : if i < 0 then i = 0
    sel = m.categories[i]
    SaveCategory(sel)
    print "[FS][SettingsScene][REG] write 'category'="; lcase(sel); " flush=true"
    updateHeader(i, sel)
    print "[FS][SettingsScene] saved selection="; lcase(sel); " (idx="; i; ")"
    return true
  end if

  return false
end function

' ---- helpers ----
function getSelectedCurrent() as string
  v = ReadCategory()
  if v = "" then return ""
  i = findIndexCI(m.categories, v)
  if i >= 0 then return m.categories[i]
  return v
end function

function findIndexCI(arr as object, val as string) as integer
  lv = lcase(val)
  for i = 0 to arr.count()-1
    if lcase(arr[i]) = lv then return i
  end for
  return -1
end function

sub updateHeader(focusedIdx as integer, selectedVal as string)
  curr = "(none)"
  if selectedVal <> "" then curr = selectedVal
  if m.header <> invalid then m.header.text = "Current: " + curr
  print "[FS][SettingsScene] header='"; m.header.text; "'"
end sub

function ReadCategory() as string
  sec = CreateObject("roRegistrySection", "FaithSaver")
  if sec = invalid then return ""
  v = sec.Read("category") : if v = invalid then return ""
  return v
end function

sub SaveCategory(cat as string)
  sec = CreateObject("roRegistrySection", "FaithSaver")
  sec.Write("category", lcase(cat))
  sec.Flush()
end sub

function getFieldSafe(n as object, f as string) as dynamic
  if n <> invalid and n.DoesExist(f) then return n[f]
  return invalid
end function
