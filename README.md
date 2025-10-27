# Terraform Azure POC

This repository contains a small Terraform proof-of-concept to create a Windows VM and networking in Azure.

Quick contents:
- `TF/Providers.tf` - Terraform required version and AzureRM provider (configured to use az CLI by default)
- `TF/main.tf` - Resource definitions (resource group, vnet, subnet, NSG, NIC, public IP, Windows VM)
- `TF/Variables.tf` - Defaults and configurable variables
- `TF/envs/dev.tfvars` - Example variable overrides for the dev environment (DO NOT commit secrets)

Prerequisites
-------------
- Terraform (1.6+ recommended)
- Azure CLI (az)
- An active Azure subscription

Authentication options
----------------------
1) Azure CLI (interactive - recommended for local development)

   - Login:

```powershell
az login
```

   - If your account has access to multiple tenants/subscriptions, set the subscription you want:

```powershell
az account list --output table
az account set --subscription "<SUBSCRIPTION-ID-OR-NAME>"
```

   - Provider in `TF/Providers.tf` uses `use_cli = true`, which tells Terraform to use the `az` login session.

2) Service principal (recommended for CI/CD)

   - Create a service principal and give it role `Contributor` (or narrower roles) on the subscription or resource group.

```powershell
# Example: create SP and capture outputs
$sp = az ad sp create-for-rbac --name "tf-rim-sp" --role Contributor --scopes /subscriptions/<SUBSCRIPTION-ID> --sdk-auth | ConvertFrom-Json
```

   - Set environment variables (PowerShell):

```powershell
$env:ARM_CLIENT_ID = "<client-id>"
$env:ARM_CLIENT_SECRET = "<client-secret>"
$env:ARM_TENANT_ID = "<tenant-id>"
$env:ARM_SUBSCRIPTION_ID = "<subscription-id>"
```

   - Terraform will use these variables for provider authentication.

Don't commit `.tfvars` with secrets. Use `TF/.gitignore` in the repo root (included) to avoid accidental commits.

Running Terraform (PowerShell)
-----------------------------
Open PowerShell and run:

```powershell
Set-Location -Path 'F:\Terraform\TF'
terraform init
terraform validate
terraform plan -var-file="envs/dev.tfvars"
terraform plan -var-file="envs/dev.tfvars" -out=tfplan
# If plan looks good:
terraform apply -var-file="envs/dev.tfvars"
#Using local, backup your state file
terraform state pull | Out-File -FilePath '..\tfstate-backup-$(Get-Date -Format u).tfstate' -Encoding utf8
#Terraform destroy
terraform destroy -var-file="envs/dev.tfvars"
```

Notes on "No subscription" errors
---------------------------------
- If `az login` shows no subscriptions, your account either has no active subscription or the subscription is disabled/expired.
- Check the Azure Portal (https://portal.azure.com) → Subscriptions to confirm.
- If you see a subscription in the Portal but not via CLI, ensure you're logged into the correct tenant (try `az login --tenant <tenant-id>`).
- If you do not have a subscription, create a new one or get invited to an existing subscription and assigned at least a Reader role.

Security
--------
- Replace `allow_rdp_from_cidr` with your public IP/CIDR (or better: use a VPN/private connectivity). The example `envs/dev.tfvars` has a small fix to use `/32`.
- Do not store secrets in the repository. Use a secure secret store or CI secret variables.

Further help
------------
If you want, I can:
- Add a sample Service Principal creation script and a CI example
- Update `Providers.tf` to prefer environment variable auth and include commented examples
- Run `terraform init`/`validate` for you (I can attempt it if Terraform is installed locally or guide you to run the commands)

GitHub Actions / CI notes
-------------------------
If you want to run Terraform in CI using GitHub Actions, follow these steps:

1) Add these repository secrets (Settings → Secrets → Actions):

   - `ARM_CLIENT_ID` — service principal client id
   - `ARM_CLIENT_SECRET` — service principal client secret
   - `ARM_TENANT_ID` — tenant id
   - `ARM_SUBSCRIPTION_ID` — subscription id
   - `ADMIN_PASSWORD` — Windows VM admin password (or pass via Key Vault)

2) Create a GitHub Environment (Settings → Environments) named `production` and add required reviewers for manual approval. The CI workflow uses this environment for the `apply` job so that apply requires explicit approval by reviewers.

3) The repository includes `.github/workflows/terraform.yml` which runs `plan` on push/PR and uploads the plan as an artifact. The `apply` job is protected by the `production` environment — it will wait for an approval before running.

4) If you prefer using the SDK auth JSON, you can store the `AZURE_CREDENTIALS` (the sdk-auth JSON from `az ad sp create-for-rbac --sdk-auth`) as a single secret and use that with `azure/login` as well.

Security reminder: Do not store TF state or raw secrets in the repository. Use the GitHub Secrets store for CI and consider a remote backend (Azure Storage) for state.

# Registering a resource provider is a subscription-scoped operation.
# az provider list --subscription "1244f95f-7fc2-4c47-acfe-130d4ba9344f" --query "[?registrationState!='Registered'].{Namespace:namespace,State:registrationState}" -o table
# az provider register --namespace Microsoft.KeyVault --subscription "1244f95f-7fc2-4c47-acfe-130d4ba9344f"
# repeat for the others...
# az provider show --namespace Microsoft.KeyVault --subscription "1244f95f-7fc2-4c47-acfe-130d4ba9344f" --query "registrationState" -o tsv

#GIT
cd F:\Terraform
git remote add origin https://github.com/<your-user-or-org>/<repo>.git
git branch -M main
git push -u origin main