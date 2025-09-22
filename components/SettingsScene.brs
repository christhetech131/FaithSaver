' Settings UI: choose among 10 options (Seasonal + 9 categories)
' Shows the *current* season inline next to Seasonal.

sub init()
  m.list = m.top.findNode("list")
  m.title = m.top.findNode("title")
  m.hint = m.top.findNode("hint")

  m.options = BuildOptionsWithSeason()
  m.list.ObserveField("itemSelected", "onItemSelected")
  m.list.ObserveField("itemFocused", "onItemFocused")

  root = CreateObject("roSGNode","ContentNode")
  for each opt in m.options
    node = CreateObject("roSGNode","ContentNode")
    node.title = opt.title
    root.appendChild(node)
  end for
  m.list.content = root

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

  m.hint.text = "OK = Select   |   Back = Close"
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
  dt = CreateObject("roDateTime")
  m = dt.GetMonth()
  if m = 3 or m = 4 or m = 5 then return "spring"
  if m = 6 or m = 7 or m = 8 then return "summer"
  if m = 9 or m = 10 or m = 11 then return "fall"
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
  ' Dynamic hint: show what will display if Seasonal is chosen
  opt = m.options[idx]
  if LCase(opt.key) = "seasonal" then
    m.hint.text = "Auto-selects by date → " + CurrentSeasonName() + " (OK = Save)"
  else
    m.hint.text = "Category: " + opt.title + " (OK = Save)"
  end if
end sub

function onKeyEvent(key as string, press as boolean) as boolean
  if press and key = "back" then
    m.top.close = true
    return true
  end if
  return false
end function
