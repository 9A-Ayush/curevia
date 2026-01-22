@echo off
echo 🔥 Deploying Firebase Indexes for Rating System...
echo.

echo 📋 Current indexes being deployed:
echo   ✅ ratings collection indexes
echo   ✅ doctors collection rating indexes  
echo   ✅ appointments collection indexes
echo.

echo 🚀 Starting deployment...
firebase deploy --only firestore:indexes

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ✅ SUCCESS: Firebase indexes deployed successfully!
    echo.
    echo 📊 Rating System Indexes Deployed:
    echo   • ratings by appointmentId + status
    echo   • ratings by doctorId + status + timestamp ^(DESC^)
    echo   • ratings by doctorId + status + timestamp ^(ASC^)
    echo   • ratings by doctorId + status + rating ^(DESC^)
    echo   • ratings by doctorId + status + rating ^(ASC^)
    echo   • ratings by status + timestamp ^(DESC^)
    echo   • ratings by status + timestamp ^(ASC^)
    echo   • ratings by patientId + status + timestamp ^(DESC^)
    echo   • ratings by patientId + timestamp ^(DESC^)
    echo   • doctors by averageRating ^(DESC^)
    echo   • doctors by averageRating + totalRatings ^(DESC^)
    echo.
    echo 🎯 Your rating system is now optimized for production!
    echo    All queries will be fast and efficient.
    echo.
) else (
    echo.
    echo ❌ ERROR: Failed to deploy indexes
    echo    Please check your Firebase configuration and try again.
    echo.
)

pause