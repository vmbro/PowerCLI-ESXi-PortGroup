$vcenter = "vCenterFQDN" # Your vCenter name -  vcenter.domain.local
$user = "username" # Your vCenter username - administrator@vsphere.local or domain\username
$password = "password" # Your vCenter password
$csv = Import-Csv -Path 'C:\portgroupList.csv' # File path to be imported.
$vSwitchName = "vSwitch0" # Your vSwitch Name
try {
    Disconnect-VIServer -server * -confirm:$false
}
catch {
    #"Could not find any of the servers specified by name."
}
$checkedHost = ""
$esxiHosts = ""
function createPortGroup {
    param([string]$checkedHost, [string]$newPG, [string]$newPGVLAN)
    Get-VMHost -name $checkedHost | Get-VirtualSwitch -Name $vSwitchName | New-VirtualPortGroup -Name $newPG -VLanId $newPGVLAN | out-null
    write-host "Creating " $portGroup.PortGroupName " Port Group with VLAN ID " $portGroup.ID "to " $checkedHost -ForegroundColor Green
}

Connect-VIServer -Server $vcenter -User $user -Password $password | out-null
$esxiHosts = Get-VMHost

foreach ($esxi in $esxiHosts) {
    $checkSwitchName = Get-VMHost -Name $esxi.Name | Get-VirtualSwitch | Where-Object { $_.Name -eq $vSwitchName }
    if ($checkSwitchName) {
        #Write-Host "Virtual Switch found on" $esxi.Name -ForegroundColor Green
        foreach ($portGroup in $csv) {
            $checkPortGroup = Get-VMHost -Name $esxi.Name | Get-VirtualSwitch -Name $vSwitchName | Get-VirtualPortGroup | Where-Object { $_.Name -eq $portGroup.PortGroupName }
            if (!$checkPortGroup) {
                createPortGroup $esxi.Name $portGroup.PortGroupName $portGroup.ID
            }
            else {
                Write-Host $portGroup.PortGroupName "port group exists on" $esxi.Name -ForegroundColor Cyan
            }
        }
    }
    else {
        Write-Host "Can not find the virtual switch" $vSwitchName "on" $esxi.Name -ForegroundColor Red
    }

}

Disconnect-VIServer -server * -confirm:$false 
