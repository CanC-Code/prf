#!/usr/bin/env bash
set -e

echo "/// Credit: CCVO - Procedural RPG Workflow Generator Full"
echo "Generating Infinite RPG project..."

# Project variables
APP_NAME="Infinite RPG"
APP_ID="com.canc.irpg"
PROJECT_DIR="$PWD"

# Ensure project directories
mkdir -p app/src/main/java/com/canc/irpg
mkdir -p app/src/main/assets/generated
mkdir -p app/src/main/res/{drawable,mipmap-mdpi,mipmap-hdpi,mipmap-xhdpi,mipmap-xxhdpi,mipmap-xxxhdpi}
mkdir -p app/src/main/cpp
mkdir -p gradle/wrapper

# -----------------------------
# Generate Gradle wrapper files
# -----------------------------
cat <<'EOL' > gradle/wrapper/gradle-wrapper.properties
distributionUrl=https\://services.gradle.org/distributions/gradle-9.2.1-all.zip
EOL

cat <<'EOL' > build.gradle
buildscript {
    repositories { google(); mavenCentral() }
    dependencies { classpath "com.android.tools.build:gradle:8.2.0" }
}
EOL

cat <<EOL > settings.gradle
rootProject.name = "InfiniteRPG"
include(":app")
EOL

cat <<EOL > app/build.gradle
plugins {
    id 'com.android.application'
    id 'kotlin-android'
}

android {
    namespace "$APP_ID"
    compileSdk 34

    defaultConfig {
        applicationId "$APP_ID"
        minSdk 21
        targetSdk 34
        versionCode 1
        versionName "1.0"
    }

    buildTypes {
        debug { debuggable true }
        release { minifyEnabled false }
    }
}

dependencies {
    implementation "org.jetbrains.kotlin:kotlin-stdlib:1.9.0"
}
EOL

cat <<EOL > app/src/main/AndroidManifest.xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="$APP_ID">

    <application
        android:allowBackup="true"
        android:label="$APP_NAME"
        android:icon="@mipmap/ic_launcher"
        android:roundIcon="@mipmap/ic_launcher_round"
        android:supportsRtl="true"
        android:theme="@android:style/Theme.DeviceDefault.Light.NoActionBar">
        <activity android:name=".MainActivity"
            android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
    </application>

</manifest>
EOL

# -----------------------------
# Generate launcher icons
# -----------------------------
echo "Generating procedural launcher icons..."
for size in mdpi hdpi xhdpi xxhdpi xxxhdpi; do
    dim=48
    case $size in
        mdpi) dim=48 ;;
        hdpi) dim=72 ;;
        xhdpi) dim=96 ;;
        xxhdpi) dim=144 ;;
        xxxhdpi) dim=192 ;;
    esac
    convert -size ${dim}x${dim} xc:none \
        -fill "rgb($((RANDOM%256)),$((RANDOM%256)),$((RANDOM%256)))" \
        -draw "circle $((dim/2)),$((dim/2)) $((dim/2)),$((dim/4))" \
        app/src/main/res/mipmap-$size/ic_launcher.png
done

# -----------------------------
# Generate procedural world
# -----------------------------
echo "Generating procedural world JSON..."
width=$((RANDOM%10+10))
height=$((RANDOM%10+10))

WORLD_JSON="app/src/main/assets/generated/world.json"
echo "{" > $WORLD_JSON
echo '  "tiles": [' >> $WORLD_JSON
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
    echo "    $row" >> $WORLD_JSON
    [[ $y -lt $((height-1)) ]] && echo "," >> $WORLD_JSON
done
echo '  ],' >> $WORLD_JSON

# NPCs
npc_count=$((RANDOM%5+3))
echo '  "npcs": [' >> $WORLD_JSON
for ((i=1;i<=npc_count;i++)); do
    x=$((RANDOM%width))
    y=$((RANDOM%height))
    echo "    {\"name\":\"Villager$i\",\"x\":$x,\"y\":$y,\"dialog\":\"Hello!\"}" >> $WORLD_JSON
    [[ $i -lt $npc_count ]] && echo "," >> $WORLD_JSON
done
echo '  ],' >> $WORLD_JSON

# Enemies
enemy_count=$((RANDOM%6+3))
types=("Slime" "Goblin" "Orc" "Bat")
echo '  "enemies": [' >> $WORLD_JSON
for ((i=1;i<=enemy_count;i++)); do
    x=$((RANDOM%width))
    y=$((RANDOM%height))
    type=${types[$RANDOM % ${#types[@]}]}
    echo "    {\"type\":\"$type\",\"x\":$x,\"y\":$y,\"hp\":30}" >> $WORLD_JSON
    [[ $i -lt $enemy_count ]] && echo "," >> $WORLD_JSON
done
echo '  ]' >> $WORLD_JSON
echo "}" >> $WORLD_JSON

# -----------------------------
# Generate pseudo-3D sprites
# -----------------------------
echo "Generating procedural pseudo-3D sprites..."
entities=("player" "sword" "shield" "slime" "goblin" "orc" "bat")
frames=4
for entity in "${entities[@]}"; do
    for i in $(seq 1 $frames); do
        convert -size 128x128 xc:none \
            -fill "rgb($((RANDOM%256)),$((RANDOM%256)),$((RANDOM%256)))" \
            -draw "circle 64,64 64,$((16+i*8))" \
            app/src/main/res/drawable/${entity}_$i.png
    done
done

echo "Project generation complete!"