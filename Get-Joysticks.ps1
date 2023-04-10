Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object System.Windows.Forms.Form
$form.Text = 'Select a Joystick'
$form.Size = New-Object System.Drawing.Size(500,500)
$form.StartPosition = 'CenterScreen'

$okButton = New-Object System.Windows.Forms.Button
$okButton.Location = New-Object System.Drawing.Point(75,425)
$okButton.Size = New-Object System.Drawing.Size(75,23)
$okButton.Text = 'Copy'
#$okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
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
    $x
} 