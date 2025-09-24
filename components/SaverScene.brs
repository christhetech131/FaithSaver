' SaverScene — preview = offline rotation; saver = GitHub feed with offline fallback
' Uses ImageFeedTask to fetch index.json on a background thread.

sub init()
  m.img  = m.top.findNode("img")
  m.tick = m.top.findNode("tick")
  m.hint = m.top.findNode("hint")

  ' Observe image load events to gracefully skip missing files
  m.img.observeField("loadStatus","onImgStatus")

  m.uris = CreateObject("roArray", 20, true)
  m.idx  = 0
  m.feed = invalid

  if LCase(m.top.mode) = "preview" then
    ' Show ALL offline images so preview never appears black
    m.hint.text = "Preview — Up/Down to cycle  •  Back to exit"
    m.tick.duration = 5.0
    m.uris = OfflineAllUris()
    if m.uris.count() = 0 then m.uris.push("pkg:/images/offline/default.jpg")
    SetImage(0)
  else
    ' Real saver: start with the saved category offline image(s),
    ' then swap to remote feed when the task returns.
    m.hint.text = ""
    m.tick.duration = 300.0   ' 5 minutes
    m.uris = OfflineForSaved()
    if m.uris.count() = 0 then m.uris.push("pkg:/images/offline/default.jpg")
    SetImage(0)
    StartFeedTask()
  end if

  m.tick.observeField("fire","onTick")
  m.tick.control = "start"
  m.top.setFocus(true)
end sub

' Build an array of ALL offline images so preview always has content
function OfflineAllUris() as Object
  base = "pkg:/images/offline/"
  arr = CreateObject("roArray", 16, true)
  arr.push(base + "animals.jpg")
  arr.push(base + "fall.jpg")
  arr.push(base + "geology.jpg")
  arr.push(base + "scenery.jpg")
  arr.push(base + "space.jpg")
  arr.push(base + "spring.jpg")
  arr.push(base + "summer.jpg")
  arr.push(base + "textures.jpg")
  arr.push(base + "winter.jpg")
  arr.push(base + "default.jpg")
  return arr
end function

' Offline URIs for the saved category (plus default)
function OfflineForSaved() as Object
  reg = CreateObject("roRegistrySection","FaithSaver")
  sel = reg.Read("category")
  if sel = invalid then sel = ""
  sel = LCase(sel)
  if sel = "seasonal" or sel = "" then sel = CurrentSeasonName()
  if sel = "" then sel = "animals"

  base = "pkg:/images/offline/"
  arr = CreateObject("roArray", 4, true)
  arr.push(base + sel + ".jpg")
  arr.push(base + "default.jpg")
  return arr
end function

' Launch the background task that fetches the GitHub index.json
sub StartFeedTask()
  reg = CreateObject("roRegistrySection","FaithSaver")
  sel = reg.Read("category")
  if sel = invalid then sel = ""

  m.feed = CreateObject("roSGNode","ImageFeedTask")
  m.feed.category = sel
  m.feed.observeField("result","onFeed")
  m.top.appendChild(m.feed)
  print "SaverScene StartFeedTask -> category="; sel
  m.feed.control = "run"
end sub

' Called when ImageFeedTask returns. If we have remote URIs, swap to them.
sub onFeed()
  if m.feed <> invalid and m.feed.result <> invalid then
    r = m.feed.result
    if r.uris <> invalid and r.uris.count() > 0 then
      m.uris = r.uris
      m.idx = 0
      SetImage(0)
      print "SaverScene onFeed -> swapping to remote URIs count="; m.uris.count()
    end if
  end if
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

  m.idx = i

  uri = m.uris[m.idx]
  print "SaverScene SetImage -> idx="; m.idx; " uri="; uri
  m.img.visible = true
  m.img.uri = uri
end sub

' Skip to next image if a uri fails to load
sub onImgStatus()
  print "Poster loadStatus="; m.img.loadStatus; " idx="; m.idx; " uri="; m.img.uri
  if m.img.loadStatus = "failed" then
    SetImage(m.idx + 1)
  end if
end sub

' Timer tick → advance
sub onTick()
  SetImage(m.idx + 1)
end sub

' Basic navigation for preview
function onKeyEvent(key as String, press as Boolean) as Boolean
  if not press then return false

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
    ' no-op in preview
    return true
  end if

  return false
end function
