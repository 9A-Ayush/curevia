@echo off
echo 🔥 Deploying Firestore Indexes...
echo.

REM Check if Firebase CLI is installed
firebase --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Firebase CLI not found. Please install it first:
    echo npm install -g firebase-tools
    echo.
    pause
    exit /b 1
)

REM Check if logged in to Firebase
firebase projects:list >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Not logged in to Firebase. Please login first:
    echo firebase login
    echo.
    pause
    exit /b 1
)

echo 📋 Current project:
firebase use

echo.
echo 🚀 Deploying Firestore indexes...
firebase deploy --only firestore:indexes

if %errorlevel% equ 0 (
    echo.
    echo ✅ Firestore indexes deployed successfully!
    echo.
    echo 📋 Next steps:
    echo 1. Wait for indexes to build ^(check Firebase Console^)
    echo 2. Test your queries
    echo 3. Monitor index usage in Firebase Console
    echo.
    echo 🌐 Firebase Console: https://console.firebase.google.com/project/curevia-f31a8/firestore/indexes
) else (
    echo.
    echo ❌ Deployment failed. Please check the error above.
)

echo.
pause