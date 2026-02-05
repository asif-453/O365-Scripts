# ================= CONFIG =================
$LogDir  = "C:\Temp"
$LogFile = Join-Path $LogDir "Duo_WindowsLogon_Update.log"

$DuoCdnUrl     = "https://dl.duosecurity.com/duo-win-login-latest.exe"
$TempInstaller = "$env:TEMP\duo-win-login-latest.exe"

# ================ LOGGING =================
if (!(Test-Path $LogDir)) {
    New-Item -Path $LogDir -ItemType Directory -Force | Out-Null
}

$RunId = [guid]::NewGuid().ToString()

function Write-Log {
    param (
        [Parameter(Mandatory)]
        [string]$Message,

        [ValidateSet("INFO","WARN","ERROR")]
        [string]$Level = "INFO"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    $entry = "$timestamp [$Level] [PID:$PID] [Run:$RunId] $Message"

    Write-Output $entry
    Add-Content -Path $LogFile -Value $entry
}

Write-Log "========== Duo Windows Logon Update Script Started =========="
Write-Log "Running as: $([Security.Principal.WindowsIdentity]::GetCurrent().Name)"

# ========== DETECT DUO (REGISTRY) ==========
Write-Log "Checking registry for Duo Windows Logon installation..."

$UninstallPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
)

$DuoProduct = Get-ItemProperty $UninstallPaths -ErrorAction SilentlyContinue |
    Where-Object {
        $_.Publisher -like "*Duo Security*" -and
        $_.DisplayName -like "*Duo Authentication for Windows Logon*"
    } |
    Select-Object -First 1

if (-not $DuoProduct) {
    Write-Log "Duo Windows Logon not installed. Nothing to do." "WARN"
    Write-Log "========== Script Finished =========="
    exit 0
}

$InstalledVersion = [version]$DuoProduct.DisplayVersion
Write-Log "Duo detected via registry."
Write-Log "Installed version: $InstalledVersion"

# ========== DOWNLOAD LATEST INSTALLER ==========
try {
    Write-Log "Downloading latest Duo installer from CDN: $DuoCdnUrl"
    Invoke-WebRequest -Uri $DuoCdnUrl -OutFile $TempInstaller -UseBasicParsing -ErrorAction Stop
}
catch {
    Write-Log "Failed to download installer. $($_.Exception.Message)" "ERROR"
    exit 1
}

if (!(Test-Path $TempInstaller)) {
    Write-Log "Installer download missing after download attempt." "ERROR"
    exit 1
}

# ========== READ & NORMALIZE INSTALLER VERSION ==========
$RawInstallerVersion = (Get-Item $TempInstaller).VersionInfo.ProductVersion
Write-Log "Raw installer version string: $RawInstallerVersion"

$NumericInstallerVersion = ($RawInstallerVersion -split '-')[0]

try {
    $LatestVersion = [version]$NumericInstallerVersion
}
catch {
    Write-Log "Unable to parse installer version string." "ERROR"
    exit 1
}

Write-Log "Latest available version: $LatestVersion"

# ========== VERSION COMPARISON ==========
if ($InstalledVersion -ge $LatestVersion) {
    Write-Log "Duo is already up to date. No update required."
    Write-Log "========== Script Finished =========="
    exit 0
}

Write-Log "Update required: $InstalledVersion → $LatestVersion"

# ========== INSTALL UPDATE ==========
try {
    Write-Log "Launching Duo installer in silent mode..."

    $process = Start-Process `
        -FilePath $TempInstaller `
        -ArgumentList "/S" `
        -Wait `
        -PassThru `
        -ErrorAction Stop

    if ($process.ExitCode -ne 0) {
        Write-Log "Installer exited with code $($process.ExitCode)" "ERROR"
        exit 1
    }
}
catch {
    Write-Log "Exception during install: $($_.Exception.Message)" "ERROR"
    exit 1
}

# ========== POST-INSTALL VERIFICATION ==========
Start-Sleep -Seconds 5
Write-Log "Verifying post-install version..."

$DuoProductPost = Get-ItemProperty $UninstallPaths -ErrorAction SilentlyContinue |
    Where-Object {
        $_.Publisher -like "*Duo Security*" -and
        $_.DisplayName -like "*Duo Authentication for Windows Logon*"
    } |
    Select-Object -First 1

if (-not $DuoProductPost) {
    Write-Log "Duo Windows Logon missing after install." "ERROR"
    exit 1
}

$PostVersion = [version]$DuoProductPost.DisplayVersion
Write-Log "Post-install version detected: $PostVersion"

if ($PostVersion -ge $LatestVersion) {
    Write-Log "Duo successfully updated."
    Write-Log "========== Script Finished =========="
    exit 0
}
else {
    Write-Log "Post-install version does not match expected version." "ERROR"
    exit 1
}
