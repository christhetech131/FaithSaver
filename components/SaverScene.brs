' *********** FaithSaver — SaverScene.brs (first=fade, slower slide, hardened) ***********

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
  m.cycler = m.top.findNode("cycler")   ' Timer (duration set in XML)
  m.feed   = m.top.findNode("feed")     ' ImageFeedTask
  m.hint   = m.top.findNode("previewHint") ' may be invalid

  ' State
  m.activeIsA     = true        ' which buffer is currently live (A starts live)
  m.index         = 0
  m.items         = CreateObject("roArray", 0, true)
  m.pendingTarget = invalid     ' "A" or "B" when a load is in-flight
  m.pendingUri    = ""
  m.flipArmed     = false
  m.didFirstTransition = false  ' <-- ensure first transition is fade-in

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

  ' PRODUCTION saver (single path)
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

  ' Timer: observe fires (duration comes from XML; do not override here)
  if m.cycler <> invalid then
    m.cycler.ObserveField("fire", "onCycle")
  end if

  ' React to visibility to pause/resume the cycler
  m.top.ObserveField("visible", "onVisibleChanged")

  ' Create Animation nodes for transitions
  SetupTransitions()

  ' Show an immediate offline-first frame for the category (via the standard path)
  ShowFirstFrameForCategory(m.category)
end sub

' =========================
' Transition Animations (reusable)
' =========================
sub SetupTransitions()
  ' Fade (cross-fade): 350ms
  m.animFade = CreateObject("roSGNode", "Animation")
  m.animFade.duration = 0.35 : m.animFade.repeat = false

  m.fadeIn = CreateObject("roSGNode", "FloatFieldInterpolator")
  m.fadeIn.key = [0.0, 1.0] : m.fadeIn.keyValue = [0.0, 1.0]
  m.fadeIn.fieldToInterp = "bgA.opacity" ' reassigned per transition

  m.fadeOut = CreateObject("roSGNode", "FloatFieldInterpolator")
  m.fadeOut.key = [0.0, 1.0] : m.fadeOut.keyValue = [1.0, 0.0]
  m.fadeOut.fieldToInterp = "bgB.opacity" ' reassigned per transition

  m.animFade.AppendChild(m.fadeIn) : m.animFade.AppendChild(m.fadeOut)
  m.top.AppendChild(m.animFade)

  ' Fade-in (incoming only) for the very first frame: 600ms
  m.animFadeSingle = CreateObject("roSGNode", "Animation")
  m.animFadeSingle.duration = 0.6 : m.animFadeSingle.repeat = false

  m.fadeInOnly = CreateObject("roSGNode", "FloatFieldInterpolator")
  m.fadeInOnly.key = [0.0, 1.0] : m.fadeInOnly.keyValue = [0.0, 1.0]
  m.fadeInOnly.fieldToInterp = "bgA.opacity"  ' reassigned to incoming

  m.animFadeSingle.AppendChild(m.fadeInOnly)
  m.top.AppendChild(m.animFadeSingle)

  ' Slide/Push (left): **slower** 2000ms
  m.animSlide = CreateObject("roSGNode", "Animation")
  m.animSlide.duration = 2.00 : m.animSlide.repeat = false

  m.inXY  = CreateObject("roSGNode", "Vector2DFieldInterpolator")
  m.inXY.key = [0.0, 1.0] : m.inXY.keyValue = [[1920, 0], [0, 0]]
  m.inXY.fieldToInterp = "bgA.translation" ' reassigned

  m.outXY = CreateObject("roSGNode", "Vector2DFieldInterpolator")
  m.outXY.key = [0.0, 1.0] : m.outXY.keyValue = [[0, 0], [-1920, 0]]
  m.outXY.fieldToInterp = "bgB.translation" ' reassigned

  m.animSlide.AppendChild(m.inXY) : m.animSlide.AppendChild(m.outXY)
  m.top.AppendChild(m.animSlide)

  ' Zoom (quick ease-in with fade): 700ms
  m.animZoom = CreateObject("roSGNode", "Animation")
  m.animZoom.duration = 0.70 : m.animZoom.repeat = false

  m.zoomInOpacity = CreateObject("roSGNode", "FloatFieldInterpolator")
  m.zoomInOpacity.key = [0.0, 1.0] : m.zoomInOpacity.keyValue = [0.0, 1.0]
  m.zoomInOpacity.fieldToInterp = "bgA.opacity" ' reassigned

  m.zoomOutOpacity = CreateObject("roSGNode", "FloatFieldInterpolator")
  m.zoomOutOpacity.key = [0.0, 1.0] : m.zoomOutOpacity.keyValue = [1.0, 0.0]
  m.zoomOutOpacity.fieldToInterp = "bgB.opacity" ' reassigned

  m.zoomScale = CreateObject("roSGNode", "Vector2DFieldInterpolator")
  m.zoomScale.key = [0.0, 1.0] : m.zoomScale.keyValue = [[0.98, 0.98], [1.0, 1.0]]
  m.zoomScale.fieldToInterp = "bgA.scale" ' reassigned

  m.animZoom.AppendChild(m.zoomInOpacity)
  m.animZoom.AppendChild(m.zoomOutOpacity)
  m.animZoom.AppendChild(m.zoomScale)
  m.top.AppendChild(m.animZoom)
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

  ' Deterministic start index (no RNG)
  dt = CreateObject("roDateTime")
  start = dt.AsSeconds() mod m.items.count()
  if start < 0 then start = 0
  m.index = start
  FSLogSaver("Start index=" + StrI(m.index))

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
    ' No online items; remain on offline first frame
  end if
