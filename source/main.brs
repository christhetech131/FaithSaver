sub RunScreenSaver()
  m.port = CreateObject("roMessagePort")
  m.sg = CreateObject("roSGScreen")
  m.sg.SetMessagePort(m.port)
  scene = m.sg.CreateScene("FaithSaverScene")
  m.sg.Show()
  ' Wait for terminate
  while true
    msg = wait(0, m.port)
    if type(msg) = "roSGScreenEvent" and msg.IsScreenClosed() then return
  end while
end sub
