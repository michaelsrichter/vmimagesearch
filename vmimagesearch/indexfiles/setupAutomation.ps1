
########################################################################################################################################################
# EDIT THESE VALUES
$updateIndexDefinitionOnly = $false									#Keep false if this is the first time you're running this.
$createNewStorageAccount = $true									#Change to false if you want to re-use an existing Storage account
$searchApiKey = "YOURSEARCHSERVICEAPIKEY"							#Get this from the Search Service you created in the Azure Portal
$searchName = "YOURSEARCHSERVICENAME"								#Get this from the Search Service you created in the Azure Portal
$user = "ADMIN@YOURDEFAULTTENANT.COM"								#create a global admin in your default AAD tenant specifically for azure automation.
$pw = ConvertTo-SecureString "ADMINPASSWORD" -AsPlainText -Force	#update this with the password for your automation admin.
########################################################################################################################################################

########################################################################################################################################################
# EDIT THIS IF YOU WANT A DIFFERENT NAME OR USING AN EXISTING STORAGE ACCOUNT
$storageAccountName = "vmimagesearch"
########################################################################################################################################################

$location = "East US"   #the Azure region all your assets will be hosted in.
$automationAccountName = "vmimagesearchIndexAutomate" #the Name of your automation account
$automationAccountRunbookName = "AddtoSearchIndex" #the name of the runbook that will execute in your automation account.
$runbookDefinitionPath = Join-Path($PSScriptRoot) addIndex.ps1 # $PSScriptRoot is a built-in variable that returns the executing script's directory.
$indexDefinitionFilePath = Join-Path($PSScriptRoot) indexDefinition.json  #the index definition that your search service will use.
$scheduleName = "4 Hour Index Update"
$credName = "automation user" #do not change this, it is referenced in the addIndex file.


$cred = New-Object –TypeName System.Management.Automation.PSCredential –ArgumentList $user, $pw

$oldverbose = $VerbosePreference
$VerbosePreference = "continue"

$storageInfo = @{
       "CreateNew"=$createNewStorageAccount;
       "StorageAccountName"=$storageAccountName; 
       "StorageAccountKey"="";
       "ContainerName"="index-definition";
       "BlobName"="indexDefinition.json"
       }
$params = @{ "searchApiKey"=$searchApiKey; #update this with the key from your search service.
             "searchName"=$searchName;                      #update this with the name of your search service.
             "indexName"="imageindex";
             "storageInfo"= $storageInfo}

# If you want to create a new storage account, make sure it is set to TRUE
if ($storageInfo.CreateNew){
    New-AzureStorageAccount -StorageAccountName $storageInfo.StorageAccountName -Label $storageInfo.StorageAccountName -Location $location -Type Standard_LRS
    Write-Verbose ("Created new Storage Account " + $storageInfo.StorageAccountName)
}
    $storageInfo.StorageAccountKey = (Get-AzureStorageKey -StorageAccountName $storageInfo.StorageAccountName).Primary
    $ctx = New-AzureStorageContext -StorageAccountName $storageInfo.StorageAccountName -StorageAccountKey $storageInfo.StorageAccountKey
    
    New-AzureStorageContainer -Context $ctx -Name $storageInfo.ContainerName -Permission Off
    Write-Verbose ("Added new Storage Container " + $storageInfo.ContainerName)
    Set-AzureStorageBlobContent -Context $ctx  -Container $storageInfo.ContainerName -File $indexDefinitionFilePath  -Blob $storageInfo.BlobName
    Write-Verbose ("Added blobl for " + $storageInfo.BlobName)
    

if (!$updateIndexDefinitionOnly) {
	New-AzureAutomationAccount -Name $automationAccountName -Location $location
	Write-Verbose ("added automation account: " + $automationAccountName)
	#this is your AUTOMATIONCREDENTIAL that you will need in your Runbook
	$cred = New-Object –TypeName System.Management.Automation.PSCredential –ArgumentList $user, $pw
	New-AzureAutomationCredential -AutomationAccountName $automationAccountName -Name $credName -Value $cred
	Write-Verbose ("added automation credential: " + $credName)
	New-AzureAutomationRunbook -AutomationAccountName $automationAccountName -Name $automationAccountRunbookName
	Write-Verbose ("added automation runbook: " + $automationAccountRunbookName)
	Set-AzureAutomationRunbook -AutomationAccountName $automationAccountName -Name $automationAccountRunbookName -LogVerbose $true
	Write-Verbose ("set runbook to log verbose")
	Set-AzureAutomationRunbookDefinition -AutomationAccountName $automationAccountName -Name $automationAccountRunbookName -Path $runbookDefinitionPath -Overwrite
	Write-Verbose ("set runbook definition")
	Publish-AzureAutomationRunbook -AutomationAccountName $automationAccountName -Name $automationAccountRunbookName
	Write-Verbose ("published runbook")
	New-AzureAutomationSchedule -AutomationAccountName $automationAccountName -Name $scheduleName -HourInterval 4 -StartTime (Get-Date).AddMinutes(6)
	Write-Verbose ("created runbook schedule")
	Register-AzureAutomationScheduledRunbook `
		-AutomationAccountName $automationAccountName `
		-Name $automationAccountRunbookName `
		-ScheduleName $scheduleName `
		-Parameters $params
}
Write-Verbose ("registered runbook with schedule and parameters")
$VerbosePreference = $oldverbose