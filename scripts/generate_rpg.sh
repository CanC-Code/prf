#!/bin/bash
set -e
echo "/// Credit: CCVO - Procedural RPG Workflow Generator Enhanced"

# -----------------------------
# Create project structure
# -----------------------------
echo "[*] Creating project folders..."
mkdir -p app/src/main/assets/generated
mkdir -p app/src/main/res/drawable
mkdir -p app/src/main/res/mipmap-{mdpi,hdpi,xhdpi,xxhdpi,xxxhdpi}
mkdir -p app/src/main/java/com/canc/rpg
mkdir -p app/src/main/cpp

# -----------------------------
# Create Gradle files
# -----------------------------
echo "[*] Generating Gradle files..."
cat > app/build.gradle <<'EOL'
apply plugin: "com.android.application"

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
        debug { debuggable true }
    }
}

dependencies {}
EOL

cat > settings.gradle <<'EOL'
rootProject.name = "ProceduralRPG"
include(":app")
EOL

cat > build.gradle <<'EOL'
buildscript {
    repositories { google(); mavenCentral() }
    dependencies { classpath "com.android.tools.build:gradle:8.2.0" }
}
EOL

mkdir -p gradle/wrapper
cat > gradle/wrapper/gradle-wrapper.properties <<EOL
distributionUrl=https\://services.gradle.org/distributions/gradle-8.2-all.zip
EOL

# -----------------------------
# Generate procedural world JSON
# -----------------------------
echo "[*] Generating procedural world..."
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

# -----------------------------
# Generate stylized pseudo-3D sprites
# -----------------------------
echo "[*] Generating sprites with ImageMagick..."
entities=("player" "sword" "shield" "slime" "goblin" "orc" "bat")
frames=6

for entity in "${entities[@]}"; do
  for i in $(seq 1 $frames); do
    file="app/src/main/res/drawable/${entity}_$i.png"
    case $entity in
      player)
        convert -size 128x128 xc:none \
          -fill "radial-gradient(rgb($((RANDOM%200+55)),$((RANDOM%200+55)),$((RANDOM%200+55))),black)" \
          -draw "circle 64,64 64,$((16+i*5))" "$file"
        ;;
      sword)
        convert -size 128x128 xc:none \
          -fill "gray" -draw "rectangle 60,10 68,110" \
          -fill "silver" -draw "polygon 56,10 72,10 64,0" "$file"
        ;;
      shield)
        convert -size 128x128 xc:none \
          -fill "cyan" -draw "circle 64,64 64,$((10+i*5))" "$file"
        ;;
      slime)
        convert -size 128x128 xc:none \
          -fill "limegreen" -draw "circle 64,64 64,$((10+i*4))" "$file"
        ;;
      goblin)
        convert -size 128x128 xc:none \
          -fill "green" -draw "circle 64,64 64,$((16+i*3))" \
          -fill "black" -draw "circle 50,50 50,54" "$file"
        ;;
      orc)
        convert -size 128x128 xc:none \
          -fill "darkgreen" -draw "circle 64,64 64,$((16+i*3))" \
          -fill "white" -draw "circle 48,50 48,54" "$file"
        ;;
      bat)
        convert -size 128x128 xc:none \
          -fill "darkgray" -draw "polygon 32,64 64,$((16+i*4)) 96,64" \
          -fill "black" -draw "circle 64,64 64,68" "$file"
        ;;
    esac
  done
done

echo "[*] Generating MainActivity and GameView..."
mkdir -p app/src/main/java/com/canc/rpg

# MainActivity.kt
cat > app/src/main/java/com/canc/rpg/MainActivity.kt <<'EOL'
package com.canc.rpg

import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity

class MainActivity : AppCompatActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(GameView(this))
    }
}
EOL

# Minimal activity_main.xml (optional for SurfaceView)
cat > app/src/main/res/layout/activity_main.xml <<'EOL'
<?xml version="1.0" encoding="utf-8"?>
<FrameLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent" />
EOL

# GameView.kt (simplified, reads sprites from drawable)
cat > app/src/main/java/com/canc/rpg/GameView.kt <<'EOL'
package com.canc.rpg
import android.content.Context
import android.graphics.*
import android.view.SurfaceHolder
import android.view.SurfaceView
import android.view.MotionEvent
import org.json.JSONObject
import java.io.InputStream
import kotlin.random.Random

class GameView(context: Context) : SurfaceView(context), SurfaceHolder.Callback, Runnable {
    private var thread: Thread? = null
    private var running = false
    private val paint = Paint()
    private val tileSize = 128
    private lateinit var world: JSONObject
    private var playerX=0; private var playerY=0
    private var playerHP=100; private var playerLevel=1
    private val npcs=mutableListOf<JSONObject>()
    private val enemies=mutableListOf<JSONObject>()
    private var attackCooldown=0; private var shieldActive=false
    private var frameCounter=0

