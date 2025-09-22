' FaithSaver settings: 10 options (Seasonal + 9 categories)
sub init()
  m.list  = m.top.findNode("list")
  m.title = m.top.findNode("title")
  m.hint  = m.top.findNode("hint")

  ' Build menu
  m.options = BuildOptionsWithSeason()
  root = CreateObject("roSGNode","ContentNode")
  for each opt in m.options
    n = CreateObject("roSGNode","ContentNode")
    n.title = opt.title
    root.appendChild(n)
  end for
  m.list.content = root

  ' Make sure the list can be selected via OK
  m.list.selectable = true
  m.list.observeField("itemSelected", "onItemSelected")
  m.list.observeField("itemFocused",  "onItemFocused")

  ' Pre-select saved choice
  reg = CreateObject("roRegistrySection","FaithSaver")
  saved = LCase(reg.Read("category"))
  if saved = invalid or saved = "" then saved = "animals"
  for i = 0 to m.options.count()-1
    if LCase(m.options[i].key) = saved then
      m.list.jumpToItem = i
      exit for
    end if
  end for

  ' Ensure keyboard focus lands on the list
  m.top.setFocus(true)
  m.list.setFocus(true)
end sub

function BuildOptionsWithSeason() as Object
  season = CurrentSeasonName()
  return [
    { title: "Seasonal (auto • " + season + ")", key: "seasonal" },
    { title: "Animals",    key: "animals" },
    { title: "Fall",       key: "fall" },
    { title: "Geology",    key: "geology" },
    { title: "Scenery",    key: "scenery" },
    { title: "Space",      key: "space" },
    { title: "Spring",     key: "spring" },
    { title: "Summer",     key: "summer" },
    { title: "Textures",   key: "textures" },
    { title: "Winter",     key: "winter" }
  ]
end function

function CurrentSeasonName() as string
  mth = CreateObject("roDateTime").GetMonth()
  if mth = 3 or mth = 4 or mth = 5 then return "spring"
  if mth = 6 or mth = 7 or mth = 8 then return "summer"
  if mth = 9 or mth = 10 or mth = 11 then return "fall"
  return "winter"
end function

sub onItemSelected()
  idx = m.list.itemSelected
  if idx < 0 or idx >= m.options.count() then return

  choice = m.options[idx].key
  reg = CreateObject("roRegistrySection","FaithSaver")
  reg.Write("category", choice)
  reg.Flush()

  m.title.text = "Saved: " + m.options[idx].title + "   (Back to close)"
end sub

sub onItemFocused()
  idx = m.list.itemFocused
  if idx < 0 or idx >= m.options.count() then return
  opt = m.options[idx]
  if LCase(opt.key) = "seasonal" then
    m.hint.text = "Auto-selects by date → " + CurrentSeasonName() + "   (OK = Save)"
  else
    m.hint.text = "Category: " + opt.title + "   (OK = Save)"
  end if
end sub

' Make Back exit settings. Return TRUE to consume the key.
function onKeyEvent(key as string, press as boolean) as boolean
  if not press then return false
  if key = "back" then
    m.top.close = true
    return true
  end if
  return false
end function
