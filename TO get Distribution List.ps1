#To Enable PS Script execution
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser

#To Import Module ExchangeOnlineManagement
Import-Module -Name ExchangeOnlineManagement

#Connecting to ExchangeOnline
Connect-ExchangeOnline 


Full Script to get Distribution group.

# Get all distribution groups
$groups = Get-DistributionGroup

# Create a list to store results
$results = @()

# Loop through each group
foreach ($group in $groups) {
    try {
        # Get members of the current group
        $members = Get-DistributionGroupMember -Identity $group.Identity -ResultSize Unlimited

        foreach ($member in $members) {
            # Only include user mailboxes or mail-enabled users (skip other groups or contacts)
            if ($member.RecipientType -in @("UserMailbox", "MailUser")) {
                $results += [PSCustomObject]@{
                    UserDisplayName    = $member.DisplayName
                    UserEmail          = $member.PrimarySmtpAddress
                    DistributionGroup  = $group.DisplayName
                }
            }
        }
    } catch {
        Write-Warning "Failed to retrieve members of group: $($group.DisplayName). Error: $_"
    }
}

# Ensure output directory exists
$outputPath = "C:\tmp\Reports"
if (-not (Test-Path $outputPath)) {
    New-Item -Path $outputPath -ItemType Directory -Force
}

# Export to CSV
$results | Sort-Object UserEmail | Export-Csv -Path "$outputPath\User_DistributionGroup_Report.csv" -NoTypeInformation

Write-Output "Report generated: $outputPath\User_DistributionGroup_Report.csv"
