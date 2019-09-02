$uri = "" # Graph url
$Response = (Invoke-RestMethod -Uri $uri –Headers $authToken –Method Get)
    $Data = $Response.value
    $NextLink = $Response."@odata.nextLink"
        while ($NextLink -ne $null){
            $Response = (Invoke-RestMethod -Uri $NextLink –Headers $authToken –Method Get)
            $NextLink = $Response."@odata.nextLink"
            $Data += $Response.value
        }
