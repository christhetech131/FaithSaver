<#
Build-FaithSaver.ps1 — FaithSaver
- Stages to .\dist
- Copies ALL code under .\source and .\components (recursively)
- Copies ALL images except .ai/.xcf
- Normalizes three core JPEGs to exact size/24bpp RGB/baseline
- Zips CONTENTS of dist so manifest is at ZIP root
- Verifies required entries; allows extras
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

    function Copy-Tree($srcDir, $dstDir) {
        if (-not (Test-Path $srcDir)) { throw "Missing required folder: $srcDir" }
        New-Item -ItemType Directory -Path $dstDir -Force | Out-Null
        Copy-Item (Join-Path $srcDir '*') $dstDir -Recurse -Force
    }

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

    # ---------- Required top-level files ----------
    $manifestPath = Join-Path $root "manifest"
    if (-not (Test-Path $manifestPath)) { throw "Missing required file: manifest" }
    Copy-SafeFile $manifestPath $dist

    # ---------- Code: copy entire /source and /components ----------
    $srcDir = Join-Path $root "source"
    $cmpDir = Join-Path $root "components"
    Copy-Tree $srcDir (Join-Path $dist "source")
    Copy-Tree $cmpDir (Join-Path $dist "components")

    # ---------- Images: copy everything except .ai/.xcf; normalize core JPEGs ----------
    $imagesRoot = Join-Path $root "images"
    if (-not (Test-Path $imagesRoot)) { throw "Missing required folder: images" }
    $imagesOut = Join-Path $dist "images"
    New-Item -ItemType Directory -Path $imagesOut -Force | Out-Null

    $coreMap = @{
        "FaithSaver-BrandTile-147x113.jpg" = @{ W=147;  H=113 }
        "FaithSaver-Splash-1280x720.jpg"   = @{ W=1280; H=720 }
        "FaithSaver-Splash-1920x1080.jpg"  = @{ W=1920; H=1080 }
    }

    Add-Type -AssemblyName System.Drawing

    function Convert-ToBaselineJpeg {
        param(
            [Parameter(Mandatory)] [string] $inPath,
            [Parameter(Mandatory)] [string] $outPath,
            [Parameter(Mandatory)] [int] $width,
            [Parameter(Mandatory)] [int] $height
        )
        $srcImg = [System.Drawing.Image]::FromFile($inPath)
        try {
            if (($srcImg.Width -ne $width) -or ($srcImg.Height -ne $height) -or ($srcImg.PixelFormat -eq [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)) {
                $bmp = New-Object System.Drawing.Bitmap($width, $height, [System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
                try {
                    $gfx = [System.Drawing.Graphics]::FromImage($bmp)
                    try {
                        $gfx.SmoothingMode  = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
                        $gfx.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
                        $gfx.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
                        $gfx.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
                        $rect = New-Object System.Drawing.Rectangle(0,0,$width,$height)
                        $gfx.DrawImage($srcImg, $rect)
                    } finally {
                        $gfx.Dispose()
                    }

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
            } else {
                Copy-Item $inPath $outPath -Force
            }
        } finally {
            $srcImg.Dispose()
        }
    }

    Get-ChildItem $imagesRoot -Recurse -File |
        Where-Object { $_.Extension -notin @('.ai','.xcf') } |
        ForEach-Object {
            $rel = $_.FullName.Substring($imagesRoot.Length).TrimStart('\','/')
            $dst = Join-Path $imagesOut $rel
            $dstDir = Split-Path $dst -Parent
            if (-not (Test-Path $dstDir)) { New-Item -ItemType Directory -Path $dstDir -Force | Out-Null }

            $name = $_.Name
            if ($coreMap.ContainsKey($name)) {
                $spec = $coreMap[$name]
                Convert-ToBaselineJpeg -inPath $_.FullName -outPath $dst -width $spec.W -height $spec.H
            } else {
                Copy-Item $_.FullName $dst -Force
            }
        }

    # ---------- Create ZIP with top-level manifest ----------
    $zipPath = Join-Path $root "FaithSaver.zip"
    if (Test-Path $zipPath) { Remove-Item $zipPath -Force }

    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::CreateFromDirectory($dist, $zipPath)

    # ---------- Verify ZIP contains the critical files ----------
    $expectedMustHave = @(
        "manifest",
        "source/main.brs",
        "components/SettingsScene.xml",
        "components/SettingsScene.brs",
        "components/SaverScene.xml",
        "components/SaverScene.brs",
        "images/FaithSaver-BrandTile-147x113.jpg",
        "images/FaithSaver-Splash-1280x720.jpg",
        "images/FaithSaver-Splash-1920x1080.jpg"
    )

    $zip = [System.IO.Compression.ZipFile]::OpenRead($zipPath)
    try {
        $zipEntries = $zip.Entries | ForEach-Object { $_.FullName }
        $missing = @()
        foreach ($e in $expectedMustHave) { if (-not ($zipEntries -contains $e)) { $missing += $e } }
        if ($missing.Count -gt 0) { throw "Zip verification failed. Missing entries:`n$($missing -join "`n")" }
    } finally { $zip.Dispose() }

    Write-Host "Build OK."
    Write-Host " - Staged in: $dist"
    Write-Host " - ZIP created at: $zipPath (manifest at ZIP root)"
}
finally {
    Pop-Location
}
