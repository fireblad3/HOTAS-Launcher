$output = Get-PnpDevice -PresentOnly | Where-Object { $_.InstanceId -match '^USB'} 


$output = $output | Where-Object {$_.FriendlyName -notmatch 'Hub' -and $_.FriendlyName -notmatch 'Audio' -and $_.FriendlyName -notmatch 'Receiver'  -and $_.FriendlyName -notmatch 'ButtKicker'}

$output = $output | Where-Object {$_.Class -notmatch 'Image' -and $_.Class -notmatch 'Media' -and $_.Class -notmatch 'Bluetooth' -and $_.Class -notmatch 'DiskDrive' -and $_.Class -notmatch 'USBDevice'}
#$Output | Format-Table
$Sticks = @()

foreach ($stick in $output) {

    $stickId = $stick.InstanceId
    $Details = Get-PnpDeviceProperty -InstanceId $StickID
    foreach ($detail in $Details) {
        if ($detail.keyname -eq 'DEVPKEY_Device_BusReportedDeviceDesc') {
            $StickName = $detail.Data
        }
    }

    $sticks += [PSCustomObject]@{
        Name = $stickName
        ID = $stickId
    }
    $stickId = $null
    $StickName = $null

}
$Sticks | ConvertTo-Json -Depth 6 | Out-File -FilePath "$PSScriptRoot\joysticks.json"