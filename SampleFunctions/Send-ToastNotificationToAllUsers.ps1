# Function to send toast notifications to all logged-in users
function Send-ToastNotificationToAllUsers {
    param (
        [string]$Title = "System Notification",
        [string]$Message = "This is a message to all logged-in users.",
        [string]$ImagePath = "",
        [string]$AudioPath = "",
        [string]$Button1Label = "View Details",
        [string]$Button1Argument = "action=view",
        [string]$Button2Label = "Dismiss",
        [string]$Button2Argument = "action=dismiss"
    )

    # Construct the toast XML content with all elements
    $ToastXml = @"
<toast>
  <visual>
    <binding template="ToastGeneric">
      <text>$Title</text>
      <text>$Message</text>
      @{if ($ImagePath -ne "") { "<image src=`"$ImagePath`" placement=`"appLogoOverride`" />" }}
    </binding>
  </visual>
  <actions>
    <action content="$Button1Label" arguments="$Button1Argument" activationType="foreground" />
    <action content="$Button2Label" arguments="$Button2Argument" activationType="foreground" />
  </actions>
  @{if ($AudioPath -ne "") { "<audio src=`"$AudioPath`" />" }}
</toast>
"@

    # Get all logged-in users
    $LoggedUsers = (quser | ForEach-Object {
        $line = $_ -split '\s{2,}'  # Split by two or more spaces
        if ($line[1] -eq 'Disc' -or $line[1] -eq 'Active') { $line[0] }
    })

    foreach ($User in $LoggedUsers) {
        try {
            # Run the notification script in the user's context
            Invoke-Command -ScriptBlock {
                Add-Type -AssemblyName Windows.UI.Notifications
                $ToastXmlDoc = New-Object Windows.Data.Xml.Dom.XmlDocument
                $ToastXmlDoc.LoadXml($using:ToastXml)

                $Toast = [Windows.UI.Notifications.ToastNotification]::new($ToastXmlDoc)
                $Notifier = [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier("YourAppName")

                $Notifier.Show($Toast)
            } -Credential (New-Object System.Management.Automation.PSCredential($User, (Get-Credential).Password))
        }
        catch {
            Write-Warning "Failed to send notification to user: $User"
        }
    }
}

# Call the function with custom parameters
Send-ToastNotificationToAllUsers -Title "Important Update" `
    -Message "The system will undergo maintenance at 8 PM." `
    -ImagePath "C:\Path\To\Image.png" `
    -AudioPath "ms-winsoundevent:Notification.Reminder" `
    -Button1Label "Learn More" `
    -Button1Argument "action=learnmore" `
    -Button2Label "Close" `
    -Button2Argument "action=close"
