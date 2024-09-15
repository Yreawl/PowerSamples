# Define the parameters for the new security group
$domain = "LDAP://OU=Groups,DC=yourdomain,DC=com"  # Modify with your domain and OU path
$groupName = "NewSecurityGroup"
$groupDescription = "This is a new AD security group created using ADSI."

# Connect to the Active Directory domain
$adsiConnection = [ADSI]"$domain"

# Create the new security group
$newGroup = $adsiConnection.Create("group", "CN=$groupName")
$newGroup.Put("sAMAccountName", $groupName)  # Set the Security Account Manager (SAM) account name
$newGroup.Put("description", $groupDescription)  # Add description
$newGroup.Put("groupType", 0x80000002)  # Group type for security group (global)
$newGroup.SetInfo()  # Commit the changes to AD

# Confirm the creation
if ($newGroup -ne $null) {
    Write-Host "AD Security Group '$groupName' has been created successfully."
} else {
    Write-Host "Failed to create the AD Security Group."
}
