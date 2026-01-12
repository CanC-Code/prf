#!/usr/bin/env bash
set -e

echo "=== Running Procedural RPG Project Generation ==="

# Bootstrap Gradle project (creates wrapper, build.gradle, etc.)
bash scripts/setup_gradle.sh

# Generate Android project shell (manifests, styles, activity)
bash scripts/generate_project.sh

# Populate procedural RPG game content (GameView, etc.)
bash scripts/populate_game.sh

# Ensure gradlew is executable
chmod +x ./gradlew

# Build debug APK
echo "=== Building debug APK ==="
./gradlew :app:assembleDebug --no-daemon

echo "=== APK build complete ==="