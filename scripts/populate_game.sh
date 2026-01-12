#!/usr/bin/env bash
set -e

echo "=== Populating Procedural RPG Game Content ==="

PKG="com.example.rpg"
SRC="app/src/main"
JAVA_DIR="$SRC/java/com/example/rpg"

# Ensure Java directory exists
mkdir -p "$JAVA_DIR"

########################################
# GameView.kt (full upgraded version with assets)
########################################
cat > "$JAVA_DIR/GameView.kt" <<'EOF'
package com.example.rpg

import android.content.Context
import android.graphics.*
import android.util.AttributeSet
import android.view.MotionEvent
import android.view.View
import kotlin.math.floor
import kotlin.random.Random

class GameView @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null
) : View(context, attrs) {

    private val paint = Paint(Paint.ANTI_ALIAS_FLAG)
    private val tileSizePx = 96f
    private val mapSize = 24

    private val TERRAIN_GRASS = 0
    private val TERRAIN_FOREST = 1
    private val TERRAIN_WATER = 2

    private val map = Array(mapSize) { IntArray(mapSize) }
    private val chests = mutableListOf<Pair<Int, Int>>()
    private val enemies = mutableListOf<Pair<Int, Int>>()

    private var playerX = mapSize / 2
    private var playerY = mapSize / 2

    private val bmpGrass = BitmapFactory.decodeResource(context.resources, R.drawable.tile_grass)
    private val bmpForest = BitmapFactory.decodeResource(context.resources, R.drawable.tile_forest)
    private val bmpWater = BitmapFactory.decodeResource(context.resources, R.drawable.tile_water)
    private val bmpChest = BitmapFactory.decodeResource(context.resources, R.drawable.tile_chest)
    private val bmpPlayer = BitmapFactory.decodeResource(context.resources, R.drawable.player)
    private val bmpEnemy = BitmapFactory.decodeResource(context.resources, R.drawable.enemy)

    init {
        generateMap()
        placeChests(10)
        placeEnemies(8)
        isFocusable = true
    }

    private fun generateMap() {
        for (y in 0 until mapSize) {
            for (x in 0 until mapSize) {
                val r = Random.nextDouble()
                map[y][x] = when {
                    r < 0.22 -> TERRAIN_FOREST
                    r < 0.30 -> TERRAIN_WATER
                    else -> TERRAIN_GRASS
                }
            }
        }
    }

    private fun placeChests(count: Int) {
        repeat(count) {
            var cx: Int
            var cy: Int
            do {
                cx = Random.nextInt(mapSize)
                cy = Random.nextInt(mapSize)
            } while (map[cy][cx] == TERRAIN_WATER || chests.contains(cx to cy))
            chests.add(cx to cy)
        }
    }

    private fun placeEnemies(count: Int) {
        repeat(count) {
            var ex: Int
            var ey: Int
            do {
                ex = Random.nextInt(mapSize)
                ey = Random.nextInt(mapSize)
            } while (map[ey][ex] == TERRAIN_WATER || (ex to ey) in chests || enemies.contains(ex to ey))
            enemies.add(ex to ey)
        }
    }

    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)

        for (y in 0 until mapSize) {
            for (x in 0 until mapSize) {
                val bmp = when (map[y][x]) {
                    TERRAIN_GRASS -> bmpGrass
                    TERRAIN_FOREST -> bmpForest
                    TERRAIN_WATER -> bmpWater
                    else -> bmpGrass
                }
                canvas.drawBitmap(bmp, x * tileSizePx, y * tileSizePx, paint)
            }
        }

        for ((cx, cy) in chests) {
            canvas.drawBitmap(bmpChest, cx * tileSizePx, cy * tileSizePx, paint)
        }

        for ((ex, ey) in enemies) {
            canvas.drawBitmap(bmpEnemy, ex * tileSizePx, ey * tileSizePx, paint)
        }

        canvas.drawBitmap(bmpPlayer, playerX * tileSizePx, playerY * tileSizePx, paint)

        postInvalidateOnAnimation()
    }

    override fun onTouchEvent(event: MotionEvent): Boolean {
        if (event.action == MotionEvent.ACTION_DOWN) {
            playerX = floor(event.x / tileSizePx).toInt().coerceIn(0, mapSize - 1)
            playerY = floor(event.y / tileSizePx).toInt().coerceIn(0, mapSize - 1)
            return true
        }
        return false
    }
}
EOF

########################################
# MainActivity.kt (overwrite to attach GameView)
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

    override fun onResume() {
        super.onResume()
        setContentView(GameView(this))
    }
}
EOF

echo "=== Procedural Game Content Installed ==="