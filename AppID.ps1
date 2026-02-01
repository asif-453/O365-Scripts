<#
.SYNOPSIS
Collects application registration data, owners, and cross-tenant details via Microsoft Graph using interactive GUI authentication.

.NOTES
Requires Microsoft.Graph module.
Install via: Install-Module Microsoft.Graph -Scope CurrentUser
#>

# ---------------------------
# Function to decode JWT token
# ---------------------------
function Parse-JWTtoken {
    param (
        [Parameter(Mandatory = $true)]
        [string]$token
    )

    $tokenParts = $token.Split(".")
    if ($tokenParts.Count -lt 2) {
        throw "Invalid token format"
    }

    $decoded = [System.Text.Encoding]::UTF8.GetString(
        [System.Convert]::FromBase64String(
            $tokenParts[1].Replace('-', '+').Replace('_', '/').PadRight(
                ($tokenParts[1].Length + 3) - (($tokenParts[1].Length + 3) % 4), '='
            )
        )
    )

    return ($decoded | ConvertFrom-Json)
}

# ---------------------------
# Connect to Microsoft Graph (GUI Auth)
# ---------------------------
Write-Host "Connecting to Microsoft Graph... please sign in via GUI window." -ForegroundColor Cyan

Connect-MgGraph -Scopes "Directory.Read.All","AuditLog.Read.All","Reports.Read.All","Application.Read.All","CustomSecAttributeAssignment.Read.All","CrossTenantInformation.ReadBasic.All"

$graphContext = Get-MgContext
$token = $graphContext.AccessToken

# If AccessToken is empty, try fallback using the Graph SDK context
if ([string]::IsNullOrEmpty($token)) {
    try {
        $token = (Get-MgGraphAccessToken -ErrorAction Stop)
    }
    catch {
        Write-Warning "Access token not available via Get-MgContext. Ensure your Microsoft.Graph module is updated."
        Write-Warning "Run: Update-Module Microsoft.Graph"
    }
}

if ([string]::IsNullOrEmpty($token)) {
    Write-Error "❌ Failed to obtain Graph access token. Please reconnect using Connect-MgGraph."
    return
}

$authHeader = @{ 'Authorization' = "Bearer $token" }

try {
    $tokenobj = Parse-JWTtoken -token $token
}
catch {
    Write-Warning "Could not parse JWT token (non-critical): $_"
}

Write-Host "Connected as: $($graphContext.Account)" -ForegroundColor Green
Write-Host "Tenant ID: $($graphContext.TenantId)" -ForegroundColor DarkGray

# ---------------------------
# Retrieve applications
# ---------------------------
Write-Host "Retrieving applications..." -ForegroundColor Cyan

try {
    $applications = @()
    $uri = "https://graph.microsoft.com/v1.0/applications"
    do {
        $response = Invoke-RestMethod -Uri $uri -Headers $authHeader -Method Get -ErrorAction Stop
        $applications += $response.value
        $uri = $response.'@odata.nextLink'
    } while ($uri)
}
catch {
    Write-Error "Failed to retrieve applications: $_"
    exit
}

Write-Host "Retrieved $($applications.Count) applications." -ForegroundColor Green

# ---------------------------
# Process each application
# ---------------------------
$results = @()

foreach ($app in $applications) {
    $owners = @()
    $spDetails = @()
    $crossTenantInfo = @()

    # Retrieve owners
    try {
        $ownerUri = "https://graph.microsoft.com/v1.0/applications/$($app.id)/owners"
        $ownerResponse = Invoke-RestMethod -Uri $ownerUri -Headers $authHeader -Method Get -ErrorAction Stop
        foreach ($owner in $ownerResponse.value) {
            $owners += $owner.displayName
        }
    }
    catch {
        Write-Verbose "Failed to retrieve owners for ${app.displayName}: $_"
    }

    # Retrieve service principal
    try {
        $spUri = "https://graph.microsoft.com/v1.0/servicePrincipals?`$filter=appId eq '$($app.appId)'"
        $spResponse = Invoke-RestMethod -Uri $spUri -Headers $authHeader -Method Get -ErrorAction Stop
        foreach ($sp in $spResponse.value) {
            $spDetails += $sp.displayName
        }
    }
    catch {
        Write-Verbose "Failed to retrieve servicePrincipal ${spID}: $_"
    }

    # Retrieve cross-tenant access info (if any)
    try {
        $crossUri = "https://graph.microsoft.com/v1.0/policies/crossTenantAccessPolicy/partners"
        $crossResponse = Invoke-RestMethod -Uri $crossUri -Headers $authHeader -Method Get -ErrorAction SilentlyContinue
        if ($crossResponse.value) {
            foreach ($partner in $crossResponse.value) {
                $crossTenantInfo += $partner.id
            }
        }
    }
    catch {
        Write-Verbose "Failed to retrieve cross-tenant information for ${app.displayName}: $_"
    }

    $results += [PSCustomObject]@{
        ApplicationName   = $app.displayName
        AppId             = $app.appId
        ObjectId          = $app.id
        Owners            = ($owners -join ", ")
        ServicePrincipals = ($spDetails -join ", ")
        CrossTenantIDs    = ($crossTenantInfo -join ", ")
    }
}

# ---------------------------
# Export results
# ---------------------------
$timestamp = (Get-Date).ToString("yyyyMMdd_HHmmss")
$outfile = "AzureAppInventory_$timestamp.csv"
$results | Export-Csv -Path $outfile -NoTypeInformation -Encoding UTF8

Write-Host "`nReport saved to: $outfile" -ForegroundColor Green
