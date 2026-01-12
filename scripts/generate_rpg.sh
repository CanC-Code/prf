#!/bin/bash
set -e

echo "/// Credit: CCVO - Procedural RPG Workflow Generator Full"

# 0️⃣ Generate AndroidManifest.xml (without package)
mkdir -p app/src/main
cat <<'EOL' > app/src/main/AndroidManifest.xml
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <application
        android:allowBackup="true"
        android:label="InfiniteRPG"
        android:icon="@mipmap/ic_launcher"
        android:roundIcon="@mipmap/ic_launcher_round"
        android:supportsRtl="true"
        android:theme="@style/Theme.AppCompat.Light.NoActionBar">
        <activity android:name=".MainActivity"
            android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
    </application>

</manifest>
EOL

# 1️⃣ Create project structure
mkdir -p app/src/main/{assets/generated,res/drawable,res/values,res/mipmap-mdpi,res/mipmap-hdpi,res/mipmap-xhdpi,res/mipmap-xxhdpi,res/mipmap-xxxhdpi,java/com/canc/rpg,cpp}
mkdir -p gradle/wrapper

# 2️⃣ Generate placeholder launcher icons
for size in mdpi hdpi xhdpi xxhdpi xxxhdpi; do
    convert -size 48x48 xc:blue app/src/main/res/mipmap-$size/ic_launcher.png
    convert -size 48x48 xc:green app/src/main/res/mipmap-$size/ic_launcher_round.png
done

# 3️⃣ Generate styles.xml
cat <<'EOL' > app/src/main/res/values/styles.xml
<resources>
    <style name="Theme.AppCompat.Light.NoActionBar" parent="Theme.AppCompat.Light.NoActionBar">
        <!-- Placeholder theme -->
    </style>
</resources>
EOL

# 4️⃣ Create build.gradle files
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

    compileOptions {
        sourceCompatibility JavaVersion.VERSION_17
        targetCompatibility JavaVersion.VERSION_17
    }
}

repositories {
    google()
    mavenCentral()
}

dependencies {
    implementation 'androidx.appcompat:appcompat:1.6.1'
}
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

# 4️⃣a Generate gradle.properties with AndroidX enabled
cat <<'EOL' > gradle.properties
org.gradle.jvmargs=-Xmx1536m
android.useAndroidX=true
android.enableJetifier=true
EOL

# 5️⃣ Generate Gradle wrapper
echo "Generating Gradle wrapper..."
gradle wrapper --gradle-version 9.2.1
chmod +x ./gradlew

# 6️⃣ Generate procedural world JSON
width=$((RANDOM%8+10))
height=$((RANDOM%8+10))
world_file=app/src/main/assets/generated/world.json

mkdir -p app/src/main/assets/generated
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

npc_count=$((RANDOM%5+3))
echo '  "npcs": [' >> $world_file
for ((i=1;i<=npc_count;i++)); do
    x=$((RANDOM%width))
    y=$((RANDOM%height))
    echo "    {\"name\":\"Villager$i\",\"x\":$x,\"y\":$y,\"dialog\":\"Hello!\"}" >> $world_file
    [[ $i -lt $npc_count ]] && echo "," >> $world_file
done
echo '  ],' >> $world_file

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

# 7️⃣ Generate placeholder sprites
entities=("player" "slime" "goblin" "orc" "bat")
for entity in "${entities[@]}"; do
    convert -size 128x128 xc:none -fill "rgb($((RANDOM%256)),$((RANDOM%256)),$((RANDOM%256)))" \
        -draw "circle 64,64 64,16" app/src/main/res/drawable/${entity}_1.png
done

# 8️⃣ Generate Java classes
mkdir -p app/src/main/java/com/canc/rpg

cat <<'EOL' > app/src/main/java/com/canc/rpg/Player.java
package com.canc.rpg;
import android.graphics.Bitmap;
public class Player {
    public int x, y;
    public Bitmap sprite;
    public Player(int x, int y, Bitmap sprite){ this.x=x; this.y=y; this.sprite=sprite; }
}
EOL

cat <<'EOL' > app/src/main/java/com/canc/rpg/Entity.java
package com.canc.rpg;
import android.graphics.Bitmap;
public class Entity {
    public int x, y;
    public Bitmap sprite;
    public Entity(int x, int y, Bitmap sprite){ this.x=x; this.y=y; this.sprite=sprite; }
}
EOL

cat <<'EOL' > app/src/main/java/com/canc/rpg/MainActivity.java
package com.canc.rpg;
import android.os.Bundle;
import androidx.appcompat.app.AppCompatActivity;
public class MainActivity extends AppCompatActivity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        GameView gameView = new GameView(this);
        setContentView(gameView);
    }
}
EOL

# 9️⃣ Generate GameView.java (placeholder)
cat <<'EOL' > app/src/main/java/com/canc/rpg/GameView.java
package com.canc.rpg;
import android.content.Context;
import android.graphics.Canvas;
import android.graphics.Paint;
import android.view.View;

public class GameView extends View {
    Paint paint = new Paint();
    public GameView(Context context){ super(context); }
    @Override
    protected void onDraw(Canvas canvas){
        super.onDraw(canvas);
        canvas.drawColor(0xFFAAAAAA); // Placeholder gray background
    }
}
EOL

# 🔟 Build APK
echo "Building debug APK..."
./gradlew clean assembleDebug --stacktrace

echo "✅ Build finished. APK is in app/build/outputs/apk/debug/"