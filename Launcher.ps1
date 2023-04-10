param(
[switch]$Elevated
)

# Import the Credential Manager this allows us to save some credentials so that the elevated window can launch the game as your standard user.
Import-Module CredentialManager

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
    [switch]$allOn,
    [switch]$test
    ) 
    $currentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
    $Admin = $currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
    #$currentUser
    IF ($Admin -ne $true) {
        IF ($test -eq $false) {
            if ($elevated) {
                Write-Warning -Message "tried to elevate, did not work, aborting"
            } else {
                If ($allOff) {
                    $Scriptpath =  "& '" + $myScript + "' -elevated -Game $Game -allOff" ; Start-Process powershell -Verb runAs -ArgumentList "$Scriptpath" ; exit
                }
                If ($allOn) {
                    $Scriptpath =  "& '" + $myScript + "' -elevated -Game $Game -allOn" ; Start-Process powershell -Verb runAs -ArgumentList "$Scriptpath" ; exit
                }
                Write-Host "Launching As Admin"
                $Scriptpath =  "& '" + $myScript + "' -elevated -Game $Game" ; Start-Process powershell -Verb runAs -ArgumentList "$Scriptpath" ; exit
            }
        }
    }
    $Admin
}

Function Set-Config {

    # Create Config
    $Stick1 = Get-Joystick $Joysticks
    $Stick2 = Get-Joystick $Joysticks
    $Stick3 = Get-Joystick $Joysticks
    $Stick4 = Get-Joystick $Joysticks

    $Options = [PSCustomObject]@{   
        DEMO = [PSCustomObject]@{ 
                Name= "DEMO"
                Path = 'E:\Games Standalone\DEMO\Demo.exe'
                Path2 = 'C:\Program Files (x86)\SimShaker\SimShaker for Aviators Beta\SimShaker for Aviators Beta.exe'
                Path3 = 'C:\Program Files (x86)\SimShaker\SimShaker for Aviators Beta\SimShaker for Aviators Beta.exe'
                Path4 = 'C:\Program Files (x86)\SimShaker\SimShaker for Aviators Beta\SimShaker for Aviators Beta.exe'
                Path5 = 'C:\Program Files (x86)\SimShaker\SimShaker for Aviators Beta\SimShaker for Aviators Beta.exe'
                Selections = [PSCustomObject]@{
                    Stick1=$Stick1
                    Stick2=$Stick2
                    Stick3=$Stick3
                    Stick4=$Stick4
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

Function Set-Settings {

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
Function Get-Joysticks {
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
    $Sticks
}

Function Get-Joystick {
    param(
        $Joysticks
    )
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $form = New-Object System.Windows.Forms.Form
    $form.Text = 'Select a Joystick'
    $form.Size = New-Object System.Drawing.Size(500,500)
    $form.StartPosition = 'CenterScreen'

    $okButton = New-Object System.Windows.Forms.Button
    $okButton.Location = New-Object System.Drawing.Point(75,425)
    $okButton.Size = New-Object System.Drawing.Size(75,23)
    $okButton.Text = 'Add'
    $okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $okButton.Add_Click{
        $x = $listBox.SelectedItem
    }
    $form.AcceptButton = $okButton
    $form.Controls.Add($okButton)

    $cancelButton = New-Object System.Windows.Forms.Button
    $cancelButton.Location = New-Object System.Drawing.Point(150,425)
    $cancelButton.Size = New-Object System.Drawing.Size(75,23)
    $cancelButton.Text = 'Close'
    $cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $form.CancelButton = $cancelButton
    $form.Controls.Add($cancelButton)

    $label = New-Object System.Windows.Forms.Label
    $label.Location = New-Object System.Drawing.Point(10,20)
    $label.Size = New-Object System.Drawing.Size(280,20)
    $label.Text = 'Please select a joystick and click copy:'
    $form.Controls.Add($label)

    $listBox = New-Object System.Windows.Forms.ListBox
    $listBox.Location = New-Object System.Drawing.Point(10,40)
    $listBox.Size = New-Object System.Drawing.Size(400,350)




    $sticks = foreach($item in $Joysticks){
            $Item.Name
            #Add-Member -in $item.value -NotePropertyName 'Name' -NotePropertyValue $item.Name –PassThru
        }


    Foreach ($stick in $sticks ) {
        [void] $listBox.Items.Add($stick)
    }

    $form.Controls.Add($listBox)

    $form.Topmost = $true

    $result = $form.ShowDialog()

    if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
        
    } 
    $x
}

Function Start-Game {
    param(
        [String]$Game,
        [switch]$allOff,
        [switch]$allOn,
        $Options,
        $Joysticks
    )

    $Selections = foreach($item in $Options.$Game.Selections.PsObject.Properties) {
        Add-Member -in $item.value -NotePropertyName 'name' -NotePropertyValue $item.name -PassThru
    }
    
    # Turn it all On
    IF ($allOff -ne $true) {
        ForEach ($Selection in $Selections) {
            $Stick = $Joysticks | Where-Object {$_.Name -eq $Selection}
            $SelectedStick = $Stick.ID
            Write-Host $Stick.ID
            Start-Process -FilePath $Path -ArgumentList "/RunAsAdmin /enable $SelectedStick"
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
        IF ($Options.$Game.arg1) {
            Start-Process -FilePath $Options.$Game.Path -ArgumentList $Options.$Game.Arg1 -Wait -Credential $Creds
        } Else {
            Start-Process -FilePath $Options.$Game.Path -Wait -Credential $Creds
        }
        Read-Host "Press Any Key to Finish"
    }

    #Turn it all off
    IF ($allOn -ne $true) {
        ForEach ($Selection in $Selections) {
            $Stick = $Joysticks | Where-Object {$_.Name -eq $Selection}
            $SelectedStick = $Stick.ID
            Write-Host $Stick.ID
            Start-Process -FilePath $Path -ArgumentList "/RunAsAdmin /Disable $SelectedStick"
            IF ($App1) {Stop-Process -InputObject $App1}
            IF ($App1) {Stop-Process -InputObject $App2}
            IF ($App1) {Stop-Process -InputObject $App3}
            IF ($App1) {Stop-Process -InputObject $App4}
        }
    }
}

#Initial Setup

#Get Credentials or set them if needed
$Creds = (Get-StoredCredential -Target "GameLauncher")
If (!(Get-StoredCredential -Target "GameLauncher")){
    Write-Warning -Message "Credentials don't exist, prompting user"
    $Creds = Get-Credential -Message "Enter your windows username and Password to run the game" | New-StoredCredential -Target "GameLauncher" -Type Generic -Persist Enterprise
    $Creds = (Get-StoredCredential -Target "GameLauncher")
}

# Check that we are running as admin and restart if we aren't
$myScript = $myinvocation.mycommand.definition
$null = Test-Admin -MyScript "$Myscript"


$SettingsPath = "$PSScriptRoot\settings.json"

IF (Test-Path -Path "$SettingsPath") {
    $settings = Get-Content -Path "$SettingsPath" -Raw | ConvertFrom-Json
    $path = $Settings.usbdview
} Else {
    $Settings = Set-Settings
    $path = $Settings.usbdview
}


#Get the Joysticks now.
$Joysticks = @(Get-Joysticks)

# Get The Games
IF (!(Test-Path -Path $PSScriptRoot\Games.json)){
    $Options = Set-Config
} 
$Options = Get-Content -Path "$PSScriptRoot\games.json" -Raw | ConvertFrom-Json

$Games = foreach($G in $Options.PsObject.Properties){
    $G.Name
}

#Create the Window

$Window = Import-Xaml "Main.xaml"

($Window.FindName('ComboGame')).ItemsSource = $Games


$Button1 = $Window.FindName('Button1')
$Button1.Add_Click({
   $Game = ($Window.FindName('ComboGame')).SelectedItem
    Start-Game -Game $Game -Options $Options -Joysticks $Joysticks
})
$Window.ShowDialog() | Out-Null

