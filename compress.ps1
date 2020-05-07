<# Alan Shindelman
PowerShell DB Dump Compression Script
May 6th 2020
#>

<# Task 1: (Completed)
- Take a folder-path as an argument/parameter. For example "C:\users\alan\document" 	
    - Verify the folder exists. If it does not, output an error message that explains it, and stop the script. 
- Get a list of all the child/sub-folders ther
- Output that list of folder-names to the console (Fullname property with no column header)
#>	

<# Task 2: (Completed)
- Given the path of a folder, the script will look for a child/sub-folder named "dbdump" there. 	
    - If there is no "dbdump" sub-folder, then do nothing. 		
    - Inside the "dbdump" folder, the script will find all the files under the dbdump folder	
        - Disregard any subfolders and their child files inside the dbdump folder
        - Add full-path of the dbdump child files to a master-list that the script is keeping track of. 	
- At the end of the script, output the file-paths of every file to a saved master-list.
#>

<# Task 3: (Completed)
- Extend the script you wrote for task 2 by using PowerShell to compress every file your script found into the .zip file format.
- Have the .zip files placed into a new folder called "archived"
- In addition to writing the list of files to that master-list.txt, the script will have generated .zip files for each file it found and add them to the master list
#>

<# Task 3.5: (Completed)
    - Fix errors when running script again 
    - Add full path names to the appended master list, second iteration changes file path output in $Masterlist
#>

<# Task 4: (Completed)
- Only zip files that have the .sql file-extension. 
- Record more information about the files you zip.
    - The original file's size 	
    - The date-time the original file was created 	
    - The file size of the newly created .zip file
- Output the above information (in the bullet points) to the log file in a sensible way that is readable by humans
- Create variables to make changing these aspects of the script easier 
#>

<# Task 5: (Completed)
- change "hardcoded" file paths, folder names, and text into variables so it is easier to test.
- Give the parameters a default value.	
#>

<# Task 6: (Completed)
- Test what happens when the $FileExtension parameter does not include the "." for example Find-Path -FileExtension "sql".
Handle -FileExtension ".sql" and -FileExtension "sql" gracefully. In other words, the script should behave the same way with both of those.
- Handle gracefully when the $MasterList parameter is an invalid or inaccessible location.
Currently the script throws an unexpected exception when it first tries to write to $MasterList (line 104 Out-File).
#>

<# Task 7:
- Expand how the script traverses through file directories to closer mimic Jenkins directory structure 
#>

