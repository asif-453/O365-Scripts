Function Force-WSUSCheckin {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Computer
    )

    Write-Host "Starting Windows Update service on $Computer..."
    Invoke-Command -ComputerName $Computer -ScriptBlock { Start-Service wuauserv -Verbose }

    # Run update session via PsExec as SYSTEM to avoid access denied
    $Cmd = '$updateSession = New-Object -ComObject Microsoft.Update.Session; $updateSearcher = $updateSession.CreateUpdateSearcher(); $updates = $updateSearcher.Search("IsInstalled=0").Updates; $updates.Count'

    Write-Host "Running Update Searcher COM object via PsExec on $Computer..."
    & c:\bin\psexec.exe -s \\$Computer powershell.exe -command $Cmd

    Write-Host "Waiting 10 seconds for update sync to complete..."
    Start-Sleep -Seconds 10

    Write-Host "Triggering update detection and reporting commands on $Computer..."
    Invoke-Command -ComputerName $Computer -ScriptBlock {
        wuauclt /detectnow
        (New-Object -ComObject Microsoft.Update.AutoUpdate).DetectNow()
        wuauclt /reportnow
        Start-Process -FilePath "c:\windows\system32\UsoClient.exe" -ArgumentList "startscan" -NoNewWindow
    }

    Write-Host "WSUS check-in forced on $Computer."
}

# === Call the function here, replace with your target computer ===
Force-WSUSCheckin -Computer "localhost"
