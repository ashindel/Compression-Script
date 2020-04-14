<# Alan Shindelman
PowerShell DB Dump Compression
Task 1 of x
#>

<# Task 1: Take a folder-path as an argument/parameter. For example "C:\users\alan\document" 	
Verify the folder exists. If it does not, output an error message that explains it, and stop the script. 
#>		

function Find-Path {
    param (
        [Validatescript({
            if( -Not ($_ | Test-Path)){
                throw "File or folder does not exist"
            }
            ##else {
            ##    throw "found file"     testing to see it works   ... maybe use try catch instead
            ##}
            return $true 
        })]
        [System.IO.FileInfo]$Path
    )
}
$Path = Read-Host -Prompt "Enter the folder path"
New-Item $Path -type Directory

