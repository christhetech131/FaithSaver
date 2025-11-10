' source/logger.brs — silent diagnostics

Function FS_LogPath() as String : return "tmp:/faithsaver.log" : End Function

Function FS_DiagEnabled() as Boolean
  sec = CreateObject("roRegistrySection", "faithsaver")
  return sec.Read("diag","0") = "1"
End Function

Sub FS_SetDiag(on as Boolean)
  sec = CreateObject("roRegistrySection", "faithsaver")
  if on then sec.Write("diag","1") else sec.Delete("diag")
  sec.Flush()
End Sub

Sub FS_Log(msg as String)
  if not FS_DiagEnabled() then return  ' stays silent unless armed
  dt = CreateObject("roDateTime")
  line = dt.ToISOString()+" | "+msg+chr(10)

  ba = CreateObject("roByteArray") : ba.FromAsciiString(line)
  old = CreateObject("roByteArray")
  if old.ReadFile(FS_LogPath())
    if old.Count() > 200000 then old = old.Sub(old.Count()-150000,150000)
    old.Append(ba) : old.WriteFile(FS_LogPath())
  else
    ba.WriteFile(FS_LogPath())
  end if

  FS_PostDiag(line) ' optional webhook; safe no-op if URL=""
End Sub

Sub FS_PostDiag(line as String)
  url = "" ' e.g. "https://hooks.zapier.com/hooks/catch/<id>/<token>"
  if url = "" or not FS_DiagEnabled() then return
  u = CreateObject("roUrlTransfer")
  u.SetUrl(url) : u.AddHeader("Content-Type","application/json")
  u.AsyncPostFromString("{""t"":""" + line + """}")
End Sub

Function FS_SyslogAttach(port as Object) as Object
  sys = CreateObject("roSystemLog") : sys.SetMessagePort(port)
  sys.EnableType("http.connect") : sys.EnableType("http.error")
  sys.EnableType("http.complete") : sys.EnableType("bandwidth.minute")
  return sys
End Function
