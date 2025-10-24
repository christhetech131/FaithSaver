' AboutOverlay.brs — modal overlay with about image (and QR), right-pane info, README link

sub init()
  m.scrim = m.top.findNode("scrim")
  m.panel = m.top.findNode("panel")

  m.aboutImage = m.top.findNode("aboutImage")
  m.qr         = m.top.findNode("qr")

  m.title  = m.top.findNode("title")
  m.line1  = m.top.findNode("line1")
  m.line2  = m.top.findNode("line2")
  m.line3  = m.top.findNode("line3")
  m.line4  = m.top.findNode("line4")
  m.line5  = m.top.findNode("line5")
  m.line6  = m.top.findNode("line6")
  m.line7  = m.top.findNode("line7")
  m.sep    = m.top.findNode("sep")
  m.readmeLabel = m.top.findNode("readmeLabel")
  m.readmeUrl   = m.top.findNode("readmeUrl")

  ' Visual styles
  colorNavy  = &h103A57FF
  colorBlack = &h000000FF
  colorMuted = &h223041FF

  m.title.font = "Large"
  m.title.color = colorNavy
  m.title.text = "About FaithSaver"

  m.line1.color = colorBlack : m.line1.text = "FaithSaver is a Roku screensaver that displays faith-based images."
  m.line2.color = colorBlack : m.line2.text = "Production saver pulls approved images from GitHub and shuffles them each run."
  m.line3.color = colorBlack : m.line3.text = "Preview remains offline-only and never makes network calls."
  m.line4.color = colorBlack : m.line4.text = "Settings let you choose a category; Back exits settings."
  m.line5.color = colorBlack : m.line5.text = "Submissions: finished images (with verse) or raw photos for curation."
  m.line6.color = colorBlack : m.line6.text = "Scan the QR to visit the submission page."
  m.line7.color = colorBlack : m.line7.text = "Images should be baseline sRGB JPG/PNG, 1920×1080 or larger."

  m.sep.opacity = 1.0

  m.readmeLabel.color = colorNavy
  m.readmeLabel.text = "README (project details):"

  ' Roku can’t open a browser; we show the URL so users can visit on phone
  m.readmeUrl.color = colorMuted
  m.readmeUrl.text = "https://github.com/christhetech131/FaithSaver#readme"

  ' Start focused so Back/OK events are captured here
  m.top.setFocus(true)
end sub

' Close on Back or OK. Swallow other keys.
function onKeyEvent(key as string, press as boolean) as boolean
  if not press then return false
  if key = "back" or key = "ok" then
    m.top.close = true
    return true
  end if
  return true
end function
