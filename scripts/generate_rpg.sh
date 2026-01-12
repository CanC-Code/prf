#!/usr/bin/env bash
set -e

echo "/// Credit: CCVO - Procedural RPG Workflow Generator Script"

# Ensure minimal project structure
mkdir -p app/src/main/assets/generated
mkdir -p app/src/main/res/drawable
mkdir -p app/src/main/java/com/canc/rpg
mkdir -p app/src/main/cpp

# Gradle wrapper
if [ ! -f gradlew ]; then
  echo "Creating minimal gradle wrapper..."
  mkdir -p gradle/wrapper
  curl -sL https://services.gradle.org/distributions/gradle-8.2-bin.zip -o gradle-8.2-bin.zip
  unzip -q gradle-8.2-bin.zip -d gradle_tmp
  mv gradle_tmp/gradle-8.2/* gradle/
  rm -rf gradle_tmp gradle-8.2-bin.zip
  echo "distributionUrl=https\://services.gradle.org/distributions/gradle-8.2-all.zip" > gradle/wrapper/gradle-wrapper.properties
fi

# Minimal build.gradle
cat > app/build.gradle <<'EOF'
apply plugin: 'com.android.application'

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
EOF

# Minimal root gradle files
cat > settings.gradle <<'EOF'
rootProject.name = "ProceduralRPG"
include(":app")
EOF

cat > build.gradle <<'EOF'
buildscript {
    repositories { google(); mavenCentral() }
    dependencies { classpath "com.android.tools.build:gradle:8.2.0" }
}
EOF

# Generate procedural world JSON
width=$((RANDOM%10+10))
height=$((RANDOM%10+10))

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

# NPCs
npc_count=$((RANDOM%5+3))
echo '  "npcs": [' >> app/src/main/assets/generated/world.json
for ((i=1;i<=npc_count;i++)); do
    x=$((RANDOM%width))
    y=$((RANDOM%height))
    echo "    {\"name\":\"Villager$i\",\"x\":$x,\"y\":$y,\"dialog\":\"Hello!\"}" >> app/src/main/assets/generated/world.json
    [[ $i -lt $npc_count ]] && echo "," >> app/src/main/assets/generated/world.json
done
echo '  ],' >> app/src/main/assets/generated/world.json

# Enemies
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

# Generate pseudo-3D animated sprites
entities=("player" "sword" "shield" "slime" "goblin" "orc" "bat")
frames=4
for entity in "${entities[@]}"; do
    for i in $(seq 1 $frames); do
        convert -size 128x128 xc:none -fill "rgb($((RANDOM%256)),$((RANDOM%256)),$((RANDOM%256)))" \
            -draw "circle 64,64 64,$((16+i*8))" \
            app/src/main/res/drawable/${entity}_$i.png
    done
done

# Write GameView.kt
cat > app/src/main/java/com/canc/rpg/GameView.kt <<'EOF'
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
    private var playerX = 0
    private var playerY = 0
    private var playerHP = 100
    private var playerLevel = 1
    private val npcs = mutableListOf<JSONObject>()
    private val enemies = mutableListOf<JSONObject>()
    private var attackCooldown = 0
    private var shieldActive = false
    private var frameCounter = 0

    init {
        holder.addCallback(this)
        loadWorld()
    }

    private fun loadWorld() {
        val stream: InputStream = context.assets.open("generated/world.json")
        val json = stream.bufferedReader().use { it.readText() }
        world = JSONObject(json)
        val npcArray = world.getJSONArray("npcs")
        for(i in 0 until npcArray.length()){ npcs.add(npcArray.getJSONObject(i)) }
        val enemyArray = world.getJSONArray("enemies")
        for(i in 0 until enemyArray.length()){ enemies.add(enemyArray.getJSONObject(i)) }
    }

    override fun surfaceCreated(holder: SurfaceHolder) {
        running = true
        thread = Thread(this)
        thread?.start()
    }

    override fun surfaceDestroyed(holder: SurfaceHolder) {
        running = false
        thread?.join()
    }

    override fun run() {
        while(running){
            if(!holder.surface.isValid) continue
            val canvas = holder.lockCanvas()
            canvas.drawColor(Color.BLACK)
            drawWorld(canvas)
            drawNPCs(canvas)
            drawEnemies(canvas)
            drawPlayer(canvas)
            holder.unlockCanvasAndPost(canvas)
            updateEnemies()
            frameCounter = (frameCounter+1)%4
            if(attackCooldown>0) attackCooldown--
        }
    }

    private fun drawWorld(canvas: Canvas){
        val tiles = world.getJSONArray("tiles")
        for(y in 0 until tiles.length()){
            val row = tiles.getJSONArray(y)
            for(x in 0 until row.length()){
                val t = row.getString(x)
                paint.color = when(t){
                    "grass" -> Color.GREEN
                    "water" -> Color.BLUE
                    "tree" -> Color.DKGRAY
                    "sand" -> Color.YELLOW
                    "rock" -> Color.LTGRAY
                    else -> Color.GRAY
                }
                canvas.drawRect((x*tileSize).toFloat(), (y*tileSize).toFloat(),
                    ((x+1)*tileSize).toFloat(), ((y+1)*tileSize).toFloat(), paint)
            }
        }
    }

    private fun drawPlayer(canvas: Canvas){
        paint.color = if(shieldActive) Color.CYAN else Color.YELLOW
        canvas.drawCircle(playerX*tileSize + tileSize/2f, playerY*tileSize + tileSize/2f, tileSize/2f, paint)
    }

    private fun drawNPCs(canvas: Canvas){
        paint.color = Color.MAGENTA
        for(npc in npcs){
            val x = npc.getInt("x")
            val y = npc.getInt("y")
            canvas.drawRect(x*tileSize.toFloat(), y*tileSize.toFloat(), (x+1)*tileSize.toFloat(), (y+1)*tileSize.toFloat(), paint)
        }
    }

    private fun drawEnemies(canvas: Canvas){
        paint.color = Color.RED
        for(enemy in enemies){
            val x = enemy.getInt("x")
            val y = enemy.getInt("y")
            canvas.drawRect(x*tileSize.toFloat(), y*tileSize.toFloat(), (x+1)*tileSize.toFloat(), (y+1)*tileSize.toFloat(), paint)
        }
    }

    private fun updateEnemies(){
        for(enemy in enemies){
            if(Random.nextBoolean()){
                val dx = listOf(-1,0,1).random()
                val dy = listOf(-1,0,1).random()
                val newX = (enemy.getInt("x")+dx).coerceIn(0, world.getJSONArray("tiles").getJSONArray(0).length()-1)
                val newY = (enemy.getInt("y")+dy).coerceIn(0, world.getJSONArray("tiles").length()-1)
                enemy.put("x", newX)
                enemy.put("y", newY)
            }
            if(Math.abs(enemy.getInt("x")-playerX)<=1 && Math.abs(enemy.getInt("y")-playerY)<=1){
                if(!shieldActive) playerHP -= 1
            }
        }
    }

    override fun onTouchEvent(event: MotionEvent): Boolean {
        if(event.action == MotionEvent.ACTION_DOWN){
            val tx = (event.x / tileSize).toInt()
            val ty = (event.y / tileSize).toInt()
            val tile = world.getJSONArray("tiles").getJSONArray(ty).getString(tx)
            if(tile != "tree" && tile != "water"){
                playerX = tx
                playerY = ty
            }
        }
        return true
    }
}
EOF

echo "RPG generation script finished."