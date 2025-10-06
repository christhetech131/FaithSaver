sub init()
  m.poster = m.top.findNode("imagePoster")
  m.overlay = m.top.findNode("overlayGroup")
  m.timer = CreateObject("roSGNode", "Timer")
  if m.timer <> invalid then
    m.timer.duration = 15
    m.timer.repeat = true
    m.timer.ObserveField("fire", "onTimerFired")
    if m.top <> invalid then
      m.top.appendChild(m.timer)
    end if
  end if

  m.feedTask = invalid
  m.displayList = []
  m.displayIndex = 0
  m.offlineList = []
  m.category = normalizeCategory(m.top.category)
  m.currentMode = normalizeMode(m.top.mode)

  m.top.ObserveField("mode", "onModeChanged")
  m.top.ObserveField("category", "onCategoryChanged")
  m.top.ObserveField("keyEvent", "onKeyEvent")

  showFirstOfflineImage()
  startFeedTask()
  applyMode()
  startTimerIfPossible()

  print "[FaithSaver] SaverScene ready (mode=" + m.currentMode + ", category=" + m.category + ")"
end sub

sub onModeChanged()
  m.currentMode = normalizeMode(m.top.mode)
  applyMode()
end sub

sub onCategoryChanged()
  m.category = normalizeCategory(m.top.category)
  showFirstOfflineImage()
  startFeedTask()
end sub

sub applyMode()
  if m.overlay <> invalid then
    m.overlay.visible = (m.currentMode = "preview")
  end if
end sub

sub showFirstOfflineImage()
  m.offlineList = buildOfflineList(m.category)
  if m.offlineList.count() = 0 and m.category <> "animals" then
    m.category = "animals"
    m.offlineList = buildOfflineList(m.category)
  end if

  if m.offlineList.count() = 0 then
    fallback = "pkg:/images/FaithSaver-Splash-1920x1080.jpg"
    setPosterUri(fallback)
    m.displayList = [ fallback ]
    m.displayIndex = 0
  else
    setPosterUri(m.offlineList[0])
    m.displayList = []
    for each uri in m.offlineList
      m.displayList.push(uri)
    end for
    m.displayIndex = 0
  end if

  startTimerIfPossible()
end sub

sub startFeedTask()
  if m.feedTask <> invalid then
    m.feedTask.UnobserveField("items")
    m.feedTask.UnobserveField("status")
    m.feedTask.control = "stop"
    if m.top <> invalid then
      m.top.removeChild(m.feedTask)
    end if
  end if

  m.feedTask = CreateObject("roSGNode", "ImageFeedTask")
  if m.feedTask = invalid then return

  if m.top <> invalid then
    m.top.appendChild(m.feedTask)
  end if

  m.feedTask.ObserveField("items", "onFeedItemsChanged")
  m.feedTask.ObserveField("status", "onFeedStatusChanged")
  m.feedTask.category = m.category
  m.feedTask.control = "run"
end sub

sub onFeedItemsChanged()
  if m.feedTask = invalid then return
  items = m.feedTask.items
  if type(items) <> "roArray" then return

  addItemsToDisplay(items)
end sub

sub onFeedStatusChanged()
  ' No-op but keep observer to avoid warnings when status updates
end sub

sub addItemsToDisplay(items as Object)
  if type(items) <> "roArray" then return
  if type(m.displayList) <> "roArray" then return

  seen = {}
  for each existing in m.displayList
    if type(existing) = "String" then
      seen[LCase(existing)] = true
    end if
  end for

  for each offlineUri in m.offlineList
    lu = LCase(offlineUri)
    if not seen.doesExist(lu) then
      m.displayList.push(offlineUri)
      seen[lu] = true
    end if
  end for

  for each item in items
    if type(item) = "String" then
      trimmed = TrimString(item)
      if trimmed <> "" then
        key = LCase(trimmed)
        if not seen.doesExist(key) then
          m.displayList.push(trimmed)
          seen[key] = true
        end if
      end if
    end if
  next

  startTimerIfPossible()
end sub

sub startTimerIfPossible()
  if m.timer = invalid then return
  if type(m.displayList) <> "roArray" then return
  if m.displayList.count() = 0 then return
  m.timer.control = "start"
end sub

sub onTimerFired()
  if type(m.displayList) <> "roArray" then return
  if m.displayList.count() = 0 then return

  m.displayIndex = (m.displayIndex + 1) mod m.displayList.count()
  uri = m.displayList[m.displayIndex]
  setPosterUri(uri)
end sub

function onKeyEvent(key as String, press as Boolean) as Boolean
  if not press then return false

  lowerKey = LCase(key)

  if m.currentMode = "saver" then
    m.top.close = true
    return true
  else if m.currentMode = "preview" then
    if lowerKey = "back" or lowerKey = "up" or lowerKey = "down" then
      m.top.close = true
      return true
    end if
  end if

  return false
end function

sub setPosterUri(uri as Dynamic)
  if m.poster = invalid then return
  if type(uri) <> "String" or uri = "" then return
  m.poster.uri = uri
  m.poster.visible = true
end sub

function buildOfflineList(cat as String) as Object
  list = []
  if type(cat) <> "String" or cat = "" then return list

  base = "pkg:/images/offline/" + cat + "/"
  for i = 1 to 24
    idx = zeroPad(i)
    path = base + cat + "-" + idx + ".jpg"
    ba = CreateObject("roByteArray")
    if ba = invalid then exit for
    if ba.ReadFile(path) then
      if ba.Count() > 0 then
        list.push(path)
      end if
    else if i > 9 then
      exit for
    end if
  end for

  return list
end function

function zeroPad(i as Integer) as String
  if i < 10 then
    return "0" + i.toStr()
  end if
  return i.toStr()
end function

function TrimString(s as Dynamic) as String
  if type(s) <> "String" then return ""
  return LTrim(RTrim(s))
end function

function normalizeMode(value as Dynamic) as String
  if type(value) <> "String" then return "preview"
  v = LCase(value)
  if v = "screensaver" then return "saver"
  if v = "saver" then return "saver"
  return "preview"
end function

function normalizeCategory(value as Dynamic) as String
  if type(value) <> "String" then return "animals"
  v = LCase(TrimString(value))
  if v = "" then return "animals"
  return v
end function
