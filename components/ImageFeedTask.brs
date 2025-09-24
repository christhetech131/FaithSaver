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
  if cat = "seasonal" or cat = "" then cat = CurrentSeasonName()

  rawRoot = "https://raw.githubusercontent.com/christhetech131/FaithSaver/main/"

  ' Fetch index.json
  url = rawRoot + "index.json"
  ut  = CreateObject("roUrlTransfer")
  ut.SetCertificatesFile("common:/certs/ca-bundle.crt")
  ut.SetUrl(url)
  ut.SetRequest("GET")
  jsonStr = ut.GetToString()
  code = ut.GetResponseCode()

  uris = CreateObject("roArray", 32, true)
  seen = CreateObject("roAssociativeArray")

  if jsonStr = invalid or jsonStr = "" then
    print "ImageFeedTask warning -> empty response code="; code
  else if code <> 200 then
    print "ImageFeedTask warning -> http"; code; " body ignored"
  else
    data = ParseJson(jsonStr)
    if type(data) = "roAssociativeArray" and data.categories <> invalid then
      list = data.categories[cat]
      if type(list) = "roArray" then
        i = 0 : while i < list.count()
          item = list[i]
          if type(item) = "roString" then
            entry = RTrim(LTrim(item))
            if entry <> "" then
              lower = LCase(entry)
              uri = ""
              if left(lower, 8) = "https://" or left(lower, 7) = "http://" then
                uri = entry
              else
                if left(entry, 1) = "/" then entry = Mid(entry, 2)
                uri = rawRoot + entry
              end if
              if uri <> "" and not seen.doesExist(uri) then
                seen[uri] = true
                uris.push(uri)
              end if
            end if
          end if
          i = i + 1
        end while
      end if
    end if
  end if

  print "ImageFeedTask complete -> category="; cat; " count="; uris.count()
  m.top.result = { uris: uris }
end sub

function CurrentSeasonName() as String
  dt = CreateObject("roDateTime") : mth = dt.GetMonth()
  if mth = 3 or mth = 4 or mth = 5 then return "spring"
  if mth = 6 or mth = 7 or mth = 8 then return "summer"
  if mth = 9 or mth = 10 or mth = 11 then return "fall"
  return "winter"
end function
