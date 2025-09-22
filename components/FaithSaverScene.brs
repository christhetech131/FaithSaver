' --- top of file (existing init etc.) ---

' Local offline fallbacks (one per category)
function LocalFallbacks() as Object
  return {
    animals:  ["pkg:/images/offline/animals.jpg"]
    fall:     ["pkg:/images/offline/fall.jpg"]
    geology:  ["pkg:/images/offline/geology.jpg"]
    scenery:  ["pkg:/images/offline/scenery.jpg"]
    space:    ["pkg:/images/offline/space.jpg"]
    spring:   ["pkg:/images/offline/spring.jpg"]
    summer:   ["pkg:/images/offline/summer.jpg"]
    textures: ["pkg:/images/offline/textures.jpg"]
    winter:   ["pkg:/images/offline/winter.jpg"]
  }
end function

' If you prefer a single global fallback instead, use this and call it below:
' function GlobalFallbackList() as Object
'   fallback = ["pkg:/images/offline/default.jpg"]
'   return { animals:fallback, fall:fallback, geology:fallback, scenery:fallback, space:fallback, spring:fallback, summer:fallback, textures:fallback, winter:fallback }
' end function

sub FetchIndex(startRotation as boolean)
  url = m.base + "/index.json?t=" + CreateObject("roDateTime").AsSeconds().ToStr()
  port = CreateObject("roMessagePort")
  xfer = CreateObject("roUrlTransfer")
  xfer.SetMessagePort(port)
  xfer.SetCertificatesFile("common:/certs/ca-bundle.crt")  ' robust HTTPS
  xfer.InitClientCertificates()
  xfer.RetainBodyOnError(true)
  xfer.SetUrl(url)
  xfer.SetRequest("GET")
  xfer.AsyncGetToString()

  timeout = CreateObject("roTimespan") : timeout.Mark()
  maxWaitMs = 7000  ' 7s network timeout

  while true
    msg = wait(250, port)
    if msg <> invalid and type(msg) = "roUrlEvent" then
      if msg.GetResponseCode() = 200 then
        j = ParseJson(msg.GetString())
        if j <> invalid and j.categories <> invalid then
          m.index = j
          if m.index.updated <> invalid then m.updatedTag = m.index.updated
          if startRotation then
            PrefetchNext(true)
            m.rotateTimer.control = "start"
            m.refreshTimer.control = "start"
          else
            PrefetchNext(false)
          end if
          return
        end if
      end if
      exit while ' HTTP error → fall back
    end if
    if timeout.TotalMilliseconds() > maxWaitMs then exit while ' Timeout → fall back
  end while

  ' --- Fallback: build an in-memory "index" from local assets
  m.index = { updated: "local", categories: LocalFallbacks() }
  if startRotation then
    PrefetchNext(true)
    m.rotateTimer.control = "start"
    m.refreshTimer.control = "start"
  else
    PrefetchNext(false)
  end if
end sub

sub ShowRandom()
  if m.index = invalid then return
  saved = LCase(CreateObject("roRegistrySection","FaithSaver").Read("category"))
  category = iif(saved = "seasonal", CurrentSeasonCategory(), m.category)
  category = LCase(category)

  list = invalid
  if m.index.categories <> invalid then list = m.index.categories[category]
  if list = invalid or list.count() = 0 then
    ' Try local fallback for this category
    lf = LocalFallbacks()
    list = lf[category]
    if list = invalid or list.count() = 0 then return
  end if

  idx = int(Rnd(0) * list.count())
  url = list[idx]

  ' Local vs remote: use pkg:/ path as-is, or prepend base for remote paths starting with "/"
  if Left(url, 1) = "/" then
    m.imgToUse = m.base + url
  else
    m.imgToUse = url ' pkg:/ local
  end if

  ' Set URI on the hidden prefetch poster (handled in your prefetch logic)
  ' For single-poster setups, just assign to m.img.uri directly:
  ' m.img.uri = m.imgToUse
end sub
