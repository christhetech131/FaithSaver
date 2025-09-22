sub init()
  m.img = m.top.findNode("img")
  m.loader = m.top.findNode("loader")
  m.base = "https://christhetech131.github.io/FaithSaver"
  m.index = invalid

  ShowLocalFallback()

  m.loader.observeField("response", "onLoaded")
  m.loader.observeField("error", "onLoadError")
  m.loader.url = m.base + "/index.json?t=" + CreateObject("roDateTime").AsSeconds().ToStr()
  m.loader.control = "run"

  m.rotateTimer = CreateObject("roSGNode","Timer")
  m.rotateTimer.duration = 300
  m.rotateTimer.observeField("fire","onRotate")
  m.top.appendChild(m.rotateTimer)
  m.rotateTimer.control = "start"
end sub

sub onLoaded()
  data = m.loader.response
  j = invalid
  if data <> invalid then j = ParseJson(data)
  if j <> invalid and j.categories <> invalid then
    m.index = j
    ShowRandom()
  end if
end sub

sub onLoadError()
  ' stay on local fallback
end sub

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

function LocalFallbacks() as Object
  return { animals:["pkg:/images/offline/default.jpg"], fall:["pkg:/images/offline/default.jpg"],
           geology:["pkg:/images/offline/default.jpg"], scenery:["pkg:/images/offline/default.jpg"],
           space:["pkg:/images/offline/default.jpg"], spring:["pkg:/images/offline/default.jpg"],
           summer:["pkg:/images/offline/default.jpg"], textures:["pkg:/images/offline/default.jpg"],
           winter:["pkg:/images/offline/default.jpg"] }
end function

sub ShowLocalFallback()
  list = LocalFallbacks()[EffectiveCategory()]
  if list = invalid or list.count() = 0 then list = ["pkg:/images/offline/default.jpg"]
  m.img.uri = list[0]
end sub

sub ShowRandom()
  if m.index = invalid then return
  list = m.index.categories[EffectiveCategory()]
  if list = invalid or list.count() = 0 then return
  idx = int(Rnd(0) * list.count())
  p = list[idx]
  if Left(p,1) = "/" then m.img.uri = m.base + p else m.img.uri = p
end sub

sub onRotate()
  if m.index <> invalid then ShowRandom() else ShowLocalFallback()
end sub
