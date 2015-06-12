Azure VM Image Search
=======

Search through all the built-in Microsoft Azure VM Images
and generate a PowerShell script for deploying VMs. Using
automation, the Search database is updated every few hours.
Searching is easy with fuzzy matching and typeahead features.

**To see a live demo, visit http://vmimagesearch.azurewebsites.net**

This projects demonstrates how to use:
* Azure Search Services
* Azure Automation
* Azure PowerShell Commands
* ASPNET 5 tools (DNX, DNU).

Getting Started
----

### Prerequisites
To get this project working you need the following
* __Azure Account__ If you don't have one already, you can sign up for a [Free Trial](http://azure.microsoft.com/en-us/pricing/free-trial).
* __Azure PowerShell__ Get this from here [How to install and configure Azure PowerShell](https://azure.microsoft.com/en-us/documentation/articles/powershell-install-configure).
Follow the directions to install Azure PowerShell and associate it with your account.
* __Automation Administrator__ Create a global admin in your Azure Active Directory. Azure Automation will run under this account.
Follow the directions to [Create or edit users](https://msdn.microsoft.com/en-us/library/azure/hh967632.aspx) in Azure AD. Choose "New user in your organization" for the global admin. Note the admin's email address and make sure to reset the password to a permanent one. 
* __Azure Search Service Account__ Visit the preview Azure portal at https://portal.azure.com and create a new Search Service. Read [Get Started with Azure Search](https://azure.microsoft.com/en-us/documentation/articles/search-get-started) for more info. Note your search service _name_ and _key_.
* __ASPNET 5__ The website that hosts the image search is written in ASPNET 5. This requires [Visual Studio 2015 RC](https://www.visualstudio.com/en-us/downloads/visual-studio-2015-downloads-vs.aspx) or just install DNX and DNU with ASPNET. See [Getting Started](http://docs.asp.net/en/latest/getting-started)
* __Node.js__, __Bower__ and __Gulp__ If you don't install Visual Studio 2015, you will need to manually install [Node.js](https://nodejs.org/download/) and then Bower and Gulp by running
```batchfile
npm install -g bower
mpm install -g gulp
```  

### Running It

Once you have all the prerequistes, getting up and running is just a few steps.

1. Open the __setupAutomation.ps1__ file and edit the parameters at the top (use the values from the prerequisites). If this is the first time you are running through this, 
leave the first 2 values ($updateIndexDefinitionOnly and $createNewStorageAccount) unchanged.
```powershell
		$updateIndexDefinitionOnly = $false									
		$createNewStorageAccount = $true									
		$searchApiKey = "YOURSEARCHSERVICEAPIKEY"
		$searchName = "YOURSEARCHSERVICENAME"
		$user = "ADMIN@YOURDEFAULTTENANT.COM"
		$pw = ConvertTo-SecureString "ADMINPASSWORD" -AsPlainText -Force
```
2. Run __setupAutomation.ps1__ from any PowerShell commandline.
3. Once setupAutomation completes you will have a new Azure Automation account, a runbook, an automation schedule, and an automation credential.
The workbook will be published and associated with the schedule. The job will run after 5 minutes and then every 4 hours.
4. Set up the web project by going into the root solution folder (the folder that contains _vmimagesearch.sln_) and run:
```batchfile
dnu restore
```
and then, in the vmimagesearch.website folder, run
```batchfile
dnx . web
```
When it says "Started" your ASPNET 5 website is running and you can reach it via http://localhost:5000

### To learn more

* Azure Automation - http://azure.microsoft.com/en-us/services/automation/
* Auzre Search - http://azure.microsoft.com/en-us/services/search/ and https://msdn.microsoft.com/en-us/magazine/dn913187.aspx
* PowerShell - http://blogs.msdn.com/b/powershell/ and https://www.microsoftvirtualacademy.com/en-us/training-courses/getting-started-with-powershell-3-0-jump-start-8276
* ASPNET 5 - http://www.asp.net/ and http://docs.asp.net/en/latest/

### Copyright and License
- Copyright &copy; Microsoft Corporation 2015
- Released under the MIT License (MIT)
- Please see LICENSE for more information.