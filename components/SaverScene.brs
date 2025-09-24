' SaverScene — preview = offline rotation; saver = GitHub feed with offline fallback
' Uses ImageFeedTask to fetch index.json on a background thread.

sub init()
  m.img  = m.top.findNode("img")
  m.tick = m.top.findNode("tick")
  m.hint = m.top.findNode("hint")

  m.previewDuration = 5.0       ' seconds
  m.saverDuration   = 300.0     ' 5 minutes per requirements
  m.defaultUri      = "pkg:/images/offline/default.jpg"
  m.previewHint     = "Preview — Up/Down to cycle  •  Back to exit"

  m.mode = ""

  ' Observe image load events to gracefully skip missing files
  m.img.observeField("loadStatus", "onImgStatus")

  m.uris = CreateObject("roArray", 0, true)
  m.idx  = 0
  m.feed = invalid

  m.tick.observeField("fire", "onTick")
  m.tick.control = "stop"

  m.top.observeField("mode", "onModeChanged")
  m.top.observeField("close", "onCloseChanged")
  onModeChanged()

  m.top.setFocus(true)
end sub

sub onModeChanged()
  modeValue = m.top.mode
  if modeValue = invalid then modeValue = ""
  nextMode = LCase(modeValue)
  if nextMode <> "preview" and nextMode <> "screensaver" then
    nextMode = "preview"
  end if

  if nextMode = m.mode then return

  print "SaverScene onModeChanged -> " ; nextMode

  m.mode = nextMode
  m.tick.control = "stop"
  StopFeedTask()

  if m.mode = "preview" then
    ConfigurePreview()
  else
    ConfigureScreensaver()
  end if
end sub

sub ConfigurePreview()
  m.hint.visible = true
  m.hint.text = m.previewHint
  m.tick.duration = m.previewDuration
  m.uris = OfflineAllUris()
  if m.uris.count() = 0 then m.uris.push(m.defaultUri)
  SetImage(0)
  m.tick.control = "start"
end sub

sub ConfigureScreensaver()
  m.hint.text = ""
  m.hint.visible = false
  m.tick.duration = m.saverDuration
  m.uris = OfflineForSaved()
  if m.uris.count() = 0 then m.uris.push(m.defaultUri)
  SetImage(0)
  StartFeedTask()
  m.tick.control = "start"
end sub

sub onCloseChanged()
  if m.top.close = true then
    m.tick.control = "stop"
    StopFeedTask()
  end if
end sub

sub StopFeedTask()
  if m.feed <> invalid then
    m.feed.unobserveField("result")
    m.feed.control = "stop"
    parent = m.feed.getParent()
    if parent <> invalid then parent.removeChild(m.feed)
    m.feed = invalid
  end if
end sub

' Build an array of ALL offline images so preview always has content
function OfflineAllUris() as Object
  base = "pkg:/images/offline/"
  arr = CreateObject("roArray", 12, true)
  arr.push(base + "animals.jpg")
  arr.push(base + "fall.jpg")
  arr.push(base + "geology.jpg")
  arr.push(base + "scenery.jpg")
  arr.push(base + "space.jpg")
  arr.push(base + "spring.jpg")
  arr.push(base + "summer.jpg")
  arr.push(base + "textures.jpg")
  arr.push(base + "winter.jpg")
  arr.push(m.defaultUri)
  return arr
end function

' Offline URIs for the saved category (plus default fallback)
function OfflineForSaved() as Object
  reg = CreateObject("roRegistrySection", "FaithSaver")
  sel = reg.Read("category")
  if sel = invalid then sel = ""
  sel = LCase(sel)
  if sel = "seasonal" or sel = "" then sel = CurrentSeasonName()
  if sel = "" then sel = "animals"

  base = "pkg:/images/offline/"
  arr = CreateObject("roArray", 4, true)
  arr.push(base + sel + ".jpg")
  fallback = m.defaultUri
  if arr[0] <> fallback then arr.push(fallback)
  return arr
end function

' Launch the background task that fetches the GitHub index.json
sub StartFeedTask()
  reg = CreateObject("roRegistrySection", "FaithSaver")
  sel = reg.Read("category")
  if sel = invalid then sel = ""

  StopFeedTask()

  m.feed = CreateObject("roSGNode", "ImageFeedTask")
  m.feed.category = sel
  m.feed.observeField("result", "onFeed")
  m.top.appendChild(m.feed)
  print "SaverScene StartFeedTask -> category=" ; sel
  m.feed.control = "run"
end sub

' Called when ImageFeedTask returns. If we have remote URIs, swap to them.
sub onFeed()
  if m.mode <> "screensaver" then return
  if m.feed = invalid then return

  result = m.feed.result
  if type(result) = "roAssociativeArray" then
    uris = result.uris
    if type(uris) = "roArray" and uris.count() > 0 then
      m.uris = uris
      m.idx = 0
      SetImage(0)
      print "SaverScene onFeed -> swapping to remote URIs count=" ; m.uris.count()
      StopFeedTask()
      return
    end if
  end if

  print "SaverScene onFeed -> remote list empty"
  StopFeedTask()
end sub

function CurrentSeasonName() as String
  dt = CreateObject("roDateTime")
  mth = dt.GetMonth()
  if mth = 3 or mth = 4 or mth = 5 then return "spring"
  if mth = 6 or mth = 7 or mth = 8 then return "summer"
  if mth = 9 or mth = 10 or mth = 11 then return "fall"
  return "winter"
end function

' Display image at index i (wraps around)
sub SetImage(i as Integer)
  if m.uris = invalid then return
  total = m.uris.count()
  if total = 0 then return

  while i < 0
    i = i + total
  end while

  if total > 0 then
    i = i mod total
  end if

  attempts = 0
  idx = i
  while attempts < total
    uri = m.uris[idx]
    if uri <> invalid and uri <> "" then
      m.idx = idx
      print "SaverScene SetImage -> idx=" ; m.idx ; " uri=" ; uri
      m.img.visible = true
      m.img.uri = uri
      return
    end if
    print "SaverScene SetImage -> skipping empty uri at index=" ; idx
    idx = (idx + 1) mod total
    attempts = attempts + 1
  end while

  print "SaverScene SetImage -> no valid URIs available"
end sub

' Skip to next image if a uri fails to load
sub onImgStatus()
  print "Poster loadStatus=" ; m.img.loadStatus ; " idx=" ; m.idx ; " uri=" ; m.img.uri
  if m.img.loadStatus = "failed" then
    SetImage(m.idx + 1)
  end if
end sub

' Timer tick → advance
sub onTick()
  if m.tick.control = "start" then
    SetImage(m.idx + 1)
  end if
end sub

' Basic navigation for preview
function onKeyEvent(key as String, press as Boolean) as Boolean
  if not press then return false

  if m.mode = "preview" then
    if key = "up" then
      SetImage(m.idx - 1)
      return true
    else if key = "down" then
      SetImage(m.idx + 1)
      return true
    else if key = "back" then
      m.top.close = true
      return true
    else if key = "OK" then
      ' no-op in preview, but consume to avoid system beep
      return true
    end if
    return false
  else if m.mode = "screensaver" then
    if key = "back" then
      m.top.close = true
      return true
    end if
    return false
  end if

  return false
end function
