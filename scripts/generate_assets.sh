#!/usr/bin/env bash
set -e

echo "=== Generating Procedural RPG Assets ==="

############################
# Config
############################
APP_RES="app/src/main/res"
FONT="/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"

# Colors
ICON_COLOR="#FF5722"
ICON_TEXT="RPG"

GRASS_COLOR="#3CAA3C"
FOREST_COLOR="#1E6432"
WATER_COLOR="#3399FF"
PLAYER_COLOR="#FF0000"
BUTTON_COLOR="#333333"
BUTTON_TEXT_COLOR="#FFFFFF"

############################
# Launcher Icons
############################
echo "--- Generating launcher icons ---"
for size in 48 72 96 144 192; do
    ICON_PATH="$APP_RES/mipmap-${size}x${size}/ic_launcher.png"
    mkdir -p "$(dirname "$ICON_PATH")"
    
    convert -size ${size}x${size} canvas:${ICON_COLOR} \
        -gravity center -pointsize $((size/3)) -fill white -font "$FONT" -annotate 0 "$ICON_TEXT" \
        "$ICON_PATH"
done

# Vector fallback
mkdir -p "$APP_RES/mipmap-anydpi-v26"
cat > "$APP_RES/mipmap-anydpi-v26/ic_launcher.xml" <<EOF
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="192dp"
    android:height="192dp"
    android:viewportWidth="192"
    android:viewportHeight="192">
    <path android:fillColor="${ICON_COLOR}" android:pathData="M0,0h192v192h-192z"/>
</vector>
EOF

############################
# Procedural Tiles
############################
echo "--- Generating map tiles ---"
TILE_DIR="$APP_RES/drawable"
mkdir -p "$TILE_DIR"

# Grass
convert -size 96x96 canvas:"$GRASS_COLOR" "$TILE_DIR/tile_grass.png"

# Forest
convert -size 96x96 canvas:"$FOREST_COLOR" "$TILE_DIR/tile_forest.png"

# Water
convert -size 96x96 canvas:"$WATER_COLOR" "$TILE_DIR/tile_water.png"

############################
# Player Marker
############################
echo "--- Generating player marker ---"
convert -size 96x96 xc:none -fill "$PLAYER_COLOR" -draw "circle 48,48 48,20" "$TILE_DIR/player_marker.png"

############################
# UI Buttons (example: Attack, Defend)
############################
echo "--- Generating UI buttons ---"
mkdir -p "$TILE_DIR/ui_buttons"

for label in "Attack" "Defend" "Item" "Run"; do
    convert -size 200x60 canvas:"$BUTTON_COLOR" \
        -gravity center -pointsize 32 -fill "$BUTTON_TEXT_COLOR" -font "$FONT" -annotate 0 "$label" \
        "$TILE_DIR/ui_buttons/btn_${label,,}.png"
done

echo "=== Procedural RPG Assets Generation Complete ==="