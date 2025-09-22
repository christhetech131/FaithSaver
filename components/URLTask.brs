sub init()
  m.top.observeField("url", "startFetch")
end sub

sub startFetch()
  u = m.top.url
  if u = invalid or u = "" then return
  x = CreateObject("roUrlTransfer")
  x.SetCertificatesFile("common:/certs/ca-bundle.crt")
  x.InitClientCertificates()
  x.SetUrl(u)
  data = x.GetToString()
  code = x.GetResponseCode()
  if code = 200 and data <> invalid then
    m.top.response = data
  else
    m.top.error = "http:" + code.toStr()
  end if
end sub
