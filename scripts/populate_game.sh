#!/usr/bin/env bash
set -e

echo "=== Populating Procedural RPG Game Content with Assets ==="

PKG="com.example.rpg"
SRC="app/src/main"
JAVA_DIR="$SRC/java/com/example/rpg"
RES_DRAWABLE="$SRC/res/drawable"

mkdir -p "$JAVA_DIR"
mkdir -p "$RES_DRAWABLE"

########################################
# Copy / generate sample PNG assets
########################################
# Grass tile
convert -size 96x96 xc:green "$RES_DRAWABLE/tile_grass.png"

# Forest tile
convert -size 96x96 xc:#1E641E "$RES_DRAWABLE/tile_forest.png"

# Player icon
convert -size 96x96 xc:none -fill red -draw "circle 48,48 48,24" "$RES_DRAWABLE/player.png"

########################################
# GameView.kt with bitmap rendering
########################################
cat > "$JAVA_DIR/GameView.kt" <<EOF
package $PKG

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.util.AttributeSet
import android.view.MotionEvent
import android.view.View
import kotlin.math.floor

class GameView @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null
) : View(context, attrs) {

    private val tileSizePx = 96f
    private val mapSize = 24
    private val map = Array(mapSize) { IntArray(mapSize) }

    private var playerX = mapSize / 2
    private var playerY = mapSize / 2

    private val grassBitmap: Bitmap = BitmapFactory.decodeResource(resources, R.drawable.tile_grass)
    private val forestBitmap: Bitmap = BitmapFactory.decodeResource(resources, R.drawable.tile_forest)
    private val playerBitmap: Bitmap = BitmapFactory.decodeResource(resources, R.drawable.player)

    init {
        generateMap()
        isFocusable = true
    }

    private fun generateMap() {
        for (y in 0 until mapSize) {
            for (x in 0 until mapSize) {
                map[y][x] = if (Math.random() > 0.22) 0 else 1
            }
        }
    }

    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)

        for (y in 0 until mapSize) {
            for (x in 0 until mapSize) {
                val bmp = if (map[y][x] == 0) grassBitmap else forestBitmap
                canvas.drawBitmap(bmp, x * tileSizePx, y * tileSizePx, null)
            }
        }

        canvas.drawBitmap(
            playerBitmap,
            playerX * tileSizePx,
            playerY * tileSizePx,
            null
        )

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
# MainActivity.kt (overwrite stable attach)
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

echo "=== Procedural Game Content with Assets Installed ==="