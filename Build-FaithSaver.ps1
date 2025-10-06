<# 
Build-FaithSaver.ps1
Zero-flag build for FaithSaver

What this does:
- PREPARES the package in .\dist\  (staging area)
- Ensures required assets exist (auto-creates an opaque images/app-logo.png if missing)
- Copies legacy offline JPGs into required folder structure without deleting originals
- Zips the CONTENTS of .\dist\ so 'manifest' is at the TOP LEVEL of the ZIP
- Outputs FaithSaver.zip to the REPO ROOT (the directory you run this from)
- Verifies required files exist in the ZIP and checks JPEG magic bytes for core images
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not $PSScriptRoot) { $ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path } else { $ScriptRoot = $PSScriptRoot }

Push-Location $ScriptRoot
try {
    $root = Get-Location

    # STAGING DIRECTORY: dist/
    $dist = Join-Path $root "dist"
    if (Test-Path $dist) {
        Remove-Item -Recurse -Force $dist
    }
    New-Item -ItemType Directory -Path $dist | Out-Null

    function Copy-SafeFile {
        param(
            [Parameter(Mandatory)] [string] $src,
            [Parameter(Mandatory)] [string] $dstDir,
            [string] $dstName
        )
        if (-not (Test-Path $src)) { throw "Missing required file on disk: $src" }
        if (-not (Test-Path $dstDir)) { New-Item -ItemType Directory -Path $dstDir -Force | Out-Null }
        $out = if ($dstName) { Join-Path $dstDir $dstName } else { Join-Path $dstDir (Split-Path $src -Leaf) }
        Copy-Item $src $out -Force
    }

    # Ensure opaque app-logo.png exists (create minimal opaque PNG if missing)
    $appLogoRel = "images\app-logo.png"
    $appLogoRepoPath = Join-Path $root $appLogoRel
    if (-not (Test-Path $appLogoRepoPath)) {
        Write-Host "[Assets] images/app-logo.png missing. Creating minimal opaque PNG..."
        $pngB64 = @"
iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAQAAADZc7J/AAAAP0lEQVR4Ae3OsQkAMAwDQd//k1qk
YwYw3xg0wqJgD9xgRrD7P7mR4kVh6cA0p2m2n7y7xO9mQmF4A8jNw1mA0nQkZ4+2rZr2mQAAcY2l
a0R1tQAAAABJRU5ErkJggg==
"@ -replace '\s',''
        $bytes = [Convert]::FromBase64String($pngB64)
        $logoDir = Join-Path $root "images"
        if (-not (Test-Path $logoDir)) { New-Item -ItemType Directory -Path $logoDir | Out-Null }
        [IO.File]::WriteAllBytes($appLogoRepoPath, $bytes)
    }

    # REQUIRED FILES (exact paths expected in the package)
    $required = @(
        "manifest",
        "source\main.brs",
        "components\SaverScene.xml",
        "components\SaverScene.brs",
        "components\SettingsScene.xml",
        "components\SettingsScene.brs",
        "components\ImageFeedTask.xml",
        "components\ImageFeedTask.brs",
        "images\FaithSaver-BrandTile-147x113.jpg",
        "images\FaithSaver-Splash-1920x1080.jpg",
        "images\FaithSaver-Splash-1280x720.jpg",
        "images\app-logo.png"
    )

    # Verify required exist in repo
    foreach ($rel in $required) {
        $p = Join-Path $root $rel
        if (-not (Test-Path $p)) { throw "Missing required file: $rel" }
    }

    # Stage required files into dist/, preserving structure
    foreach ($rel in $required) {
        $src = Join-Path $root $rel
        $dstDir = Join-Path $dist (Split-Path $rel -Parent)
        Copy-SafeFile $src $dstDir
    }

    # Stage offline images: required folder structure under dist/images/offline/<category>/
    $categories = @("animals","fall","geology","scenery","space","spring","summer","textures","winter")
    $offlineOutRoot = Join-Path $dist "images\offline"
    foreach ($cat in $categories) {
        $dst = Join-Path $offlineOutRoot $cat
        if (-not (Test-Path $dst)) { New-Item -ItemType Directory -Path $dst -Force | Out-Null }

        $repoFolder = Join-Path $root "images\offline\$cat"
        $repoSingle = Join-Path $root "images\offline\$cat.jpg"
        $copied = $false

        if (Test-Path $repoFolder) {
            $jpgs = Get-ChildItem $repoFolder -Filter *.jpg -File | Sort-Object Name
            $i = 1
            foreach ($j in $jpgs) {
                $name = "{0:D3}{1}" -f $i, ".jpg"
                Copy-SafeFile $j.FullName $dst $name
                $i++
            }
            if ($i -gt 1) { $copied = $true }
        }

        if (-not $copied -and (Test-Path $repoSingle)) {
            Copy-SafeFile $repoSingle $dst "001.jpg"
            $copied = $true
        }

        if (-not $copied) {
            $defaultSingle = Join-Path $root "images\offline\default.jpg"
            if (Test-Path $defaultSingle) {
                Copy-SafeFile $defaultSingle $dst "001.jpg"
            } else {
                Write-Warning "No offline image found for category '$cat'. The app will still run (it shows default in code)."
            }
        }
    }

    # ZIP creation (TOP LEVEL manifest)
    $zipPath = Join-Path $root "FaithSaver.zip"
    if (Test-Path $zipPath) { Remove-Item $zipPath -Force }

    Add-Type -AssemblyName System.IO.Compression.FileSystem

    # Create zip by first making a temp directory that mirrors dist/, then zipping its contents
    # CreateFromDirectory takes a directory and zips its CONTENTS at the root (no extra folder layer)
    [System.IO.Compression.ZipFile]::CreateFromDirectory($dist, $zipPath)

    # Verification: ZIP must contain top-level manifest and expected paths (no 'FaithSaver/' prefix)
    $zip = [System.IO.Compression.ZipFile]::OpenRead($zipPath)
    $zipEntries = $zip.Entries | ForEach-Object { $_.FullName }
    $zip.Dispose()  # Proper cleanup

    $expected = @(
        "manifest",
        "source/main.brs",
        "components/SaverScene.xml",
        "components/SaverScene.brs",
        "components/SettingsScene.xml",
        "components/SettingsScene.brs",
        "components/ImageFeedTask.xml",
        "components/ImageFeedTask.brs",
        "images/FaithSaver-BrandTile-147x113.jpg",
        "images/FaithSaver-Splash-1920x1080.jpg",
        "images/FaithSaver-Splash-1280x720.jpg",
        "images/app-logo.png",
        # Require at least one offline image to guarantee first-frame render
        "images/offline/animals/001.jpg"
    )

    $missing = @()
    foreach ($e in $expected) {
        if (-not ($zipEntries -contains $e)) { $missing += $e }
    }
    if ($missing.Count -gt 0) {
        throw "Zip verification failed. Missing entries:`n" + ($missing -join "`n")
    }

    # Optional JPEG magic bytes check for the 3 core images
    function Test-JpegMagic([byte[]] $bytes) {
        if ($bytes.Length -lt 4) { return $false }
        return ($bytes[0] -eq 0xFF -and $bytes[1] -eq 0xD8 -and $bytes[$bytes.Length-2] -eq 0xFF -and $bytes[$bytes.Length-1] -eq 0xD9)
    }

    $fs = [System.IO.File]::OpenRead($zipPath)
    $archive = New-Object System.IO.Compression.ZipArchive($fs, [System.IO.Compression.ZipArchiveMode]::Read)
    $jpgsToTest = @(
        "images/FaithSaver-BrandTile-147x113.jpg",
        "images/FaithSaver-Splash-1280x720.jpg",
        "images/FaithSaver-Splash-1920x1080.jpg"
    )
    foreach ($j in $jpgsToTest) {
        $entry = $archive.Entries | Where-Object { $_.FullName -eq $j }
        if ($null -eq $entry) { throw "JPEG missing in zip: $j" }
        $ms = New-Object System.IO.MemoryStream
        $entry.Open().CopyTo($ms)
        $bytes = $ms.ToArray()
        if (-not (Test-JpegMagic $bytes)) { throw "JPEG magic bytes invalid: $j" }
    }
    $archive.Dispose()
    $fs.Dispose()

    Write-Host "Build OK."
    Write-Host " - Staged in: $dist"
    Write-Host " - ZIP created at: $zipPath (manifest at ZIP root)"
}
finally {
    Pop-Location
}
