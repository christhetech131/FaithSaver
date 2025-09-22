sub init()
  m.top.observeField("url", "startFetch")
end sub

sub startFetch()
  url = m.top.url
  if url = invalid or url = "" then return

  x = CreateObject("roUrlTransfer")
  x.SetCertificatesFile("common:/certs/ca-bundle.crt")
  x.InitClientCertificates()
  x.SetUrl(url)
  data = invalid
  code = 0
  ' Blocking fetch is OK here (Task runs off UI thread)
  data = x.GetToString()
  code = x.GetResponseCode()

  if code = 200 and data <> invalid then
    m.top.response = data
  else
    m.top.error = "http:" + code.toStr()
  end if
end sub
