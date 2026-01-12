#!/bin/bash
set -e

echo "/// Credit: CCVO - Procedural RPG Workflow Generator Full"

# 0️⃣ Generate AndroidManifest.xml
mkdir -p app/src/main
cat <<'EOL' > app/src/main/AndroidManifest.xml
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.canc.rpg">

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

    compileOptions {
        sourceCompatibility JavaVersion.VERSION_17
        targetCompatibility JavaVersion.VERSION_17
    }
}

repositories {
    google()
    mavenCentral()
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

# 3️⃣ Generate Gradle wrapper
echo "Generating Gradle wrapper..."
gradle wrapper --gradle-version 9.2.1

chmod +x ./gradlew

# 4️⃣ Generate procedural world JSON
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

# 5️⃣ Generate sprites
entities=("player" "slime" "goblin" "orc" "bat")
frames=1
for entity in "${entities[@]}"; do
    for i in $(seq 1 $frames); do
        convert -size 128x128 xc:none -fill "rgb($((RANDOM%256)),$((RANDOM%256)),$((RANDOM%256)))" \
            -draw "circle 64,64 64,16" app/src/main/res/drawable/${entity}_$i.png
    done
done

# 6️⃣ Generate Java classes
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

cat <<'EOL' > app/src/main/java/com/canc/rpg/GameView.java
package com.canc.rpg;
import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Canvas;
import android.graphics.Paint;
import android.view.KeyEvent;
import android.view.SurfaceHolder;
import android.view.SurfaceView;
import org.json.JSONArray;
import org.json.JSONObject;
import java.io.InputStream;
import java.util.ArrayList;
public class GameView extends SurfaceView implements SurfaceHolder.Callback, Runnable {
    private Thread thread; private boolean running = true; private Paint paint = new Paint();
    private int tileSize = 128; private String[][] tiles;
    private ArrayList<Entity> npcs = new ArrayList<>();
    private ArrayList<Entity> enemies = new ArrayList<>();
    private Player player;
    public GameView(Context context){
        super(context); getHolder().addCallback(this); loadWorld();
        player = new Player(0,0, BitmapFactory.decodeResource(getResources(), R.drawable.player_1));
        setFocusable(true);
    }
    private void loadWorld(){
        try{
            InputStream is = getContext().getAssets().open("generated/world.json");
            byte[] buffer = new byte[is.available()];
            is.read(buffer); is.close();
            String json = new String(buffer);
            JSONObject obj = new JSONObject(json);
            JSONArray t = obj.getJSONArray("tiles");
            tiles = new String[t.length()][t.getJSONArray(0).length()];
            for(int y=0;y<t.length();y++){
                JSONArray row = t.getJSONArray(y);
                for(int x=0;x<row.length();x++){
                    tiles[y][x] = row.getString(x);
                }
            }
            JSONArray n = obj.getJSONArray("npcs");
            for(int i=0;i<n.length();i++){
                JSONObject e = n.getJSONObject(i);
                npcs.add(new Entity(e.getInt("x"), e.getInt("y"), BitmapFactory.decodeResource(getResources(), R.drawable.slime_1)));
            }
            JSONArray en = obj.getJSONArray("enemies");
            for(int i=0;i<en.length();i++){
                JSONObject e = en.getJSONObject(i);
                enemies.add(new Entity(e.getInt("x"), e.getInt("y"), BitmapFactory.decodeResource(getResources(), R.drawable.slime_1)));
            }
        } catch(Exception e){ e.printStackTrace(); }
    }
    @Override
    public void surfaceCreated(SurfaceHolder holder){ thread = new Thread(this); thread.start(); }
    @Override
    public void run(){
        while(running){
            if(!getHolder().getSurface().isValid()) continue;
            Canvas canvas = getHolder().lockCanvas();
            drawGame(canvas);
            getHolder().unlockCanvasAndPost(canvas);
            try { Thread.sleep(16); } catch(Exception e){}
        }
    }
    private void drawGame(Canvas canvas){
        canvas.drawRGB(0,0,0);
        for(int y=0;y<tiles.length;y++){
            for(int x=0;x<tiles[0].length;x++){
                paint.setColor(getTileColor(tiles[y][x]));
                canvas.drawRect(x*tileSize,y*tileSize,(x+1)*tileSize,(y+1)*tileSize,paint);
            }
        }
        for(Entity e : npcs){ canvas.drawBitmap(e.sprite,e.x*tileSize,e.y*tileSize,null); }
        for(Entity e : enemies){ canvas.drawBitmap(e.sprite,e.x*tileSize,e.y*tileSize,null); }
        canvas.drawBitmap(player.sprite, player.x*tileSize, player.y*tileSize, null);
    }
    private int getTileColor(String tile){
        switch(tile){
            case "grass": return 0xFF00FF00;
            case "water": return 0xFF0000FF;
            case "tree": return 0xFF008000;
            case "sand": return 0xFFFFFF00;
            case "rock": return 0xFF808080;
            default: return 0xFFFFFFFF;
        }
    }
    @Override
    public boolean onKeyDown(int keyCode, KeyEvent event){
        switch(keyCode){
            case KeyEvent.KEYCODE_DPAD_UP: player.y--; break;
            case KeyEvent.KEYCODE_DPAD_DOWN: player.y++; break;
            case KeyEvent.KEYCODE_DPAD_LEFT: player.x--; break;
            case KeyEvent.KEYCODE_DPAD_RIGHT: player.x++; break;
        }
        return true;
    }
    @Override public void surfaceChanged(SurfaceHolder holder, int format, int width, int height){}
    @Override public void surfaceDestroyed(SurfaceHolder holder){ running=false; }
}
EOL

# 7️⃣ Build APK
echo "Building debug APK..."
./gradlew clean assembleDebug --stacktrace

echo "✅ Build finished. APK is in app/build/outputs/apk/debug/"