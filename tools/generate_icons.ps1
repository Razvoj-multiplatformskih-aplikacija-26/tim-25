# Derive platform icons from the original logo. Run from any directory.
Add-Type -AssemblyName System.Drawing
$projectRoot = Split-Path -Parent $PSScriptRoot
$sourcePath = Join-Path $projectRoot 'packages/ui/assets/branding/logo.png'
$sourceLogo = [System.Drawing.Image]::FromFile($sourcePath)
$splashSymbol = [System.Drawing.Image]::FromFile((Join-Path $projectRoot 'packages/ui/assets/branding/splash_symbol.png'))
function Get-LogoPng([int]$size, [bool]$maskable = $false, [System.Drawing.Image]$imageSource = $sourceLogo) {
    $bitmap = [System.Drawing.Bitmap]::new($size, $size, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $graphics.Clear([System.Drawing.Color]::Transparent)
    $inset = 0
    if ($maskable) {
        $graphics.Clear([System.Drawing.ColorTranslator]::FromHtml('#172B4D'))
        $inset = [int]($size * .10)
    }
    $availableSize = $size - 2 * $inset
    $scale = [Math]::Min($availableSize / $imageSource.Width, $availableSize / $imageSource.Height)
    $drawWidth = [int][Math]::Round($imageSource.Width * $scale)
    $drawHeight = [int][Math]::Round($imageSource.Height * $scale)
    $graphics.DrawImage($imageSource, [int](($size - $drawWidth) / 2), [int](($size - $drawHeight) / 2), $drawWidth, $drawHeight)
    $buffer = [System.IO.MemoryStream]::new()
    $bitmap.Save($buffer, [System.Drawing.Imaging.ImageFormat]::Png)
    $bytes = $buffer.ToArray()
    $buffer.Dispose(); $graphics.Dispose(); $bitmap.Dispose()
    return ,$bytes
}
function Write-LogoPng([int]$size, [string]$target, [bool]$maskable = $false, [System.Drawing.Image]$imageSource = $sourceLogo) {
    $parentDirectory = Split-Path -Parent $target
    [System.IO.Directory]::CreateDirectory($parentDirectory) | Out-Null
    [System.IO.File]::WriteAllBytes($target, (Get-LogoPng $size $maskable $imageSource))
}
try {
    $densities = @{mdpi=48; hdpi=72; xhdpi=96; xxhdpi=144; xxxhdpi=192}
    foreach ($density in $densities.Keys) {
        Write-LogoPng $densities[$density] "$projectRoot/apps/mobile/android/app/src/main/res/mipmap-$density/ic_launcher.png"
        Write-LogoPng ($densities[$density] * 3) "$projectRoot/apps/mobile/android/app/src/main/res/drawable-$density/launch_logo.png" $false $splashSymbol
    }
    foreach ($size in @(192, 512)) {
        Write-LogoPng $size "$projectRoot/apps/backoffice/web/icons/Icon-$size.png"
        Write-LogoPng $size "$projectRoot/apps/backoffice/web/icons/Icon-maskable-$size.png" $true
    }
    Write-LogoPng 32 "$projectRoot/apps/backoffice/web/favicon.png"
    $frames = @(foreach ($size in @(16, 24, 32, 48, 64, 128, 256)) {
        @{ Size = $size; Bytes = (Get-LogoPng $size) }
    })
    $iconPath = "$projectRoot/apps/backoffice/windows/runner/resources/app_icon.ico"
    $stream = [System.IO.File]::Create($iconPath)
    $writer = [System.IO.BinaryWriter]::new($stream)
    try {
        $writer.Write([uint16]0); $writer.Write([uint16]1); $writer.Write([uint16]$frames.Count)
        $offset = 6 + 16 * $frames.Count
        foreach ($frame in $frames) {
            $dimension = if ($frame.Size -eq 256) { 0 } else { $frame.Size }
            $writer.Write([byte]$dimension); $writer.Write([byte]$dimension)
            $writer.Write([byte]0); $writer.Write([byte]0)
            $writer.Write([uint16]1); $writer.Write([uint16]32)
            $writer.Write([uint32]$frame.Bytes.Length); $writer.Write([uint32]$offset)
            $offset += $frame.Bytes.Length
        }
        foreach ($frame in $frames) { $writer.Write([byte[]]$frame.Bytes) }
    } finally { $writer.Dispose(); $stream.Dispose() }
} finally { $sourceLogo.Dispose(); $splashSymbol.Dispose() }
