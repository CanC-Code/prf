#!/bin/bash
# File: scripts/generate_rpg.sh
# Author: CCVO
# Purpose: Fully procedural RPG APK generator with playable levels
# Requirements: bash, imagemagick, Android SDK

set -e

echo "=== Procedural RPG Generator Script (Playable Version) ==="

# ---- 1. Setup Gradle and Android SDK ----
echo "Generating Gradle wrapper..."
./gradlew wrapper || true

echo "Ensuring Android SDK build tools..."
yes | sdkmanager "build-tools;34.0.0" "platforms;android-34" >/dev/null

# ---- 2. Prepare resource folders ----
echo "Creating resource directories..."
mkdir -p app/src/main/res/mipmap-{mdpi,hdpi,xhdpi,xxhdpi,xxxhdpi}
mkdir -p app/src/main/res/drawable
mkdir -p app/src/main/assets/textures
mkdir -p app/src/main/assets/sprites
mkdir -p app/src/main/assets/config
mkdir -p app/src/main/assets/maps

# ---- 3. Generate launcher icons ----
echo "Generating launcher icons..."
for size in 48 72 96 144 192; do
    convert -size ${size}x${size} xc:skyblue \
        -gravity center -pointsize $((size/4)) \
        -fill white -annotate +0+0 "RPG" \
        app/src/main/res/mipmap-${size}x${size}/ic_launcher.png || true
done
convert -size 108x108 xc:green -gravity center -fill white -pointsize 24 \
    -annotate +0+0 "RPG" app/src/main/res/mipmap-anydpi-v26/ic_launcher_foreground.png || true
convert -size 108x108 xc:orange app/src/main/res/mipmap-anydpi-v26/ic_launcher_background.png || true

# ---- 4. Procedural textures ----
echo "Generating procedural tile textures..."
for i in {1..5}; do
    convert -size 64x64 pattern:checkerboard \
        -fill "rgb($((RANDOM%256)),$((RANDOM%256)),$((RANDOM%256)))" \
        -colorize 30 app/src/main/assets/textures/tile_$i.png || true
done

# ---- 5. Procedural sprites ----
echo "Generating placeholder sprites..."
for i in {1..3}; do
    convert -size 128x128 xc:none -fill "red" -draw "circle 64,64 64,0" \
        app/src/main/assets/sprites/player_$i.png || true
done
for i in {1..2}; do
    convert -size 64x64 xc:none -fill "green" -draw "circle 32,32 32,0" \
        app/src/main/assets/sprites/enemy_$i.png || true
done

# ---- 6. Generate procedural game configs ----
echo "Generating game config JSON..."
cat > app/src/main/assets/config/items.json <<EOL
{
  "items": [
    {"id":1,"name":"Sword","attack":5},
    {"id":2,"name":"Shield","defense":3},
    {"id":3,"name":"Potion","heal":10}
  ]
}
EOL

cat > app/src/main/assets/config/enemies.json <<EOL
{
  "enemies": [
    {"id":1,"name":"Slime","hp":10,"attack":2},
    {"id":2,"name":"Goblin","hp":20,"attack":5}
  ]
}
EOL

cat > app/src/main/assets/config/levels.json <<EOL
{
  "levels": [
    {"id":1,"name":"Grassland"},
    {"id":2,"name":"Dungeon"}
  ]
}
EOL

# ---- 7. Generate procedural maps ----
echo "Generating procedural maps..."
for level in Grassland Dungeon; do
    map_file="app/src/main/assets/maps/${level}.json"
    echo "{" > $map_file
    echo '  "tiles": [' >> $map_file
    for y in $(seq 0 9); do
        row="["
        for x in $(seq 0 9); do
            tile=$((RANDOM % 5 + 1))
            row+="$tile"
            if [ $x -lt 9 ]; then row+=","; fi
        done
        row+="]"
        echo "    $row" >> $map_file
        if [ $y -lt 9 ]; then echo "," >> $map_file; fi
    done
    echo '  ],' >> $map_file
    echo '  "enemies": [' >> $map_file
    for e in $(seq 0 $((RANDOM%5+1))); do
        x=$((RANDOM%10))
        y=$((RANDOM%10))
        type=$((RANDOM%2+1))
        echo "    {\"x\":$x,\"y\":$y,\"type\":$type}" >> $map_file
        if [ $e -lt 4 ]; then echo "," >> $map_file; fi
    done
    echo '  ],' >> $map_file
    echo '  "items": [' >> $map_file
    for i in $(seq 0 $((RANDOM%5+1))); do
        x=$((RANDOM%10))
        y=$((RANDOM%10))
        item=$((RANDOM%3+1))
        echo "    {\"x\":$x,\"y\":$y,\"item\":$item}" >> $map_file
        if [ $i -lt 4 ]; then echo "," >> $map_file; fi
    done
    echo '  ]' >> $map_file
    echo "}" >> $map_file
done

# ---- 8. Build APK ----
echo "Building debug APK..."
./gradlew clean assembleDebug

echo "=== Procedural RPG APK generation complete! ==="
echo "Check app/build/outputs/apk/debug for the generated APK."