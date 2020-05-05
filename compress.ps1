<# Alan Shindelman
PowerShell DB Dump Compression
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
1) Only zip files that have the .sql file-extension. 
2) Record more information about the files you zip.
    - The original file's size 	
    - The date-time the original file was created 	
    - The file size of the newly created .zip file
3) Output the above information (in the bullet points) to the log file in a sensible way that is readable by humans
4) Create variables to make changing these aspects of the script easier 
#>

<# Task 5: (Completed)
- change "hardcoded" file paths, folder names, and text into variables so it is easier to test.
- Give the parameters a default value.	
#>

<# Task 6:
This is a short task. But task 7 will be big.
1 of 2) Test what happens when the $FileExtension parameter does not include the "." for example Find-Path -FileExtension "sql".
Handle -FileExtension ".sql" and -FileExtension "sql" gracefully. In other words, the script should behave the same way with both of those.
2 of 2) Handle gracefully when the $MasterList parameter is an invalid or inaccessible location.
Currently the script throws an unexpected exception when it first tries to write to $MasterList (line 104 Out-File).
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
        [System.IO.FileInfo]$Path, 
        [String]$DBDumpFolderPath = "\dbdump", ## default value of dbdump folder
        [String]$SQLFileExtension = ".sql", ## default value of .sql file extenion
        [String]$ArchivedFolderPath = "\archived", ## default value of archived folder
        [String]$MasterListFolderPath = $Path.toString() + "\Masterlist-Output", ## Master list folder location
        [String]$MasterListFilePath = $MasterListFolderPath.toString() + "\DBCompressScript-Text-Output.txt"  ## Master list of outputted files from dbdump folder and zipped files
    )
    $DebugPreference = "Continue" ## "SilentlyContinue = no debug messages, "Continue" will display debug messages
    # dbdump folder variables
    $dbDumpFullPath = $Path.toString() + $DBDumpFolderPath ## $dbDumpFullPath is the full path name for the dbdump folder
    $dbDumpFolderName = $DBDumpFolderPath.Substring(1) ## $dbDumpFolderName removes '/' from /dbdump string

    # Find dbdump folder .sql files / add to master list / zip found files / add zipped files to master list
    if ( -Not (Get-ChildItem -Path $Path -Directory | Where-Object {$_.PSIsContainer -eq $true -and $_.Name -like $dbDumpFolderName} )) {
        throw 'There is no ' + $dbDumpFolderName + ' folder in the path: ' + $Path
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
        # Test the $MasterList path to determine script output behavior  
        # If $MasterList path is valid, use Out-File command 
        # If $MasterList path is not valid, use Write-Debug command 
        if (Test-Path -Path $MasterListFolderPath) {
            $MasterListValid = $true
        }
        else {
            $MasterListValid = $false
        }    
        
        $OutputText = Get-ChildItem -Path $dbDumpFullPath -File | Format-Table -HideTableHeaders FullName -AutoSize ## Get all original files in $dbDumpFullPath
        # $MasterListValid boolean value determines where $dbDumpFullPath files are outputted
        if ($MasterListValid -eq $true) {
            $OutputText | out-file $MasterListFilePath 
        }
        else {
            $OutputText
        }
        
        
        # handle .sql and sql inputs for $SQLFileExtension
        if (-Not ($SQLFileExtension | Where-Object {($_ -like ".sql") -or ($_ -like "sql")})) {
            Write-Debug ('The ' + $SQLFileExtension + ' file extension is not correct')
        }
        # archived folder variables
        $ArchivedFullPath = $dbDumpFullPath.toString() + $ArchivedFolderPath ## $ArchivedFullPath is the full path name for the archived folder
        $ArchivedFolderName = $ArchivedFolderPath.Substring(1) ## $ArchivedFolderName removes '/' from /archived string

        # Check if an "archived" folder already exists in the dbdump folder, if not, create one
        if (-not (Test-Path -Path $ArchivedFullPath)) {
            New-Item -Path $dbDumpFullPath -Name $ArchivedFolderName -ItemType "directory" -force ## Create archived folder 
        } 
        else {
            Write-Debug ('The ' + $ArchivedFolderName + ' folder already exists. Path: ' + $ArchivedFullPath)
        }
        
        # Save the list of files so we can examine each one individually
        $allChildFiles = Get-ChildItem -Path $dbDumpFullPath | Where-Object {$_.extension -match $SQLFileExtension} ## All .sql files in dbdump folder
        
        $OutputText = $allChildFiles | Format-Table @{N="$SQLFileExtension files in $DBDumpFolderPath folder";E={$_.name}}, CreationTime, @{N='File Size';E={Get-FriendlySize -Bytes $_.Length}} -AutoSize 
        if ($MasterListValid -eq $true) {
            $OutputText | Out-File -append $MasterListFilePath ## Add every original file's info to formatted table
        }
        else {
            $OutputText
        }
          
        
        # Run through each file
        foreach ($file in $allChildFiles) {
            # assemble the file path that will be our new .zip file
            $zipFileDestinationPath = "$($ArchivedFullPath)\$($file.BaseName).zip" 
            Write-Debug "-------------"
            Write-Debug " Zipping file '$($file.Name)' to folder '$($ArchivedFullPath)'"
            Write-Debug " Path to file to zip: '$($file.FullName)'"
            Write-Debug " Destination: $zipFileDestinationPath"
            Compress-Archive -LiteralPath $file.FullName -DestinationPath $zipFileDestinationPath -Update ## Update parameter will overwrite changes to zipped files
        }
        # 
        $OutputText = Get-ChildItem -Path $ArchivedFullPath -File -Recurse | Select-Object @{N="Zipped files from $DBDumpFolderPath folder";E={$_.name}}, @{N='File Size';E={Get-FriendlySize -Bytes $_.Length}} | Format-Table -AutoSize
        if ($MasterListValid -eq $true) {
            $OutputText | Out-File -append $MasterListFilePath ## Add zipped files to master list
        }
        else {
            $OutputText
        }
        if ($MasterListValid -eq $true) {
            Invoke-Item $MasterListFilePath  ## opens master list text file
        }
    } 
    Write-Host "For testing purposes:"
    Write-Host "Enter 1 to delete archived folder and master list."
    Write-Host "Enter any other value to end script."
    $ReverseCreatedItemsParam = Read-Host -Prompt 'Enter your value'
    # Delete archived folder and master list text file for script testing purposes
    function ReverseCreatedItems {
        Write-Debug "Removing folder: $ArchivedFullPath"
        Remove-Item -Path $ArchivedFullPath -recurse
        if ($MasterListValid -eq $true) {
            Write-Debug "Removing text file: $MasterListFilePath"
            Remove-Item -Path $MasterListFilePath -include *.txt
        }  
    }
    if ($ReverseCreatedItemsParam -eq 1) {
        ReverseCreatedItems
        return "The $($MyInvocation.MyCommand) script has terminated"
    } 
    else {
        Write-Debug "No folders or files were deleted"
        return "The $($MyInvocation.MyCommand) script has terminated"
    }
}
# Run Invoke-DBCompressScript. Specify path to compress and the folder name of files to be archived (comspressed)
Invoke-DBCompressScript -Path ".\testStructures" -DBDumpFolderPath "\preTask7Test" -SQLFileExtension ".sql"
