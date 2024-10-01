function Install-CompanyPortalApp
{
	param (
		[Parameter(Mandatory = $True)]
		[string]$ApplicationId
	)
	
	start-process companyportal:ApplicationId=$ApplicationId
	Start-Sleep 10
	[void][System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms')
	[System.Windows.Forms.SendKeys]::SendWait("^{i}")
	
}