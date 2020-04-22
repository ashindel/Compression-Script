<# Alan Shindelman
PowerShell DB Dump Compression
#>

<# Task 1: 
- Take a folder-path as an argument/parameter. For example "C:\users\alan\document" 	
    - Verify the folder exists. If it does not, output an error message that explains it, and stop the script. 
- Get a list of all the child/sub-folders ther
- Output that list of folder-names to the console (Fullname property with no column header)
#>	

<# Task 2: 
- Given the path of a folder, the script will look for a child/sub-folder named "dbdump" there. 	
    - If there is no "dbdump" sub-folder, then do nothing. 		
    - Inside the "dbdump" folder, the script will find all the files under the dbdump folder	
        - Disregard any subfolders and their child files inside the dbdump folder
        - Add full-path of the dbdump child files to a master-list that the script is keeping track of. 	
- At the end of the script, output the file-paths of every file to a saved master-list.
#>

<# Task 3:
- Extend the script you wrote for task 2 by using PowerShell to compress every file your script found into the .zip file format.
- Have the .zip files placed into a new folder called "archived"
- In addition to writing the list of files to that master-list.txt, the script will have generated .zip files for each file it found and add them to the master list
    - Make master list format better?
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
    # Created Variable
    $dbDumpPath = $Path.toString() + "\dbdump" ## dbDumpPath is = to C:\users\ajs573\Documents\dbdump
    # $dbArchivedPath = $dbDumpPath.toString() + "\archived" ## dbArchievedPath is = to C:\users\ajs573\Documents\dbdump\archived 
    $MasterList = "C:\Users\ajs573\Documents\DB-Dump-Compression-Repo\Outputs\dbdump_master_list.txt" ## Master list of outputted files from dbdump folder and zipped files
    
    # Find dbdump folder files / add to master list / zip found files / add zipped files to master list
    if ( -Not (Get-ChildItem -Path $Path -Directory | Where-Object {$_.PSIsContainer -eq $true -and $_.Name -Like "dbdump"} )) {
        throw "There is no dbdump folder in the path $Path"
    }
    else { 
        Get-ChildItem -Path $dbDumpPath -File | Format-Table -HideTableHeaders FullName | out-file $MasterList   ## add files in dbdump to master list
        $ArchivedFolder = New-Item -Path $dbDumpPath -Name "archived" -ItemType "directory" ## Creates new archived folder
        Get-ChildItem -Path $dbDumpPath -File | Compress-Archive -Update -DestinationPath ($ArchivedFolder.toString() + "\archived.zip")
        Get-ChildItem -Path $ArchivedFolder -File -Recurse | Format-Table -HideTableHeaders FullName | out-file -append $MasterList ## add new zip files to master list
    }
}
# Invoke Find-Path function with specified path location
Find-Path -path C:\users\ajs573\Documents


<# ## Possible zipping of individual files ##
Add-Type -assembly 'System.IO.Compression'
Add-Type -assembly 'System.IO.Compression.FileSystem'
New-Item -Path $dbDumpPath -Name "archived" -ItemType "directory"
[string]$zipFN = 'C:\users\ajs573\Documents\dbdump\archived'
$filesToZip = (Get-ChildItem -Path $dbDumpPath -File).FullName  # | Compress-Archive -Update -DestinationPath C:\users\ajs573\Documents\dbdump\archived 

[System.IO.Compression.ZipArchive]$ZipFile = [System.IO.Compression.ZipFile]::Open($zipFN,([System.IO.Compression.ZipArchiveMode]::Create))
foreach ($fileToZip in $filesToZip) {
    [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($ZipFile, $fileToZip, (Split-Path $fileToZip -Leaf))
}
    $ZipFile.Dispose()
#>