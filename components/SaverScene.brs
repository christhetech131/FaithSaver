' *********** FaithSaver — SaverScene.brs (transitions; single offline default.jpg) ***********

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

  m.bgA    = m.top.findNode("bgA")
  m.bgB    = m.top.findNode("bgB")
  m.cycler = m.top.findNode("cycler")
  m.feed   = m.top.findNode("feed")

  m.activeIsA     = true
  m.index         = 0
  m.items         = CreateObject("roArray", 0, true)
  m.pendingTarget = invalid
  m.pendingUri    = ""
  m.flipArmed     = false
  m.didFirstTransition = false

  if m.bgA <> invalid then m.bgA.ObserveField("loadStatus", "onPosterLoad")
  if m.bgB <> invalid then m.bgB.ObserveField("loadStatus", "onPosterLoad")

  m.category = "animals"
  sec = CreateObject("roRegistrySection", "FaithSaver")
  if sec <> invalid then
    val = sec.Read("category")
    if val <> invalid and val <> "" then m.category = LCase(val)
  end if
  FSLogSaver("Registry category=" + m.category)

  if m.feed <> invalid then
    m.feed.category = m.category
    m.feed.ObserveField("items", "onFeedItems")
    m.feed.control = "run"
    FSLogSaver("ImageFeedTask started")
  else
    FSLogSaver("ERROR: feed task node not found")
  end if

  if m.cycler <> invalid then
    m.cycler.ObserveField("fire", "onCycle")
  end if

  m.top.ObserveField("visible", "onVisibleChanged")

  SetupTransitions()
  ShowFirstFrameForCategory(m.category)
end sub

' =========================
' Transition Animations
' =========================
sub SetupTransitions()
  ' Fade
  m.animFade = CreateObject("roSGNode", "Animation")
  m.animFade.duration = 0.35 : m.animFade.repeat = false

  m.fadeIn = CreateObject("roSGNode", "FloatFieldInterpolator")
  m.fadeIn.key = [0.0, 1.0] : m.fadeIn.keyValue = [0.0, 1.0]
  m.fadeIn.fieldToInterp = "bgA.opacity"

  m.fadeOut = CreateObject("roSGNode", "FloatFieldInterpolator")
  m.fadeOut.key = [0.0, 1.0] : m.fadeOut.keyValue = [1.0, 0.0]
  m.fadeOut.fieldToInterp = "bgB.opacity"

  m.animFade.AppendChild(m.fadeIn) : m.animFade.AppendChild(m.fadeOut)
  m.top.AppendChild(m.animFade)

  ' Slide (slower)
  m.animSlide = CreateObject("roSGNode", "Animation")
  m.animSlide.duration = 0.65 : m.animSlide.repeat = false

  m.inXY  = CreateObject("roSGNode", "Vector2DFieldInterpolator")
  m.inXY.key = [0.0, 1.0] : m.inXY.keyValue = [[1920, 0], [0, 0]]
  m.inXY.fieldToInterp = "bgA.translation"

  m.outXY = CreateObject("roSGNode", "Vector2DFieldInterpolator")
  m.outXY.key = [0.0, 1.0] : m.outXY.keyValue = [[0, 0], [-1920, 0]]
  m.outXY.fieldToInterp = "bgB.translation"

  m.animSlide.AppendChild(m.inXY) : m.animSlide.AppendChild(m.outXY)
  m.top.AppendChild(m.animSlide)

  ' Zoom
  m.animZoom = CreateObject("roSGNode", "Animation")
  m.animZoom.duration = 0.35 : m.animZoom.repeat = false

  m.zoomInOpacity = CreateObject("roSGNode", "FloatFieldInterpolator")
  m.zoomInOpacity.key = [0.0, 1.0] : m.zoomInOpacity.keyValue = [0.0, 1.0]
  m.zoomInOpacity.fieldToInterp = "bgA.opacity"

  m.zoomOutOpacity = CreateObject("roSGNode", "FloatFieldInterpolator")
  m.zoomOutOpacity.key = [0.0, 1.0] : m.zoomOutOpacity.keyValue = [1.0, 0.0]
  m.zoomOutOpacity.fieldToInterp = "bgB.opacity"

  m.zoomScale = CreateObject("roSGNode", "Vector2DFieldInterpolator")
  m.zoomScale.key = [0.0, 1.0] : m.zoomScale.keyValue = [[0.98, 0.98], [1.0, 1.0]]
  m.zoomScale.fieldToInterp = "bgA.scale"

  m.animZoom.AppendChild(m.zoomInOpacity)
  m.animZoom.AppendChild(m.zoomOutOpacity)
  m.animZoom.AppendChild(m.zoomScale)
  m.top.AppendChild(m.animZoom)
