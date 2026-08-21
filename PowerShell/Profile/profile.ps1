# ------------------------------
# Base functions
# ------------------------------

# Launch a new Powershell (Admin) window
function sudo {
    $pwsh = (Get-Command pwsh -ErrorAction Stop).Source
    Start-Process -FilePath $pwsh -Verb RunAs
	exit
}

# Open file in Notepad++
# Format : npp <Filename>
function npp {
    param (
        [Parameter(Mandatory)]
        [string]$Path
    )

    $nppPath = "C:\Program Files\Notepad++\notepad++.exe"

    if (Test-Path $nppPath) {
        & "$nppPath" "$Path"
    } else {
        throw "Notepad++ not found at $nppPath"
    }
}

# ------------------------------
# Utility functions
# ------------------------------

# Encode or decode a file using Base64
# Format : base64 <Mode> <Filename>
function base64 {
    param(
        [Parameter(Mandatory)]
        [ValidateSet("e", "d")]
        [string]$Mode,

        [Parameter(Mandatory)]
        [string]$Path
    )

    if (-not (Test-Path $Path)) {
        throw "Input file not found: $Path"
    }

    switch ($Mode) {
        "e" {
            $bytes = [IO.File]::ReadAllBytes($Path)
            $b64   = [Convert]::ToBase64String($bytes)

            $fileName = [IO.Path]::GetFileNameWithoutExtension($Path)
            $outFile  = "$fileName-b64.txt"
            Set-Content -Path $outFile -Value $b64 -NoNewline -Encoding ascii
        }

        "d" {
            if ([IO.Path]::GetExtension($Path) -ne ".txt") {
                throw "Decoding requires a .txt file"
            }

            $b64 = Get-Content $Path -Raw
			try {
				$bytes = [Convert]::FromBase64String($b64)
			} catch {
				throw "Invalid Base64 content in file: $Path"
			}

            $outFile = [IO.Path]::GetFileNameWithoutExtension($Path)
            [IO.File]::WriteAllBytes($outFile, $bytes)
        }
    }

    Write-Host "Saved to '$outFile'" -ForegroundColor Green
}

# Save content of all files to one file
function transcript {
	$dir = Get-Location
    $out = Join-Path $dir "transcript.txt"
    $ext = @(
        ".c", ".cpp", ".h", ".hpp", ".cs", ".csproj", ".sln", ".java", ".pom", ".kt", 
        ".kts", ".py", ".go", ".rs", ".htm", ".html", ".css", ".scss", ".sass", ".js", 
        ".ts", ".tsx", ".jsx", ".csv", ".sql", ".xml", ".json", ".md", ".txt", ".log", 
        ".ini", ".cfg", ".conf", ".gradle", ".properties", ".yml", ".yaml", ".dockerfile", 
        ".gitignore", ".sh", ".ps1", ".bat", ".cmd", ".ahk", ".svg", ".env", ".npmrc", ".yarnrc"
    )
    
    "" | Out-File -FilePath $out -Encoding utf8
    
	Get-ChildItem -Path $dir -Recurse -File | 
    Where-Object { 
        $ext -contains $_.Extension -and 
        $_.FullName -ne $out 
    } | ForEach-Object {
        @(
            "===== Filename: $($_.FullName) =====",
            (Get-Content $_.FullName -Raw),
            ""
        ) | Out-File -FilePath $out -Append -Encoding utf8
    }
	
    Write-Host "Saved to 'transcript.txt'" -ForegroundColor Green
}

