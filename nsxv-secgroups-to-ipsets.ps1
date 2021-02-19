
#Disclaimer: This product is not supported by VMware. It is a sample script put together to give an example on how to add IPsets containing the translated IP to security groups with dynamic membership criteria in NSXv
#Usage example: .\nsxv-secgroups-to-ipsets.ps1 -vc vcsa-01a.corp.local -vcusr administrator@vsphere.local -vcpsw VMware1!  -nsx nsxvmgr-01a.corp.local -nsxusr admin -nsxpsw VMware1!VMware1! -sgname security_group_name

param($vc, $vcusr, $vcpsw, $nsx , $nsxusr, $nsxpsw, $sgname)

Connect-VIServer $vc -User $vcusr -Password $vcpsw

Connect-NsxServer $nsx -Username $nsxusr -Password $nsxpsw

$NSXUsername = $nsxusr
$NSXPassword = $nsxpsw
$uri = "https://192.168.110.14"
# Create authentication header with base64 encoding
$EncodedAuthorization = [System.Text.Encoding]::UTF8.GetBytes($NSXUsername + ':' + $NSXPassword)
$EncodedPassword = [System.Convert]::ToBase64String($EncodedAuthorization)
# Construct headers with authentication data + expected Accept header (xml / json)
$head = @{"Authorization" = "Basic $EncodedPassword"}



$secGroup = Get-NsxSecurityGroup -name $sgname 

$secGroupId= $secGroup.objectId

$Url = $uri + "/api/2.0/services/securitygroup/" + $secGroup.objectId + "/translation/ipaddresses"
[xml]$r = Invoke-WebRequest -Uri $Url -Method:Get -Headers $head -Body $body -ContentType "application/xml"

$ipv4name = "ipsv4-" + $secGroup.name

$ipSetv4 = New-NsxIpSet -name $ipv4name

foreach ($item in $r.ipNodes.ipNode.ipAddresses ) {
   $ipAddresses = $item.string
   $ipAddressesElemets=$ipAddresses.split(' ')
   foreach ( $i in $ipAddressesElemets) {
      $checkifip = [IPAddress] $i.ToString()
      if ( $checkifip.AddressFamily.ToString() -eq "InterNetwork" ) {
         Get-NsxIpSet -objectId $ipSetv4.objectId | Add-NsxIpSetMember -IPAddress ($i.ToString() + "/32")
      } 
   }
}


Get-NsxSecurityGroup -objectId $secGroupId |  Add-NsxSecurityGroupMember -Member $ipSetv4
