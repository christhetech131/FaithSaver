sub Main(args as dynamic)
  mode = "preview"

  if type(args) = "roAssociativeArray" then
    if args.doesExist("launchMode") then
      candidate = LCase(args.launchMode)
      if candidate <> "" then mode = candidate
    end if
  end if

  print "Main() -> launchMode=" ; mode

  if mode = "settings" then
    RunScreenSaverSettings()
  else if mode = "screensaver" or mode = "saver" then
    RunScreenSaver()
  else if mode = "preview" then
    RunScreenSaverPreview()
  else
    RunScreenSaverPreview()
  end if
end sub

sub RunScreenSaverSettings()
  print "RunScreenSaverSettings()"
  screen = CreateObject("roSGScreen")
  port = CreateObject("roMessagePort")
  screen.SetMessagePort(port)

  scene = screen.CreateScene("SettingsScene")
  scene.observeField("close", port)
  scene.close = false

  screen.Show()
  WaitForClose(screen, scene, port)
end sub

sub RunScreenSaverPreview()
  RunSaverScene("preview")
end sub

sub RunScreenSaver()
  RunSaverScene("screensaver")
end sub

sub RunSaverScene(mode as String)
  print "RunSaverScene(" ; mode ; ")"
  screen = CreateObject("roSGScreen")
  port = CreateObject("roMessagePort")
  screen.SetMessagePort(port)

  scene = screen.CreateScene("SaverScene")
  scene.mode = mode
  scene.observeField("close", port)
  scene.close = false

  screen.Show()
  WaitForClose(screen, scene, port)
end sub

sub WaitForClose(screen as Object, scene as Object, port as Object)
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
