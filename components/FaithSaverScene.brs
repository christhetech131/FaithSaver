' FaithSaver runtime: show local fallback immediately, then remote; rotate every 5 minutes

sub init()
  m.img = m.top.findNode("img")
  m.base = "https://christhetech131.github.io/FaithSaver"
  m.index = invalid

  ' Always show something right away (prevents “frozen” preview)
  ShowLocalFallback()

  ' 5-minute rotation timer
  m.rotateTimer = CreateObject("roSGNode","Timer")
  m.rotateTimer.duration = 300
  m.rotateTimer.observeField("fire","onRotate")
  m.top.appendChild(m.rotateTimer)

  ' Fetch remote index.json asynchronously
  FetchIndex(true)
end sub

' -------- category picking --------
function EffectiveCategory() as string
  reg = CreateObject("roRegistrySection","FaithSaver")
  saved = LCase(reg.Read("category"))
  if saved = invalid or saved = "" then saved = "animals"
  if saved = "seasonal" then
    mth = CreateObject("roDateTime").GetMonth()
    if mth=3 or mth=4 or mth=5 then return "spring"
    if mth=6 or mth=7 or mth=8 then return "summer"
    if mth=9 or mth=10 or mth=11 then return "fall"
    return "winter"
  end if
  return saved
end function

' -------- offline fallbacks --------
function LocalFallbacks() as Object
  ' If you kept a single default.jpg, point all keys to it; otherwise include per-category jpgs.
  return {
    animals:  ["pkg:/images/offline/default.jpg"]
    fall:     ["pkg:/images/offline/default.jpg"]
    geology:  ["pkg:/images/offline/default.jpg"]
    scenery:  ["pkg:/images/offline/default.jpg"]
    space:    ["pkg:/images/offline/default.jpg"]
    spring:   ["pkg:/images/offline/default.jpg"]
    summer:   ["pkg:/images/offline/default.jpg"]
    textures: ["pkg:/images/offline/default.jpg"]
    winter:   ["pkg:/images/offline/default.jpg"]
  }
end function

sub ShowLocalFallback()
  lf = LocalFallbacks()
  cat = EffectiveCategory()
  list = lf[cat]
  if list = invalid or list.count() = 0 then list = ["pkg:/images/offline/default.jpg"]
  m.img.uri = list[0]
end sub

' -------- remote index fetch --------
sub FetchIndex(startRotation as boolean)
  url = m.base + "/index.json?t=" + CreateObject("roDateTime").AsSeconds().ToStr()
  port = CreateObject("roMessagePort")
  xfer = CreateObject("roUrlTransfer")
  xfer.SetMessagePort(port)
  xfer.SetCertificatesFile("common:/certs/ca-bundle.crt")
  xfer.InitClientCertificates()
  xfer.SetUrl(url)
  xfer.AsyncGetToString()

  timeout = CreateObject("roTimespan") : timeout.Mark()
  maxWaitMs = 7000

  while true
    msg = wait(250, port)
    if type(msg) = "roUrlEvent" then
      if msg.GetResponseCode() = 200 then
        j = ParseJson(msg.GetString())
        if j <> invalid and j.categories <> invalid then
          m.index = j
          if startRotation then m.rotateTimer.control = "start"
          ShowRandom() ' swap from local to remote ASAP
          return
        end if
      end if
      exit while ' error → stay on local fallback
    end if
    if timeout.TotalMilliseconds() > maxWaitMs then exit while
  end while

  if startRotation then m.rotateTimer.control = "start"
end sub

' -------- image selection --------
sub ShowRandom()
  if m.index = invalid then return
  cat = EffectiveCategory()

  list = m.index.categories[cat]
  if list = invalid or list.count() = 0 then return

  idx = int(Rnd(0) * list.count())
  p = list[idx]

  if Left(p,1) = "/" then
    m.img.uri = m.base + p
  else
    m.img.uri = p ' supports pkg:/ paths if ever needed
  end if
end sub

sub onRotate()
  if m.index <> invalid then
    ShowRandom()
  else
    ShowLocalFallback()
  end if
end sub
