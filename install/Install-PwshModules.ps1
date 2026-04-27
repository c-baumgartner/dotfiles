#Requires -Version 7

Set-PSRepository -Name PSGallery -InstallationPolicy Trusted

$modules = @(
    # Az — core subset
    'Az.Accounts',
    'Az.Resources',
    'Az.Compute',
    'Az.Network',
    'Az.Storage',
    'Az.KeyVault',
    'Az.Monitor',
    'Az.PolicyInsights',

    # Microsoft Graph — core subset
    'Microsoft.Graph.Authentication',
    'Microsoft.Graph.Users',
    'Microsoft.Graph.Groups',
    'Microsoft.Graph.Identity.DirectoryManagement',
    'Microsoft.Graph.Identity.SignIns',
    'Microsoft.Graph.Applications',
    'Microsoft.Graph.Reports'
)

foreach ($module in $modules) {
    if (-not (Get-Module -ListAvailable -Name $module)) {
        Write-Host "Installing $module..."
        Install-Module -Name $module -Scope CurrentUser -Force -AllowClobber
    } else {
        Write-Host "$module already installed — skipping."
    }
}
