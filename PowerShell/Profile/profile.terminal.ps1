# ------------------------------
# Enhanced experience
# ------------------------------

# Window settings
$host.ui.RawUI.WindowTitle = “Windows Powershell”

# ------------------------------
# Custom Banner
# ------------------------------

# Load the System Info file
$cacheFile = Join-Path (Split-Path -Parent $PROFILE) 'system.json'

if (Test-Path $cacheFile) {
    $SystemInfo = Get-Content $cacheFile -Raw | ConvertFrom-Json
} else {
    $cs  = Get-CimInstance Win32_ComputerSystem
    $csp = Get-CimInstance Win32_ComputerSystemProduct
    $os  = Get-CimInstance Win32_OperatingSystem
    $cpu = Get-CimInstance Win32_Processor
    $gpu = Get-CimInstance Win32_VideoController | Select-Object -First 1

    $SystemInfo = [ordered]@{
        Manufacturer = $cs.Manufacturer
        Model        = $cs.Model
        Product      = $csp.Version

        OS           = $os.Caption
        OSVersion    = $os.Version
        Architecture = $os.OSArchitecture

        CPU          = $cpu.Name
        GPU          = $gpu.Name
        VRAM         = $gpu.AdapterRAM
    }

    # Save cache
    $SystemInfo | ConvertTo-Json -Depth 3 | Set-Content -Path $cacheFile -Encoding UTF8
}

# Get System Information
$vendor = $SystemInfo.Manufacturer
$name   = $SystemInfo.Product
$model  = $SystemInfo.Model
$sysver = $SystemInfo.OS
$cpu    = $SystemInfo.CPU
$gpu    = $SystemInfo.GPU
$vram   = [math]::Round($SystemInfo.VRAM / 1GB, 1)

$pwsh   = (Get-Host).Version
$time   = Get-Date -f "dddd, dd MMM yyyy HH:mm:ss"

# Calculate System Resources
$os      = Get-CimInstance Win32_OperatingSystem

$totalKB = $os.TotalVisibleMemorySize
$freeKB  = $os.FreePhysicalMemory
$usedKB  = $totalKB - $freeKB
$totalGB = [math]::Round(($totalKB * 1KB) / 1GB, 2)
$usedGB  = [math]::Round(($usedKB * 1KB) / 1GB, 2)
$percent = [math]::Round(($usedKB / $totalKB) * 100)

# Get IP Adresses
$wifi = ipconfig | Select-String '^Wireless LAN adapter Wi-Fi:' -Context 0,8
$ipv4 = $wifi.Context.PostContext | Where-Object { $_ -match 'IPv4 Address' }

if ($ipv4) {
    $localIP = $ipv4.Split(':')[-1].Trim()
} else {
    $localIP = 'Offline'
}

# Load from banner.txt
$banner = Get-Content "$HOME\Documents\PowerShell\banner.txt" -Raw
$ExecutionContext.InvokeCommand.ExpandString($banner)
