Param(
	[parameter(Mandatory=$true)]
	[alias("s")]
	[string]
	$Server,
	[parameter(Mandatory=$true)]
	[alias("d")]
	[string]
	$Database,
	[parameter(Mandatory=$true)]
	[alias("u")]
	[string]
	$Username,
	[parameter(Mandatory=$true)]
	[alias("p")]
	[string]
	$Password,
	[parameter(Mandatory=$true)]
	[alias("ds")]
	[string]
	$DatabaseSchema,
	[parameter()]
	[alias("df")]
	[System.Collections.Specialized.OrderedDictionary]
	$SchemaFolders = [ordered]@{ "tables" = 1; 
						"alters" = 1; 
						"triggers" = 0; 
						"views" = 0; 
						"indexes" = 0; 
						"functions" = 0;
						"procedures" = 2;
						"permissions" = 0;
						"post_deploy" = 2 } 
)

Set-Location $PSScriptRoot
. Core\MySql\MySqlExecute.ps1
. Core\Util\Util.ps1

# GLOBALS
$Path = (Get-Location).Path
$User = $env:username
$Version = "0.0.1"

$global:DatabaseScriptsRun = $null
$global:FilesToDeploy = $null


Print-BannerHeader "Deploying Database"
Write-Host "Run time parameters:"
foreach ($key in $MyInvocation.BoundParameters.keys)
{
	If ($($key) -ne "SchemaFolders")
	{
		Write-Host "  Parameter: $($key) = $($MyInvocation.BoundParameters[$key])"
	}
}
Write-Host "  SchemaFolders:"
$SchemaFolders.Keys | ForEach {
	$value = $SchemaFolders[$_]
	if ($value -eq 0)
	{
		Write-Host "    Folder: $_"
	}
	elseif ($value -eq 1)
	{
		Write-Host "    Folder: $_ : One time folder"
	}
	else
	{
		Write-Host "    Folder: $_ : always run folder"
	}

}

# Build Database
function Create-Database
{
	Print-BannerHeader "Database Check"
	Write-Host "Checking if Database: $Database exists"
    $Query = "SELECT SCHEMA_NAME FROM information_schema.SCHEMATA WHERE SCHEMA_NAME = '$Database'"
	$result = Execute-Reader -s $Server -u $Username -p $Password -q $Query

	if ($result -eq $null)
	{
		Write-Host "  Database does not exist"
		$Query = "CREATE DATABASE $Database"
		Execute-NonQuery -s $Server -u $Username -p $Password -q $Query
		Write-Host "  Database created"
	} 
	else
	{
		Write-Host "  Database exists"
	}
	Print-BannerFooter
}

function Create-DatbaseVersionTables
{
	Print-BannerHeader "Version Tables Check"
	Write-Host "Checking if versioning tables exist"
    $Query = "SELECT * FROM information_schema.tables WHERE table_schema = '$Database' AND table_name = 'database_version'"
	$result = Execute-Reader -s $Server -u $Username -p $Password -q $Query

	if ($result -eq $null)
	{
		Write-Host "  Database Version tables do not exist"
		$file = "$Path\Core\MySql\CreateDatabase\CreateBuildTables.sql"
		Execute-NonQueryFile -s $Server -u $Username -d $Database -p $Password -f $file
		Write-Host "  Database Version tables created"
	} 
	else
	{
		Write-Host "  Database version exist"
	}
	Print-BannerFooter
}

function Get-DeploymentItems
{
	Print-BannerHeader "Deployment Items"

	Write-Host "Getting Deployment History"

	Write-Host "  Deployment Script History"
	$Query = "SELECT * FROM database_scriptsrun"
	$global:DatabaseScriptsRun = Execute-Reader -s $Server -d $Database -u $Username -p $Password -q $Query

	Write-Host "Getting Source Files:"
	$rootFolder = "$Path\Schemas\$DatabaseSchema"
	$Files = $null;
	$SchemaFolders.Keys | Foreach {
		Write-Host "  $_"
		if ($Files)
		{
			$Files += Get-Files -p "$rootFolder\$_" -e "sql"
		}
		else
		{
			$Files = Get-Files -p "$rootFolder\$_" -e "sql"
		}
	}
	$global:FilesToDeploy = $Files

	Print-BannerFooter
}

