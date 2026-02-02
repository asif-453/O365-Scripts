<#
.SYNOPSIS
Collects Windows Autopilot hardware hash and device identity information.

.DESCRIPTION
Gathers Windows Autopilot–required identifiers from the local device and
exports them to CSV for upload into Microsoft Intune / Autopilot.

Supports:
- Hardware hash
- Serial number
- Manufacturer / model
- Optional Group Tag
- Optional Assigned User

Authentication is NOT required unless importing directly to Intune
(this script performs collection only).

.NOTES
Run as Administrator.
Tested on Windows 10 / 11.

Common use cases:
- New device provisioning
- Autopilot device re-registration
- Break/fix scenarios
- OEM-independent collection

Original concept by Michael Niehaus (Microsoft).
This version is sanitized and modernized for enterprise use.
#>

# ==================================================
# Parameters
# ==================================================
[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$OutputFile = "AutoPilotInfo.csv",

    [Parameter(Mandatory = $false)]
    [string]$GroupTag,

    [Parameter(Mandatory = $false)]
    [string]$AssignedUser
)

# ==================================================
# Admin check
# ==================================================
if (-not ([Security.Principal.WindowsPrincipal]
    [Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {

    Write-Error "This script must be run as Administrator."
    exit 1
}

# ==================================================
# Collect device information
# ==================================================
Write-Host "Collecting device information..." -ForegroundColor Cyan

try {
    $computerSystem = Get-CimInstance -ClassName Win32_ComputerSystem
    $bios           = Get-CimInstance -ClassName Win32_BIOS
    $baseBoard      = Get-CimInstance -ClassName Win32_BaseBoard
}
catch {
    Write-Error "Failed to retrieve system information: $_"
    exit 1
}

$manufacturer = $computerSystem.Manufacturer
$model        = $computerSystem.Model
$serialNumber = $bios.SerialNumber

# ==================================================
# Retrieve hardware hash
# ==================================================
Write-Host "Retrieving hardware hash..." -ForegroundColor Cyan

try {
    $hash = (Get-CimInstance -Namespace root/cimv2/mdm/dmmap `
        -ClassName MDM_DevDetail_Ext01 `
        -Filter "InstanceID='Ext' AND ParentID='./DevDetail'").DeviceHardwareData
}
catch {
    Write-Error "Unable to retrieve hardware hash. Ensure device supports Autopilot."
    exit 1
}

# ==================================================
# Build output object
# ==================================================
$result = [PSCustomObject]@{
    'Device Serial Number' = $serialNumber
    'Windows Product ID'   = ''
    'Hardware Hash'        = $hash
    'Manufacturer'         = $manufacturer
    'Model'                = $model
    'Group Tag'            = $GroupTag
    'Assigned User'        = $AssignedUser
}

# ==================================================
# Export to CSV
# ==================================================
Write-Host "Exporting Autopilot data..." -ForegroundColor Cyan

try {
    $result | Export-Csv -Path $OutputFile -NoTypeInformation -Encoding UTF8
}
catch {
    Write-Error "Failed to write output file: $_"
    exit 1
}

Write-Host ""
Write-Host "Autopilot information collected successfully." -ForegroundColor Green
Write-Host "Output file: $OutputFile" -ForegroundColor Cyan
