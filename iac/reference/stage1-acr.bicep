// Stage 1 - Azure Container Registry (reference / fallback; the rubric wants the one EXPORTED from your deployment)
// Deploy: az deployment group create -g $RG -f stage1-acr.bicep -p registryName=$ACR
@description('Globally unique registry name, 5-50 lowercase alphanumerics')
@minLength(5)
@maxLength(50)
param registryName string

param location string = 'eastus'

@allowed([ 'Basic', 'Standard', 'Premium' ])
param sku string = 'Standard'

@description('Admin user is used by ACI/ACA to pull the image with username/password')
param adminUserEnabled bool = true

resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: registryName
  location: location
  sku: {
    name: sku
  }
  properties: {
    adminUserEnabled: adminUserEnabled
    publicNetworkAccess: 'Enabled'
    zoneRedundancy: 'Disabled'          // Availability zones: disabled
    networkRuleBypassOptions: 'AzureServices'
    encryption: {
      status: 'disabled'                // = Microsoft-managed keys (no customer-managed key)
    }
    policies: {
      retentionPolicy: { status: 'disabled', days: 7 }
      trustPolicy: { status: 'disabled', type: 'Notary' }
    }
    // Role assignment permissions mode "RBAC Registry Permissions" is the default, no property needed.
  }
}

output loginServer string = acr.properties.loginServer
output registryId string = acr.id
