<#
    Copyright (C) 2023  Daniel Bailey
    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see https://www.gnu.org/licenses/."


Dependencies: (optionally downloaded by the application on first launch). These applications are not distributed or supported by me but can be found in the following locations.
    Powershell Module CredentialManager - https://www.powershellgallery.com/packages/CredentialManager/2.0
    usbdview - https://www.nirsoft.net/utils/

#>
<#
My Madness for versioning (Takes effect after the first release version at 1.0.0.0).
A - Significant (> 25%) changes or additions in functionality or interface.
B - small changes or additions in functionality or interface.
C - minor changes.
D - fixes to a build that do not change the interface or add new features.
#>
#Updates:
<#Alpha
v1.0-alpha     -    Released 20/04/2023

v1.0.0.1-alpha -    Updated Description
                    Update to handling credentials if user does not want to install CredentialManager module
                    Updated comments
                    Added About Window with License info etc
                    Added auto check for updates feature
v1.0.0.2-alpha -    Fixed bug causing version to always be out of date.

v1.0.0.3-alpha -    Removed wait from game launch so that the app window is not locked up while the game is running, it was no longer automating the closure of apps etc anyway.
                    Converted all xml to variables within the main script and modified Import-Xaml to accept a variable or a file using params to enable use of a file while testing or coding the xaml (for formatting help)
                    Add functioning all on and all off buttons to main form utilizing all unique sticks from the various game configs.
#>
<#
v1.0.0.0 -  Added new button for launching the game only, this is handy when the game crashes or you run an update so you need to launch without the apps etc.
            Updated Test-Admin to work for .exe as well as the usual .ps1. This removes the need for manually choosing to run the application as administrator.
            Updated to using PS2EXE to compile my script as a .exe file. Added bonus of being able to put version and copyright info etc in the details of the .exe
            Compiler.ps1 can be used to compile the script with everything pre-filled and pulls the current version from the script below.
            First version I consider at full release, all initially planned features are now implemented.
v1.0.0.1 -  Bugfix: When creating a new game config not selecting the blank entry insisted that you had not given the config a name.
v1.0.1.0 -  Addition to current feature. Request from JSmith: support for up to 10 controllers.
            Addition to current feature. Request from Vincent: removed Apostophie from Game Path's on Settings window.
v1.0.1.1 -  Bugfix: Removed buggy line of code introduced while fixing the last bug....
v1.0.2.0 -  Implemented Tooltips
            Added loading screen for turning all controllers on.
            Updated wording on splash screen
            Updated wording throughout the app to use Game Controller or Controller instead of Joysticks, seems more appropriate considering button boxes, stearing wheels etc.
            Added "Add to blacklist" button when adding a controller, this removes it from the list and adds the device to a blacklist in settings. Also running Get-Joysticks (done every startup) Adds a default blacklist if it does not exist in settings.
            Added "Clear blacklist button"
            Moved Settings, new game, Delete Game into file menu and renamed to config...
v1.0.2.1 -  Fixed a couple minor bugs introduced in last patch that only showed up when running the compiled version.
v1.0.2.2 -  Ditto
#>
param(
[switch]$Elevated
)
$version = "v1.0.3.0"
$style = "Normal"

function Import-Xaml {
    
    Param(
        [String]$xfile,
        $xvar
    )
    [System.Reflection.Assembly]::LoadWithPartialName("PresentationFramework") | Out-Null
	IF ($xfile) {
        [xml]$xaml = Get-Content -Path $psScriptRoot\$xfile
    }
    IF ($xvar) {
        [xml]$xaml = $xvar
    }
    $manager = New-Object System.Xml.XmlNamespaceManager -ArgumentList $xaml.NameTable
	$manager.AddNamespace("x", "http://schemas.microsoft.com/winfx/2006/xaml");
	$xamlReader = New-Object System.Xml.XmlNodeReader $xaml
	[Windows.Markup.XamlReader]::Load($xamlReader)
}

