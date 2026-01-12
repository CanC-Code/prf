#!/usr/bin/env bash
set -e

echo "=== Generating Dynamic RPG Assets ==="

SRC="app/src/main"
RES_DRAWABLE="$SRC/res/drawable"

mkdir -p "$RES_DRAWABLE"

# ============================
# Helper function for textured tiles (safe, no parentheses)
# ============================
generate_textured_tile() {
    local file="$1"
    local base_color="$2"
    local overlay_color="$3"

    # Create base colored tile with subtle overlay
    convert -size 96x96 xc:"$base_color" \
        -fill "$overlay_color" -draw "rectangle 0,0 96,96" \
        -blur 0x1 "$file"
}

# ============================
# Grass tile (green with subtle highlights)
# ============================
generate_textured_tile "$RES_DRAWABLE/tile_grass.png" "rgb(60,170,60)" "rgba(80,200,80,0.3)"

# ============================
# Forest tile (darker green with subtle tree strokes)
# ============================
generate_textured_tile "$RES_DRAWABLE/tile_forest.png" "rgb(30,100,30)" "rgba(50,130,50,0.5)"

# ============================
# Water tile (blue waves)
# ============================
convert -size 96x96 xc:rgb(50,120,200) \
    -stroke white -strokewidth 2 \
    -draw "path 'M0,48 Q24,32 48,48 T96,48'" \
    -blur 0x1 "$RES_DRAWABLE/tile_water.png"

# ============================
# Chest tile (brown box with gold top)
# ============================
convert -size 96x96 xc:rgb(150,75,0) \
    -stroke black -strokewidth 2 \
    -fill rgb(200,150,50) \
    -draw "rectangle 16,16 80,80" \
    "$RES_DRAWABLE/tile_chest.png"

# ============================
# Player icon (red circle with shading)
# ============================
convert -size 96x96 xc:none \
    -fill red -draw "circle 48,48 48,24" \
    -shade 120x45 -normalize \
    "$RES_DRAWABLE/player.png"

# ============================
# Enemy icon (purple circle with shading)
# ============================
convert -size 96x96 xc:none \
    -fill purple -draw "circle 48,48 48,24" \
    -shade 120x45 -normalize \
    "$RES_DRAWABLE/enemy.png"

echo "=== RPG Assets Generated ==="