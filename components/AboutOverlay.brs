' AboutOverlay.brs — wrapped paragraph on left, QR on right, README link at bottom-left

sub init()
  m.title  = m.top.findNode("title")
  m.body   = m.top.findNode("body")
  m.sep    = m.top.findNode("sep")
  m.readmeLabel = m.top.findNode("readmeLabel")
  m.readmeUrl   = m.top.findNode("readmeUrl")
  m.qrCaption   = m.top.findNode("qrCaption")

  ' Visual styles
  colorNavy  = &h103A57FF
  colorBlack = &h000000FF
  colorMuted = &h223041FF

  m.title.color = colorNavy
  m.title.text = "About FaithSaver"

  m.body.color = colorBlack
  m.body.text = "FaithSaver is a Roku screensaver that displays faith-based images. This has been a passion project of mine to bring the Word of God into the living room. Settings let you choose a category. If you want to submit an image, scan the QR! Submissions: finished images (with verse) or raw photos for curation. Images should be baseline sRGB JPG/PNG, 1920×1080 or larger. Learn more and contribute on GitHub."

  m.readmeLabel.color = colorNavy
  m.readmeLabel.text = "README (project details):"
  m.readmeUrl.color = colorMuted
  m.readmeUrl.text = "https://github.com/christhetech131/FaithSaver#readme"

  if m.qrCaption <> invalid then
    m.qrCaption.color = colorMuted
    m.qrCaption.text = "Scan to open submissions and info"
  end if

  m.top.setFocus(true)
end sub

function onKeyEvent(key as string, press as boolean) as boolean
  if not press then return false
  key = LCase(key)
  if key = "back" or key = "ok" then
    m.top.close = true
    return true
  end if
  return true
end function
