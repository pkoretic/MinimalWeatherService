param appServicePlanName string = 'ASP-minimalweatherappcodegroup-a88b'
param webAppName string = 'minimalweatherappcode'
param location string = 'swedencentral'

var tags = {
  Application: 'MinimalWeatherService'
  Environment: 'Development'
}

// App Service Plan
resource appServicePlan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: appServicePlanName
  location: location
  sku: {
    name: 'F1'
    tier: 'Free'
  }
  kind: 'app'
  tags: tags
  properties: {
    reserved: false
  }
}

// Web App
resource webApp 'Microsoft.Web/sites@2023-12-01' = {
  name: webAppName
  location: location
  kind: 'app'
  tags: tags
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      netFrameworkVersion: 'v10.0'
      ftpsState: 'FtpsOnly'
      scmType: 'GitHubAction'
      minTlsVersion: '1.2'
      use32BitWorkerProcess: true
    }
  }
}

// Policies to disable FTP and SCM access
resource ftpPolicies 'Microsoft.Web/sites/basicPublishingCredentialsPolicies@2023-12-01' = {
  parent: webApp
  name: 'ftp'
  properties: {
    allow: false
  }
}

resource scmPolicies 'Microsoft.Web/sites/basicPublishingCredentialsPolicies@2023-12-01' = {
  parent: webApp
  name: 'scm'
  properties: {
    allow: false
  }
}
