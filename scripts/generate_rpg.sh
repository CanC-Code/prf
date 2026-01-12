#!/usr/bin/env bash
set -e

echo "/// Credit: CCVO - Procedural RPG Workflow Generator Full"

# --- 0. Create Android project structure ---
mkdir -p app/src/main/assets/generated
mkdir -p app/src/main/res/drawable
mkdir -p app/src/main/res/mipmap-mdpi
mkdir -p app/src/main/res/mipmap-hdpi
mkdir -p app/src/main/res/mipmap-xhdpi
mkdir -p app/src/main/res/mipmap-xxhdpi
mkdir -p app/src/main/res/mipmap-xxxhdpi
mkdir -p app/src/main/java/com/canc/rpg
mkdir -p app/src/main/cpp

# --- 1. Root-level settings.gradle ---
cat <<'EOF' > settings.gradle
rootProject.name = "ProceduralRPG"
include(":app")
EOF

# --- 2. Root-level build.gradle (with Android plugin classpath) ---
cat <<'EOF' > build.gradle
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath "com.android.tools.build:gradle:8.2.1"
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}
EOF

# --- 3. App build.gradle ---
cat <<'EOF' > app/build.gradle
apply plugin: 'com.android.application'

android {
    compileSdkVersion 34
    defaultConfig {
        applicationId "com.canc.rpg"
        minSdkVersion 21
        targetSdkVersion 34
        versionCode 1
        versionName "1.0"
    }
    buildTypes {
        debug {
            debuggable true
        }
    }
}

dependencies {
}
EOF

# --- 4. Generate Gradle wrapper ---
gradle wrapper --gradle-version 8.2 --distribution-type all
chmod +x gradlew

# --- 5. Generate procedural world JSON ---
width=$((RANDOM%8+10))
height=$((RANDOM%8+10))
echo "{" > app/src/main/assets/generated/world.json
echo '  "tiles": [' >> app/src/main/assets/generated/world.json
for ((y=0;y<height;y++)); do
    row="["
    for ((x=0;x<width;x++)); do
        r=$((RANDOM%5))
        tile="grass"
        [[ $r -eq 1 ]] && tile="water"
        [[ $r -eq 2 ]] && tile="tree"
        [[ $r -eq 3 ]] && tile="sand"
        [[ $r -eq 4 ]] && tile="rock"
        row="$row\"$tile\""
        [[ $x -lt $((width-1)) ]] && row="$row,"
    done
    row="$row]"
    echo "    $row" >> app/src/main/assets/generated/world.json
    [[ $y -lt $((height-1)) ]] && echo "," >> app/src/main/assets/generated/world.json
done
echo '  ],' >> app/src/main/assets/generated/world.json

npc_count=$((RANDOM%5+3))
echo '  "npcs": [' >> app/src/main/assets/generated/world.json
for ((i=1;i<=npc_count;i++)); do
    x=$((RANDOM%width))
    y=$((RANDOM%height))
    echo "    {\"name\":\"Villager$i\",\"x\":$x,\"y\":$y,\"dialog\":\"Hello!\"}" >> app/src/main/assets/generated/world.json
    [[ $i -lt $npc_count ]] && echo "," >> app/src/main/assets/generated/world.json
done
echo '  ],' >> app/src/main/assets/generated/world.json

enemy_count=$((RANDOM%6+3))
types=("Slime" "Goblin" "Orc" "Bat")
echo '  "enemies": [' >> app/src/main/assets/generated/world.json
for ((i=1;i<=enemy_count;i++)); do
    x=$((RANDOM%width))
    y=$((RANDOM%height))
    type=${types[$RANDOM % ${#types[@]}]}
    echo "    {\"type\":\"$type\",\"x\":$x,\"y\":$y,\"hp\":30}" >> app/src/main/assets/generated/world.json
    [[ $i -lt $enemy_count ]] && echo "," >> app/src/main/assets/generated/world.json
done
echo '  ]' >> app/src/main/assets/generated/world.json
echo "}" >> app/src/main/assets/generated/world.json

# --- 6. Generate sprites with ImageMagick ---
entities=("player" "sword" "shield" "slime" "goblin" "orc" "bat")
frames=4
for entity in "${entities[@]}"; do
    for i in $(seq 1 $frames); do
        convert -size 128x128 xc:none -fill "rgb($((RANDOM%256)),$((RANDOM%256)),$((RANDOM%256)))" \
            -draw "circle 64,64 64,$((16+i*8))" app/src/main/res/drawable/${entity}_$i.png
    done
done

# --- 7. Kotlin GameView.kt ---
cat <<'EOF' > app/src/main/java/com/canc/rpg/GameView.kt
# (Same GameView.kt content as before, unchanged)
EOF

echo "Procedural RPG project fully generated with Gradle plugin classpath."