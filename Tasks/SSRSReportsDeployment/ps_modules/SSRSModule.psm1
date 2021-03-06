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
        [string]$reportServerUserName,
        [string]$reportServerPassword,
        [bool]$useVerbose
    )    
    begin { }
    process {        
        try {
            $reportServerUrl = "$reportServerUrl/ReportService2010.asmx"
            Write-IfVerbose "Connecting to $reportServerUrl using $reportServerUserName..." -useVerbose $useVerbose

            $webServiceProxyArgs = @{
                Uri                  = $reportServerUrl
                Namespace            = "SSRS.ReportingService2010" 
                UseDefaultCredential = $true
                Class                = "SSRS"
            };
            if ($reportServerAuthenticationMode -eq "windows") {
                [System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }

                $reportServerSecurePassword = ConvertTo-SecureString $reportServerPassword -AsPlainText -Force
                $windowsCredential = New-Object System.Management.Automation.PSCredential ("$reportServerUserName", $reportServerSecurePassword)

                $webServiceProxyArgs.Remove("UseDefaultCredential")
                $webServiceProxyArgs.Add("Credential", $windowsCredential)
            }
            
            $rsClient = New-WebServiceProxy @webServiceProxyArgs

            if (!$rsClient) {
                Write-Error "Error while connecting to reporting server at $reportServerUrl"
                exit -1
            }
            $rsClient.Url = $reportServerUrl
            Write-Host "Connected to $reportServerUrl using $reportServerUserName"
            return $rsClient;
        }
        catch [System.Exception] {
            Write-Error "Error connecting report server $reportServerUrl. Msg: '$($_.Exception.Message)'"
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
            Write-IfVerbose "Creating folder $reportFolder in $reportPath folder." -useVerbose $useVerbose
            $rsClient.CreateFolder($reportFolder, $reportPath, $null) | out-null
            Write-Host "Created folder $reportFolder in $reportPath folder."
        }
        catch [System.Web.Services.Protocols.SoapException] {
            if ($_.Exception.Detail.InnerText -match "rsItemAlreadyExists400") {
                Write-Host "$reportFolder folder already exists."
            }
            else {
                Write-Error  "Error creating folder: $reportFolder. Msg: '$($_.Exception.Message)'"
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
        [string][parameter(Mandatory = $true)]$connectString,
        [string][parameter(Mandatory = $true)]$authenticationMode,
        [string]$userName,
        [string]$password,
        [bool]$useVerbose
    )
    begin { }
    process {
        try {
            Write-IfVerbose "Creating/Updating datasource $dataSourceName in $reportFolderPath folder." -useVerbose $useVerbose

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
                $definition.Extension = "SQL"
            }
            $reportDataSource = $rsClient.CreateDataSource($dataSourceName, $reportFolderPath, $true, $definition, $null)
           
            Write-IfVerbose "Created/Updated datasource $dataSourceName in $reportFolderPath folder." -useVerbose $useVerbose

            return $reportDataSource
        }
        catch [System.IO.IOException] {
            Write-Error "Error creating/updating datasource: $reportFolder. Msg: '$($_.Exception.Message)'"
            exit -1
        }
    }
    end { }
}

function DeleteReport() {
    param (
        [System.Web.Services.Protocols.SoapHttpClientProtocol][parameter(Mandatory = $true)]$rsClient,
        [parameter(Mandatory = $true)]$reportPath,
        [bool]$useVerbose
    )
    begin { }
    process { 
        try {
            Write-IfVerbose "Deleting $reportPath report." -useVerbose $useVerbose
            $rsClient.DeleteItem($reportPath)
            Write-Host "Deleted $reportPath report"
        }
        catch [System.Web.Services.Protocols.SoapException] {
            if ($_.Exception.Message.Contains("ItemNotFoundException")) {
                Write-Warning "Not found $reportPath report."
            }
            else {
                Write-Error "Error while deleting $reportPath report. Msg: '$($_.Exception.Message)'"
            }
        }
    }
    end { }
}

