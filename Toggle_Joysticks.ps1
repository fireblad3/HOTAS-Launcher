param(
[String]$Game,
[switch]$Elevated,
[switch]$allOff,
[switch]$allOn
)

function Import-Xaml {
    
    Param(
        [String]$xfile
    )
    [System.Reflection.Assembly]::LoadWithPartialName("PresentationFramework") | Out-Null
	[xml]$xaml = Get-Content -Path $PSScriptRoot\$xfile
	$manager = New-Object System.Xml.XmlNamespaceManager -ArgumentList $xaml.NameTable
	$manager.AddNamespace("x", "http://schemas.microsoft.com/winfx/2006/xaml");
	$xamlReader = New-Object System.Xml.XmlNodeReader $xaml
	[Windows.Markup.XamlReader]::Load($xamlReader)
}

function Test-Admin{
    Param(
    [String]$myScript,
    [String]$elevated,
    [String]$Game,
    [switch]$allOff,
    [switch]$allOn
    ) 
    $currentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
    $currentUser = $currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
    IF ($currentUser -ne $true) {
        if ($elevated) {
            Write-Warning -Message "tried to elevate, did not work, aborting"
        } else {
            If ($allOff) {
                $Scriptpath =  "& '" + $myScript + "' -elevated -Game $Game -allOff" ; Start-Process powershell -Verb runAs -ArgumentList "$Scriptpath" ; exit
            }
            If ($allOn) {
                $Scriptpath =  "& '" + $myScript + "' -elevated -Game $Game -allOn" ; Start-Process powershell -Verb runAs -ArgumentList "$Scriptpath" ; exit
            }
            $Scriptpath =  "& '" + $myScript + "' -elevated -Game $Game" ; Start-Process powershell -Verb runAs -ArgumentList "$Scriptpath" ; exit
        }
        Exit
    }
   
}



Function Set-Config {
    #joysticks
    $MFG = "USB\VID_16D0&PID_0A38\MFG500002"
    $SGF = "USB\VID_231D&PID_0127\6&5d99159&1&2"
    $MCGU = "USB\VID_231D&PID_0125\6&5d99159&1&1"
    $Hog = "USB\VID_044F&PID_0404\5&178ad4e8&0&8"
    # Create Demo Config
    $Options = [PSCustomObject]@{   
        DEMO = [PSCustomObject]@{ 
                Name= "DEMO"
                Path = 'E:\Games Standalone\DEMO\Demo.exe'
                Path2 = 'C:\Program Files (x86)\SimShaker\SimShaker for Aviators Beta\SimShaker for Aviators Beta.exe'
                Path3 = 'C:\Program Files (x86)\SimShaker\SimShaker for Aviators Beta\SimShaker for Aviators Beta.exe'
                Path4 = 'C:\Program Files (x86)\SimShaker\SimShaker for Aviators Beta\SimShaker for Aviators Beta.exe'
                Path5 = 'C:\Program Files (x86)\SimShaker\SimShaker for Aviators Beta\SimShaker for Aviators Beta.exe'
                Selections = [PSCustomObject]@{
                    MCGU=$MCGU
                    SGF=$SGF
                    Hog=$Hog
                    MFG=$MFG
                }
        }
           
        DEMO2 = [PSCustomObject]@{
            Name = "DEMO2" 
            Path = 'E:\Games Standalone\DEMO2\Demo2.exe' 
            Selections = [pscustomobject]@{
                MCGU=$MCGU
                SGF=$SGF
                Hog=$Hog
            } 
        } 
    }
    $Options | ConvertTo-Json | Out-File -FilePath "$PSScriptRoot\Games.json"
    $Options
}

Function Get-Paths {

    Add-Type -AssemblyName System.Windows.Forms

    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.initialDirectory = $initialDirectory
    $OpenFileDialog.filter = "All files (*.*)| *.*"
    $OpenFileDialog.ShowDialog() | Out-Null
    $path = $OpenFileDialog.filename

    $Settings = [PSCustomObject]@{
        usbdview = $path
        
    }
    $Settings | ConvertTo-Json | Out-File -FilePath "$PSScriptRoot\Settings.json"

    # Return
    $Settings
}

#Get some Settings

