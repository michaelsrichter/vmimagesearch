workflow AddtoSearchIndex {
    
    Param
    (
        [Parameter(Mandatory=$true)]
        [string]
        $searchApiKey,

        [Parameter(Mandatory=$true)]
        [string]
        $indexName,

        [Parameter(Mandatory=$true)]
        [string]
        $searchName,

        #Easier to package up all the storage info to retrtieve the index template.
        [Parameter(Mandatory=$true)]
        [object]
        $storageInfo,

        [Parameter(Mandatory=$false)]
        [string]
        $apiVersion="2015-02-28"
    )

    #turn on verbose so that I can see what's going on.
    $oldverbose = $VerbosePreference
    $VerbosePreference = "continue"

            #use the AUTOMATIONCREDENTIAL name you specified in the automation setup file. 
    	    $cred = Get-AutomationPSCredential -Name 'automation user'
	        $acct = Add-AzureAccount -Credential $cred

    
    #construct the URLs I'll be using to delete the existing index (if exists), create a new one, and populate it. 
    $apiKey = $searchApiKey
    $searchPrefix = $searchName
    $indexUrl = "https://" + $searchPrefix + ".search.windows.net/indexes/" + $indexName + "?api-version=" + $apiVersion
    $indexDocsUrl = $indexUrl -replace $indexName, ($indexName + "/docs/index")

    #create a temp path to hold my json file
    $objectJsonTempFile = [io.path]::GetTempFileName() 


    #this function gets the index definition/template file from Azure storage.
    function get-indexDefinition($storageInfo){
        $ContainerName = $storageInfo.ContainerName
        $StorageAccountName = $storageInfo.StorageAccountName
        $StorageAccountKey = $storageInfo.StorageAccountKey
        $BlobName = $storageInfo.BlobName
        $Ctx = New-AzureStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey

        #List all blobs in a container.
        $indexDefTemp = [io.path]::GetTempFileName() 
        Get-AzureStorageBlob -Container $ContainerName -Context $Ctx -Blob $BlobName | Get-AzureStorageBlobContent -Destination $indexDefTemp -Force -WarningAction Continue
        $indexDefText = [IO.File]::ReadAllText($indexDefTemp)
        return $indexDefText
    }


    #call the function to get the index definition
    $indexDefGet = get-indexDefinition -storageInfo $storageInfo
    Write-Verbose ("Got the Search Index definition from " + $storageInfo.ContainerName + "/" + $storageInfo.BlobName)

    #replace the INDEXNAME token in the definition with the actual index name
    $indexDef = $indexDefGet[1] -replace "INDEXNAME", $indexName


    #using an inlinescript was required because the New-Object functionality wouldn't work otherwise.
    inlineScript {
        #get a list of public images and customer images.
        $images = Get-AzureVMImage
        Write-Verbose ("Found " + $images.Count + " Azure VM Images.")

        #for each image found, I need to modify some of the fields I am interested in to save them as docs for an Azure Search Index.
        $images | ForEach-Object { 
             if ($_.PublishedDate -ne $null) {
             Add-Member -Inp $_ PublishedDateFormatted  ($_.PublishedDate).ToString("yyyy-MM-ddTHH:mm:ssZ");
             } else {
             Add-Member -Inp $_ PublishedDateFormatted  ((Get-Date).AddYears(-5)).ToString("yyyy-MM-ddTHH:mm:ssZ");
             };
             Add-Member -Inp $_ SearchId ($_.ImageName).Replace(".","_")  }
        $imageItems = $images | Select-Object -Property ImageName, OS, LogicalSizeInGB, Category, Location, Label, Description, ImageFamily, PublishedDateFormatted, SmallIconUri, RecommendedVMSize, SearchId, PublisherName
        
        #all the docs need to be in a "value" property of an object that gets submitted to the Azure Search REST API.
        $object = New-Object -TypeName psobject -Property @{ value = $imageItems }

        Write-Verbose ("Saved " + $images.Count + " Azure VM Images as search items.")

        #I need to save the object to disk so that I can change it's encoding to ascii which the REST API requires.
        $objectJson = $object | ConvertTo-Json -Compress | Out-File -Encoding ascii $using:objectJsonTempFile
    
        Write-Verbose ("Saved Azure Images as JSON to " + $using:objectJsonTempFile)
    }


    try {
     #Delete current index - try/catch block in case this is a brand new index - deleting an index that doesn't exist results in error
     $requestDeleteIndex= Invoke-RestMethod -Headers @{"Content-Type"="application/json" ; "api-key"=$apiKey } -Method Delete -Uri $indexUrl
     Write-Verbose ("Deleted existing index for " + $indexName )
     }
    catch {
            $errorMessage = $_
            Write-Verbose ("Problem deleting existing index " + $indexName + " or the index didn't exist. Error = " + $errorMessage)
        }
     Finally {
            $ErrorActionPreference = "Continue"
        }

     #create index
     $requestAddIndex = Invoke-RestMethod -Headers @{"Content-Type"="application/json" ; "api-key"=$apiKey } -Method Put -Uri $indexUrl -Body $indexDef
     Write-Verbose ("Created index " + $indexName)

     #add documents to index
     $requestAddIndexDocs = Invoke-RestMethod -Headers @{"Content-Type"="application/json" ; "api-key"=$apiKey } -Method Post -Uri $indexDocsUrl -Body (Get-Content $objectJsonTempFile -Raw)
     Write-Verbose ("Populated index " + $indexName)

     #reset verbose preference
     $VerbosePreference = $oldverbose
}