end sub

' =========================
' Offline first frame (single default.jpg)
' =========================
sub ShowFirstFrameForCategory(cat as string)
  ' Touch the parameter so there is no "unused" warning in some firmware compilers
  if false then print cat
  uri = "pkg:/images/offline/default.jpg"
  ShowImage(uri)
end sub

' =========================
' Feed callback
' =========================
sub onFeedItems(evt as Object)
  if evt = invalid then return
  arr = evt.GetData()
  if type(arr) <> "roArray" or arr.count() = 0 then
    FSLogSaver("Feed returned empty; staying on offline default")
    return
  end if

  m.items = arr
  FSLogSaver("Feed items=" + ToStr(m.items))

  dt = CreateObject("roDateTime")
  start = dt.AsSeconds() mod m.items.count()
  if start < 0 then start = 0
  m.index = start
  FSLogSaver("Start index=" + StrI(m.index))

  if m.cycler <> invalid then
    m.cycler.control = "start"
    FSLogSaver("Cycler started (first online image on first tick)")
  end if
end sub

' =========================
' Timer tick
' =========================
sub onCycle()
  if m.items <> invalid and m.items.count() > 0 then
    m.index = (m.index + 1) mod m.items.count()
    ShowImage(m.items[m.index])
  end if
end sub

' =========================
' Image load
' =========================
sub ShowImage(uri as string)
  if uri = invalid or uri = "" then return

  targetPoster = invalid
  targetId = ""
  if m.activeIsA then
    targetPoster = m.bgB : targetId = "B"
  else
    targetPoster = m.bgA : targetId = "A"
  end if
  if targetPoster = invalid then return

  targetPoster.opacity = 0.0
  targetPoster.translation = [0, 0]
  targetPoster.scale = [1.0, 1.0]
  targetPoster.visible = true

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

  nodeId$ = ""
  if evt.GetNode() <> invalid then
    if type(evt.GetNode()) = "roSGNode" then
      nodeObj = evt.GetNode()
      nodeId$ = LCase(ToStr(nodeObj.id))
    else
      nodeId$ = LCase(ToStr(evt.GetNode()))
    end if
  end if

  expected$ = "bgb" : if m.pendingTarget = "A" then expected$ = "bga"
  if nodeId$ <> expected$ then return

  if status = "ready" then
    if m.didFirstTransition = invalid then m.didFirstTransition = false

    dt = CreateObject("roDateTime")
    mode = (dt.AsSeconds() + m.index) mod 3  ' 0=fade,1=slide,2=zoom
    if not m.didFirstTransition then
      mode = 0 : m.didFirstTransition = true ' first = FADE
    end if

    StartTransition(mode)
    m.activeIsA = not m.activeIsA

    m.pendingTarget = invalid
    m.pendingUri    = ""
    m.flipArmed     = false

  else if status = "failed" then
    FSLogSaver("ERROR: decode failed for " + m.pendingUri)
    m.pendingTarget = invalid
    m.pendingUri    = ""
    m.flipArmed     = false
  end if
end sub

' =========================
' Transitions
' =========================
sub StartTransition(mode as integer)
  incomingId$ = "bgB" : outgoingId$ = "bgA"
  if not m.activeIsA then
    incomingId$ = "bgA" : outgoingId$ = "bgB"
  end if

  if incomingId$ = "bgA" then m.bgA.visible = true else m.bgB.visible = true
  if outgoingId$ = "bgA" then m.bgA.visible = true else m.bgB.visible = true

  if mode = 0 then
    ' Fade
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

  else if mode = 1 then
    ' Slide
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
    ' Zoom
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
' Visibility
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
