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
#>

<# Task 3.5:
    - Fix errors when running script again (will improve testing) (added Delete-Tests function)
    - Add full path names to the appended master list, second iteration changes file path output in $Masterlist
#>

<# Task 4:
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
    # Variables
    $dbDumpPath = $Path.toString() + "\dbdump" ## dbDumpPath is = to C:\users\ajs573\Documents\dbdump
    $MasterList = "C:\Users\ajs573\Documents\DB-Dump-Compression-Repo\Outputs\dbdump_master_list.txt" ## Master list of outputted files from dbdump folder and zipped files
    
    # Find dbdump folder files / add to master list / zip found files / add zipped files to master list
    if ( -Not (Get-ChildItem -Path $Path -Directory | Where-Object {$_.PSIsContainer -eq $true -and $_.Name -Like "dbdump"} )) {
        throw "There is no dbdump folder in the path $Path"
    }
    else { 
        ## Function to get human-readable file size format for $MasterList output
        function Get-FriendlySize {
            param($Bytes)
            $sizes='Bytes,KB,MB,GB,TB,PB,EB,ZB' -split ','
            for($i=0; ($Bytes -ge 1kb) -and ($i -lt $sizes.Count); $i++) {
                    $Bytes/=1kb
            } $N=2;
            if($i -eq 0) { 
              $N=0 
            } "{0:N$($N)} {1}" -f $Bytes, $sizes[$i]
        }        
        Get-ChildItem -Path $dbDumpPath -File | Format-Table -HideTableHeaders FullName -AutoSize | out-file $MasterList   ## Add all files in dbdump folder to master list

        ## Create archived folder if one does not exist
        $Location = $dbDumpPath.toString() + "\archived"
        if ((Test-Path $Location) -eq $False) {
            $ArchivedFolder = New-Item -Path $dbDumpPath -Name "archived" -ItemType "directory"
            # Save the list of files so we can examine each one individually
            $allChildFiles = Get-ChildItem -Path $dbDumpPath | Where-Object {$_.extension -in ".sql"} ## All .sql files in dbdump folder

            $allChildFiles | Format-Table @{N=".sql files in dbdump folder";E={$_.name}}, CreationTime, @{N='File Size';E={Get-FriendlySize -Bytes $_.Length}} -AutoSize |
            Out-File -append $MasterList ## Add original file information to formatted table  
            
            # Run through each file
            foreach ($file in $allChildFiles) {
                # assemble the file path that will be our new .zip file
                $zipFileDestinationPath = "$($ArchivedFolder.FullName)\$($file.BaseName).zip" ## .FullName is the path \ .BasseName just appends the file name
                Write-Debug "-------------"
                Write-Debug "Zipping file '$($file.Name)' to folder '$($ArchivedFolder.FullName)'"
                Write-Debug " path to file to zip: '$($file.FullName)'"
                Write-Debug " destination: $zipFileDestinationPath"
                Compress-Archive -LiteralPath $file.FullName -DestinationPath $zipFileDestinationPath # -Force
            }
            Get-ChildItem -Path $ArchivedFolder -File -Recurse | Select-Object @{Name="Zipped files from dbdump folder";E={$_.name}}, @{N='File Size';E={Get-FriendlySize -Bytes $_.Length}} |
            Format-Table -AutoSize | Out-File -append $MasterList 

            Invoke-Item $MasterList  ## opens master list text file
        } 
        else { # WIP
             return $true
        } 
    }  
}
# Invoke Find-Path function with specified path location
Find-Path -path C:\users\ajs573\Documents

## Delete archived folder and master list text file (for testing purposes)
# function Delete-Tests {
#     Remove-Item -Path C:\users\ajs573\Documents\dbdump\archived -recurse
#     Remove-Item -Path C:\Users\ajs573\Documents\DB-Dump-Compression-Repo\Outputs\* -include *.txt
# }
# Delete-Tests