sub Main(args as dynamic)
  print "Main() -> launching preview"
  RunScreenSaverPreview()
end sub

sub RunScreenSaverSettings()
  print "RunScreenSaverSettings()"
  screen = CreateObject("roSGScreen") : port = CreateObject("roMessagePort")
  screen.SetMessagePort(port)
  scene = screen.CreateScene("SettingsScene")
  scene.observeField("close", port)
  scene.close = false
  screen.Show()
  while true
    msg = wait(100, port)
    if type(msg) = "roSGScreenEvent" and msg.isScreenClosed() then return
    if type(msg) = "roSGNodeEvent" then
      if msg.getNode() = scene and msg.getField() = "close" and msg.getData() = true then
        screen.Close()
        return
      end if
    end if
  end while
end sub

sub RunScreenSaverPreview()
  print "RunScreenSaverPreview()"
  screen = CreateObject("roSGScreen") : port = CreateObject("roMessagePort")
  screen.SetMessagePort(port)
  scene = screen.CreateScene("SaverScene")
  scene.mode = "preview"
  scene.observeField("close", port)
  scene.close = false
  screen.Show()
  while true
    msg = wait(100, port)
    if type(msg) = "roSGScreenEvent" and msg.isScreenClosed() then return
    if type(msg) = "roSGNodeEvent" then
      if msg.getNode() = scene and msg.getField() = "close" and msg.getData() = true then
        screen.Close()
        return
      end if
    end if
  end while
end sub

sub RunScreenSaver()
  print "RunScreenSaver()"
  screen = CreateObject("roSGScreen") : port = CreateObject("roMessagePort")
  screen.SetMessagePort(port)
  scene = screen.CreateScene("SaverScene")
  scene.mode = "screensaver"
  scene.observeField("close", port)
  scene.close = false
  screen.Show()
  while true
    msg = wait(100, port)
    if type(msg) = "roSGScreenEvent" and msg.isScreenClosed() then return
    if type(msg) = "roSGNodeEvent" then
      if msg.getNode() = scene and msg.getField() = "close" and msg.getData() = true then
        screen.Close()
        return
      end if
    end if
  end while
end sub
