<# Alan Shindelman
PowerShell DB Dump Compression
#>

<# Task 1 (completed): 
- Take a folder-path as an argument/parameter. For example "C:\users\alan\document" 	
    - Verify the folder exists. If it does not, output an error message that explains it, and stop the script. 
- Get a list of all the child/sub-folders ther
- Output that list of folder-names to the console (Fullname property with no column header)
#>	

<# Task 2 (completed): 
- Given the path of a folder, the script will look for a child/sub-folder named "dbdump" there. 	
    - If there is no "dbdump" sub-folder, then do nothing. 		
    - Inside the "dbdump" folder, the script will find all the files under the dbdump folder	
        - Disregard any subfolders and their child files inside the dbdump folder
        - Add full-path of the dbdump child files to a master-list that the script is keeping track of. 	
- At the end of the script, output the file-paths of every file to a saved master-list.
#>

<# Task 3 (completed):
- Extend the script you wrote for task 2 by using PowerShell to compress every file your script found into the .zip file format.
- Have the .zip files placed into a new folder called "archived"
- In addition to writing the list of files to that master-list.txt, the script will have generated .zip files for each file it found and add them to the master list
#>

<# Task 3.5 (completed):
    - Fix errors when running script again (added Delete-Tests function)
    - Add full path names to the appended master list, second iteration changes file path output in $Masterlist
#>

<# Task 4 (completed):
1) Only zip files that have the .sql file-extension. (Done)
2) Record more information about the files you zip.
    - The original file's size 	
    - The date-time the original file was created 	
    - The file size of the newly created .zip file
3) Output the above information (in the bullet points) to the log file in a sensible way that is readable by humans, format a table!
4) Create variables to make changing these aspects of the script easier (you have already done some of these):
    - full path location of the log file (master list as you named it) 	(done)
    - the name of the "dbdump" folder 	 (done)	
    - the name of the "archived" folder  (done)
    - only .zip files with this file-extension
#>

<# Task 5:  
- change "hardcoded" file paths, folder names, and text into variables so it is easier to test.
- Give the parameters a default value.
	- The file extension of files to zip. Currently hardcoded as .sql Appears in lines 87 and 89 "Master list" location. 	
- The "dbDump" folder name. Appears in lines 60, 65, 66, 89, 102. A lot of those are logging/text. 	 	
- The "archived" folder name 	
#>

function Find-Path {
    param (
        [Validatescript({
            # Test if the user specified $path exists
            if( -Not ($_ | Test-Path)){
                throw "The path $_ does not exist"  
            }
            return $true
            })]
        # Parameters
        [System.IO.FileInfo]$Path,
        [String]$DBDumpFolderPath = "\dbdump",
        [String]$FileExtension = ".sql",
        [String]$ArchiveFolderPath,
        [String]$MasterList = "C:\Users\ajs573\Documents\DB-Dump-Compression-Repo\Outputs\dbdump_master_list.txt" ## Master list of outputted files from dbdump folder and zipped files
    )
    $DebugPreference = "Continue" ## "SilentlyContinue = no debug messages, "Continue" will display debug messages
    $dbDumpPath = $Path.toString() + $DBDumpFolderPath

    # Find dbdump folder files / add to master list / zip found files / add zipped files to master list
    if ( -Not (Get-ChildItem -Path $Path -Directory | Where-Object {$_.PSIsContainer -eq $true -and $_.Name -Like "dbdump"} )) {
        throw "There is no dbdump folder in the path $Path"
    }
    else { 
        #  Get-FriendlySize function to get human-readable file size format for $MasterList output
        function Get-FriendlySize {
            param($Bytes)
            $sizes='Bytes,KB,MB,GB,TB,PB,EB,ZB' -split ','
            for($i=0; ($Bytes -ge 1kb) -and ($i -lt $sizes.Count); $i++) {
                    $Bytes/=1kb
            } $N=2; 
            ## Add debug message??
            if($i -eq 0) { 
              $N=0 
            } "{0:N$($N)} {1}" -f $Bytes, $sizes[$i] 
        }        
        Get-ChildItem -Path $dbDumpPath -File | Format-Table -HideTableHeaders FullName -AutoSize | out-file $MasterList   ## Add all files in dbdump folder to master list
        $ArchivedFolder = $dbDumpPath.toString() + $ArchiveFolderPath

        # Check if an "archived" folder already exists in the dbdump folder, if not, create one
        if (-not (Test-Path -Path $ArchivedFolder)) {
            New-Item -Path $dbDumpPath -Name "archived" -ItemType "directory" -force ## Create archived folder
        } 
        else {
            Write-Debug "Archive folder already exists. Path: ($($ArchivedFolder))"
        }
        # Save the list of files so we can examine each one individually
        $allChildFiles = Get-ChildItem -Path $dbDumpPath | Where-Object {$_.extension -in $FileExtension} ## All .sql files in dbdump folder
        
        $allChildFiles | Format-Table @{N="$FileExtension files in dbdump folder";E={$_.name}}, CreationTime, @{N='File Size';E={Get-FriendlySize -Bytes $_.Length}} -AutoSize |
        Out-File -append $MasterList ## Add every original file info to formatted table  
        
        # Run through each file
        foreach ($file in $allChildFiles) {
            # assemble the file path that will be our new .zip file
            $zipFileDestinationPath = "$($ArchivedFolder)\$($file.BaseName).zip" 
            Write-Debug "-------------"
            Write-Debug "Zipping file '$($file.Name)' to folder '$($ArchivedFolder)'"
            Write-Debug " path to file to zip: '$($file.FullName)'"
            Write-Debug " destination: $zipFileDestinationPath"
            Compress-Archive -LiteralPath $file.FullName -DestinationPath $zipFileDestinationPath -Update ## Update parameter will overwrite changes to zipped files
        }
        Get-ChildItem -Path $ArchivedFolder -File -Recurse | Select-Object @{N="Zipped files from dbdump folder";E={$_.name}}, @{N='File Size';E={Get-FriendlySize -Bytes $_.Length}} |
        Format-Table -AutoSize | Out-File -append $MasterList  ## Add zipped files to master list
        Invoke-Item $MasterList  ## opens master list text file
    } 
    Write-Host "For testing purposes:"
    Write-Host "Enter 1 to delete archived folder and master list."
    Write-Host "Enter any other value to end script."
    $ReverseCreatedItemsParam = Read-Host -Prompt 'Enter your value'
    # Delete archived folder and master list text file for script testing purposes
    function ReverseCreatedItems {
        Remove-Item -Path $ArchivedFolder -recurse
        Remove-Item -Path $MasterList -include *.txt
    }
    if ($ReverseCreatedItemsParam -eq 1) {
        Write-Debug "Removing items in $ArchivedFolder"
        Write-Debug "Removing text file: $MasterList"
        ReverseCreatedItems
    } 
    else {
        return "The Find-Path script has terminated"
    }
}
# Invoke Find-Path function. Specify path to compress and folder name of files to be compressed
Find-Path -Path C:\users\ajs573\Documents -ArchiveFolderPath "\archived"
