 Connect-VIServer vcsa-01a.corp.local -User administrator@vsphere.local  -Password VMware1!

Connect-NsxServer -Username "admin" -Password VMware1!VMware1!  192.168.110.14


#Preparation
$NSXUsername = "admin"
$NSXPassword = "VMware1!VMware1!"
$uriP = "https://192.168.110.14"
# Create authentication header with base64 encoding
$EncodedAuthorization = [System.Text.Encoding]::UTF8.GetBytes($NSXUsername + ':' + $NSXPassword)
$EncodedPassword = [System.Convert]::ToBase64String($EncodedAuthorization)
# Construct headers with authentication data + expected Accept header (xml / json)
$head = @{"Authorization" = "Basic $EncodedPassword"}



$Url = $uriP + "/api/4.0/edges/edge-1/vnics/3"

try { [xml]$response = Invoke-WebRequest -Uri $Url -Method:Delete -Headers $head  } catch {
      $_.Exception.Response}



$Url = $uriP + "/api/4.0/edges/edge-1/vnics/4"

try { [xml]$response = Invoke-WebRequest -Uri $Url -Method:Delete -Headers $head  } catch {
      $_.Exception.Response}




$Url = $uriP + "/api/4.0/edges/edge-1/vnics/5"

try { [xml]$response = Invoke-WebRequest -Uri $Url -Method:Delete -Headers $head  } catch {
      $_.Exception.Response}


$LSuapp = Get-NsxTransportZone -name universal-tz | New-NsxLogicalSwitch -Name u-app
$LSudb = Get-NsxTransportZone -name universal-tz | New-NsxLogicalSwitch -Name u-db
$LSube1 = Get-NsxTransportZone -name universal-tz | New-NsxLogicalSwitch -Name u-backend-1
$LSube2 = Get-NsxTransportZone -name universal-tz | New-NsxLogicalSwitch -Name u-backend-2

$UDLR = Get-NsxLogicalRouter -Name u-udlr01

$UDLR | New-NsxLogicalRouterInterface `
  -Type Internal `
  -name "App" `
  -ConnectedTo $LSuapp `
  -PrimaryAddress "172.16.20.1" `
  -SubnetPrefixLength "24"


$UDLR | New-NsxLogicalRouterInterface `
  -Type Internal `
  -name "Db" `
  -ConnectedTo $LSudb `
  -PrimaryAddress "172.16.30.1" `
  -SubnetPrefixLength "24"

$UDLR | New-NsxLogicalRouterInterface `
  -Type Internal `
  -name "backend1" `
  -ConnectedTo $LSube1 `
  -PrimaryAddress "172.20.1.1" `
  -SubnetPrefixLength "24"

$UDLR | New-NsxLogicalRouterInterface `
  -Type Internal `
  -name "backend2" `
  -ConnectedTo $LSube2 `
  -PrimaryAddress "172.20.2.1" `
  -SubnetPrefixLength "24"


get-vm -Name db-* | Get-NetworkAdapter | Set-NetworkAdapter -PortGroup ( $LSudb | Get-NsxBackingPortGroup ) -Confirm:$false
get-vm -Name app-* | Get-NetworkAdapter | Set-NetworkAdapter -PortGroup ( $LSuapp | Get-NsxBackingPortGroup ) -Confirm:$false
get-vm -Name backend-1 | Get-NetworkAdapter | Set-NetworkAdapter -PortGroup ( $LSube1 | Get-NsxBackingPortGroup ) -Confirm:$false
get-vm -Name backend-2 | Get-NetworkAdapter | Set-NetworkAdapter -PortGroup ( $LSube2 | Get-NsxBackingPortGroup ) -Confirm:$false

Get-NsxLogicalSwitch -Name dlr-transit | Remove-NsxLogicalSwitch -Confirm:$false
Get-NsxLogicalSwitch -Name sitea-app | Remove-NsxLogicalSwitch -Confirm:$false
Get-NsxLogicalSwitch -Name sitea-db | Remove-NsxLogicalSwitch -Confirm:$false
Get-NsxLogicalSwitch -Name backend-1 | Remove-NsxLogicalSwitch -Confirm:$false
Get-NsxLogicalSwitch -Name backend-2 | Remove-NsxLogicalSwitch -Confirm:$false 
