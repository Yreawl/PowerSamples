Function Get-PowerCFGConfig
{
	
	<#
	.SYNOPSIS
	
	Checks module json settings and set's them if required. Uses the currently installed SCCM client to identify initial values for Management point and SCCM Site.  
	
	.DESCRIPTION
	
	Checks module json settings and set's them if required. Uses the currently installed SCCM client to identify initial values for Management point and SCCM Site.  
	
	.LINK
	
	https://github.com/Yreawl
	
	.EXAMPLE 
	
	Get-ECMConfig
		
	#>
	
	$StartPath = (Get-Location).path
	$ConfigPath = "C:\ProgramData\PowerCFG\"
	$ConfigFile = "PowerCFG.Settings.json"
	if (!(test-path -Path "$($ConfigPath)\$($ConfigFile)" -ErrorAction SilentlyContinue))
	{
		$DefaultProviderMachineName = "$((Get-CimInstance -NameSpace "Root\CCM" -ClassName SMS_Authority -ErrorAction SilentlyContinue).CurrentManagementPoint)"
		$DefaultProviderMachineName = $DefaultProviderMachineName.trim()
		$DefaultSiteCode = (Get-CimInstance -NameSpace "Root\CCM" -ClassName CCM_Authority -ErrorAction SilentlyContinue).Name | Where-Object { $_ -match "SMS:" -and $_.Length -eq 7 }
		$DefaultSiteCode = ($DefaultSiteCode -replace ("SMS:", "")).Trim()
		Do
		{
			$ProviderMachineName = Read-Host "Please enter your site-server [$($DefaultProviderMachineName)]."
			if ($ProviderMachineName -eq "")
			{
				$ProviderMachineName = "$($DefaultProviderMachineName)"
			}
			$ServerExists = Test-Connection -ComputerName $ProviderMachineName -Count 1 -Quiet
			if (!$ServerExists)
			{
				Write-Host "Cannot find $($ProviderMachineName), please ensure the FQDN is correct"
			}
		}
		while (!$ServerExists)
		$ProviderMachineName = $ProviderMachineName.trim()
		$SiteCode = Read-Host "Please enter your SiteCode [$($DefaultSiteCode.trim())]."
		if ($SiteCode -eq "")
		{
			$SiteCode = "$($DefaultSiteCode)"
		}
		$SiteCode = $SiteCode.trim()
		Do
		{
			$SourceServer = Read-Host "Please enter your source server."
			if ($SourceServer.Length -ne 0)
			{
				$ServerExists = Test-Connection -ComputerName $SourceServer -Count 1 -Quiet
				if (!$ServerExists)
				{
					Write-Host "Cannot find $($SourceServer), please ensure the FQDN is correct"
				}
			}
			Else
			{
				Write-Host "You must add a source server."
				$ServerExists = $false
			}
		}
		While (!$ServerExists)
		$SourceServer = $SourceServer.trim()
		Do
		{
			$DriverSourceServer = Read-Host "Please enter your driver source server [$($SourceServer)]."
			if ($DriverSourceServer.Length -eq 0)
			{
				$DriverSourceServer = "$($SourceServer)"
			}
			
			if ($DriverSourceServer.Length -ne 0)
			{
				$ServerExists = Test-Connection -ComputerName $DriverSourceServer -Count 1 -Quiet
				if (!$ServerExists)
				{
					Write-Host "Cannot find $($DriverSourceServer), please ensure the FQDN is correct"
				}
			}
			Else
			{
				Write-Host "You must add a source server."
				$ServerExists = $false
			}
		}
		While (!$ServerExists)
		$DriverSourceServer.trim()
		
		[ADSI]$RootDSE = "LDAP://RootDSE"
		[Object]$DefaultRootDomain = (New-Object System.DirectoryServices.DirectoryEntry "GC://$($RootDSE.rootDomainNamingContext)").Path
		$DefaultRootDomain = $DefaultRootDomain -replace "GC:", "LDAP:"
		Do
		{
			$RootDomain = Read-Host "Please enter your root AD domain (LDAP) [$($DefaultRootDomain)]."
			if ($RootDomain.Length -eq 0) { $RootDomain = "$($DefaultRootDomain)" }
		}
		while ($RootDomain.Length -eq 0)
		
		
		$DefaultName = "APP Catalog distribution points"
		$ECMApplicationCatalogDistributionPointGroup = Read-Host "Please enter your application catalog distribution point group [$($DefaultName)]."
		if ($ECMApplicationCatalogDistributionPointGroup.Length -eq 0) { $ECMApplicationCatalogDistributionPointGroup = "$($DefaultName)" }
		
		$OSDDefaultName = "OSD distribution points"
		$OSDDistributionPointGroup = Read-Host "Please enter your OSD distribution point group [$($OSDDefaultName)]."
		if ($OSDDistributionPointGroup.Length -eq 0) { $OSDDistributionPointGroup = "$($OSDDefaultName)" }
		
		$DefaultName = "Application Catalog"
		$ECMApplicationCatalogCollection = Read-Host "Please enter your application catalog collection. [$($DefaultName)]."
		if ($ECMApplicationCatalogCollection.Length -eq 0) { $ECMApplicationCatalogCollection = "$($DefaultName)" }
		
		$PowerCFGExport = New-Object psobject -Property @{
			"SiteCode"		      = "$($SiteCode)"
			"ProviderMachineName" = "$($ProviderMachineName)"
			"SourceServer"	      = "$($SourceServer.trim())"
			"DriverSourceServer"  = "$($DriverSourceServer)"
			"AppCatalogDistributionPointGroup" = "$($ECMApplicationCatalogDistributionPointGroup)"
			"OSDDistributionPointGroup" = "$($OSDDistributionPointGroup)"
			"AppCatalogCollection" = "$($ECMApplicationCatalogCollection)"
			"RootDomain"		  = "$($RootDomain)"
		}
		$PowerCFGExport
		new-item -Path "$($ConfigPath)" -ItemType Directory -Force
		$JsonPowerCFGData = $PowerCFGExport | ConvertTo-Json
		$JsonPowerCFGData | Out-File "$($ConfigPath)\$($ConfigFile)" -Force
		$JsonPowerCFGData
	}
	Else
	{
		$JsonPowerCFGData = Get-Content -Path "$($ConfigPath)\$($ConfigFile)" | ConvertFrom-Json
		if ($JsonPowerCFGData.ProviderMachineName.length -eq 0)
		{
			$UpdateFile = $True
			$DefaultProviderMachineName = "$((Get-CimInstance -NameSpace "Root\CCM" -ClassName SMS_Authority -ErrorAction SilentlyContinue).CurrentManagementPoint)"
			$DefaultProviderMachineName = $DefaultProviderMachineName.trim()
			$ProviderMachineName = Read-Host "Please enter your site server [$($DefaultProviderMachineName)]."
			if ($ProviderMachineName -eq "")
			{
				$ProviderMachineName = "$($DefaultProviderMachineName)"
			}
		}
		Else
		{
			$ProviderMachineName = $JsonPowerCFGData.ProviderMachineName
		}
		$ProviderMachineName = $ProviderMachineName.trim()
		if ($JsonPowerCFGData.SiteCode.Length -eq 0)
		{
			$UpdateFile = $True
			$DefaultSiteCode = (Get-CimInstance -NameSpace "Root\CCM" -ClassName SMS_Authority -ErrorAction SilentlyContinue).Name | Where-Object { $_ -match "SMS:" -and $_.Length -eq 7 }
			$DefaultSiteCode = ($DefaultSiteCode -replace ("SMS:", "")).Trim()
			$SiteCode = Read-Host "Please enter your SiteCode [$($DefaultSiteCode.trim())]."
			if ($SiteCode -eq "")
			{
				$SiteCode = "$($DefaultSiteCode)"
			}
		}
		Else
		{
			$SiteCode = $JsonPowerCFGData.SiteCode
		}
		$SiteCode = $SiteCode.Trim()
		if ($JsonPowerCFGData.SourceServer.Length -eq 0)
		{
			$UpdateFile = $True
			$SourceServer = Read-Host "Please enter your Source Server."
		}
		Else
		{
			$SourceServer = $JsonPowerCFGData.SourceServer
		}
		$SourceServer = $SourceServer.Trim()
		if ($JsonPowerCFGData.DriverSourceServer.Length -eq 0)
		{
			$UpdateFile = $True
			Do
			{
				$DriverSourceServer = Read-Host "Please enter your driver source server [$($JsonPowerCFGData.SourceServer)]."
				if ($DriverSourceServer.Length -eq 0)
				{
					$DriverSourceServer = "$($JsonPowerCFGData.SourceServer)"
				}
				
				if ($DriverSourceServer.Length -ne 0)
				{
					$ServerExists = Test-Connection -ComputerName $DriverSourceServer -Count 1 -Quiet
					if (!$ServerExists)
					{
						Write-Host "Cannot find $($DriverSourceServer), please ensure the FQDN is correct"
					}
				}
				Else
				{
					Write-Host "You must add a driver source server."
					$ServerExists = $false
				}
			}
			While (!$ServerExists)
			$DriverSourceServer = $DriverSourceServer.trim()
		}
		if ($JsonPowerCFGData.RootDomain.Length -eq 0)
		{
			[ADSI]$RootDSE = "LDAP://RootDSE"
			[Object]$DefaultRootDomain = (New-Object System.DirectoryServices.DirectoryEntry "GC://$($RootDSE.rootDomainNamingContext)").Path
			$DefaultRootDomain = $DefaultRootDomain -replace "GC:", "LDAP:"
			Do
			{
				$RootDomain = Read-Host "Please enter your root AD domain (LDAP) [$($DefaultRootDomain)]."
				if ($RootDomain.Length -eq 0) { $RootDomain = "$($DefaultRootDomain)" }
				$UpdateFile = $True
			}
			while ($RootDomain.Length -eq 0)
		}
		Else
		{
			$RootDomain = "$($JsonPowerCFGData.RootDomain)"
		}
		
		if ($JsonPowerCFGData.OSDDistributionPointGroup.Length -eq 0)
		{
			Do
			{
				$OSDDefaultName = "OSD distribution points"
				$OSDDistributionPointGroup = Read-Host "Please enter your OSD distribution point group [$($OSDDefaultName)]."
				if ($OSDgDistributionPointGroup.Length -eq 0) { $OSDDistributionPointGroup = "$($OSDDefaultName)" }
				$UpdateFile = $True
			}
			while ($OSDDistributionPointGroup.Length -eq 0)
		}
		Else
		{
			$OSDDistributionPointGroup = $JsonPowerCFGData.OSDDistributionPointGroup
		}
		
		if ($JsonPowerCFGData.AppCatalogDistributionPointGroup.Length -eq 0)
		{
			$DefaultName = "APP Catalog distribution points"
			Do
			{
				$ECMApplicationCatalogDistributionPointGroup = Read-Host "Please enter your application catalog distribution point group [$($DefaultName)]."
				if ($ECMApplicationCatalogDistributionPointGroup.Length -eq 0) { $ECMApplicationCatalogDistributionPointGroup = "$($DefaultName)" }
				$UpdateFile = $True
			}
			while ($ECMApplicationCatalogDistributionPointGroup.Length -eq 0)
		}
		Else
		{
			$ECMApplicationCatalogCollection = $JsonPowerCFGData.AppCatalogDistributionPointGroup
		}
		
		if ($JsonPowerCFGData.AppCatalogCollection.Length -eq 0)
		{
			$DefaultName = "Application Catalog"
			$ECMApplicationCatalogCollection = Read-Host "Please enter your application catalog copllection. [$($DefaultName)]."
			if ($ECMApplicationCatalogCollection.Length -eq 0) { $ECMApplicationCatalogCollection = "$($DefaultName)" }
			$UpdateFile = $True
		}
		Else
		{
			$ECMApplicationCatalogCollection = "$($JsonPowerCFGData.AppCatalogCollection)"
		}
		if ($UpdateFile)
		{
			$JsonPowerCFGData = New-Object psobject -Property @{
				"SiteCode"		      = "$($SiteCode)"
				"ProviderMachineName" = "$($ProviderMachineName)"
				"SourceServer"	      = "$($SourceServer.trim())"
				"DriverSourceServer"  = "$($DriverSourceServer)"
				"AppCatalogDistributionPointGroup" = "$($ECMApplicationCatalogDistributionPointGroup)"
				"OSDDistributionPointGroup" = "$($OSDDistributionPointGroup)"
				"AppCatalogCollection" = "$($ECMApplicationCatalogCollection)"
				"RootDomain"		  = "$($RootDomain)"
			}
			
			$JsonPowerCFGData | ConvertTo-Json | Out-File "$($ConfigPath)\$($ConfigFile)" -Force
		}
	}
	Initialize-PowerCFGObjects
	Return $JsonPowerCFGData
}
function Write-Response
{
	<#
	.DESCRIPTION	
	
	Origionally a private function, Write-Response displays a colour coded message, and optionally records activity to the event log
	
	.SYNOPSIS 
	
	Displays command activity 
	
	.PARAMETER Message
	
	The message to display
	
	.PARAMETER ForegroundColor
	
	Cyan = I'm about to start a cycle on something
	Magenta = I want you to check something
	Red = Something went wrong
	Blue = I am taking an action
	White = Default
	Green = Something worked
	Yellow = something might not have worked
	
	.PARAMETER EventLogName
	
	The name of an event log to store responses.

	.PARAMETER SpeakToMe
	
	Uses System.Speech to vocalise the entry.
	
	.LINK
	
	https://github.com/Yreawl
	
	.EXAMPLE
	
	Write-Response -Message "Started to do something" -ForegroundColor Cyan
	
	.EXAMPLE 
	
	Write-Response -Message "Something Might have gone wrong" -ForegroundColor Yellow
	
	.EXAMPLE 
	
	Write-Response -Message "Something went wrong" -ForegroundColor Red -EventLogName "PowerCFG-module"
		
	.INPUTS
	
	You can NOT pipe module names to this cmdlet.  
	
	.OUTPUTS
	
	None
	
	.NOTES

	#>
	
	param (
		[Parameter(Mandatory = $True)]
		[string]$Message,
		[Parameter(Mandatory = $false)]
		[ValidateSet("Cyan", "Magenta", "Red", "Blue", "White", "Green", "Yellow")]
		[string]$ForegroundColor = "White",
		[Parameter(Mandatory = $false)]
		[string]$EventLogName,
		[Parameter(Mandatory = $false)]
		[Switch]$SpeakToMe
	)
	
	switch ($ForegroundColor)
	{
		"Cyan" {
			Write-Host " - $($Message)" -ForegroundColor $ForegroundColor
			$EventID = "3000"
			$EntryType = "Information"
		}
		"Magenta" {
			Write-Host " - $($Message)" -ForegroundColor $ForegroundColor
			$EventID = "3000"
			$EntryType = "Information"
		}
		"Blue" {
			Write-Host " - $($Message)" -ForegroundColor $ForegroundColor
			$EventID = "3000"
			$EntryType = "Information"
		}
		"White" {
			Write-Host " - $($Message)" -ForegroundColor $ForegroundColor
			$EventID = "3000"
			$EntryType = "Information"
		}
		"Green" {
			Write-Host " - $($Message)" -ForegroundColor $ForegroundColor
			$EventID = "3001"
			$EntryType = "SuccessAudit"
		}
		
		"Red" {
			Write-Host " ->> $($Message)" -ForegroundColor $ForegroundColor
			$EventID = "3666"
			$EntryType = "Error"
		}
		"Yellow" {
			Write-Host " ->> $($Message)" -ForegroundColor $ForegroundColor
			$EventID = "3002"
			$EntryType = "Warning"
		}
		Default { Write-Host "$($Message)" -ForegroundColor Gray }
	}
	if ($EventLogName.Length -ge 8)
	{
		if ([Security.Principal.WindowsIdentity]::GetCurrent().Claims.Value.Contains('S-1-5-32-544'))
		{
			$EventLogFound = [System.Diagnostics.EventLog]::Exists("$EventLogName");
			if (!$EventLogFound)
			{
				New-EventLog -Source "$($EventLogName)" -LogName "$($EventLogName)"
			}
			$EventLogFound = [System.Diagnostics.EventLog]::Exists("$EventLogName");
			if ($EventLogFound -and $EventID -and $EntryType)
			{
				Write-EventLog -LogName $EventLogName -Source "$($EventLogName)" -EventID "$($EventID)" -EntryType $EntryType -Message "$($Message)"
			}
		}
	}
	if ($SpeakToMe)
	{
		Add-Type -AssemblyName System.Speech
		$synth = New-Object -TypeName System.Speech.Synthesis.SpeechSynthesizer
		$synth.Speak("$($Message)")
	}
	
}
function Get-MSIProperties
{
	param (
		[parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[System.IO.FileInfo]$Path,
		[parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[ValidateSet("ProductCode", "ProductVersion", "ProductName", "Manufacturer", "ProductLanguage", "FullVersion", "ARPCONTACT")]
		[string]$Property
	)
	try
	{
		$WindowsInstaller = New-Object -ComObject WindowsInstaller.Installer
		$MSIDatabase = $WindowsInstaller.GetType().InvokeMember("OpenDatabase", "InvokeMethod", $null, $WindowsInstaller, @($Path.FullName, 0))
		$Query = "SELECT Value FROM Property WHERE Property = '$($Property)'"
		$View = $MSIDatabase.GetType().InvokeMember("OpenView", "InvokeMethod", $null, $MSIDatabase, ($Query))
		$View.GetType().InvokeMember("Execute", "InvokeMethod", $null, $View, $null)
		$Record = $View.GetType().InvokeMember("Fetch", "InvokeMethod", $null, $View, $null)
		$Value = $Record.GetType().InvokeMember("StringData", "GetProperty", $null, $Record, 1)
		$MSIDatabase.GetType().InvokeMember("Commit", "InvokeMethod", $null, $MSIDatabase, $null)
		$View.GetType().InvokeMember("Close", "InvokeMethod", $null, $View, $null)
		$MSIDatabase = $null
		$View = $null
	}
	catch
	{
		Write-Response -Message "$($Property) failed with error $($_.Exception.Message)"
	}
	return $Value
}
function Format-ObjectName
{
	param (
		[Parameter(Mandatory = $True)]
		[string]$ObjectName,
		[Parameter(Mandatory = $False)]
		[string]$VendorName
	)
	
	if ($ObjectName -ne $VendorName)
	{
		Write-Response -Message "Cleaning: $($ObjectName)"
		if ($ObjectName -match "7-Zip")
		{
			$ObjectName = "7-Zip"
		}
		elseif ($ObjectName -match "Paint.NET")
		{
			$ObjectName = "Paint.NET"
		}
		Else
		{
			$ObjectName = $ObjectName.Replace("x64", "")
			$ObjectName = $ObjectName.Replace("x86", "")
			$ObjectName = $ObjectName.Replace("64bit", "")
			$ObjectName = $ObjectName.Replace("32bit", "")
			$ObjectName = $ObjectName.Replace("64-bit", "")
			$ObjectName = $ObjectName.Replace("32-bit", "")
			$ObjectName = $ObjectName.Replace("en-US", "")
			$ObjectName = $ObjectName.Replace("edition", "")
			$ObjectName = $ObjectName.Replace("Build of", "")
			$ObjectName = [regex]::Replace($ObjectName, "\s+", " ")
			$ObjectName = $ObjectName -replace ("[^a-zA-Z\d\s:]", "")
		}
		Write-Response -Message "ObjectName: $($ObjectName)"
		if ($ObjectName.trim() -ne $VendorName)
		{
			if ($ObjectName -match "$($VendorName)")
			{
				$ObjectName = $ObjectName -replace ("$($VendorName)", "")
			}
		}
	}
	Write-Response -Message "Returning: $($ObjectName.trim())" -ForegroundColor white
	return $ObjectName.trim()
}
function Add-ECMMSIApplicaiton
{
	param (
		[Parameter(Mandatory = $True)]
		[string]$SourcePath,
		[Parameter(Mandatory = $false)]
		[string]$ArgumentOverride = "/s",
		[Parameter(Mandatory = $false)]
		[string]$PublisherOverride,
		[Parameter(Mandatory = $false)]
		[string]$VersionOverride,
		[Parameter(Mandatory = $false)]
		[string]$NameOverride,
		[Parameter(Mandatory = $false)]
		[Switch]$ApprovalRequired,
		[Parameter(Mandatory = $false)]
		[switch]$Execute
	)
	
	# Define the SCCM site server and namespace
	
	[string]$SCCMSiteServer = (Get-PowerCFGConfig).ProviderMachineName
	[string]$SiteCode = (Get-PowerCFGConfig).SiteCode
	[string]$SourceServer = (Get-PowerCFGConfig).SourceServer
	[string]$Namespace = "root\SMS\site_$($SiteCode)"
	
	# Define application properties
	$ECMApplicationSourceMSI = Get-ChildItem -Path $SourcePath -Filter "*.msi"
	# Grab the application name, Publisher and version from the binary
	if ($NameOverride.length -ne 0)
	{
		[string]$ECMApplicationName = $NameOverride
	}
	Else
	{
		$DiscoveredApplicationName = Get-MSIProperties -Path $ECMApplicationSourceMSI.fullname -Property ProductName
		[string]$ECMApplicationName = Format-ObjectName -ObjectName "$($DiscoveredApplicationName)"
	}
	if ($VersionOverride.length -ne 0)
	{
		[string]$ECMApplicationVersion = $VersionOverride
	}
	Else
	{
		[string]$ECMApplicationVersion = Get-MSIProperties -Path $ECMApplicationSourceMSI.fullname -Property ProductVersion
	}
	if ($PublisherOverride.length -ne 0)
	{
		[string]$ECMApplicationPublisher = $PublisherOverride
	}
	Else
	{
		[string]$OrigionalPublisher = Get-MSIProperties -Path $ECMApplicationSourceMSI.fullname -Property Manufacturer
		if ($OrigionalPublisher -match ",") { $ECMApplicationPublisher = ($OrigionalPublisher -split (","))[0].trim() }
		Else { $ECMApplicationPublisher = $OrigionalPublisher }
	}
	if ($ECMApplicationName.length -eq 0)
	{
		Write-Response -Message "Name not found, use -NameOverride" -ForegroundColor Red
	}
	if ($PublisherOverride.length -eq 0)
	{
		Write-Response -Message "Publisher not found, use -PublisherOverride" -ForegroundColor Red
	}
	if ($ECMApplicationVersion.length -eq 0)
	{
		Write-Response -Message "Version not found, use -VersionOverride" -ForegroundColor Red
	}
	
	[string]$ECMApplicationDescription = "Created through automation by $($env:USERDOMAIN)\$($env:USERNAME) on $(Get-Date)"
	[string]$ECMApplicationContentLocation = "\\$($SourceServer)\Applications\$($ECMApplicationPublisher)\$($ECMApplicationName)\$($ECMApplicationVersion)"
	
	# Create the target path if it does not exist.
	
	$PathExists = Test-Path -Path "$($ECMApplicationContentLocation)" -PathType Container
	if (!$PathExists)
	{
		Try
		{
			New-Item -Path "$($ECMApplicationContentLocation)" -ItemType "directory" -Force -ErrorAction SilentlyContinue | Out-Null
			Write-Response -Message "Created: $($ECMApplicationContentLocation)" -ForegroundColor green
		}
		catch
		{
			Write-Response -Message "$($ECMApplicationContentLocation) NOT created, the error was $($_.Exception.Message)" -ForegroundColor red
			break
		}
	}
	
	# Put the file in the correct target location
	
	Try
	{
		Unblock-File -Path "$($ECMApplicationSourceMSI.FullName)" -ErrorAction SilentlyContinue
		Write-Response -Message "Unblocked: $($ECMApplicationSourceMSI.Name)" -ForegroundColor green
	}
	catch
	{
		Write-Response -Message "Unable to unblock $($ECMApplicationSourceMSI.Name), the error was $($_.Exception.Message)" -ForegroundColor red
		break
	}
	try
	{
		if ($Execute)
		{
			Copy-Item -Path "$($SourcePath)\*" -Destination "$($ECMApplicationContentLocation)" -Recurse -Force
		}
		Write-Response -Message "Copied $($SourcePath)\*"
	}
	catch
	{
		Write-Response -Message "$($SourcePath)\* NOT copied to $($ECMApplicationContentLocation), the error was $($_.Exception.Message)." -ForegroundColor Red
		break
	}
	$ECMApplicationMSI = Get-ChildItem -Path $ECMApplicationContentLocation -Filter "*.msi"
	if ($Execute)
	{
		$ParentFolder = (Get-Item -path "$($ECMApplicationContentLocation)").Parent
	}
	return $ParentFolder.FullName
	
	if ($ArgumentOverride -ne "/s")
	{
		[string]$ECMApplicationInstallCmdLine = "msiexec /i $($ECMApplicationMSI.Name) /quiet $($ArgumentOverride)"
	}
	Else
	{
		[string]$ECMApplicationInstallCmdLine = "msiexec /i $($ECMApplicationMSI.Name) /quiet"
	}
	
	# get the application icon
	# Check icon is valid
	
	$ECMApplicationlicationIcon = Get-ChildItem -Path "\\$($SourceServer)\Source\Icons" -filter "*.png" | where-object { $_.Name -eq "$($RootPath.Name).png" -or $_.Name -eq "$($Manufacturer.trim()).png" -or $_.Name -eq "$($RootPath.Parent.Name).png" } | Select-Object -First 1
	[string]$IconPath = "$($ECMApplicationlicationIcon.FullName)"
	
	
	$Image = [System.Drawing.Image]::FromFile($IconPath)
	$Width = $Image.Width
	$Height = $Image.Height
	
	if ($Width -gt 500 -or $Height -gt 500)
	{
		Write-Response -Message "The image is $Width pixels wide and $Height pixels high." -ForegroundColor Red
		exit
	}
	$Image.Dispose()
	
	$IconBytes = [System.IO.File]::ReadAllBytes($IconPath)
	
	# Connect to the SCCM WMI namespace
	$ECMConnection = Get-WmiObject -Namespace $Namespace -ComputerName $SCCMSiteServer -Query "SELECT * FROM SMS_ProviderLocation WHERE ProviderForLocalSite = true"
	$ECMProvider = $ECMConnection.Machine
	$ECMWMI = [WMIClass] "\\$ECMProvider\$Namespace:SMS_Application"
	
	# Create a new application object
	$ECMApplication = $ECMWMI.CreateInstance()
	
	# Set application properties
	$ECMApplication.LocalizedDisplayName = $ECMApplicationName
	$ECMApplication.LocalizedDescription = $ECMApplicationDescription
	$ECMApplication.Publisher = $ECMApplicationPublisher
	$ECMApplication.SoftwareVersion = $ECMApplicationVersion
	$ECMApplication.Icon = $IconBytes # Assign the icon byte array to the application
	
	# Save the new application
	$ECMApplication.Put()
	
	# Retrieve the application ID
	$ECMApplicationID = $ECMApplication.ModelName
	
	# Define the deployment type properties
	$ECMDeploymentType = ([WmiClass]"\\$ECMProvider\$Namespace:SMS_DeploymentType").CreateInstance()
	$ECMDeploymentType.ApplicationModelName = $ECMApplicationID
	$ECMDeploymentType.ContentSourcePath = $ECMApplicationContentLocation
	$ECMDeploymentType.InstallCommandLine = $ECMApplicationInstallCmdLine
	$ECMDeploymentType.UninstallCommandLine = $ECMApplicationUninstallCmdLine
	$ECMDeploymentType.DeploymentTypeName = "My Test Deployment Type"
	
	# Save the deployment type
	$ECMDeploymentType.Put()
	
	Write-Output "Application '$ECMApplicationName' with ID '$ECMApplicationID' created successfully with an icon."
}