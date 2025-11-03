' AboutOverlay.brs — wrapped paragraph on left, QR on right, README link at bottom-left

sub init()
  m.title       = m.top.findNode("title")
  m.body        = m.top.findNode("body")
  m.sep         = m.top.findNode("sep")
  m.readmeLabel = m.top.findNode("readmeLabel")
  m.readmeUrl   = m.top.findNode("readmeUrl")
  m.qrCaption   = m.top.findNode("qrCaption")

  ' Visual styles
  colorNavy  = &h103A57FF
  colorBlack = &h000000FF
  colorMuted = &h223041FF

  if m.title <> invalid then m.title.color = colorNavy
  if m.sep   <> invalid then m.sep.blendColor = colorNavy

  if m.body <> invalid then
    m.body.color = colorBlack
    m.body.numLines = 8
    desc = "FaithSaver is a lightweight screensaver that shows faith-based imagery from a public GitHub repository. Open the project README to learn how to contribute images."
    m.body.text = desc
  end if

  if m.readmeLabel <> invalid and m.readmeUrl <> invalid then
    m.readmeLabel.color = colorMuted
    m.readmeLabel.text  = "README (project details):"
    m.readmeUrl.color   = colorMuted
    m.readmeUrl.text    = "https://github.com/christhetech131/FaithSaver#readme"
  end if

  if m.qrCaption <> invalid then
    m.qrCaption.color = colorMuted
    m.qrCaption.text  = "Scan to open submissions and info"
  end if

  m.top.setFocus(true)
end sub
