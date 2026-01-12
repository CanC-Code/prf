#!/usr/bin/env bash
set -e

echo "=== Generating Android Project Shell ==="

PKG="com.example.rpg"
SRC="app/src/main"
JAVA_DIR="$SRC/java/com/example/rpg"
RES="$SRC/res"

# Ensure required directories exist
mkdir -p "$JAVA_DIR"
mkdir -p "$RES/layout" "$RES/values"
mkdir -p "$RES/mipmap-48x48" "$RES/mipmap-72x72" "$RES/mipmap-96x96" "$RES/mipmap-144x144" "$RES/mipmap-192x192" "$RES/mipmap-anydpi-v26"

########################################
# AndroidManifest.xml
########################################
cat > "$SRC/AndroidManifest.xml" <<EOF
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="$PKG">

    <application
        android:label="Infinite RPG"
        android:icon="@mipmap/ic_launcher"
        android:theme="@style/Theme.App">

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
# styles.xml (AppCompat-safe)
########################################
cat > "$RES/values/styles.xml" <<EOF
<resources>
    <style name="Theme.App" parent="Theme.AppCompat.Light.NoActionBar"/>
</resources>
EOF

########################################
# activity_main.xml
########################################
cat > "$RES/layout/activity_main.xml" <<EOF
<FrameLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:id="@+id/root"
    android:layout_width="match_parent"
    android:layout_height="match_parent"/>
EOF

########################################
# MainActivity.kt (minimal placeholder)
########################################
cat > "$JAVA_DIR/MainActivity.kt" <<EOF
package $PKG

import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity

class MainActivity : AppCompatActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)
    }
}
EOF

echo "=== Android Project Shell Generated ==="