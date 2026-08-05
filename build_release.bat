@echo off
REM Extract version from pubspec.yaml
REM Using PowerShell to parse YAML more reliably

for /f "tokens=2 delims= " %%i in ('findstr /R "^version:" pubspec.yaml') do set FULL_VER=%%i

REM Split version and build number
for /f "tokens=1 delims=+" %%i in ('echo %FULL_VER%') do set VERSION=%%i
for /f "tokens=2 delims=+" %%i in ('echo %FULL_VER%') do set BUILD_NUMBER=%%i

echo.
echo 🚀 Building APK with version: %VERSION%+%BUILD_NUMBER%
echo.

REM Clean, get dependencies, and build
echo Cleaning...
call flutter clean

echo Getting dependencies...
call flutter pub get

echo Building APK...
call flutter build apk --release

REM Rename APK with version
set SOURCE_APK=build\app\outputs\flutter-apk\app-release.apk
set DEST_APK=build\app\outputs\flutter-apk\nextpsa-v%VERSION%-build%BUILD_NUMBER%.apk

if exist "%SOURCE_APK%" (
    move "%SOURCE_APK%" "%DEST_APK%"
    echo.
    echo ✅ APK built successfully!
    echo 📱 Location: %DEST_APK%
    echo.
) else (
    echo.
    echo ❌ Build failed - APK not found
    exit /b 1
)
