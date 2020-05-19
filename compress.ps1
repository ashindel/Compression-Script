<# Alan Shindelman
PowerShell DB Dump Compression Script
Started: April 13th, 2020
More task information can be found at: https://docs.google.com/document/d/1cllxJOYWe3tGzf92XFtGpHVJ1NPz4CEbb_xrRGby8QI/edit?usp=sharing 
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
- In addition to writing the list of files to that master-list.txt, the script will have generated .zip files for each file it found and add them to the Master List
#>

<# Task 3.5: (Completed)
    - Fix errors when running script again 
    - Add full path names to the appended Master List, second iteration changes file path output in $Masterlist
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

<# Task 7: (Completed)
- Expand how the script traverses through file directories to closer mimic Jenkins directory structure 
#>

<# Task 8:
- Script should archive every file except the most-recently-modified file. 
    - Determine which files to archive based on the "Date Modified" field of file. 
- Add another parameter and functionality to the function: [int]$ArchiveDateLimitInDays 
- Delete all matching sql files after .zip/copy was created
- Challenge: Add Y/N column to pre-zipped output that shows which files were and were not zipped (user friendly task)
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
        [System.IO.FileInfo]$Path = ".\testStructures\Drupal 8 Dumps", ## $path is the most parent folder of file structure
        [String]$DBDumpFolderName = "\dbdump", ## default value of dbdump folder within a specific repo
        [String]$SQLFileExtension = ".sql", ## default value of .sql file extenion
        [String]$ArchivedFolderPath = "\archived", ## default value of archived folders to be created
        [String]$MasterListFolderPath = ".", ## default value of Master List folder location
        [String]$MasterListFilePath = $MasterListFolderPath.toString() + "\DBCompressScript-Text-Output.txt",  ## Master List text file location
        [int]$ArchiveDateLimitInDays = 1 ## default value for the # of day(s) a $file's "date modified" value will be tested against to determine if compression occurs 
    )
    $DebugPreference = "Continue" ## "SilentlyContinue = no debug messages, "Continue" will display debug messages
    $dbDumpString = $DBDumpFolderName.Substring(1) ## $dbDumpFolderName removes '/' from /dbdump string
    $ArchiveDateLimitInDaysNeg = ($ArchiveDateLimitInDays * 24 * 60 * 60 * 1000 * -1) ## convert to ArchiveDateLimitInDays value to negative milliseconds to use in $fileDateCompare test

    # Test the $MasterListFolderPath  to determine script output behavior  
    # If $MasterListFolderPath  is valid, use Out-File command 
    # If $MasterListFolderPath  is not valid, output Format-Table into console
    if (Test-Path -Path $MasterListFolderPath) {
        Write-Debug "The Master List folder path: $($Path.FullName)\ is valid."
        Write-Debug "Script output will be sent to $($MasterListFilePath)"
        $MasterListValid = $true
    }
    else {
        Write-Debug "The Master List folder path: $($MasterListFolderPath) is not valid."
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

    # get the d8c folders in $path
    $PathChildFolders = Get-ChildItem -Path $Path -Directory | Where-Object {$_.Name -match "d8c"}
    foreach ($d8cRepoFolder in $PathChildFolders) { ## get the dbdump folder in each d8c repo folder 
        # check if dbdump folder exists in each repo
        if ( -Not (Get-ChildItem -Path $d8cRepoFolder.FullName -Directory | Where-Object {$_.Name -like $dbDumpString} )) {
            throw 'There is no ' + $dbDumpString + ' folder in the path: ' + $d8cRepoFolder.FullName
        }
        else { 
            $d8cChildFolders = Get-ChildItem -Path $d8cRepoFolder.FullName -Directory | Where-Object {$_.Name -like $dbDumpString} ## get 
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
                # Handle .sql and sql inputs for $SQLFileExtension, script continues execution regardless of input
                if (-Not ($SQLFileExtension | Where-Object {($_ -like ".sql") -or ($_ -like "sql")})) {
                    Write-Debug ('The ' + $SQLFileExtension + ' file extension is not correct.')
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
                $itsChildFiles = Get-ChildItem -Path $itsFolderFullPath | Where-Object {$_.extension -match $SQLFileExtension} | Sort-Object -Property LastWriteTime ## Get .sql files in its### folder and sort by most recently modified at bottom of list
                # Format files in each $itsFolder that match $SQLFileExtenion 
                $OutputText = $itsChildFiles | Format-Table @{N="$SQLFileExtension files in $($d8cRepoFolder.Name)/$($DBDumpString)/$($itsFolderName) folder";E={$_.name}}, LastWriteTime, @{N='File Size';E={Get-FriendlySize -Bytes $_.Length}} -AutoSize 
                if ($MasterListValid) {
                    $OutputText | Out-File -append $MasterListFilePath ## Add each $SQLFileExtension file info to $MasterListFilePath
                }
                else {
                    Write-Output ($OutputText | Out-String) ## Print $dbDumpChildFiles files to console 
                }
                # adding yes or no column would require appending a column after the following logic to the original table ...is this possible?

                # Run through each file in its### folder
                foreach ($file in $itsChildFiles) {
                    # need to add test to find most recent number and not compress that as failsafe
                    # if ($file -match "\d+") {
                    #     $matches.value
                    # }
                    # $largestFileNum = 0
                    # foreach ($number in $TheFile)
                    # {
                    #     if ([Double]$matches -gt $largestFileNum)
                    #     {
                    #         $largestFileNum = $number
                    #     }
                    # }
                    # foreach file in its folder {
                    #     if the files number found in its name is greater than the next file then
                    #     add it to a variable tracking that number variable
                    #     then once looping through all the files in a folder, do not compress the file that had the greatest value (as found in other variable?)
                    # }

                    # $LastFileinList equals most recently modified file in each its### folder
                    $LastFileinList = $itsChildFiles[-1]
                    # Last $file in each its### folder for-loop iteration is not compressed because it is the most recently modified file
                    if ($file -eq $LastFileinList) {
                        Write-Debug "-------------"
                        Write-Debug "The $($file) file from $($d8cRepoFolder.Name)/$($DBDumpString)/$($itsFolderName) folder is the most recently modified file."
                        Write-Debug "$($file) will not be compressed."
                        break
                    }
                    
                    # $MostRecentFile is the most recently modified file's "date modified" property
                    $CurrentTime = Get-Date #-Format HH:mm:ss.fff
                    # $fileDateCompare is set to # day(s) less than most recently modified file's "date modified" property value
                    $fileDateCompare = (Get-Date $CurrentTime).AddMilliseconds($ArchiveDateLimitInDaysNeg)
                    $fileTest = (Get-Item -Path $File.FullName).LastWriteTime                  
                    
                    # If $file "date modified" property is less than one day old from the most recently modified file ($LastFileinList), then do not compress
                    if ($fileTest -gt $fileDateCompare) {
                        Write-Debug "-------------"
                        Write-Debug "The $($file) file from $($d8cRepoFolder.Name)/$($DBDumpString)/$($itsFolderName) folder is less than 1 day old as of running this script"
                        Write-Debug "$($file) will not be compressed."
                        break
                    }
                    
                    # assemble the file path that will be our new .zip file
                    $zipFileDestinationPath = "$($ArchivedFullPath)\$($file.BaseName).zip" 
                    Write-Debug "-------------"
                    Write-Debug " Zipping file '$($file.Name)' to folder '$($ArchivedFullPath)'"
                    Write-Debug " Path to file to be zip: '$($file.FullName)'"
                    Write-Debug " Destination: $zipFileDestinationPath"
                    Compress-Archive -LiteralPath $file.FullName -DestinationPath $zipFileDestinationPath -Update ## Update parameter will overwrite changes to zipped files
                    
                    # Index or loop over original format table? (see bookmarks)
                    # Need to move the append outfile to the beginning of the for loop before other logic kicks in, maybe?
                    # if (Test-Path $zipFileDestinationPath) {
                    #     Write-Debug "-------------"
                    #     Write-Debug "TEST - YES"
                    #     $Yes = "Y"
                    #     $file | Format-Table @{N="To be Zipped? (Y/N)?";E={$Yes}} -AutoSize | Out-File -Update $MasterListFilePath
                    # }
                    # else {
                    #     $No = "N"
                    #     Write-Debug "-------------"
                    #     Write-Debug "TEST - YES"
                    #     Format-Table @{N="Y/N file zipped?";E={$No}} -AutoSize -append
                    # }


                    # Remove original $file if archived-file exists
                    $fileFullPath = $file.Fullname
                    If (Test-Path $zipFileDestinationPath) {
                        Write-Debug "-------------"
                        Write-Debug "Removing $($d8cRepoFolder.Name)/$($DBDumpString)/$($itsFolderName)/$($file)"
                        Remove-Item $fileFullPath             
                    }
                    else {
                        Write-Debug "-------------"
                        Write-Debug "Could not find $($zipFileDestinationPath)"
                        Write-Debug "$($file) could not be removed."
                    }
                }
                # Format files in $ArchivedFullPath 
                $OutputText = Get-ChildItem -Path $ArchivedFullPath -File -Recurse | Select-Object @{N="Zipped files from $($d8cRepoFolder.Name)/$($DBDumpString)/$($itsFolderName) folder";E={$_.name}}, @{N='File Size';E={Get-FriendlySize -Bytes $_.Length}} | Format-Table -AutoSize
                if ($MasterListValid) {
                    $OutputText | Out-File -append $MasterListFilePath ## Add $ArchivedFullPath files to $MasterListFilePath
                }
                else {
                    Write-Output ($OutputText | Out-String) ## Print $ArchivedFullPath files to console 
                }
            }
        }
    }
    # open the Master List text file if applicable
    if ($MasterListValid) {
        Write-Debug "-------------"
        Write-Debug "Opening the file: $($MasterListFilePath)..."
        Invoke-Item $MasterListFilePath  
    }
    #ReverseCreatedItems function used to delete archived folders and Master List text file for script testing purposes
    Write-Debug "-------------"
    Write-Debug "For testing purposes:"
    Write-Debug "Enter 1 to delete all newly created archived folders and the Master List."
    Write-Debug "Enter any other value to end script."
    $ReverseCreatedItemsParam = Read-Host -Prompt 'Enter value'
    function ReverseCreatedItems {
        Write-Debug "All $($ArchivedFolderName) folders removed."
        Get-ChildItem $Path -recurse | Where-Object {$_.extension -match ".zip"} | ForEach-Object { remove-item $_.FullName -force}
        Get-ChildItem $Path -recurse | Where-Object {$_.name -like $ArchivedFolderName} | ForEach-Object { remove-item $_.FullName -force}
        # If the Master List path is valid, remove the file 
        if ($MasterListValid) {
            Write-Debug "Removing file: $MasterListFilePath"
            Remove-Item -Path $MasterListFilePath -include *.txt
        }  
        # If the Master List path is not valid, prompt user to remove any instance of a Master List
        else {
            Write-Debug "No Master List was created... "
            Write-Debug "Do you want to remove any instance of a Master List?"
            $MasterListDelete = Read-Host -Prompt 'Enter 1 for Yes. Any other value to cancel'
            if ($MasterListDelete -eq 1) {
                $MostParentPath = (Get-Item $Path).parent.parent.FullName
                Write-Debug "Deleting Master List at location: $($MostParentPath)"
                Get-ChildItem $MostParentPath | Where-Object {$_.name -match "text-output"} | ForEach-Object { remove-item $_.FullName -force}
            }
            else {
                Write-Debug "No Master List was deleted."
            }
        }
    }
    # Execute ReverseCreatedItems function is user value equals "1"
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
Invoke-DBCompressScript -Path ".\testStructures\Drupal 8 Dumps"  -SQLFileExtension ".sql"