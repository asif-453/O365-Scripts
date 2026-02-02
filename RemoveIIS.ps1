<#
.SYNOPSIS
Disables and removes IIS-related Windows optional features.

.DESCRIPTION
Iterates through a predefined list of IIS and WAS features
and removes them silently without forcing a restart.

This is useful for hardening servers or preparing
minimal Windows Server installations.

.NOTES
- Run as Administrator
- No forced restart is performed
- Errors are suppressed silently

#>

# ----------------------------
# List of IIS and WAS features
# ----------------------------
$iisFeatures = @(
    "IIS-WebServerRole",
    "IIS-WebServerManagementTools",
    "IIS-IIS6ManagementCompatibility",
    "IIS-Metabase",
    "IIS-WMICompatibility",
    "IIS-ManagementConsole",
    "IIS-ManagementScriptingTools",
    "IIS-CommonHttpFeatures",
    "IIS-StaticContent",
    "IIS-DefaultDocument",
    "IIS-DirectoryBrowsing",
    "IIS-HttpErrors",
    "IIS-HttpRedirect",
    "IIS-ApplicationDevelopment",
    "IIS-ASP",
    "IIS-ASPNET",
    "IIS-ISAPIExtensions",
    "IIS-ISAPIFilter",
    "IIS-NetFxExtensibility",
    "IIS-ServerSideIncludes",
    "IIS-HealthAndDiagnostics",
    "IIS-HttpLogging",
    "IIS-HttpTracing",
    "IIS-LoggingLibraries",
    "IIS-RequestMonitor",
    "IIS-Performance",
    "IIS-HttpCompressionStatic",
    "IIS-Security",
    "IIS-RequestFiltering",
    "IIS-WindowsAuthentication",
    "WAS-WindowsActivationService",
    "WAS-ProcessModel",
    "WAS-NetFxEnvironment",
    "WAS-ConfigurationAPI"
)

# ----------------------------
# Remove each feature silently
# ----------------------------
foreach ($feature in $iisFeatures) {
    try {
        Disable-WindowsOptionalFeature -Online `
            -FeatureName $feature `
            -Remove `
            -NoRestart `
            -ErrorAction SilentlyContinue | Out-Null
        Write-Host "Removed feature: $feature" -ForegroundColor Green
    }
    catch {
        Write-Warning "Failed to remove feature: $feature"
    }
}

Write-Host "IIS feature removal complete. A restart may be required to finalize changes." -ForegroundColor Cyan
