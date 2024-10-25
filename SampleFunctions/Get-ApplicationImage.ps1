param(
    [string]$AppName,
    [String]$TargetPath
)

# Function to search for an image URL by application name
function Search-ImageUrl {
    param(
        [string]$AppName
    )

    # Search query for Bing
    $searchQuery = "$AppName icon square transparent"
    
    # Perform Bing search (limited result count)
    $searchUrl = "https://www.bing.com/images/search?q=$searchQuery"
    $response = Invoke-WebRequest -Uri $searchUrl

    # Parse HTML and look for images in the page
    $imgTags = $response.Content -split '<img'

    foreach ($tag in $imgTags) {
        # Extract the image URLs from the tags
        if ($tag -match 'src="([^"]+)"') {
            $imgUrl = $matches[1]
            if ($imgUrl -match "https?:\/\/.*\.(jpg|jpeg|png|gif|svg)") {
                return $imgUrl
            }
        }
    }

    return $null
}

# Function to download the image from the URL
function Download-Image {
    param(
        [string]$ImageUrl,
        [string]$FileName
    )

    try {
        $response = Invoke-WebRequest -Uri $ImageUrl -OutFile $FileName
        if ($response.StatusCode -eq 200) {
            Write-Host "Image successfully downloaded as $FileName"
        }
    } catch {
        Write-Host "Failed to download image: $_"
    }
}

Function Get-ApplicationIcon
{
    param(
        [string]$ApplicationName,
        [string]$TargetPath
    )
    # Main block
    $ImageUrl = Search-ImageUrl -AppName $ApplicationName

    if ($ImageUrl) {
        Write-Host "Logo found: $ImageUrl"
        $FileName = "$ApplicationName-Icon.png"
        Download-Image -ImageUrl $ImageUrl -FileName "$($TargetPath)\$($FileName)"
    } else {
        Write-Host "Logo not found."
    }
}

Get-ApplicationIcon -ApplicationName $AppName -TargetPath $TargetPath