function CreateReport() {
    param (
        [System.Web.Services.Protocols.SoapHttpClientProtocol][parameter(Mandatory = $true)]$rsClient,
        [SSRS.ReportingService2010.CatalogItem[]][parameter(Mandatory = $true)]$reportDataSource,
        [parameter(Mandatory = $true)]$reportFile,
        [string][parameter(Mandatory = $true)]$reportFolder,
        [bool]$cleanUpload,
        [bool]$useVerbose
    )
    begin { }
    process {
        try {

            if ($cleanUpload -eq $true) {
                DeleteReport -rsClient $rsClient -reportPath "$reportFolder/$($reportFile.BaseName)" -useVerbose $useVerbose
            }

            Write-IfVerbose "Uploading report $reportFile to $reportFolder folder." -useVerbose $useVerbose
            $warnings = $null
            $bytes = Get-Content $reportFile.FullName -encoding byte
            $report = $rsClient.CreateCatalogItem("Report", $reportFile.BaseName, $reportFolder, $true, $bytes, $null, [ref]$warnings)

            Write-IfVerbose "Assigning data source $($reportDataSource.Name) to $($report.Name)." -useVerbose $useVerbose

            $reportDataSources = $rsClient.GetItemDataSources($report.Path)
            foreach ($itemDataSource in $reportDataSources) {
                $itemDataSource.Item = New-Object -TypeName ("SSRS.ReportingService2010.DataSourceReference")
                $itemDataSource.Item.Reference = $reportDataSource.Path
            }
            $rsClient.SetItemDataSources($report.Path, $reportDataSources)

            Write-Host "Uploaded report $($report.Path)"
            for ($i = 0; $i -lt $warnings.Length; $i++) {
                if ($warnings[$i].Code -notmatch "rsDataSourceReferenceNotPublished") {
                    Write-Warning "$($warnings[$i].Severity) : $($warnings[$i].Code) - $($warnings[$i].Message)"
                }
            }
        }
        catch [System.IO.IOException] {
            Write-Error "Error creating/updating report: $reportFolder. Msg: '$($_.Exception.Message)'"
        }
    }
    end { }
}

function CreateReportsInFolder () {
    param(
        [System.Web.Services.Protocols.SoapHttpClientProtocol][parameter(Mandatory = $true)]$rsClient,
        [SSRS.ReportingService2010.CatalogItem[]][parameter(Mandatory = $true)]$reportDataSource,
        [string][parameter(Mandatory = $true)]$reportFolderPath,
        [string][parameter(Mandatory = $true)]$reportFolder, 
        [string][parameter(Mandatory = $true)]$reportPath,
        [bool]$cleanUpload,
        [bool]$useVerbose
    )
    begin { }
    process {
        
        $rdlFiles = Get-ChildItem $reportFolderPath -Filter *.rdl
        Write-IfVerbose "Filtered rdl files and found $($rdlFiles.Count) report(s)." -useVerbose $useVerbose

        if ($rdlFiles.Count -eq 0) {
            Write-Warning "No reports found in $reportFolder folder."
            return
        }

        if ($reportPath -eq '/') {
            $reportCompletePath = "$reportPath$reportFolder"
        }
        else {
            $reportCompletePath = "$reportPath/$reportFolder" 
        }
        Write-IfVerbose "Creating reports from $reportCompletePath." -useVerbose $useVerbose
        foreach ($rdlfile in $rdlFiles) {
            CreateReport -rsClient $rsClient -reportDataSource $reportDataSource -reportFile $rdlfile -reportFolder $reportCompletePath -cleanUpload $cleanUpload -useVerbose $useVerbose
        }
        Write-IfVerbose "Created reports from $reportCompletePath." -useVerbose $useVerbose
    }    
    end { }
}