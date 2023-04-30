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
Updates:
Version v1.0-alpha -        Released 20/04/2023

Version v1.0.0.1-alpha -     Updated Description
                            Update to handling credentials if user does not want to install CredentialManager module
                            Updated comments
                            Added About Window with License info etc
                            Added auto check for updates feature
Version v1.0.0.2-alpha -     Fixed bug causing version to always be out of date.

Version v1.0.0.3-alpha -    Removed wait from game launch so that the app window is not locked up while the game is running, it was no longer automating the closure of apps etc anyway.
                            Converted all xml to variables within the main script and modified Import-Xaml to accept a variable or a file using params to enable use of a file while testing or coding the xaml (for formatting help)
                            Add functioning all on and all off buttons to main form utilizing all unique sticks from the various game configs.

#>
param(
[switch]$Elevated
)
$version = "v1.0.0.3-alpha"

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

Function Get-Joysticks {
    Param(
        $xml
    )
    
    $SplashPnpDevice = Import-Xaml -xvar $xml
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
        $Joysticks,
        $xml
    )

    $Splash = Import-Xaml -xvar $xml
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
        [Switch]$Off
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
        Write-Host "Turn it all On"
        ForEach ($Selection in $All) {
            $Stick = $Joysticks | Where-Object {$_.Name -eq $Selection}
            $SelectedStick = $Stick.ID
            Start-Process -FilePath $Path -ArgumentList "/RunAsAdmin /enable $SelectedStick"
            Timeout /T 5
        }
    }
    IF ($Off) {
        Write-Host "Turn it all Off"
        ForEach ($Selection in $All) {
            $Stick = $Joysticks | Where-Object {$_.Name -eq $Selection}
            $SelectedStick = $Stick.ID
            Write-Host $Stick.ID
            Start-Process -FilePath $Path -ArgumentList "/RunAsAdmin /disable $SelectedStick"
        }
    }
}

# Check that we are running as admin and restart if we aren't(this only works when run as a .ps1, the exe has to be launched as administrator)
$myScript = $myinvocation.mycommand.definition
$null = Test-Admin -MyScript "$Myscript"

#Set up the xml variables
$xmlMain = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Game Picker"
        Background="#66ffcc"
        SizeToContent="WidthAndHeight"
        MinHeight="300"
        MinWidth="300"
