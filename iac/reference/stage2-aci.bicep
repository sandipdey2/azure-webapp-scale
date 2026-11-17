// Stage 2 - Azure Container Instances pulling from ACR with admin credentials
// Deploy: az deployment group create -g $RG -f stage2-aci.bicep -p acrName=$ACR acrPassword=$ACR_PASS dnsLabel=$ACI-$RANDOM lawCustomerId=$LAW_CID lawKey=$LAW_KEY
param containerGroupName string = 'myapp-aci'
param location string = 'eastus'
param acrName string
param imageName string = 'myapp:1.0'
param acrUsername string = acrName
@secure()
param acrPassword string
param dnsLabel string
param cpuCores int = 1
param memoryInGB string = '1.5'

@description('Optional Log Analytics workspace customer ID (GUID). Leave empty to skip.')
param lawCustomerId string = ''
@secure()
@description('Optional Log Analytics workspace primary key')
param lawKey string = ''

var loginServer = '${acrName}.azurecr.io'

resource aci 'Microsoft.ContainerInstance/containerGroups@2023-05-01' = {
  name: containerGroupName
  location: location
  properties: {
    osType: 'Linux'
    sku: 'Standard'
    restartPolicy: 'Always'           // restart after OOMKilled so the event is visible
    imageRegistryCredentials: [
      {
        server: loginServer
        username: acrUsername
        password: acrPassword
      }
    ]
    containers: [
      {
        name: 'myapp'
        properties: {
          image: '${loginServer}/${imageName}'
          ports: [ { port: 80, protocol: 'TCP' } ]
          environmentVariables: [ { name: 'LEAK_MB', value: '250' } ]
          resources: {
            requests: {
              cpu: cpuCores
              memoryInGB: json(memoryInGB)
            }
          }
        }
      }
    ]
    ipAddress: {
      type: 'Public'
      dnsNameLabel: dnsLabel
      ports: [ { port: 80, protocol: 'TCP' } ]
    }
    diagnostics: empty(lawCustomerId) ? null : {
      logAnalytics: {
        workspaceId: lawCustomerId
        workspaceKey: lawKey
        logType: 'ContainerInstanceLogs'
      }
    }
  }
}

output fqdn string = aci.properties.ipAddress.fqdn
