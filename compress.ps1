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
    - Fix errors when running script again (will improve testing)
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
        Get-ChildItem -Path $dbDumpPath -File | Format-Table -HideTableHeaders FullName | out-file $MasterList   ## add files in dbdump to master list
        $ArchivedFolder = New-Item -Path $dbDumpPath -Name "archived" -ItemType "directory" ## Creates new archived folder  
        # save the list of files so we can examine each one individually
        $allChildFiles = Get-ChildItem -Path $dbDumpPath | Where-Object {$_.extension -in ".sql"}
        
        # run through each file
        foreach ($file in $allChildFiles) {
            $size=Format-FileSize((Get-Item $file).length)
            If ($size -gt 1TB) {
                [string]::Format("{0:0.00} TB", $size / 1TB) | out-file -append $MasterList } 
            ElseIf ($size -gt 1GB) {
                [string]::Format("{0:0.00} GB", $size / 1GB) | out-file -append $MasterList }
            ElseIf ($size -gt 1MB) {
                [string]::Format("{0:0.00} MB", $size / 1MB)  | out-file -append $MasterList }
            ElseIf ($size -gt 1KB) {
                [string]::Format("{0:0.00} kB", $size / 1KB)  | out-file -append $MasterList }
            ElseIf ($size -eq 0KB) {
                [string]::Format("{0:0.00} B", $size) | out-file -append $MasterList }
            Else {""}
            # assemble the file path that will be our new .zip file
            $zipFileDestinationPath = "$($ArchivedFolder.FullName)\$($file.BaseName).zip" ## .FullName is the path \ .BasseName just appends the file name
            Write-Debug "-------------"
            Write-Debug "Zipping file '$($file.Name)' to folder '$($ArchivedFolder.FullName)'"
            Write-Debug " path to file to zip: '$($file.FullName)'"
            Write-Debug " destination: $zipFileDestinationPath"
            # (Original) File size calculator, date time file was created
            
                # $size = (Get-Item $file).length -ge 0kb 
                # $size=(Get-Item $file).length/1024  #Getting the File size in KB**
                #$size | out-file -append $MasterList #"$file is $size KB"  # display the name of the file and its size in KB**
             
            
            
            

            Compress-Archive -LiteralPath $file.FullName -DestinationPath $zipFileDestinationPath # -Force

            # File size of new zipped file
            
            # log this single file:
            $zipFileDestinationPath | out-file -append  $MasterList 
        }
    }   Invoke-Item "C:\Users\ajs573\Documents\DB-Dump-Compression-Repo\Outputs\dbdump_master_list.txt"  ## add new zip files to master list   
}
# Invoke Find-Path function with specified path location
Find-Path -path C:\users\ajs573\Documents

#Get-ChildItem -Path C:\users\ajs573\Documents\dbdump -file |  Select-Object CreationTime, Length

## Delete archived folder and master list text file
# function Delete-Tests {
#     Remove-Item -Path C:\users\ajs573\Documents\dbdump\archived -recurse
#     Remove-Item -Path C:\Users\ajs573\Documents\DB-Dump-Compression-Repo\Outputs\* -include *.txt
# }
# Delete-tests