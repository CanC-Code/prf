#!/usr/bin/env bash
set -e

echo "=== Populating Procedural RPG Game Content ==="

PKG="com.example.rpg"
SRC="app/src/main"
JAVA_DIR="$SRC/java/com/example/rpg"

mkdir -p "$JAVA_DIR"

########################################
# GameView.kt
########################################
cat > "$JAVA_DIR/GameView.kt" <<EOF
package $PKG

import android.content.Context
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.util.AttributeSet
import android.view.MotionEvent
import android.view.View
import kotlin.math.floor

class GameView @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null
) : View(context, attrs) {

    private val paint = Paint(Paint.ANTI_ALIAS_FLAG)

    private val tileSizePx = 96f
    private val mapSize = 24
    private val map = Array(mapSize) { IntArray(mapSize) }

    private var playerX = mapSize / 2
    private var playerY = mapSize / 2

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
                paint.color =
                    if (map[y][x] == 0) Color.rgb(60, 170, 60)
                    else Color.rgb(30, 100, 30)

                canvas.drawRect(
                    x * tileSizePx,
                    y * tileSizePx,
                    (x + 1) * tileSizePx,
                    (y + 1) * tileSizePx,
                    paint
                )
            }
        }

        paint.color = Color.RED
        canvas.drawCircle(
            (playerX + 0.5f) * tileSizePx,
            (playerY + 0.5f) * tileSizePx,
            tileSizePx * 0.35f,
            paint
        )

        postInvalidateOnAnimation()
    }

    override fun onTouchEvent(event: MotionEvent): Boolean {
        if (event.action == MotionEvent.ACTION_DOWN) {
            playerX = floor(event.x / tileSizePx).toInt()
                .coerceIn(0, mapSize - 1)
            playerY = floor(event.y / tileSizePx).toInt()
                .coerceIn(0, mapSize - 1)
            return true
        }
        return false
    }
}
EOF

########################################
# MainActivity.kt (overwrite with stable attach)
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