Function Process-Handler {
   param(
      [Parameter(Position=0,Mandatory=$true)][CloudNative.CloudEvents.CloudEvent]$CloudEvent
   )

# Form cloudEventData object and output to console for debugging
$cloudEventData = $cloudEvent | Read-CloudEventJsonData -ErrorAction SilentlyContinue -Depth 10
if($cloudEventData -eq $null) {
   $cloudEventData = $cloudEvent | Read-CloudEventData
   }
Write-Host "Full contents of CloudEventData`n $(${cloudEventData} | ConvertTo-Json)`n"

# Extract hostname from CloudEventData object
$esxiHost=$cloudEventData.Host.Name
Write-Host "Hostname from CloudEventData" $esxiHost

## Check secret in place which supplies vROps environment variables
Write-Host "vropsFqdn:" ${env:vropsFqdn}
Write-Host "vropsUser:" ${env:vropsUser}
Write-Host "vropsPassword:" ${env:vropsPassword}

## Form unauthorized headers payload
$headers = @{
   "Content-Type" = "application/json";
   "Accept"  = "application/json"
   }

## Acquire bearer token
$uri = "https://" + ${env:vropsFqdn} + "/suite-api/api/auth/token/acquire"
$basicAuthBody = @{
    username = ${env:vropsUser};
    password = ${env:vropsPassword} ;
    }
$basicAuthBodyJson = $basicAuthBody | ConvertTo-Json -Depth 5
Write-Host "Acquiring bearer token ..."
$bearer = Invoke-WebRequest -Uri $uri -Method POST -Headers $headers -Body $basicAuthBodyJson -SkipCertificateCheck | ConvertFrom-Json
Write-Host "Bearer token is" $bearer.token

## Form authorized headers payload
$authedHeaders = @{
   "Content-Type" = "application/json";
   "Accept"  = "application/json";
   "Authorization" = "vRealizeOpsToken " + $bearer.token
   }

## Get host ResourceID
$uri = "https://" + ${env:vropsFqdn} + "/suite-api/api/adapterkinds/VMWARE/resourcekinds/HostSystem/resources?name=" + $esxiHost
Write-Host "Acquiring host ResourceID ..."
$resource = Invoke-WebRequest -Uri $uri -Method GET -Headers $authedHeaders -SkipCertificateCheck
$resourceJson = $resource.Content | ConvertFrom-Json
Write-Host "ResourceID of host is " $resourceJson.resourceList[0].identifier

## Unmark host as maintenance mode
$uri = "https://" + ${env:vropsFqdn} + "/suite-api/api/resources/" + $resourceJson.resourceList[0].identifier + "/maintained"
Write-Host "Unmarking host as vROps maintenance mode ..."
Invoke-WebRequest -Uri $uri -Method DELETE -Headers $authedHeaders -SkipCertificateCheck

## Get host maintenance mode state
$uri = "https://" + ${env:vropsFqdn} + "/suite-api/api/adapterkinds/VMWARE/resourcekinds/HostSystem/resources?name=" + $esxiHost
Write-Host "Acquiring host maintenance mode state ..."
$resource = Invoke-WebRequest -Uri $uri -Method GET -Headers $authedHeaders -SkipCertificateCheck
$resourceJson = $resource.Content | ConvertFrom-Json
Write-Host "Host maintenence mode state is " $resourceJson.resourceList[0].resourceStatusStates[0].resourceState
Write-Host "Note: STARTED=Not In Maintenance | MAINTAINED_MANUAL=In Maintenance"
}