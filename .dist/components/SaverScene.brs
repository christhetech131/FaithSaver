function onKeyEvent(key as String, press as Boolean) as Boolean
  if not press then return false
  k = LCase(key)

  ' Normalize mode
  mm = LCase(m.mode)
  if mm = "screensaver" then mm = "saver"

  if mm = "preview"
    if k = "back" then
      m.top.close = true : return true
    else if k = "left" or k = "up"
      ShowPrev() : return true
    else if k = "right" or k = "down"
      ShowNext() : return true
    else if k = "ok"
      ' make OK exit preview quickly if you like; or set false to keep scrolling only
      m.top.close = true : return true
    end if
    return false
  else
    ' Production saver: ANY key exits (Home is handled by Roku)
    m.top.close = true
    return true
  end if
end function
