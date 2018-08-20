<#
.Synopsis
    Script to check network connectivity
.Description
    This script is sending ping request to some host every second for specified duration (default - 1 day, needs to be specified in seconds) and writes the results in a csv log file.
.Parameter Destination
    Specifies destination host.
.Parameter Duration
    Ping duration, specified in seconds.
.Parameter LogPath
    Log location, including filename.
.Parameter Output
    Set to 1 to see output to console, by default it's 0 (no output) 
.Example 
    .\pingtest.ps1 -Destination google.com
.Example
    .\pingtest.ps1 -Destination google.com -Duration 60 -LogPath .\pinglog.csv
.Example
    .\pingtest.ps1 -Destination google.com -Duration 60 -LogPath D:\pinglog.csv -Output 1
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$True)]
    [string]$Destination,
    [int]$Duration = '86400',
    [string]$LogPath = '.\pinglog.csv',
    [bool]$Output=$false 
)
$Duration = [convert]::ToInt32($Duration, 10)
$Ping = @()
#Test if path exists, if not, create it
If (-not (Test-Path (Split-Path $LogPath) -PathType Container))
{   
    New-Item (Split-Path $LogPath) -ItemType Directory | Out-Null
}

#Test if log file exists, if not seed it with a header row
If (-not (Test-Path $LogPath))
{   
    Add-Content -Value 'TimeStamp,Source,Destination,IPV4Address,Status,ResponseTime' -Path $LogPath
}
$dur = $Duration/60    
Write-Host "Script will run for $dur minutes. Ends at:" (Get-date).AddSeconds($Duration)
While ($Duration -gt 0)
{
    $Ping += Get-WmiObject Win32_PingStatus -Filter "Address = '$Destination'" | Select @{Label="TimeStamp";Expression={Get-Date}},@{Label="Source";Expression={ $_.__Server }},@{Label="Destination";Expression={ $_.Address }},IPv4Address,@{Label="Status";Expression={ If ($_.StatusCode -ne 0) {"Failed"} Else {"OK"}}},ResponseTime
    $Duration --
    if($Output)
    {
        $Ping | Select TimeStamp,Source,Destination,IPv4Address,Status,ResponseTime  | ft -AutoSize
    }
    add-content $LogPath "$($Ping.TimeStamp), $($Ping.Source), $($Ping.Destination), $($Ping.IPv4Address), $($Ping.Status), $($Ping.ResponseTime)"
    Clear-Variable -name Ping
    Start-Sleep -Seconds 1
}
Write-Host "Script execution finished."
if ($LogPath -eq '.\pinglog.csv' )
{
    $LogPath = Resolve-Path "pinglog.csv"
    Write-Host "Log location $LogPath"
}
Else{
    Write-Host "Log location $LogPath"
}