sub init()
  m.bar = m.top.findNode("bar")
  m.lbl = m.top.findNode("lbl")
  m.NAVY  = &hFF083554
  m.WHITE = &hFFFFFFFF
  if m.lbl <> invalid then m.lbl.color = m.NAVY
  if m.bar <> invalid then m.bar.visible = false
  print "[FS][SettingsRow] init bar="; (m.bar <> invalid); " lbl="; (m.lbl <> invalid)
end sub

sub onContent()
  c = m.top.itemContent
  if c <> invalid and c.DoesExist("title")
    m.lbl.text = c.title
  else
    m.lbl.text = ""
  end if
  if m.lbl <> invalid then m.lbl.color = m.NAVY
  if m.bar <> invalid then m.bar.visible = m.top.itemHasFocus
  print "[FS][SettingsRow] onContent title='"; m.lbl.text; "'"
end sub

sub onFocus()
  if m.top.itemHasFocus then
    if m.bar <> invalid then m.bar.visible = true
    if m.lbl <> invalid then m.lbl.color = m.WHITE
    print "[FS][SettingsRow] onFocus focus=true"
  else
    if m.bar <> invalid then m.bar.visible = false
    if m.lbl <> invalid then m.lbl.color = m.NAVY
    print "[FS][SettingsRow] onFocus focus=false"
  end if
end sub
