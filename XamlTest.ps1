
function Import-Xaml {
	[xml]$xaml = Get-Content -Path $PSScriptRoot\Main.xaml
	$manager = New-Object System.Xml.XmlNamespaceManager -ArgumentList $xaml.NameTable
	$manager.AddNamespace("x", "http://schemas.microsoft.com/winfx/2006/xaml");
	$xamlReader = New-Object System.Xml.XmlNodeReader $xaml
	[Windows.Markup.XamlReader]::Load($xamlReader)
}
[System.Reflection.Assembly]::LoadWithPartialName("PresentationFramework") | Out-Null
$Window = Import-Xaml 
$Window.ShowDialog()