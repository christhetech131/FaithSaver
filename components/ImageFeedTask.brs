' Runs on TASK thread. Fetch index.json from GitHub and return { uris: [ ... ] }

sub init()
  m.top.functionName = "go"
end sub

sub go()
  cat = LCase(m.top.category)
  if cat = "seasonal" or cat = "" then cat = CurrentSeasonName()

  ' Fetch index.json
  url = "https://raw.githubusercontent.com/christhetech131/FaithSaver/main/index.json"
  ut  = CreateObject("roUrlTransfer")
  ut.SetCertificatesFile("common:/certs/ca-bundle.crt")
  ut.SetUrl(url)
  ut.SetRequest("GET")
  jsonStr = ut.GetToString()

  uris = CreateObject("roArray", 20, true)

  if jsonStr <> invalid and jsonStr <> "" then
    p = CreateObject("roJSONParser")
    data = invalid
    ' Protect parsing
    err = false
    try
      data = p.Parse(jsonStr)
    catch
      err = true
    end try

    if not err and data <> invalid and data.categories <> invalid then
      list = data.categories[cat]
      if type(list) = "roArray" then
        i = 0 : while i < list.count()
          item = list[i]
          if type(item) = "roString" then
            ' If item looks relative, prefix with raw GitHub root of repo
            if left(item,8) = "https://" or left(item,7) = "http://" then
              uris.push(item)
            else
              ' assume stored path like "animals/file.jpg"
              raw = "https://raw.githubusercontent.com/christhetech131/FaithSaver/main/" + item
              uris.push(raw)
            end if
          end if
          i = i + 1
        end while
      end if
    end if
  end if

  m.top.result = { uris: uris }
end sub

function CurrentSeasonName() as String
  dt = CreateObject("roDateTime") : mth = dt.GetMonth()
  if mth = 3 or mth = 4 or mth = 5 then return "spring"
  if mth = 6 or mth = 7 or mth = 8 then return "summer"
  if mth = 9 or mth = 10 or mth = 11 then return "fall"
  return "winter"
end function
