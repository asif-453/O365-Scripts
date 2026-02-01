<#
.SYNOPSIS
Collects Azure AD (Microsoft Entra ID) application registration metadata using Microsoft Graph.

.DESCRIPTION
Retrieves application registrations, associated owners, related service principals,
and cross-tenant access partner identifiers using Microsoft Graph REST APIs.

Authentication is performed interactively using the Microsoft Graph PowerShell SDK.

.OUTPUTS
Exports a CSV report containing:
- Application name
- App (client) ID
- Object ID
- Owners
- Service principal display names
- Cross-tenant partner IDs

.REQUIREMENTS
- Microsoft.Graph PowerShell module
- Directory.Read.All
- Application.Read.All
- CrossTenantInformation.ReadBasic.All
- Additional read-only scopes as required

.INSTALLATION
Install-Module Microsoft.Graph -Scope CurrentUser

.NOTES
- Script uses REST calls for pagination control and consistency.
- Cross-tenant access policy data is tenant-wide and not application-specific.
- Intended for inventory, audit, and visibility purposes only.
#>

# --------------------------------------------------------------------
# Decode JWT access token to extract context (non-critical, debug only)
# --------------------------------------------------------------------
function Parse-JWTtoken {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Token
    )

    $tokenParts = $Token.Split(".")
    if ($tokenParts.Count -lt 2) {
        throw "Invalid token format"
    }

    $decoded = [System.Text.Encoding]::UTF8.GetString(
        [System.Convert]::FromBase64String(
            $tokenParts[1]
                .Replace('-', '+')
                .Replace('_', '/')
                .PadRight(
                    ($tokenParts[1].Length + 3) - (($tokenParts[1].Length + 3) % 4),
                    '='
                )
        )
    )

    return ($decoded | ConvertFrom-Json)
}

# --------------------------------------------------------------------
# Authenticate to Microsoft Graph using interactive sign-in
# --------------------------------------------------------------------
Write-Host "Connecting to Microsoft Graph (interactive sign-in)..." -ForegroundColor Cyan

Connect-MgGraph -Scopes `
    "Directory.Read.All",
    "AuditLog.Read.All",
    "Reports.Read.All",
    "Application.Read.All",
    "CustomSecAttributeAssignment.Read.All",
    "CrossTenantInformation.ReadBasic.All"

$graphContext = Get-MgContext
$token = $graphContext.AccessToken

# Fallback for older SDK contexts
if ([string]::IsNullOrEmpty($token)) {
    try {
        $token = Get-MgGraphAccessToken -ErrorAction Stop
    }
    catch {
        Write-Warning "Unable to retrieve access token. Ensure Microsoft.Graph module is up to date."
        Write-Warning "Run: Update-Module Microsoft.Graph"
    }
}

if ([string]::IsNullOrEmpty($token)) {
    Write-Error "Failed to obtain Microsoft Graph access token."
    return
}

$authHeader = @{ Authorization = "Bearer $token" }

# Optional token parsing (non-blocking)
try {
    $null = Parse-JWTtoken -Token $token
}
catch {
    Write-Verbose "JWT token parsing failed (non-critical)."
}

Write-Host "Connected account : $($graphContext.Account)" -ForegroundColor Green
Write-Host "Tenant ID        : $($graphContext.TenantId)" -ForegroundColor DarkGray

# --------------------------------------------------------------------
# Retrieve all application registrations (paged)
# --------------------------------------------------------------------
Write-Host "Retrieving application registrations..." -ForegroundColor Cyan

$applications = @()
$uri = "https://graph.microsoft.com/v1.0/applications"

try {
    do {
        $response = Invoke-RestMethod -Uri $uri -Headers $authHeader -Method GET -ErrorAction Stop
        $applications += $response.value
        $uri = $response.'@odata.nextLink'
    } while ($uri)
}
catch {
    Write-Error "Failed to retrieve application registrations: $_"
    return
}

Write-Host "Applications retrieved: $($applications.Count)" -ForegroundColor Green

# --------------------------------------------------------------------
# Retrieve cross-tenant access partner identifiers (tenant-wide)
# Note: This data is global and not tied to individual applications
# --------------------------------------------------------------------
$crossTenantPartnerIds = @()

try {
    $crossUri = "https://graph.microsoft.com/v1.0/policies/crossTenantAccessPolicy/partners"
    $crossResponse = Invoke-RestMethod -Uri $crossUri -Headers $authHeader -Method GET -ErrorAction SilentlyContinue

    if ($crossResponse.value) {
        $crossTenantPartnerIds = $crossResponse.value.id
    }
}
catch {
    Write-Verbose "Cross-tenant access policy retrieval failed."
}

# --------------------------------------------------------------------
# Process each application registration
# --------------------------------------------------------------------
$results = @()

foreach ($app in $applications) {

    $owners = @()
    $servicePrincipals = @()

    # Retrieve application owners
    try {
        $ownerUri = "https://graph.microsoft.com/v1.0/applications/$($app.id)/owners"
        $ownerResponse = Invoke-RestMethod -Uri $ownerUri -Headers $authHeader -Method GET -ErrorAction Stop

        foreach ($owner in $ownerResponse.value) {
            $owners += $owner.displayName
        }
    }
    catch {
        Write-Verbose "Owner lookup failed for application: $($app.displayName)"
    }

    # Retrieve associated service principals using AppId
    try {
        $spUri = "https://graph.microsoft.com/v1.0/servicePrincipals?`$filter=appId eq '$($app.appId)'"
        $spResponse = Invoke-RestMethod -Uri $spUri -Headers $authHeader -Method GET -ErrorAction Stop

        foreach ($sp in $spResponse.value) {
            $servicePrincipals += $sp.displayName
        }
    }
    catch {
        Write-Verbose "Service principal lookup failed for application: $($app.displayName)"
    }

    $results += [PSCustomObject]@{
        ApplicationName   = $app.displayName
        AppId             = $app.appId
        ObjectId          = $app.id
        Owners            = ($owners -join ", ")
        ServicePrincipals = ($servicePrincipals -join ", ")
        CrossTenantIDs    = ($crossTenantPartnerIds -join ", ")
    }
}

# --------------------------------------------------------------------
# Export inventory report
# --------------------------------------------------------------------
$timestamp = (Get-Date).ToString("yyyyMMdd_HHmmss")
$outFile = "AzureAppInventory_$timestamp.csv"

$results | Export-Csv -Path $outFile -NoTypeInformation -Encoding UTF8

Write-Host "Report generated: $outFile" -ForegroundColor Green
