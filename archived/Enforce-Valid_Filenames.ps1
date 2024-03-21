param ( [Parameter(Mandatory=$False)] [string]$Folder="G:\HDTV\000-TO-BE-PROCESSED", [Parameter(Mandatory=$False)] [switch]$Recurse = $False )  
[console]::BufferWidth = 512  
echo 'Rename files to remove special characters: *** Ignore the error: Exception setting "BufferWidth": "The handle is invalid."'  
# 
# Powershell script to rename files to remove all special characters. 
# BEFORE this powershell script is invoked by the calling batch file, ensure the incoming folder has no trailing "\" 
# OTHERWISE the trailing double-quote " becomes 'escaped', thus everything on the commandline after it gets included in that parameter value. 
# eg  
# 
#set the_folder=G:\HDTV\000-TO-BE-PROCESSED 
#set "rightmost_character=!the_folder:~-1!" 
#if /I "!rightmost_character!" == "\" (set "the_folder=!the_folder:~,-1!") 
#powershell -NoLogo -ExecutionPolicy Unrestricted -Sta -NonInteractive -WindowStyle Minimized -File "G:\HDTV\000-TO-BE-PROCESSED\something.ps1" -Recurse -Folder ""  
#  
# The following is necessary if an incoming foldername string STILL has a trailing \ and DOS quoting does not work  
echo "Rename files to remove special characters: Incoming Folder = '$Folder'"  
if ($Folder.Substring($Folder.Length-2,2) -eq '" ') {$Folder=$Folder -Replace "..$"} # removes the last 2 characters  
if ($Folder.Substring($Folder.Length-2,2) -eq ' "') {$Folder=$Folder -Replace "..$"} # removes the last 2 characters  
if ($Folder.Substring($Folder.Length-2,2) -eq " '") {$Folder=$Folder -Replace "..$"} # removes the last 2 characters  
if ($Folder.Substring($Folder.Length-1,1) -eq "\")  {$Folder=$Folder -Replace ".$"}  # removes the last 1 character  
if ($Folder.Substring(0,1) -eq "'" -And $Folder.Substring($Folder.Length-1,1) -eq "'") {$Folder=$Folder.Trim("'")} # removes the specified character from both ends of the string  
echo "Rename files to remove special characters: Fixed Folder = '$Folder'"  
if ($Recurse) {  
	echo "Rename files to remove special characters: RECURSE FOUND for tree '$Folder'"  
	# note we add -Recurse and leave "\*" off of the folder name  
	$FileList = Get-ChildItem -Path "$Folder" -Recurse -File -Include '*.ts','*.mp4','*.mpg','*.bprj','*.mp3','*.aac','*.mp2'  
} else {  
	# note we add "\*" to the folder name  
	echo "Rename files to remove special characters: NON RECURSE FOUND for only '$Folder'"  
	$FileList = Get-ChildItem -Path "$Folder\*" -File -Include '*.ts','*.mp4','*.mpg','*.bprj','*.mp3','*.aac','*.mp2'  
}  
echo "Rename files to remove special characters: START in folder tree '$Folder' to remove special characters in every .ts .mp4 .mpg .bprj .mp3 filename by Matching them with a regex match in Powershell ..."  
foreach ($FL_Item in $FileList) {  
	#$FL_Item.FullName  
	#$FL_Item | Select-Object Name,CreationTime,LastWriteTime  
	$old_full_filename=$FL_Item.FullName  
	$old_filename=$FL_Item.Name  
	# regex replace all successive matches by a single . since there is a trailing + in the regex.  means NOT the following.  
	$new_filename=$FL_Item.Name -replace '[^a-zA-Z0-9-_. ]+','.'  
	if($old_filename -ne $new_filename){  
		echo "Renaming: '$old_full_filename' to '$new_filename'"  
		$FL_Item | Rename-Item -NewName {$new_filename}  
	} else {  
		echo "Left alone: '$old_full_filename'"  
	}  
}  
echo "Rename files to remove special characters: FINISH  in folder tree '$Folder' to remove special characters in every .ts .mp4 .mpg .bprj .mp3 filename by Matching them with a regex match in Powershell ..."  
## regex [^a-zA-Z0-9-_. ]+  
## the leading hat ^ character means NOT in any of the set, trailing + means any number of matches in the set  
## a-z 
## A-Z 
## 0-9 
## - underscore . space 
