sub Main(args as dynamic)
  passedArgs = args
  print "Main() argsType=" ; type(passedArgs)
  if type(passedArgs) = "roAssociativeArray" or type(passedArgs) = "roArray" then
    print "Main() argsCount=" ; passedArgs.Count()
  end if
  print "Main() argsType=" ; type(args)
  if false then print args ' Ensure Roku treats args as referenced even if logging removed
  print "Main()"
  ' Dev Installer: make "Go to app" useful
  RunScreenSaverPreview()
end sub

sub RunScreenSaverSettings()
  print "RunScreenSaverSettings()"
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
  print "RunScreenSaverPreview()"
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
  print "RunScreenSaver()"
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
