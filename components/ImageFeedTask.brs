sub init()
  m.top.functionName = "run"
end sub

sub run()
  m.top.status = "running"

  cat = normalizeCategory(m.top.category)
  offlineList = buildOfflineList(cat)
  if offlineList.count() = 0 and cat <> "animals" then
    cat = "animals"
    offlineList = buildOfflineList(cat)
  end if

  result = []
  seen = {}
  addUnique(result, seen, offlineList)

  remoteList = loadRemoteList(cat)
  addUnique(result, seen, remoteList)

  m.top.items = result
  m.top.status = "done"
  print "[FaithSaver] ImageFeedTask items=" + result.count().toStr()
end sub

sub addUnique(dest as Object, seen as Object, src as Object)
  if type(dest) <> "roArray" then return
  if type(seen) <> "roAssociativeArray" then return
  if type(src) <> "roArray" then return

  for each item in src
    if type(item) = "String" then
      trimmed = TrimString(item)
      if trimmed <> "" then
        key = LCase(trimmed)
        if not seen.doesExist(key) then
          dest.push(trimmed)
          seen[key] = true
        end if
      end if
    end if
  next
end sub

function loadRemoteList(cat as String) as Object
  result = []
  jsonText = readTextFile("pkg:/index.json")
  if jsonText = "" then
    remoteUrl = "https://raw.githubusercontent.com/christhetech131/FaithSaver/main/index.json"
    remoteText = httpGet(remoteUrl)
    if type(remoteText) = "String" then
      jsonText = remoteText
    end if
  end if

  if jsonText <> "" then
    parsed = ParseJSON(jsonText)
    if type(parsed) = "roAssociativeArray" then
      arr = parsed[cat]
      if type(arr) <> "roArray" then
        arr = parsed["animals"]
      end if
      if type(arr) = "roArray" then
        for each entry in arr
          if type(entry) = "String" then
            normalized = normalizeRemoteEntry(entry)
            if normalized <> "" then result.push(normalized)
          else if type(entry) = "roAssociativeArray" and entry.doesExist("uri") then
            uri = normalizeRemoteEntry(entry.uri)
            if uri <> "" then result.push(uri)
          end if
        next
      end if
    end if
  end if

  return result
end function

function normalizeRemoteEntry(value as Dynamic) as String
  uri = TrimString(value)
  if uri = "" then return ""
  lower = LCase(uri)
  if Left(lower, 5) = "pkg:/" then return uri
  if Left(lower, 4) = "http" then return uri
  if Left(uri, 1) = "/" then uri = Mid(uri, 2)
  return "https://raw.githubusercontent.com/christhetech131/FaithSaver/main/" + uri
end function

function readTextFile(path as String) as String
  ba = CreateObject("roByteArray")
  if ba = invalid then return ""
  if not ba.ReadFile(path) then return ""
  if ba.Count() = 0 then return ""
  return ba.ToAsciiString()
end function

function buildOfflineList(cat as String) as Object
  list = []
  base = "pkg:/images/offline/" + cat + "/"
  for i = 1 to 24
    idx = zeroPad(i)
    path = base + cat + "-" + idx + ".jpg"
    ba = CreateObject("roByteArray")
    if ba = invalid then exit for
    if ba.ReadFile(path) then
      if ba.Count() > 0 then
        list.push(path)
      end if
    else if i > 9 then
      exit for
    end if
  end for
  return list
end function

function httpGet(url as String) as Dynamic
  if type(url) <> "String" or url = "" then return invalid
  xfer = CreateObject("roUrlTransfer")
  if xfer = invalid then return invalid
  port = CreateObject("roMessagePort")
  if port = invalid then return invalid
  xfer.SetMessagePort(port)
  ok = true
  ok = ok and xfer.SetUrl(url)
  if not ok then return invalid
  xfer.SetCertificatesFile("common:/certs/ca-bundle.crt")
  xfer.InitClientCertificates()
  xfer.RetainBodyOnError(true)
  rsp = xfer.GetToString()
  return rsp
end function

function TrimString(s as Dynamic) as String
  if type(s) <> "String" then return ""
  return LTrim(RTrim(s))
end function

function zeroPad(i as Integer) as String
  if i < 10 then return "0" + i.toStr()
  return i.toStr()
end function

function normalizeCategory(value as Dynamic) as String
  if type(value) <> "String" then return "animals"
  v = LCase(TrimString(value))
  if v = "" then return "animals"
  return v
end function
