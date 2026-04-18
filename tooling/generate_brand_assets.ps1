Add-Type -AssemblyName System.Drawing

$projectRoot = Split-Path -Parent $PSScriptRoot
$outputPath = Join-Path $projectRoot "assets\images\app_icon.png"
$outputDir = Split-Path -Parent $outputPath

if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir | Out-Null
}

function Add-RoundedRectPath {
    param(
        [System.Drawing.Drawing2D.GraphicsPath]$Path,
        [float]$X,
        [float]$Y,
        [float]$Width,
        [float]$Height,
        [float]$Radius
    )

    $diameter = $Radius * 2
    $Path.AddArc($X, $Y, $diameter, $diameter, 180, 90)
    $Path.AddArc($X + $Width - $diameter, $Y, $diameter, $diameter, 270, 90)
    $Path.AddArc($X + $Width - $diameter, $Y + $Height - $diameter, $diameter, $diameter, 0, 90)
    $Path.AddArc($X, $Y + $Height - $diameter, $diameter, $diameter, 90, 90)
    $Path.CloseFigure()
}

$size = 1024
$bitmap = New-Object System.Drawing.Bitmap $size, $size
$graphics = [System.Drawing.Graphics]::FromImage($bitmap)

try {
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality

    $backgroundRect = New-Object System.Drawing.RectangleF(0, 0, $size, $size)
    $backgroundBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
        $backgroundRect,
        ([System.Drawing.Color]::FromArgb(255, 18, 23, 32)),
        ([System.Drawing.Color]::FromArgb(255, 8, 10, 15)),
        90
    )
    $graphics.FillRectangle($backgroundBrush, $backgroundRect)

    $framePen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(34, 255, 255, 255), 8)
    $graphics.DrawRectangle($framePen, 4, 4, $size - 8, $size - 8)

    $white = [System.Drawing.Color]::FromArgb(255, 246, 248, 253)
    $dark = [System.Drawing.Color]::FromArgb(255, 8, 10, 15)
    $accent = [System.Drawing.Color]::FromArgb(255, 64, 218, 255)
    $accentSoft = [System.Drawing.Color]::FromArgb(72, 64, 218, 255)

    $outerBubble = New-Object System.Drawing.Drawing2D.GraphicsPath
    Add-RoundedRectPath -Path $outerBubble -X 182 -Y 222 -Width 660 -Height 450 -Radius 132
    $outerBubble.AddPolygon(@(
        (New-Object System.Drawing.PointF(324, 672)),
        (New-Object System.Drawing.PointF(424, 672)),
        (New-Object System.Drawing.PointF(276, 816))
    ))
    $graphics.FillPath((New-Object System.Drawing.SolidBrush($white)), $outerBubble)

    $innerBubble = New-Object System.Drawing.Drawing2D.GraphicsPath
    Add-RoundedRectPath -Path $innerBubble -X 270 -Y 308 -Width 484 -Height 286 -Radius 88
    $innerBubble.AddPolygon(@(
        (New-Object System.Drawing.PointF(366, 594)),
        (New-Object System.Drawing.PointF(432, 594)),
        (New-Object System.Drawing.PointF(334, 694))
    ))
    $graphics.FillPath((New-Object System.Drawing.SolidBrush($dark)), $innerBubble)

    $chevronPen = New-Object System.Drawing.Pen($white, 34)
    $chevronPen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $chevronPen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
    $chevronPen.LineJoin = [System.Drawing.Drawing2D.LineJoin]::Round

    $slashPen = New-Object System.Drawing.Pen($accent, 34)
    $slashPen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $slashPen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round

    $graphics.DrawLines($chevronPen, @(
        (New-Object System.Drawing.Point(396, 452)),
        (New-Object System.Drawing.Point(330, 505)),
        (New-Object System.Drawing.Point(396, 558))
    ))
    $graphics.DrawLine($slashPen, 500, 416, 452, 594)
    $graphics.DrawLines($chevronPen, @(
        (New-Object System.Drawing.Point(618, 452)),
        (New-Object System.Drawing.Point(684, 505)),
        (New-Object System.Drawing.Point(618, 558))
    ))

    $glowBrush = New-Object System.Drawing.SolidBrush($accentSoft)
    $graphics.FillEllipse($glowBrush, 706, 180, 154, 154)

    $dotBrush = New-Object System.Drawing.SolidBrush($accent)
    $graphics.FillEllipse($dotBrush, 748, 222, 70, 70)

    $bitmap.Save($outputPath, [System.Drawing.Imaging.ImageFormat]::Png)
    Write-Output "Generated $outputPath"
}
finally {
    if ($null -ne $dotBrush) { $dotBrush.Dispose() }
    if ($null -ne $glowBrush) { $glowBrush.Dispose() }
    if ($null -ne $slashPen) { $slashPen.Dispose() }
    if ($null -ne $chevronPen) { $chevronPen.Dispose() }
    if ($null -ne $innerBubble) { $innerBubble.Dispose() }
    if ($null -ne $outerBubble) { $outerBubble.Dispose() }
    if ($null -ne $framePen) { $framePen.Dispose() }
    if ($null -ne $backgroundBrush) { $backgroundBrush.Dispose() }
    $graphics.Dispose()
    $bitmap.Dispose()
}