    init { holder.addCallback(this); loadWorld() }
    private fun loadWorld() {
        val stream: InputStream = context.assets.open("generated/world.json")
        val json = stream.bufferedReader().use{it.readText()}
        world = JSONObject(json)
        val npcArray = world.getJSONArray("npcs")
        for(i in 0 until npcArray.length()){ npcs.add(npcArray.getJSONObject(i)) }
        val enemyArray = world.getJSONArray("enemies")
        for(i in 0 until enemyArray.length()){ enemies.add(enemyArray.getJSONObject(i)) }
    }

    override fun surfaceCreated(holder: SurfaceHolder) { running=true; thread=Thread(this); thread?.start() }
    override fun surfaceDestroyed(holder: SurfaceHolder) { running=false; thread?.join() }
    override fun run() {
        while(running){
            if(!holder.surface.isValid) continue
            val canvas=holder.lockCanvas()
            canvas.drawColor(Color.BLACK)
            drawWorld(canvas); drawNPCs(canvas); drawEnemies(canvas); drawPlayer(canvas)
            holder.unlockCanvasAndPost(canvas)
            updateEnemies(); frameCounter=(frameCounter+1)%6; if(attackCooldown>0) attackCooldown--
        }
    }

    private fun drawWorld(canvas: Canvas){
        val tiles = world.getJSONArray("tiles")
        for(y in 0 until tiles.length()){
            val row=tiles.getJSONArray(y)
            for(x in 0 until row.length()){
                val t=row.getString(x)
                paint.color=when(t){"grass"->Color.GREEN;"water"->Color.BLUE;"tree"->Color.DKGRAY;"sand"->Color.YELLOW;"rock"->Color.LTGRAY;else->Color.GRAY}
                canvas.drawRect((x*tileSize).toFloat(),(y*tileSize).toFloat(),((x+1)*tileSize).toFloat(),((y+1)*tileSize).toFloat(),paint)
            }
        }
    }

    private fun drawPlayer(canvas: Canvas){
        paint.color=if(shieldActive) Color.CYAN else Color.YELLOW
        canvas.drawCircle(playerX*tileSize+tileSize/2f,playerY*tileSize+tileSize/2f,tileSize/2f,paint)
    }

    private fun drawNPCs(canvas: Canvas){ paint.color=Color.MAGENTA; for(npc in npcs){ val x=npc.getInt("x"); val y=npc.getInt("y"); canvas.drawRect(x*tileSize.toFloat(),y*tileSize.toFloat(),(x+1)*tileSize.toFloat(),(y+1)*tileSize.toFloat(),paint) } }
    private fun drawEnemies(canvas: Canvas){ paint.color=Color.RED; for(enemy in enemies){ val x=enemy.getInt("x"); val y=enemy.getInt("y"); canvas.drawRect(x*tileSize.toFloat(),y*tileSize.toFloat(),(x+1)*tileSize.toFloat(),(y+1)*tileSize.toFloat(),paint) } }
    private fun updateEnemies(){ for(enemy in enemies){ if(Random.nextBoolean()){ val dx=listOf(-1,0,1).random(); val dy=listOf(-1,0,1).random(); val newX=(enemy.getInt("x")+dx).coerceIn(0, world.getJSONArray("tiles").getJSONArray(0).length()-1); val newY=(enemy.getInt("y")+dy).coerceIn(0, world.getJSONArray("tiles").length()-1); enemy.put("x",newX); enemy.put("y",newY) }; if(Math.abs(enemy.getInt("x")-playerX)<=1 && Math.abs(enemy.getInt("y")-playerY)<=1){ if(!shieldActive) playerHP-=1 } } }
    override fun onTouchEvent(event: MotionEvent): Boolean {
        if(event.action==MotionEvent.ACTION_DOWN){
            val tx=(event.x/tileSize).toInt(); val ty=(event.y/tileSize).toInt()
            val tile=world.getJSONArray("tiles").getJSONArray(ty).getString(tx)
            if(tile!="tree" && tile!="water"){playerX=tx;playerY=ty}
            if(event.x>width-200 && event.y>height-200){attack()} else if(event.x>width-400 && event.y>height-200){shield()}
        }
        return true
    }

    private fun attack(){ if(attackCooldown==0){ for(enemy in enemies){ if(Math.abs(enemy.getInt("x")-playerX)<=1 && Math.abs(enemy.getInt("y")-playerY)<=1){ val hp=enemy.getInt("hp")-10; if(hp<=0) enemies.remove(enemy) else enemy.put("hp",hp); playerLevel++ ; break } }; attackCooldown=20 } }
    private fun shield(){ shieldActive=true; Thread{ Thread.sleep(1000); shieldActive=false }.start() }
}
EOL

echo "[*] RPG project generated successfully."