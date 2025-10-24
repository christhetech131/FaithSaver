' *********** FaithSaver — SaverScene.brs (safe preloading; no gray frames) ***********

sub FSLogSaver(msg as string)
  print "[FaithSaver][Saver] "; ToStr(msg)
end sub

function ToStr(v as dynamic) as string
  if v = invalid then return ""
  t = type(v)
  if t = "Boolean" then return v and "true" or "false"
  if t = "roString" or t = "String" then return v
  if t = "Integer" or t = "LongInteger" then return StrI(v)
  if t = "Float" or t = "Double" then return Str(v)
  if t = "roArray" then return "Array(" + StrI(v.count()) + ")"
  if t = "roAssociativeArray" then return "AA(" + StrI(v.count()) + ")"
  return "<" + t + ">"
end function

' Map the first offline frame by category (fallback default)
function FirstFrameUriForCategory(cat as string) as string
  localMap = {
    "animals":  "pkg:/images/offline/animals.jpg",
    "fall":     "pkg:/images/offline/fall.jpg",
    "geology":  "pkg:/images/offline/geology.jpg",
    "scenery":  "pkg:/images/offline/scenery.jpg",
    "space":    "pkg:/images/offline/space.jpg",
    "spring":   "pkg:/images/offline/spring.jpg",
    "summer":   "pkg:/images/offline/summer.jpg",
    "textures": "pkg:/images/offline/textures.jpg",
    "winter":   "pkg:/images/offline/winter.jpg",
    "seasonal": "pkg:/images/offline/default.jpg",
    "default":  "pkg:/images/offline/default.jpg"
  }
  key = LCase(cat)
  uri = localMap[key]
  if uri = invalid then uri = localMap["default"]
  return uri
end function

' === Node state ===
' m.active     : "A" or "B" — which poster is currently visible
' m.pending    : node (bgA/bgB) that is loading a new image, or invalid
' m.pendingKind: "offlineFirst" | "cycle" (for logging only)

sub init()
  FSLogSaver("init()")

  m.bgA    = m.top.findNode("bgA")
  m.bgB    = m.top.findNode("bgB")
  m.cycler = m.top.findNode("cycler")
  m.feed   = m.top.findNode("feed")

  m.active = "A"
  m.pending = invalid
  m.pendingKind = ""
  m.index = 0
  m.items = CreateObject("roArray", 0, true)

  ' Observe poster loadStatus so we only flip when the target is ready
  if m.bgA <> invalid then m.bgA.ObserveField("loadStatus", "onPosterLoad")
  if m.bgB <> invalid then m.bgB.ObserveField("loadStatus", "onPosterLoad")

  ' Read category (default animals)
  m.category = "animals"
  sec = CreateObject("roRegistrySection", "FaithSaver")
  if sec <> invalid then
    val = sec.Read("category")
    if val <> invalid and val <> "" then m.category = LCase(val)
  end if
  FSLogSaver("Registry category=" + m.category)

  ' Show a guaranteed local splash immediately, visible on A
  if m.bgA <> invalid then
    m.bgA.visible = true
    m.bgA.uri = "pkg:/images/FaithSaver-Splash-1920x1080.jpg"
    FSLogSaver("Initial placeholder on A (splash)")
  end if
  if m.bgB <> invalid then m.bgB.visible = false

  ' Start loading the offline first-frame into the hidden buffer (B) but DO NOT show yet
  offlineUri = FirstFrameUriForCategory(m.category)
  QueueLoadIntoInactive(offlineUri, "offlineFirst")

  ' Wire feed + timer
  if m.feed <> invalid then
    m.feed.category = m.category
    m.feed.ObserveField("items", "onFeedItems")
    m.feed.ObserveField("status", "onFeedStatus")
    m.feed.control = "run"
    FSLogSaver("ImageFeedTask started (category=" + m.category + ")")
  else
    FSLogSaver("ERROR: feed task node not found")
  end if

  if m.cycler <> invalid then
    m.cycler.ObserveField("fire", "onCycle")
    FSLogSaver("cycler wired (duration= " + ToStr(m.cycler.duration) + "s)")
  end if
end sub

' Begin loading a URI into the hidden buffer; flip will occur in onPosterLoad when ready
sub QueueLoadIntoInactive(uri as string, kind as string)
  if uri = invalid or uri = "" then return
  target = (m.active = "A") and m.bgB or m.bgA
  if target = invalid then return

  ' Keep current image visible; load next in hidden target
  target.visible = false
  m.pending = target
  m.pendingKind = kind
  target.uri = uri
  FSLogSaver("QueueLoad(" + kind + "): " + uri + " -> " + ((m.active="A") and "B" or "A"))
end sub

' Flip to the node passed (assumes it is ready)
sub FlipTo(node as object)
  if node = invalid then return
  if node = m.bgA then
    m.bgA.visible = true
    m.bgB.visible = false
    m.active = "A"
  else
    m.bgB.visible = true
    m.bgA.visible = false
    m.active = "B"
  end if
end sub

' Poster load callback — only flip when the new image is ready
sub onPosterLoad()
  if m.pending = invalid then return

  status = LCase(ToStr(m.pending.loadStatus))
  if status = "ready" then
    FSLogSaver("poster ready (" + m.pendingKind + "); flipping")
    FlipTo(m.pending)
    m.pending = invalid
    m.pendingKind = ""
  else if status = "failed" then
    FSLogSaver("poster FAILED (" + m.pendingKind + "); keeping current image")
    m.pending = invalid
    m.pendingKind = ""
  end if
end sub

' Feed status passthrough (for logs you see in telnet)
sub onFeedStatus()
  FSLogSaver("feed status: " + ToStr(m.feed.status))
end sub

' Feed delivered items → start cycler
sub onFeedItems(evt as Object)
  if evt = invalid then return
  arr = evt.GetData()
  if type(arr) <> "roArray" or arr.count() = 0 then
    FSLogSaver("Feed empty; remain on offline image")
    return
  end if
  m.items = arr
  FSLogSaver("Feed items count= " + StrI(m.items.count()))
  if m.cycler <> invalid then
    m.cycler.control = "start"
    FSLogSaver("Cycler started")
  end if
end sub

' Timer fired — request next image; it will flip once ready (no gray)
sub onCycle()
  if m.items = invalid or m.items.count() = 0 then return
  m.index = (m.index + 1) mod m.items.count()
  nextUri = m.items[m.index]
  QueueLoadIntoInactive(nextUri, "cycle")
end sub

' Keys: production saver swallows back/home
function onKeyEvent(key as string, press as boolean) as boolean
  if not press then return false
  if key = "back" or key = "home" then return true
  return true
end function