end sub

' =========================
' Double-buffered image load
' =========================
sub ShowImage(uri as string)
  if uri = invalid or uri = "" then return

  ' Decide which poster to target (load into the non-live one)
  targetPoster = invalid
  targetId = ""
  if m.activeIsA then
    targetPoster = m.bgB : targetId = "B"
  else
    targetPoster = m.bgA : targetId = "A"
  end if
  if targetPoster = invalid then return

  ' Baseline reset on the target buffer for clean transitions
  targetPoster.opacity = 0.0
  targetPoster.translation = [0, 0]
  targetPoster.scale = [1.0, 1.0]
  targetPoster.visible = true

  ' Load
  m.pendingTarget = targetId
  m.pendingUri    = uri
  m.flipArmed     = true

  FSLogSaver("Request load → " + uri + " (to bg" + targetId + ")")
  targetPoster.uri = uri
end sub

' =========================
' Poster load handler
' =========================
sub onPosterLoad(evt as Object)
  if evt = invalid then return
  status = LCase(ToStr(evt.GetData()))

  if m.pendingTarget = invalid or m.pendingUri = "" then return

  ' Which node fired?
  nodeId$ = ""
  if evt.GetNode() <> invalid then
    if type(evt.GetNode()) = "roSGNode" then
      nodeObj = evt.GetNode()
      nodeId$ = LCase(ToStr(nodeObj.id))   ' "bga" / "bgb"
    else
      nodeId$ = LCase(ToStr(evt.GetNode()))
    end if
  end if

  ' Expected target id
  expected$ = "bgb" : if m.pendingTarget = "A" then expected$ = "bga"
  if nodeId$ <> expected$ then return

  if status = "ready" then
    ' Transition select: first is ALWAYS FADE-IN; then rotate (0=fade,1=slide,2=zoom)
    first = (m.didFirstTransition = false)
    mode = 0
    if not first then
      dt = CreateObject("roDateTime")
      mode = (dt.AsSeconds() + m.index) mod 3
    end if

    StartTransition(mode, first)
    m.didFirstTransition = true  ' lock in so slide never happens first

    ' Toggle which buffer is live AFTER starting the animation
    m.activeIsA = not m.activeIsA

    ' Clear pending
    m.pendingTarget = invalid
    m.pendingUri    = ""
    m.flipArmed     = false

  else if status = "failed" then
    FSLogSaver("ERROR: decode failed for " + m.pendingUri)
    m.pendingTarget = invalid
    m.pendingUri    = ""
    m.flipArmed     = false
  else
    ' loading, etc → ignore
  end if
end sub

