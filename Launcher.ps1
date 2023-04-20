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
    $Options = [PSCustomObject]@{   
        ' ' = [PSCustomObject]@{ 
            Name= $null
            Path = $null
            Path2 = $null
            Path3 = $null
            Path4 = $null
            Path5 = $null
            Selections = [PSCustomObject]@{
                Stick1= $null
                Stick2= $null
                Stick3= $null
                Stick4= $null
            }
        }

    }
    $Options | ConvertTo-Json | Out-File -FilePath "$GamesJson"
    $Options
}

Function Get-FilePath {
    Add-Type -AssemblyName System.Windows.Forms

    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.initialDirectory = $initialDirectory
    $OpenFileDialog.filter = "All files (*.*)| *.*"
    $OpenFileDialog.ShowDialog() | Out-Null
    $Path = $OpenFileDialog.filename
    $Path
}
Function Set-Settings {

    $path = Get-FilePath

    $Settings = [PSCustomObject]@{
        usbdview = $path
        
    }
    $Settings | ConvertTo-Json | Out-File -FilePath "$MyAppData\Settings.json"

    # Return
    $Settings
}
Function Get-Joysticks {
    
    $SplashPnpDevice = Import-Xaml "SplashPnpDevice.xaml"
    $SplashPnpDevice.Add_ContentRendered({
        $output = Get-PnpDevice -PresentOnly | Where-Object { $_.InstanceId -match '^USB'}
        $output = $output | Where-Object {$_.FriendlyName -notmatch 'Hub'  } 
        #$output = $output | Where-Object {$_.FriendlyName -notmatch 'USB Audio'}
       
        #$output = $output | Where-Object {$_.FriendlyName -notmatch 'Receiver'}
        #$output = $output | Where-Object {$_.FriendlyName -notmatch 'ButtKicker'}
        #$output = $output | Where-Object {$_.FriendlyName -notmatch 'USB Receiver'}

        $output = $output | Where-Object {$_.Class -notmatch 'Image' -and $_.Class -notmatch 'Media' -and $_.Class -notmatch 'Bluetooth' -and $_.Class -notmatch 'DiskDrive' -and $_.Class -notmatch 'USBDevice'}
        $Script:Sticks = @()
        $filter = @(
                'Receiver',
                'LianLi',
                'USB',
                'ITE Device',
                'ButtKicker',
                'Mic',
                'WebCam'
            )
        foreach ($stick in $output) {
            $filterMatch = $false
            $stickId = $stick.InstanceId
            $Details = Get-PnpDeviceProperty -InstanceId $StickID
            foreach ($detail in $Details) {
                if ($detail.keyname -eq 'DEVPKEY_Device_BusReportedDeviceDesc') {
                    $StickName = $detail.Data
                }
            }
            
            foreach ($i in $filter) {
                if ($StickName -match $i){
                    $filterMatch = $true
                }
            }
            IF (!($filterMatch)) {
                $Script:Sticks += [PSCustomObject]@{
                    Name = $stickName
                    ID = $stickId
                }
            }
            
            $stickId = $null
            $StickName = $null

        }
        
        $SplashPnpDevice.Close()
    })
    
    $SplashPnpDevice.ShowDialog() | Out-Null
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

    $Splash = Import-Xaml "Splash.xaml"
    $Splash.Add_ContentRendered({    
        
    
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
                    Start-Process -FilePath $Options.$Game.GamePath -Wait -ArgumentList $Options.$Game.Arg1 -Credential $Creds
                } Else {
                    Start-Process -FilePath $Options.$Game.GamePath -Wait -Credential $Creds
                }
                $Splash.Close()
            }
        }
    })
    $Splash.ShowDialog() | Out-Null
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

Function Show-Message {
    param (
        [Parameter(Mandatory)]$Message,
        [Switch]$Question
    )
    Add-Type -AssemblyName PresentationCore,PresentationFramework
    IF ($Question) {
        $ButtonType = [System.Windows.MessageBoxButton]::YesNo
        $MessageIcon = [System.Windows.MessageBoxImage]::Question
        $MessageTitle = "Confirmation"
    } Else {
        $ButtonType = [System.Windows.MessageBoxButton]::OK
        $MessageIcon = [System.Windows.MessageBoxImage]::Error
        $MessageTitle = "Error"
    }
    $MessageBody = $Message
    $Result = [System.Windows.MessageBox]::Show($MessageBody,$MessageTitle,$ButtonType,$MessageIcon)
    $Result
}


