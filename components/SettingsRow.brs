sub init()
  m.bar   = m.top.findNode("bar")
  m.label = m.top.findNode("label")
  m.top.observeField("title","onTitle")
  m.top.observeField("isFocused","onFocusChange")
end sub

sub onTitle()
  m.label.text = m.top.title
end sub

sub onFocusChange()
  m.bar.visible = m.top.isFocused
  m.label.color = &h000000FF
end sub
