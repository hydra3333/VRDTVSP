param ( [Parameter(Mandatory=$False)] [string]$Folder="G:\HDTV\000-TO-BE-PROCESSED", [Parameter(Mandatory=$False)] [switch]$Recurse = $False )  
[console]::BufferWidth = 512  
echo 'Set file date-time timestamps: *** Ignore the error: Exception setting "BufferWidth": "The handle is invalid."'  
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
echo "Set file date-time timestamps: Incoming Folder = '$Folder'"  
if ($Folder.Substring($Folder.Length-2,2) -eq '" ') {$Folder=$Folder -Replace "..$"} # removes the last 2 characters  
if ($Folder.Substring($Folder.Length-2,2) -eq ' "') {$Folder=$Folder -Replace "..$"} # removes the last 2 characters  
if ($Folder.Substring($Folder.Length-2,2) -eq " '") {$Folder=$Folder -Replace "..$"} # removes the last 2 characters  
if ($Folder.Substring($Folder.Length-1,1) -eq "\")  {$Folder=$Folder -Replace ".$"}  # removes the last 1 character  
if ($Folder.Substring(0,1) -eq "'" -And $Folder.Substring($Folder.Length-1,1) -eq "'") {$Folder=$Folder.Trim("'")} # removes the specified character from both ends of the string  
echo "Set file date-time timestamps: Fixed Folder = '$Folder'"  
if ($Recurse) {  
	echo "Set file date-time timestamps: RECURSE FOUND for tree '$Folder'"  
	# note we add -Recurse and leave "\*" off of the folder name  
	$FileList = Get-ChildItem -Path "$Folder" -Recurse -File -Include '*.ts','*.mp4','*.mpg','*.bprj','*.mp3','*.aac','*.mp2'  
} else {  
	# note we add "\*" to the folder name  
	echo "Set file date-time timestamps: NON RECURSE FOUND for only '$Folder'"  
	$FileList = Get-ChildItem -Path "$Folder\*" -File -Include '*.ts','*.mp4','*.mpg','*.bprj','*.mp3','*.aac','*.mp2'  
}  
echo "Set file date-time timestamps: START in folder tree '$Folder' ..."  
# 
# 1. capture a commandline parameter 1 as a mandatory "Folder string" with a default value 
$DateFormat = "yyyy-MM-dd" 
# 2. Iterate the files 
foreach ($FL_Item in $FileList) { 
	$fn = $FL_Item.FullName 
	#echo "Processing Timestamp for 'fn'" 
	$ixxx = $FL_Item.BaseName -match '(?<DateString>\d{4}-\d{2}-\d{2})' 
	if($ixxx){ 
		$DateString = $Matches.DateString 
		$date_from_file = [datetime]::ParseExact($DateString, $DateFormat, $Null) 
	} else { 
		$date_from_file = $FL_Item.CreationTime.Date # .Date removes the time component 
	} 
	$FL_Item.CreationTime = $date_from_file 
	$FL_Item.LastWriteTime = $date_from_file 
	$df=$date_from_file.ToString() # .ToString() formats the date/time 
	$cd=$FL_Item.CreationTime.ToString() # .ToString() formats the date/time 
	$lw=$FL_Item.LastWriteTime.ToString() # .ToString() formats the date/time 
	echo "Set '$df' into Creation-date: '$cd' Modification-Date: '$lw' on '$fn'" 
} 
echo "Set file date-time timestamps: FINISH in folder tree '$Folder' ..."  
# https://stackoverflow.com/questions/56211626/powershell-change-file-date-created-and-date-modified-based-on-filename 
