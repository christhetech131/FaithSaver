sub init()
  m.bar = m.top.findNode("bar")
  m.lbl = m.top.findNode("lbl")
  m.NAVY  = &hFF083554
  m.WHITE = &hFFFFFFFF

  if m.bar <> invalid then
    m.bar.color = m.NAVY
    m.bar.visible = false
  end if

  if m.lbl <> invalid then
    m.lbl.color = m.NAVY
    m.lbl.blendColor = m.NAVY
  end if

  applyFocusVisuals(m.top.itemHasFocus)

  print "[FS][SettingsRow] init bar="; (m.bar <> invalid); " lbl="; (m.lbl <> invalid)
end sub

sub onContent()
  content = m.top.itemContent
  title = ""
  if content <> invalid and content.DoesExist("title") then
    title = content.title
  end if

  if m.lbl <> invalid then
    m.lbl.text = title
  end if

  applyFocusVisuals(m.top.itemHasFocus)

  print "[FS][SettingsRow] onContent title='"; title; "'"
end sub

sub onFocus()
  hasFocus = m.top.itemHasFocus
  applyFocusVisuals(hasFocus)
  if hasFocus then
    print "[FS][SettingsRow] onFocus focus=true"
  else
    print "[FS][SettingsRow] onFocus focus=false"
  end if
end sub

sub applyFocusVisuals(hasFocus as boolean)
  if m.bar <> invalid then
    m.bar.visible = hasFocus
    m.bar.color = m.NAVY
  end if

  if m.lbl <> invalid then
    if hasFocus then
      m.lbl.color = m.WHITE
      m.lbl.blendColor = m.WHITE
    else
      m.lbl.color = m.NAVY
      m.lbl.blendColor = m.NAVY
    end if
  end if
end sub
