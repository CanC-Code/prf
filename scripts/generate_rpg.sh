#!/usr/bin/env bash
set -e
echo "=== Full Procedural RPG Generator Script ==="

# Ensure Gradle wrapper exists
if [ ! -f ./gradlew ]; then
    echo "Gradle wrapper not found. Please run setup_gradle.sh first."
    exit 1
fi

# Step 1: Ensure Android SDK build tools
echo "Ensuring Android SDK build tools..."
yes | sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0"

# Step 2: Create resource directories if missing
echo "Creating resource directories..."
mkdir -p app/src/main/res/mipmap-48x48
mkdir -p app/src/main/res/mipmap-72x72
mkdir -p app/src/main/res/mipmap-96x96
mkdir -p app/src/main/res/mipmap-144x144
mkdir -p app/src/main/res/mipmap-192x192
mkdir -p app/src/main/res/mipmap-anydpi-v26

# Step 3: Generate launcher icons
echo "Generating launcher icons..."
ICON_SIZES=(48 72 96 144 192)
for size in "${ICON_SIZES[@]}"; do
    convert -size "${size}x${size}" xc:'#ff4500' \
        -gravity center -pointsize $((size/4)) -fill white -annotate +0+0 "RPG" \
        "app/src/main/res/mipmap-${size}x${size}/ic_launcher.png"
done
# Anydpi icons
convert -size 512x512 xc:'#ff4500' \
    -gravity center -pointsize 128 -fill white -annotate +0+0 "RPG" \
    app/src/main/res/mipmap-anydpi-v26/ic_launcher_foreground.png
convert -size 512x512 xc:'#222222' \
    app/src/main/res/mipmap-anydpi-v26/ic_launcher_background.png

# Step 4: Generate procedural tile textures
echo "Generating procedural tile textures..."
mkdir -p app/src/main/res/drawable
for i in {1..10}; do
    convert -size 64x64 xc:"#%06x" $((RANDOM*65536)) \
        "app/src/main/res/drawable/tile_${i}.png"
done

# Step 5: Generate placeholder sprites
echo "Generating placeholder sprites..."
mkdir -p app/src/main/res/drawable/sprites
for i in {1..5}; do
    convert -size 32x32 xc:"#%06x" $((RANDOM*65536)) \
        -fill black -draw "circle 16,16 16,1" \
        "app/src/main/res/drawable/sprites/sprite_${i}.png"
done

# Step 6: Generate game config JSON
echo "Generating game config JSON..."
mkdir -p app/src/main/assets
cat <<EOL > app/src/main/assets/game_config.json
{
  "game_name": "Procedural RPG",
  "version": "1.0",
  "tiles": 10,
  "sprites": 5,
  "maps": 3
}
EOL

# Step 7: Generate procedural maps
echo "Generating procedural maps..."
for map_id in {1..3}; do
    cat <<EOL > app/src/main/assets/map_${map_id}.json
{
  "map_id": ${map_id},
  "width": 16,
  "height": 16,
  "tiles": [
    $(for y in {1..16}; do
        echo "["
        for x in {1..16}; do
            echo $((RANDOM % 10)),
        done
        echo "],"
    done)
  ]
}
EOL
done

# Step 8: Build APK
echo "Building debug APK..."
./gradlew assembleDebug

echo "=== Procedural RPG generation complete! ==="
echo "You can now install the APK from app/build/outputs/apk/debug/"