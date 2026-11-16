$csharpCode = @"
using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.Drawing.Text;

public class TvBannerGenerator
{
    public static void Generate(string outputPath)
    {
        int width = 320;
        int height = 180;

        using (Bitmap bmp = new Bitmap(width, height, PixelFormat.Format32bppArgb))
        using (Graphics g = Graphics.FromImage(bmp))
        {
            g.SmoothingMode = SmoothingMode.AntiAlias;
            g.InterpolationMode = InterpolationMode.HighQualityBicubic;
            g.PixelOffsetMode = PixelOffsetMode.HighQuality;
            g.TextRenderingHint = TextRenderingHint.ClearTypeGridFit;

            // 1. Dark futuristic background gradient
            using (LinearGradientBrush bgBrush = new LinearGradientBrush(
                new Point(0, 0),
                new Point(width, height),
                Color.FromArgb(255, 12, 15, 24),
                Color.FromArgb(255, 20, 26, 42)))
            {
                g.FillRectangle(bgBrush, 0, 0, width, height);
            }

            // Radial cyan glow behind the icon badge
            using (GraphicsPath glowPath = new GraphicsPath())
            {
                glowPath.AddEllipse(-15, 15, 170, 150);
                using (PathGradientBrush glowBrush = new PathGradientBrush(glowPath))
                {
                    glowBrush.CenterColor = Color.FromArgb(48, 0, 229, 255);
                    glowBrush.SurroundColors = new Color[] { Color.FromArgb(0, 12, 15, 24) };
                    g.FillPath(glowBrush, glowPath);
                }
            }

            // 2. Icon Badge on the left
            int badgeX = 26;
            int badgeY = 44;
            int badgeSize = 92;
            int radius = 20;

            using (GraphicsPath badgePath = new GraphicsPath())
            {
                int d = radius * 2;
                badgePath.AddArc(badgeX, badgeY, d, d, 180, 90);
                badgePath.AddArc(badgeX + badgeSize - d, badgeY, d, d, 270, 90);
                badgePath.AddArc(badgeX + badgeSize - d, badgeY + badgeSize - d, d, d, 0, 90);
                badgePath.AddArc(badgeX, badgeY + badgeSize - d, d, d, 90, 90);
                badgePath.CloseFigure();

                // Badge interior fill
                using (SolidBrush badgeFill = new SolidBrush(Color.FromArgb(255, 17, 22, 34)))
                {
                    g.FillPath(badgeFill, badgePath);
                }

                // Badge border gradient (Cyan to Purple)
                using (LinearGradientBrush borderBrush = new LinearGradientBrush(
                    new Point(badgeX, badgeY),
                    new Point(badgeX + badgeSize, badgeY + badgeSize),
                    Color.FromArgb(255, 0, 229, 255),
                    Color.FromArgb(255, 124, 77, 255)))
                using (Pen borderPen = new Pen(borderBrush, 2.5f))
                {
                    g.DrawPath(borderPen, badgePath);
                }
            }

            // Lightning Bolt inside badge
            float bx = badgeX + 17;
            float by = badgeY + 14;
            float bw = badgeSize - 34;
            float bh = badgeSize - 28;

            PointF[] boltPoints = new PointF[]
            {
                new PointF(bx + 0.54f * bw, by + 0.05f * bh),
                new PointF(bx + 0.74f * bw, by + 0.44f * bh),
                new PointF(bx + 0.53f * bw, by + 0.44f * bh),
                new PointF(bx + 0.66f * bw, by + 0.95f * bh),
                new PointF(bx + 0.28f * bw, by + 0.52f * bh),
                new PointF(bx + 0.48f * bw, by + 0.52f * bh),
            };

            using (GraphicsPath boltPath = new GraphicsPath())
            {
                boltPath.AddPolygon(boltPoints);

                // Cyan aura around bolt
                using (Pen glowPen = new Pen(Color.FromArgb(90, 0, 229, 255), 6f))
                {
                    glowPen.LineJoin = LineJoin.Round;
                    g.DrawPath(glowPen, boltPath);
                }

                // Bolt gradient fill
                using (LinearGradientBrush boltBrush = new LinearGradientBrush(
                    new PointF(bx, by),
                    new PointF(bx, by + bh),
                    Color.FromArgb(255, 0, 229, 255),
                    Color.FromArgb(255, 170, 90, 255)))
                {
                    g.FillPath(boltBrush, boltPath);
                }
            }

            // 3. Typography on the Right
            float textStartX = 124f;
            float titleY = 48f;

            using (Font titleFont = new Font("Segoe UI", 32f, FontStyle.Bold, GraphicsUnit.Pixel))
            using (Font subFont = new Font("Segoe UI", 12f, FontStyle.Bold, GraphicsUnit.Pixel))
            {
                SizeF veloxSize = g.MeasureString("Velox", titleFont);

                // Title Drop Shadow
                using (SolidBrush shadowBrush = new SolidBrush(Color.FromArgb(220, 0, 0, 0)))
                {
                    g.DrawString("Velox", titleFont, shadowBrush, textStartX + 2, titleY + 2);
                    g.DrawString("TV", titleFont, shadowBrush, textStartX + veloxSize.Width - 9 + 2, titleY + 2);
                }

                // Title: "Velox" in White, "TV" in Neon Cyan
                using (SolidBrush whiteBrush = new SolidBrush(Color.FromArgb(255, 255, 255, 255)))
                using (SolidBrush cyanBrush = new SolidBrush(Color.FromArgb(255, 0, 229, 255)))
                {
                    g.DrawString("Velox", titleFont, whiteBrush, textStartX, titleY);
                    g.DrawString("TV", titleFont, cyanBrush, textStartX + veloxSize.Width - 9, titleY);
                }

                // Subtitle: "NEXT-GEN IPTV PLAYER"
                float subY = 96f;
                using (SolidBrush subShadow = new SolidBrush(Color.FromArgb(180, 0, 0, 0)))
                using (SolidBrush subBrush = new SolidBrush(Color.FromArgb(255, 130, 185, 220)))
                {
                    g.DrawString("NEXT-GEN IPTV PLAYER", subFont, subShadow, textStartX + 1, subY + 1);
                    g.DrawString("NEXT-GEN IPTV PLAYER", subFont, subBrush, textStartX, subY);
                }

                // Cyan accent glow underline
                using (Pen linePen = new Pen(Color.FromArgb(180, 0, 229, 255), 2f))
                {
                    g.DrawLine(linePen, textStartX, subY + 20, textStartX + 155, subY + 20);
                }
            }

            // 4. Subtle Outer Border
            using (Pen borderPen = new Pen(Color.FromArgb(35, 255, 255, 255), 1f))
            {
                g.DrawRectangle(borderPen, 0, 0, width - 1, height - 1);
            }

            // Save to disk
            bmp.Save(outputPath, ImageFormat.Png);
        }
    }
}
"@

Add-Type -TypeDefinition $csharpCode -ReferencedAssemblies "System.Drawing"

$bannerPath = "C:\Users\meshk\.gemini\antigravity\scratch\veloxtv\android\app\src\main\res\drawable\tv_banner.png"
[TvBannerGenerator]::Generate($bannerPath)

# Also copy to assets/icon/tv_banner.png
$assetPath = "C:\Users\meshk\.gemini\antigravity\scratch\veloxtv\assets\icon\tv_banner.png"
[System.IO.Directory]::CreateDirectory((Split-Path $assetPath)) | Out-Null
[TvBannerGenerator]::Generate($assetPath)

Write-Output "Successfully generated TV Banner with App Name at: $bannerPath"
