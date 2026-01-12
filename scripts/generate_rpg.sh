#!/usr/bin/env bash
set -e
echo "=== Full Procedural RPG Generator Script ==="

# Ensure Gradle project exists
if [ ! -f ./gradlew ]; then
    echo "Gradle wrapper missing! Please run setup_gradle.sh first."
    exit 1
fi

# Create Android resource directories if missing
echo "Creating resource directories..."
mkdir -p app/src/main/res/layout
mkdir -p app/src/main/res/drawable
mkdir -p app/src/main/res/mipmap-48x48
mkdir -p app/src/main/res/mipmap-72x72
mkdir -p app/src/main/res/mipmap-96x96
mkdir -p app/src/main/res/mipmap-144x144
mkdir -p app/src/main/res/mipmap-192x192
mkdir -p app/src/main/res/mipmap-anydpi-v26

# Generate launcher icons (simple colored squares)
echo "Generating launcher icons..."
for size in 48 72 96 144 192; do
    convert -size "${size}x${size}" xc:blue app/src/main/res/mipmap-"${size}x${size}"/ic_launcher.png
done

# Generate adaptive icons for Android
convert -size 108x108 xc:blue app/src/main/res/mipmap-anydpi-v26/ic_launcher_foreground.png
convert -size 108x108 xc:white app/src/main/res/mipmap-anydpi-v26/ic_launcher_background.png

# Generate procedural tile textures
echo "Generating procedural tile textures..."
mkdir -p app/src/main/res/drawable/tiles
for tile in grass water stone lava; do
    convert -size 64x64 xc:green app/src/main/res/drawable/tiles/"${tile}.png"
done

# Generate placeholder sprites
echo "Generating placeholder sprites..."
mkdir -p app/src/main/res/drawable/sprites
for sprite in hero enemy npc; do
    convert -size 64x64 xc:red app/src/main/res/drawable/sprites/"${sprite}.png"
done

# Generate minimal XML layout
echo "Generating main activity layout..."
cat <<EOL > app/src/main/res/layout/activity_main.xml
<?xml version="1.0" encoding="utf-8"?>
<FrameLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:id="@+id/game_container"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:background="#000000">
</FrameLayout>
EOL

# Generate minimal MainActivity.java
echo "Generating MainActivity.java..."
cat <<EOL > app/src/main/java/com/example/rpg/MainActivity.java
package com.example.rpg;

import android.os.Bundle;
import androidx.appcompat.app.AppCompatActivity;

public class MainActivity extends AppCompatActivity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
    }
}
EOL

# Generate procedural game config JSON
echo "Generating procedural game config..."
mkdir -p app/src/main/assets
cat <<EOL > app/src/main/assets/game_config.json
{
    "world": {
        "width": 100,
        "height": 100,
        "tiles": ["grass", "water", "stone", "lava"]
    },
    "entities": ["hero", "enemy", "npc"]
}
EOL

# Optional: create placeholder maps
echo "Generating procedural maps..."
mkdir -p app/src/main/assets/maps
for i in $(seq 1 3); do
    cat <<EOL > app/src/main/assets/maps/map${i}.txt
####################
#..................#
#....###...........#
#....#.#...........#
#..................#
####################
EOL
done

# Build APK
echo "Building debug APK..."
./gradlew :app:assembleDebug --no-daemon --stacktrace

echo "Procedural RPG generation complete!"
echo "APK available at app/build/outputs/apk/debug/app-debug.apk"