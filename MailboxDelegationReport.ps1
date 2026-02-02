<#
.SYNOPSIS
Generates a report of mailbox delegation permissions in Exchange Online.

.DESCRIPTION
Retrieves Full Access, Send As, and Send On Behalf permissions
for all mailboxes in Exchange Online and exports the results to CSV.

The script excludes inherited permissions and system principals
(e.g., NT AUTHORITY, SIDs).

.OUTPUTS
CSV file containing:
- Mailbox SMTP address
- Mailbox type
- Delegate
- Access type

.REQUIREMENTS
- Exchange Online PowerShell module
- Exchange Administrator or equivalent permissions

.NOTES
Designed for audit, access review, and security validation.
Read-only operation; no changes are made.
#>

# ==================================================
# Connect to Exchange Online
# ==================================================
Connect-ExchangeOnline

# ==================================================
# Initialize results collection
# ==================================================
$Results = New-Object System.Collections.Generic.List[object]

# ==================================================
# Retrieve all mailboxes
# ==================================================
$mailboxes = Get-Mailbox -ResultSize Unlimited

foreach ($mbx in $mailboxes) {

    $mailboxType = $mbx.RecipientTypeDetails

    # ==================================================
    # Full Access permissions (explicit only)
    # ==================================================
    Get-MailboxPermission -Identity $mbx.Identity |
        Where-Object {
            $_.AccessRights -contains "FullAccess" -and
            $_.IsInherited -eq $false -and
            $_.User -notlike "NT AUTHORITY\*" -and
            $_.User -notlike "S-1-5*"
        } |
        ForEach-Object {
            $Results.Add([PSCustomObject]@{
                Mailbox     = $mbx.PrimarySmtpAddress
                MailboxType = $mailboxType
                Delegate    = $_.User
                AccessType  = "FullAccess"
            })
        }

    # ==================================================
    # Send As permissions
    # ==================================================
    Get-RecipientPermission -Identity $mbx.Identity |
        Where-Object {
            $_.AccessRights -contains "SendAs" -and
            $_.Trustee -notlike "NT AUTHORITY\*"
        } |
        ForEach-Object {
            $Results.Add([PSCustomObject]@{
                Mailbox     = $mbx.PrimarySmtpAddress
                MailboxType = $mailboxType
                Delegate    = $_.Trustee
                AccessType  = "SendAs"
            })
        }

    # ==================================================
    # Send On Behalf permissions
    # ==================================================
    foreach ($delegate in $mbx.GrantSendOnBehalfTo) {
        $Results.Add([PSCustomObject]@{
            Mailbox     = $mbx.PrimarySmtpAddress
            MailboxType = $mailboxType
            Delegate    = $delegate.Name
            AccessType  = "SendOnBehalf"
        })
    }
}

# ==================================================
# Export results
# ==================================================
$Results |
    Sort-Object Mailbox, AccessType |
    Export-Csv -Path "ExchangeOnline_Mailbox_Delegation_Report.csv" `
        -NoTypeInformation `
        -Encoding UTF8

Write-Host "Mailbox delegation report exported successfully."
