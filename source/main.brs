' [FaithSaver] main.brs
' Roku SDK 10+; SceneGraph entry controller with defensive checks

sub main(args as dynamic)
    ' Defensive: args may be invalid or missing
    entry = safeGetEntry(args)

    screen = CreateObject("roSGScreen")
    if type(screen) <> "roSGScreen" then
        print "[FaithSaver] roSGScreen invalid, aborting."
        return
    end if

    m.port = CreateObject("roMessagePort")
    if type(m.port) <> "roMessagePort" then
        print "[FaithSaver] roMessagePort invalid, aborting."
        return
    end if
    screen.SetMessagePort(m.port)

    ' Asset validator — ensure 3 core images exist & are readable
    validateCoreAssets()

    ' Choose scene
    sceneName = "SaverScene"
    if entry = "runscreensaversettings" then sceneName = "SettingsScene"

    ' Preferred attachment pattern B
    scene = screen.CreateScene(sceneName)
    if scene = invalid then
        print "[FaithSaver] CreateScene failed for "; sceneName
        return
    end if

    screen.Show()

    ' Set initial mode/category only after scene is visible to avoid races
    if sceneName = "SaverScene" then
        mode = "preview"
        if entry = "runscreensaver" then mode = "saver"
        if entry = "runscreensaverpreview" then mode = "preview"
        ' accept any unknown by defaulting to preview
        safeSetField(scene, "mode", mode)
        safeSetField(scene, "category", getSavedCategory())
    end if

    ' Wire up close/saved notifications
    if sceneName = "SaverScene" then
        scene.ObserveField("close", m.port)
    else if sceneName = "SettingsScene" then
        scene.ObserveField("close", m.port)
        scene.ObserveField("saved", m.port)
    end if

    ' Event loop
    while true
        msg = wait(0, m.port)
        if type(msg) = "roSGScreenEvent"
            if msg.isScreenClosed() then
                exit while
            end if
        else if type(msg) = "roSGNodeEvent"
            if msg.GetField() = "close" then
                exit while
            end if
        end if
    end while
end sub

' ---------- Helpers ----------

function safeGetEntry(args as dynamic) as string
    entry = "runscreensaverpreview" ' default to preview per requirement
    if args <> invalid and GetInterface(args, "ifAssociativeArray") <> invalid then
        if args.entry <> invalid then
            if type(args.entry) = "roString" or type(args.entry) = "String" then
                entry = LCase(args.entry)
            else if type(args.entry) = "roXMLElement" then
                entry = LCase(args.entry.getText())
            end if
        end if
    end if

    ' Normalize
    if entry = "screensaver" then entry = "runscreensaver"
    if entry = "" then entry = "runscreensaverpreview"
    return entry
end function

function getSavedCategory() as string
    defaultCat = "animals"
    sec = CreateObject("roRegistrySection", "FaithSaver")
    if sec = invalid then
        print "[FaithSaver] Registry section invalid; using default category."
        return defaultCat
    end if

    cat = invalid
    if sec.Exists("category") then
        cat = sec.Read("category")
    end if

    if cat = invalid or type(cat) <> "roString" and type(cat) <> "String" or cat = "" then
        return defaultCat
    end if

    return cat
end function

sub validateCoreAssets()
    core = [
        "pkg:/images/FaithSaver-BrandTile-147x113.jpg",
        "pkg:/images/FaithSaver-Splash-1280x720.jpg",
        "pkg:/images/FaithSaver-Splash-1920x1080.jpg"
    ]
    for each p in core
        ba = CreateObject("roByteArray")
        if ba = invalid then
            print "[Assets] Not readable (missing or decode-hostile): "; p
            return
        end if
        ok = ba.ReadFile(p)
        if ok then
            print "[Assets] Found & readable: "; p; " (bytes="; ba.Count().ToStr(); ")"
        else
            print "[Assets] Not readable (missing or decode-hostile): "; p
        end if
    end for
end sub

sub safeSetField(node as Object, field as string, value as dynamic)
    if node <> invalid and GetInterface(node, "ifSGNodeWritable") <> invalid then
        node[field] = value
    end if
end sub
