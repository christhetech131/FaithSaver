<# 
Build-FaithSaver.ps1
Zero-flag build for FaithSaver
- Stages a clean package (no extraneous files)
- Ensures required assets exist; creates an opaque app-logo.png if missing
- Copies legacy offline JPGs into required folder structure without deleting originals
- Verifies ZIP contents and JPEG magic bytes
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not $PSScriptRoot) { $ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path } else { $ScriptRoot = $PSScriptRoot }

Push-Location $ScriptRoot
try {
    $root = Get-Location

    $dist = Join-Path $root "dist"
    if (-not (Test-Path $dist)) { New-Item -ItemType Directory -Path $dist | Out-Null }

    $stageRoot = Join-Path $root "build\FaithSaver"
    if (Test-Path $stageRoot) { Remove-Item -Recurse -Force $stageRoot }
    New-Item -ItemType Directory -Path $stageRoot | Out-Null

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
    $appLogoPath = Join-Path $root $appLogoRel
    if (-not (Test-Path $appLogoPath)) {
        Write-Host "[Assets] images/app-logo.png missing. Creating minimal opaque PNG..."
        $pngB64 = @"
iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAQAAADZc7J/AAAAP0lEQVR4Ae3OsQkAMAwDQd//k1qk
YwYw3xg0wqJgD9xgRrD7P7mR4kVh6cA0p2m2n7y7xO9mQmF4A8jNw1mA0nQkZ4+2rZr2mQAAcY2l
a0R1tQAAAABJRU5ErkJggg==
"@ -replace '\s',''
        $bytes = [Convert]::FromBase64String($pngB64)
        $logoDir = Join-Path $root "images"
        if (-not (Test-Path $logoDir)) { New-Item -ItemType Directory -Path $logoDir | Out-Null }
        [IO.File]::WriteAllBytes($appLogoPath, $bytes)
    }

    # REQUIRED FILES (exact)
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

    foreach ($rel in $required) {
        $p = Join-Path $root $rel
        if (-not (Test-Path $p)) { throw "Missing required file: $rel" }
    }

    foreach ($rel in $required) {
        Copy-SafeFile (Join-Path $root $rel) (Join-Path $stageRoot (Split-Path $rel -Parent))
    }

    # Stage offline images using required folder structure, but do not remove originals
    $categories = @("animals","fall","geology","scenery","space","spring","summer","textures","winter")
    $offlineOutRoot = Join-Path $stageRoot "images\offline"
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

    # Zip creation
    $zipPath = Join-Path $root "FaithSaver.zip"
    if (Test-Path $zipPath) { Remove-Item $zipPath -Force }
    if (Test-Path (Join-Path $dist "FaithSaver.zip")) { Remove-Item (Join-Path $dist "FaithSaver.zip") -Force }

    Add-Type -AssemblyName System.IO.Compression.FileSystem
    # Zip the parent directory of the staged folder so entries are "FaithSaver/..."
    [System.IO.Compression.ZipFile]::CreateFromDirectory((Join-Path $stageRoot ".."), $zipPath)

    Copy-Item $zipPath (Join-Path $dist "FaithSaver.zip") -Force

    # Verification: ZIP must contain our staged files (no extraneous),
    # but only REQUIRE animals/001.jpg to exist (others are optional).
    $zip = [System.IO.Compression.ZipFile]::OpenRead($zipPath)
    $zipEntries = $zip.Entries | ForEach-Object { $_.FullName }
    $zip.Dispose()  # <-- fixed: Dispose instead of Close

    $expected = @(
        "FaithSaver/components/SaverScene.xml",
        "FaithSaver/components/SaverScene.brs",
        "FaithSaver/components/SettingsScene.xml",
        "FaithSaver/components/SettingsScene.brs",
        "FaithSaver/components/ImageFeedTask.xml",
        "FaithSaver/components/ImageFeedTask.brs",
        "FaithSaver/images/FaithSaver-BrandTile-147x113.jpg",
        "FaithSaver/images/FaithSaver-Splash-1920x1080.jpg",
        "FaithSaver/images/FaithSaver-Splash-1280x720.jpg",
        "FaithSaver/images/app-logo.png",
        "FaithSaver/manifest",
        "FaithSaver/source/main.brs",
        # Require at least one offline image to guarantee first-frame render
        "FaithSaver/images/offline/animals/001.jpg"
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

    $jpgsToTest = @(
        "FaithSaver/images/FaithSaver-BrandTile-147x113.jpg",
        "FaithSaver/images/FaithSaver-Splash-1280x720.jpg",
        "FaithSaver/images/FaithSaver-Splash-1920x1080.jpg"
    )

    $fs = [System.IO.File]::OpenRead($zipPath)
    $archive = New-Object System.IO.Compression.ZipArchive($fs, [System.IO.Compression.ZipArchiveMode]::Read)
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

    Write-Host "Build OK. Zip created at: $zipPath and copied to dist\FaithSaver.zip"
}
finally {
    Pop-Location
}
