#!/usr/bin/env bash
set -e
echo "=== Full Android Gradle Project Bootstrap ==="

# Ensure required directories exist
mkdir -p app/src/main/java/com/example/rpg
mkdir -p app/src/main/res
mkdir -p app/src/main/res/mipmap-48x48
mkdir -p app/src/main/res/mipmap-72x72
mkdir -p app/src/main/res/mipmap-96x96
mkdir -p app/src/main/res/mipmap-144x144
mkdir -p app/src/main/res/mipmap-192x192
mkdir -p app/src/main/res/mipmap-anydpi-v26

# gradle.properties (AndroidX REQUIRED)
if [ ! -f gradle.properties ]; then
cat <<EOF > gradle.properties
android.useAndroidX=true
android.enableJetifier=true
EOF
    echo "Created gradle.properties with AndroidX enabled"
fi

# settings.gradle
if [ ! -f settings.gradle ]; then
    echo "rootProject.name = 'ProceduralRPG'" > settings.gradle
    echo "include ':app'" >> settings.gradle
    echo "Created settings.gradle"
fi

# Root build.gradle
if [ ! -f build.gradle ]; then
cat <<EOL > build.gradle
// Top-level build file
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath 'com.android.tools.build:gradle:8.3.0'
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}
EOL
    echo "Created root build.gradle"
fi

# App module build.gradle
if [ ! -f app/build.gradle ]; then
cat <<EOL > app/build.gradle
apply plugin: 'com.android.application'

android {
    namespace "com.example.rpg"
    compileSdkVersion 34
    defaultConfig {
        applicationId "com.example.rpg"
        minSdkVersion 24
        targetSdkVersion 34
        versionCode 1
        versionName "1.0"
    }

    buildTypes {
        release {
            minifyEnabled false
        }
    }
}

dependencies {
    implementation 'androidx.appcompat:appcompat:1.6.1'
    implementation 'com.google.android.material:material:1.9.0'
}
EOL
    echo "Created app/build.gradle with namespace"
fi

# Gradle wrapper
if [ ! -f gradlew ]; then
    echo "Generating Gradle wrapper..."
    gradle wrapper --gradle-version 9.2.1
    chmod +x gradlew
    echo "Gradle wrapper created"
fi

echo "Gradle project bootstrap complete."
echo "You can now run ./gradlew :app:assembleDebug"