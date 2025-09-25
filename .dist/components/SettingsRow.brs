' components/SettingsRow.brs  (AARRGGBB colors + explicit visibility)

sub init()
  m.bar   = m.top.findNode("bar")
  m.label = m.top.findNode("label")
  m.check = m.top.findNode("check")

  ' Force navy bar color (AARRGGBB = FF 10 3A 57)
  m.bar.color = &hFF103A57

  ' Ensure text will render
  m.label.visible = true : m.label.opacity = 1.0
  m.check.visible = true : m.check.opacity = 1.0

  m.top.observeField("itemContent", "onContent")
  m.top.observeField("focused",     "onFocusChange")
  m.top.observeField("savedIndex",  "onSavedIndex")
end sub

sub onContent()
  c = m.top.itemContent
  if c = invalid then return
  m.label.text = c.title
  onFocusChange()
  onSavedIndex()
end sub

sub onFocusChange()
  f = m.top.focused
  m.bar.visible = f

  ' Focused row = white text; unfocused row = black text (AARRGGBB)
  if f then
    m.label.color = &hFFFFFFFF   ' white
  else
    m.label.color = &hFF000000   ' black
  end if
  m.check.color = &hFFFFFFFF
end sub

sub onSavedIndex()
  isSaved = (m.top.itemIndex = m.top.savedIndex)
  if isSaved then
    m.check.text = "*"          ' ASCII-safe selected marker
  else
    m.check.text = ""
  end if
end sub
