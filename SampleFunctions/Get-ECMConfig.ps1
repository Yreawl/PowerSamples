Function Get-ECMConfig
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
		$AppCatalogDistributionPointGroup = Read-Host "Please enter your application catalog distribution point group [$($DefaultName)]."
		if ($AppCatalogDistributionPointGroup.Length -eq 0) { $AppCatalogDistributionPointGroup = "$($DefaultName)" }
		
		$OSDDefaultName = "OSD distribution points"
		$OSDDistributionPointGroup = Read-Host "Please enter your OSD distribution point group [$($OSDDefaultName)]."
		if ($OSDDistributionPointGroup.Length -eq 0) { $OSDDistributionPointGroup = "$($OSDDefaultName)" }
		
		$DefaultName = "Application Catalog"
		$AppCatalogCollection = Read-Host "Please enter your application catalog collection. [$($DefaultName)]."
		if ($AppCatalogCollection.Length -eq 0) { $AppCatalogCollection = "$($DefaultName)" }
		
		$PowerCFGExport = New-Object psobject -Property @{
			"SiteCode"		      = "$($SiteCode)"
			"ProviderMachineName" = "$($ProviderMachineName)"
			"SourceServer"	      = "$($SourceServer.trim())"
			"DriverSourceServer"  = "$($DriverSourceServer)"
			"AppCatalogDistributionPointGroup" = "$($AppCatalogDistributionPointGroup)"
			"OSDDistributionPointGroup" = "$($OSDDistributionPointGroup)"
			"AppCatalogCollection" = "$($AppCatalogCollection)"
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
				$AppCatalogDistributionPointGroup = Read-Host "Please enter your application catalog distribution point group [$($DefaultName)]."
				if ($AppCatalogDistributionPointGroup.Length -eq 0) { $AppCatalogDistributionPointGroup = "$($DefaultName)" }
				$UpdateFile = $True
			}
			while ($AppCatalogDistributionPointGroup.Length -eq 0)
		}
		Else
		{
			$AppCatalogCollection = $JsonPowerCFGData.AppCatalogDistributionPointGroup
		}
		
		if ($JsonPowerCFGData.AppCatalogCollection.Length -eq 0)
		{
			$DefaultName = "Application Catalog"
			$AppCatalogCollection = Read-Host "Please enter your application catalog copllection. [$($DefaultName)]."
			if ($AppCatalogCollection.Length -eq 0) { $AppCatalogCollection = "$($DefaultName)" }
			$UpdateFile = $True
		}
		Else
		{
			$AppCatalogCollection = "$($JsonPowerCFGData.AppCatalogCollection)"
		}
		if ($UpdateFile)
		{
			$JsonPowerCFGData = New-Object psobject -Property @{
				"SiteCode"		      = "$($SiteCode)"
				"ProviderMachineName" = "$($ProviderMachineName)"
				"SourceServer"	      = "$($SourceServer.trim())"
				"DriverSourceServer"  = "$($DriverSourceServer)"
				"AppCatalogDistributionPointGroup" = "$($AppCatalogDistributionPointGroup)"
				"OSDDistributionPointGroup" = "$($OSDDistributionPointGroup)"
				"AppCatalogCollection" = "$($AppCatalogCollection)"
				"RootDomain"		  = "$($RootDomain)"
			}
			
			$JsonPowerCFGData | ConvertTo-Json | Out-File "$($ConfigPath)\$($ConfigFile)" -Force
		}
	}
	Initialize-PowerCFGObjects
	Return $JsonPowerCFGData
}

$Config = Get-ECMConfig
Write-host "ProviderMachineName: $($Config.ProviderMachineName)"
Write-host "SiteCode: $($Config.SiteCode)"
Write-host "SourceServer: $($Config.SourceServer)"