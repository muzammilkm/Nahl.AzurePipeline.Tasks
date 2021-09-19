[CmdletBinding()]
param ()

$sourceFolder = Get-VstsInput -Name "sourceFolder" -Require
$reportServerUrl = Get-VstsInput -Name "reportServerUrl" -Require
$reportServerAuthenticationMode = Get-VstsInput -Name "reportServerAuthenticationMode" -Require 
$targetFolder = Get-VstsInput -Name "targetFolder"
$dataSourceName = Get-VstsInput -Name "dataSourceName" -Require
$dataSourceAuthenticationMode = Get-VstsInput -Name "dataSourceAuthenticationMode" -Require
$dataSourceConnectString = Get-VstsInput -Name "dataSourceConnectString" -Require
$dataSourceUserName = Get-VstsInput -Name "dataSourceUserName"
$dataSourcePassword = Get-VstsInput -Name "dataSourcePassword"
$useVerbose = Get-VstsInput -Name "useVerbose"

function Write-IfVerbose {
    [cmdletbinding()]
    param(
        [Parameter(Position = 1)]$text
    )
    if ($UseVerbose -and $UseVerbose -eq $true) {
        Write-Host "$text";
    }
}


Write-IfVerbose "Running script SSRSReportsDeployment.ps1"
Write-IfVerbose "sourceFolder = $sourceFolder"
Write-IfVerbose "reportServerUrl = $reportServerUrl"
Write-IfVerbose "reportServerAuthenticationMode  = $reportServerAuthenticationMode"
Write-IfVerbose "targetFolder = $targetFolder"
Write-IfVerbose "dataSourceName = $dataSourceName"
Write-IfVerbose "dataSourceAuthenticationMode = $dataSourceAuthenticationMode"
Write-IfVerbose "dataSourceConnectString = $dataSourceConnectString"
Write-IfVerbose "dataSourceUserName = $dataSourceUserName"
Write-IfVerbose "dataSourcePassword = $dataSourcePassword"