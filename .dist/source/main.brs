' source/main.brs
' Entry + wiring: preview, saver (production), and settings
' ASCII only.

sub Main(args as Dynamic)
  mode = "preview"

  if type(args) = "roAssociativeArray"
    ' Roku sets this when the user opens the screensaver’s Settings app
    if args.runScreenSaverSettings = true then
      RunScreenSaverSettings()
      return
    end if

    ' Roku sets this when it launches you as an actual screensaver
    if args.runAsScreensaver = true then
      mode = "saver"
    end if
  end if

  RunSaverScene(mode)
end sub

sub RunScreenSaverSettings()
  screen = CreateObject("roSGScreen")
  port   = CreateObject("roMessagePort")
  screen.SetMessagePort(port)

  scene = screen.CreateScene("SettingsScene")
  if scene = invalid then
    print "[FATAL] SettingsScene could not be created."
    return
  end if

  screen.Show()
  screen.SetScene(scene)
  scene.SetFocus(true)

  WaitForClose(screen, scene, port)
end sub

sub RunSaverScene(mode as String)
  screen = CreateObject("roSGScreen")
  port   = CreateObject("roMessagePort")
  screen.SetMessagePort(port)

  scene = screen.CreateScene("SaverScene")
  if scene = invalid then
    print "[FATAL] SaverScene could not be created."
    return
  end if

  ' Normalize: we accept "saver" or "screensaver" internally as "saver"
  if LCase(mode) = "screensaver" then mode = "saver"
  scene.mode = LCase(mode)

  ' Listen for close events emitted by the Scene
  scene.observeField("close", port)

  screen.Show()
  screen.SetScene(scene)
  scene.SetFocus(true)

  WaitForClose(screen, scene, port)
end sub

sub WaitForClose(screen as Object, scene as Object, port as Object)
  while true
    msg = wait(0, port)

    if type(msg) = "roSGScreenEvent" and msg.isScreenClosed() then return

    if type(msg) = "roSGNodeEvent"
      ' Compare roSGNode objects (avoid string vs node mismatch)
      n = invalid
      if GetInterface(msg, "ifSGNodeEvent") <> invalid and msg.getRoSGNode <> invalid then
        n = msg.getRoSGNode()
      end if

      if n = scene and msg.getField() = "close" and msg.getData() = true then
        screen.Close()
        return
      end if
    end if
  end while
end sub
