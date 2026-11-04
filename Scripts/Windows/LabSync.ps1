# --------------- Configuration ---------------

# NOTE: For creating a shortcut, use below:
# pwsh -NoProfile -File "path\to\Backup.ps1"

# Source folder to be used for the process
$SourcePath = 'E:\GitHub'

# Destination folder for keeping the archives
$BackupPath = 'C:\Users\Kunal\Documents\Cloud\XY - Miscellaneous\Developer\Backups'

# Number of newest backups to retain
$NoOfCopies = 5

# Files/folders to exclude from the archive.
#
# Examples:
#   '*\.git\*'              - exclude all Git metadata
#   '*\node_modules\*'      - exclude all node_modules folders
#   '*.tmp'                 - exclude matching .tmp files
#
$ExcludeList = @(
    # Files
    '*.class', '*.dll', '*.exe', '*.lib', '*.log'
    '*.o', '*.out', '*.test', '*.tmp', '*\*.tsbuildinfo'

    # Python
    '*\__pycache__\*', '*\.coverage', '*\.coverage.*'
    '*\.mypy_cache\*', '*\.pytest_cache\*', '*\.venv\*'

    # Node / React / TypeScript / Vite
    '*\.next\*', '*\.npm\*', '*\node_modules\*', '*\.output\*'
    '*\.vite\*', '*\.yarn\*', '*\dist\*', '*\coverage\*'

    # Java / Maven / Gradle / Android
    '*\.gradle\*', '*\bin\*', '*\build\*', '*\captures\*'
    '*\local.properties', '*\out\*', '*\target\*', '*\target-*\*', 
    '*\failsafe-reports\*', '*\surefire-reports\*'

    # Rust / Go
    '*\.cargo\git\*', '*\.cargo\registry\*', '*\vendor\*'

    # IDEs
    '*\.apt_generated\*', '*\.classpath', '*\.factorypath'
    '*\.idea\*', '*\.project', '*\.settings\*', '*\.vscode\*'

    # Temporary / cache / logs
    '*\.cache\*', '*\.temp\*', '*\temp\*', '*\tmp\*'

    # Windows
    '*\$RECYCLE.BIN\*', '*\Desktop.ini', '*\Thumbs.db'
)

# ---------------- Validation ----------------

if (-not (Test-Path -LiteralPath $SourcePath -PathType Container)) {
    throw "[ERROR] Source folder does not exist: $SourcePath"
}

if (-not (Test-Path -LiteralPath $BackupPath -PathType Container)) {
    throw "[ERROR] Backup folder does not exist: $BackupPath"
}

if ($NoOfCopies -lt 1) {
    throw '[ERROR] No. of copies must be 1 or more.'
}

$Tool_7z = @('7z', '7za', '7zz') |
    Where-Object { Get-Command $_ -ErrorAction SilentlyContinue } |
    Select-Object -First 1

if (-not $Tool_7z) {
    throw '[ERROR] No 7-Zip executable was found in PATH.'
}

# ----------------- Archiving -----------------

$DateName  = Get-Date -Format 'yyyy-MM-dd'
$FinalFile = Join-Path $BackupPath "$DateName.7z"
$TempFile  = Join-Path $BackupPath "$DateName.partial.7z"

Write-Host ''
Write-Host '=== Development Environment Backup ===' -ForegroundColor Cyan
Write-Host "Source : $SourcePath"
Write-Host "Backup : $FinalFile"
Write-Host "Keep   : $NoOfCopies"
Write-Host ''

# Never leave a previous temporary archive around
if (Test-Path -LiteralPath $TempFile) {
    Remove-Item -LiteralPath $TempFile -Force
}

# Build 7-Zip arguments
$Arguments = @(
    'a'
    '-t7z'
    '-m0=lzma2'
    '-mx=9'
    '-mmt=on'
    '-y'
    $TempFile
    (Join-Path $SourcePath '*')
)

foreach ($Pattern in $ExcludeList) {
    $Arguments += "-xr!$Pattern"
}

Write-Host '[INFO] Creating archive...' -ForegroundColor Yellow

& $Tool_7z @Arguments

if ($LASTEXITCODE -ne 0) {
    if (Test-Path -LiteralPath $TempFile) {
        Remove-Item -LiteralPath $TempFile -Force
    }

    throw "[ERROR] Compression failed with exit code $LASTEXITCODE."
}

# --------------- Verification ---------------

Write-Host ''
Write-Host '[INFO] Verifying archive...' -ForegroundColor Yellow

& $Tool_7z 't' '-y' $TempFile

if ($LASTEXITCODE -ne 0) {
    if (Test-Path -LiteralPath $TempFile) {
        Remove-Item -LiteralPath $TempFile -Force
    }

    throw "[ERROR] Verification failed with exit code $LASTEXITCODE."
}

# Replace an existing backup for the same date only after
# compression and verification have succeeded.
Move-Item -LiteralPath $TempFile -Destination $FinalFile -Force

Write-Host ''
Write-Host "[SUCCESS] Backup created successfully !" -ForegroundColor Green
Write-Host "[SUCCESS] Location: $FinalFile" -ForegroundColor Green

# ----------------- Retention -----------------

Write-Host ''
Write-Host "[INFO] Applying retention policy..." -ForegroundColor Yellow

$Backups = @(
    Get-ChildItem -LiteralPath $BackupPath -Filter '*.7z' -File |
    Where-Object { $_.Name -match '^\d{4}-\d{2}-\d{2}\.7z$' } |
    Sort-Object Name -Descending
)

$BackupsToDelete = $Backups | Select-Object -Skip $NoOfCopies

foreach ($Backup in $BackupsToDelete) {
    Write-Host "[INFO] Deleting old backup: $($Backup.Name)" -ForegroundColor Cyan
    Remove-Item -LiteralPath $Backup.FullName -Force
}

Write-Host ''
Write-Host '[SUCCESS] Backup completed successfully.' -ForegroundColor Green
Write-Host ''

pause

# Open FreeFileSync
Start-Process 'C:\Program Files\FreeFileSync\FreeFileSync.exe'
