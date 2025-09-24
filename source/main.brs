sub Main(args as dynamic)
  print "Main() -> launching preview"
  RunScreenSaverPreview()
  passedArgs = args
  print "Main() argsType=" ; type(passedArgs)
  if type(passedArgs) = "roAssociativeArray" or type(passedArgs) = "roArray" then
    print "Main() argsCount=" ; passedArgs.Count()
  end if

  print "Main() argsType=" ; type(args)
  if false then print args ' Ensure Roku treats args as referenced even if logging removed
  print "Main()"

  mode = "screensaver"
  if type(args) = "roAssociativeArray" then
    if args.DoesExist("launchMode") then mode = LCase(args.launchMode)
  end if

  if mode = "preview" then
    RunScreenSaverPreview()
  else if mode = "settings" then
    RunScreenSaverSettings()
  else
    RunScreenSaver()
  end if
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
