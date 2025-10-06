<# 
Build-FaithSaver.ps1
Zero-flag build for FaithSaver

- PREPARES the package in .\dist\
- Copies ALL files under .\images\ except .ai/.xcf (keeps your PNG/JPGs)
- Re-encodes the 3 core JPEGs to baseline sRGB if progressive/CMYK (fixes Roku PHY)
- Zips the CONTENTS of .\dist\ so 'manifest' is at the TOP LEVEL of the ZIP
- Outputs FaithSaver.zip to the REPO ROOT
- Verifies required paths and JPEG magic bytes for core images
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

    # REQUIRED (no app-logo.png anymore)
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
        "images\FaithSaver-Splash-1280x720.jpg"
    )
    foreach ($rel in $required) {
        $p = Join-Path $root $rel
        if (-not (Test-Path $p)) { throw "Missing required file: $rel" }
    }

    # Stage code/manifest to dist
    foreach ($rel in $required | Where-Object { -not ($_ -like 'images\*') }) {
        $src = Join-Path $root $rel
        $dstDir = Join-Path $dist (Split-Path $rel -Parent)
        Copy-SafeFile $src $dstDir
    }

    # --- JPEG re-encode to baseline sRGB for the three core images (fixes PHY) ---
    Add-Type -AssemblyName System.Drawing

    function Convert-ToBaselineJpeg {
        param([string]$inPath, [string]$outPath)
        try {
            $img = [System.Drawing.Image]::FromFile($inPath)
            try {
                $jpegCodec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq 'image/jpeg' }
                $encParams = New-Object System.Drawing.Imaging.EncoderParameters(1)
                $encParams.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, [int64]90)
                $tmp = "$outPath.tmp"
                $img.Save($tmp, $jpegCodec, $encParams)
                if (Test-Path $outPath) { Remove-Item $outPath -Force }
                Move-Item $tmp $outPath -Force
            } finally {
                $img.Dispose()
            }
        } catch {
            Write-Warning "Could not re-encode JPEG '$inPath' -> using original. Error: $($_.Exception.Message)"
            Copy-Item $inPath $outPath -Force
        }
    }

    function Test-IsProgressiveJpeg {
        param([string]$path)
        try {
            $bytes = [IO.File]::ReadAllBytes($path)
            for ($i=0; $i -lt $bytes.Length-1; $i++) {
                if ($bytes[$i] -eq 0xFF) {
                    $marker = $bytes[$i+1]
                    if ($marker -eq 0xC2) { return $true } # SOF2 progressive
                }
            }
            return $false
        } catch { return $false }
    }

    # Copy ALL images recursively, excluding .ai/.xcf; normalize the 3 core JPEGs via re-encode
    $imagesRoot = Join-Path $root "images"
    if (-not (Test-Path $imagesRoot)) { throw "Missing required folder: images" }
    $imagesOut = Join-Path $dist "images"
    New-Item -ItemType Directory -Path $imagesOut -Force | Out-Null

    Get-ChildItem $imagesRoot -Recurse -File |
        Where-Object { $_.Extension -notin @('.ai','.xcf') } |
        ForEach-Object {
            $relPath = $_.FullName.Substring($imagesRoot.Length).TrimStart('\','/')
            $destDir = Join-Path $imagesOut (Split-Path $relPath -Parent)
            $destPath = Join-Path $imagesOut $relPath
            if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }

            $relNorm = $relPath -replace '\\','/'
            if ($relNorm -ieq "FaithSaver-BrandTile-147x113.jpg" -or
                $relNorm -ieq "FaithSaver-Splash-1280x720.jpg" -or
                $relNorm -ieq "FaithSaver-Splash-1920x1080.jpg") {
                # Normalize critical JPEGs
                if (Test-IsProgressiveJpeg -path $_.FullName) {
                    Write-Host "[Assets] Re-encoding progressive JPEG to baseline: images/$relNorm"
                }
                Convert-ToBaselineJpeg -inPath $_.FullName -outPath $destPath
            } else {
                Copy-Item $_.FullName $destPath -Force
            }
        }

    # Ensure at least one offline image exists for first-frame render
    $animals001 = Join-Path $imagesOut "offline\animals\001.jpg"
    if (-not (Test-Path $animals001)) {
        $legacyAnimals = Join-Path $imagesOut "offline\animals.jpg"
        if (Test-Path $legacyAnimals) {
            New-Item -ItemType Directory -Path (Split-Path $animals001 -Parent) -Force | Out-Null
            Copy-Item $legacyAnimals $animals001 -Force
        } else {
            Write-Warning "images/offline/animals/001.jpg not found; app will fall back to any available offline default."
        }
    }

    # Create ZIP with top-level manifest
    $zipPath = Join-Path $root "FaithSaver.zip"
    if (Test-Path $zipPath) { Remove-Item $zipPath -Force }

    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::CreateFromDirectory($dist, $zipPath)

    # Verify ZIP contents
    $zip = [System.IO.Compression.ZipFile]::OpenRead($zipPath)
    $zipEntries = $zip.Entries | ForEach-Object { $_.FullName }
    $zip.Dispose()

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
        "images/FaithSaver-Splash-1280x720.jpg"
    )
    $missing = @()
    foreach ($e in $expected) {
        if (-not ($zipEntries -contains $e)) { $missing += $e }
    }
    if ($missing.Count -gt 0) {
        throw "Zip verification failed. Missing entries:`n" + ($missing -join "`n")
    }

    # JPEG magic bytes check for core images inside the ZIP
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
