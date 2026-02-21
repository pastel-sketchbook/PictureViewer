#!/bin/bash
# Generate app icons from SVG source
# Requires: librsvg (for rsvg-convert) and ImageMagick (for convert/magick)
# Install on macOS: brew install librsvg imagemagick

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ICONS_DIR="$SCRIPT_DIR"
SVG_SOURCE="$ICONS_DIR/app-icon.svg"

echo "🎨 Generating app icons from SVG..."

# Check if tools are available
if ! command -v rsvg-convert &> /dev/null; then
    echo "❌ rsvg-convert not found. Install with: brew install librsvg"
    exit 1
fi

if ! command -v magick &> /dev/null && ! command -v convert &> /dev/null; then
    echo "❌ ImageMagick not found. Install with: brew install imagemagick"
    exit 1
fi

# Use magick or convert depending on what's available
if command -v magick &> /dev/null; then
    CONVERT_CMD="magick"
else
    CONVERT_CMD="convert"
fi

# Function to generate PNG from SVG
generate_png() {
    local size=$1
    local output=$2
    echo "  Generating $output (${size}x${size})"
    rsvg-convert -w $size -h $size "$SVG_SOURCE" -o "$output"
}

# Generate PNGs
generate_png 32 "$ICONS_DIR/32x32.png"
generate_png 128 "$ICONS_DIR/128x128.png"
generate_png 256 "$ICONS_DIR/128x128@2x.png"
generate_png 1024 "$ICONS_DIR/icon.png"

# Windows Store logos
generate_png 30 "$ICONS_DIR/Square30x30Logo.png"
generate_png 44 "$ICONS_DIR/Square44x44Logo.png"
generate_png 71 "$ICONS_DIR/Square71x71Logo.png"
generate_png 89 "$ICONS_DIR/Square89x89Logo.png"
generate_png 107 "$ICONS_DIR/Square107x107Logo.png"
generate_png 142 "$ICONS_DIR/Square142x142Logo.png"
generate_png 150 "$ICONS_DIR/Square150x150Logo.png"
generate_png 284 "$ICONS_DIR/Square284x284Logo.png"
generate_png 310 "$ICONS_DIR/Square310x310Logo.png"
generate_png 50 "$ICONS_DIR/StoreLogo.png"

echo "  Generating icon.ico (Windows)"
$CONVERT_CMD "$ICONS_DIR/32x32.png" "$ICONS_DIR/128x128.png" "$ICONS_DIR/128x128@2x.png" "$ICONS_DIR/icon.png" "$ICONS_DIR/icon.ico"

echo "  Generating icon.icns (macOS)"
# Create iconset directory
ICONSET_DIR="$ICONS_DIR/icon.iconset"
mkdir -p "$ICONSET_DIR"

# Generate all required sizes for macOS
generate_png 16 "$ICONSET_DIR/icon_16x16.png"
generate_png 32 "$ICONSET_DIR/icon_16x16@2x.png"
generate_png 32 "$ICONSET_DIR/icon_32x32.png"
generate_png 64 "$ICONSET_DIR/icon_32x32@2x.png"
generate_png 128 "$ICONSET_DIR/icon_128x128.png"
generate_png 256 "$ICONSET_DIR/icon_128x128@2x.png"
generate_png 256 "$ICONSET_DIR/icon_256x256.png"
generate_png 512 "$ICONSET_DIR/icon_256x256@2x.png"
generate_png 512 "$ICONSET_DIR/icon_512x512.png"
generate_png 1024 "$ICONSET_DIR/icon_512x512@2x.png"

# Convert iconset to icns
iconutil -c icns "$ICONSET_DIR" -o "$ICONS_DIR/icon.icns"

# Clean up iconset directory
rm -rf "$ICONSET_DIR"

echo "✅ Icon generation complete!"
echo ""
echo "Generated files:"
echo "  - icon.png (1024x1024)"
echo "  - icon.icns (macOS)"
echo "  - icon.ico (Windows)"
echo "  - Various PNG sizes for different platforms"
