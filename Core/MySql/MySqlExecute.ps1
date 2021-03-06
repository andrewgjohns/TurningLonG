function Parse-Sql
{
	Param(
		[parameter(Mandatory=$true)]
		[alias("q")]
		[string]
		$Query,
		[parameter(Mandatory=$true)]
		[alias("d")]
		[string]
		$Database)

	$result = $Query -replace "{{DatabaseName}}", $Database 
	$result
}

function Execute-NonQuery
{
	Param(
		[parameter(Mandatory=$true)]
		[alias("s")]
		[string]
		$Server,
		[parameter()]
		[alias("d")]
		[string]
		$Database = "",
		[parameter(Mandatory=$true)]
		[alias("u")]
		[string]
		$Username,
		[parameter(Mandatory=$true)]
		[alias("p")]
		[string]
		$Password,
		[parameter(Mandatory=$true)]
		[alias("q")]
		[string]
		$Query)

	$ConnectionString = "server=" + $Server + ";port=3306;uid=" + $Username + ";pwd=" + $Password + ";"
	
	if ($Database) {
		$ConnectionString += "database=$Database;"
		$Query = Parse-Sql -q $Query -d $Database
	}

	Try {
	  $MySqlLib = (Get-Location).Path + "\bin\Debug\MySql.Data.dll"   
	  [Reflection.Assembly]::LoadFile($MySqlLib) | Out-Null
	  [void][System.Reflection.Assembly]::LoadWithPartialName("MySql.Data")
	  $Connection = New-Object MySql.Data.MySqlClient.MySqlConnection($ConnectionString)
	  $Connection.Open()
	  $Command = New-Object MySql.Data.MySqlClient.MySqlCommand($Query, $Connection)
	  $Command.CommandTimeout=0
	  $Command.ExecuteNonQuery() | Out-Null
	}
	Catch {
	  Write-Warning $Query
	  Write-Error $_.Exception.ItemName
	  throw
	}
	Finally {
	  $Connection.Close()
	}
}

function Execute-Reader
{
	Param(
		[parameter(Mandatory=$true)]
		[alias("s")]
		[string]
		$Server,
		[parameter()]
		[alias("d")]
		[string]
		$Database = "",
		[parameter(Mandatory=$true)]
		[alias("u")]
		[string]
		$Username,
		[parameter(Mandatory=$true)]
		[alias("p")]
		[string]
		$Password,
		[parameter(Mandatory=$true)]
		[alias("q")]
		[string]
		$Query)

	$ConnectionString = "server=" + $Server + ";port=3306;uid=" + $Username + ";pwd=" + $Password + ";"

	if ($Database) {
		$ConnectionString += "database=$Database;"
		$Query = Parse-Sql -q $Query -d $Database
	}
	
	$result = $null

	Try {
	  $MySqlLib = (Get-Location).Path + "\bin\Debug\MySql.Data.dll"   
	  [Reflection.Assembly]::LoadFile($MySqlLib) | Out-Null
	  [void][System.Reflection.Assembly]::LoadWithPartialName("MySql.Data")
	  $Connection = New-Object MySql.Data.MySqlClient.MySqlConnection($ConnectionString)
	  [void]$Connection.Open()
	  $Command = New-Object MySql.Data.MySqlClient.MySqlCommand($Query, $Connection)
	  $Command.CommandTimeout=0
	  $Reader = $Command.ExecuteReader()
	  
	  $Datatable = New-Object System.Data.DataTable
	  $DataTable.Load($Reader) | Out-Null
	  $result = $DataTable
	}
	Catch {
	  Write-Warning $Query
	  Write-Error $_.Exception.ItemName
	  throw
	}
	Finally {
	  $Connection.Close()
	}
	
	$result
}

function Execute-File
{
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
		[alias("f")]
		[string]
		$File)
	
	[string]$Query = (Get-Content -Path $File) -join "`r`n"
	Execute-Reader -s $Server -d $Database -u $Username -p $Password -q $Query
}

function Execute-NonQueryFile
{
	Param(
		[parameter(Mandatory=$true)]
		[alias("s")]
		[string]
		$Server,
		[parameter()]
		[alias("d")]
		[string]
		$Database = "",
		[parameter(Mandatory=$true)]
		[alias("u")]
		[string]
		$Username,
		[parameter(Mandatory=$true)]
		[alias("p")]
		[string]
		$Password,
		[parameter(Mandatory=$true)]
		[alias("f")]
		[string]
		$File)

	$ConnectionString = "server=" + $Server + ";port=3306;uid=" + $Username + ";pwd=" + $Password + ";default command timeout=36000;"
	[string]$Query = (Get-Content -Path $File) -join "`r`n"

	if ($Database) {
		$ConnectionString += "database=$Database;"
		$Query = Parse-Sql -q $Query -d $Database		
	}

	Try {

		$MySqlLib = (Get-Location).Path + "\bin\Debug\MySql.Data.dll"   
		[Reflection.Assembly]::LoadFile($MySqlLib) | Out-Null
		[void][System.Reflection.Assembly]::LoadWithPartialName("MySql.Data")
		$Connection = New-Object MySql.Data.MySqlClient.MySqlConnection($ConnectionString)
		$Connection.Open()
		$script = New-Object MySql.Data.MySqlClient.MySqlScript($Connection, $Query);
	
		$script.Execute() | Out-Null
	}
	Catch {
	  Write-Warning $Query
	  Write-Error $_.Exception.ItemName
	  throw
	}
	Finally {
	  $Connection.Close()
	}

}