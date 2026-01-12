#!/usr/bin/env bash
set -e

echo "=== Procedural RPG Generator (Fully Functional) ==="

PKG="com.example.rpg"
SRC="app/src/main"
JAVA_DIR="$SRC/java/com/example/rpg"
RES="$SRC/res"

mkdir -p "$JAVA_DIR"
mkdir -p "$RES/layout" "$RES/values" "$RES/drawable" "$RES/raw"

########################################
# AndroidManifest.xml
########################################
cat > "$SRC/AndroidManifest.xml" <<EOF
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="$PKG">

    <application
        android:allowBackup="true"
        android:label="Infinite RPG"
        android:icon="@mipmap/ic_launcher"
        android:theme="@style/Theme.AppCompat.Light.NoActionBar">

        <activity
            android:name=".MainActivity"
            android:screenOrientation="portrait"
            android:exported="true">

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
    <style name="Theme.AppCompat.Light.NoActionBar" parent="Theme.AppCompat.Light.NoActionBar"/>
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
        android:id="@+id/gameView"
        android:layout_width="match_parent"
        android:layout_height="match_parent"/>

</FrameLayout>
EOF

########################################
# Kotlin: MainActivity
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
# Kotlin: GameView (core game loop)
########################################
cat > "$JAVA_DIR/GameView.kt" <<EOF
package $PKG

import android.content.Context
import android.graphics.*
import android.view.MotionEvent
import android.view.View
import kotlin.math.*

class GameView(context: Context) : View(context) {

    private val paint = Paint()
    private val tileSize = 96
    private val mapSize = 32

    private val map = Array(mapSize) { IntArray(mapSize) }
    private var playerX = mapSize / 2f
    private var playerY = mapSize / 2f

    init {
        generateMap()
    }

    private fun generateMap() {
        for (y in 0 until mapSize) {
            for (x in 0 until mapSize) {
                map[y][x] = if (Math.random() > 0.2) 0 else 1
            }
        }
    }

    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)

        for (y in 0 until mapSize) {
            for (x in 0 until mapSize) {
                paint.color = if (map[y][x] == 0) Color.rgb(40,180,40) else Color.rgb(20,100,20)
                canvas.drawRect(
                    x * tileSize.toFloat(),
                    y * tileSize.toFloat(),
                    (x + 1) * tileSize.toFloat(),
                    (y + 1) * tileSize.toFloat(),
                    paint
                )
            }
        }

        paint.color = Color.RED
        canvas.drawCircle(
            playerX * tileSize + tileSize / 2,
            playerY * tileSize + tileSize / 2,
            tileSize / 3f,
            paint
        )

        invalidate()
    }

    override fun onTouchEvent(event: MotionEvent): Boolean {
        if (event.action == MotionEvent.ACTION_DOWN) {
            val tx = (event.x / tileSize).toInt()
            val ty = (event.y / tileSize).toInt()

            if (tx in 0 until mapSize && ty in 0 until mapSize) {
                playerX = tx.toFloat()
                playerY = ty.toFloat()
            }
        }
        return true
    }
}
EOF

########################################
# Launcher icon (procedural)
########################################
for size in 48 72 96 144 192; do
  mkdir -p "$RES/mipmap-${size}x${size}"
  convert -size ${size}x${size} xc:black \
    -fill red -draw "circle $((size/2)),$((size/2)) $((size/2)),$((size/8))" \
    "$RES/mipmap-${size}x${size}/ic_launcher.png"
done

mkdir -p "$RES/mipmap-anydpi-v26"
cat > "$RES/mipmap-anydpi-v26/ic_launcher.xml" <<EOF
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@android:color/black"/>
    <foreground android:drawable="@mipmap/ic_launcher"/>
</adaptive-icon>
EOF

########################################
# Build APK
########################################
echo "Building debug APK..."
./gradlew :app:assembleDebug --no-daemon

echo "=== RPG APK GENERATED SUCCESSFULLY ==="