>
<StackPanel>
    <StackPanel HorizontalAlignment="right" Orientation="Horizontal">
        <CheckBox x:Name="chkVersion" Content="Check for updates on startup?"/>
        <Button Content="About" x:Name="btnAbout" Height="30" Width="70" Margin="5"/>
    </StackPanel>
    <StackPanel x:Name="stackCombo" Orientation="Vertical" HorizontalAlignment="Center">
        <StackPanel Margin="10" Orientation="Horizontal" HorizontalAlignment="Center">
            <ComboBox x:Name="ComboGame" Margin="10" Height="25" Width="200" Padding="3"></ComboBox>
            
        </StackPanel>
        <StackPanel Margin="10" Orientation="Horizontal" HorizontalAlignment="Center">
            <Button Content="Start" x:Name="btnStart" Height="30" Width="150" Margin="5"/>
            <Button Content="Stop" x:Name="btnStop" Visibility='Collapsed' Height="30" Width="150" Margin="5"/>
        </StackPanel>
        <StackPanel x:Name="stackControls" Margin="10" Orientation="Vertical" HorizontalAlignment="Center">
            <StackPanel Margin="10" Orientation="Horizontal" HorizontalAlignment="Center">
                <Button Content="Settings" x:Name="btnEditGame" Height="25" Width="90" Margin="5"/>
                <Button Content="New Game" x:Name="btnNewGame" Height="25" Width="90" Margin="5"/>
                <Button x:Name="btnDelete" Content="Delete Game" Height="25" Width="90" Margin="5"/>
            </StackPanel>
            <StackPanel Margin="10" Orientation="Horizontal" HorizontalAlignment="Center">
                <Button Content="All On" x:Name="btnAllOn" Height="25" Width="90" Margin="5"/>
                <Button Content="All Off" x:Name="btnAllOff" Height="25" Width="90" Margin="5"/>
            </StackPanel>
        </StackPanel>
        
    </StackPanel>

    <StackPanel x:Name="stackEdit" Margin="10">

        <StackPanel Margin="5" Orientation="Horizontal" HorizontalAlignment="Center">
            <Label FontSize="25" Width="150" Height="50" Padding="3" Margin="5">Game Name</Label>
            <TextBox x:Name="txtGameName" Width = "300" Height="25" Padding="3" Margin="5"/>
        </StackPanel>

        <StackPanel Margin="5" Orientation="Horizontal" HorizontalAlignment="Center">
            <Label FontSize="25" Width="150" Height="50" Padding="3" Margin="5">Game Path's</Label>
        </StackPanel>

        <StackPanel Margin="5" Orientation="Horizontal" HorizontalAlignment="Center">
            <Label Width="70" Height="25" Padding="3" Margin="5">Game Path</Label>
            <TextBox x:Name="txtGamePath" Width = "300" Height="25" Padding="3" Margin="5"/>
            <Button x:Name="btnBrowseGame" Content="Browse" Height="25" Width="100" Margin="5"/>
            <Label Width="35" Height="25" Padding="3" Margin="5">Args</Label>
            <TextBox x:Name="txtGameArgs" Width = "150" Height="25" Padding="3" Margin="5"/>
        </StackPanel>
        <StackPanel Margin="5" Orientation="Horizontal" HorizontalAlignment="Center">
            <Label Width="70" Height="25" Padding="3" Margin="5">App1 Path</Label>
            <TextBox x:Name="txtAppPath1" Width = "300" Height="25" Padding="3" Margin="5"/>
            <Button x:Name="btnBrowseApp1" Content="Browse" Height="25" Width="100" Margin="5"/>
            
            
        </StackPanel>
        <StackPanel Margin="5" Orientation="Horizontal" HorizontalAlignment="Center">
            <Label Width="70" Height="25" Padding="3" Margin="5">App2 Path</Label>
            <TextBox x:Name="txtAppPath2" Width = "300" Height="25" Padding="3" Margin="5"/>
            <Button x:Name="btnBrowseApp2" Content="Browse" Height="25" Width="100" Margin="5"/>
            
            
        </StackPanel>
        <StackPanel Margin="5" Orientation="Horizontal" HorizontalAlignment="Center">
            <Label Width="70" Height="25" Padding="3" Margin="5">App3 Path</Label>
            <TextBox x:Name="txtAppPath3" Width = "300" Height="25" Padding="3" Margin="5"/>
            <Button x:Name="btnBrowseApp3" Content="Browse" Height="25" Width="100" Margin="5"/>
            
            
        </StackPanel>
        <StackPanel Margin="5" Orientation="Horizontal" HorizontalAlignment="Center">
            <Label Width="70" Height="25" Padding="3" Margin="5">App4 Path</Label>
            <TextBox x:Name="txtAppPath4" Width = "300" Height="25" Padding="3" Margin="5"/>
            <Button x:Name="btnBrowseApp4" Content="Browse" Height="25" Width="100" Margin="5"/>
            
            
        </StackPanel>

        <StackPanel Margin="5" Orientation="Horizontal" HorizontalAlignment="Center">
            <Label FontSize="25" Width="150" Height="50" Padding="3" Margin="5">Joysticks</Label>
        </StackPanel>

        <StackPanel Margin="5" Orientation="Horizontal" HorizontalAlignment="Center">
            <Label Width="70" Height="25" Padding="3" Margin="5">Joystick 1</Label>
            <Label x:Name="lblJoy1" Width="200" Height="25" Padding="3" Margin="5" Background="white"/>
            <Button x:Name="btnJoy1" Content="Select" Height="25" Width="100" Margin="5"/>
        </StackPanel>
        <StackPanel Margin="5" Orientation="Horizontal" HorizontalAlignment="Center">
            <Label Width="70" Height="25" Padding="3" Margin="5">Joystick 2</Label>
            <Label x:Name="lblJoy2" Width="200" Height="25" Padding="3" Margin="5" Background="white"/>
            <Button x:Name="btnJoy2" Content="Select" Height="25" Width="100" Margin="5"/>
        </StackPanel>
        <StackPanel Margin="5" Orientation="Horizontal" HorizontalAlignment="Center">
            <Label Width="70" Height="25" Padding="3" Margin="5">Joystick 3</Label>
            <Label x:Name="lblJoy3" Width="200" Height="25" Padding="3" Margin="5" Background="white"/>
            <Button x:Name="btnJoy3" Content="Select" Height="25" Width="100" Margin="5"/>
        </StackPanel>
        <StackPanel Margin="5" Orientation="Horizontal" HorizontalAlignment="Center">
            <Label Width="70" Height="25" Padding="3" Margin="5">Joystick 4</Label>
            <Label x:Name="lblJoy4" Width="200" Height="25" Padding="3" Margin="5" Background="white"/>
            <Button x:Name="btnJoy4" Content="Select" Height="25" Width="100" Margin="5"/>
        </StackPanel>

        <StackPanel Margin="10" Orientation="Horizontal" HorizontalAlignment="Center">
            <Button x:Name="btnSaveGame" Content="Save Game Config" Height="25" Width="110" Margin="5"/>
            <Button x:Name="btnCancelEdit" Content="Cancel Edit" Height="25" Width="110" Margin="5"/>
        </StackPanel>
    </StackPanel>
    <StackPanel Margin="5" VerticalAlignment="Bottom" HorizontalAlignment="Left">
        <Label Width="200" Height="25" Padding="3" Margin="5">Copyright, Daniel Bailey 2023</Label>
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
<StackPanel Margin="30" Background="#f0f0f5">
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
        Title="Game Picker"
        Background="#66ffcc"
        Width="500"
        Height="200"
        WindowStartupLocation="CenterScreen"
        WindowStyle="None"
>
<StackPanel Margin="10" HorizontalAlignment="Center" VerticalAlignment="Center">
    <Label FontSize="25" Content="Loading Game, Please Wait"></Label>
</StackPanel>
</Window>
"@
$xmlSplashpnpDevice = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Game Picker"
        Background="#66ffcc"
        Width="500"
        Height="200"
        WindowStartupLocation="CenterScreen"
        WindowStyle="None"
>
<StackPanel Margin="10" HorizontalAlignment="Center" VerticalAlignment="Center">
    <Label FontSize="25" Content="Finding Available Joysticks, Please Wait"></Label>
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
        $Error
        #Couldn't get version info so presuming no internet and no big deal so failing silently
    }
}

#Get the Joysticks now.
$Joysticks = @(Get-Joysticks $xmlSplashpnpDevice)

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


#Populate labels and text boxes with bindings
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
$btnAbout = $Window.FindName('btnAbout')
$btnAbout.Add_Click({
    $About = Import-Xaml -xvar $xmlAbout
    $About.ShowDialog()
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
    Switch-All -Joysticks $Joysticks -Options $Options -On
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

#Populate the Joysticks textboxes using a joystick picker
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
        #use the game
        $SelectedGame = ($Window.FindName('ComboGame')).SelectedItem
        
        IF ($SelectedGame -ne " "){ #If we have selected a game and changed the name remove the old one
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