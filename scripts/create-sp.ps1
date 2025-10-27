<#
Creates a service principal scoped to a subscription and prints environment variable snippets for PowerShell, Bash, and GitHub Actions.
Usage:
  # Interactive - uses current az login subscription
  .\create-sp.ps1

  # Provide subscription id and name
  .\create-sp.ps1 -SubscriptionId <sub-id> -Name "tf-rim-sp"

The script writes an sdk-auth JSON to the current directory as: sp-<name>-sdk-auth.json
#>

param(
    [string]$SubscriptionId = "",
    [string]$Name = "tf-rim-sp",
    [switch]$SaveFile
)

function Write-Line { param($text) Write-Output $text }

# Ensure az is available
if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
    Write-Error "Azure CLI (az) not found in PATH. Install Azure CLI before running this script."
    exit 1
}

# If no subscription provided, use current
if ([string]::IsNullOrEmpty($SubscriptionId)) {
    $account = az account show --output json | ConvertFrom-Json
    if (-not $account) {
        Write-Error "No active Azure CLI account. Run 'az login' first or provide -SubscriptionId explicitly."
        exit 1
    }
    $SubscriptionId = $account.id
}

# Create SP with contributor role at subscription scope
Write-Line "Creating service principal '$Name' scoped to subscription $SubscriptionId..."

try {
    $spJson = az ad sp create-for-rbac --name $Name --role "Contributor" --scopes "/subscriptions/$SubscriptionId" --sdk-auth --output json | ConvertFrom-Json
} catch {
    Write-Error "Failed to create service principal: $_"
    exit 1
}

# Print outputs
Write-Line "\nService principal created. Details:\n"
$spJson | ConvertTo-Json -Depth 10

# Write environment variable snippets
$clientId = $spJson.clientId
$clientSecret = $spJson.clientSecret
$tenantId = $spJson.tenantId
$subscriptionId = $SubscriptionId

Write-Line "\nPowerShell environment variables (temporary for the session):"
Write-Line "$($null) `n$env:ARM_CLIENT_ID = \"$clientId\""
Write-Line "$env:ARM_CLIENT_SECRET = \"$clientSecret\""
Write-Line "$env:ARM_TENANT_ID = \"$tenantId\""
Write-Line "$env:ARM_SUBSCRIPTION_ID = \"$subscriptionId\""

Write-Line "\nBash export lines:"
Write-Line "export ARM_CLIENT_ID=\"$clientId\""
Write-Line "export ARM_CLIENT_SECRET=\"$clientSecret\""
Write-Line "export ARM_TENANT_ID=\"$tenantId\""
Write-Line "export ARM_SUBSCRIPTION_ID=\"$subscriptionId\""

Write-Line "\nGitHub Actions secrets (set these in your repository secrets):"
Write-Line "ARM_CLIENT_ID: $clientId"
Write-Line "ARM_CLIENT_SECRET: $clientSecret"
Write-Line "ARM_TENANT_ID: $tenantId"
Write-Line "ARM_SUBSCRIPTION_ID: $subscriptionId"

# Save sdk-auth JSON file for use with some tools (optional)
$sdkFilename = "sp-$Name-sdk-auth.json"
$sdkContent = (ConvertTo-Json $spJson -Depth 10)
Set-Content -Path $sdkFilename -Value $sdkContent -Encoding UTF8
Write-Line "\nSDK auth JSON written to: $sdkFilename"

Write-Line "\nIMPORTANT: Treat these credentials like a secret. Do NOT commit to source control."
Write-Line "You can set these values in CI secrets or export them in your environment before running Terraform."

Write-Line "\nDone."
