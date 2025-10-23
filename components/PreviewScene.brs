' PreviewScene — offline-only preview that cycles images via UP/DOWN.

sub init()
  ' Node refs
  m.bg      = m.top.findNode("bg")
  m.img     = m.top.findNode("img")
  m.title   = m.top.findNode("title")
  m.hint    = m.top.findNode("hint")
  m.overlay = m.top.findNode("overlay")

  ' Ensure we actually receive keys
  if m.top.doesExist("focusable") then m.top.focusable = true
  m.top.setFocus(true)

  ' Build the list of offline images
  m.uris = buildOfflineUriList("pkg:/images/offline")
  if m.uris = invalid or m.uris.count() = 0 then
    m.uris = CreateObject("roArray", 1, true)
    m.uris.push("pkg:/images/FaithSaver-Splash-1920x1080.jpg")
  end if

  ' Choose starting index based on saved category if possible
  m.index = findSavedStartIndex(m.uris)

  ' Initial render
  showCurrent()
end sub

' Returns an roArray of URIs (strings) to files in the folder with image extensions
function buildOfflineUriList(folder as string) as object
  fs = CreateObject("roFileSystem")
  if fs = invalid then return invalid

  list = fs.GetDirectoryListing(folder)
  if list = invalid then return invalid

  uris = CreateObject("roArray", list.count(), true)
  i = 0
  while i < list.count()
    name = list[i]
    if type(name) = "String" and name <> "" then
      lower = LCase(name)
      if Right(lower, 4) = ".jpg" or Right(lower, 5) = ".jpeg" or Right(lower, 4) = ".png" then
        uris.push(folder + "/" + name)
      end if
    end if
    i = i + 1
  end while
  return uris
end function

' Compute the preferred starting index from saved category's offline filename if it exists
function findSavedStartIndex(uris as object) as integer
  saved = getSavedCategory()
  expected = offlineFilenameForKey(saved)
  if expected <> "" then
    expectedUri = "pkg:/images/offline/" + expected
    i = 0
    while i < uris.count()
      if LCase(uris[i]) = LCase(expectedUri) then return i
      i = i + 1
    end while
  end if
  return 0
end function

function offlineFilenameForKey(key as string) as string
  if key = "seasonal" then return "seasonal.jpg"
  if key = "animals"  then return "animals.jpg"
  if key = "fall"     then return "fall.jpg"
  if key = "geology"  then return "geology.jpg"
  if key = "scenery"  then return "scenery.jpg"
  if key = "space"    then return "space.jpg"
  if key = "spring"   then return "spring.jpg"
  if key = "summer"   then return "summer.jpg"
  if key = "textures" then return "textures.jpg"
  if key = "winter"   then return "winter.jpg"
  return ""
end function

function getSavedCategory() as string
  reg = CreateObject("roRegistrySection", "FaithSaver")
  if reg <> invalid then
    v = reg.Read("category", "animals")
    if type(v) = "String" and v <> "" then return LCase(v)
  end if
  return "animals"
end function

sub showCurrent()
  if m.index < 0 then m.index = 0
  if m.index >= m.uris.count() then m.index = m.uris.count() - 1

  m.img.uri = m.uris[m.index]
  m.title.text = "Preview — " + stri(m.index + 1) + " / " + stri(m.uris.count())
end sub

function onKeyEvent(key as string, press as boolean) as boolean
  if not press then return false

  if key = "up" then
    m.index = m.index - 1
    if m.index < 0 then m.index = m.uris.count() - 1
    showCurrent()
    return true  ' handled; do not bubble
  end if

  if key = "down" then
    m.index = m.index + 1
    if m.index >= m.uris.count() then m.index = 0
    showCurrent()
    return true  ' handled; do not bubble
  end if

  if key = "back" then
    m.top.closeRequested = true
    return true  ' handled; do not bubble
  end if

  return false
end function
