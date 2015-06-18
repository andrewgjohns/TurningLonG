$server = "localhost"
$database = "example"
$username = "root"
$databaseSchema = "example_database"
$password = Read-Host "Enter password for user: $username"

Set-Location $PSScriptRoot

.\Deploy.ps1 -s $server -d $database -u $username -p $password -ds $databaseSchema