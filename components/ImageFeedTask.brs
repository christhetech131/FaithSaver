' ImageFeedTask.brs — GitHub Contents fetch (firmware-agnostic)
' Fetches /<category> from repo root, filters images, shuffles with a custom LCG, returns URLs.

sub init()
  m.top.functionName = "runTask"
end sub

sub runTask()
  cat = LCase(ToStringSafe(m.top.category))
  if cat = "" then cat = "animals"

  user   = "christhetech131"
  repo   = "FaithSaver"
  branch = "main"

  apiUrl = "https://api.github.com/repos/" + user + "/" + repo + "/contents/" + cat
  FSLogFeed("GET " + apiUrl)

  data = HttpGet(apiUrl)
  if data = invalid then
    FSLogFeed("ERROR: transport failed or empty response")
    m.top.items = []
    return
  end if

  json = ParseJsonSafe(data)
  if type(json) <> "roArray" then
    FSLogFeed("ERROR: JSON parse failed or not an array (type=" + Type(json) + ")")
    FSLogFeed("Body(head 320): " + LeftSafe(data, 320))
    m.top.items = []
    return
  end if

  files = []
  for each entry in json
    if type(entry) = "roAssociativeArray" then
      if LCase(ToStringSafe(entry["type"])) = "file" then
        name = ToStringSafe(entry["name"])
        if IsImageName(name) then
          raw = "https://raw.githubusercontent.com/" + user + "/" + repo + "/" + branch + "/" + cat + "/" + name
          files.push(raw)
        end if
      end if
    end if
  end for

  FSLogFeed("Discovered " + StrI(files.count()) + " image file(s) in '" + cat + "'")

  if files.count() = 0 then
    FSLogFeed("No images found. Verify repo path '/" + cat + "/*.(jpg|jpeg|png)' at root (no subfolders).")
    names = []
    for each e in json
      if type(e) = "roAssociativeArray" then names.push(ToStringSafe(e["name"]))
    end for
    FSLogFeed("Dir listing sample: " + JoinFirstN(names, 10))
    m.top.items = []
    return
  end if

  ShuffleArray(files)
  m.top.items = files
  FSLogFeed("OK items=" + StrI(files.count()))
end sub

' ---------- helpers ----------

function HttpGet(url as string) as dynamic
  ut = CreateObject("roURLTransfer")
  ut.SetCertificatesFile("common:/certs/ca-bundle.crt")
  ut.InitClientCertificates()
  ut.SetURL(url)
  ut.AddHeader("User-Agent","FaithSaver/1.0 (+roku)")
  ut.AddHeader("Accept","application/vnd.github+json")
  data = ut.GetToString()
  if data = invalid then return invalid
  if Len(data) = 0 then return invalid
  return data
end function

function IsImageName(name as string) as boolean
  n = LCase(name)
  if Right(n,4) = ".jpg" then return true
  if Right(n,5) = ".jpeg" then return true
  if Right(n,4) = ".png" then return true
  return false
end function

function ToStringSafe(v as dynamic) as string
  if v = invalid then return ""
  return v
end function

function LeftSafe(s as dynamic, n as integer) as string
  if s = invalid then return ""
  if type(s) <> "roString" and type(s) <> "String" then return ""
  if n <= 0 then return ""
  L = Len(s)
  if L <= n then return s
  return Left(s, n)
end function

function ParseJsonSafe(s as dynamic) as dynamic
  if s = invalid then return invalid
  if type(s) <> "roString" and type(s) <> "String" then return invalid
  j = invalid
  j = ParseJson(s)
  return j
end function

' Fisher–Yates using a simple LCG (no Randomize/Rnd/roRandom required)
sub ShuffleArray(arr as object)
  c = arr.count()
  if c <= 1 then return

  ' Seed from current time (seconds + milliseconds if available)
  dt = CreateObject("roDateTime")
  seed = dt.AsSeconds()
  ' LCG constants (glibc style)
  a = 1103515245
  m = 2147483648 ' 2^31
  inc = 12345

  i = c - 1
  while i > 0
    seed = (a * seed + inc) mod m
    ' Convert to an index 0..i
    j = seed mod (i + 1)
    tmp = arr[i] : arr[i] = arr[j] : arr[j] = tmp
    i = i - 1
  end while
end sub

function JoinFirstN(a as object, n as integer) as string
  if a = invalid then return ""
  c = a.count()
  if c = 0 then return ""
  k = n
  if k > c then k = c
  s = ""
  i = 0
  while i < k
    if i > 0 then s = s + ", "
    s = s + ToStringSafe(a[i])
    i = i + 1
  end while
  if c > k then s = s + ", ..."
  return s
end function

sub FSLogFeed(msg as string)
  print "[FaithSaver][Feed] "; msg
end sub
