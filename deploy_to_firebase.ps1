Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "  🚀 Marakadhey Firebase Web & APK Deployer " -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

# 1. Build Latest Flutter Web
Write-Host "`n[1/3] Building Flutter Web..." -ForegroundColor Yellow
Set-Location -Path "c:\marakadhey_app\marakadhey_flutter"
& "C:\flutter\bin\flutter.bat" build web

# 2. Copy latest APK to Web root for direct public download
Write-Host "`n[2/3] Syncing latest APKs to public web distribution..." -ForegroundColor Yellow
$apkSource = "c:\marakadhey_app\marakadhey_flutter\build\app\outputs\flutter-apk"
if (Test-Path "$apkSource\app-arm64-v8a-release.apk") {
    Copy-Item "$apkSource\app-arm64-v8a-release.apk" -Destination "c:\marakadhey_app\marakadhey_flutter\build\web\Marakadhey_v1.4.0.apk" -Force
    Copy-Item "$apkSource\app-arm64-v8a-release.apk" -Destination "c:\marakadhey_app\marakadhey_flutter\build\web\Marakadhey_arm64-v8a.apk" -Force
}

# 3. Deploy to Firebase Hosting
Write-Host "`n[3/3] Deploying to Firebase Hosting (marakadhey.web.app)..." -ForegroundColor Yellow
Set-Location -Path "c:\marakadhey_app"
& npx --yes firebase-tools deploy --only hosting

Write-Host "`n=========================================" -ForegroundColor Green
Write-Host "  ✓ Marakadhey is LIVE Online!" -ForegroundColor Green
Write-Host "  Web App: https://marakadhey.web.app" -ForegroundColor Green
Write-Host "  APK Download: https://marakadhey.web.app/Marakadhey_arm64-v8a.apk" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green
