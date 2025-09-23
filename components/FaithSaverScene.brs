' components/FaithSaverScene.brs  (minimal to get Preview drawing)
' - Shows a local image immediately
' - Back exits Preview

sub init()
  print "Saver.init (minimal)"
  m.img = m.top.findNode("img")

  ShowLocalFallback()

  ' Ensure scene captures Back
  m.top.setFocus(true)
end sub

function onKeyEvent(key as string, press as boolean) as boolean
  if not press then return false
  if key = "back" then
    print "Saver.onKeyEvent back -> close"
    m.top.close = true
    return true
  end if
  return false
end function

sub ShowLocalFallback()
  fs = CreateObject("roFileSystem")
  p = "pkg:/images/offline/default.jpg"
  if not fs.Exists(p) then
    ' Try first file in offline/
    dir = "pkg:/images/offline"
    items = fs.ListDir(dir)
    if items <> invalid then
      for each f in items
        lf = LCase(f)
        if Right(lf,4) = ".jpg" or Right(lf,5) = ".jpeg" or Right(lf,4) = ".png" then
          p = dir + "/" + f
          exit for
        end if
      end for
    end if
  end if
  if not fs.Exists(p) then
    p = "pkg:/images/FaithSaver-Poster-540x405.jpg"
  end if
  m.img.uri = p
  print "Saver.ShowLocalFallback -> "; p
end sub
