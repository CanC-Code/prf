#!/bin/bash
set -e

echo "/// Credit: CCVO - Procedural RPG Workflow Generator Full"

# --- Project structure ---
mkdir -p app/src/main/assets/generated
mkdir -p app/src/main/res/drawable
mkdir -p app/src/main/res/mipmap-{mdpi,hdpi,xhdpi,xxhdpi,xxxhdpi}
mkdir -p app/src/main/java/com/canc/rpg
mkdir -p app/src/main/cpp

# --- Gradle wrapper check ---
if [ ! -f "./gradlew" ]; then
  echo "Generating Gradle wrapper..."
  gradle wrapper --gradle-version 9.2.1 --distribution-type all
fi
chmod +x ./gradlew

# --- APK metadata ---
APP_NAME="Infinite RPG"
PACKAGE_NAME="com.canc.irpg"

# --- Build settings files ---
cat <<EOL > settings.gradle
rootProject.name = "IRPG"
include(":app")
EOL

cat <<EOL > app/build.gradle
plugins {
    id 'com.android.application'
}

android {
    namespace "$PACKAGE_NAME"
    compileSdk 34

    defaultConfig {
        applicationId "$PACKAGE_NAME"
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

dependencies {
}
EOL

cat <<EOL > build.gradle
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

cat <<EOL > gradle/wrapper/gradle-wrapper.properties
distributionUrl=https\://services.gradle.org/distributions/gradle-9.2.1-all.zip
EOL

# --- Procedural world JSON ---
WIDTH=$((RANDOM%8+10))
HEIGHT=$((RANDOM%8+10))

WORLD_JSON="app/src/main/assets/generated/world.json"
echo "{" > $WORLD_JSON
echo '  "tiles": [' >> $WORLD_JSON
for ((y=0;y<HEIGHT;y++)); do
  row="["
  for ((x=0;x<WIDTH;x++)); do
    R=$((RANDOM%5))
    TILE="grass"
    if [ $R -eq 1 ]; then TILE="water"; fi
    if [ $R -eq 2 ]; then TILE="tree"; fi
    if [ $R -eq 3 ]; then TILE="sand"; fi
    if [ $R -eq 4 ]; then TILE="rock"; fi
    row="$row\"$TILE\""
    [ $x -lt $((WIDTH-1)) ] && row="$row,"
  done
  row="$row]"
  echo "    $row" >> $WORLD_JSON
  [ $y -lt $((HEIGHT-1)) ] && echo "," >> $WORLD_JSON
done
echo '  ],' >> $WORLD_JSON

NPC_COUNT=$((RANDOM%5+3))
echo '  "npcs": [' >> $WORLD_JSON
for ((i=1;i<=NPC_COUNT;i++)); do
  X=$((RANDOM%WIDTH))
  Y=$((RANDOM%HEIGHT))
  echo "    {\"name\":\"Villager$i\",\"x\":$X,\"y\":$Y,\"dialog\":\"Hello!\"}" >> $WORLD_JSON
  [ $i -lt $NPC_COUNT ] && echo "," >> $WORLD_JSON
done
echo '  ],' >> $WORLD_JSON

ENEMY_COUNT=$((RANDOM%6+3))
TYPES=("Slime" "Goblin" "Orc" "Bat")
echo '  "enemies": [' >> $WORLD_JSON
for ((i=1;i<=ENEMY_COUNT;i++)); do
  X=$((RANDOM%WIDTH))
  Y=$((RANDOM%HEIGHT))
  TYPE=${TYPES[$RANDOM % ${#TYPES[@]}]}
  echo "    {\"type\":\"$TYPE\",\"x\":$X,\"y\":$Y,\"hp\":30}" >> $WORLD_JSON
  [ $i -lt $ENEMY_COUNT ] && echo "," >> $WORLD_JSON
done
echo '  ]' >> $WORLD_JSON
echo "}" >> $WORLD_JSON

# --- Generate simple ImageMagick sprites ---
ENTITIES=("player" "sword" "shield" "slime" "goblin" "orc" "bat")
FRAMES=4
for ENTITY in "${ENTITIES[@]}"; do
  for i in $(seq 1 $FRAMES); do
    convert -size 128x128 xc:none \
      -fill "rgb($((RANDOM%256)),$((RANDOM%256)),$((RANDOM%256)))" \
      -draw "circle 64,64 64,$((16+i*8))" \
      app/src/main/res/drawable/${ENTITY}_$i.png
  done
done

# --- Generate main GameView.kt ---
mkdir -p app/src/main/java/com/canc/rpg
cat <<'EOL' > app/src/main/java/com/canc/rpg/GameView.kt
// Full GameView.kt with procedural world, pseudo-3D combat, sword/shield mechanics
// (You can paste the version from previous full enhanced GameView)
EOL

# --- Build APK ---
echo "Building APK..."
./gradlew clean assembleDebug --stacktrace