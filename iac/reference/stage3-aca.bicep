// Stage 3 - Azure Container Apps with CPU + HTTP autoscale rules, 0.5 vCPU / 1Gi
// Deploy: az deployment group create -g $RG -f stage3-aca.bicep -p acrName=$ACR acrPassword=$ACR_PASS lawName=$LAW
param location string = 'eastus'
param environmentName string = 'myapp-aca-env'
param containerAppName string = 'myapp-aca'
param acrName string
param imageName string = 'myapp:1.0'
@secure()
param acrPassword string
@description('Existing Log Analytics workspace in this resource group')
param lawName string
param cpu string = '0.5'
param memory string = '1Gi'
param minReplicas int = 0
param maxReplicas int = 4

var loginServer = '${acrName}.azurecr.io'

resource law 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
  name: lawName
}

resource env 'Microsoft.App/managedEnvironments@2024-03-01' = {
  name: environmentName
  location: location
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: law.properties.customerId
        sharedKey: law.listKeys().primarySharedKey
      }
    }
  }
}

resource app 'Microsoft.App/containerApps@2024-03-01' = {
  name: containerAppName
  location: location
  properties: {
    managedEnvironmentId: env.id
    configuration: {
      activeRevisionsMode: 'Single'
      ingress: {
        external: true
        targetPort: 80                 // the starter image listens on 80
        transport: 'auto'
        allowInsecure: false
      }
      registries: [
        {
          server: loginServer
          username: acrName
          passwordSecretRef: 'acr-password'
        }
      ]
      secrets: [
        { name: 'acr-password', value: acrPassword }
      ]
    }
    template: {
      containers: [
        {
          name: 'myapp'
          image: '${loginServer}/${imageName}'
          env: [ { name: 'LEAK_MB', value: '250' } ]
          resources: {
            cpu: json(cpu)
            memory: memory
          }
          probes: [
            {
              type: 'Liveness'
              httpGet: { path: '/healthz', port: 80 }
              periodSeconds: 10
            }
          ]
        }
      ]
      scale: {
        minReplicas: minReplicas
        maxReplicas: maxReplicas
        rules: [
          {
            name: 'cpu-rule'
            custom: {
              type: 'cpu'
              metadata: { type: 'Utilization', value: '70' }
            }
          }
          {
            name: 'http-rule'
            http: {
              metadata: { concurrentRequests: '10' }
            }
          }
        ]
      }
    }
  }
}

output url string = 'https://${app.properties.configuration.ingress.fqdn}'
