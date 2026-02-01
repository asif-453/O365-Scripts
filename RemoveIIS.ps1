# Define a list of IIS-related features to disable and remove
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

# Disable and remove features silently without forced restart
foreach ($feature in $iisFeatures) {
    Disable-WindowsOptionalFeature -Online -FeatureName $feature -Remove -NoRestart -ErrorAction SilentlyContinue | Out-Null
}


