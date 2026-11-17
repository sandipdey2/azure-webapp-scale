// Stage 4 - App Service (Linux container) + staging slot + 30% traffic routing
//           + autoscale 1/3/1 (CPU >70 out, <30 in) + metric alert CPU >90% for 10 min -> email action group
// Deploy: az deployment group create -g $RG -f stage4-appservice.bicep \
//           -p location=$APP_LOC appName=$APP acrName=$ACR alertEmail=PASTE_YOUR_EMAIL
param location string = 'eastus'
param planName string = 'myapp-plan'
param appName string
param acrName string
param prodImage string = 'myapp:1.0'
param stagingImage string = 'myapp:2.0'
param alertEmail string = 'PASTE_YOUR_EMAIL'
@minValue(0)
@maxValue(100)
param stagingTrafficPercent int = 30
param containerPort string = '80'

var loginServer = '${acrName}.azurecr.io'
var acrPullRoleId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')

resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' existing = {
  name: acrName
}

resource plan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: planName
  location: location
  kind: 'linux'
  sku: { name: 'S1', tier: 'Standard', capacity: 1 }   // slots + autoscale need Standard or higher
  properties: { reserved: true }
}

resource site 'Microsoft.Web/sites@2023-12-01' = {
  name: appName
  location: location
  kind: 'app,linux,container'
  identity: { type: 'SystemAssigned' }
  properties: {
    serverFarmId: plan.id
    httpsOnly: true
    clientAffinityEnabled: false        // spread requests across instances for load tests
    siteConfig: {
      linuxFxVersion: 'DOCKER|${loginServer}/${prodImage}'
      acrUseManagedIdentityCreds: true
      alwaysOn: true
      appSettings: [
        { name: 'WEBSITES_PORT', value: containerPort }
        { name: 'WEBSITES_ENABLE_APP_SERVICE_STORAGE', value: 'false' }
      ]
    }
  }
}

resource staging 'Microsoft.Web/sites/slots@2023-12-01' = {
  parent: site
  name: 'staging'
  location: location
  kind: 'app,linux,container'
  identity: { type: 'SystemAssigned' }
  properties: {
    serverFarmId: plan.id
    httpsOnly: true
    clientAffinityEnabled: false
    siteConfig: {
      linuxFxVersion: 'DOCKER|${loginServer}/${stagingImage}'
      acrUseManagedIdentityCreds: true
      alwaysOn: true
      appSettings: [
        { name: 'WEBSITES_PORT', value: containerPort }
        { name: 'WEBSITES_ENABLE_APP_SERVICE_STORAGE', value: 'false' }
      ]
    }
  }
}

// A/B: route a % of production traffic to the staging slot
resource prodWebConfig 'Microsoft.Web/sites/config@2023-12-01' = {
  parent: site
  name: 'web'
  properties: {
    experiments: {
      rampUpRules: [
        {
          name: 'staging'
          actionHostName: '${appName}-staging.azurewebsites.net'
          reroutePercentage: stagingTrafficPercent
        }
      ]
    }
  }
  dependsOn: [ staging ]
}

resource prodAcrPull 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(acr.id, site.id, 'AcrPull')
  scope: acr
  properties: {
    roleDefinitionId: acrPullRoleId
    principalId: site.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

resource stagingAcrPull 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(acr.id, staging.id, 'AcrPull')
  scope: acr
  properties: {
    roleDefinitionId: acrPullRoleId
    principalId: staging.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

resource autoscale 'Microsoft.Insights/autoscalesettings@2022-10-01' = {
  name: '${planName}-autoscale'
  location: location
  properties: {
    enabled: true
    targetResourceUri: plan.id
    profiles: [
      {
        name: 'cpu-profile'
        capacity: { minimum: '1', maximum: '3', default: '1' }
        rules: [
          {
            metricTrigger: {
              metricName: 'CpuPercentage'
              metricNamespace: 'microsoft.web/serverfarms'
              metricResourceUri: plan.id
              timeGrain: 'PT1M'
              statistic: 'Average'
              timeWindow: 'PT5M'
              timeAggregation: 'Average'
              operator: 'GreaterThan'
              threshold: 70
            }
            scaleAction: { direction: 'Increase', type: 'ChangeCount', value: '1', cooldown: 'PT5M' }
          }
          {
            metricTrigger: {
              metricName: 'CpuPercentage'
              metricNamespace: 'microsoft.web/serverfarms'
              metricResourceUri: plan.id
              timeGrain: 'PT1M'
              statistic: 'Average'
              timeWindow: 'PT7M'
              timeAggregation: 'Average'
              operator: 'LessThan'
              threshold: 30
            }
            scaleAction: { direction: 'Decrease', type: 'ChangeCount', value: '1', cooldown: 'PT7M' }
          }
        ]
      }
    ]
  }
}

resource actionGroup 'Microsoft.Insights/actionGroups@2023-01-01' = {
  name: 'ag-cpu-email'
  location: 'global'
  properties: {
    groupShortName: 'cpualert'
    enabled: true
    emailReceivers: [
      { name: 'me', emailAddress: alertEmail, useCommonAlertSchema: true }
    ]
  }
}

resource cpuAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: '${planName}-cpu-over-90'
  location: 'global'
  properties: {
    description: 'App Service plan CPU above 90% (average) for 10 minutes'
    severity: 2
    enabled: true
    scopes: [ plan.id ]
    evaluationFrequency: 'PT1M'
    windowSize: 'PT10M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          criterionType: 'StaticThresholdCriterion'
          name: 'cpu90'
          metricName: 'CpuPercentage'
          metricNamespace: 'microsoft.web/serverfarms'
          operator: 'GreaterThan'
          threshold: 90
          timeAggregation: 'Average'
        }
      ]
    }
    actions: [ { actionGroupId: actionGroup.id } ]
  }
}

output prodUrl string = 'https://${site.properties.defaultHostName}'
output stagingUrl string = 'https://${staging.properties.defaultHostName}'
