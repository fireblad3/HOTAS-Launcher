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
v1.0.3.0 -  Rework of GUI including enabling multi select when adding controllers to the blacklist
            Added Feature to prevent launching a game if a controller is not present
            Fixed bug preventing reset blacklist from being displayed without restart of Hotas Launcher
            General code tidy up
            Hopefully fixed Jorgen's bug
v1.0.4.0    Added feature to allow selecting an individual game or supporting app to run as administrator if required.
            Added check to prevent user from using change config to create a new config which caused an error.
            Fixed the logic with downloading or selecting the external app usbdeview which was causing an exception if all the ducks lined up... The application will not run if it can't find it.
            Fixed Exception caused when saving your very first config.
            Fixed Exception caused when deleting a config that doesn't exist
            Fixed Added Checks and Balances on the Credentials supplied, if they don't pass you can't launch the app.
v1.0.5.0    Fixed some apps not loading by Adding -WorkingDirectory to all start-process commands, this allows apps with relative paths launch correctly.
            Added additional 6 app paths for those with many supporting apps...
            Made some gui changes to accomodate the extra paths on a smaller screen
            Added a Configurations menu and moved all configuration stuff in there
            Added an Exit button to the file menu.
v1.0.6.0    Created a new Controllers menu.
            Changed the All on and All off buttons that were on the main window to Controllers on and Controllers off. These buttons turn only the controllers for that configuration on.
            Moved All on and All off into the new controllers menu.
            Created a Configure Blacklist button in the controllers menu.
            Moved the Clear Blacklist button into the controllers menu.
            Modified the Get-Controller function to facilitate the new blacklist flow.
            Fixed a bug where updating the blacklist did not occur until after you restarted the app.
v1.0.7.0    Added more controller slots
v1.0.7.1    Added a check to see if the game path is blank and if it is just skip over launching the game itself.
            Added a version number to the bottom corner of the main window.
