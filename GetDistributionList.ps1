<#
.SYNOPSIS
Retrieves all members of Exchange Online distribution groups and exports to CSV.

.DESCRIPTION
- Connects to Exchange Online via the ExchangeOnlineManagement module.
- Retrieves all distribution groups and their members.
- Filters members to include only user mailboxes or mail-enabled users.
- Exports results to a CSV file for auditing or reporting.

.REQUIREMENTS
- ExchangeOnlineManagement PowerShell module
- Exchange Administrator permissions

.NOTES
- Run as Administrator
- Script is read-only and does not modify any objects
- ExecutionPolicy should allow running scripts (e.g., RemoteSigned)

.EXAMPLE
.\Get-DistributionGroupMembers.ps1
#>

# ----------------------------
# Enable PS script execution (if required)
# ----------------------------
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force

# ----------------------------
# Import Exchange Online module
# ----------------------------
Import-Module -Name ExchangeOnlineManagement

# ----------------------------
# Connect to Exchange Online
# ----------------------------
Connect-ExchangeOnline

# ----------------------------
# Retrieve all distribution groups
# ----------------------------
$groups = Get-DistributionGroup

# Initialize results collection
$results = @()

# ----------------------------
# Loop through each group and get members
# ----------------------------
foreach ($group in $groups) {
    try {
        $members = Get-DistributionGroupMember -Identity $group.Identity -ResultSize Unlimited

        foreach ($member in $members) {
            # Include only user mailboxes or mail-enabled users
            if ($member.RecipientType -in @("UserMailbox", "MailUser")) {
                $results += [PSCustomObject]@{
                    UserDisplayName   = $member.DisplayName
                    UserEmail         = $member.PrimarySmtpAddress
                    DistributionGroup = $group.DisplayName
                }
            }
        }
    } catch {
        Write-Warning "Failed to retrieve members of group: $($group.DisplayName). Error: $_"
    }
}

# ----------------------------
# Ensure output directory exists
# ----------------------------
$outputPath = "C:\tmp\Reports"
if (-not (Test-Path $outputPath)) {
    New-Item -Path $outputPath -ItemType Directory -Force | Out-Null
}

# ----------------------------
# Export results to CSV
# ----------------------------
$csvFile = Join-Path $outputPath "User_DistributionGroup_Report.csv"
$results | Sort-Object UserEmail | Export-Csv -Path $csvFile -NoTypeInformation -Encoding UTF8

Write-Host "Distribution group membership report generated:" $csvFile -ForegroundColor Green

