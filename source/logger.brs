' source/logger.brs — private diagnostics (file + optional webhook)
' Turn on via your hidden sequence. Writes to tmp:/faithsaver.log.
' Optionally mirror to a webhook (set FS_WebhookUrl()).
' Tested patterns: roUrlTransfer PostFromString, tmp:/ writable store.

Function FS_LogPath() as String : return "tmp:/faithsaver.log" : End Function

' TODO: set your private webhook URL here (or return "").
Function FS_WebhookUrl() as String
  return "https://hooks.zapier.com/hooks/catch/24558472/us7p4qu/"
End Function

Function FS_DiagEnabled() as Boolean
  sec = CreateObject("roRegistrySection", "faithsaver")
  return sec.Read("diag","0") = "1"
End Function

' Enable/disable diagnostics. When turning off, auto-export the file (optional).
Sub FS_SetDiag(on as Boolean)
  sec = CreateObject("roRegistrySection", "faithsaver")
  if on then
    sec.Write("diag","1")
  else
    sec.Delete("diag")
  end if
  sec.Flush()

  if on then
    FS_Tee("[diag] enabled")
  else
    FS_Tee("[diag] disabled")
    ' Auto-export current log. Comment out if you prefer manual export.
    FS_ExportLog()
  end if
End Sub

' Print always; also write to file (and webhook) when diagnostics are enabled.
Sub FS_Tee(msg as String)
  print msg
  FS_Log(msg)
End Sub

' Write a single line to tmp:/faithsaver.log (and mirror to webhook).
Sub FS_Log(msg as String)
  if not FS_DiagEnabled() then return

  dt = CreateObject("roDateTime")
  line = dt.ToISOString() + " | " + msg + chr(10)

  baLine = CreateObject("roByteArray") : baLine.FromAsciiString(line)
  baOld  = CreateObject("roByteArray")
  if baOld.ReadFile(FS_LogPath())
    ' Keep file size bounded (~200 KB)
    if baOld.Count() > 200000 then baOld = baOld.Sub(baOld.Count()-150000, 150000)
    baOld.Append(baLine)
    baOld.WriteFile(FS_LogPath())
  else
    baLine.WriteFile(FS_LogPath())
  end if

  FS_PostDiag(line)
End Sub

' POST a single line to webhook (if configured)
Sub FS_PostDiag(line as String)
  url = FS_WebhookUrl()
  if url = "" or not FS_DiagEnabled() then return
  u = CreateObject("roUrlTransfer")
  u.SetUrl(url)
  u.AddHeader("Content-Type","text/plain; charset=utf-8")
  ' For JSON: set content-type to application/json and wrap as needed.
  u.PostFromString(line)
End Sub

' Export the entire file to webhook as one POST (plain text).
' Returns true on best-effort success.
Function FS_ExportLog() as Boolean
  url = FS_WebhookUrl()
  if url = "" then return false

  ba = CreateObject("roByteArray")
  if not ba.ReadFile(FS_LogPath()) then return false

  u = CreateObject("roUrlTransfer")
  u.SetUrl(url)
  u.AddHeader("Content-Type","text/plain; charset=utf-8")
  ok = u.PostFromString(ba.ToAsciiString())
  FS_Tee("[diag] export " + (ok and "OK" or "FAILED"))
  return ok
End Function

' Attach system logging (HTTP/connect/errors/bandwidth) to your message port.
' In your main loop, when you receive roSystemLogEvent, call FS_Tee with details.
Function FS_SyslogAttach(port as Object) as Object
  sys = CreateObject("roSystemLog")
  sys.SetMessagePort(port)
  sys.EnableType("http.connect")
  sys.EnableType("http.error")
  sys.EnableType("http.complete")
  sys.EnableType("bandwidth.minute")
  return sys
End Function
