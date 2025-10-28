# Replace with your subscription ID
$subscriptionId = "<YOUR_SUBSCRIPTION_ID>"

az ad sp create-for-rbac `
    --name "github-actions-sp" `
    --role "Contributor" `
    --scopes "/subscriptions/$subscriptionId" `
    --sdk-auth
