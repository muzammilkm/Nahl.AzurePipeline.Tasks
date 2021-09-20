# SSRS Reports Deployment
Deploy/Publish your reports & data source (rdl & rds) files.

**Supports**
- Uploading reports along with folder structure.
- Create and Configure data source by passing tfs variables.
- Modify the data source of reports as they deploy.
- Environment specific folders.
- TLS Support.

## Parameters ##

**Reports Folder Path**
    Path in which rdl files are located & all these reports will be assigned to new data source.

**Report Server Url**
    SSRS Server Url, should be https and SSRS Server url excluding /ReportService2010.asmx.

**Report Server Authentication Mode**
    Authentication mode with which to connect to SSRS server by default it is `Default Credentials` which is TFS agent user.

**Target Folder**
    Folder in whichh reports would be uploaded & Data Source would be created.

[More Details on Parameters](https://github.com/muzammilkm/Nahl.AzurePipeline.Tasks/wiki/SSRS-Reports-Deployment-Parameters)

**Preview**
![Preview of SSRS Reports Deployment Extension](https://raw.githubusercontent.com/muzammilkm/Nahl.AzurePipeline.Tasks/main/screenshots/SSRSReportsDeployment-preview.png "Preview of SSRS Reports Deployment Extension")