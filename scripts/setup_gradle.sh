#!/usr/bin/env bash
set -e

echo "=== Bootstrapping Gradle Project ==="

# Root Gradle files
if [ ! -f settings.gradle ]; then
    cat > settings.gradle <<EOL
rootProject.name = "ProceduralRPG"
include(":app")
EOL
    echo "Created settings.gradle"
fi

if [ ! -f build.gradle ]; then
    cat > build.gradle <<EOL
buildscript {
    repositories { google(); mavenCentral() }
    dependencies { classpath 'com.android.tools.build:gradle:8.2.0' }
}
allprojects { repositories { google(); mavenCentral() } }
EOL
    echo "Created root build.gradle"
fi

# App module
mkdir -p app
if [ ! -f app/build.gradle ]; then
    cat > app/build.gradle <<EOL
plugins {
    id 'com.android.application'
    id 'org.jetbrains.kotlin.android' version '1.9.0' apply false
}

android {
    compileSdk 34
    defaultConfig {
        applicationId "com.canc.proceduralrpg"
        minSdk 24
        targetSdk 34
        versionCode 1
        versionName "1.0"
    }
}
EOL
    echo "Created app/build.gradle"
fi

# Gradle wrapper
if [ ! -f ./gradlew ]; then
    gradle wrapper --gradle-version 9.2.1
    chmod +x ./gradlew
    echo "Generated Gradle wrapper"
fi

echo "=== Gradle setup complete ==="