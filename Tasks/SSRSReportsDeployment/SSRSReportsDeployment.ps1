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