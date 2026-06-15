#!/bin/bash

set -e

echo "🔍 Checking for connected devices..."
flutter devices

echo ""
echo "📦 Building release APK..."
flutter build apk --release

echo ""
echo "📲 Installing APK to connected device..."
flutter install

echo ""
echo "✅ Build and installation complete!"
echo "📱 App is now running on your device."
