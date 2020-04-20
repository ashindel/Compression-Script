<# Alan Shindelman
PowerShell DB Dump Compression
Task 1 of x
#>

<# Task 1: Take a folder-path as an argument/parameter. For example "C:\users\alan\document" 	
Verify the folder exists. If it does not, output an error message that explains it, and stop the script. 
- Get a list of all the child/sub-folders ther
- Output that list of folder-names to the console (Fullname property with no column header)
#>	


function Find-Path {
    param (
        [Validatescript({
            if( -Not ($_ | Test-Path)){
                throw "The path $_ does not exist"  ## If specified path does not exist, display error message and stop script
            }
            # if(-Not ($_ | Test-Path -PathType Container)){
            #     throw "The Path argument must be a container. File paths are not allowed as of now."
            # }
            return $true
            })]
        [System.IO.FileInfo]$Path
    )
    if ( -Not (Get-ChildItem -Path $Path -Directory | Where-Object {$_.PSIsContainer -eq $true -and $_.Name -Like "scripts"} )) {
        throw "There is no dbdump folder in the path $Path"
    }
    else {Get-ChildItem -Path $Path -Recurse | Format-Table -HideTableHeaders FullName | out-file C:\Users\ajs573\Documents\DB-Dump-Compression-Repo\Outputs\dbdump_master_list.txt
        
    } 
}
# Invoke Find-Path function with specified path location
Find-Path -path C:\users\ajs573\Documents
