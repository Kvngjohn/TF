
# Terraform Azure POC

This repository contains a small Terraform proof-of-concept to create a Windows VM and networking in Azure.

## Repo layout

```
TF/
 ├─ providers.tf        # AzureRM provider (reads ARM_* env vars)
 ├─ main.tf             # RG, VNet, Subnet, NSG, Public IP, NIC, Windows VM
 ├─ variables.tf        # Defaults and configurable variables
 └─ envs/
     └─ dev.tfvars      # Example variable overrides (no secrets)
.github/
 └─ workflows/
     └─ terraform.yml   # GitHub Actions: plan + gated apply (environment: dev)
```

## Prerequisites

* Terraform ≥ 1.6 (1.6.x recommended)
* Azure subscription with permissions to create the listed resources

---

## Authentication options

### 1) Local development (either CLI or SP)

**Option A — Azure CLI (interactive)**

```powershell
az login
# If you have many subscriptions/tenants:
az account list --output table
az account set --subscription "<SUBSCRIPTION-ID-OR-NAME>"
```

Then run Terraform (no extra env needed if your `providers.tf` keeps using envs; CLI can still be useful for ad-hoc az commands).

**Option B — Service Principal (non-interactive)**

```powershell
# Create SP scoped to your subscription or a single RG (least privilege recommended)
$sub="<SUBSCRIPTION_ID>"
$rg="<RESOURCE_GROUP_NAME>"       # optional; if used, scope to the RG
$scope="/subscriptions/$sub"      # or "/subscriptions/$sub/resourceGroups/$rg"

$sp = az ad sp create-for-rbac `
  --name "tf-rim-sp" `
  --role Contributor `
  --scopes $scope `
  --sdk-auth | ConvertFrom-Json

# Set env vars for Terraform AzureRM provider
$env:ARM_CLIENT_ID        = $sp.clientId
$env:ARM_CLIENT_SECRET    = $sp.clientSecret
$env:ARM_TENANT_ID        = $sp.tenantId
$env:ARM_SUBSCRIPTION_ID  = $sp.subscriptionId
```

> The provider in `TF/providers.tf` reads **ARM_*** variables. No credentials are hard-coded.

---

## Running Terraform locally (PowerShell)

```powershell
Set-Location -Path 'F:\Terraform\TF'

# Initialize (local state by default)
terraform init

# Validate syntax
terraform validate

# Create a plan using your environment file
terraform plan -var-file="envs/dev.tfvars" -out=tfplan

# If the plan looks good:
terraform apply tfplan

# Optional: backup local state (if not using remote backend)
terraform state pull | Out-File -FilePath '..\tfstate-backup-$(Get-Date -Format "yyyy-MM-ddTHH-mm-ssZ").tfstate' -Encoding utf8

# Destroy when done
terraform destroy -var-file="envs/dev.tfvars"
```

### Example `envs/dev.tfvars`

```hcl
project_name        = "rim-poc"
location            = "eastus2"
address_space       = "10.20.0.0/16"
subnet_prefix       = "10.20.1.0/24"
allow_rdp_from_cidr = "x.x.x.x/32"     # <-- YOUR public IP; do NOT leave 0.0.0.0/0
vm_size             = "Standard_B2ms"
admin_username      = "azureadmin"
# admin_password   comes from TF_VAR_admin_password in CI (don’t put it here)
tags = {
  environment = "dev"
  owner       = "iac"
}
```

---

## GitHub Actions CI/CD

1. **Repository secrets** (Settings → Secrets and variables → Actions)

   * `AZURE_CREDENTIALS` — JSON from `az ad sp create-for-rbac --sdk-auth`
   * `ARM_CLIENT_ID`
   * `ARM_CLIENT_SECRET`
   * `ARM_TENANT_ID`
   * `ARM_SUBSCRIPTION_ID`
   * `ADMIN_PASSWORD` — Windows VM admin password (Terraform reads via `TF_VAR_admin_password`)

2. **Environment**
   Create an environment named **`dev`** (Settings → Environments → New environment `dev`).
   Optionally add required reviewers—`terraform-apply` is gated on this environment.

3. **Workflow triggers**

   * Push/PR to `main` runs **plan** and uploads `tfplan` as an artifact.
   * Approving the **`dev`** environment allows the **apply** job to run.
   * The workflow is already configured to **skip apply if no changes** (via detailed exit code).

---

## Optional (recommended): Remote state in Azure Storage

1. Create (once):

```powershell
az group create -n az-rim-eu2-tf -l westeurope
az storage account create -g az-rim-eu2-tf -n azrimeu2tfstatedev --sku Standard_LRS --kind StorageV2
az storage container create --account-name azrimeu2tfstatedev -n tfstate
```

2. Give the SP **Storage Blob Data Contributor** on the storage account.

3. In `TF/providers.tf`, uncomment the backend block:

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "az-rim-eu2-tf"
    storage_account_name = "azrimeu2tfstatedev"
    container_name       = "tfstate"
    key                  = "dev/winvm.tfstate"
  }
}
```

4. Re-init (locally or in CI):

```powershell
terraform init -reconfigure
```

The backend also uses `ARM_*` env vars (no access keys needed).

---

## Security notes

* **RDP exposure**: Use your `/32` public IP in `allow_rdp_from_cidr`. For production, prefer **Azure Bastion**, VPN, or a jump host and remove the Public IP from the VM.
* **Secrets**: Never commit passwords or state with secrets. Use GitHub Secrets and a remote backend.
* **Least privilege**: Scope the SP to a single RG when possible instead of the whole subscription.

---

## Troubleshooting

**“No subscription found” (local)**

* Ensure you’re in the correct tenant: `az login --tenant <tenant-id>`
* Set the subscription: `az account set --subscription "<id or name>"`
* If you don’t have one, ask for access or create/enable a subscription.

**Provider registration errors**
Some resource types need provider registration. Register at subscription scope as needed:

```powershell
az provider list --query "[?registrationState!='Registered'].{Ns:namespace,State:registrationState}" -o table
az provider register --namespace Microsoft.Network
az provider register --namespace Microsoft.Compute
az provider register --namespace Microsoft.KeyVault
# ...etc
```

**State lock / contention**

* The workflow uses a concurrency group to avoid overlapping runs.
* You can add `-lock-timeout=300s` (already included in CI) for busy backends.

## Git quick start

```powershell
cd F:\Terraform
git init
git remote add origin https://github.com/<your-user-or-org>/<repo>.git
git add .
git commit -m "Initial POC"
git branch -M main
git push -u origin main
```