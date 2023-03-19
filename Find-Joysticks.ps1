$output = Get-PnpDevice -PresentOnly | Where-Object { $_.InstanceId -match '^USB'} 


$output = $output | Where-Object {$_.FriendlyName -notmatch 'Hub' -and $_.FriendlyName -notmatch 'Audio' -and $_.FriendlyName -notmatch 'Receiver'  -and $_.FriendlyName -notmatch 'ButtKicker'}

$Output | Format-Table
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
#$Sticks | Format-Table
$Sticks | ConvertTo-Json -Depth 6 | Out-File -FilePath "$PSScriptRoot\joysticks.json"