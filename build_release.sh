#!/bin/bash

# Extract version from pubspec.yaml
VERSION=$(grep -oP 'version: \K[^+]+' pubspec.yaml)
BUILD_NUMBER=$(grep -oP 'version: [^+]+\+\K[0-9]+' pubspec.yaml)
FULL_VERSION="$VERSION+$BUILD_NUMBER"

echo "🚀 Building APK with version: $FULL_VERSION"

# Clean, get dependencies, and build
flutter clean
flutter pub get
flutter build apk --release

# Rename APK with version
SOURCE_APK="build/app/outputs/flutter-apk/app-release.apk"
DEST_APK="build/app/outputs/flutter-apk/nextpsa-v${VERSION}-build${BUILD_NUMBER}.apk"

if [ -f "$SOURCE_APK" ]; then
    mv "$SOURCE_APK" "$DEST_APK"
    echo "✅ APK built successfully: $DEST_APK"
else
    echo "❌ Build failed - APK not found"
    exit 1
fi