function Deploy-Script
{
	Param(
		[parameter(Mandatory=$true)]
		[alias("v")]
		[int]
		$VersionId,
		[parameter(Mandatory=$true)]
		[alias("f")]
		[string]
		$File,
		[parameter(Mandatory=$true)]
		[alias("h")]
		[string]
		$Hash,
		[parameter(Mandatory=$true)]
		[alias("o")]
		[int]
		$IsOneTime
	)

	$ReferenceName = ($File -replace [regex]::Escape("$Path\Schemas\$DatabaseSchema\"), "") -replace [regex]::Escape("\"), "\\"
	$Content = ((Get-Content -Path $File) -replace "'", "\'") -join "`r`n"
	$dt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

	$Query =  "INSERT INTO database_scriptsrun "
	$Query += "(version_id, script_name, script_hash, text_of_script, one_time_script, created_date, modified_date, modified_by)"
	$Query += "VALUES "
	$Query += "($VersionId,'$ReferenceName','$Hash','$Content',$IsOneTime,'$dt','$dt','$user');"

	Execute-NonQueryFile -s $Server -u $Username -d $Database -p $Password -f $file
	Execute-NonQuery -s $Server -u $Username -d $Database -p $Password -q $Query
}

function Deploy-Scripts
{

	Print-BannerHeader "Deploying"
	$dt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
	$Query = "INSERT INTO database_version (version, created_date, modified_date, modified_by)"
	$Query += " VALUES  ('$Version', '$dt', '$dt', '$User'); SELECT LAST_INSERT_ID() VersionId;"
	$result = Execute-Reader -s $Server -u $Username -d $Database -p $Password -q $Query

	$VersionId = $result.VersionId

	foreach($file in $global:FilesToDeploy)
	{
		Write-Host ""
		$FilePath = $file.FullName
		$FileName = $file.Name
		$ReferenceName = ($FilePath -replace [regex]::Escape("$Path\Schemas\$DatabaseSchema\"), "") 
		$RootFolder = $ReferenceName.Split("\")[0]
		$Hash = (Get-FileHash $FilePath -Algorithm SHA384).Hash
		$IsOneTime = $SchemaFolders[$rootFolder]

		$PreviousRun = $null
		$PreviousFile = $null
		if ($global:DatabaseScriptsRun)
		{
			foreach($row in $global:DatabaseScriptsRun)
			{
				if ($row.script_hash -eq $Hash)
				{
					$PreviousRun = $row
				}
				
				if ($row.script_name -eq $ReferenceName)
				{
					$PreviousFile = $row
				}
				
				if (($PreviousRun) -and ($PreviousFile))
				{
					break 
				}
			}
		}
		
		if ($IsOneTime -eq 1)
		{
			if (($PreviousRun) -or ($PreviousFile))
			{
				if ($PreviousFile) 
				{
					[string]$previousFileName = $PreviousFile.script_name
					[string]$previousDate = $PreviousFile.created_date.ToString("yyyy-MM-dd HH:mm:ss")
					Write-Host "Skipping: $ReferenceName `r`n`t`tAlready Deployed `r`n`t`t`t $previousFileName : $previousDate"
				}
				else
				{
					[string]$previousFileName = $PreviousRun.script_name
					[string]$previousDate = $PreviousRun.created_date.ToString("yyyy-MM-dd HH:mm:ss")
					Write-Host "Skipping: $ReferenceName `r`n`t`tAlready Deployed `r`n`t`t`t $previousFileName : $previousDate"
				}				
				continue
			}
			else
			{
				Write-Host "Deploying: $ReferenceName > One Time Deploy"
			}
		}
		elseif ($IsOneTime -eq 0)
		{
			if ($PreviousRun)
			{
				Write-Host "Skipping: $ReferenceName `r`n`t`tAlready Deployed `r`n`t`t`t" $PreviousRun.script_name : $PreviousRun.created_date
				continue
			}
			else
			{
				Write-Host "Deploying: $ReferenceName"
			}
		}
		else
		{
			Write-Host "Deploying always run script: $ReferenceName"
		}

		
		Deploy-Script -v $VersionId -f $filePath -h $Hash -o $IsOneTime 		
		
	}

	Print-BannerFooter
}


Create-Database
Create-DatbaseVersionTables
Get-DeploymentItems
Get-DeploymentItems
Deploy-Scripts