function Test-Admin {
    Param(
    [String]$myScript,
    [String]$elevated,
    [Switch]$test,
    [Switch]$exe,
    [Switch]$restart,
    $style
    ) 
    $currentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
    $Admin = $currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
    #$currentUser
    IF ($Admin -ne $true -or $restart -eq $true) {
        IF ($test -eq $false) {
            if ($elevated) {
                Write-Warning -Message "tried to elevate, did not work, aborting"
            } else {
                Write-Host "Launching As Admin"
                IF ($exe.IsPresent) {
                    $Arguments =  '-elevated' ; Start-Process $myscript -Verb runAs -ArgumentList "$Arguments" ; exit
                } Else {
                    $Scriptpath =  "& '" + $myScript + "' -elevated" ; Start-Process powershell -Verb runAs -WindowStyle $style -ArgumentList "$Scriptpath" ; exit
                }
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
                Stick5= $null
                Stick6= $null
                Stick7= $null
                Stick8= $null
                Stick9= $null
                Stick10= $null
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
    
    $Download = Show-Message -Message "Would you like to download usbdview automatically from https://www.nirsoft.net/utils/ ?" -Question
    IF ($download -eq 'Yes') {
        Try {
            $url = "https://www.nirsoft.net/utils/usbdeview-x64.zip"
            Invoke-WebRequest $url -OutFile $MyAppData\usbdeview-x64.zip
            Expand-Archive -Path $MyAppData\usbdeview-x64.zip -DestinationPath $MyAppData\usbdeview-x64
            Remove-Item -Path $MyAppData\usbdeview-x64.zip
            $path = "$MyAppData\usbdeView-x64\usbdeview.exe"
        } Catch {
            Show-Message -Message "Download Failed, Please Download usbdview from https://www.nirsoft.net/utils/ and select USBDeview.exe in the next window"
            $path = Get-FilePath
        }
    } Else {
        Show-Message -Message "Please Download usbdview from https://www.nirsoft.net/utils/ and select USBDeview.exe in the next window"
        $path = Get-FilePath
    }

    $Settings = [PSCustomObject]@{
        usbdview = $path
        lastGame = $false
        updatecheck = $true
    }
    $Settings | ConvertTo-Json | Out-File -FilePath "$MyAppData\Settings.json"

    # Return
    $Settings
}

Function Set-Blacklist{
    Param(
        $Settings
    )
    $Settings.psobject.properties.remove('Blacklist')
    $blacklist = @(
                'Receiver',
                'USB',
                'ITE Device',
                'ButtKicker',
                'Mic',
                'WebCam'
            )
            $Settings | Add-Member -NotePropertyName "blacklist" -NotePropertyValue @($blacklist)
            $Settings | ConvertTo-Json | Out-File -FilePath "$MyAppData\Settings.json"
            $Script:Settings = $Settings
            $Settings
}

Function Get-Joysticks {
    Param(
        $xml,
        $Settings
    )
    
    $SplashPnpDevice = Import-Xaml -xvar $xml
    $SplashPnpDevice.Add_ContentRendered({
        $output = Get-PnpDevice -PresentOnly | Where-Object { $_.InstanceId -match '^USB'}
        $output = $output | Where-Object {$_.FriendlyName -notmatch 'Hub'  } 
        $output = $output | Where-Object {$_.Class -notmatch 'Image' -and $_.Class -notmatch 'Media' -and $_.Class -notmatch 'Bluetooth' -and $_.Class -notmatch 'DiskDrive' -and $_.Class -notmatch 'USBDevice'}
        $Script:Sticks = @()
        IF ($null -eq $Settings.blacklist) {
            $Settings = Set-Blacklist -Settings $Settings
        }
        $filter = @($Settings.blacklist)
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

Function Get-Joystick-old {
    param(
        $Joysticks,
        $Settings,
        $MyAppData
    )
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $form = New-Object System.Windows.Forms.Form
    $form.Text = 'Select a Controller'
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
    $label.Text = 'Please select a Controller and click Add or add to blacklist:'
    $form.Controls.Add($label)

    $listBox = New-Object System.Windows.Forms.ListBox
    $listBox.Location = New-Object System.Drawing.Point(10,60)
    $listBox.Size = New-Object System.Drawing.Size(400,350)

    $blButton = New-Object System.Windows.Forms.Button
    $blButton.Location = New-Object System.Drawing.Point(250,425)
    $blButton.Size = New-Object System.Drawing.Size(100,23)
    $blButton.Text = 'Add to Blacklist'
    $blButton.DialogResult = [System.Windows.Forms.DialogResult]::Abort
    $blButton.Add_Click{
        $x = $listBox.SelectedItem
        $listBox.Items.Remove($x)
        Try {
            $Settings.blacklist += $x 
        } Catch {
            $Settings | Add-Member -NotePropertyName "blacklist" -NotePropertyValue @($x)
        }
        $Settings | ConvertTo-Json | Out-File -FilePath "$MyAppData\Settings.json"
        $Script:Joysticks = $Joysticks | Where-Object { $_.Name -notMatch ($x) }
    }
    $form.Controls.Add($blButton)

    $sticks = foreach($item in $Joysticks){
        $Item.Name
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
        if ($result -eq [System.Windows.Forms.DialogResult]::Cancel){
            $null
        } Else {
            $false
        }
        
        #$false
    }
    
}

Function Get-Controller {
    param(
        $Joysticks,
        $Settings,
        $MyAppData,
        $xml
    )
    #Create the Window
    $WindowController = Import-Xaml -xvar $xml
    #Place Buttons and connect to them on the form
    $btnOk = $WindowController.FindName('btnOk')
    $btnOk.Add_Click({
        $WindowController.Tag = $lstController.SelectedItem
        $WindowController.Close()
    })
    $btnCancel=$WindowController.FindName('btnCancel')
    $btnCancel.Add_Click({
        $WindowController.Tag = $null
        $windowController.Close()
    })
    $btnBlacklist=$WindowController.FindName('btnBlacklist')
    $btnBlacklist.Add_Click{
        ForEach ($i in @($lstController.SelectedItems)) {
            While ($lstControllerCollection -contains $i) {
                $lstControllerCollection.Remove($i)
            }
            Try {
                IF ($Settings.blacklist -notcontains $i) {
                    $Settings.blacklist += $i 
                }
            } Catch {
                $Settings | Add-Member -NotePropertyName "blacklist" -NotePropertyValue @($i)
            }
            $Script:Joysticks = $Joysticks | Where-Object { $_.Name -notMatch ($i) }
        }
        $Settings | ConvertTo-Json | Out-File -FilePath "$MyAppData\Settings.json"
    }
   
    #connect to the listbox
    $lstController = $WindowController.FindName('lstController')
    #Create a list of controllers
    $Controllers = foreach($item in $Joysticks){$Item.Name}
    #Setup an Observable Collection and add the controllers to it
    $lstControllerCollection = New-Object System.Collections.ObjectModel.ObservableCollection[string]
    Foreach ($i in $Controllers) {
        $lstControllerCollection.Add($i)
    }
    #Set the ItemSource to the Observable Collection
    $lstController.ItemsSource = $lstControllerCollection
    
    # Make sure Window is on Top?
    

    # Show the Window and return the result
    $null = $WindowController.ShowDialog()
    $WindowController.Tag
}

Function Start-Game {
    param(
        [String]$Game,
        $Options,
        $Joysticks,
        $xml,
        [Switch]$NoApps
    )

    $Splash = Import-Xaml -xvar $xml
    $Splash.Add_ContentRendered({    
        
    
        $Selections = foreach($item in $Options.$Game.Selections.PsObject.Properties) {
            IF ($Null -ne $item.value -and $item.value -ne $False){
                Add-Member -in $item.value -NotePropertyName 'name' -NotePropertyValue $item.name -PassThru
            }
        }
        
        # Turn it all On
        IF (!($NoApps)){
            ForEach ($Selection in $Selections) {
                $Stick = $Joysticks | Where-Object {$_.Name -eq $Selection}
                $SelectedStick = $Stick.ID
                Write-Host $Stick.ID
                Start-Process -FilePath $Path -ArgumentList "/RunAsAdmin /enable $SelectedStick"
                Timeout /T 5
            }
        }
        
        # Start the Game
        IF ($Game) {
            IF ($Game -ne 'DEMO') {
                IF (!($NoApps)) {
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
                }
                Write-Host "Starting $Game"
                IF ($Options.$Game.arg1) {
                    Start-Process -FilePath $Options.$Game.GamePath -ArgumentList $Options.$Game.Arg1 -Credential $Creds
                } Else {
                    Start-Process -FilePath $Options.$Game.GamePath -Credential $Creds
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

Function Switch-All {
    Param(
        $Joysticks,
        $Options,
        [Switch]$On,
        [Switch]$Off,
        $xml
    )
    
    $All = @()
    Foreach($G in $Options.PsObject.Properties) {
        $Game = $G.Name
        foreach($item in $Options.$Game.Selections.PsObject.Properties) {
            $i = $Item.value
            IF ($Null -ne $i -and $i -ne $False){ 
                $all += $i
            }
        }
    }
    $all = $all | Sort-Object -Unique

    IF ($On) {
        $Splash = Import-Xaml -xvar $xml
        $Splash.Add_ContentRendered({
            ForEach ($Selection in $All) {
                $Stick = $Joysticks | Where-Object {$_.Name -eq $Selection}
                $SelectedStick = $Stick.ID
                Start-Process -FilePath $Path -ArgumentList "/RunAsAdmin /enable $SelectedStick"
                Timeout /T 5
            }
            $Splash.Close()
        })
        $Splash.ShowDialog() | Out-Null
    }
    IF ($Off) {
        ForEach ($Selection in $All) {
            $Stick = $Joysticks | Where-Object {$_.Name -eq $Selection}
            $SelectedStick = $Stick.ID
            Write-Host $Stick.ID
            Start-Process -FilePath $Path -ArgumentList "/RunAsAdmin /disable $SelectedStick"
        }
    }
}

# Check that we are running as admin and restart if we aren't
$myScript = $myinvocation.mycommand.definition
if ($myScript -like "*.ps1") {
    $null = Test-Admin -MyScript "$Myscript" -style $Style
} Else {
    $null = Test-Admin -Myscript "$Myscript" -exe -style $Style
}
#Set up the xml variables
$xmlMain = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Hotas Launcher"
        Background="#66ffcc"
        SizeToContent="WidthAndHeight"
        ResizeMode="CanMinimize"
        MinHeight="300"
        MinWidth="300"
>
    <StackPanel>
        <DockPanel>
            <Menu DockPanel.Dock="Top">
                <MenuItem Header="_File">
                    <MenuItem Header="_Change Config" x:Name="btnEditGame" />
                    <MenuItem Header="_New Config" x:Name="btnNewGame" />
                    <Separator />
                    <MenuItem Header="_Delete Config" x:Name="btnDelete" />
                    <Separator />
                    <MenuItem Header="_Clear Blacklist" x:Name="btnClearBlacklist" />
                </MenuItem>
                <MenuItem Header="_Help">
                    <MenuItem Header="Check for Updates on Startup" x:Name="chkVersion" IsCheckable="True" />
                    <Separator />
                    <MenuItem Header="_About" x:Name="btnAbout" />
                </MenuItem>
            </Menu>
        </DockPanel>
        <StackPanel x:Name="stackCombo" Background="#eae4ee" Orientation="Vertical" HorizontalAlignment="Center" Margin='10'>
            <ComboBox x:Name="ComboGame" ToolTip="Select a Config" Margin="5" Height="25" Width="200" Padding="3"></ComboBox>
                <Button Content="Start" x:Name="btnStart" ToolTip="Start Game and enable selected controllers" Height="30" Width="150" Margin="5"/>
                <Button Content="Game Only" x:Name="btnStartGO" ToolTip="Launch the game without controllers" Height="30" Width="150" Margin="5"/>
                <Button Content="Stop" x:Name="btnStop" ToolTip="Stop the game and disable controllers" Visibility='Collapsed' Height="30" Width="150" Margin="5"/>
                <StackPanel Background="#66ffcc" Margin="0">
                <Label Padding="3"></Label>
                </StackPanel>
                <StackPanel x:Name="stackControls" Margin="0" Orientation="Vertical" HorizontalAlignment="Center">
                <Button Content="All On" x:Name="btnAllOn" ToolTip="Turn on all controllers from all configurations" Height="25" Width="90" Margin="5"/>
                <Button Content="All Off" x:Name="btnAllOff" ToolTip="Turn off all controllers from all configurations" Height="25" Width="90" Margin="5"/>
            </StackPanel>
        </StackPanel>
        <StackPanel Background="#eae4ee" x:Name="stackEdit" Margin="10">
            <StackPanel Margin="5" Orientation="Horizontal" HorizontalAlignment="Left">
                <Label Width="70" Height="25" Padding="3" Margin="5">Name</Label>
                <TextBox x:Name="txtGameName" Width = "300" Height="25" Padding="3" Margin="5"/>
            </StackPanel>
            <StackPanel Background="#66ffcc">
                <Label FontSize="25" Height="50" Padding="3" Margin="0">Paths</Label>
            </StackPanel>
            <StackPanel Margin="5 0 0 5" Orientation="Horizontal" HorizontalAlignment="Left">
                <Label Width="70" Height="25" Padding="3" Margin="5">Game Path</Label>
                <TextBox x:Name="txtGamePath" Width = "300" Height="25" Padding="3" Margin="5"/>
                <Button x:Name="btnBrowseGame" Content="Browse" ToolTip="Select Game executable/launcher" Height="25" Width="100" Margin="5"/>
            </StackPanel>
            <StackPanel Margin="5 0 0 5" Orientation="Horizontal" HorizontalAlignment="Left">    
                    <Label Width="70" Height="25" Padding="3" Margin="5">Switches</Label>
                    <TextBox x:Name="txtGameArgs" Width = "150" Height="25" Padding="3" Margin="5"/>
                </StackPanel>
            <StackPanel Margin="5" Orientation="Horizontal" HorizontalAlignment="Left">
                <Label Width="70" Height="25" Padding="3" Margin="5">App1 Path</Label>
                <TextBox x:Name="txtAppPath1" Width = "300" Height="25" Padding="3" Margin="5"/>
                <Button x:Name="btnBrowseApp1" Content="Browse" ToolTip="Browse to select Optional support app 1" Height="25" Width="100" Margin="5"/>
            </StackPanel>
            <StackPanel Margin="5" Orientation="Horizontal" HorizontalAlignment="Left">
                <Label Width="70" Height="25" Padding="3" Margin="5">App2 Path</Label>
                <TextBox x:Name="txtAppPath2" Width = "300" Height="25" Padding="3" Margin="5"/>
                <Button x:Name="btnBrowseApp2" Content="Browse" ToolTip="Browse to select Optional support app 2" Height="25" Width="100" Margin="5"/>
            </StackPanel>
            <StackPanel Margin="5" Orientation="Horizontal" HorizontalAlignment="Left">
                <Label Width="70" Height="25" Padding="3" Margin="5">App3 Path</Label>
                <TextBox x:Name="txtAppPath3" Width = "300" Height="25" Padding="3" Margin="5"/>
                <Button x:Name="btnBrowseApp3" Content="Browse" ToolTip="Browse to select Optional support app 3" Height="25" Width="100" Margin="5"/>
            </StackPanel>
            <StackPanel Margin="5" Orientation="Horizontal" HorizontalAlignment="Left">
                <Label Width="70" Height="25" Padding="3" Margin="5">App4 Path</Label>
                <TextBox x:Name="txtAppPath4" Width = "300" Height="25" Padding="3" Margin="5"/>
                <Button x:Name="btnBrowseApp4" Content="Browse" ToolTip="Browse to select Optional support app 4" Height="25" Width="100" Margin="5"/>
            </StackPanel>
            <StackPanel Background="#66ffcc">
                <Label FontSize="25" Height="50" Padding="0" Margin="0">Controllers</Label>
            </StackPanel>
            <StackPanel Margin="5" Orientation="Horizontal" HorizontalAlignment="Left">
                <Label Width="75" Height="25" Padding="3" Margin="5">Controller 1</Label>
                <Label x:Name="lblJoy1" Width="300" Height="25" Padding="3" Margin="5" Background="white" />
                <Button x:Name="btnJoy1" Content="Select" ToolTip="Browse to select Controller 1" Height="25" Width="100" Margin="5"/>
            </StackPanel>
            <StackPanel Margin="5" Orientation="Horizontal" HorizontalAlignment="Left">
                <Label Width="75" Height="25" Padding="3" Margin="5">Controller 2</Label>
                <Label x:Name="lblJoy2" Width="300" Height="25" Padding="3" Margin="5" Background="white"/>
                <Button x:Name="btnJoy2" Content="Select" ToolTip="Browse to select Controller 2" Height="25" Width="100" Margin="5"/>
            </StackPanel>
            <StackPanel Margin="5" Orientation="Horizontal" HorizontalAlignment="Left">
                <Label Width="75" Height="25" Padding="3" Margin="5">Controller 3</Label>
                <Label x:Name="lblJoy3" Width="300" Height="25" Padding="3" Margin="5" Background="white"/>
                <Button x:Name="btnJoy3" Content="Select" ToolTip="Browse to select Controller 3" Height="25" Width="100" Margin="5"/>
            </StackPanel>
            <StackPanel Margin="5" Orientation="Horizontal" HorizontalAlignment="Left">
                <Label Width="75" Height="25" Padding="3" Margin="5">Controller 4</Label>
                <Label x:Name="lblJoy4" Width="300" Height="25" Padding="3" Margin="5" Background="white"/>
                <Button x:Name="btnJoy4" Content="Select" ToolTip="Browse to select Controller 4" Height="25" Width="100" Margin="5"/>
            </StackPanel>
            <StackPanel Margin="5" Orientation="Horizontal" HorizontalAlignment="Left">
                <Label Width="75" Height="25" Padding="3" Margin="5">Controller 5</Label>
                <Label x:Name="lblJoy5" Width="300" Height="25" Padding="3" Margin="5" Background="white"/>
                <Button x:Name="btnJoy5" Content="Select" ToolTip="Browse to select Controller 5" Height="25" Width="100" Margin="5"/>
            </StackPanel>
            <StackPanel Margin="5" Orientation="Horizontal" HorizontalAlignment="Left">
                <Label Width="75" Height="25" Padding="3" Margin="5">Controller 6</Label>
                <Label x:Name="lblJoy6" Width="300" Height="25" Padding="3" Margin="5" Background="white"/>
                <Button x:Name="btnJoy6" Content="Select" ToolTip="Browse to select Controller 6" Height="25" Width="100" Margin="5"/>
            </StackPanel>
            <StackPanel Margin="5" Orientation="Horizontal" HorizontalAlignment="Left">
                <Label Width="75" Height="25" Padding="3" Margin="5">Controller 7</Label>
                <Label x:Name="lblJoy7" Width="300" Height="25" Padding="3" Margin="5" Background="white"/>
                <Button x:Name="btnJoy7" Content="Select" ToolTip="Browse to select Controller 7" Height="25" Width="100" Margin="5"/>
            </StackPanel>
            <StackPanel Margin="5" Orientation="Horizontal" HorizontalAlignment="Left">
                <Label Width="75" Height="25" Padding="3" Margin="5">Controller 8</Label>
                <Label x:Name="lblJoy8" Width="300" Height="25" Padding="3" Margin="5" Background="white"/>
                <Button x:Name="btnJoy8" Content="Select" ToolTip="Browse to select Controller 8" Height="25" Width="100" Margin="5"/>
            </StackPanel>
            <StackPanel Margin="5" Orientation="Horizontal" HorizontalAlignment="Left">
                <Label Width="75" Height="25" Padding="3" Margin="5">Controller 9</Label>
                <Label x:Name="lblJoy9" Width="300" Height="25" Padding="3" Margin="5" Background="white"/>
                <Button x:Name="btnJoy9" Content="Select" ToolTip="Browse to select Controller 9" Height="25" Width="100" Margin="5"/>
            </StackPanel>
            <StackPanel Margin="5" Orientation="Horizontal" HorizontalAlignment="Left">
                <Label Width="75" Height="25" Padding="3" Margin="5">Controller 10</Label>
                <Label x:Name="lblJoy10" Width="300" Height="25" Padding="3" Margin="5" Background="white"/>
                <Button x:Name="btnJoy10" Content="Select" ToolTip="Browse to select Controller 10" Height="25" Width="100" Margin="5"/>
            </StackPanel>
            <StackPanel Background="#66ffcc">
                <StackPanel Orientation="Horizontal" HorizontalAlignment="Center">
                    <Button x:Name="btnSaveGame" Content="Save Game Config" ToolTip="Save the config" Height="25" Width="110" Margin="5"/>
                    <Button x:Name="btnCancelEdit" Content="Cancel Edit" ToolTip="Discard changes" Height="25" Width="110" Margin="5"/>
                </StackPanel>
            </StackPanel>
        </StackPanel>
        <StackPanel Margin="0" VerticalAlignment="Bottom" HorizontalAlignment="Left">
            <Label Width="200" Height="25" Padding="3" Margin="5">Copyright, Daniel Bailey 2023</Label>
        </StackPanel>
    </StackPanel>
</Window>
"@
$xmlController = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Select Controller"
        Background="#66ffcc"
        SizeToContent="WidthAndHeight"
        WindowStartupLocation="CenterScreen"
>
<StackPanel Margin="30" Background="#eae4ee" Orientation="Horizontal">
    <StackPanel Margin="5" Background="#eae4ee" Orientation="Vertical">
        <Label FontSize="12" Width="125" Padding="3" Margin="5">Available Controllers</Label>
        <ListBox x:Name="lstController" SelectionMode="Extended" Margin="5"/>
    </StackPanel>
    <StackPanel Margin="5" Background="#eae4ee" Orientation="Vertical">
        <Button Content="Add" x:Name="btnOk" IsDefault="True" ToolTip="Add controller to config" Height="30" Width="150" Margin="5"/>
        <Button Content="Cancel" x:Name="btnCancel" IsCancel="True" ToolTip="Cancel Operation" Height="30" Width="150" Margin="5"/>
        <Button Content="Add to Blacklist" x:Name="btnBlacklist" ToolTip="Add controller to Blacklist to prevent showing here" Height="30" Width="150" Margin="5"/>
    </StackPanel>
</StackPanel>
</Window>
"@
$xmlAbout = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="About"
        Background="#66ffcc"
        SizeToContent="WidthAndHeight"
        MinHeight="200"
        MinWidth="200"
>
<StackPanel Margin="30" Background="#eae4ee">
    <Label FontSize="14" FontWeight="Bold">Source</Label>
    <TextBlock  Margin="10" FontSize="12" TextWrapping="WrapWithOverflow" MaxWidth="600">
        Original source code can be found on github https://github.com/fireblad3/HOTAS-Launcher.
    </TextBlock>
    <Label FontSize="14" FontWeight="Bold">Purpose</Label>
    <TextBlock Margin="10" FontSize="12" TextWrapping="WrapWithOverflow" MaxWidth="600">
        I was getting frustrated with two things, first because I have 5 usb controllers my PC would not enter sleep
        or standby modes, Disabling each one Manually when I finished playing was not an option.
    </TextBlock>
    <TextBlock Margin="10" FontSize="12" TextWrapping="WrapWithOverflow" MaxWidth="600">
        Secondly, I found it very frustrating when I launched Star Citizen after re-plugging any
        or all of my joysticks (or forgot to turn off my wheel after racing) and suddenly Star Citizen
        would have re-organized my sticks and messed up all the mappings.
    </TextBlock>
    <TextBlock Margin="10" FontSize="12" TextWrapping="WrapWithOverflow" MaxWidth="600">
        For me this application solves both of those issues and also allows me to launch other supporting programs such as
        Transducer applications, Windowed Borderless Gaming, crew cheif etc and close them when I'm done with one simple button.
    </TextBlock>
    <Label FontSize="14" FontWeight="Bold">Copyright</Label>
    <TextBlock Margin="10" FontSize="12" TextWrapping="WrapWithOverflow" MaxWidth="600">
        Copyright (C) 2023  Daniel Bailey
    </TextBlock>
    <TextBlock Margin="10" FontSize="12" TextWrapping="WrapWithOverflow" MaxWidth="600">
        This program is free software: you can redistribute it and/or modify
        it under the terms of the GNU General Public License as published by
        the Free Software Foundation, either version 3 of the License, or
        (at your option) any later version.
    </TextBlock>
    <TextBlock Margin="10" FontSize="12" TextWrapping="WrapWithOverflow" MaxWidth="600">
        This program is distributed in the hope that it will be useful,
        but WITHOUT ANY WARRANTY; without even the implied warranty of
        MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
        GNU General Public License for more details.
    </TextBlock>
    <TextBlock Margin="10" FontSize="12" TextWrapping="WrapWithOverflow" MaxWidth="600">
        You should have received a copy of the GNU General Public License
        along with this program.  If not, see https://www.gnu.org/licenses/."
    </TextBlock>
    <Label FontSize="14" FontWeight="Bold">Dependencies</Label>
    <TextBlock Margin="10" FontSize="12" TextWrapping="WrapWithOverflow" MaxWidth="600">
        Optionally downloaded from the locations below by the application on first launch. 
        These applications are not distributed or supported by me but can be found in the following locations.
    </TextBlock>
    <TextBlock Margin="5" FontSize="12" TextWrapping="WrapWithOverflow" MaxWidth="600">
        Powershell Module CredentialManager - https://www.powershellgallery.com/packages/CredentialManager/2.0
    </TextBlock>
    <TextBlock Margin="5" FontSize="12" TextWrapping="WrapWithOverflow" MaxWidth="600">
        usbdview - https://www.nirsoft.net/utils/
    </TextBlock>
</StackPanel>

</Window>
"@
$xmlSplash = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Enable Game Controllers"
        Background="#66ffcc"
        Width="500"
        Height="200"
        WindowStartupLocation="CenterScreen"
        WindowStyle="None"
>
<StackPanel Margin="10" HorizontalAlignment="Center" VerticalAlignment="Center">
    <Label FontSize="25" Content="Enabling Game Controllers, Please Wait"></Label>
</StackPanel>
</Window>
"@
$xmlSplashpnpDevice = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Find Controllers"
        Background="#66ffcc"
        Width="600"
        Height="200"
        WindowStartupLocation="CenterScreen"
        WindowStyle="None"
>
<StackPanel Margin="10" HorizontalAlignment="Center" VerticalAlignment="Center">
    <Label FontSize="25" Content="Finding Available Game Controllers, Please Wait"></Label>
</StackPanel>
</Window>
"@

# Import the Credential Manager this allows us to save some credentials so that the elevated window can launch the game as your standard user.
if (Get-Module -ListAvailable -Name CredentialManager) {
    Import-Module CredentialManager
    $CredentialsManaged = $true
} else {
    $installCM = Show-Message -Message "The Powershell CredentialManager module is required, okay to install? If you say no you will be prompted for credentials each time" -Question
    IF ($installCM -eq 'Yes') {
        Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
        Install-Module CredentialManager -force
        Import-Module CredentialManager
        $CredentialsManaged = $true
    } Else {
        $CredentialsManaged = $false
    }
}

#Initial Setup

#Get Credentials or set them if needed
IF ($CredentialsManaged) {
    try {
        $Creds = (Get-StoredCredential -Target "HOTAS Launcher")
        If (!(Get-StoredCredential -Target "HOTAS Launcher")){
            Write-Warning -Message "Credentials don't exist, prompting user"
            $Creds = Get-Credential -Message "Enter your windows username and Password to run the game" | New-StoredCredential -Target "HOTAS Launcher" -Type Generic -Persist Enterprise
            $Creds = (Get-StoredCredential -Target "HOTAS Launcher")
        }
    } catch {
        Show-Message -Message $Error
    }
} Else {
    $Creds = (Get-Credential -Message "Please enter your windows username and password for launching the game as your standard user")
}

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
    $Settings = Get-Content -Path "$SettingsPath" -Raw | ConvertFrom-Json
    $path = $Settings.usbdview
    $LastGame = $Settings.lastGame
} Else {
    $Settings = Set-Settings
    $path = $Settings.usbdview
}

#Check if we have the latest version of HOTAS Launcher
IF ($Settings.updatecheck) {
    Try {
        $latestRelease = Invoke-WebRequest https://api.github.com/repos/fireblad3/HOTAS-Launcher/releases -Headers @{"Accept"="application/json"}
        $json = $latestRelease.Content | ConvertFrom-Json
        $Versions = [PSCustomObject]@{
            Version = $json.tag_name
            Created = $json.created_at
        }
        $Versions | Sort-Object -Property 'Created'
        $latestVersion = $Versions.Version[0]
    
        $Ver = [PSCustomObject]@{
            Version = $latestVersion
            URL = "https://github.com/fireblad3/HOTAS-Launcher/releases/download/$latestVersion/hotas.launcher.exe"
        }
        
        if ($Ver.Version -ne $Version) {
            #Time to update
            $URL = $Ver.URL
            $version = $Ver.Version
            $download = Show-Message -Message "There is a new version ($Version) of Hotas-Launcher available Would you like to download it in your browser now?" -Question
            IF ($download -eq "Yes") {
                Start-Process -FilePath $URL
                Exit
            }
        }
    } Catch {
        #$Error
        #Couldn't get version info so presuming no internet and no big deal so failing silently
    }
}

#Get the Joysticks now.
$Joysticks = @(Get-Joysticks -xml $xmlSplashpnpDevice -Settings $Settings)

#Test if we have a Games.json file and create it if needed
IF (Test-Path -Path $GamesJson){
    #read the contents of the Games.json file
    $Options = Get-Content -Path "$GamesJson" -Raw | ConvertFrom-Json
} Else {
    $Options = Set-Config
}

# Set up a variable to use as the source for our combobox
$Script:Games = foreach($G in $Options.PsObject.Properties){
    $G.Name
}
#Create the main Window
#$Window = Import-Xaml "Main.xaml"
$Window = Import-Xaml -xvar $xmlMain
#Bind some stack Panels so we can hide them as needed and Hide the edit panel
$stackEdit = $Window.FindName('stackEdit')
$stackEdit.Visibility = "Collapsed"
$stackCombo = $Window.FindName('stackCombo')
$stackControls = $Window.FindName('stackControls')
#Make a combobox and bind to our list of games
$ComboGame = $Window.FindName('ComboGame')
$ComboGame.ItemsSource = $Games
IF ($Games -contains $LastGame) {
    $ComboGame.SelectedItem = $LastGame
}
#Make a File Menu Item for Update Check
$chkVersion = $Window.FindName('chkVersion')
$chkVersion.IsChecked = $Settings.updatecheck
$chkVersion.Add_Checked({
    Try {
        $Settings.updatecheck = $chkVersion.IsChecked
    } Catch {
        $Settings | Add-Member -NotePropertyName "updatecheck" -NotePropertyValue $chkVersion.IsChecked
    }
    $Settings | ConvertTo-Json | Out-File -FilePath "$MyAppData\Settings.json"
})
$chkVersion.Add_UnChecked({
    Try {
        $Settings.updatecheck = $chkVersion.IsChecked
    } Catch {
        $Settings | Add-Member -NotePropertyName "updatecheck" -NotePropertyValue $chkVersion.IsChecked
    }
    $Settings | ConvertTo-Json | Out-File -FilePath "$MyAppData\Settings.json"
})
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
$lblJoy5 = $Window.FindName('lblJoy5')
$lblJoy6 = $Window.FindName('lblJoy6')
$lblJoy7 = $Window.FindName('lblJoy7')
$lblJoy8 = $Window.FindName('lblJoy8')
$lblJoy9 = $Window.FindName('lblJoy9')
$lblJoy10 = $Window.FindName('lblJoy10')
$txtGameArgs = $Window.FindName('txtGameArgs')

#Assign bindings for some buttons and click actions for them
$btnAbout = $Window.FindName('btnAbout')
$btnAbout.Add_Click({
    $About = Import-Xaml -xvar $xmlAbout
    $About.ShowDialog()
})
$btnClearBlacklist = $Window.FindName('btnClearBlacklist')
$btnClearBlacklist.Add_Click({
    IF ((Show-Message -Message "Are you sure you want to clear the blacklist and restart Hotas Launcher?" -Question) -eq 'yes') {
        $Settings = Set-Blacklist -Settings $Settings
        if ($myScript -like "*.ps1") {
            $null = Test-Admin -MyScript "$Myscript" -restart
        } Else {
            Show-Message -Message "Unable to re-launch Please Launch Hotas Launcher Manually"
            #$null = Test-Admin -Myscript "$Myscript" -restart -exe
        }
    }
})
$btnStart = $Window.FindName('btnStart')
$btnStart.Add_Click({
    Try {
        IF ($ComboGame.SelectedItem -ne ' ') { #Only perform an action if a game is selected
            # Set visibility to hidden on some items to prevent user from crashing the app... and show the stop button
            $btnStart.Visibility = 'Collapsed'
            $btnStop.Visibility = 'Visible'
            $ComboGame.Visibility = 'Collapsed'
            $StackControls.Visibility = 'Collapsed'
            
            #use the game selected from the combobox
            $Game = $ComboGame.SelectedItem
            #Start the game itself using the current game and preferences
            Start-Game -Game $Game -Options $Options -Joysticks $Joysticks -xml $xmlSplash
            #Save the last game we have launched so that we can select it on next launch by default
            $Settings.lastGame = $Game
            $Settings | ConvertTo-Json | Out-File -FilePath $SettingsPath
        }
    } Catch {
        Show-Message -Message "Game Settings invalid Please Fix your thing!"
    }
})
$btnStartGO = $Window.FindName('btnStartGO')
$btnStartGO.Add_Click({
    Try {
        IF ($ComboGame.SelectedItem -ne ' ') { #Only perform an action if a game is selected
            # Set visibility to hidden on some items to prevent user from crashing the app... and show the stop button
            $btnStart.Visibility = 'Collapsed'
            $btnStop.Visibility = 'Visible'
            $ComboGame.Visibility = 'Collapsed'
            $StackControls.Visibility = 'Collapsed'
            
            #use the game selected from the combobox
            $Game = $ComboGame.SelectedItem
            #Start the game itself using the current game and preferences
            Start-Game -Game $Game -Options $Options -Joysticks $Joysticks -xml $xmlSplash -NoApps
            #Save the last game we have launched so that we can select it on next launch by default
            $Settings.lastGame = $Game
            $Settings | ConvertTo-Json | Out-File -FilePath $SettingsPath
        }
    } Catch {
        Show-Message -Message "Game Settings invalid Please Fix your thing!"
    }
})

$btnStop = $Window.FindName('btnStop')
$btnStop.Add_Click({
    IF ($ComboGame.SelectedItem -ne ' ') {#Only perform an action if a game is selected
        # Set visibility to hidden on some items to prevent user from crashing the app... and show the stop button
        $btnStart.Visibility = 'Visible'
        $btnStop.Visibility = 'Collapsed'
        $ComboGame.Visibility = 'Visible'
        $StackControls.Visibility = 'Visible'

        #use the game selected from the combobox
        $Game = ($Window.FindName('ComboGame')).SelectedItem
        #Stop the game using the game selected and preferences
        Stop-Game -Game $Game -Options $Options -Joysticks $Joysticks
        
    }
})

$btnAllOn = $Window.FindName('btnAllOn')
$btnAllOn.Add_Click({
    Switch-All -Joysticks $Joysticks -Options $Options -On -xml $xmlSplash
})

$btnAllOff = $Window.FindName('btnAllOff')
$btnAllOff.Add_Click({
    Switch-All -Joysticks $Joysticks -Options $Options -Off
})

#Populate the file path textboxes using a file picker
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

#Populate the Joysticks textboxes using a Controller picker
$btnJoy1 = $Window.FindName('btnJoy1')
$btnJoy1.Add_Click({
        $result = Get-Controller -Joysticks $Joysticks -Settings $Settings -MyAppData $MyAppData -xml $xmlController
        $lblJoy1.Content = $result
})

$btnJoy2 = $Window.FindName('btnJoy2')
$btnJoy2.Add_Click({
        $result = Get-Controller -Joysticks $Joysticks -Settings $Settings -MyAppData $MyAppData -xml $xmlController
        $lblJoy2.Content = $result
})

$btnJoy3 = $Window.FindName('btnJoy3')
$btnJoy3.Add_Click({
        $result = Get-Controller -Joysticks $Joysticks -Settings $Settings -MyAppData $MyAppData -xml $xmlController
        $lblJoy3.Content = $result
})

$btnJoy4 = $Window.FindName('btnJoy4')
$btnJoy4.Add_Click({
        $result = Get-Controller -Joysticks $Joysticks -Settings $Settings -MyAppData $MyAppData -xml $xmlController
        $lblJoy4.Content = $result
})

$btnJoy5 = $Window.FindName('btnJoy5')
$btnJoy5.Add_Click({
        $result = Get-Controller -Joysticks $Joysticks -Settings $Settings -MyAppData $MyAppData -xml $xmlController
        $lblJoy5.Content = $result
})

$btnJoy6 = $Window.FindName('btnJoy6')
$btnJoy6.Add_Click({
        $result = Get-Controller -Joysticks $Joysticks -Settings $Settings -MyAppData $MyAppData -xml $xmlController
        $lblJoy6.Content = $result
})

$btnJoy7 = $Window.FindName('btnJoy7')
$btnJoy7.Add_Click({
        $result = Get-Controller -Joysticks $Joysticks -Settings $Settings -MyAppData $MyAppData -xml $xmlController
        $lblJoy7.Content = $result
})

$btnJoy8 = $Window.FindName('btnJoy8')
$btnJoy8.Add_Click({
        $result = Get-Controller -Joysticks $Joysticks -Settings $Settings -MyAppData $MyAppData -xml $xmlController
        $lblJoy8.Content = $result
})

$btnJoy9 = $Window.FindName('btnJoy9')
$btnJoy9.Add_Click({
        $result = Get-Controller -Joysticks $Joysticks -Settings $Settings -MyAppData $MyAppData -xml $xmlController
        $lblJoy9.Content = $result
})

$btnJoy10 = $Window.FindName('btnJoy10')
$btnJoy10.Add_Click({
        $result = Get-Controller -Joysticks $Joysticks -Settings $Settings -MyAppData $MyAppData -xml $xmlController
        $lblJoy10.Content = $result
})

$btnSaveGame = $Window.FindName('btnSaveGame')
$btnSaveGame.Add_Click({
    
    #use the game
    $SelectedGame = ($Window.FindName('ComboGame')).SelectedItem
    IF ($SelectedGame -ne " "){ #If we have selected a game and changed the name remove the old one
        if ($SelectedGame -ne $txtGameName.Text) {
            $Options.psobject.properties.remove($SelectedGame)
        }
    }
    
    Try {
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
                Stick5=$lblJoy5.Content
                Stick6=$lblJoy6.Content
                Stick7=$lblJoy7.Content
                Stick8=$lblJoy8.Content
                Stick9=$lblJoy9.Content
                Stick10=$lblJoy10.Content
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
        Show-Message -Message "Please give your game a name"
    }
})

$btnCancelEdit = $Window.FindName('btnCancelEdit')
$btnCancelEdit.Add_Click({
    #not changing anything after all, so lets just hide everything and not use it (it gets refreshed before being shown again if you click edit again)
    $stackEdit.Visibility= "Collapsed"
    $stackCombo.Visibility = "Visible"
})

$btnNewGame = $Window.FindName('btnNewGame')
$btnNewGame.Add_Click({
    #First set the selected Item back to nothing to ensure a blank config is presented
    $ComboGame.SelectedItem = " "
    #Hide the combo box and show the edit fields
    $stackEdit.Visibility = "Visible"
    $stackCombo.Visibility = "Collapsed"
    #Set the game variable as blank to prevent errors and allow us to blank all the fields
    $Game = ($Window.FindName('ComboGame')).SelectedItem
    
    #blank all the fields
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
    $lblJoy5.Content = $Options.$Game.Selections.Stick5
    $lblJoy6.Content = $Options.$Game.Selections.Stick6
    $lblJoy7.Content = $Options.$Game.Selections.Stick7
    $lblJoy8.Content = $Options.$Game.Selections.Stick8
    $lblJoy9.Content = $Options.$Game.Selections.Stick9
    $lblJoy10.Content = $Options.$Game.Selections.Stick10
})

$btnEditGame = $Window.FindName('btnEditGame')
$btnEditGame.Add_Click({
    #hide the combo box to prevent user from causing problems and show the edit fields
    $stackEdit.Visibility = "Visible"
    $stackCombo.Visibility = "Collapsed"
    #Select the game to the selected item from the combobox
    $Game = ($Window.FindName('ComboGame')).SelectedItem
    
    #set all the fields to their current settings
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
    $lblJoy5.Content = $Options.$Game.Selections.Stick5
    $lblJoy6.Content = $Options.$Game.Selections.Stick6
    $lblJoy7.Content = $Options.$Game.Selections.Stick7
    $lblJoy8.Content = $Options.$Game.Selections.Stick8
    $lblJoy9.Content = $Options.$Game.Selections.Stick9
    $lblJoy10.Content = $Options.$Game.Selections.Stick10
    
})

$btnDelete = $Window.FindName('btnDelete')
$btnDelete.Add_Click({
    #lets use the game that is selected for this...
    $SelectedGame = ($Window.FindName('ComboGame')).SelectedItem
    #Double check the user did not get click happy
    $Answer = Show-Message -Message "Are you sure you wish to Delete $SelectedGame ?" -Question
    IF ($Answer -eq 'Yes') {# Well we warned him, lets go...
        IF ($SelectedGame -ne " "){ #nah you're not allowed to delete the blank game ;)
            #Remove the object for that game
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