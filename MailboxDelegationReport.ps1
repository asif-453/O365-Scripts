Connect-ExchangeOnline

$Results = New-Object System.Collections.Generic.List[object]

$mailboxes = Get-Mailbox -ResultSize Unlimited

foreach ($mbx in $mailboxes) {

    $mailboxType = $mbx.RecipientTypeDetails

    # -------- Full Access --------
    Get-MailboxPermission $mbx.Identity |
    Where-Object {
        $_.AccessRights -contains "FullAccess" -and
        $_.User -notlike "NT AUTHORITY\*" -and
        $_.User -notlike "S-1-5*" -and
        $_.IsInherited -eq $false
    } |
    ForEach-Object {
        $Results.Add([PSCustomObject]@{
            Mailbox      = $mbx.PrimarySmtpAddress
            MailboxType  = $mailboxType
            Delegate     = $_.User
            AccessType   = "FullAccess"
        })
    }

    # -------- Send As --------
    Get-RecipientPermission $mbx.Identity |
    Where-Object {
        $_.AccessRights -contains "SendAs" -and
        $_.Trustee -notlike "NT AUTHORITY\*"
    } |
    ForEach-Object {
        $Results.Add([PSCustomObject]@{
            Mailbox      = $mbx.PrimarySmtpAddress
            MailboxType  = $mailboxType
            Delegate     = $_.Trustee
            AccessType   = "SendAs"
        })
    }

    # -------- Send On Behalf --------
    foreach ($delegate in $mbx.GrantSendOnBehalfTo) {
        $Results.Add([PSCustomObject]@{
            Mailbox      = $mbx.PrimarySmtpAddress
            MailboxType  = $mailboxType
            Delegate     = $delegate.Name
            AccessType   = "SendOnBehalf"
        })
    }
}

$Results |
Sort-Object Mailbox, AccessType |
Export-Csv "ExchangeOnline_Mailbox_Delegation_Report.csv" -NoTypeInformation
