# =====================================================================
# SYSTEM COMPLIANCE CHECK SCRIPT (PUBLIC / SANITISED VERSION)
#
# NOTE:
# - Organisation-specific identifiers (email, SMTP, domains, usernames)
#   have been intentionally removed for public release.
# - Replace placeholders with values appropriate for your environment.
# =====================================================================

# ================= CONFIG =================

# SANITISED:
# Previously used an org-specific directory (e.g. C:\Drivers).
# Replaced with a neutral, best-practice location.
$BaseDir = Join-Path $env:ProgramData "SystemCompliance"

$LogFilePath               = Join-Path $BaseDir "ComplianceErrors.log"
$ComplianceCheckFilePath   = Join-Path $BaseDir "ComplianceCheck.txt"
$LastSentEmailFilePath     = Join-Path $BaseDir "LastSentEmail.txt"

if (!(Test-Path $BaseDir)) {
    New-Item -Path $BaseDir -ItemType Directory -Force | Out-Null
}

# ================= UTILITIES =================

function Is-ComplianceCheckRecent {
    # Checks if compliance was run in the last 7 days
    if (Test-Path $ComplianceCheckFilePath) {
        ((Get-Date) - (Get-Item $ComplianceCheckFilePath).LastWriteTime).Days -le 7
    } else {
        # SANITISED:
        # File is created locally without any tenant or org reference.
        New-Item $ComplianceCheckFilePath -ItemType File -Force | Out-Null
        return $false
    }
}

function Log-StatusMessage {
    param ([string]$Message)

    # Standardised failure marker for automation / RMM parsing
    if ($Message -match 'failed' -and $Message -notmatch 'CheckFailed') {
        $Message += " CheckFailed"
    }

    Add-Content -Path $LogFilePath -Value $Message
}

# ================= EMAIL ALERTING =================

function Send-EmailAlert {
    param (
        [string]$Subject,
        [string]$Body
    )

    <#
        SANITISED:
        - SMTP server name removed
        - Sender/recipient email addresses removed
        - Credentials removed
        - Org-specific messaging removed

        IMPLEMENTATION NOTE:
        Replace this stub with one of:
        - Send-MailMessage (SMTP relay)
        - Microsoft Graph (recommended)
        - RMM / ticketing webhook
    #>

    Write-Host "Email alert triggered (placeholder): $Subject"
}

function Send-ErrorsByEmail {
    if (!(Test-Path $LogFilePath)) { return }

    $errors = Get-Content $LogFilePath
    if ($errors -match 'CheckFailed') {
        Send-EmailAlert `
            -Subject "System Compliance Alert" `
            -Body ($errors -join "`n")

        # SANITISED:
        # Timestamp only – no email addresses or tenant info stored.
        Get-Date | Out-File $LastSentEmailFilePath -Force
    }
}

# ================= INITIALISE =================

Clear-Content -Path $LogFilePath -ErrorAction SilentlyContinue

# ================= CHECK 1: Cloudflare WARP =================

# APPLICATION DETAIL RETAINED:
# Service name intentionally left intact (vendor-specific but not org-specific).
$warpService = Get-Service -Name "Cloudflare WARP" -ErrorAction SilentlyContinue

if ($warpService.Status -eq "Running") {
    Log-StatusMessage "✅ Check 1: Cloudflare WARP service is running."
} else {
    Log-StatusMessage "⚠️ Check 1: Cloudflare WARP service is not running. CheckFailed"
}

# ================= CHECK 2: Cloudflare WARP CONNECTIVITY =================

# PUBLIC URL – safe to expose
try {
    $trace = Invoke-RestMethod -Uri "https://www.cloudflare.com/cdn-cgi/trace"

    if ($trace -match "warp=on" -and $trace -match "gateway=on") {
        Log-StatusMessage "✅ Check 2: Cloudflare WARP tunnel active."
    } else {
        Log-StatusMessage "⚠️ Check 2: Cloudflare WARP tunnel inactive. CheckFailed"
    }
}
catch {
    Log-StatusMessage "⚠️ Check 2: Unable to validate Cloudflare WARP status. CheckFailed"
}

# ================= CHECK 3: SECURITY AGENT =================

# SANITISED:
# Original agent name replaced with a generic placeholder.
# Rename this service to match your endpoint security tool.
$securityAgent = Get-Service -Name "Security Agent" -ErrorAction SilentlyContinue

if ($securityAgent.Status -eq "Running") {
    Log-StatusMessage "✅ Check 3: Security agent service is running."
} else {
    Log-StatusMessage "⚠️ Check 3: Security agent service is not running. CheckFailed"
}

# ================= CHECK 4: LOCAL ADMINISTRATORS =================

# SANITISED:
# Hardcoded admin usernames removed.
# Check now enforces a numeric threshold instead.
$allowedAdminCount = 1

$adminMembers = Get-LocalGroupMember -Group "Administrators" -ErrorAction SilentlyContinue |
    Where-Object { $_.ObjectClass -eq 'User' }

$enabledAdmins = foreach ($member in $adminMembers) {
    $user = Get-LocalUser $member.Name.Split('\')[-1] -ErrorAction SilentlyContinue
    if ($user.Enabled) { $user.Name }
}

if ($enabledAdmins.Count -le $allowedAdminCount) {
    Log-StatusMessage "✅ Check 4: Local administrator count within expected limits."
} else {
    Log-StatusMessage "⚠️ Check 4: Unexpected enabled local administrators detected. CheckFailed"
}

# ================= CHECK 5: BITLOCKER =================

# APPLICATION DETAIL RETAINED:
# BitLocker state is device-specific but not org-identifying.
$bitlocker = Get-BitLockerVolume -MountPoint "C:" -ErrorAction SilentlyContinue

if ($bitlocker.ProtectionStatus -eq "On") {
    Log-StatusMessage "✅ Check 5: BitLocker protection enabled."
} else {
    Log-StatusMessage "⚠️ Check 5: BitLocker not enabled. CheckFailed"
}

# ================= CHECK 6: DNS AGENT =================

# APPLICATION DETAIL RETAINED:
# DNS Agent presence check retained as-is.
if (Get-Service -Name "DNS Agent" -ErrorAction SilentlyContinue) {
    Log-StatusMessage "⚠️ Check 6: DNS Agent service detected. CheckFailed"
} else {
    Log-StatusMessage "✅ Check 6: DNS Agent service not present."
}

# ================= FINAL ACTION =================

# SANITISED:
# Alerting method abstracted to avoid leaking email / ticketing systems.
Send-ErrorsByEmail
