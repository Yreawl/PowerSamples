function Get-PendingWindowsUpdates
{
<#
	.DESCRIPTION	
	
	Uses the Windows updates API to check for and optionally install all pending windows updates.
	
	.SYNOPSIS 
	
	Displays command activity 
	
	.PARAMETER FixSettings
	
	Restores windows registry settings to default.  
	
	.PARAMETER ForceInstall
	
	Forces the install of pending updates.
		
	.LINK
	
	https://github.com/Yreawl
	
	.EXAMPLE
	
	Write-Host  "Started to do something" -ForegroundColor Cyan
	
	.EXAMPLE 
	
	Write-Host  "Something Might have gone wrong" -ForegroundColor Yellow
	
	.EXAMPLE 
	
	Write-Host  "Something went wrong" -ForegroundColor Red -EventLogName "PowerCFG-module"
		
	.INPUTS
	
	You can NOT pipe module names to this cmdlet.  
	
	.OUTPUTS
	
	None
	
	.NOTES

	#>
	
	param (
		[Parameter(Mandatory = $False)]
		[Switch]$FixSettings,
		[Parameter(Mandatory = $False)]
		[Switch]$ForceInstall
	)
	$PendingReboot = Get-PendingRebootState
	if ($PendingReboot -eq $False)
	{
		if ($FixSettings)
		{
			$WindowsUpdate = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
			$WindowsUpdateAU = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
			
			if (Test-Path $WindowsUpdateAU)
			{
				$NoAutoUpdate = (Get-itemproperty -Path $WindowsUpdateAU -Erroraction SilentlyContinue).NoAutoUpdate
				$UseWUServer = (Get-itemproperty -Path $WindowsUpdateAU -Erroraction SilentlyContinue).UseWUServer
				
				Write-Host "NoAutoUpdate is set to $($NoAutoUpdate)`nUseWUServer is set to $($UseWUServer)"
				
				If ($NoAutoUpdate -ne "0")
				{
					Try
					{
						New-ItemProperty -Path $WindowsUpdateAU -Name NoAutoUpdate -Value "0" -PropertyType DWORD -Force | Out-Null
						Write-Host "NoAutoUpdate changed to 0"
					}
					Catch
					{
						Write-Host "NoAutoUpdate was not changed the error was $($_.Exception.Message)"
					}
				}
				If ($UseWUServer -ne "0")
				{
					Try
					{
						New-ItemProperty -Path $WindowsUpdateAU -Name UseWUServer -Value "0" -PropertyType DWORD -Force | Out-Null
						Write-Host "UseWUServer changed to 0"
					}
					Catch
					{
						Write-Host "UseWUServer was not changed the error was $($_.Exception.Message)"
					}
				}
			}
			if (Test-Path $WindowsUpdate)
			{
				$DisableWindowsUpdateAccess = (Get-itemproperty -Path $WindowsUpdate -Erroraction SilentlyContinue).DisableWindowsUpdateAccess
				$DoNotConnectToWindowsUpdateInternetLocations = (Get-itemproperty -Path $WindowsUpdate -Erroraction SilentlyContinue).DoNotConnectToWindowsUpdateInternetLocations
				$WUServer = (Get-itemproperty -Path $WindowsUpdate -Erroraction SilentlyContinue).WUServer
				$WUStatusServer = (Get-itemproperty -Path $WindowsUpdate -Erroraction SilentlyContinue).WUStatusServer
				
				Write-Host "DisableWindowsUpdateAccess is set to $($DisableWindowsUpdateAccess)`nDoNotConnectToWindowsUpdateInternetLocations is set to $($DoNotConnectToWindowsUpdateInternetLocations)`nWUServer is set to $($WUServer)`nWUStatusServer is set to $($WUStatusServer)"
				
				If ($DisableWindowsUpdateAccess -ne "0")
				{
					Try
					{
						New-ItemProperty -Path $WindowsUpdate -Name DisableWindowsUpdateAccess -Value "0" -PropertyType DWORD -Force | Out-Null
						Write-Host "DisableWindowsUpdateAccess changed to 0"
					}
					Catch
					{
						Write-Host "DisableWindowsUpdateAccess was not changed the error was $($_.Exception.Message)"
					}
				}
				If ($DoNotConnectToWindowsUpdateInternetLocations -ne "0")
				{
					Try
					{
						New-ItemProperty -Path $WindowsUpdate -Name DoNotConnectToWindowsUpdateInternetLocations -Value "0" -PropertyType DWORD -Force | Out-Null
						Write-Host "DoNotConnectToWindowsUpdateInternetLocations changed to 0"
					}
					Catch
					{
						Write-Host "DoNotConnectToWindowsUpdateInternetLocations was not changed the error was $($_.Exception.Message)"
					}
				}
				if ($WUServer)
				{
					Try
					{
						Remove-ItemProperty -Path $WindowsUpdate -Name "WUServer" -ErrorAction SilentlyContinue -Force
						Write-Host "WUServer removed"
					}
					Catch
					{
						Write-Host "WUServer was not removed the error was $($_.Exception.Message)"
					}
				}
				if ($WUStatusServer)
				{
					Try
					{
						Remove-ItemProperty -Path $WindowsUpdate -Name "WUStatusServer" -ErrorAction SilentlyContinue -Force
						Write-Host "WUStatusServer removed"
					}
					Catch
					{
						Write-Host "WUStatusServer was not removed the error was $($_.Exception.Message)"
					}
				}
			}
		}
		$UpdatesList = @()
		$searchcriteria = "isinstalled=0 and type='Software' and IsAssigned=1"
		$msUpdateSession = New-Object -ComObject Microsoft.Update.Session
		$pendingUpdates = $msUpdateSession.CreateupdateSearcher().Search($searchcriteria).Updates
		
		$msUpdateSession = [activator]::CreateInstance([type]::GetTypeFromProgID("Microsoft.Update.Session", $env:COMPUTERNAME))
		$pendingUpdates = $msUpdateSession.CreateUpdateSearcher().Search("isinstalled=0 and type='Software' and IsAssigned=1").Updates
		
		foreach ($pendingUpdate in $pendingUpdates)
		{
			if ($ForceInstall)
			{
				Write-Host "Installing KB$($pendingUpdate.KBArticleIDs) - $($pendingUpdate.title)"
			}
			Else
			{
				Write-Host "KB$($pendingUpdate.KBArticleIDs) - $($pendingUpdate.title) needs to be installed"
			}
		}
		Write-Host "System has $($pendingUpdates.Count) pending Windows Updates"
		if ($pendingUpdates.Count -ne 0)
		{
			if ($ForceInstall)
			{
				Try
				{
					$Downloader = $msUpdateSession.CreateUpdateDownloader()
					$Downloader.Updates = $pendingUpdates
					$Downloader.Download()
					$Installer = $msUpdateSession.CreateUpdateInstaller()
					$Installer.Updates = $pendingUpdates
					$Result = $Installer.Install()
					Write-Host "Windows update completed restart required $($Result.rebootRequired)"
					If ($Result.rebootRequired) { $ExitCode = "3010" }
				}
				Catch
				{
					$ExitCode = $LastExitCode
					Write-Host "Windows Update failed with error $($_.Exception.Message)"
				}
			}
		}
	}
	Else
	{
		Write-Host "System has a pending restart, no action taken" | Out-Null
		$ExitCode = "3010"
	}
	if ($ForceInstall)
	{
		Write-Host "$($pendingUpdates.Count) pending windows updates installed with exit code [$($ExitCode)] and a pending reboot is $($Result.rebootRequired)"
	}
	Else
	{
		Write-Host "$env:COMPUTERNAME has $($pendingUpdates.Count) pending windows and a pending reboot is $($Result.rebootRequired)"
	}
	return $ExitCode
}<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2024 v5.8.242
	 Created on:   	29/06/2024 08:46
	 Created by:   	yreaw
	 Organization: 	
	 Filename:     	
	===========================================================================
	.DESCRIPTION
		A description of the file.
#>



Get-PendingWindowsUpdates