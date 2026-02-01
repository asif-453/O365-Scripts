# Start logging to a file
Start-Transcript -Path "C:\Users\sahashmi\Desktop\Scripts\GraphPermissionsLog.txt" -Append

try {
    # Connect with required scopes
    Write-Host "Connecting to Microsoft Graph..."
    Connect-MgGraph -Scopes "Application.ReadWrite.All", "RoleManagement.ReadWrite.Directory" -ErrorAction Stop
    Write-Host "Successfully connected to Microsoft Graph."
} catch {
    Write-Error "Failed to connect to Microsoft Graph: $_"
    pause
    Stop-Transcript
    exit
}

# Variables
$appId = "14d82eec-204b-4c2f-b7e8-296a70dab67e"  # Your Application ID
$graphAppId = "00000003-0000-0000-c000-000000000000"  # Microsoft Graph appId

# Validate appId format
if (-not ($appId -match '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$')) {
    Write-Error "Invalid Application ID format. Please provide a valid GUID."
    pause
    Stop-Transcript
    exit
}

# Permissions you want to add (Application permissions) - Reduced for testing
$requiredPermissions = @(
    "Directory.Read.All",
    "User.Read.All",
    "Group.Read.All"
)

Write-Host "Getting service principals..."

# Get your app's service principal
try {
    $servicePrincipal = Get-MgServicePrincipal -Filter "appId eq '$appId'" -ErrorAction Stop
    if (-not $servicePrincipal) {
        Write-Error "App service principal not found. Check your Application ID."
        pause
        Stop-Transcript
        exit
    }
} catch {
    Write-Error "Error retrieving app service principal: $_"
    pause
    Stop-Transcript
    exit
}

# Get Microsoft Graph service principal
try {
    $graphServicePrincipal = Get-MgServicePrincipal -Filter "appId eq '$graphAppId'" -ErrorAction Stop
    if (-not $graphServicePrincipal) {
        Write-Error "Microsoft Graph service principal not found."
        pause
        Stop-Transcript
        exit
    }
} catch {
    Write-Error "Error retrieving Microsoft Graph service principal: $_"
    pause
    Stop-Transcript
    exit
}

Write-Host "Retrieving permission IDs..."

# Find the AppRole IDs for the required permissions (Application type)
$appRoleIds = @()
$skippedPermissions = @()
foreach ($perm in $requiredPermissions) {
    $appRole = $graphServicePrincipal.AppRoles | Where-Object { $_.Value -eq $perm -and $_.AllowedMemberTypes -contains "Application" }
    if ($appRole) {
        $appRoleIds += $appRole.Id
        Write-Host "Found permission $perm with AppRoleId $($appRole.Id)"
    } else {
        $skippedPermissions += $perm
        Write-Warning "Permission $perm not found or is not an Application permission."
    }
}
if ($skippedPermissions) {
    Write-Host "Skipped permissions: $($skippedPermissions -join ', ')"
}

# Check existing assignments to avoid duplicates
try {
    $existingAssignments = Get-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $servicePrincipal.Id -ErrorAction Stop
    $existingAppRoleIds = $existingAssignments.AppRoleId
} catch {
    Write-Error "Error retrieving existing app role assignments: $_"
    pause
    Stop-Transcript
    exit
}

Write-Host "Assigning permissions..."

foreach ($appRoleId in $appRoleIds) {
    if ($existingAppRoleIds -contains $appRoleId) {
        Write-Host "Permission with AppRoleId $appRoleId is already assigned. Skipping..."
        continue
    }
    try {
        New-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $servicePrincipal.Id `
            -PrincipalId $servicePrincipal.Id `
            -ResourceId $graphServicePrincipal.Id `
            -AppRoleId $appRoleId -ErrorAction Stop
        Write-Host "Assigned AppRoleId $appRoleId successfully."
    } catch {
        Write-Warning "Failed to assign AppRoleId $appRoleId. Error: $_"
    }
}

Write-Host "All permissions assigned. Please grant admin consent in the Azure portal: https://portal.azure.com/#blade/Microsoft_AAD_RegisteredApps/ApplicationMenuBlade/CallAnAPI/appId/$appId"

# Verify assignments
Write-Host "Current permissions assigned to the app:"
try {
    $assignments = Get-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $servicePrincipal.Id -ErrorAction Stop
    if (-not $assignments) {
        Write-Host "No permissions assigned to the app."
    } else {
        $assignments | ForEach-Object {
            $role = $graphServicePrincipal.AppRoles | Where-Object { $_.Id -eq $_.AppRoleId }
            Write-Host " - $($role.Value)"
        }
    }
} catch {
    Write-Warning "Error retrieving final app role assignments: $_"
}

# Stop logging
Stop-Transcript

# Pause to keep the window open
Write-Host "Script completed. Review the output above or check the log file at C:\Users\sahashmi\Desktop\Scripts\GraphPermissionsLog.txt."
pause