' =========================
' Start one of the 3 transitions
' =========================
sub StartTransition(mode as integer, isFirst as boolean)
  ' Determine incoming/outgoing ids based on which was live BEFORE toggle.
  incomingId$ = "bgB" : outgoingId$ = "bgA"
  if not m.activeIsA then
    incomingId$ = "bgA" : outgoingId$ = "bgB"
  end if

  ' Ensure both visible during transition
  if incomingId$ = "bgA" then m.bgA.visible = true else m.bgB.visible = true
  if outgoingId$ = "bgA" then m.bgA.visible = true else m.bgB.visible = true

  if mode = 0 then
    ' ----- Fade -----
    if isFirst then
      ' First transition = FADE-IN (incoming only)
      if incomingId$ = "bgA" then
        m.fadeInOnly.fieldToInterp = "bgA.opacity"
        m.bgA.opacity = 0.0
      else
        m.fadeInOnly.fieldToInterp = "bgB.opacity"
        m.bgB.opacity = 0.0
      end if
      m.animFadeSingle.control = "stop" : m.animFadeSingle.control = "start"
      FSLogSaver("Transition = FADE (first, incoming only)")
    else
      ' Regular cross-fade
      if incomingId$ = "bgA" then
        m.fadeIn.fieldToInterp  = "bgA.opacity"
        m.fadeOut.fieldToInterp = "bgB.opacity"
        m.bgA.opacity = 0.0 : m.bgB.opacity = 1.0
      else
        m.fadeIn.fieldToInterp  = "bgB.opacity"
        m.fadeOut.fieldToInterp = "bgA.opacity"
        m.bgB.opacity = 0.0 : m.bgA.opacity = 1.0
      end if
      m.animFade.control = "stop" : m.animFade.control = "start"
      FSLogSaver("Transition = FADE")
    end if

  else if mode = 1 then
    ' ----- Slide / Push left (slower) -----
    if incomingId$ = "bgA" then
      m.inXY.fieldToInterp  = "bgA.translation"
      m.outXY.fieldToInterp = "bgB.translation"
      m.bgA.translation = [1920, 0] : m.bgB.translation = [0, 0]
      m.bgA.opacity = 1.0 : m.bgB.opacity = 1.0
    else
      m.inXY.fieldToInterp  = "bgB.translation"
      m.outXY.fieldToInterp = "bgA.translation"
      m.bgB.translation = [1920, 0] : m.bgA.translation = [0, 0]
      m.bgB.opacity = 1.0 : m.bgA.opacity = 1.0
    end if
    m.animSlide.control = "stop" : m.animSlide.control = "start"
    FSLogSaver("Transition = SLIDE")

  else
    ' ----- Zoom -----
    if incomingId$ = "bgA" then
      m.zoomInOpacity.fieldToInterp  = "bgA.opacity"
      m.zoomOutOpacity.fieldToInterp = "bgB.opacity"
      m.zoomScale.fieldToInterp      = "bgA.scale"
      m.bgA.opacity = 0.0 : m.bgB.opacity = 1.0
      m.bgA.scale = [0.98, 0.98]
    else
      m.zoomInOpacity.fieldToInterp  = "bgB.opacity"
      m.zoomOutOpacity.fieldToInterp = "bgA.opacity"
      m.zoomScale.fieldToInterp      = "bgB.scale"
      m.bgB.opacity = 0.0 : m.bgA.opacity = 1.0
      m.bgB.scale = [0.98, 0.98]
    end if
    m.animZoom.control = "stop" : m.animZoom.control = "start"
    FSLogSaver("Transition = ZOOM")
  end if
end sub

' =========================
' Visibility handling — pause/resume cycler
' =========================
sub onVisibleChanged()
  if m.cycler = invalid then return
  if m.top.visible = true then
    if m.items <> invalid and m.items.count() > 0 then
      m.cycler.control = "start"
      FSLogSaver("Visible=TRUE → cycler resumed")
    end if
  else
    m.cycler.control = "stop"
    FSLogSaver("Visible=FALSE → cycler paused")
  end if
end sub

' =========================
' Key handling (saver)
' =========================
function onKeyEvent(key as string, press as boolean) as boolean
  if not press then return false

  ' Swallow Back in dev; Roku handles Home/Back on published savers
  if key = "back" then return true

  return false
end function
