sub init()
  m.list  = m.top.findNode("list")
  m.title = m.top.findNode("title")
  m.hint  = m.top.findNode("hint")

  m.options = BuildOptionsWithSeason()
  root = CreateObject("roSGNode","ContentNode")
  for each opt in m.options
    n = CreateObject("roSGNode","ContentNode")
    n.title = opt.title
    root.appendChild(n)
  end for
  m.list.content = root
  m.list.selectable = true

  m.list.observeField("itemFocused", "onItemFocused")
  m.list.observeField("itemSelected","onItemSelected")

  reg = CreateObject("roRegistrySection","FaithSaver")
  saved = LCase(reg.Read("category"))
  if saved = invalid or saved = "" then saved = "animals"
  for i = 0 to m.options.count()-1
    if LCase(m.options[i].key) = saved then m.list.jumpToItem = i : exit for
  end for

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

sub onItemFocused()
  ' show/hide the blue bar in the visible row component
  for i = 0 to m.list.visibleChildCount()-1
    row = m.list.getChild(i)
    if row <> invalid then row.isFocused = (m.list.itemFocusedVisibleIndex = i)
  end for
end sub

sub onItemSelected()
  idx = m.list.itemSelected
  if idx < 0 or idx >= m.options.count() then return
  choice = m.options[idx].key

  reg = CreateObject("roRegistrySection","FaithSaver")
  reg.Write("category", choice)
  reg.Flush()

  m.title.text = "Saved: " + m.options[idx].title + "   (Back to close)"
end sub

function onKeyEvent(key as string, press as boolean) as boolean
  if not press then return false
  if key = "back" then
    m.top.close = true
    return true
  else if key = "OK" then
    idx = m.list.itemFocused
    if idx >= 0 then
      m.list.itemSelected = idx
      return true
    end if
  end if
  return false
end function
