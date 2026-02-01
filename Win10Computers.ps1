# Import the Active Directory module (only needed if not already loaded)
Import-Module ActiveDirectory

# Get Windows 10 computers
$win10Computers = Get-ADComputer -Filter 'OperatingSystem -like "*Windows 10*"' -Properties Name, OperatingSystem, OperatingSystemVersion, LastLogonTimestamp |
    Select-Object Name,
                  OperatingSystem,
                  OperatingSystemVersion,
                  @{Name="LastLogonDate";Expression={[DateTime]::FromFileTime($_.LastLogonTimestamp)}} |
    Sort-Object LastLogonDate -Descending

# Output to console
$win10Computers

# Optional: Export to CSV
$exportPath = ".\Windows10Computers.csv"
$win10Computers | Export-Csv -Path $exportPath -NoTypeInformation

Write-Host "Exported list to $exportPath" -ForegroundColor Green
