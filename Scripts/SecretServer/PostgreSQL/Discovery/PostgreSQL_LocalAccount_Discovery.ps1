<#
    Created by Cagdas Barak - Delinea

    .SYNOPSIS
    Discovery script for finding PostgreSQL Logins on the target machine.
    .DESCRIPTION
    C:\Program Files (x86)\PostgreSQL\Npgsql\bin\net451\Npgsql.dll path must have Npgsql.dll file.
    NOTES
    The following logPath variable is used for troubleshooting when necessary; a file is written to this path with errors.
    A file will be created for each server and overwritten on each run.

    Nick Drosinis
    Add SSL Mode and trust Certificate (if you have only IP) on connection string to connect Postgresql on Azure  (SaaS) 
    Add System.Threading.Tasks.Extensions.dll 
    Added Log file "C:\scripts\postgres.log"

#>

$server = $args[0]
$port = '5432'
$database = 'postgres'
$username = $args[1]
$password = $args[2]

# Log file path
$logFile = "C:\scripts\postgres.log"

# Function to write to the log file
function Write-Log {
    param (
        [string]$message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "$timestamp - $message"
    Add-Content -Path $logFile -Value $logMessage
}

$FoundPostgreSQLUsers = @()

try {
    # Specify the path of the Npgsql .NET data provider
    $npgsqlDllPath = "C:\Program Files (x86)\PostgreSQL\Npgsql\bin\net451\Npgsql.dll"
    $tasksDllPath = "C:\Program Files (x86)\PostgreSQL\Npgsql\bin\net451\System.Threading.Tasks.Extensions.dll"

    # Load the DLL file
    [System.Reflection.Assembly]::LoadFile($npgsqlDllPath) | Out-Null
    [System.Reflection.Assembly]::LoadFile($tasksDllPath) | Out-Null
    
    # Construct the PostgreSQL connection string
																											
    $connectionString = "Host=$server;Port=$port;Database=$database;User Id=$username;Password=$password;Ssl Mode=Require;Trust Server Certificate=True;"
  
    # Write the server connection to the log file  
    #Write-Log "Connection : $server"

    # Create a connection to the PostgreSQL database
    $connection = New-Object Npgsql.NpgsqlConnection
    $connection.ConnectionString = $connectionString
    $connection.Open()

    # SQL Query to find admin accounts
    $query = "SELECT usename FROM pg_catalog.pg_user WHERE usename NOT IN ('postgres');"
    $command = $connection.CreateCommand()
    $command.CommandText = $query

    # for IBM SecretServer
    $reader = $command.ExecuteReader()

    while ($reader.Read()) {
        $object = New-Object –TypeName PSObject
        $object | Add-Member -MemberType NoteProperty -Name Machine -Value $server
        $object | Add-Member -MemberType NoteProperty -Name Username -Value $reader["usename"]
        $FoundPostgreSQLUsers += $object
    }

    $reader.Close()
    $connection.Close()
} catch {
    Write-Log "Error: $($_.Exception.Message)"
    throw "Hata: $($_.Exception.Message)"
}

$FoundPostgreSQLUsers
