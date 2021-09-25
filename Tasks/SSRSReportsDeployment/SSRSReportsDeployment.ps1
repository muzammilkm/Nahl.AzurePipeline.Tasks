[CmdletBinding()]
param ()

$sourceFolder = Get-VstsInput -Name "sourceFolder" -Require
$reportServerUrl = Get-VstsInput -Name "reportServerUrl" -Require
$reportServerAuthenticationMode = Get-VstsInput -Name "reportServerAuthenticationMode" -Require
$reportServerAdminUserName = Get-VstsInput -Name "reportServerAdminUserName"
$reportServerAdminPassword = Get-VstsInput -Name "reportServerAdminPassword"
$targetFolder = Get-VstsInput -Name "targetFolder"
$dataSourceName = Get-VstsInput -Name "dataSourceName" -Require
$dataSourceAuthenticationMode = Get-VstsInput -Name "dataSourceAuthenticationMode" -Require
$dataSourceConnectString = Get-VstsInput -Name "dataSourceConnectString" -Require
$dataSourceUserName = Get-VstsInput -Name "dataSourceUserName"
$dataSourcePassword = Get-VstsInput -Name "dataSourcePassword"
[bool]$useTLS12 = Get-VstsInput -Name "useTLS12" -AsBool
[bool]$useVerbose = Get-VstsInput -Name "useVerbose" -AsBool

Import-Module -Name $PSScriptRoot\ps_modules\SSRSModule.psm1

if ($useTLS12 -eq $true) {
    Write-IfVerbose "Setting TLS 1.2" -useVerbose $useVerbose
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
}

$reportServerDomain = ""
if ($reportServerAuthenticationMode = "default") {
    $reportServerDomain = $env:UserDomain
    $reportServerAdminUserName = $env:UserName
}

Write-IfVerbose "sourceFolder = $sourceFolder" -useVerbose $useVerbose
Write-IfVerbose "reportServerUrl = $reportServerUrl" -useVerbose $useVerbose
Write-IfVerbose "reportServerAuthenticationMode = $reportServerAuthenticationMode" -useVerbose $useVerbose
Write-IfVerbose "reportServerAdminUserName = $reportServerAdminUserName" -useVerbose $useVerbose
if ([System.String]::IsNullOrWhiteSpace($reportServerAdminPassword) -eq $false) {
    Write-IfVerbose "reportServerAdminPassword = ********" -useVerbose $useVerbose
}
Write-IfVerbose "targetFolder = $targetFolder" -useVerbose $useVerbose
Write-IfVerbose "dataSourceName = $dataSourceName" -useVerbose $useVerbose
Write-IfVerbose "dataSourceAuthenticationMode = $dataSourceAuthenticationMode" -useVerbose $useVerbose
Write-IfVerbose "dataSourceConnectString = $dataSourceConnectString" -useVerbose $useVerbose
Write-IfVerbose "dataSourceUserName = $dataSourceUserName" -useVerbose $useVerbose
if ([System.String]::IsNullOrWhiteSpace($dataSourcePassword) -eq $false) {
    Write-IfVerbose "dataSourcePassword = ********" -useVerbose $useVerbose
}

$rsClientArgs = @{
    reportServerUrl                = $reportServerUrl
    reportServerAuthenticationMode = $reportServerAuthenticationMode
    reportServerDomain             = $reportServerDomain
    reportServerUserName           = $reportServerAdminUserName
    reportServerPassword           = $reportServerAdminPassword
    useVerbose                     = $useVerbose
}

$rsClient = CreateClient @rsClientArgs

Write-IfVerbose "Created: Report service client." -useVerbose $useVerbose

Write-IfVerbose "Start creating folders..." -useVerbose $useVerbose

$folderArgs = @{
    rsClient         = $rsClient 
    reportFolderPath = $sourceFolder 
    reportFolder     = $targetFolder 
    reportPath       = "/" 
    forceCreate      = $true 
    useVerbose       = $useVerbose
}

CreateFolder @folderArgs

$dataSourceArgs = @{
    rsClient           = $rsClient 
    reportFolderPath   = /$targetFolder 
    dataSourceName     = $dataSourceName 
    connectString      = $dataSourceConnectString 
    authenticationMode = $dataSourceAuthenticationMode 
    userName           = $dataSourceUserName 
    password           = $dataSourcePassword 
    useVerbose         = $useVerbose
}

$reportDataSource = CreateDataSource @dataSourceArgs

$folderReportArgs = @{
    rsClient         = $rsClient 
    reportDataSource = $reportDataSource 
    reportFolderPath = $sourceFolder 
    reportFolder     = $targetFolder 
    reportPath       = "/" 
    useVerbose       = $useVerbose
}

CreateReportsInFolder @folderReportArgs

foreach ($folder in Get-ChildItem $sourceFolder -Directory) {
    $folderArgs = @{
        rsClient         = $rsClient 
        reportFolderPath = $folder.FullName 
        reportFolder     = $folder.Name 
        reportPath       = /$targetFolder 
        forceCreate      = $false 
        useVerbose       = $useVerbose
    }

    $folderReportArgs = @{
        rsClient         = $rsClient 
        reportDataSource = $reportDataSource 
        reportFolderPath = $folder.FullName 
        reportFolder     = $folder.Name 
        reportPath       = /$targetFolder 
        useVerbose       = $useVerbose
    }

    CreateFolder @folderArgs

    CreateReportsInFolder @folderReportArgs 
}

Write-IfVerbose "Completed uploading reports from folders..." -useVerbose $useVerbose

Write-Host "Task Completed."