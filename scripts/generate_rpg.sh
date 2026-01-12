#!/usr/bin/env bash
set -e

echo "/// Credit: CCVO - Procedural RPG Workflow Generator Full"

# -----------------------------
# Prepare project structure
# -----------------------------
mkdir -p app/src/main/assets/generated
mkdir -p app/src/main/res/drawable
mkdir -p app/src/main/res/mipmap-mdpi
mkdir -p app/src/main/res/mipmap-hdpi
mkdir -p app/src/main/res/mipmap-xhdpi
mkdir -p app/src/main/res/mipmap-xxhdpi
mkdir -p app/src/main/res/mipmap-xxxhdpi
mkdir -p app/src/main/java/com/canc/rpg
mkdir -p app/src/main/cpp

# -----------------------------
# Gradle wrapper & project files
# -----------------------------
cat <<'EOL' > build.gradle
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath "com.android.tools.build:gradle:8.2.0"
    }
}
EOL

cat <<'EOL' > settings.gradle
rootProject.name = "InfiniteRPG"
include(":app")
EOL

cat <<'EOL' > app/build.gradle
plugins {
    id 'com.android.application'
}

android {
    namespace "com.canc.rpg"
    compileSdk 34
    defaultConfig {
        applicationId "com.canc.rpg"
        minSdk 21
        targetSdk 34
        versionCode 1
        versionName "1.0"
    }
    buildTypes {
        debug {
            debuggable true
        }
    }
}

dependencies {}
EOL

mkdir -p gradle/wrapper
cat <<'EOL' > gradle/wrapper/gradle-wrapper.properties
distributionUrl=https\://services.gradle.org/distributions/gradle-9.2.1-all.zip
EOL

# -----------------------------
# Create Gradle wrapper script
# -----------------------------
cat <<'EOL' > gradlew
#!/usr/bin/env bash
DIR="$(cd "$(dirname "$0")" && pwd)"
java -jar "$DIR/gradle/wrapper/gradle-wrapper.jar" "$@"
EOL
chmod +x gradlew

# Download valid gradle-wrapper.jar
curl -L https://services.gradle.org/distributions/gradle-9.2.1-bin.zip -o gradle.zip
unzip -o gradle.zip "gradle-9.2.1/lib/gradle-wrapper.jar" -d gradle/wrapper/
rm gradle.zip

# -----------------------------
# Procedural world JSON
# -----------------------------
width=$((RANDOM%8+10))
height=$((RANDOM%8+10))
echo "{" > app/src/main/assets/generated/world.json
echo '  "tiles": [' >> app/src/main/assets/generated/world.json
for ((y=0;y<height;y++)); do
    row="["
    for ((x=0;x<width;x++)); do
        r=$((RANDOM%5))
        tile="grass"
        if [ $r -eq 1 ]; then tile="water"; fi
        if [ $r -eq 2 ]; then tile="tree"; fi
        if [ $r -eq 3 ]; then tile="sand"; fi
        if [ $r -eq 4 ]; then tile="rock"; fi
        row="$row\"$tile\""
        if [ $x -lt $((width-1)) ]; then row="$row,"; fi
    done
    row="$row]"
    echo "    $row" >> app/src/main/assets/generated/world.json
    if [ $y -lt $((height-1)) ]; then echo "," >> app/src/main/assets/generated/world.json; fi
done
echo '  ],' >> app/src/main/assets/generated/world.json

npc_count=$((RANDOM%5+3))
echo '  "npcs": [' >> app/src/main/assets/generated/world.json
for ((i=1;i<=npc_count;i++)); do
    x=$((RANDOM%width))
    y=$((RANDOM%height))
    echo "    {\"name\":\"Villager$i\",\"x\":$x,\"y\":$y,\"dialog\":\"Hello!\"}" >> app/src/main/assets/generated/world.json
    if [ $i -lt $npc_count ]; then echo "," >> app/src/main/assets/generated/world.json; fi
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
    if [ $i -lt $enemy_count ]; then echo "," >> app/src/main/assets/generated/world.json; fi
done
echo '  ]' >> app/src/main/assets/generated/world.json
echo "}" >> app/src/main/assets/generated/world.json

# -----------------------------
# Generate simple ImageMagick sprites
# -----------------------------
entities=("player" "sword" "shield" "slime" "goblin" "orc" "bat")
frames=4
for entity in "${entities[@]}"; do
    for i in $(seq 1 $frames); do
        convert -size 128x128 xc:none -fill "rgb($((RANDOM%256)),$((RANDOM%256)),$((RANDOM%256)))" \
            -draw "circle 64,64 64,$((16+i*8))" \
            app/src/main/res/drawable/${entity}_$i.png
    done
done

echo "Procedural assets, Gradle wrapper, and sprites created successfully!"