#Initial Setup

#Get Credentials or set them if needed
try {
    $Creds = (Get-StoredCredential -Target "GameLauncher")
    If (!(Get-StoredCredential -Target "GameLauncher")){
        Write-Warning -Message "Credentials don't exist, prompting user"
        $Creds = Get-Credential -Message "Enter your windows username and Password to run the game" | New-StoredCredential -Target "GameLauncher" -Type Generic -Persist Enterprise
        $Creds = (Get-StoredCredential -Target "GameLauncher")
    }
} catch {
    Show-Message -Message "Failure to set Credentials"
}
# Check that we are running as admin and restart if we aren't
$myScript = $myinvocation.mycommand.definition
$null = Test-Admin -MyScript "$Myscript"

#Set up Paths for config files
$MyAppData = "$env:APPDATA\HOTAS Launcher"
$SettingsPath = "$MyAppData\settings.json"
$GamesJson = "$MyAppData\Games.json"

# Check that we have a settings directory and if not create it.
If (!(Test-Path -Path $MyAppData)) {
    mkdir $MyAppData
}

#Get existing settings or create them
IF (Test-Path -Path "$SettingsPath") {
    $settings = Get-Content -Path "$SettingsPath" -Raw | ConvertFrom-Json
    $path = $Settings.usbdview
} Else {
    $Settings = Set-Settings
    $path = $Settings.usbdview
}

#Get the Joysticks now.
$Joysticks = @(Get-Joysticks)

#Test if we have a Games.json file and create it if needed
IF (!(Test-Path -Path $GamesJson)){
    $Options = Set-Config
}

#read the contents of the Games.json file
$Options = Get-Content -Path "$GamesJson" -Raw | ConvertFrom-Json

# Set up a variable to use as the source for our combobox
$Script:Games = foreach($G in $Options.PsObject.Properties){
    $G.Name
}

#Create the Window

$Window = Import-Xaml "Main.xaml"

#Make some stack Panels so we can hide them as needed and Hide the edit panel
$stackEdit = $Window.FindName('stackEdit')
$stackEdit.Visibility = "Collapsed"
$stackCombo = $Window.FindName('stackCombo')
$stackControls = $Window.FindName('stackControls')

#Make a combobox and bind to our list of games
$ComboGame = $Window.FindName('ComboGame')
$ComboGame.ItemsSource = $Games

#Populate labels and text boxes with bindings
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

#Assign bindings for some buttons and click actions for them
$btnStart = $Window.FindName('btnStart')
$btnStart.Add_Click({
    Try {
        IF ($ComboGame.SelectedItem -ne ' ') { 
            $btnStart.Visibility = 'Collapsed'
            $btnStop.Visibility = 'Visible'
            $ComboGame.Visibility = 'Collapsed'
            $StackControls.Visibility = 'Collapsed'

            $Game = $ComboGame.SelectedItem
            Start-Game -Game $Game -Options $Options -Joysticks $Joysticks
        }
    } Catch {
        Show-Message -Message "Game Settings invalid Please Fix your thing!"
    }
})

$btnStop = $Window.FindName('btnStop')
$btnStop.Add_Click({
    IF ($ComboGame.SelectedItem -ne ' ') {
        $btnStart.Visibility = 'Visible'
        $btnStop.Visibility = 'Collapsed'
        $ComboGame.Visibility = 'Visible'
        $StackControls.Visibility = 'Visible'

        $Game = ($Window.FindName('ComboGame')).SelectedItem
        Stop-Game -Game $Game -Options $Options -Joysticks $Joysticks
        
    }
})

$btnBrowseGame = $Window.FindName('btnBrowseGame')
$btnBrowseGame.Add_Click({
    $txtGamePath.Text = Get-FilePath
})

$btnBrowseApp1 = $Window.FindName('btnBrowseApp1')
$btnBrowseApp1.Add_Click({
    $txtAppPath1.Text = Get-FilePath
})