function Invoke-DBCompressScript {
    [CmdletBinding()]
    param (
        [Validatescript({
            # Test if the user specified $path exists
            if( -Not ($_ | Test-Path)){
                throw "The path $_ does not exist"  
            }
            return $true
            })]
        # Parameters
        [System.IO.FileInfo]$Path = "C:\Users\ajs573\Documents\DB-Dump-Compression-Repo\DB-Dump-Compression\testStructures\Drupal 8 Dumps", # $path is the most parent folder of file structure
        [String]$DBDumpFolderName = "\dbdump", ## default value of dbdump folder within a specific repo
        [String]$SQLFileExtension = ".sql", ## default value of .sql file extenion
        [String]$ArchivedFolderPath = "\archived", ## default value of archived folder
        [String]$MasterListFolderPath = "C:\Users\ajs573\Documents\DB-Dump-Compression-Repo\DB-Dump-Compression\testStructures\Masterlist-Output", ## default value of master list folder location
        [String]$MasterListFilePath = $MasterListFolderPath.toString() + "\DBCompressScript-Text-Output.txt"  ## Master list text file location
    )
    $DebugPreference = "Continue" ## "SilentlyContinue = no debug messages, "Continue" will display debug messages
    $dbDumpString = $DBDumpFolderName.Substring(1) ## $dbDumpFolderName removes '/' from /dbdump string

    # Test the $MasterListFolderPath  to determine script output behavior  
    # If $MasterListFolderPath  is valid, use Out-File command 
    # If $MasterListFolderPath  is not valid, output Format-Table into console
    if (Test-Path -Path $MasterListFolderPath) {
        Write-Debug "The master list folder path: $($MasterListFolderPath) is valid."
        Write-Debug "Script output will be sent to $($MasterListFilePath)"
        $MasterListValid = $true
    }
    else {
        Write-Debug "The master list folder path: $($MasterListFolderPath) is not valid."
        Write-Debug "Script output will be sent to the console."
        $MasterListValid = $false
    } 

    # #Get every original files in $Path
    $OutputText = Get-ChildItem -Path $Path -File -Recurse | Format-Table -HideTableHeaders FullName -AutoSize 
    # $MasterListValid boolean value determines where all files in $Path are outputted 
    if ($MasterListValid) {
        $OutputText | out-file $MasterListFilePath -append 
    }
    else {
        Write-Output ($OutputText | Out-String)
    }
    
    $PathChildFolders = Get-ChildItem -Path $Path -Directory | Where-Object {$_.Name -match "d8c"} 
    foreach ($dbdumpFolderPath in $PathChildFolders) { ## get the dbdump folder in each d8c repo folder 
        if ( -Not (Get-ChildItem -Path $dbdumpFolderPath.FullName -Directory | Where-Object {$_.Name -like $dbDumpString} )) {
            throw 'There is no ' + $dbDumpString + ' folder in the path: ' + $dbdumpFolderPath.FullName
        }
        else { 
            $d8cChildFolders = Get-ChildItem -Path $dbdumpFolderPath.FullName -Directory | Where-Object {$_.Name -like $dbDumpString}
            $dbdumpChildFolders =  Get-ChildItem -Path $d8cChildFolders.FullName -Directory | Where-Object {$_.Name -match "its"}
            # get the its### folders in each dbdump folder
            foreach ($itsFolderName in $dbdumpChildFolders) { ## get each its folder in the dbdump folder from each d8c repo folder
                # Set full path of each its### folder equal to $itsFolderFullPath
                $itsFolderFullPath = $itsFolderName.Fullname
                #  Get-FriendlySize function to get human-readable file size format for $MasterList output
                function Get-FriendlySize {
                    # Write-Debug messages commented out for usability purposes
                    param($Bytes)
                        #Write-Debug "Inside $($MyInvocation.MyCommand) now"
                        #Write-Debug "  bytes is originally '$($Bytes)'"
                    $sizes='Bytes,KB,MB,GB,TB,PB,EB,ZB' -split ','
                    for($i=0; ($Bytes -ge 1kb) -and ($i -lt $sizes.Count); $i++) {
                        $Bytes/=1kb
                    } $N=2; 
                        #Write-Debug "  bytes is now '$($Bytes)'"
                        #Write-Debug "  N is '$($N)'"
                    if($i -eq 0) { 
                    $N=0 
                    } "{0:N$($N)} {1}" -f $Bytes, $sizes[$i] 
                }
                # Handle .sql and sql inputs for $SQLFileExtension
                if (-Not ($SQLFileExtension | Where-Object {($_ -like ".sql") -or ($_ -like "sql")})) {
                    Write-Debug ('The ' + $SQLFileExtension + ' file extension is not correct.')
                    # exit
                }  
                # Archived folder variables
                $ArchivedFullPath = $itsFolderFullPath.toString() + $ArchivedFolderPath ## $ArchivedFullPath is the full path name for the archived folder
                $ArchivedFolderName = $ArchivedFolderPath.Substring(1) ## $ArchivedFolderName removes '/' from /archived string
                
                # Check if an "archived" folder already exists in each its### folder, if not, create one
                if (-not (Test-Path -Path $ArchivedFullPath)) {
                    Write-Debug "-------------"
                    Write-Debug "Creating new $ArchivedFolderName folder at location: $ArchivedFullPath"
                    New-Item -Path $itsFolderFullPath -Name $ArchivedFolderName -ItemType "directory" -Force | Out-Null 
                } 
                else {
                    Write-Debug "-------------"
                    Write-Debug "The $ArchivedFolderName folder already exists in $itsFolderFullPath"
                }

                # Save the list of files in its### folder so we can examine each one individually
                $itsChildFiles = Get-ChildItem -Path $itsFolderFullPath | Where-Object {$_.extension -match $SQLFileExtension} ## Get .sql files in its### folder
                # Format files in each $itsFolder that match $SQLFileExtenion 
                $OutputText = $itsChildFiles | Format-Table @{N="$SQLFileExtension files in $itsFolderName folder";E={$_.name}}, CreationTime, @{N='File Size';E={Get-FriendlySize -Bytes $_.Length}} -AutoSize 
                if ($MasterListValid) {
                    $OutputText | Out-File -append $MasterListFilePath ## Add each $SQLFileExtension file info to $MasterListFilePath
                }
                else {
                    Write-Output ($OutputText | Out-String) ## Print $dbDumpChildFiles files to console 
                }
                
                # Run through each file in its### folder
                foreach ($file in $itsChildFiles) {
                    # assemble the file path that will be our new .zip file
                    $zipFileDestinationPath = "$($ArchivedFullPath)\$($file.BaseName).zip" 
                    Write-Debug "-------------"
                    Write-Debug " Zipping file '$($file.Name)' to folder '$($ArchivedFullPath)'"
                    Write-Debug " Path to file to be zip: '$($file.FullName)'"
                    Write-Debug " Destination: $zipFileDestinationPath"
                    Compress-Archive -LiteralPath $file.FullName -DestinationPath $zipFileDestinationPath -Update ## Update parameter will overwrite changes to zipped files
                }
                # Format files in $ArchivedFullPath 
                $OutputText = Get-ChildItem -Path $ArchivedFullPath -File -Recurse | Select-Object @{N="Zipped files from $itsFolderName folder";E={$_.name}}, @{N='File Size';E={Get-FriendlySize -Bytes $_.Length}} | Format-Table -AutoSize
                if ($MasterListValid) {
                    $OutputText | Out-File -append $MasterListFilePath ## Add $ArchivedFullPath files to $MasterListFilePath
                }
                else {
                    Write-Output ($OutputText | Out-String) ## Print $ArchivedFullPath files to console 
                }
            }
        }
    }
    # open the master list text file if applicable
    if ($MasterListValid) {
        Write-Debug "-------------"
        Write-Debug "Opening the file: $($MasterListFilePath)..."
        Invoke-Item $MasterListFilePath  
    }
    #ReverseCreatedItems function used to deleted archived folders and master list text file for script testing purposes
    Write-Debug "-------------"
    Write-Debug "For testing purposes:"
    Write-Debug "Enter 1 to delete all newly created archived folders and the master list."
    Write-Debug "Enter any other value to end script."
    $ReverseCreatedItemsParam = Read-Host -Prompt 'Enter your value'
    function ReverseCreatedItems {
        Write-Debug "All $($ArchivedFolderName) folders removed."
        Get-ChildItem $Path -recurse | Where-Object {$_.extension -match ".zip"} | ForEach-Object { remove-item $_.FullName -force}
        Get-ChildItem $Path -recurse | Where-Object {$_.name -like $ArchivedFolderName} | ForEach-Object { remove-item $_.FullName -force}
        if ($MasterListValid) {
            Write-Debug "Removing file: $MasterListFilePath"
            Remove-Item -Path $MasterListFilePath -include *.txt
        }  
    }
    if ($ReverseCreatedItemsParam -eq 1) {
        ReverseCreatedItems
        return "The $($MyInvocation.MyCommand) script has terminated."
    } 
    else {
        Write-Debug "No folders or files were deleted"
        return "The $($MyInvocation.MyCommand) script has terminated."
    }
}
# Run Invoke-DBCompressScript. Specify path to compress and the folder name of files to be archived (comspressed)
#-Path ".\testStructures\Drupal 8 Dump"
Invoke-DBCompressScript  -SQLFileExtension ".sql"