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

$Window = Import-Xaml "Main.xaml"

$Window.ShowDialog() | Out-Null