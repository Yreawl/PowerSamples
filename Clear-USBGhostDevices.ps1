<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2024 v5.8.244
	 Created on:   	05/07/2024 08:37
	 Created by:   	yreaw
	 Organization: 	
	 Filename:     	
	===========================================================================
	.DESCRIPTION
		A description of the file.
#>

# https://superuser.com/questions/1776942/how-to-bulk-remove-all-hidden-devices-in-device-manager-sample-powershell-scri

#List all hidden devices
$unknown_devs = Get-PnpDevice | Where-Object{ $_.Status -eq 'Unknown' }

#loop through all hidden devices to remove them using pnputil
ForEach ($dev in $unknown_devs)
{
	pnputil /remove-device $dev.InstanceId
}

pnputil.exe /scan-devices