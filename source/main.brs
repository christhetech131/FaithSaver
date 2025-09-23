sub Main(args as dynamic)
  ' Dev Installer: make "Go to app" useful
  RunScreenSaverPreview()
end sub

sub RunScreenSaverSettings()
  screen = CreateObject("roSGScreen") : port = CreateObject("roMessagePort")
  screen.SetMessagePort(port)
  scene = screen.CreateScene("SettingsScene")
  screen.Show()
  while true
    msg = wait(100, port)
    if type(msg) = "roSGScreenEvent" and msg.isScreenClosed() then return
    if scene.close = true then screen.Close() : return
  end while
end sub

sub RunScreenSaverPreview()
  screen = CreateObject("roSGScreen") : port = CreateObject("roMessagePort")
  screen.SetMessagePort(port)
  scene = screen.CreateScene("SaverScene")
  scene.mode = "preview"
  screen.Show()
  while true
    msg = wait(100, port)
    if type(msg) = "roSGScreenEvent" and msg.isScreenClosed() then return
    if scene.close = true then screen.Close() : return
  end while
end sub

sub RunScreenSaver()
  screen = CreateObject("roSGScreen") : port = CreateObject("roMessagePort")
  screen.SetMessagePort(port)
  scene = screen.CreateScene("SaverScene")
  scene.mode = "screensaver"
  screen.Show()
  while true
    msg = wait(100, port)
    if type(msg) = "roSGScreenEvent" and msg.isScreenClosed() then return
    if scene.close = true then screen.Close() : return
  end while
end sub
