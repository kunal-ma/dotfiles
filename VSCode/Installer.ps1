# Verify VSCode exists and is available in PATH
if (-not (Get-Command code -ErrorAction SilentlyContinue)) {
    throw "Visual Studio Code was not found in PATH"
}

# -----------------------------
# Configuration
# -----------------------------

# Extensions to be installed from the Extension Marketplace
$extensions = @(
    "edwinhuish.better-comments-next",
    "streetsidesoftware.code-spell-checker",
    "yzhang.markdown-all-in-one",
    "esbenp.prettier-vscode",
    "ms-python.python",
    # "ms-python.vscode-pylance" included in above
    "vscode-icons-team.vscode-icons"
)

# Unnecessary extensions bundled with required extensions
$uninstalls = @(
    "ms-python.debugpy",
	"ms-python.vscode-python-envs"
)

# Extensions to be downloaded from the GitHub release
# NOTE: The name must match EXACTLY to the file in the release
$files = @(
    "TodoZen-4.19.1.vsix"
)

# API Call to fetch the GitHub release data
$release = Invoke-RestMethod "https://api.github.com/repos/kunal-ma/dotfiles/releases/tags/vscode"

# Location to store the downloaded VSIX
$downloadPath = Join-Path $PSScriptRoot "Extensions"

# -----------------------------
# Functions
# -----------------------------

function Install-Extension($extension) {
    Write-Host "Installing $extension..." -ForegroundColor Yellow
    code --install-extension $extension --force
}

function Uninstall-Extension($extension) {
    Write-Host "Uninstalling $extension..." -ForegroundColor Yellow
    code --uninstall-extension $extension --force
}

# -----------------------------
# Execution
# -----------------------------

# Installing extensions from the Extension Marketplace
foreach ($extension in $extensions) {
    Install-Extension $extension
}

# Downloading & installing extensions from the GitHub releases
if (-not (Test-Path $downloadPath)) {
    New-Item -ItemType Directory -Path $downloadPath | Out-Null
}

foreach ($file in $files) {
    $asset = $release.assets | Where-Object name -eq $file

    if (-not $asset) {
        Write-Warning "Release asset not found: $file"
        continue
    }

    $destination = Join-Path $downloadPath $file

    Write-Host "Downloading $file..." -ForegroundColor Yellow
    Invoke-WebRequest $asset.browser_download_url -OutFile $destination

    Install-Extension $destination
}

# Uninstalling useless extensions after all installs
foreach ($uninstall in $uninstalls) {
    Uninstall-Extension $uninstall
}

Write-Host "Finished !" -ForegroundColor Green
