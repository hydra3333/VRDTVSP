Option explicit
'
' VRDTVS - automatically parse, convert video/audio from TVSchedulerPro TV recordings, 
' and perhaps adscan them too. This looks only at .TS .MP4 .MPG files and autofixes associated .BPRJ files.
'
' Copyright hydra3333@gmail.com 2021
'
' Invoke from a DOS commandline or a .bat, Interactively or in a Scheduled Task 
' using a single one-line commndline.
' All options are, well, optional and are based on a default source_Folder
'
'cscript //nologo "E:\GIT-REPOSITORIES\VRDTVSP\VRDTVS_001.vbs" ^
'/DEBUG:True ^
'/DEV:True ^
'/capture_Folder:"G:\HDTV\000-TO-BE-PROCESSED\zzz-TEST\0save\" ^
'/source_Folder:"G:\HDTV\000-TO-BE-PROCESSED\zzz-TEST\VRDTVS-Source\" ^
'/done_Folder:"G:\HDTV\000-TO-BE-PROCESSED\zzz-TEST\VRDTVS-Done\" ^
'/destination_Folder:"G:\HDTV\000-TO-BE-PROCESSED\zzz-TEST\VRDTVS-Converted\" ^
'/failed_Folder:"G:\HDTV\000-TO-BE-PROCESSED\zzz-TEST\VRDTVS-Failed-Conversion\" ^
'/temp_path:"D:\VRDTVS-SCRATCH\" ^
'/vrd_version_for_qsf:6 ^
'/vrd_version_for_adscan:6
'
' ... use /capture_Folder:"" to prevent the moving of files from a capture folder, eg when testing
' ... note
'		that carat (^) is the normal DOS commandline-continuation flag ... do NOT purt a trailing space after one
'		there are a range of dependencies for locations of .exe files and whatnot, 
'			including Vapoursynth and DG-tools and ffmpeg and ffprobe and mediainfo
'
'----------------------------------------------------------------------------------------------------------------------------------------
' 1. Check and Exit if this .vbs isn't run under CSCRIPT (not WSCRIPT which is the default)
'    NOTE:  For ANY of this to work, the vb script MUST be run under Cscript host - or, things like stdout fail to work.
WScript.StdOut.WriteLine "------------------------------------------------------------------------------------------------------"
Dim  cscript_wshShell, cscript_strEngine
'
Set cscript_wshShell = CreateObject( "WScript.Shell" )
cscript_strEngine = UCase( Right( WScript.FullName, 12 ) )
Set cscript_wshShell = Nothing
WScript.Echo "Checked and CSCRIPT Engine = """ & cscript_strEngine & """" ' .Echo works in both wscript and cscript
If UCase(cscript_strEngine) <> UCase("\CSCRIPT.EXE") Then
    ' exit immediately with error code 17 cannot perform the requested operation
    ' since it was not run like:
    '      cscript //NOLOGO "vbscript_path_and_file" "parameter 1" "parameter 2"
    '      cscript //NOLOGO "test.vbs" /p1:"This is the value for p1" /p2:500
    ' Err.Raise 17 ' Error 17 = cannot perform the requested operation
    WScript.Echo "CSCRIPT Engine MUST be CSCRIPT not WSCRIPT ... Aborting ..."
	WScript.Quit 17 ' Error 17 = cannot perform the requested operation
End If
WScript.StdOut.WriteLine "VRDTVS cscript Engine: """ & cscript_strEngine & """"
WScript.StdOut.WriteLine "VRDTVS    Script name: " & Wscript.ScriptName
WScript.StdOut.WriteLine "VRDTVS    Script path: " & Wscript.ScriptFullName
WScript.StdOut.WriteLine "------------------------------------------------------------------------------------------------------"
'
'----------------------------------------------------------------------------------------------------------------------------------------
' Setup Global constants which we don't group below
'
Const theLeadingReplaceCharacter_ForMovingDates = "."

' Setup Global variables
'
Dim vrdtvs_run_datetime, vrdtvs_ScriptName
Dim vrdtvs_timer_StartTime_overall, vrdtvs_timer_EndTime_overall
vrdtvs_run_datetime = vrdtvs_current_datetime_string() ' start of runtime, for common use
vrdtvs_ScriptName = Wscript.ScriptName
WScript.StdOut.WriteLine(vrdtvs_ScriptName & " Started: " & vrdtvs_current_datetime_string() & " ")
vrdtvs_timer_StartTime_overall = Timer
vrdtvs_timer_EndTime_overall = Timer
'
' (these two are Global but are also Global Defaults declared early here)
Dim vrdtvs_DEBUG, vrdtvs_DEVELOPMENT_NO_ACTIONS
vrdtvs_DEBUG = True
vrdtvs_DEVELOPMENT_NO_ACTIONS = True
'
' Create a bunch of scratch variables
'
Dim vrdtvs_tmp, vrdtvs_status, vrdtvs_exit_code, vrdrvs_Err_Code, vrdrvs_Err_Description, vrdtvs_cmd, vrdtvs_exe_obj ' a few working variables, for common use
Dim vrdtvs_temp_powershell_filename, vrdtvs_temp_powershell_cmd, vrdtvs_temp_powershell_exe
Dim vrdtvs_saved_ffmpeg_commands_filename, vrdtvs_saved_ffmpeg_commands_object
Dim scratch_local_timerStart, scratch_local_timerEnd
Set vrdtvs_temp_powershell_exe = Nothing
Set vrdtvs_saved_ffmpeg_commands_object = Nothing
'
'----------------------------------------------------------------------------------------------------------------------------------------
' Setup Global Objects (remember to Set the_object=Nothing later)
' For Microsft Objects, see https://docs.microsoft.com/en-us/office/vba/language/reference/user-interface-help/filesystemobject-object
'
Dim fso, wso, objFolder
Set wso = CreateObject("Wscript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")
Set objFolder = Nothing
'
'----------------------------------------------------------------------------------------------------------------------------------------
' Setup Global exe file paths, resolving them to Absolute paths
'
Dim vs_root
Dim vrdtvs_mp4boxexex64
Dim vrdtvs_mediainfoexe64
Dim vrdtvs_ffprobeexe64
Dim vrdtvs_ffmpegexe64
Dim vrdtvs_dgindexNVexe64
Dim vrdtvs_Insomniaexe64
vs_root = fso.GetAbsolutePathName("C:\SOFTWARE\Vapoursynth-x64\")
vrdtvs_mp4boxexex64 = fso.GetAbsolutePathName(fso.BuildPath("C:\SOFTWARE\ffmpeg\0-homebuilt-x64\","MP4Box.exe"))
vrdtvs_mediainfoexe64 = fso.GetAbsolutePathName(fso.BuildPath("C:\SOFTWARE\MediaInfo\","MediaInfo.exe"))
vrdtvs_ffprobeexe64 = fso.GetAbsolutePathName(fso.BuildPath(vs_root,"ffprobe.exe"))
vrdtvs_ffmpegexe64 = fso.GetAbsolutePathName(fso.BuildPath(vs_root,"ffmpeg.exe"))
vrdtvs_dgindexNVexe64 = fso.GetAbsolutePathName(fso.BuildPath(vs_root,"DGIndex\DGIndexNV.exe"))
vrdtvs_Insomniaexe64 = fso.GetAbsolutePathName("C:\SOFTWARE\Insomnia\64-bit\Insomnia.exe")
'
'----------------------------------------------------------------------------------------------------------------------------------------
' Setup Global VideoReDo QSF and Adscan file paths and stuff
'
Dim vrd_version_for_qsf
Dim vrd_version_for_adscan
Dim vrd_path_for_qsf_vbs
Dim vrd_path_for_adscan_vbs
Dim vrd_profile_name_for_qsf_mpeg2
Dim vrd_profile_name_for_qsf_avc
Dim vrd_extension_mpeg2
Dim vrd_extension_avc
'
Const const_vrd5_path = "C:\Program Files (x86)\VideoReDoTVSuite5"
Const const_vrd5_profile_mpeg2 = "zzz-MPEG2ps"
Const const_vrd5_profile_avc = "zzz-H.264-MP4-general"
Const const_vrd5_extension_mpeg2 = "mpg"
Const const_vrd5_extension_avc = "mp4"
'
Const const_vrd6_path =  "C:\Program Files (x86)\VideoReDoTVSuite6"
Const const_vrd6_profile_mpeg2 = "VRDTVS-for-QSF-MPEG2"
Const const_vrd6_profile_avc = "VRDTVS-for-QSF-H264"
Const const_vrd6_extension_mpeg2 = "mpg"
Const const_vrd6_extension_avc = "mp4"
'
vrd_version_for_qsf = 6
vrd_version_for_adscan = 6
'
'----------------------------------------------------------------------------------------------------------------------------------------
' Setup Global Default Paths, resolving them to Absolute paths
'
Dim vrdtvs_CAPTURE_TS_Folder
Dim vrdtvs_source_TS_Folder
Dim vrdtvs_done_TS_Folder
Dim vrdtvs_destination_mp4_Folder
Dim vrdtvs_failed_conversion_TS_Folder
Dim vrdtvs_temp_path
vrdtvs_CAPTURE_TS_Folder = fso.GetAbsolutePathName("G:\HDTV\")
vrdtvs_source_TS_Folder = fso.GetAbsolutePathName("G:\HDTV\000-TO-BE-PROCESSED\zzz-TEST\")
vrdtvs_done_TS_Folder = fso.GetAbsolutePathName(fso.BuildPath(vrdtvs_source_TS_Folder,"VRDTVS-done\"))
vrdtvs_destination_mp4_Folder = fso.GetAbsolutePathName(fso.BuildPath(vrdtvs_source_TS_Folder,"VRDTVS-Converted\"))
vrdtvs_failed_conversion_TS_Folder = fso.GetAbsolutePathName(fso.BuildPath(vrdtvs_source_TS_Folder,"VRDTVS-Failed-Conversion\"))
vrdtvs_temp_path = fso.GetAbsolutePathName("D:\VRDTVS-SCRATCH\")
' just examples of stuff for re-use in future BuildPath calls
' theParentFolderName = fso.GetParentFolderName(an_AbsolutePath) ' the drive and folder name of the file without any trailing "\"
' theBaseName = fso.GetBaseName(an_AbsolutePath)
' theExtName = fso.GetExtensionName(an_AbsolutePath) ' does not include  the "."
' theFileName = fso.GetFileName(an_AbsolutePath) ' includes filename and "." and extension
' theDriveName = fso.GetDriveName(an_AbsolutePath) ' includes driver letter and ":"
' theParentFolderName = fso.GetParentFolderName(an_AbsolutePath) 
'
'----------------------------------------------------------------------------------------------------------------------------------------
' Check if commandline parameters over-ride our standard values. Ignore any other commandline parameters.
'
vrdtvs_DEBUG = vrdtvs_get_commandline_parameter("DEBUG",vrdtvs_DEBUG)                                                                               ' /DEBUG:True
vrdtvs_DEVELOPMENT_NO_ACTIONS = vrdtvs_get_commandline_parameter("DEV",vrdtvs_DEVELOPMENT_NO_ACTIONS)                                               ' /DEV:True
If vrdtvs_DEVELOPMENT_NO_ACTIONS Then vrdtvs_DEBUG = True ' if in Development then always force debug on ' DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV 
'
vrdtvs_CAPTURE_TS_Folder = vrdtvs_get_commandline_parameter("capture_Folder",vrdtvs_CAPTURE_TS_Folder) ' no GetAbsolutePathName to leave "" as ""   ' /capture_Folder:""
If vrdtvs_CAPTURE_TS_Folder <> "" Then
	vrdtvs_CAPTURE_TS_Folder = fso.GetAbsolutePathName(vrdtvs_CAPTURE_TS_Folder)                 ' re-write capture folder as an Absolute Pathname ONLY if not ""
End If
If vrdtvs_DEVELOPMENT_NO_ACTIONS Then vrdtvs_CAPTURE_TS_Folder = ""  ' if under development, force do not copy any files ' DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV 
vrdtvs_source_TS_Folder = fso.GetAbsolutePathName(vrdtvs_get_commandline_parameter("source_Folder",vrdtvs_source_TS_Folder))                        ' /source_Folder:""
vrdtvs_done_TS_Folder = fso.GetAbsolutePathName(vrdtvs_get_commandline_parameter("done_Folder",vrdtvs_done_TS_Folder))                              ' /done_Folder:""
vrdtvs_destination_mp4_Folder = fso.GetAbsolutePathName(vrdtvs_get_commandline_parameter("destination_Folder",vrdtvs_destination_mp4_Folder))       ' /destination_Folder:""
vrdtvs_failed_conversion_TS_Folder = fso.GetAbsolutePathName(vrdtvs_get_commandline_parameter("failed_Folder",vrdtvs_failed_conversion_TS_Folder))  ' /failed_Folder:""
vrdtvs_temp_path = fso.GetAbsolutePathName(vrdtvs_get_commandline_parameter("temp_path",vrdtvs_temp_path))                                          ' /temp_path:"D:\VRDTVS-SCRATCH\"
'
vrd_version_for_qsf = vrdtvs_get_commandline_parameter("vrd_version_for_qsf",vrd_version_for_qsf)                                                   ' /vrd_version_for_qsf:6
vrd_version_for_adscan = vrdtvs_get_commandline_parameter("vrd_version_for_adscan",vrd_version_for_adscan)                                          ' /vrd_version_for_adscan:6
If vrd_version_for_qsf = 5 Then '*** QSF
    vrd_path_for_qsf_vbs = fso.GetAbsolutePathName(fso.BuildPath(const_vrd5_path,"vp.vbs"))
    vrd_profile_name_for_qsf_mpeg2 = const_vrd5_profile_mpeg2
    vrd_profile_name_for_qsf_avc = const_vrd5_profile_avc
    vrd_extension_mpeg2 = const_vrd5_extension_mpeg2
    vrd_extension_avc = const_vrd5_extension_avc
ElseIf vrd_version_for_qsf = 6 Then
    vrd_path_for_qsf_vbs = fso.GetAbsolutePathName(fso.BuildPath(const_vrd6_path,"vp.vbs"))
    vrd_profile_name_for_qsf_mpeg2 = const_vrd6_profile_mpeg2
    vrd_profile_name_for_qsf_avc = const_vrd6_profile_avc
    vrd_extension_mpeg2 = const_vrd6_extension_mpeg2
    vrd_extension_avc = const_vrd6_extension_avc
Else
    WScript.StdOut.WriteLine("VRDTVS ERROR - vrd_version_for_qsf can only be 5 or 6 ... Aborting ...")
    WScript.Quit 17 ' Error 17 = cannot perform the requested operation
End If
If vrd_version_for_adscan = 5 Then '*** AdScan
    vrd_path_for_adscan_vbs = fso.GetAbsolutePathName(fso.BuildPath(const_vrd5_path,"AdScan.vbs"))
ElseIf vrd_version_for_adscan = 6 Then
    vrd_path_for_adscan_vbs = fso.GetAbsolutePathName(fso.BuildPath(const_vrd6_path,"AdScan2.vbs"))
Else
    WScript.StdOut.WriteLine("VRDTVS ERROR - vrd_path_for_adscan_vbs can only be 5 or 6 ... Aborting ...")
    WScript.Quit 17 ' Error 17 = cannot perform the requested operation
End If
WScript.StdOut.WriteLine("NOTE: final                       vrdtvs_DEBUG=" & vrdtvs_DEBUG)
WScript.StdOut.WriteLine("NOTE: final      vrdtvs_DEVELOPMENT_NO_ACTIONS=" & vrdtvs_DEVELOPMENT_NO_ACTIONS)
If vrdtvs_DEBUG Then 
    WScript.StdOut.WriteLine("VRDTVS DEBUG: final                       vrdtvs_DEBUG=" & vrdtvs_DEBUG)
    WScript.StdOut.WriteLine("VRDTVS DEBUG: final      vrdtvs_DEVELOPMENT_NO_ACTIONS=" & vrdtvs_DEVELOPMENT_NO_ACTIONS & """")
    WScript.StdOut.WriteLine("VRDTVS DEBUG: final           vrdtvs_CAPTURE_TS_Folder=""" & vrdtvs_CAPTURE_TS_Folder & """")
    WScript.StdOut.WriteLine("VRDTVS DEBUG: final            vrdtvs_source_TS_Folder=""" & vrdtvs_source_TS_Folder & """")
    WScript.StdOut.WriteLine("VRDTVS DEBUG: final              vrdtvs_done_TS_Folder=""" & vrdtvs_done_TS_Folder & """")
    WScript.StdOut.WriteLine("VRDTVS DEBUG: final      vrdtvs_destination_mp4_Folder=""" & vrdtvs_destination_mp4_Folder & """")
    WScript.StdOut.WriteLine("VRDTVS DEBUG: final vrdtvs_failed_conversion_TS_Folder=""" & vrdtvs_failed_conversion_TS_Folder & """")
    WScript.StdOut.WriteLine("VRDTVS DEBUG: final                   vrdtvs_temp_path=""" & vrdtvs_temp_path & """")
    WScript.StdOut.WriteLine("VRDTVS DEBUG: final                vrd_version_for_qsf=" & vrd_version_for_qsf)
    WScript.StdOut.WriteLine("VRDTVS DEBUG: final               vrd_path_for_qsf_vbs=""" & vrd_path_for_qsf_vbs & """")
    WScript.StdOut.WriteLine("VRDTVS DEBUG: final     vrd_profile_name_for_qsf_mpeg2=""" & vrd_profile_name_for_qsf_mpeg2 & """")
    WScript.StdOut.WriteLine("VRDTVS DEBUG: final       vrd_profile_name_for_qsf_avc=""" & vrd_profile_name_for_qsf_avc & """")
    WScript.StdOut.WriteLine("VRDTVS DEBUG: final                vrd_extension_mpeg2=""" & vrd_extension_mpeg2 & """")
    WScript.StdOut.WriteLine("VRDTVS DEBUG: final                  vrd_extension_avc=""" & vrd_extension_avc & """")
    WScript.StdOut.WriteLine("VRDTVS DEBUG: final             vrd_version_for_adscan=" & vrd_version_for_adscan)
    WScript.StdOut.WriteLine("VRDTVS DEBUG: final            vrd_path_for_adscan_vbs=""" & vrd_path_for_adscan_vbs & """")
End If
'
'----------------------------------------------------------------------------------------------------------------------------------------
' Create the working folders if they do not already exist
'
If NOT fso.FolderExists(vrdtvs_source_TS_Folder) Then     
	Set objFolder = fso.CreateFolder(vrdtvs_source_TS_Folder)
	Set objFolder = Nothing
    If vrdtvs_DEBUG Then WScript.StdOut.WriteLine("VRDTVS DEBUG: Created vrdtvs_source_TS_Folder folder=" & vrdtvs_source_TS_Folder)
End If
If NOT fso.FolderExists(vrdtvs_done_TS_Folder) Then     
	Set objFolder = fso.CreateFolder(vrdtvs_done_TS_Folder)
	Set objFolder = Nothing
    If vrdtvs_DEBUG Then WScript.StdOut.WriteLine("VRDTVS DEBUG: Created vrdtvs_done_TS_Folder folder=" & vrdtvs_done_TS_Folder)
End If
If NOT fso.FolderExists(vrdtvs_destination_mp4_Folder) Then     
	Set objFolder = fso.CreateFolder(vrdtvs_destination_mp4_Folder)
	Set objFolder = Nothing
    If vrdtvs_DEBUG Then WScript.StdOut.WriteLine("VRDTVS DEBUG: Created vrdtvs_destination_mp4_Folder folder=" & vrdtvs_destination_mp4_Folder)
End If
If NOT fso.FolderExists(vrdtvs_failed_conversion_TS_Folder) Then     
	Set objFolder = fso.CreateFolder(vrdtvs_failed_conversion_TS_Folder)
	Set objFolder = Nothing
    If vrdtvs_DEBUG Then WScript.StdOut.WriteLine("VRDTVS DEBUG: Created vrdtvs_failed_conversion_TS_Folder folder=" & vrdtvs_failed_conversion_TS_Folder)
End If
If NOT fso.FolderExists(vrdtvs_temp_path) Then     
	Set objFolder = fso.CreateFolder(vrdtvs_temp_path)
	Set objFolder = Nothing
    If vrdtvs_DEBUG Then WScript.StdOut.WriteLine("VRDTVS DEBUG: Created vrdtvs_temp_path folder=" & vrdtvs_temp_path)
End If
'
'----------------------------------------------------------------------------------------------------------------------------------------
' Start a new copy of Insomnia so the PC does not go to sleep in the middle of conversions, do not wait for it to finish
'
Dim vrdtvs_Insomnia64_tmp_filename, vrdtvs_Insomnia64_ProcessID
vrdtvs_Insomnia64_tmp_filename = vrdtvs_gimme_a_temporary_absolute_filename("VRDTVS_Insomnia64_copy-" & vrdtvs_run_datetime) & ".exe"
If vrdtvs_DEBUG Then WScript.StdOut.WriteLine("VRDTVS DEBUG: Insomnia: Creating and running Insomnia vrdtvs_Insomnia64_tmp_filename=" & vrdtvs_Insomnia64_tmp_filename)
vrdtvs_exit_code = vrdtvs_delete_a_file (vrdtvs_Insomnia64_tmp_filename, True) ' True=silently delete it even though it should never pre-exist
If vrdtvs_DEBUG Then WScript.StdOut.WriteLine("VRDTVS DEBUG: Insomnia: Copying """ & vrdtvs_Insomniaexe64 & """ to """ & vrdtvs_Insomnia64_tmp_filename & """")
On Error Resume Next
fso.CopyFile vrdtvs_Insomniaexe64, vrdtvs_Insomnia64_tmp_filename, True 
vrdrvs_Err_Code = Err.Number
vrdrvs_Err_Description = Err.Description
On Error Goto 0
'If vrdtvs_DEBUG Then WScript.StdOut.WriteLine("VRDTVS DEBUG: Insomnia: File Copy returned error code: " & vrdrvs_Err_Code & " Descrption: " & vrdrvs_Err_Description)
If vrdrvs_Err_Code <> 0 Then
    Err.Clear
    WScript.StdOut.WriteLine("VRDTVS Insomnia: ERROR - Error " & vrdrvs_Err_Code & " Creating vrdtvs_Insomnia64_tmp_filename=" & vrdtvs_Insomnia64_tmp_filename & "... Aborting ...")
    WScript.StdOut.WriteLine("VRDTVS Insomnia: ERROR - " & vrdrvs_Err_Description)
    ' Err.Raise 17 ' Error 17 = cannot perform the requested operation
    WScript.Quit 17 ' Error 17 = cannot perform the requested operation
End If
'
' Exec it asynchronously and do not wait for it to finish
' Start "title" "file" 
' NOTE: Exec object has a .Terminate - this type of process kill does NOT clean up properly and may cause memory leaks - use only as a last resort!
'
'vrdtvs_cmd = "CMD /C START /min """ &  vrdtvs_Insomnia64_tmp_filename & """ """ & vrdtvs_Insomnia64_tmp_filename & """"
'vrdtvs_cmd = "START /min """ &  vrdtvs_Insomnia64_tmp_filename & """ """ & vrdtvs_Insomnia64_tmp_filename & """"
vrdtvs_cmd = """" &  vrdtvs_Insomnia64_tmp_filename & """"
If vrdtvs_DEBUG Then WScript.StdOut.WriteLine("VRDTVS DEBUG: Insomnia: Exec command: " & vrdtvs_cmd)
set vrdtvs_exe_obj = wso.Exec(vrdtvs_cmd)
vrdtvs_Insomnia64_ProcessID = vrdtvs_exe_obj.ProcessID
vrdtvs_status = vrdtvs_exe_obj.ExitCode
Set vrdtvs_exe_obj = Nothing
WScript.StdOut.WriteLine("VTDRVS Insomnia: Exec command: " & vrdtvs_cmd)
WScript.StdOut.WriteLine("VTDRVS Insomnia: has run asynchronously with vrdtvs_Insomnia64_ProcessID=" & vrdtvs_Insomnia64_ProcessID)
If vrdtvs_Insomnia64_ProcessID = 0 Then
    WScript.StdOut.WriteLine("VRDTVS Insomnia: ERROR - Insomnia START command created ProcessID is zero ... Aborting ...")
    ' Err.Raise 17 ' Error 17 = cannot perform the requested operation
    WScript.Quit 17 ' Error 17 = cannot perform the requested operation
End If
WScript.StdOut.WriteLine("VTDRVS Insomnia: Exec Exit Status: " & vrdtvs_status)
If vrdtvs_DEBUG Then WScript.StdOut.WriteLine("VRDTVS DEBUG: Insomnia: Exec Exit Status: " & vrdtvs_status)
'
'----------------------------------------------------------------------------------------------------------------------------------------
' Move .ts .mp4 .mpg .brpj files from the Source Folder to the source folder sincethat is where we process from
'
If vrdtvs_CAPTURE_TS_Folder <> "" Then
    vrdtvs_status = vrdtvs_move_files_to_folder(vrdtvs_CAPTURE_TS_Folder & "\*.ts", vrdtvs_source_TS_Folder & "\")    ' ignore any status
    vrdtvs_status = vrdtvs_move_files_to_folder(vrdtvs_CAPTURE_TS_Folder & "\*.mp4", vrdtvs_source_TS_Folder & "\")   ' ignore any status
    vrdtvs_status = vrdtvs_move_files_to_folder(vrdtvs_CAPTURE_TS_Folder & "\*.mpg", vrdtvs_source_TS_Folder & "\")   ' ignore any status
    vrdtvs_status = vrdtvs_move_files_to_folder(vrdtvs_CAPTURE_TS_Folder & "\*.bprj", vrdtvs_source_TS_Folder & "\")  ' ignore any status '.bprj are associated with .mp4 of the same BaseName
End If
'
'----------------------------------------------------------------------------------------------------------------------------------------
' In Top Level Folders: Source and Destination 
' (the function filters for file Extensions: .ts .mp4 .mpg, and autofixes .bprj which are associated with .mpg and .mp4 and should have the same BaseName)
'   a) Remove special characters in filenames for file Extensions: .ts .mp4 .mpg and autofix .bprj
'   b) Modify the filenames based on the filename content including reformatting the date in the filename
'	c) Also Modily content of associated .bprj files (they are .xml content) to link to the new media filename since we are modifying the pair
'
'If vrdtvs_DEBUG Then WScript.StdOut.WriteLine("VRDTVS DEBUG: about to call vrdtvs_fix_filenames_in_a_folder_tree(""" & vrdtvs_source_TS_Folder & """, False)")
vrdtvs_status = vrdtvs_fix_filenames_in_a_folder_tree(vrdtvs_source_TS_Folder, False) ' this does (a) and (b) and (c).  False indicates to process only the top level folder with NO SUBFOLDERS
If vrdtvs_status <> 0 Then ' Something went wrong with processing files in the Source folder ... check for 53 not found ?
	If vrdtvs_DEBUG Then WScript.StdOut.WriteLine("VRDTVS DEBUG: VRDTVS ERROR - Error " & vrdtvs_status & " from vrdtvs_fix_filenames_in_a_folder_tree in """ & vrdtvs_source_TS_Folder & """... Aborting ...")
	WScript.StdOut.WriteLine("VRDTVS ERROR - Error " & vrdtvs_status & " from vrdtvs_fix_filenames_in_a_folder_tree in """ & vrdtvs_source_TS_Folder & """ ... Aborting ...")
	Wscript.Quit vrdtvs_status
End If
'If vrdtvs_DEBUG Then WScript.StdOut.WriteLine("VRDTVS DEBUG: about to call vrdtvs_fix_filenames_in_a_folder_tree(""" & vrdtvs_destination_mp4_Folder & """, True)")
vrdtvs_status = vrdtvs_fix_filenames_in_a_folder_tree(vrdtvs_destination_mp4_Folder, True) ' this does (a) and (b) and (c).  True indicates to process the top level folder including SUBFOLDERS
If vrdtvs_status <> 0 Then ' Something went wrong with processing files in the Destination folder ... check for 53 not found ?
	If vrdtvs_DEBUG Then WScript.StdOut.WriteLine("VRDTVS DEBUG: VRDTVS ERROR - Error " & vrdtvs_status & " from vrdtvs_fix_filenames_in_a_folder_tree in """ & vrdtvs_destination_mp4_Folder & """... Aborting ...")
	WScript.StdOut.WriteLine("VRDTVS ERROR - Error " & vrdtvs_status & " from vrdtvs_fix_filenames_in_a_folder_tree in """ & vrdtvs_destination_mp4_Folder & """ ... Aborting ...")
	Wscript.Quit vrdtvs_status
End If
'
'----------------------------------------------------------------------------------------------------------------------------------------
' Convert Video files and create the associated .bprj files by running adscan on the media file
' The function filters for file Extensions: .ts .mp4 .mpg and creates .bprj
'
' generate a unique filename to save FFMPEG and related commands
vrdtvs_saved_ffmpeg_commands_filename = fso.GetAbsolutePathName(fso.BuildPath(vrdtvs_source_TS_Folder, "vrdtvs_saved_ffmpeg_commands-" & vrdtvs_run_datetime & ".bat"))
' delete the FFMPEG COMMANDS file silently
vrdtvs_status = vrdtvs_delete_a_file (vrdtvs_saved_ffmpeg_commands_filename, True) ' delete it silently
If vrdtvs_status <> 0 AND vrdtvs_status <> 53 Then ' Something went wrong with deleting the file, but allow 53 "File not found"
	If vrdtvs_DEBUG Then WScript.StdOut.WriteLine("VRDTVS DEBUG: VRDTVS ERROR - Error " & vrdtvs_status & " from vrdtvs_delete_a_file with """ & vrdtvs_saved_ffmpeg_commands_filename & """... Aborting ...")
	WScript.StdOut.WriteLine("VRDTVS ERROR - Error " & vrdtvs_status & " from vrdtvs_delete_a_file with """ & vrdtvs_saved_ffmpeg_commands_filename & """... Aborting ...")
	Wscript.Quit vrdtvs_status
End If
' Create a new empty FFMPEG COMMANDS file with overwrite
'?????????????????????????????????????????????.CreateFile
' open the FFMPEG COMMANDS file and get a Global object used to write to it
'?????????????????????????????????????????????.Open for write
'Set vrdtvs_saved_ffmpeg_commands_object = ???
' initialize the FFMPEG COMMANDS file with @echo, expansion etc
'?????????????????????????????????????????????.Writeline
' 
'.................. START video processing for the FULL SOURCE TS folder (not tree) - the function has a big loop - converts Source files then moves them to Done or Failed
'vrdtvs_status = vrdtvs_convert_video_files_and_move_to_done() ' it uses globally defined folders (the function filters for file Extensions: .ts .mp4 .mpg and creates .bprj)
'If vrdtvs_status <> 0 Then ' Something bad went wrong (invididual conversion failures just result in moving the source file to the Failed folder)
'	If vrdtvs_DEBUG Then WScript.StdOut.WriteLine("VRDTVS DEBUG: VRDTVS ERROR - Error " & vrdtvs_status & " from vrdtvs_convert_video_files_and_move_to_done ... Aborting ...")
'	WScript.StdOut.WriteLine("VRDTVS ERROR - Error " & vrdtvs_status & " from vrdtvs_convert_video_files_and_move_to_done ... Aborting ...")
'	Wscript.Quit vrdtvs_status
'End If
'.................. END video processing for the FULL SOURCE TS folder (not tree) - the function has a big loop - converts Source files then moves them to Done or Failed
'
' finalize the FFMPEG COMMANDS file with PAUSE etc
'?????????????????????????????????????????????.Writeline
' close the FFMPEG COMMANDS file 
'?????????????????????????????????????????????.Close
' set the FFMPEG COMMANDS file object to nothing
'Set vrdtvs_saved_ffmpeg_commands_object = Nothing







'----------------------------------------------------------------------------------------------------------------------------------------
' Fix the DateCreated and DateModified timestamps based on the date in the filename (a PowerShell command ... learn how to do that on the commandline)
' in Top Level Folders and Subfolders: Source and Destination (the function filters for file Extensions: .ts .mp4 .mpg but NOT .bprj)
'
vrdtvs_temp_powershell_filename = vrdtvs_gimme_a_temporary_absolute_filename("vrdtvs_ps1_to_fix_timestamps-" & vrdtvs_run_datetime) & ".ps1"
'vrdtvs_status = vrdtvs_create_ps1_to_fix_timestamps(vrdtvs_temp_powershell_filename)
'If vrdtvs_status <> 0 Then ' Something went wrong with creating the .ps1 file
'	If vrdtvs_DEBUG Then WScript.StdOut.WriteLine("VRDTVS DEBUG: VRDTVS ERROR - Error " & vrdtvs_status & " from vrdtvs_create_ps1_to_fix_timestamps with """ & vrdtvs_temp_powershell_filename & """... Aborting ...")
'	WScript.StdOut.WriteLine("VRDTVS ERROR - Error " & vrdtvs_status & " from vrdtvs_create_ps1_to_fix_timestamps with """ & vrdtvs_temp_powershell_filename & """... Aborting ...")
'	Wscript.Quit vrdtvs_status
'End If
'scratch_local_timerStart = Timer
'?????????????????????????????????
' DO THIS IN A SEPARATE FUNCTION:
'if fix_timestamps = True then
'	Set objWscriptShell = CreateObject("Wscript.shell")
'	vrdtvs_temp_powershell_cmd = "powershell -NoLogo -ExecutionPolicy Unrestricted -Sta -NonInteractive -WindowStyle Normal -File """ & vrdtvs_temp_powershell_filename & """ -Folder """ & ???thefoldertree??? & """"
'	WScript.StdOut.WriteLine "vbs_rename_files: ***** Fixing file dates using:<" & vrdtvs_temp_powershell_cmd & ">"
'	???? objWscriptShell.??? exec run vrdtvs_temp_powershell_cmd, True ?????????? use exec instead with stdout stderr etc
'	Set objWscriptShell = Nothing
'	WScript.StdOut.WriteLine "vbs_rename_files: --- FINISHED for folder <" & aPath & ">"
'end if
'????????????????????????????
'scratch_local_timerEnd = Timer
'WScript.StdOut.WriteLine("VRDTVS Finished Powershell file timestamp fixing for folder tree """ & ffiaft_folder_tree & """ with Elapsed Time " & vrdtvs_Calculate_ElapsedTime_string(scratch_local_timerStart, scratch_local_timerEnd))
'vrdtvs_status = vrdtvs_delete_a_file (vrdtvs_temp_powershell_filename, True)
'If vrdtvs_status <> 0 Then ' Something went wrong with deleting the .ps1 file
'	If vrdtvs_DEBUG Then WScript.StdOut.WriteLine("VRDTVS DEBUG: VRDTVS ERROR - Error " & vrdtvs_status & " from vrdtvs_delete_a_file with """ & vrdtvs_temp_powershell_filename & """... Aborting ...")
'	WScript.StdOut.WriteLine("VRDTVS ERROR - Error " & vrdtvs_status & " from vrdtvs_delete_a_file with """ & vrdtvs_temp_powershell_filename & """... Aborting ...")
'	Wscript.Quit vrdtvs_status
'End If
'
'----------------------------------------------------------------------------------------------------------------------------------------
' Kill the Insomnia64 process that we started earlier
'
'vrdtvs_cmd = "TaskKill /t /f /im """ & vrdtvs_Insomnia64_tmp_filename & """" ' we saved the ProcessId when we started it
vrdtvs_cmd = "TaskKill /t /f /pid " & vrdtvs_Insomnia64_ProcessID ' we saved the ProcessId when we started it
' taskkill /t /f /im "%iFile%" >> "!vrdlog!" 2>&1
'   /f  Specifies that processes be forcefully ended.
'   /t	Ends the specified process and any child processes started by it.
'   /pid <processID>    Specifies the process ID of the process to be terminated.
'   /im <imagename>     Specifies the image name of the process to be terminated.
WScript.StdOut.WriteLine("VTDRVS TaskKill: TaskKill Insomnia Exec command: " & vrdtvs_cmd)
set vrdtvs_exe_obj = wso.Exec(vrdtvs_cmd)
Do While vrdtvs_exe_obj.Status = 0 '0 is running and 1 is ending
    Wscript.Sleep 100
Loop
Do Until vrdtvs_exe_obj.StdOut.AtEndOfStream
    vrdtvs_tmp = vrdtvs_exe_obj.StdOut.ReadLine()
    WScript.StdOut.WriteLine("VTDRVS TaskKill: TaskKill Insomnia Exec StdOut: " & vrdtvs_tmp)
Loop
Do Until vrdtvs_exe_obj.StdErr.AtEndOfStream
    vrdtvs_tmp = vrdtvs_exe_obj.StdErr.ReadLine()
    WScript.StdOut.WriteLine("VTDRVS TaskKill: TaskKill Insomnia Exec StdErr: " & vrdtvs_tmp)
Loop
vrdtvs_status = vrdtvs_exe_obj.ExitCode ' Ignore any error codes returned by taskkill
WScript.StdOut.WriteLine("VTDRVS TaskKill: Insomnia TaskKill Exec Exit Status: " & vrdtvs_status)
Set vrdtvs_exe_obj = Nothing
If vrdtvs_DEBUG Then WScript.StdOut.WriteLine("VRDTVS DEBUG: VTDRVS TaskKill Insomnia exiting with status=""" & vrdtvs_status & """")
'
'----------------------------------------------------------------------------------------------------------------------------------------
' Finish and Quit
'
vrdtvs_timer_EndTime_overall = Timer
WScript.StdOut.WriteLine(vrdtvs_ScriptName & " Finished: " & vrdtvs_current_datetime_string() & "  Elapsed Time: " & vrdtvs_Calculate_ElapsedTime_string(vrdtvs_timer_StartTime_overall, vrdtvs_timer_EndTime_overall))
If vrdtvs_DEBUG Then WScript.StdOut.WriteLine("VRDTVS DEBUG: VTDRVS: " & vrdtvs_ScriptName & " Finished: " & vrdtvs_current_datetime_string() & "  Elapsed Time: " & vrdtvs_Calculate_ElapsedTime_string(vrdtvs_timer_StartTime_overall, vrdtvs_timer_EndTime_overall))
WScript.Quit
'
'----------------------------------------------------------------------------------------------------------------------------------------
'----------------------------------------------------------------------------------------------------------------------------------------
'----------------------------------------------------------------------------------------------------------------------------------------
'----------------------------------------------------------------------------------------------------------------------------------------
'----------------------------------------------------------------------------------------------------------------------------------------
'----------------------------------------------------------------------------------------------------------------------------------------
'----------------------------------------------------------------------------------------------------------------------------------------
'----------------------------------------------------------------------------------------------------------------------------------------
'----------------------------------------------------------------------------------------------------------------------------------------
'----------------------------------------------------------------------------------------------------------------------------------------
'----------------------------------------------------------------------------------------------------------------------------------------
'----------------------------------------------------------------------------------------------------------------------------------------
'----------------------------------------------------------------------------------------------------------------------------------------
'----------------------------------------------------------------------------------------------------------------------------------------
'----------------------------------------------------------------------------------------------------------------------------------------
'----------------------------------------------------------------------------------------------------------------------------------------
'----------------------------------------------------------------------------------------------------------------------------------------
'----------------------------------------------------------------------------------------------------------------------------------------
'----------------------------------------------------------------------------------------------------------------------------------------
'----------------------------------------------------------------------------------------------------------------------------------------
'
' Subroutines and Functions
'
Function vrdtvs_get_commandline_parameter(gcp_argument_name, gcp_default_value)
    ' Parameters: 
    '   gcp_argument_name       named argument specified on commandline like 
    '                               /p1:"This is the value for p1"
    '   gcp_default_value       a default value if the parameter is not specified on the commandline (or specified with no value)
    ' Call like this:
    '       x = vrdtvs_get_commandline_parameter("source_TS_Folder", "G:\HDTV\000-TO-BE-PROCESSED\zzz-TEST\")
    '       x = vrdtvs_get_commandline_parameter("True_or_False", False)
    ' NOTE: if the commandline parameter is a path or something, it is NOT checked or Absoluted by this function
    Dim gcp_argument_count, gcp_NamedArgs, gcp_Return_Value
    gcp_argument_count = WScript.Arguments.Count
    gcp_Return_Value = gcp_default_value ' default to return the default_value
    'If vrdtvs_DEBUG Then 
    '    WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_get_commandline_parameter gcp_argument_name=" & gcp_argument_name)
    '    WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_get_commandline_parameter gcp_default_value=" & gcp_default_value)
    'End If
    If gcp_argument_count > 0 Then
        Set gcp_NamedArgs = WScript.Arguments.Named
        If gcp_NamedArgs.Exists(gcp_argument_name) and NOT IsEmpty(gcp_NamedArgs(gcp_argument_name)) Then ' IsEmpty is a special case of exists but has no value, but is not "" which is different
            gcp_Return_Value = gcp_NamedArgs.Item(gcp_argument_name)
            If vrdtvs_DEBUG Then WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_get_commandline_parameter obtained commandline Argument: " & gcp_argument_name & "=""" & gcp_Return_Value & """")
            If Ucase(gcp_Return_Value) = Ucase("True")  Then 
                gcp_Return_Value = True    ' if required, convert to boolean True
                'If vrdtvs_DEBUG Then WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_get_commandline_parameter converted to boolean True gcp_Return_Value=" & gcp_Return_Value)
            End If
            If Ucase(gcp_Return_Value) = Ucase("False") Then 
                gcp_Return_Value = False   ' if required, convert to boolean False
                'If vrdtvs_DEBUG Then WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_get_commandline_parameter converted to boolean False gcp_Return_Value=" & gcp_Return_Value)
            End If
        End If
        Set gcp_NamedArgs = Nothing
    End If
    If vrdtvs_DEBUG Then WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_get_commandline_parameter exiting with: " & gcp_argument_name & "=""" & gcp_Return_Value & """")
    vrdtvs_get_commandline_parameter = gcp_Return_Value
End Function
'
Function vrdtvs_current_datetime_string ()
    'return format: YYYY.MM.DD-HH.MM.SS.mmm
    ' Call like this:
    '       x = vrdtvs_current_datetime_string()
	Dim t, t_date, tmp, milliseconds
	'capture the date and timer "close together" so if the date changes while the other code runs the values you are using don't change
	t = Timer
	t_date = Now()
	tmp = Int(t)
	milliseconds = Int((t-tmp) * 1000)
    vrdtvs_current_datetime_string = year(t_date) & "." & Right("00" & month(t_date),2) & "." & Right("00" & day(t_date),2) & "-" & Right("00" & hour(t_date),2) & "." & Right("00" & minute(t_date),2) & "." & Right("00" & second(t_date),2) & "." & Right("000" & milliseconds,3)
End Function
'
Function vrdtvs_gimme_a_temporary_absolute_filename (gataf_filename_prepend_string)
    ' rely on global variable "fso"
    ' rely on global variable "vrdtvs_temp_path" being set to a valid path for the temporary file
    ' rely on function vrdtvs_current_datetime_string
    ' Parameters: 
    '   gataf_filename_prepend_string       allows better identification of what the temporary file is associate with
    ' Call like this:
    '       x = vrdtvs_gimme_a_temporary_absolute_filename("a_base_filename_text_string")
    Dim gataf_temp
    'If vrdtvs_DEBUG Then WScript.StdOut.WriteLine("VRDTVS DEBUG: entered vrdtvs_gimme_a_temporary_absolute_filename")
    gataf_temp = gataf_filename_prepend_string & "-" & vrdtvs_current_datetime_string() & "-" & fso.GetTempName ' ".tmp" already added
    gataf_temp = fso.GetAbsolutePathName(fso.BuildPath(vrdtvs_temp_path,gataf_temp)) ' rely on global variable "vrdtvs_temp_path" already being set to a valid path
    'If vrdtvs_DEBUG Then WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_gimme_a_temporary_absolute_filename generated a_temporary_filename=""" & gataf_temp & """")
    vrdtvs_gimme_a_temporary_absolute_filename = gataf_temp
End Function
'
Function vrdtvs_delete_a_file (filename_to_delete, do_it_silently)
    ' rely on global variable "fso"
    ' Parameters:
    '   filename_to_delete      a fully qualified filename
    '   do_it_silently          true or false
    ' Call like this:
    '       x = vrdtvs_delete_a_file("c:\temp\temp.tmp",False)
    Dim daf_Err_number, daf_Err_Description, daf_Err_Helpfile, daf_Err_HelpContext
    Dim daf_filename_to_delete
    If NOT do_it_silently Then WScript.StdOut.WriteLine("vrdtvs_delete_a_file Deleting file: """ & filename_to_delete & """")
    If vrdtvs_DEBUG Then WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_delete_a_file Deleting file: """ & filename_to_delete & """")
    'If fso.FileExists(filename_to_delete) Then
    	On Error Resume Next
	    fso.DeleteFile filename_to_delete, True ' fso.DeleteFile ( filespec[, force] ) ' it also supports wildcards, allowing delete of multiple files ...
	    daf_Err_number = Err.Number
        daf_Err_Description = Err.Description
        daf_Err_Helpfile = Err.Helpfile
        daf_Err_HelpContext = Err.HelpContext
        If daf_Err_number <> 0 Then
            If NOT do_it_silently Then WScript.StdOut.WriteLine("VRDTVS ERROR: vrdtvs_delete_a_file error " &  daf_Err_number &  " " &  daf_Err_Description & " : raised when Deleting file """ & filename_to_delete & """")
            'If vrdtvs_DEBUG Then WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_delete_a_file Error " &  daf_Err_number &  " " &  daf_Err_Description & " : raised when Deleting file """ & filename_to_delete & """")
	        Err.Clear
        Else
            If NOT do_it_silently Then WScript.StdOut.WriteLine("vrdtvs_delete_a_file Deleted file """ & filename_to_delete & """")
            'If vrdtvs_DEBUG Then WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_delete_a_file Deleted file """ & filename_to_delete & """")
        End if
	    On Error Goto 0 ' now continue
    'End If
    'If vrdtvs_DEBUG Then WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_delete_a_file exiting with status=""" & daf_Err_number & """")
    vrdtvs_delete_a_file = daf_Err_number
End Function
'
Function vrdtvs_move_files_to_folder (mf_source_path_wildcard, mv_destination_folder) ' this uses DOS "CMD /C MOVE /Y ..."
    ' rely on global variable "fso"
    ' Parameters:
    '   mf_source_path_wildcard     
    '   mv_destination_folder
    ' Call like this:
    '       result = vrdtvs_move_files_to_folder("G:\SOME_SOURCE_PATH\*.MPG", "G:\SOME_DESTINATION_PATH\")
    '            which does a DOS command something like MOVE /Y "G:\SOME_SOURCE_PATH\*.MPG" "G:\SOME_DESTINATION_PATH\" 
    ' Examples of some useful functions:
        ' an_AbsolutePath = fso.GetAbsolutePathName(fso.BuildPath("C:\SOFTWARE\ffmpeg\0-homebuilt-x64\","MP4Box.exe"))
        ' theParentFolderName = fso.GetParentFolderName(an_AbsolutePath) ' the drive and folder name of the file without any trailing "\"
        ' theBaseName = fso.GetBaseName(an_AbsolutePath)
        ' theExtName = fso.GetExtensionName(an_AbsolutePath) ' does not include  the "."
        ' theFileName = fso.GetFileName(an_AbsolutePath) ' includes filename and "." and extension
        ' theDriveName = fso.GetDriveName(an_AbsolutePath) ' includes driver letter and ":"
        ' theParentFolderName = fso.GetParentFolderName(an_AbsolutePath) 
    Dim mf_exe, mf_cmd, mf_status, mf_tmp
    Dim mf_source_AbsolutePath, mf_destination_AbsolutePath
    'If vrdtvs_DEBUG Then WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_move_files_to_folder: """ & mf_source_path_wildcard & """" & " to """ &  mv_destination_folder & """")
    mf_source_AbsolutePath = fso.GetAbsolutePathName(mf_source_path_wildcard)
    mf_destination_AbsolutePath = fso.GetAbsolutePathName(mv_destination_folder)
    If Right(mf_destination_AbsolutePath,1) <> "\" Then
        mf_destination_AbsolutePath = mf_destination_AbsolutePath & "\"     ' add a trailing backslash for DOS MOVE to recognise the destination pathname
    End If
    If vrdtvs_DEBUG Then
       ' WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_move_files_to_folder      mf_source_AbsolutePath=""" & mf_source_AbsolutePath & """")
        'WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_move_files_to_folder mf_destination_AbsolutePath=""" & mf_destination_AbsolutePath & """")
    End If
    ' Ugh, a DOS MOVE requires CMD /C  to work !! 
    mf_cmd = "CMD /C MOVE /Y """ & mf_source_AbsolutePath & """ """ & mf_destination_AbsolutePath & """ 2>&1"
	If vrdtvs_DEVELOPMENT_NO_ACTIONS Then ' DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV 
		mf_cmd = "REM " & mf_cmd ' do not move anything 
	End If
	WScript.StdOut.WriteLine("vrdtvs_move_files_to_folder Exec command: " & mf_cmd)
    set mf_exe = wso.Exec(mf_cmd)
    Do While mf_exe.Status = 0 '0 is running and 1 is ending
         Wscript.Sleep 100
    Loop
    Do Until mf_exe.StdOut.AtEndOfStream
        mf_tmp = mf_exe.StdOut.ReadLine()
        WScript.StdOut.WriteLine("vrdtvs_move_files_to_folder StdOut: " & mf_tmp)
    Loop
    Do Until mf_exe.StdErr.AtEndOfStream
        mf_tmp = mf_exe.StdErr.ReadLine()
        WScript.StdOut.WriteLin("vrdtvs_move_files_to_folder StdErr: " & mf_tmp)
    Loop
    mf_status = mf_exe.ExitCode
    WScript.StdOut.WriteLine("vrdtvs_move_files_to_folder Exit Status: " & mf_status)
    Set mf_exe = Nothing
    'If vrdtvs_DEBUG Then WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_move_files_to_folder exiting with status=""" & mf_status & """")
    vrdtvs_move_files_to_folder = mf_status
End Function
'
Function vrdtvs_Calculate_ElapsedTime_ms (timer_StartTime, timer_EndTime)
    ' Parameters:
    '   timer_StartTime
    '   timer_EndTime
    ' Call like this:
    '       dim timer_StartTime, timer_EndTime
    '       timer_StartTime = Timer()
    '       Wscript.Sleep 750 ' milliseconds
    '       timer_EndTime = Timer()
    '       Wscript.Echo "Function Elapsed Time in ms : " & vrdtvs_Calculate_ElapsedTime_ms(timer_StartTime, timer_EndTime)
    vrdtvs_Calculate_ElapsedTime_ms = Round(timer_EndTime - timer_StartTime, 3) * 1000 ' round to 3 decimal places is milliseconds
End Function
'
Function vrdtvs_Calculate_ElapsedTime_string (timer_StartTime, timer_EndTime)
    ' Parameters:
    '   timer_StartTime
    '   timer_EndTime
    ' Call like this:
    '       dim timer_StartTime, timer_EndTime
    '       timer_StartTime = Timer()
    '       Wscript.Sleep 750 ' milliseconds
    '       timer_EndTime = Timer()
    '       Wscript.Echo "Function Elapsed Time String: " & vrdtvs_Calculate_ElapsedTime_string(timer_StartTime, timer_EndTime)
    Const SECONDS_IN_DAY    = 86400
    Const SECONDS_IN_HOUR   = 3600
    Const SECONDS_IN_MINUTE = 60
    Const SECONDS_IN_WEEK   = 604800
	Dim seconds, minutes, hours, days, seconds_plural
    seconds = Round(timer_EndTime - timer_StartTime, 3) ' 3 decimal places is milliseconds
	If seconds > 1 Then
		seconds_plural = "s"
	Else
		seconds_plural = ""
	End If
    If seconds < SECONDS_IN_MINUTE Then
        vrdtvs_Calculate_ElapsedTime_string = FormatNumber(seconds,3) & " second" & seconds_plural
        Exit Function
    End If
    If seconds < SECONDS_IN_HOUR Then 
        minutes = seconds / SECONDS_IN_MINUTE
        seconds = seconds MOD SECONDS_IN_MINUTE
        vrdtvs_Calculate_ElapsedTime_string = Int(minutes) & " minutes " & FormatNumber(seconds,3) & " second" & seconds_plural
        Exit Function
    End If
    If seconds < SECONDS_IN_DAY Then
        hours   = seconds / SECONDS_IN_HOUR
        minutes = (seconds MOD SECONDS_IN_HOUR) / SECONDS_IN_MINUTE
        seconds = (seconds MOD SECONDS_IN_HOUR) MOD SECONDS_IN_MINUTE
        vrdtvs_Calculate_ElapsedTime_string = Int(hours) & " hours " & Int(minutes) & " minutes " & FormatNumber(seconds,3) & " second" & seconds_plural
        Exit Function
    End If
    If seconds < SECONDS_IN_WEEK Then
        days    = seconds / SECONDS_IN_DAY
        hours   = (seconds MOD SECONDS_IN_DAY) / SECONDS_IN_HOUR
        minutes = ((seconds MOD SECONDS_IN_DAY) MOD SECONDS_IN_HOUR) / SECONDS_IN_MINUTE
        seconds = ((seconds MOD SECONDS_IN_DAY) MOD SECONDS_IN_HOUR) MOD SECONDS_IN_MINUTE
        vrdtvs_Calculate_ElapsedTime_string = Int(days) & " days " & Int(hours) & " hours " & Int(minutes) & " minutes " & FormatNumber(seconds,3) & " second" & seconds_plural
        Exit Function
    End If
End Function
'
Function vrdtvs_get_mediainfo_parameter (mi_Section, mi_Parameter, mi_MediaFilename, mi_Legacy) 
    ' rely on global variable "wso"
    ' rely on global variable vrdtvs_mediainfoexe64 exists pointing to the mediainfo exe
    ' Note \r\n is Windows new-line, 
    '   Which in the case of multiple audio streams, outputs a result for each stream on a new line, 
    '   the first stream being the first entry, and the first audio stream should be the one we need. 
    ' Parameters:
    '   mi_Section          eg "Video" "Auidio" "General"
    '   mi_Parameter        name of parameter to fetch eg "DisplayAspectRatio/String"
    '   mi_MediaFilename    fully qualified (Absolute) filename of the media file to query
    '   mi_Legacy           "" or "--Legacy" to invoke old the old mediainfo parameter name/value pairs
    ' Call like this:
    '       dim V_Width, V_Height, V_DisplayAspectRatio, V_DisplayAspectRatio_string, V_DisplayAspectRatio_string_slash, A_Video_Delay_ms, A_Audio_Delay_ms
    '       V_Width = get_mediainfo_parameter("Video","Width","G:\HDTV\000-TO-BE-PROCESSED\zzz-TEST\VRDTVS-Converted\News-ABC_Evening_News.2021-02-05.mp4", "")
    '       V_Height = get_mediainfo_parameter("Video","Height","G:\HDTV\000-TO-BE-PROCESSED\zzz-TEST\VRDTVS-Converted\News-ABC_Evening_News.2021-02-05.mp4", "")
    '       V_DisplayAspectRatio = get_mediainfo_parameter("Video","DisplayAspectRatio","G:\HDTV\000-TO-BE-PROCESSED\zzz-TEST\VRDTVS-Converted\News-ABC_Evening_News.2021-02-05.mp4", "")
    '       V_DisplayAspectRatio_string = get_mediainfo_parameter("Video","DisplayAspectRatio/String","G:\HDTV\000-TO-BE-PROCESSED\zzz-TEST\VRDTVS-Converted\News-ABC_Evening_News.2021-02-05.mp4", "")
    '       V_DisplayAspectRatio_string_slash = Replace(V_DisplayAspectRatio_string,":","/",1,-1,1)
    '       A_Video_Delay_ms =  get_mediainfo_parameter("Audio","Video_Delay","G:\HDTV\000-TO-BE-PROCESSED\zzz-TEST\VRDTVS-Converted\News-ABC_Evening_News.2021-02-05.mp4", "")
    '       If A_Video_Delay_ms = "" Then
    '           A_Video_Delay_ms = 0
    '           A_Audio_Delay_ms = 0
    '       Else
    '           A_Audio_Delay_ms = 0 - A_Video_Delay_ms
    '       End If
    '       Wscript.echo("V_Width=" & V_Width & " V_Height=" & V_Height)
    '       Wscript.echo("V_DisplayAspectRatio=" & V_DisplayAspectRatio)
    '       Wscript.echo("V_DisplayAspectRatio_string=" & V_DisplayAspectRatio_string & " V_DisplayAspectRatio_string_slash=" & V_DisplayAspectRatio_string_slash)
    '       Wscript.echo("A_Video_Delay_ms=" & A_Video_Delay_ms)
    '       Wscript.echo("A_Audio_Delay_ms=" & A_Audio_Delay_ms)
    Dim mi_exe
    Dim mi_cmd, mi_status, mi_tmp
    'Dim mi_temp_Filename
    If vrdtvs_DEBUG Then
        WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_get_mediainfo_parameter       mi_Section= " & mi_Section)
        WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_get_mediainfo_parameter     mi_Parameter= " & mi_Parameter)
        WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_get_mediainfo_parameter mi_MediaFilename= " & mi_MediaFilename)
        WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_get_mediainfo_parameter        mi_Legacy= " & mi_Legacy)
    End If
    If Ucase(mi_Legacy) <> Ucase("--Legacy") AND Ucase(mi_Legacy) <> "" Then
        WScript.StdOut.WriteLine("VRDTVS ERROR: vrdtvs_get_mediainfo_parameter UNRECOGNISED LEGACY PARAMETER: " & mi_Legacy & " : it should only be an empty string or --Legacy")
        ' Err.Raise 17 ' Error 17 = cannot perform the requested operation
	    WScript.Quit 17 ' Error 17 = cannot perform the requested operation
    End If
    '
    ' If piping to a temporary file, cmd looks something like this:
    ' mi_temp_Filename = vrdtvs_gimme_a_temporary_absolute_filename() ' generate a fully qualified temporary filename from the function
    ' mi_status = delete_a_file (mi_temp_Filename, True)
    ' mi_cmd =  """" & vrdtvs_mediainfoexe64 & """ " & mi_Legacy & " ""--Inform=" & mi_Section & ";%" & mi_Parameter & "%\r\n"" """ & mi_MediaFilename & """ > """ & mi_temp_Filename & """"
    '
    mi_cmd = """" & vrdtvs_mediainfoexe64 & """ " & mi_Legacy & " ""--Inform=" & mi_Section & ";%" & mi_Parameter & "%\r\n"" """ & mi_MediaFilename & """"
    If vrdtvs_DEBUG Then WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_get_mediainfo_parameter Exec command: " & mi_cmd)
    set mi_exe = wso.Exec(mi_cmd)
    Do While mi_exe.Status = 0 '0 is running and 1 is ending
        Wscript.Sleep 100
    Loop
    Do Until mi_exe.StdErr.AtEndOfStream
        mi_tmp = mi_exe.StdErr.ReadLine()
        WScript.StdOut.WriteLine("VRDTVS ERROR: vrdtvs_get_mediainfo_parameter StdErr: " & mi_tmp)
    Loop
    mi_status = mi_exe.ExitCode
    If mi_status <> 0 then
        WScript.StdOut.WriteLine("VRDTVS ERROR: vrdtvs_get_mediainfo_parameter ABORTING with Exec command: " & mi_cmd)
        WScript.StdOut.WriteLine("VRDTVS ERROR: vrdtvs_get_mediainfo_parameter ABORTING with  Exit Status: " & mi_status)
        ' Err.Raise 17 ' Error 17 = cannot perform the requested operation
	    WScript.Quit 17 ' Error 17 = cannot perform the requested operation
    End If
    mi_tmp="" ' default to nothing
    Do Until mi_exe.StdOut.AtEndOfStream ' we need to read only one line though
        mi_tmp = mi_exe.StdOut.ReadLine()
        If vrdtvs_DEBUG Then WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_get_mediainfo_parameter StdOut: " & mi_tmp)
        Exit Do ' we need to read only THE FIRST line so exit loop immediately after doing that
    Loop
    Set mi_exe = Nothing
    If vrdtvs_DEBUG Then WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_get_mediainfo_parameter exiting with value: " & mi_tmp)
    vrdtvs_get_mediainfo_parameter = mi_tmp
End Function
'
Function vrdtvs_get_ffprobe_video_stream_parameter (ffp_Parameter, ffp_MediaFilename) 
    ' rely on global variable "wso"
    ' rely on global variable vrdtvs_ffprobeexe64 exists pointing to the ffprobe exe
    ' Note \r\n is Windows new-line, which is for the case of multiple audio streams, 
    '      it outputs a result for each stream on a new line, the first stream being the first entry,
    '      and the first audio stream should be the one we need. 
    '      read the first line.
    '      see if -probesize 5000M  makes any difference
    ' Parameters:
    '   ffp_Parameter       name of parameter to fetch eg "duration"
    '   ffp_MediaFilename   fully qualified (Absolute) filename of the media file to query
    ' Call like this:
    '       dim V_Width_FF, V_Height_FF, V_Duration_s_FF, V_BitRate_FF, V_BitRate_Maximum_FF
    '       V_Width_FF = get_ffprobe_video_stream_parameter("width","G:\HDTV\000-TO-BE-PROCESSED\zzz-TEST\VRDTVS-Converted\News-ABC_Evening_News.2021-02-05.mp4")
    '       V_Height_FF = get_ffprobe_video_stream_parameter("height","G:\HDTV\000-TO-BE-PROCESSED\zzz-TEST\VRDTVS-Converted\News-ABC_Evening_News.2021-02-05.mp4")
    '       V_Duration_s_FF = get_ffprobe_video_stream_parameter("duration","G:\HDTV\000-TO-BE-PROCESSED\zzz-TEST\VRDTVS-Converted\News-ABC_Evening_News.2021-02-05.mp4")
    '       V_BitRate_FF = get_ffprobe_video_stream_parameter("bit_rate","G:\HDTV\000-TO-BE-PROCESSED\zzz-TEST\VRDTVS-Converted\News-ABC_Evening_News.2021-02-05.mp4")
    '       V_BitRate_Maximum_FF = get_ffprobe_video_stream_parameter("max_bit_rate","G:\HDTV\000-TO-BE-PROCESSED\zzz-TEST\VRDTVS-Converted\News-ABC_Evening_News.2021-02-05.mp4")
    '       Wscript.echo("V_Width_FF=" & V_Width_FF & " V_Height_FF=" & V_Height_FF)
    '       Wscript.echo("V_Duration_s_FF=" & V_Duration_s_FF)
    '       Wscript.echo("V_BitRate_FF=" & V_BitRate_FF)
    '       Wscript.echo("V_BitRate_Maximum_FF=" & V_BitRate_Maximum_FF)
    Dim ffp_exe
    Dim ffp_cmd, ffp_status, ffp_tmp
    If vrdtvs_DEBUG Then
        WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_get_ffprobe_video_stream_parameter     ffp_Parameter= " & ffp_Parameter)
        WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_get_ffprobe_video_stream_parameter ffp_MediaFilename= " & ffp_MediaFilename)
    End If
    '
    ' If piping to a temporary file, cmd looks something like this:
    ' ffp_temp_Filename = gimme_a_temporary_absolute_filename() ' generate a fully qualified temporary filename from the function
    ' ffp_status = delete_a_file (ffp_temp_Filename, True)
    ' ffp_cmd =  """" & vrdtvs_ffprobeexe64 & ???  & ffp_MediaFilename & """ > """ & ffp_temp_Filename & """"
    '
    ffp_cmd = """" & vrdtvs_ffprobeexe64 & """ -hide_banner -v quiet -select_streams v:0 -show_entries stream=" & ffp_Parameter & " -of default=noprint_wrappers=1:nokey=1 """ & ffp_MediaFilename & """"
    If vrdtvs_DEBUG Then WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_get_ffprobe_video_stream_parameter Exec command: " & ffp_cmd)
    set ffp_exe = wso.Exec(ffp_cmd)
    Do While ffp_exe.Status = 0 '0 is running and 1 is ending
        Wscript.Sleep 100
    Loop
    Do Until ffp_exe.StdErr.AtEndOfStream
        ffp_tmp = ffp_exe.StdErr.ReadLine()
        WScript.StdOut.WriteLine("VRDTVS ERROR: vrdtvs_get_ffprobe_video_stream_parameter StdErr: " & ffp_tmp)
    Loop
    ffp_status = ffp_exe.ExitCode
    If ffp_status <> 0 then
        WScript.StdOut.WriteLine("VRDTVS ERROR: vrdtvs_get_ffprobe_video_stream_parameter ABORTING with Exec command: " & ffp_cmd)
        WScript.StdOut.WriteLine("VRDTVS ERROR: vrdtvs_get_ffprobe_video_stream_parameter ABORTING with  Exit Status: " & ffp_status)
        ' Err.Raise 17 ' Error 17 = cannot perform the requested operation
	    WScript.Quit 17 ' Error 17 = cannot perform the requested operation
    End If
        ffp_tmp="" ' default to nothing
    Do Until ffp_exe.StdOut.AtEndOfStream ' we need to read only one line though
        ffp_tmp = ffp_exe.StdOut.ReadLine()
        If vrdtvs_DEBUG Then WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_get_ffprobe_video_stream_parameter StdOut: " & ffp_tmp)
     Exit Do ' we need to read only one line so exit loop immediately
    Loop
    Set ffp_exe = Nothing
    If vrdtvs_DEBUG Then WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_get_ffprobe_video_stream_parameter exiting with value: " & ffp_tmp)
    vrdtvs_get_ffprobe_video_stream_parameter = ffp_tmp
End Function
'
Function vrdtvs_remove_special_characters_from_string(rsp_string, rsp_is_an_AbsolutePath) ' treat only the "BaseName" component of an Absolute Patch and return the treated Absolute Path
    ' rely on global variable "fso"
    ' Parameters:
    '   rsp_string                  the string to Treat - ususally the "BaseName" component of a filename
    '   rsp_is_an_AbsolutePath      True if is an absolute path string, where we treat only the "BaseName" component and return the treated Absolute pathname
    ' Call like this:
    '       ????
    ' just examples of stuff for re-use in future BuildPath calls
        ' an_AbsolutePath = fso.GetAbsolutePathName(fso.BuildPath("C:\SOFTWARE\ffmpeg\0-homebuilt-x64\","MP4Box.exe"))
        ' theParentFolderName = fso.GetParentFolderName(an_AbsolutePath) ' the drive and folder name of the file without any trailing "\"
        ' theBaseName = fso.GetBaseName(an_AbsolutePath)
        ' theExtName = fso.GetExtensionName(an_AbsolutePath) ' does not include  the "."
        ' theFileName = fso.GetFileName(an_AbsolutePath) ' includes filename and "." and extension
        ' theDriveName = fso.GetDriveName(an_AbsolutePath) ' includes driver letter and ":"
        ' theParentFolderName = fso.GetParentFolderName(an_AbsolutePath) 
    Const rsp_replacement_character = "."
    Const rsp_regex_pattern = "[^a-zA-Z0-9-_. ]+"      ' ^ means not matching
    Dim rsp_RegExp
    Dim rsp_tmp, rsp_result
    Dim rsp_AbsolutePath, rsp_ParentFolderName, rsp_BaseName, rsp_ExtName
    'If vrdtvs_DEBUG Then
    '    WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_remove_special_characters_from_string             rsp_string= " & rsp_string)
    '    WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_remove_special_characters_from_string rsp_is_an_AbsolutePath= " & rsp_is_an_AbsolutePath)
    'End If
    rsp_tmp = rsp_string
    If rsp_is_an_AbsolutePath Then
        rsp_AbsolutePath = fso.GetAbsolutePathName(rsp_string)
        rsp_ParentFolderName = fso.GetParentFolderName(rsp_AbsolutePath) 
        rsp_BaseName = fso.GetBaseName(rsp_AbsolutePath)
        rsp_ExtName = fso.GetExtensionName(rsp_AbsolutePath)
        rsp_tmp = rsp_BaseName
        'If vrdtvs_DEBUG Then
        '    WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_remove_special_characters_from_string rsp_ParentFolderName= " & rsp_ParentFolderName)
        '    WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_remove_special_characters_from_string         rsp_BaseName= " & rsp_BaseName)
        '    WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_remove_special_characters_from_string          rsp_ExtName= " & rsp_ExtName)
        'End If
    End If
    Set rsp_RegExp = New RegExp
    rsp_RegExp.IgnoreCase = False
    rsp_RegExp.Global = True  
    rsp_RegExp.Pattern = rsp_regex_pattern
    rsp_result = rsp_RegExp.Replace(rsp_tmp,rsp_replacement_character) ' in this case replace all matching characters with ".", in this case all non-standard characters
    Set rsp_RegExp = Nothing
    If rsp_is_an_AbsolutePath Then
        rsp_result = fso.GetAbsolutePathName(fso.BuildPath(rsp_ParentFolderName, rsp_result & "." & rsp_ExtName))
    End If
    'If vrdtvs_DEBUG Then WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_remove_special_characters_from_string exiting with return value: " & rsp_result)
    vrdtvs_remove_special_characters_from_string = rsp_result
End Function
'
'----------------------------------------------------------------------------------------------------------------------------------------
'----------------------------------------------------------------------------------------------------------------------------------------
'----------------------------------------------------------------------------------------------------------------------------------------
'****************************************************************************************************************************************
'****************************************************************************************************************************************
'****************************************************************************************************************************************
'
Function vrdtvs_fix_filenames_in_a_folder_tree (the_folder_tree, do_subfolders_as_well) 
	' Function to traverse a folder tree ( a called function filters for file Extensions: .ts .mp4 .mpg)
	'   a) Remove special characters in filenames for file Extensions: .ts .mp4 .mpg and autofixes associated .bprj
	'   b) modify the filenames based on the filename content including reformatting the date in the filename
	' rely on global variable "fso"
    ' Parameters:
	'	the_folder_tree			the top level folder to process
    '   do_subfolders_as_well	False flags to process only the top level folder with NO SUBFOLDERS
    ' Call like this:
    '       status = vrdtvs_fix_filenames_in_a_folder_tree ("G:\HDTV\", False) 
	Dim ffiaft_folder_tree
    Dim vrdtvs_folder_object
    Dim vrdtvs_f_object
	Dim local_timerStart, local_timerEnd
	Dim local_timerStart_2, local_timerEnd_2
	local_timerStart = Timer
	local_timerEnd = Timer
	local_timerStart_2 = Timer
	local_timerEnd_2 = Timer
	'
	ffiaft_folder_tree = the_folder_tree
    If NOT fso.FolderExists(ffiaft_folder_tree) Then
	    WScript.StdOut.WriteLine("VRDTVS vrdtvs_fix_filenames_in_a_folder_tree: Folder named """ & ffiaft_folder_tree & """ does NOT EXIST ... not processed by vrdtvs_fix_filenames_in_a_folder_tree")
	    If vrdtvs_DEBUG Then WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_fix_filenames_in_a_folder_tree: Folder named """ & ffiaft_folder_tree & """ does NOT EXIST ... not processed by vrdtvs_fix_filenames_in_a_folder_tree")
        vrdtvs_fix_filenames_in_a_folder_tree = 53 ' 53 = File not found
	    Exit Function
    End If
    '
	'If vrdtvs_DEBUG Then WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_fix_filenames_in_a_folder_tree: Started basic file renames for folder tree """ & ffiaft_folder_tree & """")
	Set vrdtvs_folder_object = fso.GetFolder(ffiaft_folder_tree)            ' get an object of the specified top level folder to process
	Call vrdtvs_ffiaft_Process_Files_In_Subfolders (vrdtvs_folder_object, do_subfolders_as_well)   ' process the content (files, folders) of that specified top level folder and if specified the SUBFOLDERS too
    Set vrdtvs_folder_object = Nothing                                      ' finished, disppose of the object
	local_timerEnd = Timer
	'If vrdtvs_DEBUG Then WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_fix_filenames_in_a_folder_tree: Finished basic file renames for folder tree """ & ffiaft_folder_tree & """ with Elapsed Time " & vrdtvs_Calculate_ElapsedTime_string(local_timerStart, local_timerEnd))
    '
	local_timerEnd_2 = Timer
	'If vrdtvs_DEBUG Then 
	'	WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_fix_filenames_in_a_folder_tree: Finished all fixing for folder tree """ & ffiaft_folder_tree & """ with Elapsed Time " & vrdtvs_Calculate_ElapsedTime_string(local_timerStart_2, local_timerEnd_2))
	'End If
	vrdtvs_fix_filenames_in_a_folder_tree = 0 ' return with status 0
End Function
'
Sub vrdtvs_ffiaft_Process_Files_In_Subfolders (objSpecifiedFolder, do_subfolders_as_well) ' Process all files in specified folder tree
	' Function to Process all files in specified folder tree OBJECT with file Extensions: .ts .mp4 .mpg
	'   a) Remove special characters in filenames for file Extensions: .ts .mp4 .mpg and autofixes associated .bprj
	'   b) modify the filenames based on the filename content including reformatting the date in the filename
	'   c) *** NOT THIS, do it outside ... fix the file DateCreated and DateModified timestamps based on the date in the filename (a PowerShell command ... since DateCreated can't be modified in vbscript)
    ' rely on global variable "fso"
    ' Parameters:
	'	objSpecifiedFolder		Object from fso.GETFOLDER of the top level folder to process
    '   do_subfolders_as_well	False flags to process only the top level folder with NO SUBFOLDERS
    ' Call like this:
    '       status = vrdtvs_ffiaft_Process_Files_In_Subfolders (folder_object, False) 
	Dim objCurrentFolder, objColFiles, objSubFolder, objFile, ext
	'If vrdtvs_DEBUG Then WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_ffiaft_Process_Files_In_Subfolders: Started with incoming folder path """ & fso.GetFolder(objSpecifiedFolder.Path) & """")
    Set objCurrentFolder = fso.GetFolder(objSpecifiedFolder.Path) ' get a NEW instance of a folder object (keep for recursion)
	'If vrdtvs_DEBUG Then WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_ffiaft_Process_Files_In_Subfolders: Started with " & objCurrentFolder.Files.Count & " files in folder """ & fso.GetFolder(objSpecifiedFolder.Path) & """")
    ' Process all files in the current folder
    Set objColFiles = objCurrentFolder.Files ' get an object of a collection of files for the folder object
    For Each objFile in objColFiles
		'If vrdtvs_DEBUG Then WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_ffiaft_Process_Files_In_Subfolders: found File in collection=""" & objFile.Path & """")
        ext = UCase(fso.GetExtensionName(objFile.name))
        '********* FILTER BY FILE EXTENSION *********
		If ext = Ucase("ts") OR ext = Ucase("mp4") OR ext = Ucase("mpg") Then ' ********** only process specific file extensions
			'If vrdtvs_DEBUG Then WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_ffiaft_Process_Files_In_Subfolders: recognised Extension of file in collection=""" & objFile.Path & """ and about to call vrdtvs_ffiaft_pfis_Rename_a_File")
            Call vrdtvs_ffiaft_pfis_Rename_a_File(objFile)'  fso.GetAbsolutePathName(objFile.Path) should be the fully qualified absolute filename of this file
        End If
        '********* FILTER BY FILE EXTENSION *********
		Next
    Set objColFiles = Nothing
	If do_subfolders_as_well Then
    	' If specified, locate and recursively process subfolders of the current folder
    	For Each objSubFolder in objCurrentFolder.SubFolders
        	Call vrdtvs_ffiaft_Process_Files_In_Subfolders(objSubFolder)
    	Next
    	Set objCurrentFolder = Nothing
	End If
End Sub
'
Sub vrdtvs_ffiaft_pfis_Rename_a_File (objSpecifiedFile) 
    ' Process a specific file ... fso.GetAbsolutePathName(objSpecifiedFile.Path) should be the fully qualified absolute filename of this file
    ' Parameters:
	'		objSpecifiedFile is already pre-filtered beforehand to be one of ts mp4 mpg
    Dim theOriginalAbsoluteFilename, theOriginalParentFolderName, theOriginalBaseName, theOriginalExtName
    Dim NewBaseName, newAbsoluteFilename
	Dim Final_Renamed_AbsoluteFilename_AfterRetries, Final_Renamed_ParentFolderName, Final_Renamed_BaseName, Final_Renamed_ExtName
	Dim Original_BPRJ_AbsoluteFilename, Final_Renamed_BPRJ_AbsoluteFilename, bprj_status, bprj_objErr, bprj_errorCode, bprj_reason
	Dim vrdtvs_xmlDoc
	Dim local_timerStart, local_timerEnd
	local_timerStart = Timer
	local_timerEnd = Timer
    theOriginalAbsoluteFilename = fso.GetAbsolutePathName(objSpecifiedFile.Path) ' should already be fully qualified but do it anyway just to be safe
    theOriginalParentFolderName = fso.GetParentFolderName(theOriginalAbsoluteFilename)
    theOriginalBaseName = fso.GetBaseName(theOriginalAbsoluteFilename)
    theOriginalExtName = fso.GetExtensionName(theOriginalAbsoluteFilename) ' does not include  the "."
    '
    'If vrdtvs_DEBUG Then WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_ffiaft_pfis_Rename_a_File: entered Sub with original BaseName """ & theOriginalBaseName & """ from """ & theOriginalAbsoluteFilename & """")
    NewBaseName = theOriginalBaseName ' initialize so we can keep the original stuff if we need i in the future
    NewBaseName = vrdtvs_remove_special_characters_from_string(NewBaseName, False) ' flag is not an Absolute filename by passing False to the function
    'If vrdtvs_DEBUG Then WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_ffiaft_pfis_Rename_a_File: after vrdtvs_remove_special_characters_from_string original BaseName """ & theOriginalBaseName & """ NewBaseName """ & NewBaseName & """")
    NewBaseName = vrdtvs_remove_tvs_classifying_stuff_from_string(NewBaseName)
    'If vrdtvs_DEBUG Then WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_ffiaft_pfis_Rename_a_File: after vrdtvs_remove_tvs_classifying_stuff_from_string original BaseName """ & theOriginalBaseName & """ NewBaseName """ & NewBaseName & """")
    NewBaseName = vrdtvs_Move_Date_to_End_of_String(NewBaseName)
    'If vrdtvs_DEBUG Then WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_ffiaft_pfis_Rename_a_File: after vrdtvs_Move_Date_to_End_of_String original BaseName """ & theOriginalBaseName & """ NewBaseName """ & NewBaseName & """")
	'
	'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	newAbsoluteFilename = fso.GetAbsolutePathName(fso.BuildPath(theOriginalParentFolderName,NewBaseName & "." & theOriginalExtName))
	if ucase(NewBaseName) = Ucase(theOriginalBaseName) Then ' no change to filename
		WScript.StdOut.WriteLine("VRDTVS vrdtvs_ffiaft_pfis_Rename_a_File: ---- <" & theOriginalAbsoluteFilename & "> ---- NO NEED for a Rename" )
		If vrdtvs_DEBUG Then 
		'	WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_ffiaft_pfis_Rename_a_File: NO NEED for a Rename, no change: theOriginalBaseName=""" & theOriginalBaseName & """" )
		'	WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_ffiaft_pfis_Rename_a_File: NO NEED for a Rename, no change: theOriginalAbsoluteFilename=""" & theOriginalAbsoluteFilename & """" )
		End If
	Else ' is a change to the filename
		If vrdtvs_DEBUG Then 
			'WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_ffiaft_pfis_Rename_a_File: needs a Rename using theOriginalBaseName=""" & theOriginalBaseName & """" )
			'WScript.StdOut.WriteLine("                                                                       NewBaseName=""" & NewBaseName & """" )
			'WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_ffiaft_pfis_Rename_a_File: needs a Rename using theOriginalAbsoluteFilename=""" & theOriginalAbsoluteFilename & """" )
			'WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_ffiaft_pfis_Rename_a_File:                              newAbsoluteFilename=""" & newAbsoluteFilename & """" )
		End If
		Final_Renamed_AbsoluteFilename_AfterRetries = vrdtvs_do_a_Try99Times_Rename(theOriginalAbsoluteFilename, newAbsoluteFilename) ' AUTOFIXING a .BPRJ OCCURS AFTER THIS FUNCTION
		If Final_Renamed_AbsoluteFilename_AfterRetries = "" Then
			' Silly Error detected here, it should never occur unless we have some sort of logic issue ;)
			WScript.StdOut.WriteLine("VRDTVS ERROR: vrdtvs_ffiaft_pfis_Rename_a_File ABORTING: Final_Renamed_AbsoluteFilename_AfterRetries is not properly set after vrdtvs_do_a_Try99Times_Rename <" & Final_Renamed_AbsoluteFilename_AfterRetries & ">")
			Wscript.Quit 17
		End If
		Final_Renamed_ParentFolderName = fso.GetParentFolderName(Final_Renamed_AbsoluteFilename_AfterRetries)
		Final_Renamed_BaseName = fso.GetBaseName(Final_Renamed_AbsoluteFilename_AfterRetries)
		Final_Renamed_ExtName = fso.GetExtensionName(Final_Renamed_AbsoluteFilename_AfterRetries) ' does not include  the "."



		... ??? copied legacy code conversion  in progress ...
		'???????????????????????????????????? ALSO taking care of editing and rewriting the content .bprj files (which are just XML files) ... test for Ucase(theExtName) = Ucase("bprj")
		Original_BPRJ_AbsoluteFilename = fso.GetAbsolutePathName( fso.BuildPath(theOriginalParentFolderName,theOriginalBaseName & ".bprj")
		Final_Renamed_BPRJ_AbsoluteFilename = fso.GetAbsolutePathName( fso.BuildPath(Final_Renamed_ParentFolderName,Final_Renamed_BaseName & ".bprj")
		
		If fso.FileExists(Original_BPRJ_AbsoluteFilename) Then 
			' yeppity, a matching .bprj file found for the original media filename, 
			If vrdtvs_DEBUG Then WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_ffiaft_pfis_Rename_a_File: found a matching .bprj file to autofix: """ & Original_BPRJ_AbsoluteFilename & """")
		
???????????????????????????????????????????????????
			' a) rename the .bprj file to match the new BaseName of the media file ... abort on a failure to simply rename the .bprj file

			 do the rename in here

			' b) process/fix the content of .bprj file (it's xml) so the media filename in it is updated to match the renamed media filename


			' load the file Final_Renamed_BPRJ_AbsoluteFilename and replace the file part with Final_Renamed_BaseName in it
			Set vrdtvs_xmlDoc = CreateObject("Microsoft.XMLDOM")
			vrdtvs_xmlDoc.async = False
			on error resume next 
			If vrdtvs_DEBUG Then WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_ffiaft_pfis_Rename_a_File: about to vrdtvs_xmlDoc.load file """ & Final_Renamed_BPRJ_AbsoluteFilename & """")
			bprj_status = vrdtvs_xmlDoc.load(Final_Renamed_BPRJ_AbsoluteFilename) '???????????????????????????????????????????????????????????????????????????????????????????????
			Set bprj_objErr = vrdtvs_xmlDoc.parseError
			bprj_errorCode = bprj_objErr.errorCode
			bprj_reason = bprj_objErr.reason
			Err.clear
			on error goto 0 
			If not bprj_status Then
				WScript.StdOut.WriteLine("VRDTVS ERROR: vrdtvs_ffiaft_pfis_Rename_a_File ABORTING: Failed to load XML doc .BPRJ file """ & Final_Renamed_BPRJ_AbsoluteFilename & """")
				WScript.StdOut.WriteLine("VRDTVS ERROR: vrdtvs_ffiaft_pfis_Rename_a_File ABORTING: XML error: " & bprj_errorCode & " : " &bprj_reason
				Wscript.Quit 17
			End If
			'WScript.StdOut.WriteLine "vbs_rename_files: debug: loaded xml doc " & new_name
			'Locate the desired node. Note the use of XPATH instead of looping over all the child nodes.
			Set nNode = vrdtvs_xmlDoc.selectsinglenode ("//VideoReDoProject/Filename")
			If nNode is Nothing then
				WScript.StdOut.WriteLine "vbs_rename_files: Aborted. Could not find XML node //VideoReDoProject/Filename in file " & new_name
				WScript.quit 1 ' exit with an error ... soft or hard ?
			End If
			??? this looks like it is using foldername ".\" so ... do we stay that way ?
			txtbefore = nNode.text
			' find the rightmost \ then replace everything at and it to the start with .\
			' if a \ doesn't exist, add .\ to the start
			i = InStrRev(txtbefore,"\",-1,vbTextCompare)
			if i > 0 then
				txtafter = ".\" & mid(txtbefore,i+1)
			else
				txtafter = ".\" & txtbefore
			end if
			' replace the xbasename portion of the string with the new_basename portion
			txtafter = Replace(txtafter, xbasename, new_basename, 1, -1, vbTextCompare)
			nNode.text = txtafter
			WScript.StdOut.WriteLine "vbs_rename_files: Update bprj xml node before:<" & txtbefore & ">"
			WScript.StdOut.WriteLine "vbs_rename_files:                       after:<" & nNode.text & ">"
			vrdtvs_xmlDoc.save(Final_Renamed_BPRJ_AbsoluteFilename) '???????????????????????????????????????????????????????????????????????????????????????????????
			Set vrdtvs_xmlDoc = Nothing
    	'???????????????????????????????????? ALSO taking care of editing and rewriting the content .bprj files (which are just XML files) ... test for Ucase(theExtName) = Ucase("bprj")






	End If
	'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	'
	local_timerEnd = Timer
    'If vrdtvs_DEBUG Then 
	'	WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_ffiaft_pfis_Rename_a_File: Exit having Elapsed Time " & vrdtvs_Calculate_ElapsedTime_string(local_timerStart, local_timerEnd))
	'End If
	' vrdtvs_ffiaft_pfis_Rename_a_File is a Sub, hence no return values
End Sub
'
Function vrdtvs_do_a_Try99Times_Rename(OriginalAbsoluteFilename, TargetAbsoluteFilename)
	' Try to rename a file and re-Rename it if required, trying up to 99 times
	' Cater "file already exists" and loop try up to 100 times to add a 2 digit number ".00" to ".99" to the end of NewBaseName if needed fail to failure folder ?
	' Taking care of editing and rewriting the content .bprj files (which are just XML files) ... test for Ucase(theExtName) = Ucase("bprj")
    ' Parameters:
	'		theOriginalAbsoluteFilename		source filename
	'		theTargetAbsoluteFilename		target filename
	Const vrdtvs_t99tr_MaxReTries = 99
	Const theLeadingCharacterForRetries = "_"
	Dim theOriginalAbsoluteFilename, theOriginalParentFolderName, theOriginalBaseName, theOriginalExtName
	Dim theTargetAbsoluteFilename, theTargetParentFolderName, theTargetBaseName, theTargetExtName
	Dim saved_theTargetAbsoluteFilename, saved_theTargetParentFolderName, saved_theTargetBaseName, saved_theTargetExtName
	Dim vrdtvs_t99tr_ErrNo, vrdtvs_t99tr_ErrDescription, vrdtvs_t99tr_ErrCount
	Dim local_timerStart, local_timerEnd
	local_timerStart = Timer
	local_timerEnd = Timer
	If vrdtvs_DEBUG Then
		'WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_do_a_Try99Times_Rename:  incoming Original filename <" & OriginalAbsoluteFilename & ">")
		'WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_do_a_Try99Times_Rename:    incoming Target filename <" & TargetAbsoluteFilename & ">")
	End If
    theOriginalAbsoluteFilename = fso.GetAbsolutePathName(OriginalAbsoluteFilename) ' should already be fully qualified but do it anyway just to be safe
    theOriginalParentFolderName = fso.GetParentFolderName(theOriginalAbsoluteFilename)
    theOriginalBaseName = fso.GetBaseName(theOriginalAbsoluteFilename)
    theOriginalExtName = fso.GetExtensionName(theOriginalAbsoluteFilename) ' does not include  the "."
	theTargetAbsoluteFilename = fso.GetAbsolutePathName(TargetAbsoluteFilename) ' should already be fully qualified but do it anyway just to be safe
    theTargetParentFolderName = fso.GetParentFolderName(theTargetAbsoluteFilename)
    theTargetBaseName = fso.GetBaseName(theTargetAbsoluteFilename)
    theTargetExtName = fso.GetExtensionName(theTargetAbsoluteFilename) ' does not include  the "."
	saved_theTargetAbsoluteFilename = theTargetAbsoluteFilename
    saved_theTargetParentFolderName = theTargetParentFolderName
    saved_theTargetBaseName = theTargetBaseName
    saved_theTargetExtName = theTargetExtName ' does not include  the "."
	' the last part of the basename should be: theLeadingReplaceCharacter_ForMovingDates & "yyyy.mm.dd" ... eg like ".2021.02.05"
	' if it is not like that, then the filename does not contain a date at the end of the basename
	vrdtvs_t99tr_ErrNo = 0
	vrdtvs_t99tr_ErrDescription=""
	vrdtvs_t99tr_ErrCount = 0
	WScript.StdOut.WriteLine("VRDTVS vrdtvs_do_a_Try99Times_Rename:  rename <" & theOriginalAbsoluteFilename & ">")
	WScript.StdOut.WriteLine("VRDTVS vrdtvs_do_a_Try99Times_Rename:      to <" & theTargetAbsoluteFilename & ">")
	on error resume next
	If vrdtvs_DEVELOPMENT_NO_ACTIONS Then ' DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV 
		'WScript.StdOut.WriteLine("VRDTVS vrdtvs_DEVELOPMENT_NO_ACTIONS: DEV: vrdtvs_do_a_Try99Times_Rename NOT DOING 'fso.MoveFile theOriginalAbsoluteFilename, theTargetAbsoluteFilename'")
	Else
		fso.MoveFile theOriginalAbsoluteFilename, theTargetAbsoluteFilename ' this is the actual File Rename
	End If
	vrdtvs_t99tr_ErrNo = Err.Number
	vrdtvs_t99tr_ErrDescription = Err.Description
	Err.Clear
	on error goto 0
	If vrdtvs_t99tr_ErrNo = 0 Then
		' successful rename ... debug statement here please
	ElseIf vrdtvs_t99tr_ErrNo <> 58 Then ' catch any non-0 non-58 error and abort
		WScript.StdOut.WriteLine("VRDTVS ERROR: vrdtvs_do_a_Try99Times_Rename ABORTING: error " & vrdtvs_t99tr_ErrNo & " " & vrdtvs_t99tr_ErrDescription & " ... ABORTING since vbscript non-error-58 was detected at first attempt")
		Wscript.Quit 17 ' vrdtvs_t99tr_ErrNo
		vrdtvs_do_a_Try99Times_Rename = ""
		Exit Function
	Else ' if it gets to here then it MUST be error 58 = File already exists ... meaning we must re-try up to vrdtvs_t99tr_MaxReTries times
		vrdtvs_t99tr_ErrCount = 0
		vrdtvs_t99tr_ErrNo = 58 ' should already be 58 but set it anyway
		While (vrdtvs_t99tr_ErrNo = 58 AND vrdtvs_t99tr_ErrCount < vrdtvs_t99tr_MaxReTries) ' only vrdtvs_t99tr_MaxReTries number of retries
			vrdtvs_t99tr_ErrCount = vrdtvs_t99tr_ErrCount + 1
			theTargetBaseName = vrdtvs_Move_Date_to_End_of_String(saved_theTargetBaseName & theLeadingCharacterForRetries & vrdtvs_Digits2(vrdtvs_t99tr_ErrCount)) ' REMEMBER TO RE-PUT THE DATE BACK ON THE END OF THE FILENAME STRING
			theTargetAbsoluteFilename =  fso.GetAbsolutePathName(fso.BuildPath(saved_theTargetParentFolderName, theTargetBaseName & "." & saved_theTargetExtName))
			WScript.StdOut.WriteLine("VRDTVS vrdtvs_do_a_Try99Times_Rename:   Retry <" & theTargetAbsoluteFilename & "> Attempt " & vrdtvs_Digits2(vrdtvs_t99tr_ErrCount))
			on error resume next
			If vrdtvs_DEVELOPMENT_NO_ACTIONS Then ' DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV 
				'WScript.StdOut.WriteLine("VRDTVS vrdtvs_DEVELOPMENT_NO_ACTIONS: DEV: vrdtvs_do_a_Try99Times_Rename retry NOT DOING 'fso.MoveFile theOriginalAbsoluteFilename, theTargetAbsoluteFilename'")
			Else
				fso.MoveFile theOriginalAbsoluteFilename, theTargetAbsoluteFilename ' this is the actual File Rename and theTargetAbsoluteFilename contains an updated Absolte filename to use
			End If
			vrdtvs_t99tr_ErrNo = Err.Number
			vrdtvs_t99tr_ErrDescription = Err.Description
			Err.Clear
			on error goto 0
			If (vrdtvs_t99tr_ErrNo <> 0 AND vrdtvs_t99tr_ErrNo <> 58) Then ' catch any non-0 non-58 error and abort ... it catches everything like that before a Wend
				WScript.StdOut.WriteLine("VRDTVS ERROR: vrdtvs_do_a_Try99Times_Rename ABORTING: error " & vrdtvs_t99tr_ErrNo & " " & vrdtvs_t99tr_ErrDescription & " ... ABORTING since vbscript non-error-58 was detected during retries")
				Wscript.Quit 17 ' vrdtvs_t99tr_ErrNo
				vrdtvs_do_a_Try99Times_Rename = ""
				Exit Function
			End If
		Wend ' should Wend on non-58 error number (including 0) or reached max retries
		If (vrdtvs_t99tr_ErrNo = 58 and vrdtvs_t99tr_ErrCount >= vrdtvs_t99tr_MaxReTries) Then ' Error 0 is OK and doesn't get caught by this test
			WScript.StdOut.WriteLine("VRDTVS ERROR: vrdtvs_do_a_Try99Times_Rename ABORTING: error " & vrdtvs_t99tr_ErrNo & " - ABORTING since done " & vrdtvs_t99tr_ErrCount & " retries and still detected error-58 File already exists")
			Wscript.Quit 17 ' vrdtvs_t99tr_ErrNo
			vrdtvs_do_a_Try99Times_Rename = ""
			Exit Function
		End If
	End If
	on error goto 0
	vrdtvs_do_a_Try99Times_Rename = theTargetAbsoluteFilename ' Final Renamed AbsoluteFilename After Retries
End Function
'
Function vrdtvs_remove_tvs_classifying_stuff_from_string (theOriginalString)
    ' remove stuff in the string which was previously added by TVSchedulerPro, eg "Movie-" etc etc etc
    ' Parameters:
	'		theOriginalString	the string to be "fixed" ... it is usually the fso.BaseName of the file
	Dim xyear, std_year, ss, se, findme, theNewString
	Dim searchformeArray(3)
    searchformeArray(0)="-"
	searchformeArray(1)="_"
	searchformeArray(2)="."
	searchformeArray(3)=" "
	theNewString = theOriginalString ' start with the original string
	theNewString = Replace(theNewString, " ", "_", 1, -1, vbTextCompare) ' replace spaces with underscores ... so, Remember we've done this !
	' search for a year with a combination of leading and trailing characters and replace with a standard formatted year
	for xyear = 2017 to 2040 ' too lazy to figure out a regex to do this 
		std_year = "." & xyear & "-"
		For Each ss In searchformeArray
			For Each se In searchformeArray
                findme = ss & xyear & se
				theNewString = Replace(theNewString, findme, std_year, 1, -1, vbTextCompare)
			Next
		Next
	next
	' replace legacy stuff at the middle and end of a string
	theNewString = Replace(theNewString, ".h264.", ".", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, ".h265.", ".", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, ".aac.", ".", 1, -1, vbTextCompare)
	theNewString = vrdtvs_ReplaceEndStringCaseIndependent(theNewString, ".h264", "")
	theNewString = vrdtvs_ReplaceEndStringCaseIndependent(theNewString, ".h265", "")
	theNewString = vrdtvs_ReplaceEndStringCaseIndependent(theNewString, ".aac", "")
	'
	' THIS NEXT LEGACY CODE ALL IN A SPECIAL ORDER !  YUK.
	' DO NOT CHANGE THE ORDER OF THE STATEMENTS
	'
	theNewString = Replace(theNewString, "[", "_", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "]", "_", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "(", "_", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, ")", "_", 1, -1, vbTextCompare)
	'
	theNewString = Replace(theNewString, "_-_", "-", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "-_", "-", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "_-", "-", 1, -1, vbTextCompare)
	'
	theNewString = Replace(theNewString, "__", "_", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "__", "_", 1, -1, vbTextCompare) ' yes again to catch all  replaces
	theNewString = Replace(theNewString, "__", "_", 1, -1, vbTextCompare) ' yes again to catch all  replaces
	theNewString = Replace(theNewString, "__", "_", 1, -1, vbTextCompare) ' yes again to catch all  replaces
	theNewString = Replace(theNewString, "__", "_", 1, -1, vbTextCompare) ' yes again to catch all  replaces

	theNewString = Replace(theNewString, "--", "-", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "--", "-", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "--", "-", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "--", "-", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "--", "-", 1, -1, vbTextCompare)
	'
	theNewString = Replace(theNewString, "..", ".", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "..", ".", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "..", ".", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "..", ".", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "..", ".", 1, -1, vbTextCompare)
	'
	' BELOW IS ALL LEGACY CODE ... too lazy to change it
	'
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie_Movie_", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie_", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "_Movie", "-Movie")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Action-Adventure-Comedy_", "Action-Adventure-Comedy-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Action-Adventure-Crime-Movie_", "Action-Adventure-Crime-Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Action-Adventure-Fantasy-Movie_", "Action-Adventure-Fantasy-Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Action-Adventure-Movie-Sci-Fi_", "Action-Adventure-Movie-Sci-Fi-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Action-Drama-Movie-Thriller_", "Action-Drama-Movie-Thriller-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Action-Drama-Movie-Thriller_", "Action-Drama-Movie-Thriller-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Action-Fantasy-Movie_", "Action-Fantasy-Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Action-Fantasy-Movie-Sci-Fi_", "Action-Fantasy-Movie-Sci-Fi-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Action-Movie-Thriller_", "Action-Movie-Thriller-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Adventure-Animation-Children-Entertainment_", "Adventure-Animation-Children-Entertainment-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Adventure-Family-Fantasy-Movie_", "Adventure-Family-Fantasy-Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Adventure-Movie_", "Adventure-Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Animation-Comedy-Family-Movie_", "Animation-Comedy-Family-Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Arts-Culture-Biography-Drama-Historical-Movie-Romance_", "Arts-Culture-Biography-Drama-Historical-Movie-Romance-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Arts-Culture-Documentary-Historical-Nature-Society-Culture-Travel_", "Arts-Culture-Documentary-Historical-Nature-Society-Culture-Travel-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Arts-Culture-Documentary-Historical-Society-Culture_", "Arts-Culture-Documentary-Historical-Society-Culture-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Arts-Culture-Drama-Movie_", "Arts-Culture-Drama-Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Biography-Comedy-Drama-Movie_", "Biography-Comedy-Drama-Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Biography-Documentary-Historical_", "Biography-Documentary-Historical-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Biography-Documentary-Historical-Mystery_", "Biography-Documentary-Historical-Mystery-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Biography-Documentary-Historical-Society-Culture_", "Biography-Documentary-Historical-Society-Culture-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Biography-Documentary-Music_", "Biography-Documentary-Music-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Biography-Drama-Historical_", "Biography-Drama-Historical-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Biography-Drama-Movie_", "Biography-Drama-Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Biography-Drama-Movie-Romance_", "Biography-Drama-Movie-Romance-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Children_", "Children-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Comedy_", "Comedy-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Comedy-Dance-Movie-Romance_", "Comedy-Dance-Movie-Romance-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Comedy-Drama-Fantasy-Movie-Romance_", "Comedy-Drama-Fantasy-Movie-Romance-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Comedy-Drama-Movie_", "Comedy-Drama-Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Comedy-Drama-Music_", "Comedy-Drama-Music-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Comedy-Family-Movie_", "Comedy-Family-Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Comedy-Family-Movie-Romance_", "Comedy-Family-Movie-Romance-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Comedy-Horror-Movie_", "Comedy-Horror-Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Comedy-Movie_", "Comedy-Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Comedy-Movie-Romance_", "Comedy-Movie-Romance-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Crime-Drama_", "Crime-Drama-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Crime-Drama-Murder-Mystery_", "Crime-Drama-Murder-Mystery-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Crime-Drama-Mystery_", "Crime-Drama-Mystery-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Current_", "Current-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Documentary_", "Documentary-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Documentary-Entertainment-Historical-Travel_", "Documentary-Entertainment-Historical-Travel-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Documentary-Historical_", "Documentary-Historical-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Documentary-Historical-Mini_", "Documentary-Historical-Mini-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Documentary-Historical-Mystery_", "Documentary-Historical-Mystery-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Documentary-Historical-War_", "Documentary-Historical-War-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Documentary-Medical-Science-Tech_", "Documentary-Medical-Science-Tech-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Documentary-Nature_", "Documentary-Nature-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Documentary-Science-Tech-Society-Culture_", "Documentary-Science-Tech-Society-Culture-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Documentary-Science-Tech-Travel_", "Documentary-Science-Tech-Travel-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Documentary-Society-Culture_", "Documentary-Society-Culture-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Drama_", "Drama-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Drama-Family-Movie_", "Drama-Family-Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Drama-Fantasy-Mystery_", "Drama-Fantasy-Mystery-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Drama-Historical_", "Drama-Historical-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Drama-Historical-Movie-Romance_", "Drama-Historical-Movie-Romance-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Drama-Horror-Movie-Mystery_", "Drama-Horror-Movie-Mystery-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Drama-Movie_", "Drama-Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Drama-Movie-Music-Romance_", "Drama-Movie-Music-Romance-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Drama-Movie-Mystery-Romance_", "Drama-Movie-Mystery-Romance-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Drama-Movie-Mystery-Sci-Fi_", "Drama-Movie-Mystery-Sci-Fi-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Drama-Movie-Romance_", "Drama-Movie-Romance-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Drama-Movie-Sci-Fi-Thriller_", "Drama-Movie-Sci-Fi-Thriller-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Drama-Movie-Thriller_", "Drama-Movie-Thriller-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Drama-Movie-Violence_", "Drama-Movie-Violence-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Drama-Murder-Mystery_", "Drama-Murder-Mystery-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Drama-Mystery_", "Drama-Mystery-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Drama-Mystery-Sci-Fi_", "Drama-Mystery-Sci-Fi-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Drama-Mystery-Violence_", "Drama-Mystery-Violence-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Drama-Romance-Sci-Fi_", "Drama-Romance-Sci-Fi-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Drama-Thriller_", "Drama-Thriller-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Education-Science_", "Education-Science-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Education-Science-Tech_", "Education-Science-Tech-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Entertainment_", "Entertainment-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Entertainment-Real_", "Entertainment-Real-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Horror-Movie_", "Horror-Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Infotainment-Real_", "Infotainment-Real-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Lifestyle-Medical-Science-Tech_", "Lifestyle-Medical-Science-Tech-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie_", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Mystery_", "Movie-Mystery-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Sci-Fi_", "Movie-Sci-Fi-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Sci-Fi-Thriller_", "Movie-Sci-Fi-Thriller-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Sci-Fi-Western_", "Movie-Sci-Fi-Western-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Thriller_", "Movie-Thriller-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Western_", "Movie-Western-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Sci-Fi_", "Sci-Fi-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Travel_", "Travel-")
    '    
	theNewString = Replace(theNewString, "-44_Adelaide", "", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "_44_Adelaide", "", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "-SBS_ONE_HD", "", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "_SBS_ONE_HD", "", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "-SBS_VICELAND_HD", "", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "_SBS_VICELAND_HD", "", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "-SBS_World_Movies", "", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "_SBS_World_Movies", "", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "-ABC_HD", "", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "_ABC_HD", "", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "-ABC_ME", "", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "_ABC_ME", "", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "-ABCKids-Kids", "", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "_ABCKids-Kids", "", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "-ABC-Kids", "", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "_ABC-Kids", "", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "-ABCKids", "", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "_ABCKids", "", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "-ABCComedy-Kids", "", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "_ABCComedy-Kids", "", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "-ABC_COMEDY", "", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "_ABC_COMEDY", "", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "-ABC_NEWS", "", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "_ABC_NEWS", "", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "-9Gem_HD_Adelaide", "", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "_9Gem_HD_Adelaide", "", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "-9Gem", "", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "_9Gem", "", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "-9HD_Adelaide", "", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "_9HD_Adelaide", "", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "-9HD", "", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "_9HD", "", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "-9Go-", "", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "_9Go-", "", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "-9Life", "", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "_9Life", "", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "-9Rush_Adelaide", "", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "_9Rush_Adelaide", "", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "-10_HD_Adelaide", "", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "_10_HD_Adelaide", "", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "-10_HD", "", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "_10_HD", "", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "-10_BOLD", "", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "_10_BOLD", "", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "-10_Peach", "", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "_10_Peach", "", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "-10_Shake", "", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "_10_Shake", "", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "-TEN_HD", "", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "_TEN_HD", "", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "-7TWO_Adelaide", "", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "_7TWO_Adelaide", "", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "-7flix_Adelaide", "", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "_7flix_Adelaide", "", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "-7HD_Adelaide", "", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "_7HD_Adelaide", "", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "-7HD", "", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "_7HD", "", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "-7mate_Adelaide", "", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "_7mate_Adelaide", "", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "-7mateHD_Adelaide", "", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "_7mateHD_Adelaide", "", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "-7mateHD", "", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "_7mateHD", "", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "-NITV", "", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "_NITV", "", 1, -1, vbTextCompare)
	'
	theNewString = Replace(theNewString, "-HD_Adelaide", "", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "_HD_Adelaide", "", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "_Adelaide.", ".", 1, -1, vbTextCompare)
	'
	theNewString = Replace(theNewString, "Movie-Movie", "Movie", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "Sci-Fi_Movie", "Sci-Fi-Movie", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "Movie-Sci-Fi-Movie", "Movie-Sci-Fi", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "Movie-Thriller-Movie", "Movie-Thriller", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "Western-Movie", "Western", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "Western Movie", "Western", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "Romance-Movie", "Romance", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "Romance Movie", "Romance", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "Thriller-Movie", "Thriller", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "Thriller_Movie", "Thriller", 1, -1, vbTextCompare)
	'
	theNewString = Replace(theNewString, "-Movie_Movie-", "-Movie-", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "-Movie_Movie-", "-Movie-", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "-Movie-Movie-", "-Movie-", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "-Movie-_", "-Movie-", 1, -1, vbTextCompare)
	'
	theNewString = Replace(theNewString, "Agatha_Christie-s_Poirot_", "Agatha_Christie-s_Poirot-", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "Murder-Mystery_Agatha_Christie-s_Poirot_", "Agatha_Christie-s_Poirot-", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "Murder-Mystery_Agatha_Christie-s_Poirot-", "Agatha_Christie-s_Poirot-", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "Back_Roads_", "Back_Roads-", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "Catalyst_", "Catalyst-", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "Tech_Catalyst_", "Catalyst-", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "Tech_Catalyst-", "Catalyst-", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "Berlin_Station_", "Berlin_Station-", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "Foyle-s_War_", "Foyle-s_War-", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "Killing_Eve_", "Killing_Eve-", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "Medici-Masters_Of_Florence_", "Medici-Masters_Of_Florence-", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "Mistresses_", "Mistresses-", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "Orphan_Black_", "Orphan_Black-", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "Plebs_", "Plebs-", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "Pope-The_Most_Powerful_Man_In_History_", "Pope-The_Most_Powerful_Man_In_History-", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "Scandal_", "Scandal-", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "Star_Trek_", "Star_Trek-", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "The.Expanse_", "The.Expanse-", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "The_Expanse_", "The_Expanse-", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "The_Girlfriend_Experience_", "The_Girlfriend_Experience-", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "The_Inspector_Lynley_Mysteries_", "The_Inspector_Lynley_Mysteries-", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "The_IT_Crowd_", "The_IT_Crowd-", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "the.it.crowd.", "The_IT_Crowd-", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "The_Young_Pope_", "The_Young_Pope-", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "The_Two_Ronnies_", "The_Two_Ronnies-", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "The_Games_", "The_Games-", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "Utopia_", "Utopia-", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "The_X-Files_", "The_X-Files-", 1, -1, vbTextCompare)
	'
	If instr(1, theNewString, "-Movie-", vbTextCompare) > 0 then ' move "movie" to the front of the string
		theNewString = "Movie-" & Replace(theNewString, "-Movie-", "-", 1, -1, vbTextCompare)
	End If
	'
	' Replace stuff at the start of the string
	'
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Adventure-Nature_", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Action-Adventure-Comedy-", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Action-Adventure-Drama_", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Action-Drama-Sci-Fi_", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Action-Drama_", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Adult-Crime-Drama-Society-Culture-", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Adult-Documentary-Real_Life-Society-Culture-", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Adventure-Cult-Sci-Fi_", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Adventure-Animation-Children-Entertainment-","")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Adventure-Documentary-Drama-Sci-Fi-Science-", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Adventure-Entertainment-Travel-", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Animation-Children-", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Arts-Culture-Documentary-Historical-Nature-Society-Culture-Travel-", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Arts-Culture-Documentary-Historical-Society-Culture-", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Arts-Culture-Entertainment-", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Biography-Documentary-Historical-", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Children-", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Comedy-", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Comedy_", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Cooking-", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Crime-Documentary-Historical-Mini_Series-Religion-Society-Culture_", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Crime-Documentary-Historical-Mini_Series-Religion-Society-Culture-", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Crime-Drama-Murder-Mystery-", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Crime-Drama-Mystery-", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Crime-Drama-Thriller_", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Crime-Drama-", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Crime-Drama_", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Crime-Mystery_", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Crime_", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Current-Affairs-Documentary_", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Documentary-Entertainment-Historical-Travel-", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Documentary-Entertainment-", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Documentary-Historical-", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Documentary-Historical-Mystery-", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Documentary-Historical-Religion-Society-Culture_", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Documentary-Historical-Science-Tech-Society-Culture-", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Documentary-Historical-Travel_", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Documentary-Historical-War-", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Documentary-Infotainment-", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Documentary-Medical-", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Documentary-Nature-Society-Culture-Travel-", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Documentary-Nature-", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Documentary-Real_Life-Society-Culture_", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Documentary-Science-Tech-Society-Culture-", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Documentary-Science-Tech-Travel-", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Documentary-Science-Tech_", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Documentary-Science-", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Documentary-Travel_", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Documentary-", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Drama-Murder-Mystery-", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Drama-Historical-Mystery-Sci-Fi-Thriller_", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Drama-Historical-", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Drama-Mystery-Sci-Fi-", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Drama-Mystery-", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Drama-Romance-Sci-Fi-", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Drama-Romance_", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Drama-Sci-Fi-Thriller_", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Drama-Thriller-", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Drama-", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Drama_", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Education-Entertainment-Game_Show-", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Education-Science-Tech-", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Education-Science-", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Education-Science_", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Entertainment-", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Family_Movie-", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Historical-Travel-", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Historical-Travel_", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Historical-Infotainment-Lifestyle-Real_Life-Society-Culture-", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Historical-Infotainment-Lifestyle-Real_Life-Society-Culture_", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Lifestyle-Medical-Science-Tech-", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Action-Adventure-Animation-", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Action-Adventure-Comedy-Sci-Fi-", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Action-Adventure-Comedy-", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Action-Adventure-Crime-Drama-", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Action-Adventure-Crime-", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Action-Adventure-Drama-Romance-", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Action-Adventure-Drama-", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Action-Adventure-Family-", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Action-Adventure-Fantasy-", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Action-Adventure-Historical-Sci-Fi-", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Action-Adventure-Mystery-", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Action-Adventure-Sci-Fi-", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Action-Adventure-", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Action-Comedy-", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Action-Crime-", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Action-Drama-Historical-", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Action-Drama-", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Action-Drama-Sci-Fi-", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Action-Drama-Thriller-", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Action-Drama-Western-", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Action-Fantasy-Sci-Fi-", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Action-Fantasy-", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Action-Horror-Sci-Fi-Thriller-", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Action-Sci-Fi-Thriller-", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Action-Sci-Fi-", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Action-Thriller-", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Action-", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Adventure-Animation-", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Adventure-Biography-Drama-", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Adventure-Children-Family-Sci-Fi-", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Adventure-Comedy-Drama-Romance-", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Adventure-Comedy-Drama-", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Adventure-Drama-Fantasy-", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Adventure-Drama-Historical-Romance-", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Adventure-Drama-Sci-Fi-", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Adventure-Family-Fantasy-", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Adventure-Fantasy-", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Adventure-Sci-Fi-", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Adventure-", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Animation-Children-Comedy-", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Animation-Comedy-Family-", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Animation-", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Arts-Culture-Biography-Drama-Historical-Romance-", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Arts-Culture-Drama-War_Movie-", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Arts-Culture-Drama-", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Biography-Comedy-Drama-", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Biography-Documentary-", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Biography-Drama-Historical-", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Biography-Drama-Romance-", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Biography-Drama-", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Biography-", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Children-Family-", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Comedy-Crime-", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Comedy-Dance-Romance-", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Comedy-Drama-Family-", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Comedy-Drama-Fantasy-", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Comedy-Drama-Fantasy-Romance-", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Comedy-Drama-Fantasy-", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Comedy-Drama-Historical-", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Comedy-Drama-Music-", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Comedy-Drama-Musical-Romance-", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Comedy-Drama-Music_Movie-", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Comedy-Drama-Romance-", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Comedy-Drama-Sci-Fi-", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Comedy-Drama-", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Comedy-Family-Romance-", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Comedy-Family-", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Comedy-Fantasy-Musical-", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Comedy-Fantasy-Romance-", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Comedy-Historical-", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Comedy-Horror-Romance-", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Comedy-Horror-", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Comedy-Music_Movie-", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Comedy-Romance-", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Comedy-Sci-Fi-", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Comedy-War_Movie-", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Comedy-War-", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Comedy-", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Crime-Drama-Fantasy-Horror-", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Crime-Drama-Mystery_Movie-", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Crime-Drama-Mystery-", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Crime-Mystery-", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Crime-Mystery_Movie-", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Crime-Romance-Thriller-", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Crime-", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Drama-Historical-Romance-", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Drama-Horror-Mystery-", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Drama-Horror-Romance-", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Drama-Music-Romance-", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Drama-Mystery-Romance-", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Drama-Mystery-Sci-Fi-", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Drama-Mystery-Thriller-", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Drama-Romance-", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Drama-Sci-Fi-Thriller-", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Drama-Sci-Fi-", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Drama-Thriller-", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Drama-Violence-", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Drama-War_Movie-", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Drama-", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Family-", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Family-Fantasy-", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Family-Musical-", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Fantasy-Horror-", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Fantasy-Sci-Fi-", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Fantasy-", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Horror-", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Horror-Mystery-Sci-Fi-", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Horror-Mystery-Thriller-", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Horror-Sci-Fi-Thriller-", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Horror-Sci-Fi-", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Horror-Thriller-", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Horror-", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Musical-Romance-", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Musical-", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Music_Movie-", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Mystery-Sci-Fi-Thriller-", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Mystery-Sci-Fi-", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Romance-", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Romance-Western-", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Sci-Fi-Thriller-", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Sci-Fi-Western-", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Sci-Fi-", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Thriller-", "Movie-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-Western-", "Movie-")
	'
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Extreme_Railways_Journeys_", "Extreme_Railways_Journeys-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Great_British_Railway_Journeys_", "Great_British_Railway_Journeys-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Great_American_Railroad_Journeys_", "Great_American_Railroad_Journeys-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Great_Continental_Railway_Journeys_", "Great_Continental_Railway_Journeys-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Great_Indian_Railway_Journeys_", "Great_Indian_Railway_Journeys-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Tony_Robinson-s_World_By_Rail_", "Tony_Robinson-s_World_By_Rail-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Railways_That_Built_Britain_", "Railways_That_Built_Britain-")
	'
	' On second thought, replace Movie at the start with nothing ...
	'
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Movie-", "")
	'
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Action-Drama-Mini_Series-Sci-Fi-", "Sci-Fi-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Action-Drama-Mini_Series-Sci-Fi_", "Sci-Fi-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Adventure-Sci-Fi-", "Sci-Fi-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Adventure-Sci-Fi_", "Sci-Fi-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Adventure-Sci-Fi_", "Sci-Fi-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Adult-Documentary-Society-Culture_", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Adult-Documentary-Society-Culture-", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Arts-Culture-Biography-Historical_", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Arts-Culture-Documentary_", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Arts-Culture-Entertainment_", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Arts-Culture-Biography-Romance-", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Arts-Culture-War_", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Arts-Culture-", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Biography-Cult-Religion-Society-Culture_", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Biography-Documentary_", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Biography-Historical_", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Biography-Mini_Series_", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Biography-Tech_", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Biography-", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Entertainment_", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Family-Fantasy_", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Family-Fantasy-", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Food-Wine-Lifestyle-Science_", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Food-Wine-Society-Culture_", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Game_Show-", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Game_Show_", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Historical-", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Historical_", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Historical-Mini_Series-Science-Tech_", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Horror-Mystery-Thriller_", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Infotainment-Real-Life_", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Infotainment-", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Infotainment_", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Lifestyle-", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Lifestyle_", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Lifestyle-Science-Tech_", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Lifestyle-Travel_", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Medical_", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Mini_Series-Thriller_", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Mini_Series-War", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Mini-Series-Science-Tech-Society-Culture-Travel_", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Mini-Series-Society-Culture_", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Murder-Mystery-", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Murder-Mystery_", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Music-Romance_Movie-", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Music-Romance_Movie_", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Mystery-", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Mystery_", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Nature-Society-Culture_", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Nature_", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "News-Science-Tech-", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "News-Science-Tech_", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "News_", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Real_Life-Renovation-","")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Real_Life-Society-Culture_", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Real_Life-Travel_", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Real_Life_", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Real_Life-", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Religion-Society-Culture_", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Religion-Thriller-", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Religion_", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Romance-Society-Culture_", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Romance_", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Romance-", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Science-Tech_", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Science-Tech-", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Society-Culture_", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Society-Culture-", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Science-Tech-Society-Culture_", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Science-Tech-Special_", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Science-Tech_", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Science_", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Sci-Fi-Thriller_", "Sci-Fi-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Sitcom-", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Sitcom_", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Action-Sci-Fi_", "Sci-Fi-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Sci-Fi-", "Sci-Fi-")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Sci-Fi-", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Sci-Fi_", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Society-Culture_", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Sport-", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Sport_", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Thriller-", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Thriller_", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Tech-Travel_", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Tech-Travel-", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Travel_", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "Travel-", "")
	'
	theNewString = Replace(theNewString, "__", "_", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "__", "_", 1, -1, vbTextCompare) ' yes again to catch all  replaces
	theNewString = Replace(theNewString, "__", "_", 1, -1, vbTextCompare) ' yes again to catch all  replaces
	theNewString = Replace(theNewString, "__", "_", 1, -1, vbTextCompare) ' yes again to catch all  replaces
	theNewString = Replace(theNewString, "__", "_", 1, -1, vbTextCompare) ' yes again to catch all  replaces

	theNewString = Replace(theNewString, "--", "-", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "--", "-", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "--", "-", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "--", "-", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "--", "-", 1, -1, vbTextCompare)
	'
	theNewString = Replace(theNewString, "..", ".", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "..", ".", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "..", ".", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "..", ".", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "..", ".", 1, -1, vbTextCompare)
	'
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "-", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, "_", "")
	theNewString = vrdtvs_ReplaceStartStringCaseIndependent(theNewString, ".", "")
	theNewString = vrdtvs_ReplaceEndStringCaseIndependent(theNewString, "-", "")
	theNewString = vrdtvs_ReplaceEndStringCaseIndependent(theNewString, "_", "")
	theNewString = vrdtvs_ReplaceEndStringCaseIndependent(theNewString, ".", "")
    vrdtvs_remove_tvs_classifying_stuff_from_string = theNewString
End Function
'
Function vrdtvs_Move_Date_to_End_of_String(theOriginalString)
    ' if a Date exists in a string, move it to the end of the string (used in renaming files with the date on the end)
    Dim theLeadingSearchCharacter, txtToSearchFor
	Dim searchformeArray(3) ' an array of valid leading characters to include in the search/replace
    Dim xyear, xmonth, xday, xDate, is_a_date_there
    Dim theNewString
	Dim timerStart_MDES, timerEnd_MDES
	timerStart_MDES = Timer
	timerEnd_MDES = Timer
    'If vrdtvs_DEBUG Then WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_Move_Date_to_End_of_String: entered with original value """ & theOriginalString & """")
    searchformeArray(0)="-"
	searchformeArray(1)="_"
	searchformeArray(2)="."
	searchformeArray(3)=" " ' a space should not exist by the time it gets to here, but check/fix anyway
    theNewString = theOriginalString
    ' Brute force through dates, nothing fancy here. Very slow but sure.
    ' But first, cheekily see if there's a date at all by checking for "20"
    is_a_date_there = False
    For Each theLeadingSearchCharacter In searchformeArray ' this is a QUICK FOR loop, only 4 iterations
        txtToSearchFor = theLeadingSearchCharacter & "20" ' assuming start of a date in the "2000" years, eg "2021"
		'If vrdtvs_DEBUG Then WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_Move_Date_to_End_of_String: QUICK searching for """ & txtToSearchFor & """ in """ & theNewString & """") 
        If instr(1, theNewString, txtToSearchFor, vbTextCompare) > 0 Then 
            is_a_date_there = True
			'If vrdtvs_DEBUG Then WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_Move_Date_to_End_of_String: QUICK FOUND """ & txtToSearchFor & """ in """ & theNewString & """ exiting Quick FOR Loop") 
            Exit For
        End If
    Next
	'If vrdtvs_DEBUG Then WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_Move_Date_to_End_of_String: is_a_date_there=" & is_a_date_there)
    Do While is_a_date_there ' loop forever ... setting up for cheeky way to exit all FOR loops at once
		'for xyear = 2017 to 2040
        for xyear = 2021 to 2021 ' FORCE DEBUG OUTSIDE OF REAL DEBUG
			'If vrdtvs_DEBUG Then WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_Move_Date_to_End_of_String: Start    processing Year " & xyear & " ... with original value """ & theOriginalString & """")
	        for xmonth = 01 to 12
	            for xday = 01 to 31
	                xDate = vrdtvs_Digits4(xyear) & "-" & vrdtvs_Digits2(xmonth) & "-" & vrdtvs_Digits2(xday) ' assume dates in the filename are always in format dd-mm-yyyy with leading zeroes
					'If vrdtvs_DEBUG Then WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_Move_Date_to_End_of_String: About to process date " & xDate & " ")
                    For Each theLeadingSearchCharacter In searchformeArray
                        txtToSearchFor = theLeadingSearchCharacter & xDate
						'If vrdtvs_DEBUG Then 
						'	WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_Move_Date_to_End_of_String: About to process " & xDate & " with txtToSearchFor: """ & txtToSearchFor & """ in """ & theOriginalString & """")
						'End If
						If instr(1, theOriginalString, txtToSearchFor, vbTextCompare) > 0 then                                                                ' we found date within the string
							'If vrdtvs_DEBUG Then 
							'	WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_Move_Date_to_End_of_String: FOUND txtToSearchFor: """ & txtToSearchFor & """ in """ & theOriginalString & """")
							'End If
                            If right(theOriginalString, len(xDate)) <> xDate then ' ensure it's not already at the end of the string
                                theNewString = Replace(theOriginalString, txtToSearchFor, "", 1, -1, vbTextCompare) & theLeadingReplaceCharacter_ForMovingDates & xDate     ' move the date to the end of the string since it's not already there
								'If vrdtvs_DEBUG Then 
                                '	WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_Move_Date_to_End_of_String: FOUND string with DATE NOT AT END <" & txtToSearchFor & ">=<" & theOriginalString & "> ... changing to <" & theNewString & ">")
								'	'Wscript.Sleep 1000 * 2
								'End If
                            End If
							is_a_date_there = False ' this only means exit the Do loop, not that there isn't one !!!
							Exit Do ' cheeky way to exit all the For loops at once, just Exit the outer Do Loop
							If vrdtvs_DEBUG Then 
								WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_Move_Date_to_End_of_String: ?????? vrdtvs_Move_Date_to_End_of_String should have exited Loop with Exit Do but has not ??????")
								WScript.Quit 17 ' Error 17 = cannot perform the requested operation
						End If
					End If
                    Next
	            Next
	        Next
			'If vrdtvs_DEBUG Then 
			'	WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_Move_Date_to_End_of_String: Finished processing Year " & xyear & " YEAR NOT IN STRING ... with original value """ & theOriginalString & """")
			'	'Wscript.Sleep 1000 * 2
			'End If
		Next
		is_a_date_there = False ' this only means exit the Do loop !!!
		Exit Do
    Loop
	timerEnd_MDES = Timer
    'If vrdtvs_DEBUG Then WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_Move_Date_to_End_of_String: exiting with return value   """ & theNewString & """ having Loop ELapsed Time " & vrdtvs_Calculate_ElapsedTime_string(timerStart_MDES, timerEnd_MDES))
	vrdtvs_Move_Date_to_End_of_String = theNewString
End Function
'
Function vrdtvs_Digits2 (val)
    ' pad a number with leading zeroes, up to 2 characters in size total
    vrdtvs_Digits2 = vrdtvs_PadDigits(val, 2)
End Function
'
Function vrdtvs_Digits4(val)
    ' pad a number with leading zeroes, up to 4 characters in size total
    vrdtvs_Digits4 = vrdtvs_PadDigits(val, 4)
End Function
'
Function vrdtvs_PadDigits(val, digits) 
    ' pad a number with leading zeroes, up to a speified number of characters in size total
    vrdtvs_PadDigits = Right(String(digits,"0") & val, digits)
End Function
'
Function vrdtvs_ReplaceStartStringCaseIndependent(theString, theSearchString, theReplaceString)
	' replace string only at the start of a line
	dim L
	If lcase(left(theString,len(theSearchString))) = lcase(theSearchString) then
		L = len(theString) - len(theSearchString)
		''vrdtvs_ReplaceStartStringCaseIndependent = Replace(theString, theSearchString, theReplaceString, 1, 1, vbTextCompare)
		vrdtvs_ReplaceStartStringCaseIndependent = theReplaceString & right(theString,L)
	else
		vrdtvs_ReplaceStartStringCaseIndependent = theString
	end if
End Function
'
Function vrdtvs_ReplaceEndStringCaseIndependent(theString, theSearchString, theReplaceString)
	' replace string only at the end of a line
	dim L
	If lcase(right(theString,len(theSearchString))) = lcase(theSearchString) then
		L = len(theString) - len(theSearchString)
		''vrdtvs_ReplaceStartStringCaseIndependent = Replace(theString, theSearchString, theReplaceString, 1, 1, vbTextCompare)
		vrdtvs_ReplaceEndStringCaseIndependent =  left(theString,L) & theReplaceString
	else
		vrdtvs_ReplaceEndStringCaseIndependent = theString
	end if
End Function
'----------------------------------------------------------------------------------------------------------------------------------------
'----------------------------------------------------------------------------------------------------------------------------------------
'----------------------------------------------------------------------------------------------------------------------------------------
'****************************************************************************************************************************************
'****************************************************************************************************************************************
'****************************************************************************************************************************************