#>
param(
[switch]$Elevated
)
$version = "v1.0.7.1"
$Testing = $false
IF ($Testing) {
    $style = "Normal"
    $Pause = $true
    $nogame = $false
} Else {
    $style = "Hidden"
    $Pause = $false
}

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
                Stick11= $null
                Stick12= $null
                Stick13= $null
                Stick14= $null
                Stick15= $null
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
Function Get-USBdview {
    $path = "$MyAppData\usbdeView-x64\usbdeview.exe"
    IF (!(Test-Path -Path $path)) {
        $Download = Show-Message -Message "usbdview is required for Hotas-Launcher to run, Would you like to download usbdview automatically from https://www.nirsoft.net/utils/ ?" -Question
        IF ($download -eq 'Yes') {
            Try {
                $url = "https://www.nirsoft.net/utils/usbdeview-x64.zip"
                Invoke-WebRequest $url -OutFile $MyAppData\usbdeview-x64.zip
                Expand-Archive -Path $MyAppData\usbdeview-x64.zip -DestinationPath $MyAppData\usbdeview-x64 -Force
                Remove-Item -Path $MyAppData\usbdeview-x64.zip
                
            } Catch {
                While (!(Test-Path -Path $path)){
                    $test = Show-Message -Message "Download Failed, Please Download usbdview from https://www.nirsoft.net/utils/ and select USBDeview.exe in the next window" -Question
                    IF ($test -eq 'Yes') {
                        $path = Get-FilePath
                    } Else {
                        Break
                    }
                }
            }
        } Else {
            While (!(Test-Path -Path $path)){
                $test = Show-Message -Message "Download Failed, Please Download usbdview from https://www.nirsoft.net/utils/ and select USBDeview.exe in the next window" -Question
                IF ($test -eq 'Yes') {
                    $path = Get-FilePath
                } Else {
                    Break
                }
            }
        }
    }
    $path
}
Function Set-Settings {
    $path = Get-USBdview
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
            
            $Script:Joysticks = @(Get-Joysticks -xml $xmlSplashpnpDevice -Settings $Settings)
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

Function Get-Controller {
    param(
        $Joysticks,
        $Settings,
        $MyAppData,
        $xml,
        [Switch]$Setup
    )
    #Create the Window
    $WindowController = Import-Xaml -xvar $xml
    #Place Buttons and connect to them on the form
    
    $btnOk = $WindowController.FindName('btnOk')
    $btnOk.Add_Click({
        $WindowController.Tag = $lstController.SelectedItem
        $WindowController.Close()
    })
    $btnSave = $WindowController.FindName('btnSave')
    $btnSave.Add_Click({
        $WindowController.Tag = 'yes'
        $Settings | ConvertTo-Json | Out-File -FilePath "$MyAppData\Settings.json"
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
                IF ($Script:Settings.blacklist -notcontains $i) {
                    $Script:Settings.blacklist += $i 
                }
            } Catch {
                $Script:Settings | Add-Member -NotePropertyName "blacklist" -NotePropertyValue @($i)
            }
            #$Script:Joysticks = $Joysticks | Where-Object { $_.Name -notMatch ($i) }
        }
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
    
    #If setup is tru change how the form looks
    IF ($Setup){
        $btnOk.Visibility = "Collapsed"
        #$btnCancel.Visibility = "Collapsed"
    } Else {
        $btnSave.Visibility = "Collapsed"
        $btnBlacklist.Visibility = "Collapsed"
    }

    # Show the Window and return the result
    $null = $WindowController.ShowDialog()
    $WindowController.Tag
}

Function Test-MyCreds {
    Param (
        [System.Management.Automation.PSCredential]$Creds = [pscredential]::Empty
    )
    IF ($null -ne $Creds.UserName) {
        Try {
            $null = Start-Job {$PWD} -Credential $Creds | Receive-Job -AutoRemoveJob -Wait -ErrorAction Stop
            $result = $true
        } Catch {
            $result = $false
        }
    } Else {
        $result = $false
    }
   $result
}

Function Set-MyCreds {
    $Creds = (Get-StoredCredential -Target "HOTAS Launcher")
    While (!(Test-MyCreds -Creds $Creds) -and $again -ne 'No') {
        Try {
            Remove-StoredCredential -Target "HOTAS Launcher" -ErrorAction Ignore
            $Credos = Get-Credential -UserName $Env:UserName -Message "Enter your local windows username and Password to run the game. Note, if your username has spaces in it you can use your Microsoft Account email and password if it is linked to your PC"
            IF (Test-MyCreds -Creds $Credos) {
                Write-Host "Before manager Set"
                $null = $Credos | New-StoredCredential -Target "HOTAS Launcher" -Type Generic -Persist Enterprise 
                Start-Sleep -Seconds 2
                $Creds = (Get-StoredCredential -Target "HOTAS Launcher")
            }
            
            IF (!(Test-MyCreds -Creds $Creds)){
                $again = Show-Message -Message "Can't verify your credentials, Try entering them again?" -Question
                IF ($again -eq 'No') {
                    $Creds = [pscredential]::Empty
                }
            }
        } Catch {
            $again = Show-Message -Message "Can't verify your credentials, They can't be blank, Try entering them again"
        }
    }
    $Creds
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
        
        # Turn On Controllers
        IF (!($NoApps)){
            ForEach ($Selection in $Selections) {
                While ($Try -ne 'No'){
                    $Stick = $Joysticks | Where-Object {$_.Name -eq $Selection}
                    $SelectedStick = $Stick.ID
                    $Try = 'No'
                    IF ($SelectedStick.Length -lt 1) {
                        $Try = Show-Message -Message "Unable to enable $Selection, Please plug-in or Turn on the Device: Try again?." -Question
                        IF ($Try -eq 'Yes') {
                            $Joysticks = @(Get-Joysticks -xml $xmlSplashpnpDevice -Settings $Settings)
                            $Script:Joysticks = $Joysticks
                        } Else {
                            $btnStart.Visibility = 'Visible'
                            $btnStop.Visibility = 'Collapsed'
                            $ComboGame.Visibility = 'Visible'
                            $StackControls.Visibility = 'Visible'
                            $Splash.Close()
                            Return
                        }
                    }
                    $Connected = Get-PnpDevice -PresentOnly | Where-Object { $_.InstanceId -eq $SelectedStick }
                    IF ($null -eq $Connected) {
                        $Try = Show-Message -Message "Hey dummy you turned off $Selection Turn it back on!,: Try again?." -Question
                        IF ($Try -eq 'No') {
                            $btnStart.Visibility = 'Visible'
                            $btnStop.Visibility = 'Collapsed'
                            $ComboGame.Visibility = 'Visible'
                            $StackControls.Visibility = 'Visible'
                            $Splash.Close()
                            Return
                        }
                    }
                }     
            }
            ForEach ($Selection in $Selections) {
                $Stick = $Joysticks | Where-Object {$_.Name -eq $Selection}
                $SelectedStick = $Stick.ID
                Start-Process -FilePath $Path -ArgumentList "/RunAsAdmin /enable $SelectedStick" -Wait
                Timeout /T 5 
            }
        }
        # Start the Game
        IF ($nogame) {
            Write-Host "Skipping Game launch due to Testing"
            $Splash.Close()
            Return
        }
        #Start the Supporting Apps
        IF ($Game) {
            IF ($Game -ne 'DEMO') {
                IF (!($NoApps)) {
                    IF ($Options.$Game.AppPath1){
                        Write-Host "Starting Aux app 1"
                        Try {
                            $App1Path = $Options.$Game.AppPath1
                            $App1Parent = Split-Path "$App1Path" -Parent
                            IF ($Options.$Game.App1AsAdmin -eq $true) {
                                $Script:App1 = Start-Process -WorkingDirectory $App1Parent -FilePath $App1Path -PassThru
                                
                            } Else {
                                $Script:App1 = Start-Process -WorkingDirectory $App1Parent -FilePath $App1Path -Credential $Creds -PassThru
                            }
                        } Catch{
                            Show-Message -Message "App1 failed to launch, maybe try setting it to run as admin in the config?"
                        }
                    }
                    IF ($Options.$Game.AppPath2){
                        Write-Host "Starting Aux app 2"
                        Try {
                            $App2Path = $Options.$Game.AppPath2
                            $App2Parent = Split-Path $App2Path -Parent
                            IF ($Options.$Game.App2AsAdmin -eq $true) {
                                $Script:App2 = Start-Process -WorkingDirectory $App2Parent -FilePath $App2Path -PassThru
                            } Else {
                                $Script:App2 = Start-Process -WorkingDirectory $App2Parent -FilePath $App2Path -Credential $Creds -PassThru
                            }
                        } Catch{
                            Show-Message -Message "App2 failed to launch, maybe try setting it to run as admin in the config?"
                        }
                    }
                    IF ($Options.$Game.AppPath3){
                        Write-Host "Starting Aux app 3"
                        Try {
                            $App3Path = $Options.$Game.AppPath3
                            $App3Parent = Split-Path $Options.$Game.AppPath3 -Parent
                            IF ($Options.$Game.App3AsAdmin -eq $true) {
                                $Script:App3 = Start-Process -WorkingDirectory $App3Parent -FilePath $App3Path -PassThru
                            } Else {
                                $Script:App3 = Start-Process -WorkingDirectory $App3Parent -FilePath $App3Path -Credential $Creds -PassThru
                            }
                        } Catch{
                            Show-Message -Message "App3 failed to launch, maybe try setting it to run as admin in the config?"
                        }
                    }
                    IF ($Options.$Game.AppPath4){
                        Write-Host "Starting Aux app 4"
                        Try {
                            $App4Path = $Options.$Game.AppPath4
                            $App4Parent = Split-Path $App4Path -Parent
                            IF ($Options.$Game.App4AsAdmin -eq $true) {
                                $Script:App4 = Start-Process -WorkingDirectory $App4Parent -FilePath $App4Path  -PassThru
                            } Else {
                                $Script:App4 = Start-Process -WorkingDirectory $App4Parent -FilePath $App4Path -Credential $Creds -PassThru
                            }
                        } Catch {
                            Show-Message -Message "App4 failed to launch, maybe try setting it to run as admin in the config?"
                        }
                    }
                }
                IF ($Options.$Game.AppPath5){
                    Write-Host "Starting Aux app 5"
                    Try {
                        $App5Path = $Options.$Game.AppPath5
                        $App5Parent = Split-Path "$App5Path" -Parent
                        IF ($Options.$Game.App5AsAdmin -eq $true) {
                            $Script:App5 = Start-Process -WorkingDirectory $App5Parent -FilePath $App5Path -PassThru
                            
                        } Else {
                            $Script:App5 = Start-Process -WorkingDirectory $App5Parent -FilePath $App5Path -Credential $Creds -PassThru
                        }
                    } Catch{
                        Show-Message -Message "App5 failed to launch, maybe try setting it to run as admin in the config?"
                    }
                }
                IF ($Options.$Game.AppPath6){
                    Write-Host "Starting Aux app 6"
                    Try {
                        $App6Path = $Options.$Game.AppPath6
                        $App6Parent = Split-Path "$App6Path" -Parent
                        IF ($Options.$Game.App6AsAdmin -eq $true) {
                            $Script:App6 = Start-Process -WorkingDirectory $App6Parent -FilePath $App6Path -PassThru
                            
                        } Else {
                            $Script:App6 = Start-Process -WorkingDirectory $App6Parent -FilePath $App6Path -Credential $Creds -PassThru
                        }
                    } Catch{
                        Show-Message -Message "App6 failed to launch, maybe try setting it to run as admin in the config?"
                    }
                }
                IF ($Options.$Game.AppPath7){
                    Write-Host "Starting Aux app 7"
                    Try {
                        $App7Path = $Options.$Game.AppPath7
                        $App7Parent = Split-Path "$App7Path" -Parent
                        IF ($Options.$Game.App7AsAdmin -eq $true) {
                            $Script:App7 = Start-Process -WorkingDirectory $App7Parent -FilePath $App7Path -PassThru
                            
                        } Else {
                            $Script:App7 = Start-Process -WorkingDirectory $App7Parent -FilePath $App7Path -Credential $Creds -PassThru
                        }
                    } Catch{
                        Show-Message -Message "App7 failed to launch, maybe try setting it to run as admin in the config?"
                    }
                }
                IF ($Options.$Game.AppPath8){
                    Write-Host "Starting Aux app 8"
                    Try {
                        $App8Path = $Options.$Game.AppPath8
                        $App8Parent = Split-Path "$App8Path" -Parent
                        IF ($Options.$Game.App8AsAdmin -eq $true) {
                            $Script:App8 = Start-Process -WorkingDirectory $App8Parent -FilePath $App8Path -PassThru
                            
                        } Else {
                            $Script:App8 = Start-Process -WorkingDirectory $App8Parent -FilePath $App8Path -Credential $Creds -PassThru
                        }
                    } Catch{
                        Show-Message -Message "App8 failed to launch, maybe try setting it to run as admin in the config?"
                    }
                }
                IF ($Options.$Game.AppPath9){
                    Write-Host "Starting Aux app 9"
                    Try {
                        $App9Path = $Options.$Game.AppPath9
                        $App9Parent = Split-Path "$App9Path" -Parent
                        IF ($Options.$Game.App9AsAdmin -eq $true) {
                            $Script:App9 = Start-Process -WorkingDirectory $App9Parent -FilePath $App9Path -PassThru
                            
                        } Else {
                            $Script:App9 = Start-Process -WorkingDirectory $App9Parent -FilePath $App9Path -Credential $Creds -PassThru
                        }
                    } Catch{
                        Show-Message -Message "App9 failed to launch, maybe try setting it to run as admin in the config?"
                    }
                }
                IF ($Options.$Game.AppPath10){
                    Write-Host "Starting Aux app 10"
                    Try {
                        $App10Path = $Options.$Game.AppPath10
                        $App10Parent = Split-Path "$App10Path" -Parent
                        IF ($Options.$Game.App10AsAdmin -eq $true) {
                            $Script:App10 = Start-Process -WorkingDirectory $App10Parent -FilePath $App10Path -PassThru
                            
                        } Else {
                            $Script:App10 = Start-Process -WorkingDirectory $App10Parent -FilePath $App10Path -Credential $Creds -PassThru
                        }
                    } Catch{
                        Show-Message -Message "App10 failed to launch, maybe try setting it to run as admin in the config?"
                    }
                }
                Write-Host "Starting $Game"
                $GamePath = $Options.$Game.GamePath
                IF ($GamePath.Length -gt 4) { # Only try to launch the game if it has a path...
                    $GameParent = Split-Path $GamePath -Parent
                    IF ($Options.$Game.arg1) {
                        If ($Options.$Game.GameAsAdmin.IsChecked -eq $true){
                            Start-Process -WorkingDirectory $GameParent -FilePath $GamePath -ArgumentList $Options.$Game.Arg1
                        } Else {
                            Start-Process -WorkingDirectory $GameParent -FilePath $GamePath -ArgumentList $Options.$Game.Arg1 -Credential $Creds
                        }
                    } Else {
                        If ($Options.$Game.GameAsAdmin.IsChecked -eq $true){
                            Start-Process -WorkingDirectory $GameParent -FilePath $GamePath
                        } Else {
                            Start-Process -WorkingDirectory $GameParent -FilePath $GamePath -Credential $Creds
                        }
                    }
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
        IF (!($App1.HasExited)) {$null = Stop-Process -InputObject $App1}
        $Script:App1 = $false
    }
    IF ($App2) {
        IF (!($App2.HasExited)) {$null = Stop-Process -InputObject $App2}
        $Script:App2 = $false
    }
    IF ($App3) {
        IF (!($App3.HasExited)) {$null = Stop-Process -InputObject $App3}
        $Script:App3 = $false
    }
    IF ($App4) {
        IF (!($App4.HasExited)) {$null = Stop-Process -InputObject $App4}
        $Script:App4 = $false
    }
    IF ($App5) {
        IF (!($App5.HasExited)) {$null = Stop-Process -InputObject $App5}
        $Script:App5 = $false
    }
    IF ($App6) {
        IF (!($App6.HasExited)) {$null = Stop-Process -InputObject $App6}
        $Script:App6 = $false
    }
    IF ($App7) {
        IF (!($App7.HasExited)) {$null = Stop-Process -InputObject $App7}
        $Script:App7 = $false
    }
    IF ($App8) {
        IF (!($App8.HasExited)) {$null = Stop-Process -InputObject $App8}
        $Script:App8 = $false
    }
    IF ($App9) {
        IF (!($App9.HasExited)) {$null = Stop-Process -InputObject $App9}
        $Script:App9 = $false
    }
    IF ($App10) {
        IF (!($App10.HasExited)) {$null = Stop-Process -InputObject $App10}
        $Script:App10 = $false
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

Function Switch-Controllers {
    Param(
        $Joysticks,
        $Options,
        [Switch]$On,
        [Switch]$Off,
        $xml,
        [Switch]$All,
        $Game
    )
    IF ($All){
        $Controllers = @()
        Foreach($G in $Options.PsObject.Properties) {
            $Game = $G.Name
            foreach($item in $Options.$Game.Selections.PsObject.Properties) {
                $i = $Item.value
                IF ($Null -ne $i -and $i -ne $False){ 
                    $Controllers += $i
                }
            }
        }
    } Else {
        $Controllers = @()
        foreach($item in $Options.$Game.Selections.PsObject.Properties) {
            $i = $Item.value
            IF ($Null -ne $i -and $i -ne $False){ 
                $Controllers += $i
            }
        }
    }
    $Controllers = $Controllers | Sort-Object -Unique

    IF ($On) {
        #$Splash = Import-Xaml -xvar $xml
        #$Splash.Add_ContentRendered({
            ForEach ($Selection in $Controllers) {
                $Stick = $Joysticks | Where-Object {$_.Name -eq $Selection}
                $SelectedStick = $Stick.ID
                Start-Process -FilePath $Path -ArgumentList "/RunAsAdmin /enable $SelectedStick"
                Timeout /T 5
            }
            #$Splash.Close()
        #})
        #$Splash.ShowDialog() | Out-Null
    }
    IF ($Off) {
        ForEach ($Selection in $Controllers) {
            $Stick = $Joysticks | Where-Object {$_.Name -eq $Selection}
            $SelectedStick = $Stick.ID
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
                    <MenuItem Header="_Exit" x:Name="btnExit" />
                </MenuItem>
                <MenuItem Header="_Configurations">
                    <MenuItem Header="_Change Config" x:Name="btnEditGame" />
                    <MenuItem Header="_New Config" x:Name="btnNewGame" />
                    <Separator />
                    <MenuItem Header="_Delete Config" x:Name="btnDelete" />
                </MenuItem>
                <MenuItem Header="_Controllers">
                    <MenuItem Header="_All On" x:Name="btnAllOn" />
                    <Separator />
                    <MenuItem Header="_All Off" x:Name="btnAllOff" />
                    <Separator />
                    <Separator />
                    <MenuItem Header="_Configure Blacklist" x:Name="btnConfigureBlacklist" />
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
                <Button Content="Controllers On" x:Name="btnControllersOn" ToolTip="Turn on selected controllers from this configuration" Height="25" Width="150" Margin="5"/>
                <Button Content="Controllers Off" x:Name="btnControllersOff" ToolTip="Turn off selected controllers from this configuration" Height="25" Width="150" Margin="5"/>
            </StackPanel>
        </StackPanel>
        <StackPanel Background="#eae4ee" x:Name="stackEdit" Margin="10" Orientation="Vertical">
            <StackPanel Margin="5" Orientation="Horizontal" HorizontalAlignment="Left">
                <Label Width="70" Height="25" Padding="3" Margin="5">Name</Label>
                <TextBox x:Name="txtGameName" Width = "300" Height="25" Padding="3" Margin="5"/>
            </StackPanel>
            <StackPanel x:Name="StackSections" Orientation="Horizontal">
                <StackPanel x:Name="StackPaths" Orientation="Vertical">
                    <StackPanel Background="#66ffcc">
                        <Label FontSize="25" Height="50" Padding="3" Margin="0">Paths</Label>
                    </StackPanel>
                    <StackPanel Margin="5 0 0 5" Orientation="Horizontal" HorizontalAlignment="Left">
                        <Label Width="70" Height="25" Padding="3" Margin="5">Game Path</Label>
                        <TextBox x:Name="txtGamePath" Width = "300" Height="25" Padding="3" Margin="5"/>
                        <Button x:Name="btnBrowseGame" Content="Browse" ToolTip="Select Game executable/launcher" Height="25" Width="100" Margin="5"/>
                        <CheckBox x:Name="chkGameAsAdmin" Content="Run as admin" ToolTip="Check to run the game as administrator" Margin="5"/>
                    </StackPanel>
                    <StackPanel Margin="5 0 0 5" Orientation="Horizontal" HorizontalAlignment="Left">    
                        <Label Width="70" Height="25" Padding="3" Margin="5">Switches</Label>
                        <TextBox x:Name="txtGameArgs" Width = "150" Height="25" Padding="3" Margin="5"/>
                    </StackPanel>
                    <StackPanel Margin="5" Orientation="Horizontal" HorizontalAlignment="Left">
                        <Label Width="70" Height="25" Padding="3" Margin="5">App1 Path</Label>
                        <TextBox x:Name="txtAppPath1" Width = "300" Height="25" Padding="3" Margin="5"/>
                        <Button x:Name="btnBrowseApp1" Content="Browse" ToolTip="Browse to select Optional support app 1" Height="25" Width="100" Margin="5"/>
                        <CheckBox x:Name="chkApp1AsAdmin" Content="Run as admin" ToolTip="Check to run App 1 as administrator" Margin="5"/>
                    </StackPanel>
                    <StackPanel Margin="5" Orientation="Horizontal" HorizontalAlignment="Left">
                        <Label Width="70" Height="25" Padding="3" Margin="5">App2 Path</Label>
                        <TextBox x:Name="txtAppPath2" Width = "300" Height="25" Padding="3" Margin="5"/>
                        <Button x:Name="btnBrowseApp2" Content="Browse" ToolTip="Browse to select Optional support app 2" Height="25" Width="100" Margin="5"/>
                        <CheckBox x:Name="chkApp2AsAdmin" Content="Run as admin" ToolTip="Check to run App 2 as administrator" Margin="5"/>
                    </StackPanel>
                    <StackPanel Margin="5" Orientation="Horizontal" HorizontalAlignment="Left">
                        <Label Width="70" Height="25" Padding="3" Margin="5">App3 Path</Label>
                        <TextBox x:Name="txtAppPath3" Width = "300" Height="25" Padding="3" Margin="5"/>
                        <Button x:Name="btnBrowseApp3" Content="Browse" ToolTip="Browse to select Optional support app 3" Height="25" Width="100" Margin="5"/>
                        <CheckBox x:Name="chkApp3AsAdmin" Content="Run as admin" ToolTip="Check to run App 3 as administrator" Margin="5"/>
                    </StackPanel>
                    <StackPanel Margin="5" Orientation="Horizontal" HorizontalAlignment="Left">
                        <Label Width="70" Height="25" Padding="3" Margin="5">App4 Path</Label>
                        <TextBox x:Name="txtAppPath4" Width = "300" Height="25" Padding="3" Margin="5"/>
                        <Button x:Name="btnBrowseApp4" Content="Browse" ToolTip="Browse to select Optional support app 4" Height="25" Width="100" Margin="5"/>
                        <CheckBox x:Name="chkApp4AsAdmin" Content="Run as admin" ToolTip="Check to run App 4 as administrator" Margin="5"/>
                    </StackPanel>
                    <StackPanel Margin="5" Orientation="Horizontal" HorizontalAlignment="Left">
                        <Label Width="70" Height="25" Padding="3" Margin="5">App5 Path</Label>
                        <TextBox x:Name="txtAppPath5" Width = "300" Height="25" Padding="3" Margin="5"/>
                        <Button x:Name="btnBrowseApp5" Content="Browse" ToolTip="Browse to select Optional support app 5" Height="25" Width="100" Margin="5"/>
                        <CheckBox x:Name="chkApp5AsAdmin" Content="Run as admin" ToolTip="Check to run App 5 as administrator" Margin="5"/>
                    </StackPanel>
                    <StackPanel Margin="5" Orientation="Horizontal" HorizontalAlignment="Left">
                        <Label Width="70" Height="25" Padding="3" Margin="5">App6 Path</Label>
                        <TextBox x:Name="txtAppPath6" Width = "300" Height="25" Padding="3" Margin="5"/>
                        <Button x:Name="btnBrowseApp6" Content="Browse" ToolTip="Browse to select Optional support app 6" Height="25" Width="100" Margin="5"/>
                        <CheckBox x:Name="chkApp6AsAdmin" Content="Run as admin" ToolTip="Check to run App 6 as administrator" Margin="5"/>
                    </StackPanel>
                    <StackPanel Margin="5" Orientation="Horizontal" HorizontalAlignment="Left">
                        <Label Width="70" Height="25" Padding="3" Margin="5">App7 Path</Label>
                        <TextBox x:Name="txtAppPath7" Width = "300" Height="25" Padding="3" Margin="5"/>
                        <Button x:Name="btnBrowseApp7" Content="Browse" ToolTip="Browse to select Optional support app 7" Height="25" Width="100" Margin="5"/>
                        <CheckBox x:Name="chkApp7AsAdmin" Content="Run as admin" ToolTip="Check to run App 7 as administrator" Margin="5"/>
                    </StackPanel>
                    <StackPanel Margin="5" Orientation="Horizontal" HorizontalAlignment="Left">
                        <Label Width="70" Height="25" Padding="3" Margin="5">App8 Path</Label>
                        <TextBox x:Name="txtAppPath8" Width = "300" Height="25" Padding="3" Margin="5"/>
                        <Button x:Name="btnBrowseApp8" Content="Browse" ToolTip="Browse to select Optional support app 8" Height="25" Width="100" Margin="5"/>
                        <CheckBox x:Name="chkApp8AsAdmin" Content="Run as admin" ToolTip="Check to run App 8 as administrator" Margin="5"/>
                    </StackPanel>
                    <StackPanel Margin="5" Orientation="Horizontal" HorizontalAlignment="Left">
                        <Label Width="70" Height="25" Padding="3" Margin="5">App9 Path</Label>
                        <TextBox x:Name="txtAppPath9" Width = "300" Height="25" Padding="3" Margin="5"/>
                        <Button x:Name="btnBrowseApp9" Content="Browse" ToolTip="Browse to select Optional support app 9" Height="25" Width="100" Margin="5"/>
                        <CheckBox x:Name="chkApp9AsAdmin" Content="Run as admin" ToolTip="Check to run App 9 as administrator" Margin="5"/>
                    </StackPanel>
                    <StackPanel Margin="5" Orientation="Horizontal" HorizontalAlignment="Left">
                        <Label Width="70" Height="25" Padding="3" Margin="5">App10 Path</Label>
                        <TextBox x:Name="txtAppPath10" Width = "300" Height="25" Padding="3" Margin="5"/>
                        <Button x:Name="btnBrowseApp10" Content="Browse" ToolTip="Browse to select Optional support app 10" Height="25" Width="100" Margin="5"/>
                        <CheckBox x:Name="chkApp10AsAdmin" Content="Run as admin" ToolTip="Check to run App 10 as administrator" Margin="5"/>
                    </StackPanel>
                </StackPanel>
                <StackPanel x:Name="Separater" Width="10" Background="#66ffcc">
                </StackPanel>
                <StackPanel x:Name="StackControllers" Orientation="Vertical">
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
                    <StackPanel Margin="5" Orientation="Horizontal" HorizontalAlignment="Left">
                        <Label Width="75" Height="25" Padding="3" Margin="5">Controller 1</Label>
                        <Label x:Name="lblJoy11" Width="300" Height="25" Padding="3" Margin="5" Background="white" />
                        <Button x:Name="btnJoy11" Content="Select" ToolTip="Browse to select Controller 11" Height="25" Width="100" Margin="5"/>
                    </StackPanel>
                    <StackPanel Margin="5" Orientation="Horizontal" HorizontalAlignment="Left">
                        <Label Width="75" Height="25" Padding="3" Margin="5">Controller 12</Label>
                        <Label x:Name="lblJoy12" Width="300" Height="25" Padding="3" Margin="5" Background="white" />
                        <Button x:Name="btnJoy12" Content="Select" ToolTip="Browse to select Controller 12" Height="25" Width="100" Margin="5"/>
                    </StackPanel>
                    <StackPanel Margin="5" Orientation="Horizontal" HorizontalAlignment="Left">
                        <Label Width="75" Height="25" Padding="3" Margin="5">Controller 13</Label>
                        <Label x:Name="lblJoy13" Width="300" Height="25" Padding="3" Margin="5" Background="white" />
                        <Button x:Name="btnJoy13" Content="Select" ToolTip="Browse to select Controller 13" Height="25" Width="100" Margin="5"/>
                    </StackPanel>
                    <StackPanel Margin="5" Orientation="Horizontal" HorizontalAlignment="Left">
                        <Label Width="75" Height="25" Padding="3" Margin="5">Controller 14</Label>
                        <Label x:Name="lblJoy14" Width="300" Height="25" Padding="3" Margin="5" Background="white" />
                        <Button x:Name="btnJoy14" Content="Select" ToolTip="Browse to select Controller 14" Height="25" Width="100" Margin="5"/>
                    </StackPanel>
                    <StackPanel Margin="5" Orientation="Horizontal" HorizontalAlignment="Left">
                        <Label Width="75" Height="25" Padding="3" Margin="5">Controller 15</Label>
                        <Label x:Name="lblJoy15" Width="300" Height="25" Padding="3" Margin="5" Background="white" />
                        <Button x:Name="btnJoy15" Content="Select" ToolTip="Browse to select Controller 15" Height="25" Width="100" Margin="5"/>
                    </StackPanel>
                </StackPanel>
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
            <Label x:Name="lblVersion" Width="200" Height="25" Padding="3" />
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
        <Button Content="Save" x:Name="btnSave" IsDefault="True" ToolTip="Save and Close the window" Height="30" Width="150" Margin="5"/>
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

#Get Credentials or set them if needed
IF ($CredentialsManaged) {
    $Creds = Set-MyCreds
    IF (!(Test-MyCreds -Creds $Creds)) {Exit} 
} Else {
    While (!(Test-MyCreds -Creds $Creds)){
        Try {
            $Creds = (Get-Credential -Message "Please enter your local windows username and password for launching the game as your standard user. If there are spaces in your username you can use your Microsoft account email and password.")
        } Catch{
            $Creds = [pscredential]::Empty
            $again = Show-Message -Message "Cannot validate credentials, try again?" -Question
            IF ($again -eq 'no') {Exit}
        }
    } 
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
# Now to prevent any shinanegans we check if usbdview is found and if not we kill the app.
IF (!(Test-Path -Path $path)){
    $path = Get-USBdview
    IF (!(Test-Path -Path $path)){
        Show-Message -Message "Unable to find usbdview.exe Hotas Launcher quitting."
        Exit
    }
    $Settings.usbdview = $path
    $Settings | ConvertTo-Json | Out-File -FilePath "$MyAppData\Settings.json"
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
#Make a Label and bind to $Version
$lblVersion = $Window.FindName('lblVersion')
$lblVersion.Content = $Version
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
# Assign Checkboxes for Run as Admin
$chkGameAsAdmin = $Window.FindName('chkGameAsAdmin')
$chkApp1AsAdmin = $Window.FindName('chkApp1AsAdmin')
$chkApp2AsAdmin = $Window.FindName('chkApp2AsAdmin')
$chkApp3AsAdmin = $Window.FindName('chkApp3AsAdmin')
$chkApp4AsAdmin = $Window.FindName('chkApp4AsAdmin')
$chkApp5AsAdmin = $Window.FindName('chkApp5AsAdmin')
$chkApp6AsAdmin = $Window.FindName('chkApp6AsAdmin')
$chkApp7AsAdmin = $Window.FindName('chkApp7AsAdmin')
$chkApp8AsAdmin = $Window.FindName('chkApp8AsAdmin')
$chkApp9AsAdmin = $Window.FindName('chkApp9AsAdmin')
$chkApp10AsAdmin = $Window.FindName('chkApp10AsAdmin')

#Populate labels and text boxes with bindings
$txtGameName = $Window.FindName('txtGameName')
$txtGamePath = $Window.FindName('txtGamePath')
$txtAppPath1 = $Window.FindName('txtAppPath1')
$txtAppPath2 = $Window.FindName('txtAppPath2')
$txtAppPath3 = $Window.FindName('txtAppPath3')
$txtAppPath4 = $Window.FindName('txtAppPath4')
$txtAppPath5 = $Window.FindName('txtAppPath5')
$txtAppPath6 = $Window.FindName('txtAppPath6')
$txtAppPath7 = $Window.FindName('txtAppPath7')
$txtAppPath8 = $Window.FindName('txtAppPath8')
$txtAppPath9 = $Window.FindName('txtAppPath9')
$txtAppPath10 = $Window.FindName('txtAppPath10')
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
$lblJoy11 = $Window.FindName('lblJoy11')
$lblJoy12 = $Window.FindName('lblJoy12')
$lblJoy13 = $Window.FindName('lblJoy13')
$lblJoy14 = $Window.FindName('lblJoy14')
$lblJoy15 = $Window.FindName('lblJoy15')
$txtGameArgs = $Window.FindName('txtGameArgs')

#Assign bindings for some buttons and click actions for them
$btnExit = $Window.FindName('btnExit')
$btnExit.Add_Click({
    $Window.Close()
})
$btnAbout = $Window.FindName('btnAbout')
$btnAbout.Add_Click({
    $About = Import-Xaml -xvar $xmlAbout
    $About.ShowDialog()
})
$btnClearBlacklist = $Window.FindName('btnClearBlacklist')
$btnClearBlacklist.Add_Click({
    IF ((Show-Message -Message "Are you sure you want to clear the blacklist and re-detect controllers?" -Question) -eq 'yes') {
        $Settings = Set-Blacklist -Settings $Settings
    }
})
$btnStart = $Window.FindName('btnStart')
$btnStart.Add_Click({
    #Try {
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
    #} Catch {
     #   Show-Message -Message "Game Settings invalid Please Fix your thing!"
    #}
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
    Switch-Controllers -Joysticks $Joysticks -Options $Options -On -xml $xmlSplash -all
})

$btnAllOff = $Window.FindName('btnAllOff')
$btnAllOff.Add_Click({
    Switch-Controllers -Joysticks $Joysticks -Options $Options -Off -all
})
$btnControllersOn = $Window.FindName('btnControllersOn')
$btnControllersOn.Add_Click({
    $Game = $ComboGame.SelectedItem
    Switch-Controllers -Joysticks $Joysticks -Options $Options -On -xml $xmlSplash -Game $Game
})

$btnControllersOff = $Window.FindName('btnControllersOff')
$btnControllersOff.Add_Click({
    $Game = $ComboGame.SelectedItem
    Switch-Controllers -Joysticks $Joysticks -Options $Options -Off -Game $Game
})

$btnConfigureBlacklist = $Window.FindName('btnConfigureBlacklist')
$btnConfigureBlacklist.Add_Click({
    $BLUpdated = Get-Controller -Joysticks $Joysticks -Settings $Settings -MyAppData $MyAppData -xml $xmlController -setup
    IF ($BLUpdated -eq 'yes') {
        $Script:Settings = Get-Content -Path "$SettingsPath" -Raw | ConvertFrom-Json
        $Script:Joysticks = @(Get-Joysticks -xml $xmlSplashpnpDevice -Settings $Settings)
    }
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
$btnBrowseApp5 = $Window.FindName('btnBrowseApp5')
$btnBrowseApp5.Add_Click({
    $txtAppPath5.Text = Get-FilePath
})
$btnBrowseApp6 = $Window.FindName('btnBrowseApp6')
$btnBrowseApp6.Add_Click({
    $txtAppPath6.Text = Get-FilePath
})
$btnBrowseApp7 = $Window.FindName('btnBrowseApp7')
$btnBrowseApp7.Add_Click({
    $txtAppPath7.Text = Get-FilePath
})
$btnBrowseApp8 = $Window.FindName('btnBrowseApp8')
$btnBrowseApp8.Add_Click({
    $txtAppPath8.Text = Get-FilePath
})
$btnBrowseApp9 = $Window.FindName('btnBrowseApp9')
$btnBrowseApp9.Add_Click({
    $txtAppPath9.Text = Get-FilePath
})
$btnBrowseApp10 = $Window.FindName('btnBrowseApp10')
$btnBrowseApp10.Add_Click({
    $txtAppPath10.Text = Get-FilePath
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

$btnJoy11 = $Window.FindName('btnJoy11')
$btnJoy11.Add_Click({
        $result = Get-Controller -Joysticks $Joysticks -Settings $Settings -MyAppData $MyAppData -xml $xmlController
        $lblJoy11.Content = $result
})

$btnJoy12 = $Window.FindName('btnJoy12')
$btnJoy12.Add_Click({
        $result = Get-Controller -Joysticks $Joysticks -Settings $Settings -MyAppData $MyAppData -xml $xmlController
        $lblJoy12.Content = $result
})

$btnJoy13 = $Window.FindName('btnJoy13')
$btnJoy13.Add_Click({
        $result = Get-Controller -Joysticks $Joysticks -Settings $Settings -MyAppData $MyAppData -xml $xmlController
        $lblJoy13.Content = $result
})

$btnJoy14 = $Window.FindName('btnJoy14')
$btnJoy14.Add_Click({
        $result = Get-Controller -Joysticks $Joysticks -Settings $Settings -MyAppData $MyAppData -xml $xmlController
        $lblJoy14.Content = $result
})

$btnJoy15 = $Window.FindName('btnJoy15')
$btnJoy15.Add_Click({
        $result = Get-Controller -Joysticks $Joysticks -Settings $Settings -MyAppData $MyAppData -xml $xmlController
        $lblJoy15.Content = $result
})

$btnSaveGame = $Window.FindName('btnSaveGame')
$btnSaveGame.Add_Click({
    
    #use the game
    $SelectedGame = ($Window.FindName('ComboGame')).SelectedItem
    IF ($SelectedGame -ne " " -and $null -ne $SelectedGame){ #If we have selected a game and changed the name remove the old one
        if ($SelectedGame -ne $txtGameName.Text) {
            $Options.psobject.properties.remove($SelectedGame)
        }
    }
    
    Try {
        #Create the object with all the properties needed for each game config and assign values from the text boxes
        $GameObject = [PSCustomObject]@{
            Name = $txtGameName.Text
            GamePath = $txtGamePath.Text
            GameAsAdmin = $chkGameAsAdmin.IsChecked
            AppPath1 = $txtAppPath1.Text
            App1AsAdmin = $chkApp1AsAdmin.IsChecked
            AppPath2 = $txtAppPath2.Text
            App2AsAdmin = $chkApp2AsAdmin.IsChecked
            AppPath3 = $txtAppPath3.Text
            App3AsAdmin = $chkApp3AsAdmin.IsChecked
            AppPath4 = $txtAppPath4.Text
            App4AsAdmin = $chkApp4AsAdmin.IsChecked
            AppPath5 = $txtAppPath5.Text
            App5AsAdmin = $chkApp5AsAdmin.IsChecked
            AppPath6 = $txtAppPath6.Text
            App6AsAdmin = $chkApp6AsAdmin.IsChecked
            AppPath7 = $txtAppPath7.Text
            App7AsAdmin = $chkApp7AsAdmin.IsChecked
            AppPath8 = $txtAppPath8.Text
            App8AsAdmin = $chkApp8AsAdmin.IsChecked
            AppPath9 = $txtAppPath9.Text
            App9AsAdmin = $chkApp9AsAdmin.IsChecked
            AppPath10 = $txtAppPath10.Text
            App10AsAdmin = $chkApp10AsAdmin.IsChecked
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
                Stick11=$lblJoy11.Content
                Stick12=$lblJoy12.Content
                Stick13=$lblJoy13.Content
                Stick14=$lblJoy14.Content
                Stick15=$lblJoy15.Content
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
    IF ($null -ne $Options.$Game.GameAsAdmin) {$chkGameAsAdmin.IsChecked = $Options.$Game.GameAsAdmin} Else {$chkGameAsAdmin.IsChecked = $false}
    $txtAppPath1.Text = $Options.$Game.AppPath1
    IF ($null -ne $Options.$Game.App1AsAdmin) {$chkApp1AsAdmin.IsChecked = $Options.$Game.App1AsAdmin} Else {$chkApp1AsAdmin.IsChecked = $false}
    $txtAppPath2.Text = $Options.$Game.AppPath2
    IF ($null -ne $Options.$Game.App2AsAdmin) {$chkApp2AsAdmin.IsChecked = $Options.$Game.App2AsAdmin} Else {$chkApp2AsAdmin.IsChecked = $false}
    $txtAppPath3.Text = $Options.$Game.AppPath3
    IF ($null -ne $Options.$Game.App3AsAdmin) {$chkApp3AsAdmin.IsChecked = $Options.$Game.App3AsAdmin} Else {$chkApp3AsAdmin.IsChecked = $false}
    $txtAppPath4.Text = $Options.$Game.AppPath4
    IF ($null -ne $Options.$Game.App4AsAdmin) {$chkApp4AsAdmin.IsChecked = $Options.$Game.App4AsAdmin} Else {$chkApp4AsAdmin.IsChecked = $false}
    $txtAppPath5.Text = $Options.$Game.AppPath5
    IF ($null -ne $Options.$Game.App5AsAdmin) {$chkApp5AsAdmin.IsChecked = $Options.$Game.App5AsAdmin} Else {$chkApp5AsAdmin.IsChecked = $false}
    $txtAppPath6.Text = $Options.$Game.AppPath6
    IF ($null -ne $Options.$Game.App6AsAdmin) {$chkApp6AsAdmin.IsChecked = $Options.$Game.App6AsAdmin} Else {$chkApp6AsAdmin.IsChecked = $false}
    $txtAppPath7.Text = $Options.$Game.AppPath7
    IF ($null -ne $Options.$Game.App7AsAdmin) {$chkApp7AsAdmin.IsChecked = $Options.$Game.App7AsAdmin} Else {$chkApp7AsAdmin.IsChecked = $false}
    $txtAppPath8.Text = $Options.$Game.AppPath8
    IF ($null -ne $Options.$Game.App8AsAdmin) {$chkApp8AsAdmin.IsChecked = $Options.$Game.App8AsAdmin} Else {$chkApp8AsAdmin.IsChecked = $false}
    $txtAppPath9.Text = $Options.$Game.AppPath9
    IF ($null -ne $Options.$Game.App9AsAdmin) {$chkApp9AsAdmin.IsChecked = $Options.$Game.App9AsAdmin} Else {$chkApp9AsAdmin.IsChecked = $false}
    $txtAppPath10.Text = $Options.$Game.AppPath10
    IF ($null -ne $Options.$Game.App10AsAdmin) {$chkApp10AsAdmin.IsChecked = $Options.$Game.App10AsAdmin} Else {$chkApp10AsAdmin.IsChecked = $false}
    
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
    $lblJoy11.Content = $Options.$Game.Selections.Stick11
    $lblJoy12.Content = $Options.$Game.Selections.Stick12
    $lblJoy13.Content = $Options.$Game.Selections.Stick13
    $lblJoy14.Content = $Options.$Game.Selections.Stick14
    $lblJoy15.Content = $Options.$Game.Selections.Stick15
})

$btnEditGame = $Window.FindName('btnEditGame')
$btnEditGame.Add_Click({
    $Script:Settings = Get-Content -Path "$SettingsPath" -Raw | ConvertFrom-Json
    IF ($ComboGame.text -ne " " -and $false -ne $ComboGame.text){
        #hide the combo box to prevent user from causing problems and show the edit fields
        $stackEdit.Visibility = "Visible"
        $stackCombo.Visibility = "Collapsed"
        #Select the game to the selected item from the combobox
        $Game = ($Window.FindName('ComboGame')).SelectedItem
        
        #set all the fields to their current settings
        $txtGameName.Text = $Options.$Game.Name
        $txtGamePath.Text = $Options.$Game.GamePath
        IF ($null -ne $Options.$Game.GameAsAdmin) {$chkGameAsAdmin.IsChecked = $Options.$Game.GameAsAdmin} Else {$chkGameAsAdmin.IsChecked = $false}
        $txtAppPath1.Text = $Options.$Game.AppPath1
        IF ($null -ne $Options.$Game.App1AsAdmin) {$chkApp1AsAdmin.IsChecked = $Options.$Game.App1AsAdmin} Else {$chkApp1AsAdmin.IsChecked = $false}
        $txtAppPath2.Text = $Options.$Game.AppPath2
        IF ($null -ne $Options.$Game.App2AsAdmin) {$chkApp2AsAdmin.IsChecked = $Options.$Game.App2AsAdmin} Else {$chkApp2AsAdmin.IsChecked = $false}
        $txtAppPath3.Text = $Options.$Game.AppPath3
        IF ($null -ne $Options.$Game.App3AsAdmin) {$chkApp3AsAdmin.IsChecked = $Options.$Game.App3AsAdmin} Else {$chkApp3AsAdmin.IsChecked = $false}
        $txtAppPath4.Text = $Options.$Game.AppPath4
        IF ($null -ne $Options.$Game.App4AsAdmin) {$chkApp4AsAdmin.IsChecked = $Options.$Game.App4AsAdmin} Else {$chkApp4AsAdmin.IsChecked = $false}
        $txtAppPath5.Text = $Options.$Game.AppPath5
        IF ($null -ne $Options.$Game.App5AsAdmin) {$chkApp5AsAdmin.IsChecked = $Options.$Game.App5AsAdmin} Else {$chkApp5AsAdmin.IsChecked = $false}
        $txtAppPath6.Text = $Options.$Game.AppPath6
        IF ($null -ne $Options.$Game.App6AsAdmin) {$chkApp6AsAdmin.IsChecked = $Options.$Game.App6AsAdmin} Else {$chkApp6AsAdmin.IsChecked = $false}
        $txtAppPath7.Text = $Options.$Game.AppPath7
        IF ($null -ne $Options.$Game.App7AsAdmin) {$chkApp7AsAdmin.IsChecked = $Options.$Game.App7AsAdmin} Else {$chkApp7AsAdmin.IsChecked = $false}
        $txtAppPath8.Text = $Options.$Game.AppPath8
        IF ($null -ne $Options.$Game.App8AsAdmin) {$chkApp8AsAdmin.IsChecked = $Options.$Game.App8AsAdmin} Else {$chkApp8AsAdmin.IsChecked = $false}
        $txtAppPath9.Text = $Options.$Game.AppPath9
        IF ($null -ne $Options.$Game.App9AsAdmin) {$chkApp9AsAdmin.IsChecked = $Options.$Game.App9AsAdmin} Else {$chkApp9AsAdmin.IsChecked = $false}
        $txtAppPath10.Text = $Options.$Game.AppPath10
        IF ($null -ne $Options.$Game.App10AsAdmin) {$chkApp10AsAdmin.IsChecked = $Options.$Game.App10AsAdmin} Else {$chkApp10AsAdmin.IsChecked = $false}
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
        $lblJoy11.Content = $Options.$Game.Selections.Stick11
        $lblJoy12.Content = $Options.$Game.Selections.Stick12
        $lblJoy13.Content = $Options.$Game.Selections.Stick13
        $lblJoy14.Content = $Options.$Game.Selections.Stick14
        $lblJoy15.Content = $Options.$Game.Selections.Stick15
    } Else {
        Show-Message -Message "It appears you have not selected a Config, if you wish to create a new game, please click `"New Config`"."
    }
})

$btnDelete = $Window.FindName('btnDelete')
$btnDelete.Add_Click({
    #lets use the game that is selected for this...
    $SelectedGame = ($Window.FindName('ComboGame')).SelectedItem
    #Double check the user did not get click happy
    IF ($SelectedGame -ne " " -and $null -ne $SelectedGame){
        $Answer = Show-Message -Message "Are you sure you wish to Delete $SelectedGame ?" -Question
        IF ($Answer -eq 'Yes') {# Well we warned him, lets go...
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
IF ($Pause) {
    Pause
}