## write-host "testing"
# get-service -Name "*net*"
# get-service | outfile c:\services.txt
# Get-Service -Name Audiosrv
## Pipe Formatting

Get-Service | Format-List DisplayName, status, RequiredServices
Get-Service | Format-Table DisplayName, status, RequiredServices 
Get-Service | sort-object -Property status | Format-List DisplayName, status, RequiredServices

##Pipe Output
get-service | out-file c:\users\ajs573\services.txt
Get-Service | select-object * | Out-GridView
try {
    get-service | out-file c:\services.txt
 }
 catch [UnauthorizedAccessException] {
    Write-Host "We do not have permission to write"
 }

function forloop {
    for($i=10, $i -gt 1, $i--)
    {
    Write-Verbose: "i is $i"
    }
}
function subtract {
    $sub = [int](2-1)
    Write-Verbose: "$sub"
}

get-date | Out-File -FilePath c:\users\ajs573\Documents\output.txt -append

If ( -Not (Test-Path C:\Users\ajs573\Documents\ScriptOutput ) )
{
    New-Item -Path C:\Users\ajs573\Documents\ -Name ScriptOutput -ItemType "directory" ## add folder called "ScriptOutput in the specified path name"
    Set-Content -Path C:\Users\ajs573\Documents\ScriptOutput\Created.txt -Value "This directroy was created" ##
    Get-Date -Format MM/dd/yyyy-hh:mm
    Add-Content -NoNewLine -Path C:\Users\ajs573\Documents\ScriptOutput\Created.txt  
}

## Script Testing File
# Simple html script maker
get-eventlog -LogName system -Newest 5 -EntryType error | Select-Object -Property index, source, message | ConvertTo-Html | out-file C:\Users\ajs573\Documents\DB-Dump-Compression-Repo\Scripts\test.htm -Append

## https://4sysops.com/archives/how-to-use-parameter-validation-in-powershell-scripts/
## Function basics

function Get-LoggedOnUser
 {
     [CmdletBinding()]
     param
     (
         [Parameter()]
         [ValidatePattern('^\w+$')]
         [string]$ComputerName
     )
     Get-WmiObject –ComputerName $ComputerName –Class 'Win32_OperatingSystem'
 }