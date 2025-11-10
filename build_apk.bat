@echo off
echo Cleaning old build files...
flutter clean

echo Getting dependencies...
flutter pub get

echo Building release APK...
flutter build apk --release

echo Build complete!
echo APK location: build\app\outputs\flutter-apk\app-release.apk
pause
