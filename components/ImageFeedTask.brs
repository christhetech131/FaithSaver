' Runs on TASK thread. Fetch index.json from GitHub and return { uris: [ ... ] }

sub init()
  m.top.functionName = "go"
end sub

sub go()
  rawCategory = m.top.category
  if type(rawCategory) = "roString" then
    cat = LCase(rawCategory)
  else
    cat = ""
  end if
  if cat = "seasonal" or cat = "" then
    cat = CurrentSeasonName()
  end if

  rawRoot = "https://raw.githubusercontent.com/christhetech131/FaithSaver/main/"

  url = rawRoot + "index.json"
  ut  = CreateObject("roUrlTransfer")
  ut.SetCertificatesFile("common:/certs/ca-bundle.crt")
  ut.SetUrl(url)
  ut.SetRequest("GET")
  jsonStr = ut.GetToString()
  code = ut.GetResponseCode()

  uris = CreateObject("roArray", 20, true)
  seen = CreateObject("roAssociativeArray")

  if code = 200 and jsonStr <> invalid and jsonStr <> "" then
    data = ParseJson(jsonStr)
    if type(data) = "roAssociativeArray" then
      cats = data.categories
      if type(cats) = "roAssociativeArray" then
        list = cats[cat]
        if type(list) = "roArray" then
          i = 0
          while i < list.count()
            item = list[i]
            uri = NormalizeEntry(item, rawRoot)
            if uri <> "" and not seen.doesExist(uri) then
              seen[uri] = true
              uris.push(uri)
            end if
            i = i + 1
          end while
        end if
      end if
    end if
  else
    print "ImageFeedTask warning -> http"; code; " body ignored"
  end if

  print "ImageFeedTask complete -> category="; cat; " count="; uris.count()
  m.top.result = { uris: uris }
end sub

function NormalizeEntry(item as Dynamic, root as String) as String
  if type(item) <> "roString" then return ""
  entry = LTrim(RTrim(item))
  if entry = "" then return ""

  lower = LCase(entry)
  if Left(lower, 8) = "https://" or Left(lower, 7) = "http://" then
    return entry
  end if

  if Left(entry, 1) = "/" then entry = Mid(entry, 2)
  return root + entry
end function

function CurrentSeasonName() as String
  dt = CreateObject("roDateTime")
  mth = dt.GetMonth()

  if mth = 3 or mth = 4 or mth = 5 then
    return "spring"
  else if mth = 6 or mth = 7 or mth = 8 then
    return "summer"
  else if mth = 9 or mth = 10 or mth = 11 then
    return "fall"
  else
    return "winter"
  end if
end function
