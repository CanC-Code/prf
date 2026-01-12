#!/usr/bin/env bash
set -e

echo "=== Generating Dynamic RPG Assets ==="

SRC="app/src/main"
RES_DRAWABLE="$SRC/res/drawable"

mkdir -p "$RES_DRAWABLE"

# ============================
# Grass tile (green with subtle highlights)
# ============================
convert -size 96x96 xc:"rgb(60,170,60)" \
    -fill "rgba(80,200,80,0.3)" -draw "rectangle 0,0 96,96" \
    -blur 0x1 "$RES_DRAWABLE/tile_grass.png"

# ============================
# Forest tile (darker green with simple overlay)
# ============================
convert -size 96x96 xc:"rgb(30,100,30)" \
    -fill "rgba(50,130,50,0.5)" -draw "rectangle 0,0 96,96" \
    -blur 0x1 "$RES_DRAWABLE/tile_forest.png"

# ============================
# Water tile (blue with simple wave lines)
# ============================
convert -size 96x96 xc:rgb(50,120,200) \
    -stroke white -strokewidth 2 \
    -draw "line 0,48 48,32" \
    -draw "line 48,32 96,48" \
    -draw "line 0,64 48,48" \
    -draw "line 48,48 96,64" \
    -blur 0x1 \
    "$RES_DRAWABLE/tile_water.png"

# ============================
# Chest tile (brown box with gold lid)
# ============================
convert -size 96x96 xc:rgb(150,75,0) \
    -stroke black -strokewidth 2 \
    -fill rgb(200,150,50) \
    -draw "rectangle 16,16 80,80" \
    "$RES_DRAWABLE/tile_chest.png"

# ============================
# Player icon (red circle with subtle shading)
# ============================
convert -size 96x96 xc:none \
    -fill red -draw "circle 48,48 48,24" \
    -shade 120x45 -normalize \
    "$RES_DRAWABLE/player.png"

# ============================
# Enemy icon (purple circle with subtle shading)
# ============================
convert -size 96x96 xc:none \
    -fill purple -draw "circle 48,48 48,24" \
    -shade 120x45 -normalize \
    "$RES_DRAWABLE/enemy.png"

echo "=== RPG Assets Generated Successfully ==="