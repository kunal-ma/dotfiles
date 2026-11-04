# --------------- Configuration ---------------

# Variables for Icon Cache locations
$iconCache = "$env:LOCALAPPDATA\IconCache.db"
$iconCacheX = "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\iconcache*"

# Check for Administrator privileges
If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
{
    # Restart script as an Administrator
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    Exit
}

# --------------- Functionality ---------------

# Reset the Icon Cache
Start-Process ie4uinit.exe -ArgumentList "-show" -NoNewWindow -Wait

# Stop and restart the Windows Explorer process
Stop-Process -Name explorer -Force
Start-Sleep -Seconds 2

# Remove the Icon Cache files
Remove-Item -Path $iconCache -Force -ErrorAction SilentlyContinue
Remove-Item -Path $iconCacheX -Force -Recurse -ErrorAction SilentlyContinue

# Start the Windows Explorer process
Start-Process explorer
