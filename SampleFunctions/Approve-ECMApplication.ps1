
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
# Define variables
[string]$SCCMSiteServer = (Get-PowerCFGConfig).ProviderMachineName
[string]$SiteCode = (Get-PowerCFGConfig).SiteCode
[string]$SourceServer = (Get-PowerCFGConfig).SourceServer
[string]$Namespace = "root\SMS\site_$($SiteCode)"

$requestID = "RequestID" # Replace with the request ID you want to approve

# WMI Namespace for SCCM
$namespace = "root\SMS\site_$siteCode"

# Query the User Application Request
$request = Get-WmiObject -Namespace $namespace -Class SMS_UserApplicationRequest -ComputerName $SCCMSiteServer | Where-Object { $_.RequestID -eq $requestID }

if ($request)
{
	# Approve the request by setting the ApprovalState property
	$request.ApprovalState = 1 # 1 is the value for 'Approved'
	$request.Put() # Commit the changes
	
	Write-Host "Request ID '$requestID' has been approved."
}
else
{
	Write-Host "Request ID '$requestID' not found."
}