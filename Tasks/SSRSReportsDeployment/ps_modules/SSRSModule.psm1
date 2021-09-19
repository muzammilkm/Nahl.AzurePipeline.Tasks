function Write-IfVerbose {
    [cmdletbinding()]
    param(
        [Parameter(Position = 1)]$text,
        [bool] $useVerbose
    )
    if ($useVerbose -eq $true) {
        Write-Host "$text";
    }
}

function CreateClient {
    param (
        [string][parameter(Mandatory = $true)]$reportServerUrl,
        [string]$reportServerAuthenticationMode,
        [string]$reportServerDomain,
        [string]$reportServerUserName,
        [bool]$useVerbose
    )    
    begin { }
    process {        
        try {
            Write-IfVerbose "Connecting to $reportServerUrl using $reportServerDomain\$reportServerUserName..." -useVerbose $useVerbose
            $rsClient = New-WebServiceProxy -Uri $reportServerUrl -Namespace SSRS.ReportingService2010 -UseDefaultCredential -Class "SSRS"
            if (!$rsClient) {
                Write-Error "Error while connecting to reporting server at $reportServerUrl"
                exit -1
            }
            $rsClient.Url = $reportServerUrl
            Write-Host "Connected to $reportServerUrl using $reportServerDomain\$reportServerUserName"
            return $rsClient;
        }
        catch [System.Exception] {
            Write-Error "Error connecting report server $reportServerUrl. Msg: '{0}'" -f $_.Exception.Message
            exit -1
        }
    }
    end { }
}

function CreateFolder() {
    param(
        [System.Web.Services.Protocols.SoapHttpClientProtocol][parameter(Mandatory = $true)]$rsClient,        
        [string][parameter(Mandatory = $true)]$reportFolderPath,
        [string][parameter(Mandatory = $true)]$reportFolder, 
        [string][parameter(Mandatory = $true)]$reportPath,
        [bool]$forceCreate,
        [bool]$useVerbose
    )
    begin {}
    process {
        try {
            if ($forceCreate -eq $false -and (Get-ChildItem $reportFolderPath -Filter *.rdl).Count -eq 0) {
                return;
            }
            Write-IfVerbose "Creating folder $reportFolder in $reportPath" -useVerbose $useVerbose
            $rsClient.CreateFolder($reportFolder, $reportPath, $null) | out-null
            Write-Host "Created folder $reportFolder in $reportPath" -useVerbose $useVerbose
        }
        catch [System.Web.Services.Protocols.SoapException] {
            if ($_.Exception.Detail.InnerText -match "rsItemAlreadyExists400") {
                Write-Host " - Skip (Already exists)"
            }
            else {
                Write-Error  "Error creating folder: $reportFolder. Msg: '{0}'" -f $_.Exception.Detail.InnerText
                exit -1
            }
        }
    }
    end {}
}

function CreateDataSource() {
    param (
        [System.Web.Services.Protocols.SoapHttpClientProtocol][parameter(Mandatory = $true)]$rsClient,
        [string][parameter(Mandatory = $true)]$reportFolderPath,
        [string][parameter(Mandatory = $true)]$dataSourceName,
        [string][parameter(Mandatory = $true)]$dataSourceAuthenticationMode,
        [string][parameter(Mandatory = $true)]$connectString,
        [string][Parameter(Mandatory = $true)]$authenticationMode,
        [string]$userName,
        [SecureString]$password,
        [bool]$useVerbose
    )
    begin { }
    process {
        try {
            Write-IfVerbose "Creating/Updating datasource $dataSourceName in $reportFolderPath" -useVerbose $useVerbose

            $definition = New-Object -TypeName SSRS.ReportingService2010.DataSourceDefinition
            $definition.ConnectString = $connectString
            if ($authenticationMode -eq "sqlServer") {
                $definition.CredentialRetrieval = "Store";
                $definition.Extension = "SQL"
                $definition.UserName = $userName
                $definition.Password = $password
            }
            else {
                $definition.CredentialRetrieval = "Integrated";
            }
            $reportDataSource = $rsClient.CreateDataSource($dataSourceName, $reportFolderPath, $true, $definition, $null)
           
            Write-IfVerbose "Created/Updated datasource $dataSourceName in $reportFolderPath" -useVerbose $useVerbose

            return $reportDataSource
        }
        catch [System.IO.IOException] {
            Write-Error "Error creating/updating datasource: $reportFolder. Msg: '{0}'" -f $_.Exception.Message
            exit -1
        }
    }
    end { }
}

function CreateReport() {
    param (
        [System.Web.Services.Protocols.SoapHttpClientProtocol][parameter(Mandatory = $true)]$rsClient,
        [SSRS.ReportingService2010.CatalogItem[]][parameter(Mandatory = $true)]$rsDataSource,
        [parameter(Mandatory = $true)]$reportFile,
        [string][parameter(Mandatory = $true)]$reportFolder,
        [bool]$useVerbose
    )
    begin { }
    process {
        try {
            Write-IfVerbose "Upload report $reportFile to $reportFolder" -useVerbose $useVerbose

            $bytes = Get-Content $reportFile.FullName -encoding byte
            $report = $rsClient.CreateCatalogItem("Report", $reportFile.BaseName, $reportFolder, $true, $bytes, $null, [ref]$warnings)

            Write-IfVerbose "Assign data source $rsDataSource.Name to $report.Name" -useVerbose $useVerbose

            $reportDataSources = $rs.GetItemDataSources($report.Path)
            foreach ($reportDataSource in $reportDataSources) {
                $reportDataSource.Item = New-Object -TypeName ("SSRS.ReportingService2010.DataSourceReference")
                $reportDataSource.Item.Reference = $rds.Path
            }
            $rs.SetItemDataSources($r.Path, $reportDataSources)

            Write-Host "Uploaded report $report.Name & Assigned data source $rsDataSource.Name" 
        }
        catch [System.IO.IOException] {
            Write-Error "Error creating/updating report: $reportFolder. Msg: '{0}'" -f $_.Exception.Message
        }
    }
    end { }
}

function CreateReportsInFolder () {
    param(
        [System.Web.Services.Protocols.SoapHttpClientProtocol][parameter(Mandatory = $true)]$rsClient,
        [SSRS.ReportingService2010.CatalogItem[]][parameter(Mandatory = $true)]$rsDataSource,
        [string][parameter(Mandatory = $true)]$reportFolderPath,
        [string][parameter(Mandatory = $true)]$reportFolder, 
        [string][parameter(Mandatory = $true)]$reportPath,
        [bool]$useVerbose
    )
    begin { }
    process {
        
        $rdlFiles = Get-ChildItem $reportFolderPath -Filter *.rdl
        Write-IfVerbose "Filtered rdl files and found $rdlFiles.Count" -useVerbose $useVerbose

        if ($rdlFiles.Count -eq 0) {
            Write-Warning "Skip: No reports found in $reportFolder"
            return
        }

        if ($reportPath -eq '/') {
            $reportCompletePath = "$reportPath$reportFolder"
        }
        else {
            $reportCompletePath = "$reportPath/$reportFolder" 
        }
        Write-IfVerbose "Creating reports from $reportCompletePath" -useVerbose $useVerbose
        foreach ($rdlfile in $rdlFiles) {
            CreateReport -rsClient $rsClient 
            -rsDataSource $rsDataSource 
            -reportFile $rdlfile 
            -reportFolder $reportCompletePath
            -useVerbose $useVerbose
        }
    }    
    end { }
}