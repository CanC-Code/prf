#!/usr/bin/env bash
set -e

echo "=== Procedural RPG Generator (AndroidX + Namespace Correct) ==="

PKG="com.example.rpg"
SRC="app/src/main"
JAVA_DIR="$SRC/java/com/example/rpg"
RES="$SRC/res"

########################################
# Ensure base directories
########################################
mkdir -p "$JAVA_DIR"
mkdir -p "$RES/layout" "$RES/values" "$RES/drawable" "$RES/raw"
mkdir -p "$RES/mipmap-anydpi-v26"

########################################
# gradle.properties (AndroidX REQUIRED)
########################################
cat > gradle.properties <<EOF
org.gradle.jvmargs=-Xmx2048m
android.useAndroidX=true
android.enableJetifier=true
EOF

########################################
# settings.gradle
########################################
cat > settings.gradle <<EOF
rootProject.name = "InfiniteRPG"
include(":app")
EOF

########################################
# Root build.gradle
########################################
cat > build.gradle <<EOF
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath "com.android.tools.build:gradle:8.3.0"
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}
EOF

########################################
# app/build.gradle (namespace FIXED)
########################################
mkdir -p app
cat > app/build.gradle <<EOF
plugins {
    id "com.android.application"
}

android {
    namespace "$PKG"
    compileSdk 34

    defaultConfig {
        applicationId "$PKG"
        minSdk 24
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
    implementation "androidx.appcompat:appcompat:1.6.1"
    implementation "com.google.android.material:material:1.9.0"
}
EOF

########################################
# AndroidManifest.xml
########################################
cat > "$SRC/AndroidManifest.xml" <<EOF
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="$PKG">

    <application
        android:label="Infinite RPG"
        android:icon="@mipmap/ic_launcher"
        android:theme="@style/Theme.AppCompat.Light.NoActionBar">

        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:screenOrientation="portrait">

            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>

        </activity>
    </application>
</manifest>
EOF

########################################
# styles.xml
########################################
cat > "$RES/values/styles.xml" <<EOF
<resources>
    <style name="Theme.AppCompat.Light.NoActionBar"
        parent="Theme.AppCompat.Light.NoActionBar"/>
</resources>
EOF

########################################
# activity_main.xml
########################################
cat > "$RES/layout/activity_main.xml" <<EOF
<FrameLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent">

    <com.example.rpg.GameView
        android:layout_width="match_parent"
        android:layout_height="match_parent"/>

</FrameLayout>
EOF

########################################
# MainActivity.kt
########################################
cat > "$JAVA_DIR/MainActivity.kt" <<EOF
package $PKG

import android.app.Activity
import android.os.Bundle

class MainActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)
    }
}
EOF

########################################
# GameView.kt (real game loop)
########################################
cat > "$JAVA_DIR/GameView.kt" <<EOF
package $PKG

import android.content.Context
import android.graphics.*
import android.view.MotionEvent
import android.view.View

class GameView(context: Context) : View(context) {

    private val paint = Paint()
    private val tileSize = 96
    private val mapSize = 32
    private val map = Array(mapSize) { IntArray(mapSize) }

    private var playerX = mapSize / 2
    private var playerY = mapSize / 2

    init {
        for (y in 0 until mapSize) {
            for (x in 0 until mapSize) {
                map[y][x] = if (Math.random() > 0.25) 0 else 1
            }
        }
    }

    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)

        for (y in 0 until mapSize) {
            for (x in 0 until mapSize) {
                paint.color =
                    if (map[y][x] == 0) Color.rgb(40, 180, 40)
                    else Color.rgb(20, 100, 20)

                canvas.drawRect(
                    (x * tileSize).toFloat(),
                    (y * tileSize).toFloat(),
                    ((x + 1) * tileSize).toFloat(),
                    ((y + 1) * tileSize).toFloat(),
                    paint
                )
            }
        }

        paint.color = Color.RED
        canvas.drawCircle(
            playerX * tileSize + tileSize / 2f,
            playerY * tileSize + tileSize / 2f,
            tileSize / 3f,
            paint
        )

        invalidate()
    }

    override fun onTouchEvent(event: MotionEvent): Boolean {
        if (event.action == MotionEvent.ACTION_DOWN) {
            playerX = (event.x / tileSize).toInt().coerceIn(0, mapSize - 1)
            playerY = (event.y / tileSize).toInt().coerceIn(0, mapSize - 1)
        }
        return true
    }
}
EOF

########################################
# Launcher icons (procedural, valid)
########################################
for size in 48 72 96 144 192; do
  mkdir -p "$RES/mipmap-${size}x${size}"
  convert -size ${size}x${size} xc:black \
    -fill red -draw "circle $((size/2)),$((size/2)) $((size/2)),$((size/6))" \
    "$RES/mipmap-${size}x${size}/ic_launcher.png"
done

cat > "$RES/mipmap-anydpi-v26/ic_launcher.xml" <<EOF
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@android:color/black"/>
    <foreground android:drawable="@mipmap/ic_launcher"/>
</adaptive-icon>
EOF

########################################
# Ensure Gradle wrapper
########################################
if [ ! -f ./gradlew ]; then
  gradle wrapper --gradle-version 9.2.1
  chmod +x gradlew
fi

########################################
# Build APK
########################################
echo "Building debug APK..."
./gradlew :app:assembleDebug --no-daemon

echo "=== SUCCESS: REAL RPG APK BUILT ==="