$btnBrowseApp2 = $Window.FindName('btnBrowseApp2')
$btnBrowseApp2.Add_Click({
    $txtAppPath2.Text = Get-FilePath
})

$btnBrowseApp3 = $Window.FindName('btnBrowseApp3')
$btnBrowseApp3.Add_Click({
    $txtAppPath3.Text = Get-FilePath
})

$btnBrowseApp4 = $Window.FindName('btnBrowseApp4')
$btnBrowseApp4.Add_Click({
    $txtAppPath4.Text = Get-FilePath
})

$btnJoy1 = $Window.FindName('btnJoy1')
$btnJoy1.Add_Click({
    $lblJoy1.Content = Get-Joystick -Joysticks $Joysticks
})

$btnJoy2 = $Window.FindName('btnJoy2')
$btnJoy2.Add_Click({
    $lblJoy2.Content = Get-Joystick -Joysticks $Joysticks
})

$btnJoy3 = $Window.FindName('btnJoy3')
$btnJoy3.Add_Click({
    $lblJoy3.Content = Get-Joystick -Joysticks $Joysticks
})

$btnJoy4 = $Window.FindName('btnJoy4')
$btnJoy4.Add_Click({
    $lblJoy4.Content = Get-Joystick -Joysticks $Joysticks
})

$btnSaveGame = $Window.FindName('btnSaveGame')
$btnSaveGame.Add_Click({
    Try {
        $SelectedGame = ($Window.FindName('ComboGame')).SelectedItem
        
        IF ($SelectedGame -ne " "){
            if ($SelectedGame -ne $txtGameName.Text) {
                $Options.psobject.properties.remove($SelectedGame)
            } 
        }
        #Create the object with all the properties needed for each game config and assign values from the text boxes
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
        #Add the object to $Options and overwrite if it already exists
        Add-Member -InputObject $Options -MemberType NoteProperty -Name $txtGameName.Text -Value $GameObject -Force
        #Write the changes to file
        $Options | ConvertTo-Json | Out-File -FilePath "$GamesJson"
        # Reset the source for the combobox to refresh it
        $Games = foreach($G in $Options.PsObject.Properties){
            $G.Name
        }
        $ComboGame.ItemsSource = $Games
        $ComboGame.SelectedItem = $txtGameName.Text
        #Set stackEdit to collapsed and stackCombo to visible
        $stackEdit.Visibility= "Collapsed"
        $stackCombo.Visibility = "Visible"
    } Catch {
        Show-Message -Message "Please ensure you give your game a name"
    }
})

$btnCancelEdit = $Window.FindName('btnCancelEdit')
$btnCancelEdit.Add_Click({
    $stackEdit.Visibility= "Collapsed"
    $stackCombo.Visibility = "Visible"
})

$btnNewGame = $Window.FindName('btnNewGame')
$btnNewGame.Add_Click({
    
    $ComboGame.SelectedItem = " "
    $stackEdit.Visibility = "Visible"
    $stackCombo.Visibility = "Collapsed"
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

$btnEditGame = $Window.FindName('btnEditGame')
$btnEditGame.Add_Click({
    $stackEdit.Visibility = "Visible"
    $stackCombo.Visibility = "Collapsed"
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

$btnDelete = $Window.FindName('btnDelete')
$btnDelete.Add_Click({
    $SelectedGame = ($Window.FindName('ComboGame')).SelectedItem
    $Answer = Show-Message -Message "Are you sure you wish to Delete $SelectedGame ?" -Question
    IF ($Answer -eq 'Yes') {
        IF ($SelectedGame -ne " "){
            $Options.psobject.properties.remove($SelectedGame)
            #Write the changes to file
            $Options | ConvertTo-Json | Out-File -FilePath "$GamesJson"
            # Reset the source for the combobox to refresh it
            $Games = foreach($G in $Options.PsObject.Properties){
                $G.Name
            }
            $ComboGame.ItemsSource = $Games
            $ComboGame.SelectedItem = $txtGameName.Text
        }
    }
})
#Show the window
$Window.ShowDialog() | Out-Null