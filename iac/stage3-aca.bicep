param containerapps_myapp_aca_name string
param managedEnvironments_myapp_env_name string

resource managedEnvironments_myapp_env_name_resource 'Microsoft.App/managedEnvironments@2026-01-01' = {
  location: 'East US'
  name: managedEnvironments_myapp_env_name
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: '<guid>'
      }
    }
    customDomainConfiguration: {}
    daprConfiguration: {}
    kedaConfiguration: {}
    peerAuthentication: {
      mtls: {
        enabled: false
      }
    }
    peerTrafficConfiguration: {
      encryption: {
        enabled: false
      }
    }
    publicNetworkAccess: 'Enabled'
    workloadProfiles: [
      {
        name: 'Consumption'
        workloadProfileType: 'Consumption'
      }
    ]
    zoneRedundant: false
  }
}

resource containerapps_myapp_aca_name_resource 'Microsoft.App/containerapps@2026-01-01' = {
  identity: {
    type: 'None'
  }
  location: 'East US'
  name: containerapps_myapp_aca_name
  properties: {
    configuration: {
      activeRevisionsMode: 'Single'
      identitySettings: []
      ingress: {
        allowInsecure: false
        exposedPort: 0
        external: true
        targetPort: 80
        traffic: [
          {
            latestRevision: true
            weight: 100
          }
        ]
        transport: 'Auto'
      }
      maxInactiveRevisions: 100
      registries: [
        {
          passwordSecretRef: 'cgacr13672azurecrio-cgacr13672'
          server: 'cgacr13672.azurecr.io'
          username: 'cgacr13672'
        }
      ]
      secrets: [
        {
          name: 'cgacr13672azurecrio-cgacr13672'
        }
      ]
    }
    environmentId: managedEnvironments_myapp_env_name_resource.id
    managedEnvironmentId: managedEnvironments_myapp_env_name_resource.id
    template: {
      containers: [
        {
          image: 'cgacr13672.azurecr.io/myapp:1.0'
          name: containerapps_myapp_aca_name
          resources: {
            cpu: json('0.5')
            memory: '1Gi'
          }
        }
      ]
      scale: {
        cooldownPeriod: 300
        maxReplicas: 4
        minReplicas: 0
        pollingInterval: 30
        rules: [
          {
            http: {
              auth: []
              metadata: {
                concurrentRequests: '10'
              }
            }
            name: 'http-rule'
          }
        ]
      }
    }
    workloadProfileName: 'Consumption'
  }
}
