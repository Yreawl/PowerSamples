Function Create-powercfgObjects
{
	[string]$AppCatalogCollection = (Get-powercfgConfig).AppCatalogCollection
	[string]$AppCatalogDistributionPointGroup = (Get-powercfgConfig).AppCatalogDistributionPointGroup
	[string]$ProviderMachineName = (Get-powercfgConfig).ProviderMachineName
	[string]$SiteCode = (Get-powercfgConfig).SiteCode
	[string]$NameSpace = "root\sms\Site_$($SiteCode)"
	$initParams = @{ }
	$StartPath = (Get-Location).path
	
	Try
	{
		Show-Response -Message "Loading ConfigurationManager" -ForegroundColor Blue
		if ((Get-Module ConfigurationManager) -eq $null)
		{
			Import-Module "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1" @initParams
		}
		if ((Get-PSDrive -Name $SiteCode -PSProvider CMSite -ErrorAction SilentlyContinue) -eq $null)
		{
			New-PSDrive -Name $SiteCode -PSProvider CMSite -Root $ProviderMachineName @initParams | Out-Null
		}
		Show-Response -Message "Complete" -ForegroundColor Green
	}
	Catch
	{
		Show-Response -Message "Could not connect to SCCM, the error was $($_.Exception.Message) you must have the Endpoint Configuation Manager console installed to use this command." -ForegroundColor Red
		if ((get-location).Path -ne $StartPath) { Set-Location $StartPath }
		break
	}
	
	Do
	{
		$DefaultAppCatalogDistributionPointGroup = Get-WmiObject -ComputerName "$($ProviderMachineName)" -Namespace "$($NameSpace)" -class SMS_DistributionPointGroup -filter "Name = '$($AppCatalogDistributionPointGroup)'" -ErrorAction SilentlyContinue
		if ($DefaultAppCatalogDistributionPointGroup.count -eq 0)
		{
			Do
			{
				$CreateGroup = Read-Host "'$($AppCatalogDistributionPointGroup)' does not exist, do you want to create it? [y/n]."
			}
			until ($CreateGroup.tolower() -eq "y" -or $CreateGroup.tolower() -eq "n")
			if ($CreateGroup.tolower() -eq "y")
			{
				if ((get-location).Path -ne "$($SiteCode):\") { Set-Location "$($SiteCode):\" @initParams }
				New-CMDistributionPointGroup -Name "$($AppCatalogDistributionPointGroup)" | Out-Null
				Get-CMDistributionPoint | Add-CMDistributionPointToGroup -DistributionPointGroupName "$($AppCatalogDistributionPointGroup)"
				if ((get-location).Path -ne $StartPath) { Set-Location $StartPath }
				Write-Host "Created $($AppCatalogDistributionPointGroup)"
			}
		}
	}
	while
	($DefaultAppCatalogDistributionPointGroup.Count -eq 0)
	
	Do
	{
		$DefaultAppCatalogCollection = Get-WmiObject -ComputerName "$($ProviderMachineName)" -Namespace "$($NameSpace)" -class SMS_Collection -filter "Name = '$($AppCatalogCollection)'" -ErrorAction SilentlyContinue
		if ($DefaultAppCatalogCollection.count -eq 0)
		{
			Do
			{
				$CreateCollection = Read-Host "'$($AppCatalogCollection)' does not exist, do you want to create it? [y/n]."
			}
			until ($CreateCollection.tolower() -eq "y" -or $CreateCollection.tolower() -eq "n")
			if ($CreateCollection.tolower() -eq "y")
			{
				$Query = "select *  from  SMS_R_User where SMS_R_User.FullUserName != `"Administrator`" and SMS_R_User.FullUserName not like `"svc%`""
				if ((get-location).Path -ne "$($SiteCode):\") { Set-Location "$($SiteCode):\" @initParams }
				New-CMUserCollection -Name "$($AppCatalogCollection)" -LimitingCollectionName "All Users" -RefreshType Continuous | Out-Null
				Add-CMUserCollectionQueryMembershipRule -CollectionName "$($AppCatalogCollection)" -QueryExpression $Query -RuleName "All non ADM users" | out-null
				if ((get-location).Path -ne $StartPath) { Set-Location $StartPath }
				Write-Host "Created $($AppCatalogCollection)"
			}
		}
	}
	while
	($DefaultAppCatalogCollection.Count -eq 0)
}

Create-powercfgObjects