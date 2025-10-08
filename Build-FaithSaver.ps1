<#
Build-FaithSaver.ps1
Zero-flag build for FaithSaver

- PREPARES the package in .\dist\
- Copies ALL files under .\images\ except .ai/.xcf
- Force-normalizes three core JPEGs (brand tile + 2 splashes) to:
  * Exact pixel size (147x113, 1280x720, 1920x1080)
  * 24bpp RGB (no CMYK/alpha)
  * Baseline (non-progressive) JPEG, quality ~90
  * Strips metadata/ICC by redrawing into a fresh bitmap
- Zips the CONTENTS of .\dist\ so 'manifest' is at the TOP LEVEL of the ZIP
- Outputs FaithSaver.zip to the REPO ROOT
- Verifies required entries and asserts correct pixel dimensions inside the ZIP
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not $PSScriptRoot) {
    $ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
} else {
    $ScriptRoot = $PSScriptRoot
}

Push-Location $ScriptRoot
try {
    $root = Get-Location

    # ---------- Clean staging (dist/) ----------
    $dist = Join-Path $root "dist"
    if (Test-Path $dist) { Remove-Item -Recurse -Force $dist }
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

    # ---------- Required non-image files ----------
    $requiredCode = @(
        "manifest",
        "source\main.brs",
        "components\SaverScene.xml",
        "components\SaverScene.brs",
        "components\SettingsScene.xml",
        "components\SettingsScene.brs",
        "components\ImageFeedTask.xml",
        "components\ImageFeedTask.brs"
    )
    foreach ($rel in $requiredCode) {
        $p = Join-Path $root $rel
        if (-not (Test-Path $p)) { throw "Missing required file: $rel" }
    }
    foreach ($rel in $requiredCode) {
        $src = Join-Path $root $rel
        $dstDir = Join-Path $dist (Split-Path $rel -Parent)
        Copy-SafeFile $src $dstDir
    }

    # ---------- Images: copy everything except .ai/.xcf ----------
    $imagesRoot = Join-Path $root "images"
    if (-not (Test-Path $imagesRoot)) { throw "Missing required folder: images" }
    $imagesOut = Join-Path $dist "images"
    New-Item -ItemType Directory -Path $imagesOut -Force | Out-Null

    # Core JPEG files (exact names at images/ root)
    $coreMap = @{
        "FaithSaver-BrandTile-147x113.jpg" = @{ W=147;  H=113 }
        "FaithSaver-Splash-1280x720.jpg"   = @{ W=1280; H=720 }
        "FaithSaver-Splash-1920x1080.jpg"  = @{ W=1920; H=1080 }
    }

    Add-Type -AssemblyName System.Drawing

    function Convert-ToBaselineJpegExact {
        param(
            [string]$inPath,
            [string]$outPath,
            [int]$width,
            [int]$height
        )
        # Load original
        $srcImg = [System.Drawing.Image]::FromFile($inPath)
        try {
            # Create new 24bpp RGB canvas at exact size, which strips metadata/ICC
            $bmp   = New-Object System.Drawing.Bitmap($width, $height, [System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
            try {
                $gfx = [System.Drawing.Graphics]::FromImage($bmp)
                try {
                    $gfx.SmoothingMode  = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
                    $gfx.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
                    $gfx.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
                    $gfx.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
                    # Draw scaled to target size
                    $rect = New-Object System.Drawing.Rectangle(0,0,$width,$height)
                    $gfx.DrawImage($srcImg, $rect)
                } finally {
                    $gfx.Dispose()
                }

                # Encode as baseline JPEG (quality 90)
                $jpegCodec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq 'image/jpeg' }
                $encParams = New-Object System.Drawing.Imaging.EncoderParameters(1)
                $encParams.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, [int64]90)

                $tmp = "$outPath.tmp"
                $bmp.Save($tmp, $jpegCodec, $encParams)
                if (Test-Path $outPath) { Remove-Item $outPath -Force }
                Move-Item $tmp $outPath -Force
            } finally {
                $bmp.Dispose()
            }
        } finally {
            $srcImg.Dispose()
        }
    }

    # Copy images recursively (skip .ai/.xcf); normalize core JPEGs by exact name
    Get-ChildItem $imagesRoot -Recurse -File |
        Where-Object { $_.Extension -notin @('.ai','.xcf') } |
        ForEach-Object {
            $relPath = $_.FullName.Substring($imagesRoot.Length).TrimStart('\','/')
            $destDir = Join-Path $imagesOut (Split-Path $relPath -Parent)
            $destPath = Join-Path $imagesOut $relPath
            if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }

            $leaf = (Split-Path $relPath -Leaf)
            if ($coreMap.ContainsKey($leaf)) {
                $w = [int]$coreMap[$leaf].W
                $h = [int]$coreMap[$leaf].H
                Write-Host "[Assets] Normalizing core JPEG to $w x $h, 24bpp RGB, baseline: images/$leaf"
                Convert-ToBaselineJpegExact -inPath $_.FullName -outPath $destPath -width $w -height $h
            } else {
                Copy-Item $_.FullName $destPath -Force
            }
        }

    # Ensure at least one offline image for first-frame render
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

    # ---------- Create ZIP with top-level manifest ----------
    $zipPath = Join-Path $root "FaithSaver.zip"
    if (Test-Path $zipPath) { Remove-Item $zipPath -Force }

    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::CreateFromDirectory($dist, $zipPath)

    # ---------- Verify ZIP contents ----------
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
        "images/FaithSaver-Splash-1280x720.jpg",
        "images/FaithSaver-Splash-1920x1080.jpg"
    )
    $missing = @()
    foreach ($e in $expected) {
        if (-not ($zipEntries -contains $e)) { $missing += $e }
    }
    if ($missing.Count -gt 0) {
        throw "Zip verification failed. Missing entries:`n" + ($missing -join "`n")
    }

    # ---------- Dimension + magic-byte checks inside the ZIP ----------
    function Test-JpegMagic([byte[]] $bytes) {
        if ($bytes.Length -lt 4) { return $false }
        return ($bytes[0] -eq 0xFF -and $bytes[1] -eq 0xD8 -and $bytes[$bytes.Length-2] -eq 0xFF -and $bytes[$bytes.Length-1] -eq 0xD9)
    }

    $fs = [System.IO.File]::OpenRead($zipPath)
    $archive = New-Object System.IO.Compression.ZipArchive($fs, [System.IO.Compression.ZipArchiveMode]::Read)

    function Assert-ZipJpeg {
        param(
            [System.IO.Compression.ZipArchive] $arch,
            [string] $entryPath,
            [int] $w,
            [int] $h
        )
        $entry = $arch.Entries | Where-Object { $_.FullName -eq $entryPath }
        if ($null -eq $entry) { throw "JPEG missing in zip: $entryPath" }

        $ms = New-Object System.IO.MemoryStream
        $entry.Open().CopyTo($ms)
        $bytes = $ms.ToArray()

        if (-not (Test-JpegMagic $bytes)) { throw "JPEG magic bytes invalid: $entryPath" }

        # Dimension check: load via System.Drawing from memory
        $ms.Position = 0
        $img = [System.Drawing.Image]::FromStream($ms, $false, $false)
        try {
            if ($img.Width -ne $w -or $img.Height -ne $h) {
                throw "JPEG dimensions invalid for $entryPath (found ${($img.Width)}x${($img.Height)}, expected ${w}x${h})"
            }
            if ($img.PixelFormat -band [System.Drawing.Imaging.PixelFormat]::Indexed) {
                throw "JPEG pixel format indexed for $entryPath (expected 24bpp RGB)"
            }
        } finally {
            $img.Dispose()
        }
    }

    Assert-ZipJpeg -arch $archive -entryPath "images/FaithSaver-BrandTile-147x113.jpg" -w 147  -h 113
    Assert-ZipJpeg -arch $archive -entryPath "images/FaithSaver-Splash-1280x720.jpg"   -w 1280 -h 720
    Assert-ZipJpeg -arch $archive -entryPath "images/FaithSaver-Splash-1920x1080.jpg"  -w 1920 -h 1080

    $archive.Dispose()
    $fs.Dispose()

    Write-Host "Build OK."
    Write-Host " - Staged in: $dist"
    Write-Host " - ZIP created at: $zipPath (manifest at ZIP root)"
}
finally {
    Pop-Location
}
