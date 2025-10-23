sub init()
  m.bar = m.top.findNode("bar")
  m.lbl = m.top.findNode("lbl")
  m.NAVY  = &hFF083554
  m.WHITE = &hFFFFFFFF

  ' one-shot timer to re-assert color one frame later (beats list tinting on picky firmware)
  m.fixTimer = CreateObject("roSGNode", "Timer")
  m.fixTimer.observeField("fire", "applyColorFix")
  m.fixTimer.duration = 0.01
  m.fixTimer.repeat = false

  if m.bar <> invalid then
    m.bar.color = m.NAVY
    m.bar.visible = false
  end if
  if m.lbl <> invalid then m.lbl.color = m.NAVY
  print "[FS][SettingsRow] init bar="; (m.bar <> invalid); " lbl="; (m.lbl <> invalid)
end sub

sub onContent()
  c = m.top.itemContent
  title = ""
  if c <> invalid and c.DoesExist("title") then
    title = c.title
  end if

  if m.lbl <> invalid then
    m.lbl.text = title
    if m.top.itemHasFocus then
      m.lbl.color = m.WHITE
    else
      m.lbl.color = m.NAVY
    end if
    ' re-assert once after list finishes its own pass
    StartFixTimer()
  end if

  if m.bar <> invalid then m.bar.visible = m.top.itemHasFocus
  print "[FS][SettingsRow] onContent title='"; title; "'"
end sub

sub onFocus()
  hasFocus = m.top.itemHasFocus
  if m.bar <> invalid then m.bar.visible = hasFocus
  if m.lbl <> invalid then
    if hasFocus then
      m.lbl.color = m.WHITE
    else
      m.lbl.color = m.NAVY
    end if
    ' re-assert once after list finishes its own pass
    StartFixTimer()
  end if
  if hasFocus then
    print "[FS][SettingsRow] onFocus focus=true"
  else
    print "[FS][SettingsRow] onFocus focus=false"
  end if
end sub

sub StartFixTimer()
  if m.fixTimer <> invalid then
    m.fixTimer.control = "start"
  end if
end sub

sub applyColorFix()
  ' apply the same color again to ensure our value wins last
  if m.lbl = invalid then return
  if m.top.itemHasFocus then
    m.lbl.color = m.WHITE
  else
    m.lbl.color = m.NAVY
  end if
end sub
