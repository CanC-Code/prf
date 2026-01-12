#!/usr/bin/env bash
set -e

bash scripts/setup_gradle.sh
bash scripts/generate_project.sh
bash scripts/populate_game.sh

./gradlew :app:assembleDebug --no-daemon
