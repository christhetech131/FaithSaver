' Entrypoints for the screensaver and its Settings UI

sub RunScreenSaver()
  m.port = CreateObject("roMessagePort")
  m.sg = CreateObject("roSGScreen")
  m.sg.SetMessagePort(m.port)
  scene = m.sg.CreateScene("FaithSaverScene")
  m.sg.Show()

  while true
    msg = wait(0, m.port)
    if type(msg) = "roSGScreenEvent" and msg.IsScreenClosed() then return
  end while
end sub

' Invoked by Roku when user opens the screensaver's Settings
sub RunScreenSaverSettings()
  port = CreateObject("roMessagePort")
  screen = CreateObject("roSGScreen")
  screen.SetMessagePort(port)
  settingsScene = screen.CreateScene("SettingsScene")
  screen.Show()

  while true
    msg = wait(0, port)
    if type(msg) = "roSGScreenEvent" and msg.IsScreenClosed() then return
  end while
end sub
