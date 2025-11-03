<#
  FaithSaver build & package script
  Goals:
   1) Only capture needed files (manifest, source, components, and images *.jpg/*.jpeg/*.png).
      - Exclude design/source files (.ai, .xcf) and the three extra images.
   2) Convert JPGs to baseline (non-progressive) to avoid Poster decode stalls.
   3) Use dist\pkg for staging and output FaithSaver.zip in the repo root.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ----- Paths -----
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$Dist = Join-Path $Root "dist"
$Pkg  = Join-Path $Dist "pkg"
$Zip  = Join-Path $Root "FaithSaver.zip"

# ----- Clean dist\pkg -----
if (Test-Path $Pkg) { Remove-Item $Pkg -Recurse -Force }
if (-not (Test-Path $Dist)) { New-Item -ItemType Directory -Path $Dist | Out-Null }
New-Item -ItemType Directory -Path $Pkg | Out-Null

Write-Host "Staging to: $Pkg"

# ----- Copy core files -----
Copy-Item (Join-Path $Root "manifest")   -Destination $Pkg -Force
Copy-Item (Join-Path $Root "source")     -Destination $Pkg -Recurse -Force
Copy-Item (Join-Path $Root "components") -Destination $Pkg -Recurse -Force

# ----- Copy images (only what we need) -----
$imagesSrc = Join-Path $Root "images"
$imagesDst = Join-Path $Pkg "images"
New-Item -ItemType Directory -Path $imagesDst | Out-Null

# Specific image names to exclude (your request)
$excludeNames = @(
  'FaithSaver-BrandTile-147x113.jpg',
  'FaithSaver-SearchButton-165x60.png',
  'Logo-Full.png'
)

# Only copy image file types used by the app; drop .ai, .xcf, etc.
Get-ChildItem $imagesSrc -Recurse -File |
  Where-Object {
    ($_.Extension -in @('.jpg', '.jpeg', '.png')) -and
    ($excludeNames -notcontains $_.Name)
  } |
  ForEach-Object {
    $rel = $_.FullName.Substring($imagesSrc.Length).TrimStart('\','/')
    $dst = Join-Path $imagesDst $rel
    $dstDir = Split-Path $dst -Parent
    if (-not (Test-Path $dstDir)) { New-Item -ItemType Directory -Path $dstDir | Out-Null }
    Copy-Item $_.FullName $dst -Force
  }

# Normalize QR filename case (app expects images/faithsaverqr.png)
$qrLower = Join-Path $imagesDst "faithsaverqr.png"
if (-not (Test-Path $qrLower)) {
  $qrAny = Get-ChildItem $imagesDst -Recurse -File -Include FaithSaverQR.png,faithsaverqr.png -ErrorAction SilentlyContinue | Select-Object -First 1
  if ($qrAny) {
    Copy-Item $qrAny.FullName $qrLower -Force
    if ($qrAny.FullName -ne $qrLower) { Remove-Item $qrAny.FullName -Force }
    Write-Host "Normalized QR filename to images/faithsaverqr.png"
  }
}

# ----- Convert JPG/JPEG to baseline (non-progressive) -----
# Uses System.Drawing; default Save() without progressive flags writes baseline JPEG.
Add-Type -AssemblyName System.Drawing

function Convert-ToBaselineJpeg {
  param(
    [Parameter(Mandatory=$true)][string]$InPath,
    [Parameter(Mandatory=$true)][string]$OutPath,
    [int]$Quality = 90
  )
  $img = [System.Drawing.Image]::FromFile($InPath)
  try {
    $codec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq 'image/jpeg' }
    $encps = New-Object System.Drawing.Imaging.EncoderParameters(1)
    $encps.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, [long]$Quality)
    $img.Save($OutPath, $codec, $encps)  # baseline JPEG
  } finally {
    $img.Dispose()
  }
}

Write-Host "Converting JPGs to baseline in /images..."
Get-ChildItem $imagesDst -Recurse -Include *.jpg,*.jpeg | ForEach-Object {
  try {
    $tmp = "$($_.FullName).tmp"
    Convert-ToBaselineJpeg -InPath $_.FullName -OutPath $tmp -Quality 88
    Move-Item -Force $tmp $_.FullName
  } catch {
    Write-Warning "Baseline conversion failed: $($_.FullName) — $($_.Exception.Message)"
  }
}

# ----- Verify must-haves exist in stage -----
$mustHave = @(
  "manifest",
  "source\main.brs",
  "components\SettingsScene.xml",
  "components\SettingsScene.brs",
  "components\SaverScene.xml",
  "components\SaverScene.brs",
  "components\AboutOverlay.xml",
  "components\AboutOverlay.brs",
  "components\ImageFeedTask.xml",
  "components\ImageFeedTask.brs",
  "images\FaithSaver-Poster-290x218.jpg",
  "images\FaithSaver-Poster-540x405.jpg",
  "images\FaithSaver-Splash-1280x720.jpg",
  "images\FaithSaver-Splash-1920x1080.jpg",
  "images\offline\default.jpg"
)

$missingStage = @()
foreach ($rel in $mustHave) {
  $p = Join-Path $Pkg $rel
  if (-not (Test-Path $p)) { $missingStage += $rel }
}
if ($missingStage.Count -gt 0) {
  throw "Stage verification failed. Missing:`n$($missingStage -join "`n")"
}

# ----- Create ZIP in current directory -----
if (Test-Path $Zip) { Remove-Item $Zip -Force }
Write-Host "Creating ZIP: $Zip"
Compress-Archive -Path (Join-Path $Pkg "*") -DestinationPath $Zip -Force

# ----- Verify ZIP entries quickly -----
Add-Type -AssemblyName System.IO.Compression.FileSystem
$zipObj = [System.IO.Compression.ZipFile]::OpenRead($Zip)
try {
  $entries = $zipObj.Entries | ForEach-Object { $_.FullName.TrimStart('./') }
  $set = [System.Collections.Generic.HashSet[string]]::new([string[]]$entries)
  $missingZip = @()
  foreach ($rel in $mustHave) {
    $pathInZip = ($rel -replace '\\','/')
    if (-not $set.Contains($pathInZip)) { $missingZip += $pathInZip }
  }
  if ($missingZip.Count -gt 0) {
    throw "Zip verification failed. Missing entries:`n$($missingZip -join "`n")"
  }
} finally {
  $zipObj.Dispose()
}

# ----- Inventory -----
Write-Host "ZIP OK. Inventory:"
Get-ChildItem $Pkg -Recurse | ForEach-Object {
  if (-not $_.PSIsContainer) {
    $rel = $_.FullName.Substring($Pkg.Length).TrimStart('\','/')
    "{0,8} bytes  {1}" -f $_.Length, $rel
  }
}

Write-Host "Done: $Zip"
