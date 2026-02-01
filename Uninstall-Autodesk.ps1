# Define the ODIS Installer path
$odISInstaller = "C:\Program Files\Autodesk\AdODIS\V1\Installer.exe"

# List of hardcoded uninstall strings and associated metadata files
$uninstallCommands = @(
    # AutoCAD LT 2024 - English
    @{ ProductName = "AutoCAD LT 2024 - English"; 
       Command = "-q -i uninstall --trigger_point system -m C:\ProgramData\Autodesk\ODIS\metadata\{4558A64D-DFA2-3773-BF42-92414FF3F3DF}\bundleManifest.xml -x C:\ProgramData\Autodesk\ODIS\metadata\{4558A64D-DFA2-3773-BF42-92414FF3F3DF}\SetupRes\manifest.xsd" },

    # Autodesk AutoCAD LT 2024.1.2 Update
    @{ ProductName = "Autodesk AutoCAD LT 2024.1.2 Update"; 
       Command = "-q -i uninstall --trigger_point system -m C:\ProgramData\Autodesk\ODIS\metadata\{DCFF793F-C5E8-3435-97FB-E92D0F5B9EFD}\bundleManifest.xml -x C:\ProgramData\Autodesk\ODIS\metadata\{DCFF793F-C5E8-3435-97FB-E92D0F5B9EFD}\SetupRes\manifest.xsd" },

    # Autodesk DWG TrueView 2024 - English
    @{ ProductName = "Autodesk DWG TrueView 2024 - English"; 
       Command = "-q -i uninstall --trigger_point system -m C:\ProgramData\Autodesk\ODIS\metadata\{9C02048D-D0DB-3E06-B903-89BD24380AAD}\bundleManifest.xml -x C:\ProgramData\Autodesk\ODIS\metadata\{9C02048D-D0DB-3E06-B903-89BD24380AAD}\SetupRes\manifest.xsd" },

    # Autodesk Genuine Service
    @{ ProductName = "Autodesk Genuine Service"; 
       Command = "-q -i uninstall --trigger_point system -m C:\ProgramData\Autodesk\ODIS\metadata\{D207E870-6397-417E-B7DD-720BFBE589A3}\bundleManifest.xml -x C:\ProgramData\Autodesk\ODIS\metadata\{D207E870-6397-417E-B7DD-720BFBE589A3}\SetupRes\manifest.xsd" },

    # Autodesk Identity Manager
    @{ ProductName = "Autodesk Identity Manager"; 
       Command = "-q -i uninstall --trigger_point system -m C:\ProgramData\Autodesk\ODIS\metadata\{8E133591-B0FD-4DB0-B60E-FB593CAF72B0}\bundleManifest.xml -x C:\ProgramData\Autodesk\ODIS\metadata\{8E133591-B0FD-4DB0-B60E-FB593CAF72B0}\SetupRes\manifest.xsd" },

    # Autodesk Material Library 2023
    @{ ProductName = "Autodesk Material Library 2023"; 
       Command = "-q -i uninstall --trigger_point system -m C:\ProgramData\Autodesk\ODIS\metadata\{8E133591-B0FD-4DB0-B60E-FB593CAF72B0}\bundleManifest.xml -x C:\ProgramData\Autodesk\ODIS\metadata\{8E133591-B0FD-4DB0-B60E-FB593CAF72B0}\SetupRes\manifest.xsd" },

    # Autodesk Material Library Base Resolution Image Library 2023
    @{ ProductName = "Autodesk Material Library Base Resolution Image Library 2023"; 
       Command = "-q -i uninstall --trigger_point system -m C:\ProgramData\Autodesk\ODIS\metadata\{3B564A94-BA47-4E42-ACD6-B5C35291210B}\bundleManifest.xml -x C:\ProgramData\Autodesk\ODIS\metadata\{3B564A94-BA47-4E42-ACD6-B5C35291210B}\SetupRes\manifest.xsd" },

    # Autodesk Save to Web and Mobile
    @{ ProductName = "Autodesk Save to Web and Mobile"; 
       Command = "-q -i uninstall --trigger_point system -m C:\ProgramData\Autodesk\ODIS\metadata\{AC9D2EAD-0DA0-4E0B-8672-546F5B1E6E73}\bundleManifest.xml -x C:\ProgramData\Autodesk\ODIS\metadata\{AC9D2EAD-0DA0-4E0B-8672-546F5B1E6E73}\SetupRes\manifest.xsd" },

    # Autodesk Single Sign On Component
    @{ ProductName = "Autodesk Single Sign On Component"; 
       Command = "-q -i uninstall --trigger_point system -m C:\ProgramData\Autodesk\ODIS\metadata\{50645519-0F31-4E92-B590-C806EA1A60A4}\bundleManifest.xml -x C:\ProgramData\Autodesk\ODIS\metadata\{50645519-0F31-4E92-B590-C806EA1A60A4}\SetupRes\manifest.xsd" }
)

# Loop through the hardcoded uninstall commands and run silent uninstallation
foreach ($uninstallCommand in $uninstallCommands) {
    $productName = $uninstallCommand.ProductName
    $command = $uninstallCommand.Command

    Write-Host "Starting uninstallation for: $productName"

    # Execute the uninstall command silently
    Start-Process -FilePath $odISInstaller -ArgumentList $command -Wait -NoNewWindow

    Write-Host "Silent uninstallation completed for: $productName"
}

Start-Process -FilePath "msiexec.exe" -ArgumentList "/X{D207E870-6397-417E-B7DD-720BFBE589A3} /quiet /norestart" -Wait -NoNewWindow

Start-Process -FilePath "msiexec.exe" -ArgumentList "/X{E03EC70C-079C-4B5D-86D1-75759A46ED71} /quiet /norestart" -Wait -NoNewWindow

Start-Process -FilePath "msiexec.exe" -ArgumentList "/X{8E133591-B0FD-4DB0-B60E-FB593CAF72B0} /quiet /norestart" -Wait -NoNewWindow

Start-Process -FilePath "msiexec.exe" -ArgumentList "/X{3B564A94-BA47-4E42-ACD6-B5C35291210B} /quiet /norestart" -Wait -NoNewWindow

Start-Process -FilePath "msiexec.exe" -ArgumentList "/X{AC9D2EAD-0DA0-4E0B-8672-546F5B1E6E73} /quiet /norestart" -Wait -NoNewWindow

Start-Process -FilePath "msiexec.exe" -ArgumentList "/X{50645519-0F31-4E92-B590-C806EA1A60A4} /quiet /norestart" -Wait -NoNewWindow

Start-Process "C:\Program Files\Autodesk\AdskIdentityManager\uninstall.exe" -ArgumentList "--mode unattended" -Verb RunAs -NoNewWindow -Wait



Write-Host "All specified Autodesk products have been silently uninstalled."
