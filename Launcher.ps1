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
	[xml]$xaml = Get-Content -Path $psScriptRoot\$xfile
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
                $Scriptpath =  "& '" + $myScript + "' -elevated" ; Start-Process powershell -Verb runAs -ArgumentList "$Scriptpath" ; exit
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
    $Options | ConvertTo-Json | Out-File -FilePath "$env:APPDATA\DBLauncher\Games.json"
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
    $Settings | ConvertTo-Json | Out-File -FilePath "$env:APPDATA\DBLauncher\Settings.json"

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
        $Script:x = $listBox.SelectedItem
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
        $x
    } Else {
        $false
    }
    
}

Function Start-Game {
    param(
        [String]$Game,
        $Options,
        $Joysticks
    )

    $Selections = foreach($item in $Options.$Game.Selections.PsObject.Properties) {
        IF ($Null -ne $item.value -and $item.value -ne $False){
            Add-Member -in $item.value -NotePropertyName 'name' -NotePropertyValue $item.name -PassThru
        }
    }
    
    # Turn it all On
    ForEach ($Selection in $Selections) {
        $Stick = $Joysticks | Where-Object {$_.Name -eq $Selection}
        $SelectedStick = $Stick.ID
        Write-Host $Stick.ID
        Start-Process -FilePath $Path -ArgumentList "/RunAsAdmin /enable $SelectedStick"
        Timeout /T 5
    }

    
    # Start the Game
    IF ($Game) {
        IF ($Game -ne 'DEMO') {
            IF ($Options.$Game.AppPath1){
            Write-Host "Starting Aux app 1"
                $Script:App1 = Start-Process -FilePath $Options.$Game.AppPath1 -PassThru
            }
            IF ($Options.$Game.AppPath2){
            Write-Host "Starting Aux app 2"
                $Script:App2 = Start-Process -FilePath $Options.$Game.AppPath2 -Credential $Creds -PassThru
            }
            IF ($Options.$Game.AppPath3){
            Write-Host "Starting Aux app 3"
                $Script:App3 = Start-Process -FilePath $Options.$Game.AppPath3 -Credential $Creds -PassThru
            }
            IF ($Options.$Game.AppPath4){
            Write-Host "Starting Aux app 4"
                $Script:App4 = Start-Process -FilePath $Options.$Game.AppPath4 -Credential $Creds -PassThru
            }

            Write-Host "Starting $Game"
            IF ($Options.$Game.arg1) {
                Start-Process -FilePath $Options.$Game.GamePath -ArgumentList $Options.$Game.Arg1 -Credential $Creds
            } Else {
                Start-Process -FilePath $Options.$Game.GamePath -Wait -Credential $Creds
            }
        }
    }
}

