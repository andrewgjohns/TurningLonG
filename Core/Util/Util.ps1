function Get-Files
{
	Param (
		[Parameter(Mandatory=$true)]
		[alias("p")]
		[string]
		$Path,
		[Parameter(Mandatory=$true)]
		[alias("e")]
		[string]
		$Extension
	)

	Get-ChildItem -Path $Path -Recurse | ? {$_.name -match ".$Extension"}
}


function Print-BannerHeader
{
	Param (
		[parameter(Mandatory=$true)]
		[string]
		$Header
	)

	$BannerWidth = 100
	$Banner = "#" * $BannerWidth
	[int]$Length = ($BannerWidth - ($Header.Length + 8 )) / 2;
	$BannerLeft = ("#" * $Length) + "    " + $Header + "    "
	$BannerRight = "#" * ($BannerWidth - $BannerLeft.Length)
	Write-Host ""
	Write-Host ""
	Write-Host $Banner
	Write-Host $BannerLeft$BannerRight
	Write-Host $Banner
	Write-Host ""
}

function Print-BannerFooter
{
	$BannerWidth = 100
	$Banner = "#" * $BannerWidth
	[int]$Length = ($BannerWidth - (3 + 8 )) / 2;
	$BannerLeft = ("#" * $Length) + "    END    "
	$BannerRight = "#" * ($BannerWidth - $BannerLeft.Length)
	
	Write-Host ""
	Write-Host $Banner
	Write-Host $BannerLeft$BannerRight
	Write-Host $Banner
	Write-Host ""
	Write-Host ""
}