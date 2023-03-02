$host.ui.RawUI.WindowTitle = "iRacing Launcher"

$Chief="C:\Program Files (x86)\Britton IT Ltd\CrewChiefV4\CrewChiefV4.exe"
$iracing="E:\Games Standalone\iRacing\ui\iRacingUI.exe"
$paints="C:\Program Files (x86)\Rhinode LLC\Trading Paints\Trading Paints.exe"
$joy="C:\Program Files (x86)\JoyToKey\JoyToKey.exe"

Write-Host -ForegroundColor Cyan "Starting Crew Chief"
Start-Process -FilePath $Chief -NoNewWindow
Write-Host -ForegroundColor Cyan "Starting Trading Paints"
Start-Process -FilePath $paints -NoNewWindow

#Start-Process -FilePath $joy -NoNewWindow
Write-Host -ForegroundColor Cyan "Starting iRacing"
Write-Warning -Message "Waiting for iRacing to Close"
Start-Process -FilePath $iracing -NoNewWindow -Wait -RedirectStandardOutput ".\NUL"



taskkill /IM "CrewChiefV4.exe" /F
taskkill /IM "Trading Paints.exe" /F
# taskkill /IM "JoyToKey.exe" /F