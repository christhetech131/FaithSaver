' Screensaver runtime: prefetch, rotate, refresh, and robust error handling

sub init()
  ' Nodes
  m.imgA = m.top.findNode("imgA")
  m.imgB = m.top.findNode("imgB")
  m.status = m.top.findNode("status")

  ' Observe loadStatus so we can detect failures and readiness
  m.imgA.ObserveField("loadStatus", "onPosterStatus")
  m.imgB.ObserveField("loadStatus", "onPosterStatus")

  ' State
  m.base = "https://christhetech131.github.io/FaithSaver"
  m.index = invalid
  m.updatedTag = ""
  m.current = m.imgA     ' currently displayed poster
  m.next = m.imgB        ' prefetch target
  m.pendingUrl = invalid ' URL we’re preloading into m.next
  m.randomAttempts = 0

  ' Timers
  m.rotateTimer = CreateObject("roSGNode", "Timer")
  m.rotateTimer.duration = 300     ' 5 minutes
  m.rotateTimer.ObserveField("fire", "onRotateTick")
  m.top.AppendChild(m.rotateTimer)

  m.refreshTimer = CreateObject("roSGNode", "Timer")
  m.refreshTimer.duration = 7200   ' 2 hours
  m.refreshTimer.repeat = true
  m.refreshTimer.ObserveField("fire", "onRefreshTick")
  m.top.AppendChild(m.refreshTimer)

  FetchIndex(true) ' initial fetch; starts rotation when ready
end sub

' ---------- CATEGORY RESOLUTION ----------

function ReadSavedCategory() as string
  reg = CreateObject("roRegistrySection","FaithSaver")
  cat = reg.Read("category")
  if cat = invalid or cat = "" then return "animals"
  return LCase(cat)
end function

function CurrentSeasonCategory() as string
  dt = CreateObject("roDateTime")
  mth = dt.GetMonth()
  ' meteorological seasons
  if (mth = 3) or (mth = 4) or (mth = 5) then return "spring"
  if (mth = 6) or (mth = 7) or (mth = 8) then return "summer"
  if (mth = 9) or (mth = 10) or (mth = 11) then return "fall"
  return "winter"
end function

function EffectiveCategory() as string
  saved = ReadSavedCategory()
  if saved = "seasonal" then return CurrentSeasonCategory()
  return saved
end function

' ---------- INDEX FETCH & REFRESH ----------

sub FetchIndex(startRotation as boolean)
  url = m.base + "/index.json?t=" + CreateObject("roDateTime").AsSeconds().ToStr()
  port = CreateObject("roMessagePort")
  xfer = CreateObject("roUrlTransfer")
  xfer.SetMessagePort(port)
  xfer.SetUrl(url)
  xfer.AsyncGetToString()

  while true
    msg = wait(0, port)
    if type(msg) = "roUrlEvent" then
      if msg.GetResponseCode() = 200 then
        data = msg.GetString()
        j = invalid
        ' Guard against bad JSON
        if data <> invalid and data.len() > 0 then
          j = ParseJson(data)
        end if
        if j <> invalid and j.categories <> invalid then
          m.index = j
          if m.index.updated <> invalid then m.updatedTag = m.index.updated
          if startRotation then
            ' first run: prepare and show immediately when ready
            PrefetchNext(true)
            m.rotateTimer.control = "start"
            m.refreshTimer.control = "start"
          else
            ' on refresh: just ensure we have a next image queued
            PrefetchNext(false)
          end if
        end if
      end if
      return
    end if
  end while
end sub

sub onRefreshTick()
  ' Re-fetch index.json; only act if "updated" changed
  oldTag = m.updatedTag
  url = m.base + "/index.json?t=" + CreateObject("roDateTime").AsSeconds().ToStr()
  port = CreateObject("roMessagePort")
  xfer = CreateObject("roUrlTransfer")
  xfer.SetMessagePort(port)
  xfer.SetUrl(url)
  xfer.AsyncGetToString()

  while true
    msg = wait(0, port)
    if type(msg) = "roUrlEvent" then
      if msg.GetResponseCode() = 200 then
        j = ParseJson(msg.GetString())
        if j <> invalid and j.updated <> invalid and j.categories <> invalid then
          if j.updated <> oldTag then
            m.index = j
            m.updatedTag = j.updated
            PrefetchNext(false)
          end if
        end if
      end if
      return
    end if
  end while
end sub

' ---------- IMAGE ROTATION & PREFETCH ----------

sub onRotateTick()
  ' At each tick, if the prefetch poster is ready, swap; otherwise retry prefetch
  if m.next.loadStatus = "ready" and m.pendingUrl <> invalid then
    SwapPosters()
    PrefetchNext(false)
  else
    ' Try another image if we failed to prefetch
    PrefetchNext(false)
  end if
end sub

sub PrefetchNext(firstRun as boolean)
  if m.index = invalid then return

  cat = EffectiveCategory()
  list = m.index.categories[cat]
  if list = invalid or list.count() = 0 then
    ' Nothing to show in this category
    return
  end if

  ' Choose a random different URL than what's currently shown
  maxTries = 8
  tries = 0
  url = invalid
  currentUrl = m.current.uri

  while tries < maxTries
    idx = int(Rnd(0) * list.count())
    candidate = m.base + list[idx]
    if candidate <> currentUrl and candidate <> m.pendingUrl then
      url = candidate
      exit while
    end if
    tries = tries + 1
  end while

  if url = invalid then
    ' fallback to any entry
    url = m.base + list[int(Rnd(0) * list.count())]
  end if

  m.pendingUrl = url
  m.next.uri = url

  ' On first run, if next becomes ready, we swap immediately in onPosterStatus
end sub

sub onPosterStatus(event as Object)
  poster = event.GetRoSGNode()
  status = poster.loadStatus

  ' If the prefetch poster finished loading successfully and this is first frame, swap right away
  if poster = m.next then
    if status = "ready" then
      ' If nothing is visible yet (initial load), swap now
      if m.current.uri = invalid then
        SwapPosters()
      end if
    else if status = "failed"
      ' Try another image quickly (avoid infinite loops)
      if m.randomAttempts < 5 then
        m.randomAttempts = m.randomAttempts + 1
        PrefetchNext(false)
      else
        m.randomAttempts = 0
      end if
    end if
  else if poster = m.current
    if status = "failed" then
      ' Current failed (rare): immediately try to recover with next
      if m.next.loadStatus = "ready" then
        SwapPosters()
      else
        PrefetchNext(false)
      end if
    end if
  end if
end sub

sub SwapPosters()
  ' Make next visible, hide current, then swap references
  m.next.visible = true
  m.current.visible = false

  tmp = m.current
  m.current = m.next
  m.next = tmp

  ' Reset pending and attempts
  m.pendingUrl = invalid
  m.randomAttempts = 0
end sub