$path = "$PSScriptRoot\USBDeview.exe"
IF (!(Test-Path -Path $path)) {
    IF (Test-Path -Path "$PSScriptRoot\settings.json") {
        $settings = Get-Content -Path "$PSScriptRoot\settings.json" -Raw | ConvertFrom-Json
        $path = $Settings.usbdview
    } Else {
        $Settings = Get-Paths
        $path = $Settings.usbdview
    }

}

# Import the Credential Manager this allows us to save some credentials so that the elevated window can launch the game as your standard user.
Import-Module CredentialManager

IF (!($Game) -and !($allOff) -and !($allOn)) {
    IF (!(Test-Path -Path $PSScriptRoot\Games.json)){
        $Options = Set-Config
    } Else {
        $Window = Import-Xaml "Main.xaml"
        $Button = $Window.FindName('ButRSI')
        $Button.Add_Click({
            $Script:Game = "RSI"
            $window.Close()
        })
        $Window.ShowDialog() | Out-Null
        IF ($Game) {
            $Options = Get-Content -Path "$PSScriptRoot\games.json" -Raw | ConvertFrom-Json
        } Else {
            Write-Warning "You already have a config file either run with -game <Name> or delete your config to start again"; exit
        }
    }
} Else {
    $Options = Get-Content -Path "$PSScriptRoot\games.json" -Raw | ConvertFrom-Json
}

Foreach ($G in $Options.$Game){
    IF ($G.Name -eq $Game) {$Found = $true}
}
IF ($Found) {
    $Creds = (Get-StoredCredential -Target "GameLauncher")
    If (!(Get-StoredCredential -Target "GameLauncher")){
        Write-Warning -Message "Credentials don't exist, prompting user"
        $Creds = Get-Credential -Message "Enter your windows username and Password to run the game" | New-StoredCredential -Target "GameLauncher" -Type Generic -Persist Enterprise
        $Creds = (Get-StoredCredential -Target "GameLauncher")
    }

    $myScript = $myinvocation.mycommand.definition
    IF ($allOff) {
        Test-Admin -MyScript "$Myscript" -Game "$Game" -allOff
    }
    IF ($allOn) {
        Test-Admin -MyScript "$Myscript" -Game "$Game" -allOn
    }
    IF ($allOn -ne $true -and $alloff -ne $true) {
        Test-Admin -MyScript "$Myscript" -Game "$Game"
    }

    $Selections = foreach($item in $Options.$Game.Selections.PsObject.Properties) {
        Add-Member -in $item.value -NotePropertyName 'name' -NotePropertyValue $item.name -PassThru
    }
    
    # Turn it all On
    IF ($allOff -ne $true) {
        ForEach ($Selection in $Selections) {
            Start-Process -FilePath $Path -ArgumentList "/RunAsAdmin /enable $Selection"
            Timeout /T 5
        }
    }
    
    # Start the Game
    IF ($Game -ne 'DEMO') {
        IF ($Options.$Game.Path2){
        Write-Host "Starting Aux app 1"
            $App1 = Start-Process -FilePath $Options.$Game.Path2 -PassThru
        }
        IF ($Options.$Game.Path3){
        Write-Host "Starting Aux app 2"
            $App2 = Start-Process -FilePath $Options.$Game.Path3 -Credential $Creds -PassThru
        }
        IF ($Options.$Game.Path4){
        Write-Host "Starting Aux app 3"
            $App3 = Start-Process -FilePath $Options.$Game.Path4 -Credential $Creds -PassThru
        }
        IF ($Options.$Game.Path5){
        Write-Host "Starting Aux app 4"
            $App4 = Start-Process -FilePath $Options.$Game.Path5 -Credential $Creds -PassThru
        }

        Write-Host "Starting $Game"
        Start-Process -FilePath $Options.$Game.Path -ArgumentList $Options.$Game.Arg1 -Wait -Credential $Creds
    }

    #Turn it all off
    IF ($allOn -ne $true) {
        ForEach ($Selection in $Selections) {
            Start-Process -FilePath $Path -ArgumentList "/RunAsAdmin /Disable $Selection"
            IF ($App1) {Stop-Process -InputObject $App1}
            IF ($App1) {Stop-Process -InputObject $App2}
            IF ($App1) {Stop-Process -InputObject $App3}
            IF ($App1) {Stop-Process -InputObject $App4}
        }
    }
    
} Else {
    Write-Host "A Game with that name was not found in your config file"
}