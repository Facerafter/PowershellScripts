Function Get-AuthToken{
    $tenantID = "" # Fill in tenant ID
    $authString = "https://login.microsoftonline.com/$tenantID" 
    $appSecret = Get-AutomationVariable -Name 'roomAnalyticsAppSecret'
    $appId = "" # Fill in App ID
    $creds = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.ClientCredential" -ArgumentList $appId, $appSecret
    $authContext = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext"-ArgumentList $authString
    $context = $authContext.AcquireTokenAsync("https://graph.microsoft.com/", $creds).Result
    $script:authToken = @{
        Authorization   = $context.CreateAuthorizationHeader()
        'Content-Type'  = "application/json"
        'ExpiresOn' = $context.ExpiresOn
    }
}