Function Stop-Game {
    param(
        [String]$Game,
        $Options,
        $Joysticks
    )
    $Selections = foreach($item in $Options.$Game.Selections.PsObject.Properties) {
        IF ($Null -ne $item.value -and $item.value -ne $False){
            Add-Member -in $item.value -NotePropertyName 'name' -NotePropertyValue $item.name -PassThru
        }
    }
    #Turn it all off
    ForEach ($Selection in $Selections) {
        $Stick = $Joysticks | Where-Object {$_.Name -eq $Selection}
        $SelectedStick = $Stick.ID
        Write-Host $Stick.ID
        Start-Process -FilePath $Path -ArgumentList "/RunAsAdmin /Disable $SelectedStick"
    }
    IF ($App1) {
        $null = Stop-Process -InputObject $App1
        $Script:App1 = $false
    }
    IF ($App2) {
        $null = Stop-Process -InputObject $App2
        $Script:App2 = $false
    }
    IF ($App3) {
        $null = Stop-Process -InputObject $App3
        $Script:App3 = $false
    }
    IF ($App4) {
        $null = Stop-Process -InputObject $App4
        $Script:App4 = $false
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

If (!(Test-Path -Path $env:APPDATA\DBLauncher)) {
    mkdir $env:APPDATA\DBLauncher
}
$SettingsPath = "$env:APPDATA\DBLauncher\settings.json"

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
IF (!(Test-Path -Path $env:APPDATA\DBLauncher\Games.json)){
    $Options = Set-Config
} 
$Options = Get-Content -Path "$env:APPDATA\DBLauncher\games.json" -Raw | ConvertFrom-Json

$Script:Games = foreach($G in $Options.PsObject.Properties){
    $G.Name
}

#Create the Window

$Window = Import-Xaml "Main.xaml"


$ComboGame = $Window.FindName('ComboGame')
$ComboGame.ItemsSource = $Games
#($Window.FindName('ComboGame')).ItemsSource = $Games

$Button1 = $Window.FindName('Button1')
$Button1.Add_Click({
   #$Game = ($Window.FindName('ComboGame')).SelectedItem
   $Game = $ComboGame.SelectedItem
    Start-Game -Game $Game -Options $Options -Joysticks $Joysticks
})

$Button2 = $Window.FindName('Button2')
$Button2.Add_Click({
   $Game = ($Window.FindName('ComboGame')).SelectedItem
    Stop-Game -Game $Game -Options $Options -Joysticks $Joysticks
})

$stackEdit = $Window.FindName('stackEdit')
$stackEdit.Visibility = "Collapsed"

$txtGameName = $Window.FindName('txtGameName')
$txtGamePath = $Window.FindName('txtGamePath')
$txtAppPath1 = $Window.FindName('txtAppPath1')
$txtAppPath2 = $Window.FindName('txtAppPath2')
$txtAppPath3 = $Window.FindName('txtAppPath3')
$txtAppPath4 = $Window.FindName('txtAppPath4')
$lblJoy1 = $Window.FindName('lblJoy1')
$lblJoy2 = $Window.FindName('lblJoy2')
$lblJoy3 = $Window.FindName('lblJoy3')
$lblJoy4 = $Window.FindName('lblJoy4')
$txtGameArgs = $Window.FindName('txtGameArgs')

$Button8 = $Window.FindName('Button8')
$Button8.Add_Click({
    $lblJoy1.Content = Get-Joystick -Joysticks $Joysticks
})
$Button9 = $Window.FindName('Button9')
$Button9.Add_Click({
    $lblJoy2.Content = Get-Joystick -Joysticks $Joysticks
})
$Button10 = $Window.FindName('Button10')
$Button10.Add_Click({
    $lblJoy3.Content = Get-Joystick -Joysticks $Joysticks
})
$Button11 = $Window.FindName('Button11')
$Button11.Add_Click({
    $lblJoy4.Content = Get-Joystick -Joysticks $Joysticks
})

$Button12 = $Window.FindName('Button12')
$Button12.Add_Click({
    $stackEdit.Visibility= "Collapsed"
    $SelectedGame = ($Window.FindName('ComboGame')).SelectedItem
    
    if ($SelectedGame -ne $txtGameName.Text) {
        $Options.psobject.properties.remove($SelectedGame)
    } 

    $GameObject = [PSCustomObject]@{
        Name = $txtGameName.Text
        GamePath = $txtGamePath.Text
        AppPath1 = $txtAppPath1.Text
        AppPath2 = $txtAppPath2.Text
        AppPath3 = $txtAppPath3.Text
        AppPath4 = $txtAppPath4.Text
        Arg1 = $txtGameArgs.Text
        Selections = [PSCustomObject]@{
            Stick1=$lblJoy1.Content
            Stick2=$lblJoy2.Content
            Stick3=$lblJoy3.Content
            Stick4=$lblJoy4.Content
        }
    }
    Add-Member -InputObject $Options -MemberType NoteProperty -Name $txtGameName.Text -Value $GameObject
    $Options | ConvertTo-Json | Out-File -FilePath "$env:APPDATA\DBLauncher\Games.json"
    
    $Script:Games = foreach($G in $Options.PsObject.Properties){
        $G.Name
    }
    $ComboGame.ItemsSource = $Games
    
})

$btnCancel = $Window.FindName('btnCancel')
$btnCancel.Add_Click({
    $stackEdit.Visibility= "Collapsed"
})

$btnNewGame = $Window.FindName('btnNewGame')
$btnNewGame.Add_Click({
    $Script:Games = foreach($G in $Options.PsObject.Properties){
        $G.Name
    }
    $ComboGame.ItemsSource = $Games
    $stackEdit.Visibility = "Visible"
})

$Button13 = $Window.FindName('Button13')
$Button13.Add_Click({
    $stackEdit.Visibility = "Visible"
    $Game = ($Window.FindName('ComboGame')).SelectedItem
    
    $txtGameName.Text = $Options.$Game.Name
    $txtGamePath.Text = $Options.$Game.GamePath
    $txtAppPath1.Text = $Options.$Game.AppPath1
    $txtAppPath2.Text = $Options.$Game.AppPath2
    $txtAppPath3.Text = $Options.$Game.AppPath3
    $txtAppPath4.Text = $Options.$Game.AppPath4
    $txtGameArgs.Text = $Options.$Game.Arg1
    $lblJoy1.Content = $Options.$Game.Selections.Stick1
    $lblJoy2.Content = $Options.$Game.Selections.Stick2
    $lblJoy3.Content = $Options.$Game.Selections.Stick3
    $lblJoy4.Content = $Options.$Game.Selections.Stick4
    
})
$Window.ShowDialog() | Out-Null
