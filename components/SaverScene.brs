' *********** FaithSaver — SaverScene.brs (full file) ***********

sub FSLogSaver(msg as string)
  print "[FaithSaver][Saver] "; ToStr(msg)
end sub

function ToStr(v as dynamic) as string
  if v = invalid then return ""
  t = type(v)
  if t = "Boolean" then
    if v then return "true" else return "false"
  else if t = "roString" or t = "String" then
    return v
  else if t = "Integer" or t = "LongInteger" then
    return StrI(v)
  else if t = "Float" or t = "Double" then
    return Str(v)
  else if t = "roArray" then
    return "Array( " + StrI(v.count()) + ")"
  else if t = "roAssociativeArray" then
    return "AA(" + StrI(v.count()) + ")"
  else
    return "<" + t + ">"
  end if
end function

' =========================
' Scene lifecycle
' =========================
sub init()
  FSLogSaver("init()")

  ' Scene graph nodes
  m.bgA    = m.top.findNode("bgA")
  m.bgB    = m.top.findNode("bgB")
  m.cycler = m.top.findNode("cycler")   ' Timer
  m.feed   = m.top.findNode("feed")     ' ImageFeedTask
  m.hint   = m.top.findNode("previewHint") ' may be invalid

  ' State
  m.activeIsA     = true
  m.index         = 0
  m.items         = CreateObject("roArray", 0, true) ' online items when available
  m.pendingTarget = invalid   ' "A" or "B" when a load is in-flight
  m.pendingUri    = ""
  m.flipArmed     = false

  ' Observe poster load statuses for A/B
  if m.bgA <> invalid then m.bgA.ObserveField("loadStatus", "onPosterLoad")
  if m.bgB <> invalid then m.bgB.ObserveField("loadStatus", "onPosterLoad")

  ' Read saved category from registry (default animals)
  m.category = "animals"
  sec = CreateObject("roRegistrySection", "FaithSaver")
  if sec <> invalid then
    val = sec.Read("category")
    if val <> invalid and val <> "" then m.category = LCase(val)
  end if
  FSLogSaver("Registry category=" + m.category)

  ' PRODUCTION saver (we removed preview entry from manifest routing)
  FSLogSaver("Mode=saver; wiring ImageFeedTask")

  ' Start feed task
  if m.feed <> invalid then
    m.feed.category = m.category
    m.feed.ObserveField("items", "onFeedItems")
    m.feed.control = "run"
    FSLogSaver("ImageFeedTask started")
  else
    FSLogSaver("ERROR: feed task node not found")
  end if

  ' Timer (30s standard)
  if m.cycler <> invalid then
    m.cycler.ObserveField("fire", "onCycle")
    m.cycler.duration = 30   ' seconds
  end if

  ' Show an immediate offline-first frame for the category
  ShowFirstFrameForCategory(m.category)
end sub

' =========================
' Offline first frame (by category)
' =========================
sub ShowFirstFrameForCategory(cat as string)
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

  ShowImage(uri)
end sub

' =========================
' Feed callback (production)
' =========================
sub onFeedItems(evt as Object)
  if evt = invalid then return
  arr = evt.GetData()
  if type(arr) <> "roArray" or arr.count() = 0 then
    FSLogSaver("Feed returned empty; staying on offline category image")
    return
  end if

  m.items = arr
  FSLogSaver("Feed items=" + ToStr(m.items))

  ' Pick a deterministic but varied start index without Randomize()/roRandom
  dt = CreateObject("roDateTime")
  start = dt.AsSeconds() mod m.items.count()
  m.index = start
  FSLogSaver("Start index=" + StrI(m.index))

  ' Start the cycler; first online image will appear on first tick
  if m.cycler <> invalid then
    m.cycler.control = "start"
    FSLogSaver("Cycler started (first online image will appear on first tick)")
  end if
end sub

' =========================
' Timer tick → advance slideshow
' =========================
sub onCycle()
  if m.items <> invalid and m.items.count() > 0 then
    m.index = (m.index + 1) mod m.items.count()
    ShowImage(m.items[m.index])
  else
    ' No online items; remain on the offline first frame
  end if
end sub

' =========================
' Double-buffered image load
' =========================
sub ShowImage(uri as string)
  if uri = invalid or uri = "" then return

  ' Decide which poster to target (flip the non-active one)
  targetPoster = invalid
  targetId = ""
  if m.activeIsA then
    targetPoster = m.bgB : targetId = "B"
  else
    targetPoster = m.bgA : targetId = "A"
  end if

  if targetPoster = invalid then return

  m.pendingTarget = targetId
  m.pendingUri    = uri
  m.flipArmed     = true

  FSLogSaver("Request load → " + uri + " (to bg" + targetId + ")")
  targetPoster.uri = uri
  targetPoster.visible = true
end sub

' Safe handler for poster loadStatus events (works across firmware variants)
sub onPosterLoad(evt as Object)
  if evt = invalid then return
  status = LCase(ToStr(evt.GetData()))

  ' ignore if we have no pending target
  if m.pendingTarget = invalid or m.pendingUri = "" then return

  ' figure out which Poster fired the event (node OR string id)
  nodeId$ = ""
  if evt.GetNode() <> invalid then
    if type(evt.GetNode()) = "roSGNode" then
      nodeObj = evt.GetNode()
      nodeId$ = LCase(ToStr(nodeObj.id))   ' "bga" / "bgb"
    else
      nodeId$ = LCase(ToStr(evt.GetNode())) ' some firmware returns id string
    end if
  end if

  ' compute expected target id explicitly (no boolean and/or trick)
  targetId$ = "bgb"
  if m.pendingTarget = "A" then targetId$ = "bga"

  ' if the event isn't for our target poster, ignore
  if nodeId$ <> targetId$ then return

  if status = "ready" then
    FSLogSaver("Ready → flip to bg" + m.pendingTarget)

    ' flip visibility
    if m.activeIsA then
      if m.bgA <> invalid then m.bgA.visible = false
      m.activeIsA = false
    else
      if m.bgB <> invalid then m.bgB.visible = false
      m.activeIsA = true
    end if

    ' clear pending state
    m.pendingTarget = invalid
    m.pendingUri    = ""
    m.flipArmed     = false

  else if status = "failed" then
    FSLogSaver("ERROR: decode failed for " + m.pendingUri)
    m.pendingTarget = invalid
    m.pendingUri    = ""
    m.flipArmed     = false
  else
    ' "loading" or other transitional states → ignore
  end if
end sub

' =========================
' Key handling (saver)
' =========================
function onKeyEvent(key as string, press as boolean) as boolean
  if not press then return false

  ' In dev sideload, we swallow all keys to avoid accidental exit behavior differences
  if key = "back" or key = "home" then return true

  return true
end function