# Clear System Cache
function wipe {
    $paths = @(
        "$env:SystemRoot\Prefetch\*",
        "$env:SystemRoot\Temp\*",
        "$env:TEMP\*",
        "$env:LOCALAPPDATA\Microsoft\Windows\INetCache\*"
    )
    
    foreach ($path in $paths) {
        if (Test-Path $path) {
            Write-Host "Clearing $path" -ForegroundColor Yellow
            Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    Write-Host "Cache clearing completed" -ForegroundColor Green
}

# ------------------------------
# Application-based functions
# ------------------------------

# Modify timestamps for Git commits
# Format : timestamp <"01-02-26 11:27:34"> // No param
function timestamp {
    param(
        [string]$DateTime
    )
	
    if (-not $DateTime) {
        Remove-Item Env:GIT_AUTHOR_DATE, Env:GIT_COMMITTER_DATE -ErrorAction SilentlyContinue
        Write-Host "Cleared Git timestamps" -ForegroundColor Green
        return
    }

    $formatIn  = "dd-MM-yy HH:mm:ss"
    $formatOut = "ddd, dd MMM yyyy HH:mm:ss +0530"
    
    try {
        $dt = [datetime]::ParseExact(
            $DateTime,
            $formatIn,
            [System.Globalization.CultureInfo]::InvariantCulture
        )

        $finalDate = $dt.ToString($formatOut, [System.Globalization.CultureInfo]::InvariantCulture)
        $env:GIT_AUTHOR_DATE    = $finalDate
        $env:GIT_COMMITTER_DATE = $finalDate
        Write-Host "GIT_AUTHOR_DATE    = $env:GIT_AUTHOR_DATE" -ForegroundColor Green
        Write-Host "GIT_COMMITTER_DATE = $env:GIT_COMMITTER_DATE" -ForegroundColor Green
    }
    catch {
        throw "Invalid date format. Use: dd-MM-yy HH:mm:ss"
    }
}

# Generate and trigger Python Virtual Environment
function venv {
    $venvPath = ".venv\Scripts\Activate.ps1"
	
    if (-not (Test-Path $venvPath)) {
		Write-Host "Creating VirtualEnv..." -ForegroundColor Yellow
        python -m venv .venv
		& $venvPath
		
		Write-Host "Checking for 'requirements.txt'..." -ForegroundColor Yellow
		if (Test-Path "requirements.txt") {
			pip install -r "requirements.txt"
		}
    } else {
		& $venvPath
	}
}

# Quick download using YT-DLP
# Format : ytm <Quality> <URL>
function ytm {
    param (
        [Parameter(Mandatory)]
        [ValidateSet("360p", "480p", "720p", "1080p", "audio")]
        [string]$Quality,

        [Parameter(Mandatory)]
        [string]$Url
    )

    $formatMap = @{
        "360p" = "bestvideo[height<=360]+bestaudio/best[height<=360]"
        "480p" = "bestvideo[height<=480]+bestaudio/best[height<=480]"
        "720p" = "bestvideo[height<=720]+bestaudio/best[height<=720]"
        "1080p" = "bestvideo[height<=1080]+bestaudio/best[height<=1080]"
    }

	if ($Quality -eq "audio") {

        $download = yt-dlp --print after_move:filepath -f "bestaudio" $Url

        $opus = [System.IO.Path]::ChangeExtension($download, ".opus")
        $mp3  = [System.IO.Path]::ChangeExtension($download, ".mp3")

        ffmpeg -i "$download" -vn -acodec copy "$opus"
        ffmpeg -i "$opus" -c:a libmp3lame -q:a 0 "$mp3"

        return
    }

    $format = $formatMap[$Quality]
    yt-dlp -f $format --merge-output-format mp4 $Url
}

# ------------------------------
# Enhanced experience
# ------------------------------

# Disable module auto-loading
$PSModuleAutoLoadingPreference = 'None'

# Load in the necessary modules
Import-Module Microsoft.PowerShell.Management
Import-Module Microsoft.PowerShell.Utility
Import-Module Microsoft.PowerShell.Host
Import-Module Microsoft.PowerShell.Archive
Import-Module CimCmdlets

# Command-line settings
$PSReadLineOptions = @{
    EditMode = 'Windows'
    HistoryNoDuplicates = $true
    HistorySearchCursorMovesToEnd = $true
    HistorySavePath = "$HOME\Documents\PowerShell\history.txt"
    Colors = @{
        Command = '#87CEEB'     # SkyBlue
        Parameter = '#98FB98'   # PaleGreen
        Operator = '#FFB6C1'    # LightPink
        Variable = '#DDA0DD'    # Plum
        String = '#FFDAB9'      # PeachPuff
        Number = '#B0E0E6'      # PowderBlue
        Type = '#F0E68C'        # Khaki
        Comment = '#D3D3D3'     # LightGray
        Keyword = '#8367c7'     # Violet
        Error = '#FF6347'       # Tomato
    }
    PredictionSource = 'HistoryAndPlugin'
	PredictionViewStyle = 'ListView'
    BellStyle = 'None'
}

Set-PSReadLineOption @PSReadLineOptions
Set-PSReadLineKeyHandler -Key Tab -Function AcceptSuggestion

# Prompt colorization
function prompt {  
    " $([char]27)[33m$($PWD.Path)$([char]27)[0m > "
}

# Load Powershell profile
$profileName = switch ($true) {
    { $env:TERM_PROGRAM -eq 'vscode' } { 'vscode' }
    { $env:WT_SESSION }                { 'terminal' }
}

if ($profileName) {
    . "$HOME\Documents\PowerShell\profile.$profileName.ps1"
}
