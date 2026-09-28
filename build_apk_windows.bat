@echo off
setlocal
cd /d "%~dp0"
echo ========================================
echo Al-Akram Law - APK Build
 echo ========================================
where flutter >nul 2>&1
if errorlevel 1 (
  echo [ERROR] Flutter is not in PATH.
  echo Install Flutter and add flutter\bin to PATH, then run this file again.
  pause
  exit /b 1
)
flutter doctor -v
if errorlevel 1 (
  echo [ERROR] Flutter doctor reported a problem.
  pause
  exit /b 1
)
flutter clean
if errorlevel 1 goto :fail
flutter pub get
if errorlevel 1 goto :fail
flutter build apk --release -v
if errorlevel 1 goto :fail
echo.
echo [SUCCESS] APK created at:
echo build\app\outputs\flutter-apk\app-release.apk
pause
exit /b 0
:fail
echo.
echo [ERROR] APK build failed. The error above is the exact build error.
pause
exit /b 1
