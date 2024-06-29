<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2024 v5.8.242
	 Created on:   	29/06/2024 08:42
	 Created by:   	yreaw
	 Organization: 	
	 Filename:     	
	===========================================================================
	.DESCRIPTION
		A description of the file.
#>



function Repair-WindowsUpdates
{
	<#
	.SYNOPSIS
	
	Performs a simple repair to windows updates.  
	
	.DESCRIPTION
	
	Stops the relavent services, clears out the SoftwareDistribution and catroot2 folders and re-starts teh services.  
	
	.LINK
	
	https://github.com/Yreawl
	
	.EXAMPLE 
	
	Repair-WindowsUpdates
		
	#>
	
	$ServiceList = @("wuauserv", "cryptSvc", "bits", "msiserver")
	foreach ($Service in $ServiceList)
	{
		Try
		{
			Get-Service "$($Service)" | Stop-Service -Force
			Show-Response -Message "Stopped service $($Service)"
			break
		}
		catch
		{
			Show-Response -Message "Failed to stop $($Service) the error was $($_.Exception.Message)"
		}
	}
	$FolderList = @("C:\Windows\SoftwareDistribution", "C:\Windows\System32\catroot2")
	foreach ($Folder in $FolderList)
	{
		Try
		{
			Remove-Item -Path "$($Folder)\*" -Force -recurse -ErrorAction SilentlyContinue
			Show-Response -Message "Emptied $($Folder)"
		}
		Catch
		{
			Show-Response -Message "Failed to Empty  $($Folder) the error was $($_.Exception.Message)"
		}
	}
	foreach ($Service in $ServiceList)
	{
		Try
		{
			Start-Service "$($Service)"
			Show-Response -Message "started service $($Service)"
		}
		catch
		{
			Show-Response -Message "Failed to start $($Service) the error was $($_.Exception.Message)"
		}
	}
}


Repair-WindowsUpdates