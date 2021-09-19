[CmdletBinding()]
param (
    [Parameter(Mandatory=$True)][string]$sourceFolder,
    [Parameter(Mandatory=$True)][string]$reportServerUrl,
    [Parameter(Mandatory=$True)][string]$reportServerAuthenticationMode,  
    [string]$targetFolder,
    [Parameter(Mandatory=$True)][string]$dataSourceName,
    [Parameter(Mandatory=$True)][string]$dataSourceAuthenticationMode,
    [Parameter(Mandatory=$True)][string]$dataSourceConnectString,
    [string]$dataSourceUserName,
    [string]$dataSourcePassword
)

Write-Verbose "Runninf script SSRSReportsDeployment.ps1" -Verbose
Write-Verbose "sourceFolder = $sourceFolder" -Verbose
Write-Verbose "reportServerUrl = $reportServerUrl" -Verbose
Write-Verbose "reportServerAuthenticationMode  = $reportServerAuthenticationMode" -Verbose
Write-Verbose "targetFolder = $targetFolder" -Verbose
Write-Verbose "dataSourceName = $dataSourceName" -Verbose
Write-Verbose "dataSourceAuthenticationMode = $dataSourceAuthenticationMode" -Verbose
Write-Verbose "dataSourceConnectString = $dataSourceConnectString" -Verbose
Write-Verbose "dataSourceUserName = $dataSourceUserName" -Verbose
Write-Verbose "dataSourcePassword = $dataSourcePassword" -Verbose