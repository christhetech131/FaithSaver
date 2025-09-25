' components/ImageFeedTask.brs
' Simple offline feed generator; safe baseline while you stabilize online feed.
' ASCII only.

sub init()
  m.top.functionName = "run"
end sub

sub run()
  cat = LCase(m.top.category)
  if cat = "" or cat = "seasonal" then
    cat = CurrentSeasonName()
  end if

  m.top.error = ""
  m.top.uris  = BuildOfflineUris(cat)
end sub

function BuildOfflineUris(cat as String) as Object
  base = "pkg:/images/offline/"
  map = {
    animals:  "animals.jpg"
    fall:     "fall.jpg"
    geology:  "geology.jpg"
    scenery:  "scenery.jpg"
    space:    "space.jpg"
    spring:   "spring.jpg"
    summer:   "summer.jpg"
    textures: "textures.jpg"
    winter:   "winter.jpg"
    default:  "default.jpg"
  }

  uris = CreateObject("roArray", 0, true)

  if map.doesExist(cat) then
    uris.push(base + map[cat])
  else
    uris.push(base + map["default"])
  end if

  ' Inflate to a small carousel so preview has a few to scroll
  while uris.count() < 10
    uris.push(uris[0])
  end while

  return uris
end function

function CurrentSeasonName() as String
  dt = CreateObject("roDateTime")
  mth = dt.GetMonth()
  if mth = 3 or mth = 4 or mth = 5 then return "spring"
  if mth = 6 or mth = 7 or mth = 8 then return "summer"
  if mth = 9 or mth = 10 or mth = 11 then return "fall"
  return "winter"
end function
