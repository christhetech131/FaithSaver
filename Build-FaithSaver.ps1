$ErrorActionPreference = 'Stop'
if (-not $PSScriptRoot) {
    $ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
} else {
    $ScriptRoot = $PSScriptRoot
}
$ScriptRoot = (Resolve-Path $ScriptRoot).Path

$buildDir = Join-Path $ScriptRoot 'build'
$staging = Join-Path $buildDir 'FaithSaver'
if (Test-Path $staging) {
    Remove-Item $staging -Recurse -Force
}
New-Item -ItemType Directory -Path $staging | Out-Null

$sourceDir = Join-Path $staging 'source'
$componentsDir = Join-Path $staging 'components'
$imagesDir = Join-Path $staging 'images'
$imagesRoot = Join-Path $ScriptRoot 'images'
New-Item -ItemType Directory -Path $sourceDir | Out-Null
New-Item -ItemType Directory -Path $componentsDir | Out-Null
New-Item -ItemType Directory -Path $imagesDir | Out-Null

Copy-Item (Join-Path $ScriptRoot 'manifest') -Destination $staging -Force
Copy-Item (Join-Path (Join-Path $ScriptRoot 'source') 'main.brs') -Destination $sourceDir -Force
Copy-Item (Join-Path (Join-Path $ScriptRoot 'components') '*.xml') -Destination $componentsDir -Force
Copy-Item (Join-Path (Join-Path $ScriptRoot 'components') '*.brs') -Destination $componentsDir -Force

$indexPath = Join-Path $ScriptRoot 'index.json'
if (-not (Test-Path $indexPath)) {
    throw 'Missing index.json file.'
}
Copy-Item $indexPath -Destination $staging -Force

$requiredImages = @(
    'FaithSaver-BrandTile-147x113.jpg',
    'FaithSaver-Splash-1920x1080.jpg',
    'FaithSaver-Splash-1280x720.jpg',
    'app-logo.png'
)
foreach ($img in $requiredImages) {
    $sourcePath = Join-Path $imagesRoot $img
    if (-not (Test-Path $sourcePath)) {
        throw "Missing required image: $img"
    }
    Copy-Item $sourcePath -Destination $imagesDir -Force
}

$offlineSource = Join-Path $imagesRoot 'offline'
if (-not (Test-Path $offlineSource)) {
    throw 'Offline image directory is missing.'
}
$offlineDest = Join-Path $imagesDir 'offline'
Copy-Item $offlineSource -Destination $offlineDest -Recurse -Force

$zipPath = Join-Path $ScriptRoot 'FaithSaver.zip'
if (Test-Path $zipPath) { Remove-Item $zipPath -Force }
Compress-Archive -Path (Join-Path $staging '*') -DestinationPath $zipPath

$distDir = Join-Path $ScriptRoot 'dist'
if (-not (Test-Path $distDir)) {
    New-Item -ItemType Directory -Path $distDir | Out-Null
}
Copy-Item $zipPath -Destination (Join-Path $distDir 'FaithSaver.zip') -Force

$requiredEntries = @(
    'manifest',
    'index.json',
    'source/main.brs',
    'components/SaverScene.xml',
    'components/SaverScene.brs',
    'components/SettingsScene.xml',
    'components/SettingsScene.brs',
    'components/ImageFeedTask.xml',
    'components/ImageFeedTask.brs',
    'images/FaithSaver-BrandTile-147x113.jpg',
    'images/FaithSaver-Splash-1920x1080.jpg',
    'images/FaithSaver-Splash-1280x720.jpg',
    'images/app-logo.png'
)

Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip = [System.IO.Compression.ZipFile]::OpenRead($zipPath)
try {
    foreach ($entryPath in $requiredEntries) {
        $match = $zip.Entries | Where-Object { $_.FullName -eq $entryPath }
        if (-not $match) {
            throw "Missing entry in zip: $entryPath"
        }
    }

    $offlineCategories = Get-ChildItem $offlineSource -Directory | Select-Object -ExpandProperty Name
    foreach ($cat in $offlineCategories) {
        $prefix = "images/offline/$cat/"
        $matching = $zip.Entries | Where-Object { $_.FullName.StartsWith($prefix) -and -not $_.FullName.EndsWith('/') }
        if (-not $matching) {
            throw "Missing offline images for category: $cat"
        }
    }

    foreach ($entry in $zip.Entries) {
        if ($entry.FullName.EndsWith('/')) { continue }
        if ($entry.FullName.StartsWith('images/')) {
            if ($entry.FullName -eq 'images/FaithSaver-BrandTile-147x113.jpg' -or
                $entry.FullName -eq 'images/FaithSaver-Splash-1920x1080.jpg' -or
                $entry.FullName -eq 'images/FaithSaver-Splash-1280x720.jpg' -or
                $entry.FullName -eq 'images/app-logo.png' -or
                $entry.FullName.StartsWith('images/offline/')) {
                continue
            }
            throw "Unexpected image asset in zip: $($entry.FullName)"
        }

        if ($entry.FullName.StartsWith('components/') -or $entry.FullName.StartsWith('source/') -or $entry.FullName -eq 'manifest' -or $entry.FullName -eq 'index.json' -or $entry.FullName.StartsWith('images/')) {
            continue
        }

        throw "Unexpected entry in zip: $($entry.FullName)"
    }
}
finally {
    $zip.Dispose()
}

$jpegFiles = @(
    Join-Path $imagesRoot 'FaithSaver-BrandTile-147x113.jpg'
    Join-Path $imagesRoot 'FaithSaver-Splash-1920x1080.jpg'
    Join-Path $imagesRoot 'FaithSaver-Splash-1280x720.jpg'
)
foreach ($file in $jpegFiles) {
    $bytes = [System.IO.File]::ReadAllBytes($file)
    if ($bytes.Length -lt 4 -or $bytes[0] -ne 0xFF -or $bytes[1] -ne 0xD8 -or $bytes[$bytes.Length - 2] -ne 0xFF -or $bytes[$bytes.Length - 1] -ne 0xD9) {
        throw "Invalid JPEG magic bytes: $file"
    }
}

Write-Host 'FaithSaver.zip created successfully.'
