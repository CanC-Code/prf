#!/bin/bash
set -e

echo "/// Credit: CCVO - Procedural RPG Workflow Generator Full"

# 1️⃣ Create project structure
mkdir -p app/src/main/{assets/generated,res/drawable,res/mipmap-mdpi,res/mipmap-hdpi,res/mipmap-xhdpi,res/mipmap-xxhdpi,res/mipmap-xxxhdpi,java/com/canc/rpg,cpp}
mkdir -p gradle/wrapper

# 2️⃣ Create build.gradle files with namespace and plugin
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
        debug { debuggable true }
    }
}

dependencies {}
EOL

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

echo 'rootProject.name = "InfiniteRPG"
include(":app")' > settings.gradle

echo 'org.gradle.jvmargs=-Xmx1536m' > gradle.properties

# 3️⃣ Generate AndroidManifest.xml
cat <<EOL > app/src/main/AndroidManifest.xml
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.canc.rpg">

    <application
        android:label="Infinite RPG"
        android:icon="@mipmap/ic_launcher"
        android:roundIcon="@mipmap/ic_launcher_round"
        android:allowBackup="true"
        android:supportsRtl="true"
        android:theme="@style/Theme.AppCompat.Light.NoActionBar">
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

# 4️⃣ Generate default launcher icons
for size in mdpi hdpi xhdpi xxhdpi xxxhdpi; do
    convert -size 48x48 xc:blue -fill yellow -draw "circle 24,24 24,4" app/src/main/res/mipmap-$size/ic_launcher.png
    convert -size 48x48 xc:green -fill red -draw "circle 24,24 24,4" app/src/main/res/mipmap-$size/ic_launcher_round.png
done

# 5️⃣ Generate Gradle wrapper
echo "Generating Gradle wrapper..."
gradle wrapper --gradle-version 9.2.1
chmod +x ./gradlew

# 6️⃣ Generate procedural world
width=$((RANDOM%8+10))
height=$((RANDOM%8+10))
world_file=app/src/main/assets/generated/world.json

echo "{" > $world_file
echo '  "tiles": [' >> $world_file
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
    echo "    $row" >> $world_file
    [[ $y -lt $((height-1)) ]] && echo "," >> $world_file
done
echo '  ],' >> $world_file

# NPCs
npc_count=$((RANDOM%5+3))
echo '  "npcs": [' >> $world_file
for ((i=1;i<=npc_count;i++)); do
    x=$((RANDOM%width))
    y=$((RANDOM%height))
    echo "    {\"name\":\"Villager$i\",\"x\":$x,\"y\":$y,\"dialog\":\"Hello!\"}" >> $world_file
    [[ $i -lt $npc_count ]] && echo "," >> $world_file
done
echo '  ],' >> $world_file

# Enemies
enemy_count=$((RANDOM%6+3))
types=("Slime" "Goblin" "Orc" "Bat")
echo '  "enemies": [' >> $world_file
for ((i=1;i<=enemy_count;i++)); do
    x=$((RANDOM%width))
    y=$((RANDOM%height))
    type=${types[$RANDOM % ${#types[@]}]}
    echo "    {\"type\":\"$type\",\"x\":$x,\"y\":$y,\"hp\":30}" >> $world_file
    [[ $i -lt $enemy_count ]] && echo "," >> $world_file
done
echo '  ]' >> $world_file
echo "}" >> $world_file

# 7️⃣ Generate sprites using ImageMagick
entities=("player" "sword" "shield" "slime" "goblin" "orc" "bat")
frames=4
for entity in "${entities[@]}"; do
    for i in $(seq 1 $frames); do
        convert -size 128x128 xc:none -fill "rgb($((RANDOM%256)),$((RANDOM%256)),$((RANDOM%256)))" \
            -draw "circle 64,64 64,$((16+i*8))" app/src/main/res/drawable/${entity}_$i.png
    done
done

# 8️⃣ Build APK
echo "Building debug APK..."
./gradlew clean assembleDebug --stacktrace

echo "✅ Build finished. APK is in app/build/outputs/apk/debug/"