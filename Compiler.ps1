# https://www.powershellgallery.com/packages/ps2exe/1.0.4
$ScriptContent = Get-Content -Path ".\Launcher.ps1"
$Copyright = "Copyright (C) 2023  Daniel Bailey"
$Icon = ".\Hotas-Launcher.ico"
$Title = "HOTAS.Launcher"
$FileName = ".\$Title.exe"
foreach ($line in $ScriptContent) {
    IF ($line -like '$version = *') {
        $Version = $line.Replace('$version = "','').Replace('"','').Replace('v','').Replace('-alpha','')
    }
}

Invoke-ps2exe .\Launcher.ps1 $FileName -version $Version -noConsole -iconFile $Icon -noOutput -copyright $Copyright -title $Title -product $Title -requireAdmin
Write-Host "Compiled version $Version"