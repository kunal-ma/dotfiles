@echo off
setlocal

:: ================= CONFIG =================
set "BASEDIR=%~dp0"

set "KEYSTORE=%BASEDIR%keystore.jks"
set "APKEDITOR=%BASEDIR%APKEditor.jar"
:: ==========================================

:: Verify tools
where tar >nul 2>&1 || (echo tar not found & exit /b 1)
where java >nul 2>&1 || ( echo Java not found & exit /b 1)
where zipalign >nul 2>&1 || (echo zipalign not found & exit /b 1)
where apksigner >nul 2>&1 || (echo apksigner not found & exit /b 1)

if not exist "%KEYSTORE%" (
    echo Keystore not found: %KEYSTORE%
    exit /b 1
)

if not exist "%APKEDITOR%" (
    echo APKEditor.jar not found: %APKEDITOR%
    exit /b 1
)

:: Verify parameters
if "%~1"=="" (
    echo Usage: apkbundle filename.apks^|apkm^|xapk
    exit /b 1
)

:: Get filename of input file
set "INPUT=%~1"
set "NAME=%~n1"

:: Remove existing temp files
if exist tmp rmdir /s /q tmp
if exist unsigned.apk del /f /q unsigned.apk
if exist aligned.apk del /f /q aligned.apk
if exist "%NAME%.apk" del /f /q "%NAME%.apk"

:: Unzip app bundle using `tar`
echo Extracting contents of %INPUT%...

mkdir tmp
tar -xf "%INPUT%" -C tmp
if errorlevel 1 (
    echo ERROR: Extraction failed!
    exit /b 1
)

:: Merge app splits to APK using APKEditor
echo Merging splits...

java -jar "%APKEDITOR%" m -i tmp -o unsigned.apk
if not exist unsigned.apk (
    echo ERROR: Merge failed!
    exit /b 1
)

:: Optimize generated APK using `zipalign`
echo Aligning...

call zipalign -v 4 unsigned.apk aligned.apk >nul
if exist aligned.apk (
    set "FINAL_INPUT=aligned.apk"
) else (
    echo ERROR: Aligning failed, using `unsigned.apk`
    set "FINAL_INPUT=unsigned.apk"
)

:: Sign generated APK with `keystore.jks` using `apksigner`
echo Signing...

call apksigner sign --ks "%KEYSTORE%" --ks-key-alias "kunal-ma" --out "%NAME%.apk" "%FINAL_INPUT%"
if errorlevel 1 (
    echo ERROR: Signing failed!
    exit /b 1
)

echo SUCCESS: %NAME%.apk created!

:: Post-run cleanup
rmdir /s /q tmp
del /f /q unsigned.apk >nul 2>&1
del /f /q aligned.apk >nul 2>&1
del /f /q %NAME%.apk.idsig >nul 2>&1

endlocal
