' Runs on TASK thread. Fetch index.json from GitHub and return { uris: [ ... ] }

sub init()
  m.top.functionName = "go"
end sub

sub go()
  rawCategory = m.top.category
  if type(rawCategory) = "roString" or type(rawCategory) = "String" then
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

  uris = CreateObject("roArray", 20, true)
  seen = CreateObject("roAssociativeArray")

  if type(jsonStr) = "roString" or type(jsonStr) = "String" then
    if Len(jsonStr) > 0 then
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
      print "ImageFeedTask warning -> empty JSON body"
    end if
  else
    print "ImageFeedTask warning -> empty response"
  end if

  print "ImageFeedTask complete -> category="; cat; " count="; uris.count()
  m.top.result = { uris: uris }
end sub

function NormalizeEntry(item as Dynamic, root as String) as String
  t = type(item)
  if t <> "roString" and t <> "String" then return ""
  entry = TrimWhitespace(item)
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

  select case mth
    case 3, 4, 5
      return "spring"
    case 6, 7, 8
      return "summer"
    case 9, 10, 11
      return "fall"
  end select

  return "winter"
end function

function TrimWhitespace(input as Dynamic) as String
  if input = invalid then return ""

  t = type(input)
  if t <> "roString" and t <> "String" then return ""

  text = input
  total = Len(text)
  if total <= 0 then return ""

  startIndex = 0
  while startIndex < total
    ch = Asc(Mid(text, startIndex + 1, 1))
    if ch > 32 then exit while
    startIndex = startIndex + 1
  end while

  endIndex = total - 1
  while endIndex >= startIndex
    ch = Asc(Mid(text, endIndex + 1, 1))
    if ch > 32 then exit while
    endIndex = endIndex - 1
  end while

  if endIndex < startIndex then return ""

  return Mid(text, startIndex + 1, endIndex - startIndex + 1)
end function
