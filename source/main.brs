function main(args as dynamic) as void
  mode = "preview"
  entry = ""
  if type(args) = "roAssociativeArray" and args <> invalid then
    if args.doesExist("entry") then
      entryValue = args.entry
      if type(entryValue) = "String" then
        entry = LCase(entryValue)
      end if
    end if
  end if

  if entry = "runscreensaver" then
    mode = "saver"
  else if entry = "runscreensaverpreview" then
    mode = "preview"
  else if entry = "runscreensaversettings" then
    mode = "settings"
  end if

  validateCoreAssets()

  if mode = "settings" then
    runSettingsScene()
  else
    runSaverScene(mode)
  end if
end function

sub runSaverScene(mode as String)
  screen = CreateObject("roSGScreen")
  if screen = invalid then
    print "[FaithSaver] Unable to create roSGScreen"
    return
  end if

  port = CreateObject("roMessagePort")
  if port <> invalid then
    screen.SetMessagePort(port)
  end if

  scene = screen.CreateScene("SaverScene")
  if scene = invalid then
    print "[FaithSaver] SaverScene could not be created"
    return
  end if

  category = getSavedCategory()
  if scene.doesExist("category") then scene.category = category
  if scene.doesExist("close") and port <> invalid then scene.ObserveField("close", port)

  screen.Show()

  normalized = "preview"
  if LCase(mode) = "saver" then normalized = "saver"
  if scene.doesExist("mode") then scene.mode = normalized

  while true
    msg = wait(0, port)
    if type(msg) = "roSGNodeEvent" then
      node = msg.getNode()
      if node = scene then
        fieldName = LCase(msg.getField())
        if fieldName = "close" then
          data = msg.getData()
          if type(data) = "Boolean" and data then exit while
        end if
      end if
    else if type(msg) = "roSGScreenEvent" then
      if msg.isScreenClosed() then exit while
    end if
  end while
end sub

sub runSettingsScene()
  screen = CreateObject("roSGScreen")
  if screen = invalid then
    print "[FaithSaver] Unable to create settings screen"
    return
  end if

  port = CreateObject("roMessagePort")
  if port <> invalid then
    screen.SetMessagePort(port)
  end if

  scene = screen.CreateScene("SettingsScene")
  if scene = invalid then
    print "[FaithSaver] SettingsScene could not be created"
    return
  end if

  cat = getSavedCategory()
  if scene.doesExist("category") then scene.category = cat
  if scene.doesExist("close") and port <> invalid then scene.ObserveField("close", port)
  if scene.doesExist("saved") and port <> invalid then scene.ObserveField("saved", port)

  screen.Show()

  while true
    msg = wait(0, port)
    if type(msg) = "roSGNodeEvent" then
      node = msg.getNode()
      if node = scene then
        fieldName = LCase(msg.getField())
        if fieldName = "close" then
          data = msg.getData()
          if type(data) = "Boolean" and data then exit while
        else if fieldName = "saved" then
          data = msg.getData()
          if type(data) = "Boolean" and data then
            if scene.doesExist("category") then
              selected = scene.category
              if type(selected) = "String" and selected <> "" then
                setSavedCategory(selected)
              end if
            end if
          end if
        end if
      end if
    else if type(msg) = "roSGScreenEvent" then
      if msg.isScreenClosed() then exit while
    end if
  end while
end sub

function getSavedCategory() as String
  sec = CreateObject("roRegistrySection", "FaithSaver")
  if sec <> invalid then
    reg = sec.GetInterface("ifRegistrySection")
    if reg <> invalid then
      value = reg.Read("category", "animals")
      if type(value) = "String" and value <> "" then
        return LCase(value)
      end if
    end if
  end if
  return defaultValue
end function

sub setSavedCategory(cat as String)
  if type(cat) <> "String" then return
  trimmed = LCase(TrimString(cat))
  if trimmed = "" then return
  sec = CreateObject("roRegistrySection", "FaithSaver")
  if sec = invalid then return
  reg = sec.GetInterface("ifRegistrySection")
  if reg = invalid then return
  if reg.Write("category", trimmed) then
    reg.Flush()
  end if
end sub

function acquireRegistrySection() as Dynamic
  primary = CreateObject("roRegistrySection", "FaithSaver")
  if isRegistrySection(primary) then return primary

  registry = CreateObject("roRegistry")
  if registry <> invalid and type(registry) = "roRegistry" then
    secondary = registry.GetSection("FaithSaver")
    if isRegistrySection(secondary) then return secondary
  end if

  return invalid
end function

function isRegistrySection(obj as Dynamic) as Boolean
  objType = type(obj)
  return obj <> invalid and (objType = "roRegistrySection" or objType = "ifRegistrySection")
end function

sub validateCoreAssets()
  assets = [
    "pkg:/images/FaithSaver-BrandTile-147x113.jpg",
    "pkg:/images/FaithSaver-Splash-1920x1080.jpg",
    "pkg:/images/FaithSaver-Splash-1280x720.jpg"
  ]

  for each asset in assets
    ba = CreateObject("roByteArray")
    if ba <> invalid and ba.ReadFile(asset) and ba.Count() > 0 then
      print "[Assets] Found & readable: " + asset + " (bytes=" + ba.Count().toStr() + ")"
    else
      print "[Assets] Not readable (missing or decode-hostile): " + asset
    end if
  next
end sub

function TrimString(s as Dynamic) as String
  if type(s) <> "String" then return ""
  return LTrim(RTrim(s))
end function
