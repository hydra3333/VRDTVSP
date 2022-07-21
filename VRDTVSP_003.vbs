Option Explicit
'
' VRDTVSP - automatically parse, convert video/audio from TVSchedulerPro TV recordings, 
' and perhaps adscan them too. This looks only at .TS .MP4 .MPG files and autofixes associated .vprj files.
'
' Copyright hydra3333@gmail.com 2021 2022
'
' Invoke from a DOS commandline or a .bat, Interactively or in a Scheduled Task 
' using a single one-line commndline.
' All options are, well, optional and are based on a default source_Folder
'
'cscript //nologo "E:\GIT-REPOSITORIES\VRDTVSP\VRDTVS_003.vbs" ^
'/DEBUG:True ^
'/DEV:True ^
'/capture_Folder:"G:\HDTV\000-TO-BE-PROCESSED\zzz-TEST\0save\" ^
'/source_Folder:"G:\HDTV\000-TO-BE-PROCESSED\zzz-TEST\VRDTVSP-Source\" ^
'/done_Folder:"G:\HDTV\000-TO-BE-PROCESSED\zzz-TEST\VRDTVSP-Done\" ^
'/destination_Folder:"G:\HDTV\000-TO-BE-PROCESSED\zzz-TEST\VRDTVSP-Converted\" ^
'/failed_Folder:"G:\HDTV\000-TO-BE-PROCESSED\zzz-TEST\VRDTVSP-Failed-Conversion\" ^
'/temp_path:"D:\VRDTVSP-SCRATCH\" ^
'/vrd_version_for_qsf:6 ^
'/vrd_version_for_adscan:6 ^
'/do_adscan:False ^
'/do_audio_delay:False ^
'/show_mediainfo:False 
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
WScript.StdOut.WriteLine("======================================================================================================================================================")
WScript.StdOut.WriteLine("VRDTVS started " & vrdtvsp_current_datetime_string())
WScript.StdOut.WriteLine("======================================================================================================================================================")
Dim  cscript_wshShell, cscript_strEngine
Dim vrdtvsp_ComputerName
'
Set cscript_wshShell = CreateObject( "WScript.Shell" )
cscript_strEngine = UCase( Right( WScript.FullName, 12 ) )
vrdtvsp_ComputerName = cscript_wshShell.ExpandEnvironmentStrings( "%COMPUTERNAME%" )
'Dim wshNetwork
'Set wshNetwork = CreateObject( "WScript.Network" )
'vrdtvsp_ComputerName = wshNetwork.ComputerName
'WScript.StdOut.WriteLine("wshNetwork.ComputerName Computer Name: " & vrdtvsp_ComputerName)
'set wshNetwork = Nothing
'Dim objSysInfo
'Set objSysInfo = CreateObject( "WinNTSystemInfo" )
'vrdtvsp_ComputerName = objSysInfo.ComputerName
'WScript.StdOut.WriteLine("objSysInfo.ComputerName Computer Name: " & vrdtvsp_ComputerName)
'set objSysInfo = Nothing
Set cscript_wshShell = Nothing
WScript.Echo "Checked and CSCRIPT Engine = """ & cscript_strEngine & """" ' .Echo works in both wscript and cscript
If UCase(cscript_strEngine) <> UCase("\CSCRIPT.EXE") Then
    ' exit immediately with error code 17 cannot perform the requested operation
    ' since it was not run like:
    '      cscript //NOLOGO "vbscript_path_and_file" "parameter 1" "parameter 2"
    '      cscript //NOLOGO "test.vbs" /p1:"This is the value for p1" /p2:500
    ' Err.Raise 17 ' Error 17 = cannot perform the requested operation
    WScript.Echo "CSCRIPT Engine MUST be CSCRIPT not WSCRIPT ... Aborting ..."
	On Error goto 0
	Wscript.Echo "Error 17 = cannot perform the requested operation"
	WScript.Quit 17 ' Error 17 = cannot perform the requested operation
End If
WScript.StdOut.WriteLine("------------------------------------------------------------------------------------------------------")
WScript.StdOut.WriteLine("VRDTVSP cscript Engine: """ & cscript_strEngine & """")
WScript.StdOut.WriteLine("VRDTVSP    Script name: " & Wscript.ScriptName)
WScript.StdOut.WriteLine("VRDTVSP    Script path: " & Wscript.ScriptFullName)
WScript.StdOut.WriteLine("VRDTVSP   ComputerName: " & vrdtvsp_ComputerName)
WScript.StdOut.WriteLine("------------------------------------------------------------------------------------------------------")
'
'----------------------------------------------------------------------------------------------------------------------------------------
' Setup Global constants which we don't group below
'
Const theLeadingReplaceCharacter_ForMovingDates = "."
Const FORREADING = 1
Const FORWRITING = 2
Const FORAPPENDING = 8

' Setup Global variables
'
Dim vrdtvsp_run_datetime, vrdtvsp_ScriptName
Dim vrdtvsp_timer_StartTime_overall, vrdtvsp_timer_EndTime_overall
vrdtvsp_run_datetime = vrdtvsp_current_datetime_string() ' start of runtime, for common use
vrdtvsp_ScriptName = Wscript.ScriptName
WScript.StdOut.WriteLine(vrdtvsp_ScriptName & " Started: " & vrdtvsp_current_datetime_string() & " ")
vrdtvsp_timer_StartTime_overall = Timer
vrdtvsp_timer_EndTime_overall = Timer
'
' (these two are Global but are also Global Defaults declared early here)
Dim vrdtvsp_DEBUG, vrdtvsp_DEVELOPMENT_NO_ACTIONS
vrdtvsp_DEBUG = False
vrdtvsp_DEVELOPMENT_NO_ACTIONS = False
'
' Create a bunch of scratch variables
'
Dim vrdtvsp_tmp, vrdtvsp_REM, vrdtvsp_status, vrdtvsp_exit_code, vrdrvs_Err_Code, vrdrvs_Err_Description, vrdtvsp_cmd, vrdtvsp_exe_obj ' a few working variables, for common use
Dim file_count_checked, file_count_fixed
Dim vrdtvsp_temp_powershell_filename, vrdtvsp_temp_powershell_cmd, vrdtvsp_temp_powershell_exe
Dim vrdtvsp_saved_ffmpeg_commands_filename, vrdtvsp_saved_ffmpeg_commands_object
Dim scratch_local_timerStart, scratch_local_timerEnd
Dim vrdtvsp_Exec_in_a_DOS_BAT_file_cmd_array(), iii	' then eg ReDim Dim vrdtvsp_Exec_in_a_DOS_BAT_file_cmd_array(5) for 6 commands, 0..5), Use "Erase vrdtvsp_Exec_in_a_DOS_BAT_file_cmd_array" when finished
Set vrdtvsp_temp_powershell_exe = Nothing
Set vrdtvsp_saved_ffmpeg_commands_object = Nothing
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
Dim HDTV_root
Dim vapoursynth_root
Dim vrdtvsp_mp4boxexex64
Dim vrdtvsp_mediainfoexe64
Dim vrdtvsp_ffprobeexe64
Dim vrdtvsp_ffmpegexe64
Dim vrdtvsp_ffmpegexe64_OpenCL
Dim vrdtvsp_dgindexNVexe64
Dim vrdtvsp_Insomniaexe64
Dim vrdtvsp_Insomnia64_tmp_filename, vrdtvsp_Insomnia64_ProcessID
'
HDTV_root = fso.GetAbsolutePathName("G:\HDTV\") ' where my VideoReDo application logs are
vapoursynth_root = fso.GetAbsolutePathName("C:\SOFTWARE\Vapoursynth-x64\")
vrdtvsp_mp4boxexex64 = fso.GetAbsolutePathName(fso.BuildPath("C:\SOFTWARE\ffmpeg\0-homebuilt-x64\","MP4Box.exe"))
vrdtvsp_mediainfoexe64 = fso.GetAbsolutePathName(fso.BuildPath("C:\SOFTWARE\MediaInfo\","MediaInfo.exe"))
vrdtvsp_ffprobeexe64 = fso.GetAbsolutePathName(fso.BuildPath(vapoursynth_root,"ffprobe.exe"))
vrdtvsp_ffmpegexe64 = fso.GetAbsolutePathName(fso.BuildPath(vapoursynth_root,"ffmpeg.exe"))
vrdtvsp_ffmpegexe64_OpenCL = fso.GetAbsolutePathName(fso.BuildPath(vapoursynth_root,"ffmpeg_OpenCL.exe"))
vrdtvsp_dgindexNVexe64 = fso.GetAbsolutePathName(fso.BuildPath(vapoursynth_root,"DGIndex\DGIndexNV.exe"))
vrdtvsp_Insomniaexe64 = fso.GetAbsolutePathName("C:\SOFTWARE\Insomnia\64-bit\Insomnia.exe")
'
'----------------------------------------------------------------------------------------------------------------------------------------
' Setup Global VideoReDo QSF and Adscan file paths and stuff
'
Dim vrd_version_for_qsf
Dim vrd_version_for_adscan
Dim vrdtvsp_path_for_qsf_vbs
Dim vrdtvsp_path_for_adscan_vbs
Dim vrdtvsp_profile_name_for_qsf_mpeg2
Dim vrdtvsp_profile_name_for_qsf_avc
Dim vrdtvsp_profile_name_for_qsf
Dim vrdtvsp_extension_mpeg2
Dim vrdtvsp_extension_avc
Dim vrdtvsp_extension
Dim vrdtvsp_logfile_wildcard_QSF
Dim vrdtvsp_logfile_wildcard_ADSCAN
Dim vrdtvsp_do_adscan
Dim vrdtvsp_do_audio_delay
Dim vrdtvsp_show_mediainfo
'
Const const_vrd5_path = "C:\Program Files (x86)\VideoReDoTVSuite5"
Const const_vrd5_profile_mpeg2 = "VRDTVS-for-QSF-MPEG2_VRD5"
Const const_vrd5_profile_avc = "VRDTVS-for-QSF-H264_VRD5"
Const const_vrd5_extension_mpeg2 = "mpg"
Const const_vrd5_extension_avc = "mp4"
Dim vrd5_logfile_wildcard
vrd5_logfile_wildcard =  fso.GetAbsolutePathName(HDTV_root & "\") & "\VideoReDo-5_*.Log"
'
Const const_vrd6_path =  "C:\Program Files (x86)\VideoReDoTVSuite6"
Const const_vrd6_profile_mpeg2 = "VRDTVS-for-QSF-MPEG2_VRD6"
Const const_vrd6_profile_avc = "VRDTVS-for-QSF-H264_VRD6"
Const const_vrd6_extension_mpeg2 = "mpg"
Const const_vrd6_extension_avc = "mp4"
Const const_vrd6_adscan_profile_name = "VRDTVS_ADSCAN_VRD6_NON-INTERACTIVE"	' alternate for interactive is "VRDTVS_ADSCAN_VRD6"
Dim vrd6_logfile_wildcard
vrd6_logfile_wildcard =  fso.GetAbsolutePathName(HDTV_root & "\") & "\VideoReDo6_*.Log"
'
vrd_version_for_qsf = 6
vrd_version_for_adscan = 6
vrdtvsp_do_adscan = False
vrdtvsp_do_audio_delay = False
vrdtvsp_show_mediainfo = False
'
'----------------------------------------------------------------------------------------------------------------------------------------
' Setup Global Default Paths, resolving them to Absolute paths
'
Dim vrdtvsp_CAPTURE_TS_Folder
Dim vrdtvsp_source_TS_Folder
Dim vrdtvsp_done_TS_Folder
Dim vrdtvsp_destination_mp4_Folder
Dim vrdtvsp_failed_conversion_TS_Folder
Dim vrdtvsp_temp_path
vrdtvsp_CAPTURE_TS_Folder = fso.GetAbsolutePathName("G:\HDTV\")
vrdtvsp_source_TS_Folder = fso.GetAbsolutePathName("G:\HDTV\000-TO-BE-PROCESSED\zzz-TEST\")
vrdtvsp_done_TS_Folder = fso.GetAbsolutePathName(fso.BuildPath(vrdtvsp_source_TS_Folder,"VRDTVSP-done\"))
vrdtvsp_destination_mp4_Folder = fso.GetAbsolutePathName(fso.BuildPath(vrdtvsp_source_TS_Folder,"VRDTVSP-Converted\"))
vrdtvsp_failed_conversion_TS_Folder = fso.GetAbsolutePathName(fso.BuildPath(vrdtvsp_source_TS_Folder,"VRDTVSP-Failed-Conversion\"))
vrdtvsp_temp_path = fso.GetAbsolutePathName("D:\VRDTVSP-SCRATCH\")
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
vrdtvsp_DEBUG = vrdtvsp_get_commandline_parameter("DEBUG",vrdtvsp_DEBUG)                                                                               ' /DEBUG:True
vrdtvsp_DEVELOPMENT_NO_ACTIONS = vrdtvsp_get_commandline_parameter("DEV",vrdtvsp_DEVELOPMENT_NO_ACTIONS)                                               ' /DEV:True
If vrdtvsp_DEVELOPMENT_NO_ACTIONS Then vrdtvsp_DEBUG = True ' if in Development then always force debug on ' DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV 
'
vrdtvsp_CAPTURE_TS_Folder = vrdtvsp_get_commandline_parameter("capture_Folder",vrdtvsp_CAPTURE_TS_Folder) ' no GetAbsolutePathName to leave "" as ""   ' /capture_Folder:""
If vrdtvsp_CAPTURE_TS_Folder <> "" Then
	vrdtvsp_CAPTURE_TS_Folder = fso.GetAbsolutePathName(vrdtvsp_CAPTURE_TS_Folder)                 ' re-write capture folder as an Absolute Pathname ONLY if not ""
End If
If vrdtvsp_DEVELOPMENT_NO_ACTIONS Then vrdtvsp_CAPTURE_TS_Folder = ""  ' if under development, force do not copy any files ' DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV 
vrdtvsp_source_TS_Folder = fso.GetAbsolutePathName(vrdtvsp_get_commandline_parameter("source_Folder",vrdtvsp_source_TS_Folder))                        ' /source_Folder:""
vrdtvsp_done_TS_Folder = fso.GetAbsolutePathName(vrdtvsp_get_commandline_parameter("done_Folder",vrdtvsp_done_TS_Folder))                              ' /done_Folder:""
vrdtvsp_destination_mp4_Folder = fso.GetAbsolutePathName(vrdtvsp_get_commandline_parameter("destination_Folder",vrdtvsp_destination_mp4_Folder))       ' /destination_Folder:""
vrdtvsp_failed_conversion_TS_Folder = fso.GetAbsolutePathName(vrdtvsp_get_commandline_parameter("failed_Folder",vrdtvsp_failed_conversion_TS_Folder))  ' /failed_Folder:""
vrdtvsp_temp_path = fso.GetAbsolutePathName(vrdtvsp_get_commandline_parameter("temp_path",vrdtvsp_temp_path))                                          ' /temp_path:"D:\VRDTVSP-SCRATCH\"
vrdtvsp_do_adscan = vrdtvsp_get_commandline_parameter("do_adscan",vrdtvsp_do_adscan)                      		                    					' /do_adscan:False
vrdtvsp_do_audio_delay = vrdtvsp_get_commandline_parameter("do_audio_delay",vrdtvsp_do_audio_delay)                      		                    	' /do_audio_delay:False
vrdtvsp_show_mediainfo = vrdtvsp_get_commandline_parameter("show_mediainfo",vrdtvsp_show_mediainfo)                      		                    	' /show_mediainfo:False
vrd_version_for_adscan = vrdtvsp_get_commandline_parameter("vrd_version_for_adscan",vrd_version_for_adscan)                              			   	' /vrd_version_for_adscan:6
vrd_version_for_qsf = vrdtvsp_get_commandline_parameter("vrd_version_for_qsf",vrd_version_for_qsf)                                        				' /vrd_version_for_qsf:6
'----------------------------------------------------------------------------------------------------------------------------------------
' Create the working folders if they do not already exist
If NOT fso.FolderExists(vrdtvsp_source_TS_Folder) Then     
	Set objFolder = fso.CreateFolder(vrdtvsp_source_TS_Folder)
	Set objFolder = Nothing
    If vrdtvsp_DEBUG Then WScript.StdOut.WriteLine("VRDTVSP DEBUG: Created vrdtvsp_source_TS_Folder folder=" & vrdtvsp_source_TS_Folder)
Else
    If vrdtvsp_DEBUG Then WScript.StdOut.WriteLine("VRDTVSP DEBUG: Folder Already Exists, not created - vrdtvsp_source_TS_Folder folder=" & vrdtvsp_source_TS_Folder)
End If
If NOT fso.FolderExists(vrdtvsp_done_TS_Folder) Then     
	Set objFolder = fso.CreateFolder(vrdtvsp_done_TS_Folder)
	Set objFolder = Nothing
    If vrdtvsp_DEBUG Then WScript.StdOut.WriteLine("VRDTVSP DEBUG: Created vrdtvsp_done_TS_Folder folder=" & vrdtvsp_done_TS_Folder)
Else
    If vrdtvsp_DEBUG Then WScript.StdOut.WriteLine("VRDTVSP DEBUG: Folder Already Exists, not created - vrdtvsp_done_TS_Folder folder=" & vrdtvsp_done_TS_Folder)
End If
If NOT fso.FolderExists(vrdtvsp_destination_mp4_Folder) Then     
	Set objFolder = fso.CreateFolder(vrdtvsp_destination_mp4_Folder)
	Set objFolder = Nothing
    If vrdtvsp_DEBUG Then WScript.StdOut.WriteLine("VRDTVSP DEBUG: Created vrdtvsp_destination_mp4_Folder folder=" & vrdtvsp_destination_mp4_Folder)
Else
    If vrdtvsp_DEBUG Then WScript.StdOut.WriteLine("VRDTVSP DEBUG: Folder Already Exists, not created - vrdtvsp_destination_mp4_Folder folder=" & vrdtvsp_destination_mp4_Folder)
End If
If NOT fso.FolderExists(vrdtvsp_failed_conversion_TS_Folder) Then     
	Set objFolder = fso.CreateFolder(vrdtvsp_failed_conversion_TS_Folder)
	Set objFolder = Nothing
    If vrdtvsp_DEBUG Then WScript.StdOut.WriteLine("VRDTVSP DEBUG: Created vrdtvsp_failed_conversion_TS_Folder folder=" & vrdtvsp_failed_conversion_TS_Folder)
Else
    If vrdtvsp_DEBUG Then WScript.StdOut.WriteLine("VRDTVSP DEBUG: Folder Already Exists, not created - vrdtvsp_failed_conversion_TS_Folder folder=" & vrdtvsp_failed_conversion_TS_Folder)
End If
If NOT fso.FolderExists(vrdtvsp_temp_path) Then     
	Set objFolder = fso.CreateFolder(vrdtvsp_temp_path)
	Set objFolder = Nothing
    If vrdtvsp_DEBUG Then WScript.StdOut.WriteLine("VRDTVSP DEBUG: Created vrdtvsp_temp_path folder=" & vrdtvsp_temp_path)
Else
    If vrdtvsp_DEBUG Then WScript.StdOut.WriteLine("VRDTVSP DEBUG: Folder Already Exists, not created - vrdtvsp_temp_path folder=" & vrdtvsp_temp_path)
End If
'----------------------------------------------------------------------------------------------------------------------------------------
If vrd_version_for_qsf = 5 Then '*** QSF  ' can only do this AFTER folders are created !!!!!!!!!!!!!!!!!!!!!!!!
	' THE old WAY 2021.02.25.
	'vrdtvsp_path_for_qsf_vbs = fso.GetAbsolutePathName(fso.BuildPath(const_vrd5_path,"vp.vbs"))
	' THE NEW way is similar to vrd6
	vrdtvsp_path_for_qsf_vbs = vrdtvsp_create_custom_QSF_vbscript_vrd_5_AND_6( vrd_version_for_qsf ) ' can only do this AFTER folders are created !!!!!!!!!!!!!!!!!!!!!!!!
    vrdtvsp_profile_name_for_qsf_mpeg2 = const_vrd5_profile_mpeg2
    vrdtvsp_profile_name_for_qsf_avc = const_vrd5_profile_avc
    vrdtvsp_extension_mpeg2 = const_vrd5_extension_mpeg2
    vrdtvsp_extension_avc = const_vrd5_extension_avc
	vrdtvsp_logfile_wildcard_QSF = vrd5_logfile_wildcard
ElseIf vrd_version_for_qsf = 6 Then
    ' the old way: vrdtvsp_path_for_qsf_vbs = fso.GetAbsolutePathName(fso.BuildPath(const_vrd6_path,"vp.vbs"))
	' THE NEW way is similar to vrd6
	vrdtvsp_path_for_qsf_vbs = vrdtvsp_create_custom_QSF_vbscript_vrd_5_AND_6( vrd_version_for_qsf ) ' can only do this AFTER folders are created !!!!!!!!!!!!!!!!!!!!!!!!
    vrdtvsp_profile_name_for_qsf_mpeg2 = const_vrd6_profile_mpeg2
    vrdtvsp_profile_name_for_qsf_avc = const_vrd6_profile_avc
    vrdtvsp_extension_mpeg2 = const_vrd6_extension_mpeg2
    vrdtvsp_extension_avc = const_vrd6_extension_avc
	vrdtvsp_logfile_wildcard_QSF = vrd6_logfile_wildcard
Else
    WScript.StdOut.WriteLine("VRDTVSP ERROR - vrd_version_for_qsf can only be 5 or 6 ... Aborting ...")
	Wscript.Echo "Error 17 = cannot perform the requested operation"
    On Error goto 0
	WScript.Quit 17 ' Error 17 = cannot perform the requested operation
End If
' ***************************************************************************************************************************
'If vrd_version_for_adscan <> 5 Then '*** QSF
'	WScript.StdOut.WriteLine("VRDTVSP WARNING ************************************************************************************************************************")
'	WScript.StdOut.WriteLine("VRDTVSP WARNING version vrd_version_for_adscan=" & vrd_version_for_adscan & " does not work - auto REVERTING to vrd_version_for_adscan=5")
'	WScript.StdOut.WriteLine("VRDTVSP WARNING ************************************************************************************************************************")
'	vrd_version_for_adscan = 5
'End If
' ***************************************************************************************************************************
If vrd_version_for_adscan = 5 Then '*** AdScan
    vrdtvsp_path_for_adscan_vbs = fso.GetAbsolutePathName(fso.BuildPath(const_vrd5_path,"AdScan.vbs"))
	vrdtvsp_logfile_wildcard_ADSCAN = vrd5_logfile_wildcard
ElseIf vrd_version_for_adscan = 6 Then
    'vrdtvsp_path_for_adscan_vbs = fso.GetAbsolutePathName(fso.BuildPath(const_vrd6_path,"AdScan2.vbs"))
	' *** v6 has changed,	see https://videoredo.net/msgBoard/index.php?threads/adscan2-for-v6-how-to-use.37593/#post-133909
	'						AdScans are just saves now. Use the same script you use to QSF and just pass it *adscan_current* as the profile name. All the other progress code is identical to a normal save.
	vrdtvsp_path_for_adscan_vbs = vrdtvsp_create_custom_adscan_script_vrd6() ' create our custom VRD v6 adscan script and leave it undeleted in the scratch temporary folder
	vrdtvsp_logfile_wildcard_ADSCAN = vrd6_logfile_wildcard
Else
    WScript.StdOut.WriteLine("VRDTVSP ERROR - vrdtvsp_path_for_adscan_vbs can only be 5 or 6 ... Aborting ...")
	Wscript.Echo "Error 17 = cannot perform the requested operation"
	On Error goto 0
	WScript.Quit 17 ' Error 17 = cannot perform the requested operation
End If
WScript.StdOut.WriteLine("======================================================================================================================================================")
WScript.StdOut.WriteLine("" & vrdtvsp_current_datetime_string())
WScript.StdOut.WriteLine("VRDTVSP NOTE: final                       vrdtvsp_DEBUG=" & vrdtvsp_DEBUG)
WScript.StdOut.WriteLine("VRDTVSP NOTE: final      vrdtvsp_DEVELOPMENT_NO_ACTIONS=" & vrdtvsp_DEVELOPMENT_NO_ACTIONS)
WScript.StdOut.WriteLine("VRDTVSP NOTE: final                vrdtvsp_ComputerName=""" & vrdtvsp_ComputerName & """")
WScript.StdOut.WriteLine("VRDTVSP NOTE: final                       vrdtvsp_DEBUG=" & vrdtvsp_DEBUG)
WScript.StdOut.WriteLine("VRDTVSP NOTE: final      vrdtvsp_DEVELOPMENT_NO_ACTIONS=" & vrdtvsp_DEVELOPMENT_NO_ACTIONS & """")
WScript.StdOut.WriteLine("VRDTVSP NOTE: final           vrdtvsp_CAPTURE_TS_Folder=""" & vrdtvsp_CAPTURE_TS_Folder & """")
WScript.StdOut.WriteLine("VRDTVSP NOTE: final            vrdtvsp_source_TS_Folder=""" & vrdtvsp_source_TS_Folder & """")
WScript.StdOut.WriteLine("VRDTVSP NOTE: final              vrdtvsp_done_TS_Folder=""" & vrdtvsp_done_TS_Folder & """")
WScript.StdOut.WriteLine("VRDTVSP NOTE: final      vrdtvsp_destination_mp4_Folder=""" & vrdtvsp_destination_mp4_Folder & """")
WScript.StdOut.WriteLine("VRDTVSP NOTE: final vrdtvsp_failed_conversion_TS_Folder=""" & vrdtvsp_failed_conversion_TS_Folder & """")
WScript.StdOut.WriteLine("VRDTVSP NOTE: final                   vrdtvsp_temp_path=""" & vrdtvsp_temp_path & """")
WScript.StdOut.WriteLine("VRDTVSP NOTE: final                 vrd_version_for_qsf=" & vrd_version_for_qsf)
WScript.StdOut.WriteLine("VRDTVSP NOTE: final            vrdtvsp_path_for_qsf_vbs=""" & vrdtvsp_path_for_qsf_vbs & """")
WScript.StdOut.WriteLine("VRDTVSP NOTE: final  vrdtvsp_profile_name_for_qsf_mpeg2=""" & vrdtvsp_profile_name_for_qsf_mpeg2 & """")
WScript.StdOut.WriteLine("VRDTVSP NOTE: final    vrdtvsp_profile_name_for_qsf_avc=""" & vrdtvsp_profile_name_for_qsf_avc & """")
WScript.StdOut.WriteLine("VRDTVSP NOTE: final             vrdtvsp_extension_mpeg2=""" & vrdtvsp_extension_mpeg2 & """")
WScript.StdOut.WriteLine("VRDTVSP NOTE: final               vrdtvsp_extension_avc=""" & vrdtvsp_extension_avc & """")
WScript.StdOut.WriteLine("VRDTVSP NOTE: final              vrd_version_for_adscan=" & vrd_version_for_adscan)
WScript.StdOut.WriteLine("VRDTVSP NOTE: final         vrdtvsp_path_for_adscan_vbs=""" & vrdtvsp_path_for_adscan_vbs & """")
WScript.StdOut.WriteLine("VRDTVSP NOTE: final                   vrdtvsp_do_adscan=" & vrdtvsp_do_adscan)
WScript.StdOut.WriteLine("VRDTVSP NOTE: final              vrdtvsp_do_audio_delay=" & vrdtvsp_do_audio_delay)
WScript.StdOut.WriteLine("VRDTVSP NOTE: final              vrdtvsp_show_mediainfo=" & vrdtvsp_show_mediainfo)
WScript.StdOut.WriteLine("" & vrdtvsp_current_datetime_string())
WScript.StdOut.WriteLine("======================================================================================================================================================")
'
'----------------------------------------------------------------------------------------------------------------------------------------
'
' Start a new copy of Insomnia so the PC does not go to sleep in the middle of conversions, do not wait for it to finish
'
WScript.StdOut.WriteLine("======================================================================================================================================================")
WScript.StdOut.WriteLine("" & vrdtvsp_current_datetime_string())
WScript.StdOut.WriteLine("STARTED Run Insomnia")
vrdtvsp_Insomnia64_tmp_filename = vrdtvsp_gimme_a_temporary_absolute_filename("VRDTVS_Insomnia64_copy-" & vrdtvsp_run_datetime) & ".exe"
If vrdtvsp_DEBUG Then WScript.StdOut.WriteLine("VRDTVSP DEBUG: Insomnia: Creating and running Insomnia vrdtvsp_Insomnia64_tmp_filename=" & vrdtvsp_Insomnia64_tmp_filename)
vrdtvsp_exit_code = vrdtvsp_delete_a_file(vrdtvsp_Insomnia64_tmp_filename, True) ' True=silently delete it even though it should never pre-exist
If vrdtvsp_DEBUG Then WScript.StdOut.WriteLine("VRDTVSP DEBUG: Insomnia: Copying """ & vrdtvsp_Insomniaexe64 & """ to """ & vrdtvsp_Insomnia64_tmp_filename & """")
On Error Resume Next
fso.CopyFile vrdtvsp_Insomniaexe64, vrdtvsp_Insomnia64_tmp_filename, True 
vrdrvs_Err_Code = Err.Number
vrdrvs_Err_Description = Err.Description
On Error Goto 0
'If vrdtvsp_DEBUG Then WScript.StdOut.WriteLine("VRDTVSP DEBUG: Insomnia: File Copy returned error code: " & vrdrvs_Err_Code & " Descrption: " & vrdrvs_Err_Description)
If vrdrvs_Err_Code <> 0 Then
    Err.Clear
    WScript.StdOut.WriteLine("VRDTVSP Insomnia: ERROR - Error " & vrdrvs_Err_Code & " Creating vrdtvsp_Insomnia64_tmp_filename=" & vrdtvsp_Insomnia64_tmp_filename & "... Aborting ...")
    WScript.StdOut.WriteLine("VRDTVSP Insomnia: ERROR - " & vrdrvs_Err_Description)
    ' Err.Raise 17 ' Error 17 = cannot perform the requested operation
	Wscript.Echo "Error 17 = cannot perform the requested operation"
	On Error goto 0
	WScript.Quit 17 ' Error 17 = cannot perform the requested operation
End If
'
' Exec it asynchronously and do not wait for it to finish
' Start "title" "file" 
' NOTE: Exec object has a .Terminate - this type of process kill does NOT clean up properly and may cause memory leaks - use only as a last resort!
'
'vrdtvsp_cmd = "CMD /C START /min """ &  vrdtvsp_Insomnia64_tmp_filename & """ """ & vrdtvsp_Insomnia64_tmp_filename & """"
'vrdtvsp_cmd = "START /min """ &  vrdtvsp_Insomnia64_tmp_filename & """ """ & vrdtvsp_Insomnia64_tmp_filename & """"
vrdtvsp_cmd = """" &  vrdtvsp_Insomnia64_tmp_filename & """"
If vrdtvsp_DEBUG Then WScript.StdOut.WriteLine("VRDTVSP DEBUG: Insomnia: Exec command: " & vrdtvsp_cmd)
set vrdtvsp_exe_obj = wso.Exec(vrdtvsp_cmd)
vrdtvsp_Insomnia64_ProcessID = vrdtvsp_exe_obj.ProcessID
vrdtvsp_status = vrdtvsp_exe_obj.ExitCode
Set vrdtvsp_exe_obj = Nothing
WScript.StdOut.WriteLine("VRDTVS Run Insomnia: Exec command: " & vrdtvsp_cmd)
WScript.StdOut.WriteLine("VTDRVS Run Insomnia: has run asynchronously with vrdtvsp_Insomnia64_ProcessID=" & vrdtvsp_Insomnia64_ProcessID)
If vrdtvsp_Insomnia64_ProcessID = 0 Then
    WScript.StdOut.WriteLine("VRDTVSP Run Insomnia: ERROR - Insomnia START command created ProcessID is zero ... Aborting ...")
	Wscript.Echo "Error 17 = cannot perform the requested operation"
	On Error goto 0
	WScript.Quit 17 ' Error 17 = cannot perform the requested operation
End If
WScript.StdOut.WriteLine("VRDTVS Run Insomnia: Exec Exit Status: " & vrdtvsp_status)
If vrdtvsp_DEBUG Then WScript.StdOut.WriteLine("VRDTVSP DEBUG: Insomnia: Exec Exit Status: " & vrdtvsp_status)
WScript.StdOut.WriteLine("FINISHED Run Insomnia")
WScript.StdOut.WriteLine("" & vrdtvsp_current_datetime_string())
WScript.StdOut.WriteLine("======================================================================================================================================================")
'
'----------------------------------------------------------------------------------------------------------------------------------------
' Move .ts .mp4 .mpg .brpj files from the Source Folder to the source folder sincethat is where we process from
'
If vrdtvsp_CAPTURE_TS_Folder <> "" Then
	WScript.StdOut.WriteLine("======================================================================================================================================================")
	WScript.StdOut.WriteLine("" & vrdtvsp_current_datetime_string())
	WScript.StdOut.WriteLine("STARTED VRDTVSP Moving SOURCE files from CAPTURE_TS folder """ & vrdtvsp_CAPTURE_TS_Folder & """ to SOURCE_TS folder """ & vrdtvsp_source_TS_Folder & """ ...")
    vrdtvsp_status = vrdtvsp_move_files_to_folder(vrdtvsp_CAPTURE_TS_Folder & "\*.ts", vrdtvsp_source_TS_Folder & "\")    ' ignore any status
    vrdtvsp_status = vrdtvsp_move_files_to_folder(vrdtvsp_CAPTURE_TS_Folder & "\*.mp4", vrdtvsp_source_TS_Folder & "\")   ' ignore any status
    vrdtvsp_status = vrdtvsp_move_files_to_folder(vrdtvsp_CAPTURE_TS_Folder & "\*.mpg", vrdtvsp_source_TS_Folder & "\")   ' ignore any status
    vrdtvsp_status = vrdtvsp_move_files_to_folder(vrdtvsp_CAPTURE_TS_Folder & "\*.vprj", vrdtvsp_source_TS_Folder & "\")  ' ignore any status '.vprj are associated with .mp4 of the same BaseName
	WScript.StdOut.WriteLine("FINISHED VRDTVSP Moving SOURCE files from CAPTURE_TS folder """ & vrdtvsp_CAPTURE_TS_Folder & """ to SOURCE_TS folder """ & vrdtvsp_source_TS_Folder & """ ...")
	WScript.StdOut.WriteLine("" & vrdtvsp_current_datetime_string())
	WScript.StdOut.WriteLine("======================================================================================================================================================")
End If
'
'----------------------------------------------------------------------------------------------------------------------------------------
' In Top Level Folders: Source
' (the function filters for file Extensions: .ts .mp4 .mpg, and autofixes .vprj which are associated with .mpg and .mp4 and should have the same BaseName)
'   a) Remove special characters in filenames for file Extensions: .ts .mp4 .mpg and autofix .vprj
'   b) Modify the filenames based on the filename content including reformatting the date in the filename
'	c) Also Modily content of associated .vprj files (they are .xml content) to link to the new media filename since we are modifying the pair
'
'If vrdtvsp_DEBUG Then WScript.StdOut.WriteLine("VRDTVSP DEBUG: about to call vrdtvsp_fix_filenames_in_a_folder_tree(""" & vrdtvsp_source_TS_Folder & """, False)")
WScript.StdOut.WriteLine("======================================================================================================================================================")
WScript.StdOut.WriteLine("" & vrdtvsp_current_datetime_string())
WScript.StdOut.WriteLine("STARTED vrdtvsp_fix_filenames_in_a_folder_tree on SOURCE folder")
file_count_checked = 0
file_count_fixed = 0
vrdtvsp_status = vrdtvsp_fix_filenames_in_a_folder_tree(vrdtvsp_source_TS_Folder, False, file_count_checked, file_count_fixed) ' this does (a) and (b) and (c).  False indicates to process only the top level folder with NO SUBFOLDERS
If vrdtvsp_status <> 0 Then ' Something went wrong with processing files in the Source folder ... check for 53 not found ?
	If vrdtvsp_DEBUG Then WScript.StdOut.WriteLine("VRDTVSP DEBUG: VRDTVSP ERROR - Error " & vrdtvsp_status & " from vrdtvsp_fix_filenames_in_a_folder_tree in """ & vrdtvsp_source_TS_Folder & """... Aborting ...")
	WScript.StdOut.WriteLine("VRDTVSP ERROR - Error " & vrdtvsp_status & " from vrdtvsp_fix_filenames_in_a_folder_tree in """ & vrdtvsp_source_TS_Folder & """ ... Aborting ...")
	Wscript.Echo "Error 17 = cannot perform the requested operation"
	On Error goto 0
	WScript.Quit 17 ' Error 17 = cannot perform the requested operation
End If
WScript.StdOut.WriteLine("FINISHED vrdtvsp_fix_filenames_in_a_folder_tree on SOURCE folder.")
WScript.StdOut.WriteLine("Non-vprj files Checked=" & file_count_checked & " Fixed=" & file_count_fixed)
WScript.StdOut.WriteLine("" & vrdtvsp_current_datetime_string())
WScript.StdOut.WriteLine("======================================================================================================================================================")
'
'----------------------------------------------------------------------------------------------------------------------------------------
' Convert Video files and create the associated .vprj files by running adscan on the media file
' The function filters for file Extensions: .ts .mp4 .mpg and creates .vprj
'
'.................. START video processing for the FULL SOURCE TS folder (not tree) - the function has a big loop - converts .TS .mp4 .mpg Source files then moves them to Done or Failed
' ***** Rely on these already being defined/set Globally BEFORE invoking the conversion function
' ***** 	vrdtvsp_DEBUG
' ***** 	vrdtvsp_DEVELOPMENT_NO_ACTIONS
' ***** 	wso, fso, vrdtvsp_status
' generate a unique filename to save FFMPEG and related commands
vrdtvsp_saved_ffmpeg_commands_filename = fso.GetAbsolutePathName(fso.BuildPath(vrdtvsp_source_TS_Folder, "vrdtvsp_saved_ffmpeg_commands-" & vrdtvsp_run_datetime & ".bat"))
' process the files
WScript.StdOut.WriteLine("======================================================================================================================================================")
WScript.StdOut.WriteLine("" & vrdtvsp_current_datetime_string())
WScript.StdOut.WriteLine("about to vrdtvsp_Convert_files_in_a_folder")
vrdtvsp_status = vrdtvsp_Convert_files_in_a_folder(	vrdtvsp_source_TS_Folder, _
													vrdtvsp_done_TS_Folder, _
													vrdtvsp_destination_mp4_Folder, _
													vrdtvsp_failed_conversion_TS_Folder, _
													vrdtvsp_temp_path, _
													vrdtvsp_saved_ffmpeg_commands_filename, _
													vrdtvsp_do_adscan, _
													vrdtvsp_do_audio_delay )
If vrdtvsp_status <> 0 Then ' Something bad went wrong (invididual conversion failures just result in moving the source file to the Failed folder)
	If vrdtvsp_DEBUG Then WScript.StdOut.WriteLine("VRDTVSP DEBUG: VRDTVSP ERROR - Error " & vrdtvsp_status & " from vrdtvsp_Convert_files_in_a_folder ... Aborting ...")
	WScript.StdOut.WriteLine("VRDTVSP ERROR  VRDTVSP ERROR - Error " & vrdtvsp_status & " from vrdtvsp_Convert_files_in_a_folder ... Aborting ...")
	Wscript.Echo "Error 17 = cannot perform the requested operation"
	On Error goto 0
	WScript.Quit 17 ' Error 17 = cannot perform the requested operation
End If
'.................. END video processing for the FULL SOURCE TS folder (not tree) - the function has a big loop - converts Source files then moves them to Done or Failed
WScript.StdOut.WriteLine("after vrdtvsp_Convert_files_in_a_folder")
WScript.StdOut.WriteLine("" & vrdtvsp_current_datetime_string())
WScript.StdOut.WriteLine("======================================================================================================================================================")
'
'----------------------------------------------------------------------------------------------------------------------------------------
' In Top Level Folders: Destination 
' (the function filters for file Extensions: .ts .mp4 .mpg, and autofixes .vprj which are associated with .mpg and .mp4 and should have the same BaseName)
'   a) Remove special characters in filenames for file Extensions: .ts .mp4 .mpg and autofix .vprj
'   b) Modify the filenames based on the filename content including reformatting the date in the filename
'	c) Also Modily content of associated .vprj files (they are .xml content) to link to the new media filename since we are modifying the pair
'
'If vrdtvsp_DEBUG Then WScript.StdOut.WriteLine("VRDTVSP DEBUG: about to call vrdtvsp_fix_filenames_in_a_folder_tree(""" & vrdtvsp_destination_mp4_Folder & """, True)")
WScript.StdOut.WriteLine("======================================================================================================================================================")
WScript.StdOut.WriteLine("" & vrdtvsp_current_datetime_string())
WScript.StdOut.WriteLine("STARTED vrdtvsp_fix_filenames_in_a_folder_tree on DESTINATION folder and subfolders")
file_count_checked = 0
file_count_fixed = 0
vrdtvsp_status = vrdtvsp_fix_filenames_in_a_folder_tree(vrdtvsp_destination_mp4_Folder, True, file_count_checked, file_count_fixed) ' this does (a) and (b) and (c).  True indicates to process the top level folder including SUBFOLDERS
If vrdtvsp_status <> 0 Then ' Something went wrong with processing files in the Destination folder ... check for 53 not found ?
	If vrdtvsp_DEBUG Then WScript.StdOut.WriteLine("VRDTVSP DEBUG: VRDTVSP ERROR - Error " & vrdtvsp_status & " from vrdtvsp_fix_filenames_in_a_folder_tree in """ & vrdtvsp_destination_mp4_Folder & """... Aborting ...")
	WScript.StdOut.WriteLine("VRDTVSP ERROR - Error " & vrdtvsp_status & " from vrdtvsp_fix_filenames_in_a_folder_tree in """ & vrdtvsp_destination_mp4_Folder & """ ... Aborting ...")
	Wscript.Echo "Error " & vrdtvsp_status
	Wscript.Quit vrdtvsp_status
End If
WScript.StdOut.WriteLine("FINISHED vrdtvsp_fix_filenames_in_a_folder_tree on DESTINATION folder.")
WScript.StdOut.WriteLine("Non-vprj files Checked=" & file_count_checked & " Fixed=" & file_count_fixed)
WScript.StdOut.WriteLine("" & vrdtvsp_current_datetime_string())
WScript.StdOut.WriteLine("======================================================================================================================================================")
'
'----------------------------------------------------------------------------------------------------------------------------------------
' Fix the DateCreated and DateModified timestamps based on the date in the filename (a PowerShell command ... learn how to do that on the commandline)
' in Top Level Folders and Subfolders: Source and Destination (the function filters for file Extensions: .ts .mp4 .mpg but NOT .vprj)
'
WScript.StdOut.WriteLine("======================================================================================================================================================")
WScript.StdOut.WriteLine("" & vrdtvsp_current_datetime_string())
WScript.StdOut.WriteLine("STARTED vrdtvsp_fix_timestamps_in_a_folder_tree on DESTINATION folder and subfolders")
'If vrdtvsp_DEBUG Then WScript.StdOut.WriteLine("VRDTVSP DEBUG: about to call vrdtvsp_fix_timestamps_in_a_folder_tree(""" & vrdtvsp_destination_mp4_Folder & """, False)")
vrdtvsp_status = vrdtvsp_fix_timestamps_in_a_folder_tree(vrdtvsp_destination_mp4_Folder, True) ' False indicates to process the folder with recursion
If vrdtvsp_status <> 0 Then ' Something went wrong with processing files in the Destination folder ... check for 53 not found ?
	If vrdtvsp_DEBUG Then WScript.StdOut.WriteLine("VRDTVSP DEBUG: VRDTVSP ERROR - Error " & vrdtvsp_status & " from vrdtvsp_fix_timestamps_in_a_folder_tree in """ & vrdtvsp_destination_mp4_Folder & """... Aborting ...")
	WScript.StdOut.WriteLine("VRDTVSP ERROR - Error " & vrdtvsp_status & " from vrdtvsp_fix_timestamps_in_a_folder_tree in """ & vrdtvsp_destination_mp4_Folder & """... Aborting ...")
	Wscript.Echo "Error 17 = cannot perform the requested operation"
	On Error goto 0
	WScript.Quit 17 ' Error 17 = cannot perform the requested operation
End If
'
'vrdtvsp_status = vrdtvsp_create_ps1_to_fix_timestamps(vrdtvsp_temp_powershell_filename)
'If vrdtvsp_status <> 0 Then ' Something went wrong with creating the .ps1 file
'	If vrdtvsp_DEBUG Then WScript.StdOut.WriteLine("VRDTVSP DEBUG: VRDTVSP ERROR - Error " & vrdtvsp_status & " from vrdtvsp_create_ps1_to_fix_timestamps with """ & vrdtvsp_temp_powershell_filename & """... Aborting ...")
'	WScript.StdOut.WriteLine("VRDTVSP ERROR - Error " & vrdtvsp_status & " from vrdtvsp_create_ps1_to_fix_timestamps with """ & vrdtvsp_temp_powershell_filename & """... Aborting ...")
'	Wscript.Quit vrdtvsp_status
'End If
'scratch_local_timerStart = Timer
'?????????????????????????????????
' DO THIS IN A SEPARATE FUNCTION:
'if fix_timestamps = True then
'	Set objWscriptShell = CreateObject("Wscript.shell")
'	vrdtvsp_temp_powershell_cmd = "powershell -NoLogo -ExecutionPolicy Unrestricted -Sta -NonInteractive -WindowStyle Normal -File """ & vrdtvsp_temp_powershell_filename & """ -Folder """ & ???thefoldertree??? & """"
'	WScript.StdOut.WriteLine("vbs_rename_files: ***** Fixing file dates using:<" & vrdtvsp_temp_powershell_cmd & ">")
'	???? objWscriptShell.??? exec run vrdtvsp_temp_powershell_cmd, True ?????????? use exec instead with stdout stderr etc
'	Set objWscriptShell = Nothing
'	WScript.StdOut.WriteLine("vbs_rename_files: --- FINISHED for folder <" & aPath & ">")
'end if
'????????????????????????????
'scratch_local_timerEnd = Timer
'WScript.StdOut.WriteLine("VRDTVSP Finished Powershell file timestamp fixing for folder tree """ & ffiaft_folder_tree & """ with Elapsed Time " & vrdtvsp_Calculate_ElapsedTime_string(scratch_local_timerStart, scratch_local_timerEnd))
'vrdtvsp_status = vrdtvsp_delete_a_file(vrdtvsp_temp_powershell_filename, True)
'If vrdtvsp_status <> 0 Then ' Something went wrong with deleting the .ps1 file
'	If vrdtvsp_DEBUG Then WScript.StdOut.WriteLine("VRDTVSP DEBUG: VRDTVSP ERROR - Error " & vrdtvsp_status & " from vrdtvsp_delete_a_file with """ & vrdtvsp_temp_powershell_filename & """... Aborting ...")
'	WScript.StdOut.WriteLine("VRDTVSP ERROR - Error " & vrdtvsp_status & " from vrdtvsp_delete_a_file with """ & vrdtvsp_temp_powershell_filename & """... Aborting ...")
'	Wscript.Quit vrdtvsp_status
'End If
WScript.StdOut.WriteLine("FINISHED vrdtvsp_fix_timestamps_in_a_folder_tree on DESTINATION folder and subfolders")
WScript.StdOut.WriteLine("" & vrdtvsp_current_datetime_string())
WScript.StdOut.WriteLine("======================================================================================================================================================")
'
'----------------------------------------------------------------------------------------------------------------------------------------
' Kill the Insomnia64 process that we started earlier
'
WScript.StdOut.WriteLine("======================================================================================================================================================")
WScript.StdOut.WriteLine("" & vrdtvsp_current_datetime_string())
WScript.StdOut.WriteLine("STARTED Kill Insomnia")
'vrdtvsp_cmd = "TaskKill /t /f /im """ & vrdtvsp_Insomnia64_tmp_filename & """" ' we saved the ProcessId when we started it
vrdtvsp_cmd = "TaskKill /t /f /pid " & vrdtvsp_Insomnia64_ProcessID ' we saved the ProcessId when we started it
' taskkill /t /f /im "%iFile%"
'   /f  Specifies that processes be forcefully ended.
'   /t	Ends the specified process and any child processes started by it.
'   /pid <processID>    Specifies the process ID of the process to be terminated.
'   /im <imagename>     Specifies the image name of the process to be terminated.
WScript.StdOut.WriteLine("VTDRVS TaskKill: TaskKill Insomnia Exec command: " & vrdtvsp_cmd)
set vrdtvsp_exe_obj = wso.Exec(vrdtvsp_cmd)
Do While vrdtvsp_exe_obj.Status = 0 '0 is running and 1 is ending
    Wscript.Sleep 100
Loop
Do Until vrdtvsp_exe_obj.StdOut.AtEndOfStream
    vrdtvsp_tmp = vrdtvsp_exe_obj.StdOut.ReadLine()
    WScript.StdOut.WriteLine("VTDRVS TaskKill: TaskKill Insomnia Exec StdOut: " & vrdtvsp_tmp)
Loop
Do Until vrdtvsp_exe_obj.StdErr.AtEndOfStream
    vrdtvsp_tmp = vrdtvsp_exe_obj.StdErr.ReadLine()
    WScript.StdOut.WriteLine("VTDRVS TaskKill: TaskKill Insomnia Exec StdErr: " & vrdtvsp_tmp)
Loop
vrdtvsp_status = vrdtvsp_exe_obj.ExitCode ' Ignore any error codes returned by taskkill
WScript.StdOut.WriteLine("VTDRVS TaskKill: Insomnia TaskKill Exec Exit Status: " & vrdtvsp_status)
Set vrdtvsp_exe_obj = Nothing
If vrdtvsp_DEBUG Then WScript.StdOut.WriteLine("VRDTVSP DEBUG: VTDRVS TaskKill Insomnia exiting with status=""" & vrdtvsp_status & """")
'
'Delete the temporary Insomnia .exe file
vrdtvsp_exit_code = vrdtvsp_delete_a_file(vrdtvsp_Insomnia64_tmp_filename, True) ' True=silently delete. Ignore any errors.
WScript.StdOut.WriteLine("FINSIHED Kill Insomnia")
WScript.StdOut.WriteLine("" & vrdtvsp_current_datetime_string())
WScript.StdOut.WriteLine("======================================================================================================================================================")
'----------------------------------------------------------------------------------------------------------------------------------------
' Finish and Quit
'
'vrdtvsp_status = vrdtvsp_delete_a_file(vrdtvsp_path_for_qsf_vbs, True) ' True=silently delete it
'vrdtvsp_status = vrdtvsp_delete_a_file(vrdtvsp_path_for_adscan_vbs, True) ' True=silently delete it
'
WScript.StdOut.WriteLine("======================================================================================================================================================")
WScript.StdOut.WriteLine("" & vrdtvsp_current_datetime_string())
vrdtvsp_timer_EndTime_overall = Timer
WScript.StdOut.WriteLine("VRDTVS " & vrdtvsp_ScriptName & " Finished: " & vrdtvsp_current_datetime_string() & "  Elapsed Time: " & vrdtvsp_Calculate_ElapsedTime_string(vrdtvsp_timer_StartTime_overall, vrdtvsp_timer_EndTime_overall))
WScript.StdOut.WriteLine("" & vrdtvsp_current_datetime_string())
WScript.StdOut.WriteLine("======================================================================================================================================================")
If vrdtvsp_DEBUG Then WScript.StdOut.WriteLine("VRDTVSP DEBUG: VTDRVS: " & vrdtvsp_ScriptName & " Finished: " & vrdtvsp_current_datetime_string() & "  Elapsed Time: " & vrdtvsp_Calculate_ElapsedTime_string(vrdtvsp_timer_StartTime_overall, vrdtvsp_timer_EndTime_overall))
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
Function vrdtvsp_get_commandline_parameter(gcp_argument_name, gcp_default_value)
    ' Parameters: 
    '   gcp_argument_name       named argument specified on commandline like 
    '                               /p1:"This is the value for p1"
    '   gcp_default_value       a default value if the parameter is not specified on the commandline (or specified with no value)
    ' Call like this:
    '       x = vrdtvsp_get_commandline_parameter("source_TS_Folder", "G:\HDTV\000-TO-BE-PROCESSED\zzz-TEST\")
    '       x = vrdtvsp_get_commandline_parameter("True_or_False", False)
    ' NOTE: if the commandline parameter is a path or something, it is NOT checked or Absoluted by this function
    Dim gcp_argument_count, gcp_NamedArgs, gcp_Return_Value, gcp_defaulted_or_set
	gcp_defaulted_or_set = "defaulted"
    gcp_argument_count = WScript.Arguments.Count
    gcp_Return_Value = gcp_default_value ' default to return the default_value
    'If vrdtvsp_DEBUG Then 
    '    WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_get_commandline_parameter gcp_argument_name=" & gcp_argument_name)
    '    WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_get_commandline_parameter gcp_default_value=" & gcp_default_value)
    'End If
    If gcp_argument_count > 0 Then
        Set gcp_NamedArgs = WScript.Arguments.Named
        If gcp_NamedArgs.Exists(gcp_argument_name) and NOT IsEmpty(gcp_NamedArgs(gcp_argument_name)) Then ' IsEmpty is a special case of exists but has no value, but is not "" which is different
            gcp_Return_Value = gcp_NamedArgs.Item(gcp_argument_name)
            If vrdtvsp_DEBUG Then WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_get_commandline_parameter obtained commandline Argument: " & gcp_argument_name & "=""" & gcp_Return_Value & """")
            If Ucase(gcp_Return_Value) = Ucase("True")  Then 
                gcp_Return_Value = True    ' if required, convert to boolean True
                'If vrdtvsp_DEBUG Then WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_get_commandline_parameter converted to boolean True gcp_Return_Value=" & gcp_Return_Value)
            End If
            If Ucase(gcp_Return_Value) = Ucase("False") Then 
                gcp_Return_Value = False   ' if required, convert to boolean False
                'If vrdtvsp_DEBUG Then WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_get_commandline_parameter converted to boolean False gcp_Return_Value=" & gcp_Return_Value)
            End If
			gcp_defaulted_or_set = "set"
        End If
        Set gcp_NamedArgs = Nothing
    End If
	' WScript.StdOut.WriteLine("VRDTVSP NOTE: vrdtvsp_get_commandline_parameter " & gcp_defaulted_or_set & ": " & gcp_argument_name & "=""" & gcp_Return_Value & """")
    If vrdtvsp_DEBUG Then WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_get_commandline_parameter " & gcp_defaulted_or_set & ": " & gcp_argument_name & "=""" & gcp_Return_Value & """")
    vrdtvsp_get_commandline_parameter = gcp_Return_Value
End Function
'
Function vrdtvsp_current_datetime_string ()
    'return format: YYYY.MM.DD-HH.MM.SS.mmm
    ' Call like this:
    '       x = vrdtvsp_current_datetime_string()
	Dim t, t_date, tmp, milliseconds
	'capture the date and timer "close together" so if the date changes while the other code runs the values you are using don't change
	t = Timer
	t_date = Now()
	tmp = Int(t)
	milliseconds = Int((t-tmp) * 1000)
    vrdtvsp_current_datetime_string = year(t_date) & "." & Right("00" & month(t_date),2) & "." & Right("00" & day(t_date),2) & "-" & Right("00" & hour(t_date),2) & "." & Right("00" & minute(t_date),2) & "." & Right("00" & second(t_date),2) & "." & Right("000" & milliseconds,3)
End Function
'
Function vrdtvsp_gimme_a_temporary_absolute_filename (gataf_filename_prepend_string)
    ' rely on global variable "fso"
    ' rely on global variable "vrdtvsp_temp_path" being set to a valid path for the temporary file
    ' rely on function vrdtvsp_current_datetime_string
    ' Parameters: 
    '   gataf_filename_prepend_string       allows better identification of what the temporary file is associate with
    ' Call like this:
    '       x = vrdtvsp_gimme_a_temporary_absolute_filename("a_base_filename_text_string")
    Dim gataf_temp
    'If vrdtvsp_DEBUG Then WScript.StdOut.WriteLine("VRDTVSP DEBUG: entered vrdtvsp_gimme_a_temporary_absolute_filename")
    gataf_temp = gataf_filename_prepend_string & "-" & vrdtvsp_current_datetime_string() & "-" & fso.GetTempName ' ".tmp" already added
    gataf_temp = fso.GetAbsolutePathName(fso.BuildPath(vrdtvsp_temp_path,gataf_temp)) ' rely on global variable "vrdtvsp_temp_path" already being set to a valid path
    'If vrdtvsp_DEBUG Then WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_gimme_a_temporary_absolute_filename generated a_temporary_filename=""" & gataf_temp & """")
    vrdtvsp_gimme_a_temporary_absolute_filename = gataf_temp
End Function
'
Function vrdtvsp_delete_a_file (filename_to_delete, do_it_silently)
    ' rely on global variable "fso"
    ' Parameters:
    '   filename_to_delete      a fully qualified filename
    '   do_it_silently          true or false
    ' Call like this:
    '       x = vrdtvsp_delete_a_file("c:\temp\temp.tmp",False)
    Dim daf_Err_number, daf_Err_Description, daf_Err_Helpfile, daf_Err_HelpContext
    Dim daf_filename_to_delete
    If NOT do_it_silently Then WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_delete_a_file Deleting file: """ & filename_to_delete & """")
    If vrdtvsp_DEBUG Then WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_delete_a_file Deleting file: """ & filename_to_delete & """")
    'If fso.FileExists(filename_to_delete) Then
    	On Error Resume Next
	    fso.DeleteFile filename_to_delete, True ' fso.DeleteFile ( filespec[, force] ) ' it also supports wildcards, allowing delete of multiple files ...
	    daf_Err_number = Err.Number
        daf_Err_Description = Err.Description
        daf_Err_Helpfile = Err.Helpfile
        daf_Err_HelpContext = Err.HelpContext
        If daf_Err_number <> 0 Then
            If NOT do_it_silently Then WScript.StdOut.WriteLine("VRDTVSP ERROR: vrdtvsp_delete_a_file error " &  daf_Err_number &  " """ &  daf_Err_Description & """ : raised when Deleting file """ & filename_to_delete & """")
            'If vrdtvsp_DEBUG Then WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_delete_a_file Error " &  daf_Err_number &  " """ &  daf_Err_Description & """ : raised when Deleting file """ & filename_to_delete & """")
	        Err.Clear
        Else
            If NOT do_it_silently Then WScript.StdOut.WriteLine("vrdtvsp_delete_a_file Deleted file """ & filename_to_delete & """")
            'If vrdtvsp_DEBUG Then WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_delete_a_file Deleted file """ & filename_to_delete & """")
        End if
	    On Error Goto 0 ' now continue
    'End If
    'If vrdtvsp_DEBUG Then WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_delete_a_file exiting with status=""" & daf_Err_number & """")
    vrdtvsp_delete_a_file = daf_Err_number
End Function
'
Function vrdtvsp_move_files_to_folder (mf_source_path_wildcard, mv_destination_folder)
	' deliberately no code for saving commands to move files
    ' rely on global variable "fso"
    ' Parameters:
    '   mf_source_path_wildcard     
    '   mv_destination_folder
    ' Call like this:
    '       result = vrdtvsp_move_files_to_folder("G:\SOME_SOURCE_PATH\*.MPG", "G:\SOME_DESTINATION_PATH\")
    '            which does a DOS command something like MOVE /Y "G:\SOME_SOURCE_PATH\*.MPG" "G:\SOME_DESTINATION_PATH\" 
    Dim mf_exe, mf_cmd, mf_status, mf_tmp
    Dim mf_source_AbsolutePath, mf_destination_AbsolutePath
    'If vrdtvsp_DEBUG Then WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_move_files_to_folder: """ & mf_source_path_wildcard & """" & " to """ &  mv_destination_folder & """")
    mf_source_AbsolutePath = fso.GetAbsolutePathName(mf_source_path_wildcard)
    mf_destination_AbsolutePath = fso.GetAbsolutePathName(mv_destination_folder)
    If Right(mf_destination_AbsolutePath,1) <> "\" Then
        mf_destination_AbsolutePath = mf_destination_AbsolutePath & "\"     ' add a trailing backslash for DOS MOVE to recognise the destination pathname
    End If
    If vrdtvsp_DEBUG Then
       ' WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_move_files_to_folder      mf_source_AbsolutePath=""" & mf_source_AbsolutePath & """")
        'WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_move_files_to_folder mf_destination_AbsolutePath=""" & mf_destination_AbsolutePath & """")
    End If
	'
	' THE OLD WAY OF DOING IT
	'
	' Ugh, a DOS MOVE requires CMD /C  to work !! 
    'mf_cmd = "CMD /C MOVE /Y """ & mf_source_AbsolutePath & """ """ & mf_destination_AbsolutePath & """ 2>&1"
	'If vrdtvsp_DEVELOPMENT_NO_ACTIONS Then ' DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV 
	'	mf_cmd = "REM " & mf_cmd ' do not move anything 
	'End If
	'WScript.StdOut.WriteLine("vrdtvsp_move_files_to_folder Exec command: " & mf_cmd)
    'set mf_exe = wso.Exec(mf_cmd)
    'Do While mf_exe.Status = 0 '0 is running and 1 is ending
    '     Wscript.Sleep 100
    'Loop
    'Do Until mf_exe.StdOut.AtEndOfStream
    '    mf_tmp = mf_exe.StdOut.ReadLine()
    '    WScript.StdOut.WriteLine("vrdtvsp_move_files_to_folder StdOut: " & mf_tmp)
    'Loop
    'Do Until mf_exe.StdErr.AtEndOfStream
    '    mf_tmp = mf_exe.StdErr.ReadLine()
    '    WScript.StdOut.WriteLine("vrdtvsp_move_files_to_folder StdErr: " & mf_tmp)
    'Loop
    'mf_status = mf_exe.ExitCode
    'WScript.StdOut.WriteLine("vrdtvsp_move_files_to_folder Exit Status: " & mf_status)
    'Set mf_exe = Nothing
    'If vrdtvsp_DEBUG Then WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_move_files_to_folder exiting with status=""" & mf_status & """")
	'
	' THE NEW WAY OF DOING IT
	'
	mf_cmd = "MOVE /Y """ & mf_source_AbsolutePath & """ """ & mf_destination_AbsolutePath & """"
	ReDim vrdtvsp_Exec_in_a_DOS_BAT_file_cmd_array(2) ' base 0, so the dimension is always 1 less than the number of commands
	vrdtvsp_Exec_in_a_DOS_BAT_file_cmd_array(0) = "REM " & vrdtvsp_current_datetime_string()
	vrdtvsp_Exec_in_a_DOS_BAT_file_cmd_array(1) = "ECHO !DATE! !TIME!"
	vrdtvsp_Exec_in_a_DOS_BAT_file_cmd_array(2) = mf_cmd ' for the final return status to be good, this must be the final command in the array
	' deliberately no code for saving commands to move files
	mf_status = vrdtvsp_Exec_in_a_DOS_BAT_file(vrdtvsp_Exec_in_a_DOS_BAT_file_cmd_array, True, True) ' print .bat, do the commands, print .log
	Erase vrdtvsp_Exec_in_a_DOS_BAT_file_cmd_array
    vrdtvsp_move_files_to_folder = mf_status
End Function
'
Function vrdtvsp_Calculate_ElapsedTime_ms (timer_StartTime, timer_EndTime)
    ' Parameters:
    '   timer_StartTime
    '   timer_EndTime
    ' Call like this:
    '       dim timer_StartTime, timer_EndTime
    '       timer_StartTime = Timer()
    '       Wscript.Sleep 750 ' milliseconds
    '       timer_EndTime = Timer()
    '       Wscript.Echo "Function Elapsed Time in ms : " & vrdtvsp_Calculate_ElapsedTime_ms(timer_StartTime, timer_EndTime)
    vrdtvsp_Calculate_ElapsedTime_ms = Round(timer_EndTime - timer_StartTime, 3) * 1000 ' round to 3 decimal places is milliseconds
End Function
'
Function vrdtvsp_Calculate_ElapsedTime_string (timer_StartTime, timer_EndTime)
    ' Parameters:
    '   timer_StartTime
    '   timer_EndTime
    ' Call like this:
    '       dim timer_StartTime, timer_EndTime
    '       timer_StartTime = Timer()
    '       Wscript.Sleep 750 ' milliseconds
    '       timer_EndTime = Timer()
    '       Wscript.Echo "Function Elapsed Time String: " & vrdtvsp_Calculate_ElapsedTime_string(timer_StartTime, timer_EndTime)
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
        vrdtvsp_Calculate_ElapsedTime_string = FormatNumber(seconds,3) & " second" & seconds_plural
        Exit Function
    End If
    If seconds < SECONDS_IN_HOUR Then 
        minutes = seconds / SECONDS_IN_MINUTE
        seconds = seconds MOD SECONDS_IN_MINUTE
        vrdtvsp_Calculate_ElapsedTime_string = Int(minutes) & " minutes " & FormatNumber(seconds,3) & " second" & seconds_plural
        Exit Function
    End If
    If seconds < SECONDS_IN_DAY Then
        hours   = seconds / SECONDS_IN_HOUR
        minutes = (seconds MOD SECONDS_IN_HOUR) / SECONDS_IN_MINUTE
        seconds = (seconds MOD SECONDS_IN_HOUR) MOD SECONDS_IN_MINUTE
        vrdtvsp_Calculate_ElapsedTime_string = Int(hours) & " hours " & Int(minutes) & " minutes " & FormatNumber(seconds,3) & " second" & seconds_plural
        Exit Function
    End If
    If seconds < SECONDS_IN_WEEK Then
        days    = seconds / SECONDS_IN_DAY
        hours   = (seconds MOD SECONDS_IN_DAY) / SECONDS_IN_HOUR
        minutes = ((seconds MOD SECONDS_IN_DAY) MOD SECONDS_IN_HOUR) / SECONDS_IN_MINUTE
        seconds = ((seconds MOD SECONDS_IN_DAY) MOD SECONDS_IN_HOUR) MOD SECONDS_IN_MINUTE
        vrdtvsp_Calculate_ElapsedTime_string = Int(days) & " days " & Int(hours) & " hours " & Int(minutes) & " minutes " & FormatNumber(seconds,3) & " second" & seconds_plural
        Exit Function
    End If
End Function
'
Function vrdtvsp_get_mediainfo_parameter (byVAL mi_Section, byVAL mi_Parameter, byVAL mi_MediaFilename, byVAL mi_Legacy) 
    ' rely on global variable "wso"
    ' rely on global variable vrdtvsp_mediainfoexe64 exists pointing to the mediainfo exe
    ' Note \r\n is Windows new-line, 
    '   Which in the case of multiple audio streams, outputs a result for each stream on a new line, 
    '   the first stream being the first entry, and the first audio stream should be the one we need. 
    ' Parameters:
    '   mi_Section          eg "Video" "Auidio" "General"
    '   mi_Parameter        name of parameter to fetch eg "DisplayAspectRatio/String"
    '   mi_MediaFilename    fully qualified (Absolute) filename of the media file to query
    '   mi_Legacy           "" or "--Legacy" to invoke old the old mediainfo parameter name/value pairs
    ' Call like this:
    '       dim V_Width, V_Height
    '       V_Width = get_mediainfo_parameter("Video","Width","G:\HDTV\000-TO-BE-PROCESSED\zzz-TEST\VRDTVSP-Converted\News-ABC_Evening_News.2021-02-05.mp4", "")
    '       V_Height = get_mediainfo_parameter("Video","Height","G:\HDTV\000-TO-BE-PROCESSED\zzz-TEST\VRDTVSP-Converted\News-ABC_Evening_News.2021-02-05.mp4", "")
	'
	Dim mi_exe
    Dim mi_cmd, mi_status, mi_tmp
    'Dim mi_temp_Filename
    If vrdtvsp_DEBUG Then
        WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_get_mediainfo_parameter       mi_Section= " & mi_Section)
        WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_get_mediainfo_parameter     mi_Parameter= " & mi_Parameter)
        WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_get_mediainfo_parameter mi_MediaFilename= " & mi_MediaFilename)
        WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_get_mediainfo_parameter        mi_Legacy= " & mi_Legacy)
    End If
    If Ucase(mi_Legacy) <> Ucase("--Legacy") AND Ucase(mi_Legacy) <> "" Then
        WScript.StdOut.WriteLine("VRDTVSP ERROR: vrdtvsp_get_mediainfo_parameter UNRECOGNISED LEGACY PARAMETER: " & mi_Legacy & " : it should only be an empty string or --Legacy")
        ' Err.Raise 17 ' Error 17 = cannot perform the requested operation
		Wscript.Echo "Error 17 = cannot perform the requested operation"
		On Error goto 0
		WScript.Quit 17 ' Error 17 = cannot perform the requested operation
    End If
    '
    ' If piping to a temporary file, cmd looks something like this:
    ' mi_temp_Filename = vrdtvsp_gimme_a_temporary_absolute_filename() ' generate a fully qualified temporary filename from the function
    ' mi_status = delete_a_file (mi_temp_Filename, True)
    ' mi_cmd =  """" & vrdtvsp_mediainfoexe64 & """ " & mi_Legacy & " ""--Inform=" & mi_Section & ";%" & mi_Parameter & "%\r\n"" """ & mi_MediaFilename & """ > """ & mi_temp_Filename & """"
    '
    mi_cmd = """" & vrdtvsp_mediainfoexe64 & """ " & mi_Legacy & " ""--Inform=" & mi_Section & ";%" & mi_Parameter & "%\r\n"" """ & mi_MediaFilename & """"
    If vrdtvsp_DEBUG Then WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_get_mediainfo_parameter Exec command: " & mi_cmd)
    set mi_exe = wso.Exec(mi_cmd)
    Do While mi_exe.Status = 0 '0 is running and 1 is ending
        Wscript.Sleep 100
    Loop
    Do Until mi_exe.StdErr.AtEndOfStream
        mi_tmp = mi_exe.StdErr.ReadLine()
        WScript.StdOut.WriteLine("VRDTVSP ERROR: vrdtvsp_get_mediainfo_parameter StdErr: " & mi_tmp)
    Loop
    mi_status = mi_exe.ExitCode
    If mi_status <> 0 then
        WScript.StdOut.WriteLine("VRDTVSP ERROR: vrdtvsp_get_mediainfo_parameter ABORTING with Exec command: " & mi_cmd)
        WScript.StdOut.WriteLine("VRDTVSP ERROR: vrdtvsp_get_mediainfo_parameter ABORTING with  Exit Status: " & mi_status)
        ' Err.Raise 17 ' Error 17 = cannot perform the requested operation
		'Wscript.Echo "Error 17 = cannot perform the requested operation"
		'On Error goto 0
		'WScript.Quit 17 ' Error 17 = cannot perform the requested operation
		On Error goto 0
		' *** 2021.02.27 LET IT CONTINUE WITH A BLANK RESULT
		mi_tmp=""
    End If
    mi_tmp="" ' default to Nothing
    Do Until mi_exe.StdOut.AtEndOfStream ' we need to read only one line though
        mi_tmp = mi_exe.StdOut.ReadLine()
        If vrdtvsp_DEBUG Then WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_get_mediainfo_parameter StdOut: " & mi_tmp)
        Exit Do ' we need to read only THE FIRST line so exit loop immediately after doing that
    Loop
    Set mi_exe = Nothing
    If vrdtvsp_DEBUG Then WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_get_mediainfo_parameter exiting with value: " & mi_tmp)
    vrdtvsp_get_mediainfo_parameter = mi_tmp
End Function
'
Function vrdtvsp_get_ffprobe_video_stream_parameter (byVAL ffp_Parameter, byVAL ffp_MediaFilename) 
    ' rely on global variable "wso"
    ' rely on global variable vrdtvsp_ffprobeexe64 exists pointing to the ffprobe exe
    ' Note \r\n is Windows new-line, which is for the case of multiple audio streams, 
    '      it outputs a result for each stream on a new line, the first stream being the first entry,
    '      and the first audio stream should be the one we need. 
    '      read only the first line.
    ' Parameters:
    '   ffp_Parameter       name of parameter to fetch eg "duration"
    '   ffp_MediaFilename   fully qualified (Absolute) filename of the media file to query
    ' Call like this:
    '       dim V_Width_FF, V_Height_FF, V_Duration_s_FF, V_BitRate_FF, V_BitRate_Maximum_FF
    '       V_Width_FF = get_ffprobe_video_stream_parameter("width","G:\HDTV\000-TO-BE-PROCESSED\zzz-TEST\VRDTVSP-Converted\News-ABC_Evening_News.2021-02-05.mp4")
    '       V_Height_FF = get_ffprobe_video_stream_parameter("height","G:\HDTV\000-TO-BE-PROCESSED\zzz-TEST\VRDTVSP-Converted\News-ABC_Evening_News.2021-02-05.mp4")
    '       V_Duration_s_FF = get_ffprobe_video_stream_parameter("duration","G:\HDTV\000-TO-BE-PROCESSED\zzz-TEST\VRDTVSP-Converted\News-ABC_Evening_News.2021-02-05.mp4")
    '       V_BitRate_FF = get_ffprobe_video_stream_parameter("bit_rate","G:\HDTV\000-TO-BE-PROCESSED\zzz-TEST\VRDTVSP-Converted\News-ABC_Evening_News.2021-02-05.mp4")
    '       V_BitRate_Maximum_FF = get_ffprobe_video_stream_parameter("max_bit_rate","G:\HDTV\000-TO-BE-PROCESSED\zzz-TEST\VRDTVSP-Converted\News-ABC_Evening_News.2021-02-05.mp4")
    '       Wscript.echo("V_Width_FF=" & V_Width_FF & " V_Height_FF=" & V_Height_FF)
    '       Wscript.echo("V_Duration_s_FF=" & V_Duration_s_FF)
    '       Wscript.echo("V_BitRate_FF=" & V_BitRate_FF)
    '       Wscript.echo("V_BitRate_Maximum_FF=" & V_BitRate_Maximum_FF)
    Dim ffp_exe
    Dim ffp_cmd, ffp_status, ffp_tmp
    If vrdtvsp_DEBUG Then
        WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_get_ffprobe_video_stream_parameter     ffp_Parameter= " & ffp_Parameter)
        WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_get_ffprobe_video_stream_parameter ffp_MediaFilename= " & ffp_MediaFilename)
    End If
    '
    ' If piping to a temporary file, cmd looks something like this:
    ' ffp_temp_Filename = gimme_a_temporary_absolute_filename() ' generate a fully qualified temporary filename from the function
    ' ffp_status = delete_a_file (ffp_temp_Filename, True)
    ' ffp_cmd =  """" & vrdtvsp_ffprobeexe64 & ???  & ffp_MediaFilename & """ > """ & ffp_temp_Filename & """"
    '
    ffp_cmd = """" & vrdtvsp_ffprobeexe64 & """ -hide_banner -v quiet -select_streams v:0 -show_entries stream=" & ffp_Parameter & " -of default=noprint_wrappers=1:nokey=1 """ & ffp_MediaFilename & """"
    If vrdtvsp_DEBUG Then WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_get_ffprobe_video_stream_parameter Exec command: " & ffp_cmd)
    set ffp_exe = wso.Exec(ffp_cmd)
    Do While ffp_exe.Status = 0 '0 is running and 1 is ending
        Wscript.Sleep 100
    Loop
    Do Until ffp_exe.StdErr.AtEndOfStream
        ffp_tmp = ffp_exe.StdErr.ReadLine()
        WScript.StdOut.WriteLine("VRDTVSP ERROR: vrdtvsp_get_ffprobe_video_stream_parameter StdErr: " & ffp_tmp)
    Loop
    ffp_status = ffp_exe.ExitCode
    If ffp_status <> 0 then
        WScript.StdOut.WriteLine("VRDTVSP ERROR: vrdtvsp_get_ffprobe_video_stream_parameter ABORTING with Exec command: " & ffp_cmd)
        WScript.StdOut.WriteLine("VRDTVSP ERROR: vrdtvsp_get_ffprobe_video_stream_parameter ABORTING with  Exit Status: " & ffp_status)
        '' Err.Raise 17 ' Error 17 = cannot perform the requested operation
		'Wscript.Echo "Error 17 = cannot perform the requested operation"
		On Error goto 0
		' *** 2021.02.27 LET IT CONTINUE WITH A BLANK RESULT
		ffp_tmp=""
    End If
    ffp_tmp="" ' default to Nothing
    Do Until ffp_exe.StdOut.AtEndOfStream ' we need to read only one line though
        ffp_tmp = ffp_exe.StdOut.ReadLine()
        If vrdtvsp_DEBUG Then WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_get_ffprobe_video_stream_parameter StdOut: " & ffp_tmp)
     Exit Do ' we need to read only one line so exit loop immediately
    Loop
    Set ffp_exe = Nothing
    If vrdtvsp_DEBUG Then WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_get_ffprobe_video_stream_parameter exiting with value: " & ffp_tmp)
    vrdtvsp_get_ffprobe_video_stream_parameter = ffp_tmp
End Function
'
Function vrdtvsp_remove_special_characters_from_string(rsp_string, rsp_is_an_AbsolutePath) ' treat only the "BaseName" component of an Absolute Patch and return the treated Absolute Path
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
    'If vrdtvsp_DEBUG Then
    '    WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_remove_special_characters_from_string             rsp_string= " & rsp_string)
    '    WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_remove_special_characters_from_string rsp_is_an_AbsolutePath= " & rsp_is_an_AbsolutePath)
    'End If
    rsp_tmp = rsp_string
    If rsp_is_an_AbsolutePath Then
        rsp_AbsolutePath = fso.GetAbsolutePathName(rsp_string)
        rsp_ParentFolderName = fso.GetParentFolderName(rsp_AbsolutePath) 
        rsp_BaseName = fso.GetBaseName(rsp_AbsolutePath)
        rsp_ExtName = fso.GetExtensionName(rsp_AbsolutePath)
        rsp_tmp = rsp_BaseName
        'If vrdtvsp_DEBUG Then
        '    WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_remove_special_characters_from_string rsp_ParentFolderName= " & rsp_ParentFolderName)
        '    WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_remove_special_characters_from_string         rsp_BaseName= " & rsp_BaseName)
        '    WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_remove_special_characters_from_string          rsp_ExtName= " & rsp_ExtName)
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
    'If vrdtvsp_DEBUG Then WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_remove_special_characters_from_string exiting with return value: " & rsp_result)
    vrdtvsp_remove_special_characters_from_string = rsp_result
End Function
'
'----------------------------------------------------------------------------------------------------------------------------------------
'----------------------------------------------------------------------------------------------------------------------------------------
'----------------------------------------------------------------------------------------------------------------------------------------
'****************************************************************************************************************************************
'****************************************************************************************************************************************
'****************************************************************************************************************************************
'
Function vrdtvsp_fix_filenames_in_a_folder_tree (the_folder_tree, do_subfolders_as_well, byRef ffiaft_count_checked, byRef ffiaft_count_fixed) 
	' Function to traverse a folder tree ( a called function filters for file Extensions: .ts .mp4 .mpg)
	'   a) Remove special characters in filenames for file Extensions: .ts .mp4 .mpg and autofixes associated .vprj
	'   b) modify the filenames based on the filename content including reformatting the date in the filename
	' rely on global variable "fso"
    ' Parameters:
	'	the_folder_tree			the top level folder to process
    '   do_subfolders_as_well	False flags to process only the top level folder with NO SUBFOLDERS
    ' Call like this:
    '       status = vrdtvsp_fix_filenames_in_a_folder_tree ("G:\HDTV\", False) 
	Dim ffiaft_folder_tree
    Dim vrdtvsp_folder_object
    Dim vrdtvsp_f_object
	Dim local_timerStart, local_timerEnd
	Dim local_timerStart_2, local_timerEnd_2
	local_timerStart = Timer
	local_timerEnd = Timer
	local_timerStart_2 = Timer
	local_timerEnd_2 = Timer
	ffiaft_count_checked = 0
	ffiaft_count_fixed = 0
	'
	ffiaft_folder_tree = the_folder_tree
    If NOT fso.FolderExists(ffiaft_folder_tree) Then
	    WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_fix_filenames_in_a_folder_tree: Folder named """ & ffiaft_folder_tree & """ does NOT EXIST ... not processed by vrdtvsp_fix_filenames_in_a_folder_tree")
	    If vrdtvsp_DEBUG Then WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_fix_filenames_in_a_folder_tree: Folder named """ & ffiaft_folder_tree & """ does NOT EXIST ... not processed by vrdtvsp_fix_filenames_in_a_folder_tree")
        vrdtvsp_fix_filenames_in_a_folder_tree = 53 ' 53 = File not found
	    Exit Function
    End If
    '
	'If vrdtvsp_DEBUG Then WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_fix_filenames_in_a_folder_tree: Started basic file renames for folder tree """ & ffiaft_folder_tree & """")
	Set vrdtvsp_folder_object = fso.GetFolder(ffiaft_folder_tree)            ' get an object of the specified top level folder to process
	Call vrdtvsp_ffiaft_Process_Files_In_Subfolders (vrdtvsp_folder_object, do_subfolders_as_well, ffiaft_count_checked, ffiaft_count_fixed)   ' process the content (files, folders) of that specified top level folder and if specified the SUBFOLDERS too
    Set vrdtvsp_folder_object = Nothing                                      ' finished, disppose of the object
	local_timerEnd = Timer
	'If vrdtvsp_DEBUG Then WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_fix_filenames_in_a_folder_tree: Finished basic file renames for folder tree """ & ffiaft_folder_tree & """ with Elapsed Time " & vrdtvsp_Calculate_ElapsedTime_string(local_timerStart, local_timerEnd))
    '
	local_timerEnd_2 = Timer
	'If vrdtvsp_DEBUG Then 
	'	WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_fix_filenames_in_a_folder_tree: Finished all fixing for folder tree """ & ffiaft_folder_tree & """ with Elapsed Time " & vrdtvsp_Calculate_ElapsedTime_string(local_timerStart_2, local_timerEnd_2))
	'End If
	vrdtvsp_fix_filenames_in_a_folder_tree = 0 ' return with status 0
End Function
'
Sub vrdtvsp_ffiaft_Process_Files_In_Subfolders (objSpecifiedFolder, do_subfolders_as_well, byRef vrdtvsp_ffiaft_count_checked, byRef vrdtvsp_ffiaft_count_fixed) ' Process all files in specified folder tree
	' Function to Process all files in specified folder tree OBJECT with file Extensions: .ts .mp4 .mpg
	'   a) Remove special characters in filenames for file Extensions: .ts .mp4 .mpg and autofixes associated .vprj
	'   b) modify the filenames based on the filename content including reformatting the date in the filename
	'   c) *** NOT THIS, do it outside : fix the file DateCreated and DateModified timestamps based on the date in the filename (a PowerShell command ... since DateCreated can't be modified in vbscript)
    ' rely on global variable "fso"
    ' Parameters:
	'	objSpecifiedFolder		Object from fso.GETFOLDER of the top level folder to process
    '   do_subfolders_as_well	False flags to process only the top level folder with NO SUBFOLDERS
    ' Call like this:
    '       status = vrdtvsp_ffiaft_Process_Files_In_Subfolders (folder_object, False) 
	Dim objCurrentFolder, objColFiles, objSubFolder, objFile, ext
	Dim tmp_no_fixed
	tmp_no_fixed = 0
	If vrdtvsp_DEBUG Then WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_ffiaft_Process_Files_In_Subfolders: Started with incoming folder path """ & fso.GetFolder(objSpecifiedFolder.Path) & """")
    Set objCurrentFolder = fso.GetFolder(objSpecifiedFolder.Path) ' get a NEW instance of a folder object (keep for recursion)
	If vrdtvsp_DEBUG Then WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_ffiaft_Process_Files_In_Subfolders: Started with " & objCurrentFolder.Files.Count & " files in folder """ & fso.GetFolder(objSpecifiedFolder.Path) & """")
    ' Process all files in the current folder
    Set objColFiles = objCurrentFolder.Files ' get an object of a collection of files for the folder object
    For Each objFile in objColFiles
		If vrdtvsp_DEBUG Then WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_ffiaft_Process_Files_In_Subfolders: found File in collection=""" & objFile.Path & """")
        ext = UCase(fso.GetExtensionName(objFile.name))
        '********* FILTER BY FILE EXTENSION *********
		If ext = Ucase("ts") OR ext = Ucase("mp4") OR ext = Ucase("mpg") Then ' ********** only process specific file extensions
			tmp_no_fixed = 0
			vrdtvsp_ffiaft_count_checked = vrdtvsp_ffiaft_count_checked + 1
			If vrdtvsp_DEBUG Then WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_ffiaft_Process_Files_In_Subfolders: recognised Extension of file in collection=""" & objFile.Path & """ and about to call vrdtvsp_ffiaft_pfis_Rename_a_File")
            tmp_no_fixed = vrdtvsp_ffiaft_pfis_Rename_a_File(objFile)'  fso.GetAbsolutePathName(objFile.Path) should be the fully qualified absolute filename of this file
			vrdtvsp_ffiaft_count_fixed = vrdtvsp_ffiaft_count_fixed + tmp_no_fixed
        End If
        '********* FILTER BY FILE EXTENSION *********
		Next
    Set objColFiles = Nothing
	If do_subfolders_as_well Then
    	' If specified, locate and recursively process subfolders of the current folder
    	For Each objSubFolder in objCurrentFolder.SubFolders
        	Call vrdtvsp_ffiaft_Process_Files_In_Subfolders(objSubFolder, do_subfolders_as_well, vrdtvsp_ffiaft_count_checked, vrdtvsp_ffiaft_count_fixed)
    	Next
    	Set objCurrentFolder = Nothing
	End If
End Sub
'
Function vrdtvsp_ffiaft_pfis_Rename_a_File (objSpecifiedFile) 
    ' Process a specific file ... fso.GetAbsolutePathName(objSpecifiedFile.Path) should be the fully qualified absolute filename of this file
    ' Parameters:
	'		objSpecifiedFile is already pre-filtered beforehand to be one of ts mp4 mpg
    Dim theOriginalAbsoluteFilename, theOriginalParentFolderName, theOriginalBaseName, theOriginalExtName
    Dim NewBaseName, newAbsoluteFilename
	Dim Final_Renamed_AbsoluteFilename_AfterRetries, Final_Renamed_ParentFolderName, Final_Renamed_BaseName, Final_Renamed_ExtName
	Dim Original_vprj_AbsoluteFilename, Final_Renamed_vprj_AbsoluteFilename
	Dim local_timerStart, local_timerEnd
	Dim tmp_count_fixed
	local_timerStart = Timer
	local_timerEnd = Timer
	tmp_count_fixed = 0
    theOriginalAbsoluteFilename = fso.GetAbsolutePathName(objSpecifiedFile.Path) ' should already be fully qualified but do it anyway just to be safe
    theOriginalParentFolderName = fso.GetParentFolderName(theOriginalAbsoluteFilename)
    theOriginalBaseName = fso.GetBaseName(theOriginalAbsoluteFilename)
    theOriginalExtName = fso.GetExtensionName(theOriginalAbsoluteFilename) ' does not include  the "."
    '
    If vrdtvsp_DEBUG Then WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_ffiaft_pfis_Rename_a_File: entered Sub with original BaseName """ & theOriginalBaseName & """ from """ & theOriginalAbsoluteFilename & """")
    NewBaseName = theOriginalBaseName ' initialize so we can keep the original stuff if we need i in the future
    NewBaseName = vrdtvsp_remove_special_characters_from_string(NewBaseName, False) ' flag is not an Absolute filename by passing False to the function
    'If vrdtvsp_DEBUG Then WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_ffiaft_pfis_Rename_a_File: after vrdtvsp_remove_special_characters_from_string original BaseName """ & theOriginalBaseName & """ NewBaseName """ & NewBaseName & """")
    NewBaseName = vrdtvsp_remove_tvs_classifying_stuff_from_string(NewBaseName)
    'If vrdtvsp_DEBUG Then WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_ffiaft_pfis_Rename_a_File: after vrdtvsp_remove_tvs_classifying_stuff_from_string original BaseName """ & theOriginalBaseName & """ NewBaseName """ & NewBaseName & """")
    NewBaseName = vrdtvsp_Move_Date_to_End_of_String(NewBaseName)
    If vrdtvsp_DEBUG Then WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_ffiaft_pfis_Rename_a_File: after vrdtvsp_Move_Date_to_End_of_String original BaseName """ & theOriginalBaseName & """ NewBaseName """ & NewBaseName & """")
	'
	'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	newAbsoluteFilename = fso.GetAbsolutePathName(fso.BuildPath(theOriginalParentFolderName,NewBaseName & "." & theOriginalExtName))
	If ucase(NewBaseName) = Ucase(theOriginalBaseName) Then ' no change to filename
		If vrdtvsp_DEBUG Then 
		'	WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_ffiaft_pfis_Rename_a_File: NO NEED for a Rename, no change: theOriginalBaseName=""" & theOriginalBaseName & """" )
		'	WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_ffiaft_pfis_Rename_a_File: NO NEED for a Rename, no change: theOriginalAbsoluteFilename=""" & theOriginalAbsoluteFilename & """" )
		End If
		Final_Renamed_AbsoluteFilename_AfterRetries = theOriginalAbsoluteFilename
		Final_Renamed_ParentFolderName = fso.GetParentFolderName(theOriginalAbsoluteFilename)
		Final_Renamed_BaseName = fso.GetBaseName(theOriginalAbsoluteFilename)
		Final_Renamed_ExtName = fso.GetExtensionName(theOriginalAbsoluteFilename) ' does not include  the "."
	Else ' is a change to the filename
		tmp_count_fixed = 1
		If vrdtvsp_DEBUG Then 
			'WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_ffiaft_pfis_Rename_a_File: needs a Rename using theOriginalBaseName=""" & theOriginalBaseName & """" )
			'WScript.StdOut.WriteLine("                                                                       NewBaseName=""" & NewBaseName & """" )
			'WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_ffiaft_pfis_Rename_a_File: needs a Rename using theOriginalAbsoluteFilename=""" & theOriginalAbsoluteFilename & """" )
			'WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_ffiaft_pfis_Rename_a_File:                              newAbsoluteFilename=""" & newAbsoluteFilename & """" )
		End If
		Final_Renamed_AbsoluteFilename_AfterRetries = vrdtvsp_do_a_Rename_Try99Times(theOriginalAbsoluteFilename, newAbsoluteFilename) ' AUTOFIXING a .vprj OCCURS AFTER THIS FUNCTION
		If Final_Renamed_AbsoluteFilename_AfterRetries = "" Then
			' Silly Error detected here, it should never occur unless we have some sort of logic issue ;)
			WScript.StdOut.WriteLine("VRDTVSP ERROR: vrdtvsp_ffiaft_pfis_Rename_a_File ABORTING: Final_Renamed_AbsoluteFilename_AfterRetries is not properly set after vrdtvsp_do_a_Rename_Try99Times <" & Final_Renamed_AbsoluteFilename_AfterRetries & ">")
			Wscript.Echo "Error 17 = cannot perform the requested operation"
			On Error goto 0
			WScript.Quit 17 ' Error 17 = cannot perform the requested operation
		End If
		Final_Renamed_ParentFolderName = fso.GetParentFolderName(Final_Renamed_AbsoluteFilename_AfterRetries)
		Final_Renamed_BaseName = fso.GetBaseName(Final_Renamed_AbsoluteFilename_AfterRetries)
		Final_Renamed_ExtName = fso.GetExtensionName(Final_Renamed_AbsoluteFilename_AfterRetries) ' does not include  the "."
	End If
	'
	' Process an associated .vprj, if one exists
	vrdtvsp_status = vrdtvsp_ffiaft_pfis_Process_a_vprj(theOriginalParentFolderName, theOriginalBaseName, Final_Renamed_ParentFolderName, Final_Renamed_BaseName)
	If vrdtvsp_status <> 0 Then ' Something went wrong with processing .vprj
		If vrdtvsp_DEBUG Then WScript.StdOut.WriteLine("VRDTVSP DEBUG: VRDTVSP ERROR - vrdtvsp_ffiaft_pfis_Rename_a_File Error " & vrdtvsp_status & " returned from vrdtvsp_ffiaft_pfis_Process_a_vprj ... Aborting ...")
		WScript.StdOut.WriteLine("VRDTVSP ERROR - vrdtvsp_ffiaft_pfis_Rename_a_File Error " & vrdtvsp_status & " returned from vrdtvsp_ffiaft_pfis_Process_a_vprj ... Aborting ...")
		Wscript.Echo "Error 17 = cannot perform the requested operation"
		On Error goto 0
		WScript.Quit 17 ' Error 17 = cannot perform the requested operation
	End If
	'
	'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	'
	local_timerEnd = Timer
    If vrdtvsp_DEBUG Then 
		WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_ffiaft_pfis_Rename_a_File: Exit having Elapsed Time " & vrdtvsp_Calculate_ElapsedTime_string(local_timerStart, local_timerEnd))
	End If
	vrdtvsp_ffiaft_pfis_Rename_a_File = tmp_count_fixed
End Function
'
Function vrdtvsp_do_a_Rename_Try99Times(OriginalAbsoluteFilename, TargetAbsoluteFilename)
	' Try to rename a file and re-Rename it if required, trying up to 99 times
	' Cater for "file already exists" and loop try up to 100 times to add a 2 digit number ".00" to ".99" to the end of NewBaseName if needed fail to failure folder ?
	' Taking care of editing and rewriting the content .vprj files (which are just XML files) ... test for Ucase(theExtName) = Ucase("vprj")
    ' Parameters:
	'		theOriginalAbsoluteFilename		source filename
	'		theTargetAbsoluteFilename		target filename
	Const vrdtvsp_t99tr_MaxReTries = 99
	Const theLeadingCharacterForRetries = "_"
	Dim theOriginalAbsoluteFilename, theOriginalParentFolderName, theOriginalBaseName, theOriginalExtName
	Dim theTargetAbsoluteFilename, theTargetParentFolderName, theTargetBaseName, theTargetExtName
	Dim saved_theTargetAbsoluteFilename, saved_theTargetParentFolderName, saved_theTargetBaseName, saved_theTargetExtName
	Dim vrdtvsp_t99tr_ErrNo, vrdtvsp_t99tr_ErrDescription, vrdtvsp_t99tr_ErrCount
	Dim local_timerStart, local_timerEnd
	local_timerStart = Timer
	local_timerEnd = Timer
	If vrdtvsp_DEBUG Then
		'WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_do_a_Rename_Try99Times:  incoming Original filename <" & OriginalAbsoluteFilename & ">")
		'WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_do_a_Rename_Try99Times:    incoming Target filename <" & TargetAbsoluteFilename & ">")
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
	vrdtvsp_t99tr_ErrNo = 0
	vrdtvsp_t99tr_ErrDescription=""
	vrdtvsp_t99tr_ErrCount = 0
	WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_do_a_Rename_Try99Times:  rename <" & theOriginalAbsoluteFilename & ">")
	WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_do_a_Rename_Try99Times:      to <" & theTargetAbsoluteFilename & ">")
	on error resume Next
	If vrdtvsp_DEVELOPMENT_NO_ACTIONS Then ' DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV 
		'WScript.StdOut.WriteLine("VRDTVSP DEV: vrdtvsp_DEVELOPMENT_NO_ACTIONS: DEV: vrdtvsp_do_a_Rename_Try99Times NOT DOING 'fso.MoveFile theOriginalAbsoluteFilename, theTargetAbsoluteFilename'")
	Else
		fso.MoveFile theOriginalAbsoluteFilename, theTargetAbsoluteFilename ' this is the actual File Rename
	End If
	vrdtvsp_t99tr_ErrNo = Err.Number
	vrdtvsp_t99tr_ErrDescription = Err.Description
	Err.Clear
	on error goto 0
	If vrdtvsp_t99tr_ErrNo = 0 Then
		' successful rename ... debug statement here please
	ElseIf vrdtvsp_t99tr_ErrNo <> 58 Then ' catch any non-0 non-58 error and abort
		WScript.StdOut.WriteLine("VRDTVSP ERROR: vrdtvsp_do_a_Rename_Try99Times ABORTING: error " & vrdtvsp_t99tr_ErrNo & " " & vrdtvsp_t99tr_ErrDescription & " ... ABORTING since vbscript non-error-58 was detected at first attempt")
		On Error goto 0
		WScript.Quit 17 ' Error 17 = cannot perform the requested operation ' vrdtvsp_t99tr_ErrNo
		vrdtvsp_do_a_Rename_Try99Times = ""
		Exit Function
	Else ' if it gets to here then it MUST be error 58 = File already exists ... meaning we must re-try up to vrdtvsp_t99tr_MaxReTries times
		vrdtvsp_t99tr_ErrCount = 0
		vrdtvsp_t99tr_ErrNo = 58 ' should already be 58 but set it anyway
		While (vrdtvsp_t99tr_ErrNo = 58 AND vrdtvsp_t99tr_ErrCount < vrdtvsp_t99tr_MaxReTries) ' only vrdtvsp_t99tr_MaxReTries number of retries
			vrdtvsp_t99tr_ErrCount = vrdtvsp_t99tr_ErrCount + 1
			theTargetBaseName = vrdtvsp_Move_Date_to_End_of_String(saved_theTargetBaseName & theLeadingCharacterForRetries & vrdtvsp_Digits2(vrdtvsp_t99tr_ErrCount)) ' REMEMBER TO RE-PUT THE DATE BACK ON THE END OF THE FILENAME STRING
			theTargetAbsoluteFilename =  fso.GetAbsolutePathName(fso.BuildPath(saved_theTargetParentFolderName, theTargetBaseName & "." & saved_theTargetExtName))
			WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_do_a_Rename_Try99Times:   Retry <" & theTargetAbsoluteFilename & "> Attempt " & vrdtvsp_Digits2(vrdtvsp_t99tr_ErrCount))
			on error resume Next
			If vrdtvsp_DEVELOPMENT_NO_ACTIONS Then ' DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV 
				'WScript.StdOut.WriteLine("VRDTVSP DEV: vrdtvsp_DEVELOPMENT_NO_ACTIONS: DEV: vrdtvsp_do_a_Rename_Try99Times retry NOT DOING 'fso.MoveFile theOriginalAbsoluteFilename, theTargetAbsoluteFilename'")
			Else
				fso.MoveFile theOriginalAbsoluteFilename, theTargetAbsoluteFilename ' this is the actual File Rename and theTargetAbsoluteFilename contains an updated Absolte filename to use
			End If
			vrdtvsp_t99tr_ErrNo = Err.Number
			vrdtvsp_t99tr_ErrDescription = Err.Description
			Err.Clear
			on error goto 0
			If (vrdtvsp_t99tr_ErrNo <> 0 AND vrdtvsp_t99tr_ErrNo <> 58) Then ' catch any non-0 non-58 error and abort ... it catches everything like that before a Wend
				WScript.StdOut.WriteLine("VRDTVSP ERROR: vrdtvsp_do_a_Rename_Try99Times ABORTING: error " & vrdtvsp_t99tr_ErrNo & " " & vrdtvsp_t99tr_ErrDescription & " ... ABORTING since vbscript non-error-58 was detected during retries")
				On Error goto 0
				WScript.Quit 17 ' Error 17 = cannot perform the requested operation ' vrdtvsp_t99tr_ErrNo
				vrdtvsp_do_a_Rename_Try99Times = ""
				Exit Function
			End If
		Wend ' should Wend on non-58 error number (including 0) or reached max retries
		If (vrdtvsp_t99tr_ErrNo = 58 and vrdtvsp_t99tr_ErrCount >= vrdtvsp_t99tr_MaxReTries) Then ' Error 0 is OK and doesn't get caught by this test
			WScript.StdOut.WriteLine("VRDTVSP ERROR: vrdtvsp_do_a_Rename_Try99Times ABORTING: error " & vrdtvsp_t99tr_ErrNo & " - ABORTING since done " & vrdtvsp_t99tr_ErrCount & " retries and still detected error-58 File already exists")
			Wscript.Echo "Error 17 = cannot perform the requested operation"
			On Error goto 0
			WScript.Quit 17 ' Error 17 = cannot perform the requested operation
			vrdtvsp_do_a_Rename_Try99Times = ""
			Exit Function
		End If
	End If
	on error goto 0
	vrdtvsp_do_a_Rename_Try99Times = theTargetAbsoluteFilename ' Final Renamed AbsoluteFilename After Retries
End Function
'
Function vrdtvsp_ffiaft_pfis_Process_a_vprj (byVAL theOriginalParentFolderName, byVAL theOriginalBaseName, byVAL Final_Renamed_ParentFolderName, byVAL Final_Renamed_BaseName)
    ' Parameters:
	'		theOriginalParentFolderName		byVal	Folder of the filename to be renamed and/or fixed
	'		theOriginalBaseName				byVal	BaseName of the filename to be renamed and/or fixed
	'		Final_Renamed_ParentFolderName	byVal	Optional Folder of the filename to be renamed into (the target)   ... if "" then becomes theOriginalParentFolderName
	'		Final_Renamed_BaseName			byVal	Optional BaseName of the filename to be renamed into (the target) ... if "" then becomes theOriginalBaseName
	' byVAL means any changes to the parmater won't be transferred back to the caller
	'
	Dim Original_vprj_AbsoluteFilename
	Dim Final_Renamed_vprj_AbsoluteFilename
	Dim xml_file_to_load
	Dim vprj_status, vprj_objErr, vprj_errorCode, vprj_reason
	Dim vprj_nNode, vprj_i, vprj_txtbefore, vprj_txtafter, vprj_ErrNo, vprj_ErrDescription
	Dim vrdtvsp_xmlDoc, vprj_xmlbefore, vprj_xmlafter
	Dim vrdtvsp_xslDoc
	Const vrdtvsp_xslStylesheet_string = "<xsl:stylesheet version=""3.0"" xmlns:xsl=""http://www.w3.org/1999/XSL/Transform"" xmlns=""http://www.w3.org/1999/xhtml""><xsl:output method=""xml"" indent=""yes""/><xsl:template match=""/""><xsl:copy-of select="".""/></xsl:template></xsl:stylesheet>"
	'Const vrdtvsp_xslStylesheet_string = _
	'		"<xsl:stylesheet version=""3.0"" xmlns:xsl=""http://www.w3.org/1999/XSL/Transform"" xmlns=""http://www.w3.org/1999/xhtml"">" & _
	'		"<xsl:output method=""xml"" indent=""yes""/>" & _
	'		"<xsl:template match=""/"">" & _
	'		"<xsl:copy-of select="".""/>" & _
	'		"</xsl:template>" & _
	'		"</xsl:stylesheet>"
			'old:
			'	"<xsl:stylesheet version=""1.0"" xmlns:xsl=""http://www.w3.org/1999/XSL/Transform"">" & _
			'	"<xsl:output method=""xml"" indent=""yes""/>" & _
			'	"<xsl:template match=""/"">" & _
			'	"<xsl:copy-of select="".""/>" & _
			'	"</xsl:template>" & _
			'	"</xsl:stylesheet>"
	'
	' ***** If a matching .vprj file exists in the same folder, (a) rename it to match the new filename (b) fix the content of .vprj file (it's xml) to match the media filename 
	' ***** note: .vprj files should only exist for files aready converted to .mp4 ... ie in the destination folder
	' *****       however, in this code we choose to re-process/fix the associated .vprj files REGARDLESS of whether they are renamed or not !!!!!
	If Final_Renamed_ParentFolderName = "" OR Final_Renamed_BaseName = "" Then ' if the target is "" then make it the same name as the source so that no file renme occurs
		Final_Renamed_ParentFolderName = theOriginalParentFolderName
		Final_Renamed_BaseName = theOriginalBaseName
	End If
	Original_vprj_AbsoluteFilename = fso.GetAbsolutePathName( fso.BuildPath(theOriginalParentFolderName,theOriginalBaseName & ".vprj"))
	Final_Renamed_vprj_AbsoluteFilename = fso.GetAbsolutePathName( fso.BuildPath(Final_Renamed_ParentFolderName,Final_Renamed_BaseName & ".vprj"))
	If fso.FileExists(Original_vprj_AbsoluteFilename) Then 
		' yeppity, a matching .vprj file is FOUND for the original media filename
		If vrdtvsp_DEBUG Then 
			WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_ffiaft_pfis_Process_a_vprj: ********** found a matching .vprj file to autofix: """ & Original_vprj_AbsoluteFilename & """")
		End If
		If Original_vprj_AbsoluteFilename = Final_Renamed_vprj_AbsoluteFilename Then
			'WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_ffiaft_pfis_Process_a_vprj same filenames, NOT RENAMING """ & Original_vprj_AbsoluteFilename & """ as it is fine already.")
			If vrdtvsp_DEBUG Then WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_ffiaft_pfis_Process_a_vprj: same filenames, NOT RENAMING """ & Original_vprj_AbsoluteFilename & """ to """ & Final_Renamed_vprj_AbsoluteFilename & """")
		Else
			' a) rename the .vprj file to match the new BaseName of the media file ... abort on a failure to simply rename the .vprj file
			on error resume Next
			If vrdtvsp_DEVELOPMENT_NO_ACTIONS Then ' DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV 
				WScript.StdOut.WriteLine("VRDTVSP DEV: vrdtvsp_DEVELOPMENT_NO_ACTIONS: DEV: vrdtvsp_ffiaft_pfis_Process_a_vprj NOT RENAMING """ & Original_vprj_AbsoluteFilename & """ to """ & Final_Renamed_vprj_AbsoluteFilename & """")
			Else
				fso.MoveFile Original_vprj_AbsoluteFilename, Final_Renamed_vprj_AbsoluteFilename ' this is the actual File Rename
			End If
			vprj_ErrNo = Err.Number
			vprj_ErrDescription = Err.Description
			Err.Clear
			on error goto 0
			If (vprj_ErrNo <> 0) Then ' Error 0 is OK meaning it renamed just fine
				WScript.StdOut.WriteLine("VRDTVSP ERROR: vrdtvsp_ffiaft_pfis_Process_a_vprj ABORTING: error renaming .vprj ErrorNo: " & vprj_ErrNo & " Description: " & vprj_ErrDescription)
				WScript.StdOut.WriteLine("VRDTVSP ERROR: vrdtvsp_ffiaft_pfis_Process_a_vprj ABORTING: error renaming .vprj      Original_vprj_AbsoluteFilename=""" & Original_vprj_AbsoluteFilename & """")
				WScript.StdOut.WriteLine("VRDTVSP ERROR: vrdtvsp_ffiaft_pfis_Process_a_vprj ABORTING: error renaming .vprj Final_Renamed_vprj_AbsoluteFilename=""" & Final_Renamed_vprj_AbsoluteFilename & """")
				Wscript.Echo "Error 17 = cannot perform the requested operation"
				On Error goto 0
				WScript.Quit 17 ' Error 17 = cannot perform the requested operation
			End If
		End If
		' b) process/fix the content of .vprj file (it's xml) so the media filename in it is updated to match the renamed media filename
		' load the file Final_Renamed_vprj_AbsoluteFilename and replace the file part with Final_Renamed_BaseName in it
		Set vrdtvsp_xmlDoc = WScript.CreateObject("Msxml2.DOMDocument.6.0") ' OLD:  Set vrdtvsp_xmlDoc = CreateObject("Microsoft.XMLDOM")
		vrdtvsp_xmlDoc.async = False
		on error resume Next 
		xml_file_to_load = Final_Renamed_vprj_AbsoluteFilename
		If vrdtvsp_DEVELOPMENT_NO_ACTIONS Then ' DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV 
			xml_file_to_load = Original_vprj_AbsoluteFilename
			If vrdtvsp_DEBUG Then WScript.StdOut.WriteLine("VRDTVSP DEV: vrdtvsp_ffiaft_pfis_Process_a_vprj: about to LOAD vrdtvsp_xmlDoc.load ORIGINAL file """ & Original_vprj_AbsoluteFilename & """")
			vprj_status = vrdtvsp_xmlDoc.load(Original_vprj_AbsoluteFilename) 
		Else
			xml_file_to_load = Final_Renamed_vprj_AbsoluteFilename
			If vrdtvsp_DEBUG Then WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_ffiaft_pfis_Process_a_vprj: about to LOAD vrdtvsp_xmlDoc.load file """ & Final_Renamed_vprj_AbsoluteFilename & """")
			vprj_status = vrdtvsp_xmlDoc.load(Final_Renamed_vprj_AbsoluteFilename) 
		End If
		Set vprj_objErr = vrdtvsp_xmlDoc.parseError
		vprj_errorCode = vprj_objErr.errorCode
		vprj_reason = vprj_objErr.reason
		Set vprj_objErr = Nothing
		Err.clear
		on error goto 0 
		If NOT vprj_status Then
			WScript.StdOut.WriteLine("VRDTVSP ERROR: vrdtvsp_ffiaft_pfis_Process_a_vprj ABORTING: Failed to load XML doc .vprj file """ & xml_file_to_load & """")
			WScript.StdOut.WriteLine("VRDTVSP ERROR: vrdtvsp_ffiaft_pfis_Process_a_vprj ABORTING: vprj_status: " & vprj_status & " XML error: " & vprj_errorCode & " : " & vprj_reason)
			Wscript.Echo "Error 17 = cannot perform the requested operation"
			On Error goto 0
			WScript.Quit 17 ' Error 17 = cannot perform the requested operation
		End If
		'WScript.StdOut.WriteLine("vbs_rename_files: debug: loaded xml doc " & new_name)
		'Locate the desired node. Note the use of XPATH instead of looping over all the child nodes.
		Set vprj_nNode = vrdtvsp_xmlDoc.selectsinglenode ("//VideoReDoProject/Filename")
		If vprj_nNode is Nothing Then
			WScript.StdOut.WriteLine("VRDTVSP ERROR: vrdtvsp_ffiaft_pfis_Process_a_vprj ABORTING: Could not find XML node //VideoReDoProject/Filename in file " & xml_file_to_load)
			Wscript.Echo "Error 17 = cannot perform the requested operation"
			On Error goto 0
			WScript.Quit 17 ' Error 17 = cannot perform the requested operation exit with an error ... soft or hard ?
		End If
		vprj_txtbefore = vprj_nNode.text ' this is the pathname to the associated media file 
		' find the rightmost \ then replace everything at it to the start with .\ ... i.e. replace the full path of the associated media file with "\."
		' if a \ doesn't exist, add .\ to the start
		vprj_i = InStrRev(vprj_txtbefore,"\",-1,vbTextCompare)
		If vprj_i > 0 Then
			vprj_txtafter = ".\" & mid(vprj_txtbefore,vprj_i+1)
		Else
			vprj_txtafter = ".\" & vprj_txtbefore
		End If
		' replace the old basename portion of the associated media filename with the renamed basename portion
		vprj_txtafter = Replace(vprj_txtafter, fso.GetBaseName(Original_vprj_AbsoluteFilename), fso.GetBaseName(Final_Renamed_vprj_AbsoluteFilename), 1, -1, vbTextCompare)
		vprj_xmlbefore = vrdtvsp_xmlDoc.xml ' save the overall XML before we fix and transform
		vprj_nNode.text = vprj_txtafter ' load the edited text back intothe XML document
		'''' ??????????? try to in-place transform the XML string using an XSL stylesheet  per https://blogs.iis.net/robert_mcmurray/creating-quot-pretty-quot-xml-using-xsl-and-vbscript
		' OLD Set vrdtvsp_xslDoc = CreateObject("Microsoft.XMLDOM") ' or perhaps this instead: Set vrdtvsp_xslDoc = WScript.CreateObject("Msxml2.DOMDocument") ' per https://stackoverflow.com/questions/33187289/parsing-xml-string-in-vbscript#comment54231267_33189735
		Set vrdtvsp_xslDoc = WScript.CreateObject("Msxml2.DOMDocument.6.0") ' assume no error
		vrdtvsp_xslDoc.async = False
		If vrdtvsp_DEBUG Then
			WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_ffiaft_pfis_Process_a_vprj: about to load XSL vrdtvsp_xslStylesheet_string: ")
			WScript.StdOut.WriteLine("" & vrdtvsp_xslStylesheet_string & "")
		End If
		on error resume Next 
		vprj_status = vrdtvsp_xslDoc.loadXML(vrdtvsp_xslStylesheet_string) ' load the xsl stylesheet string
		Set vprj_objErr = vrdtvsp_xslDoc.parseError
		vprj_errorCode = vprj_objErr.errorCode
		vprj_reason = vprj_objErr.reason
		Set vprj_objErr = Nothing
		Err.clear
		on error goto 0
		If NOT vprj_status Then ' Error 0 is OK
			WScript.StdOut.WriteLine("VRDTVSP ERROR: vrdtvsp_ffiaft_pfis_Process_a_vprj ABORTING: XSL vrdtvsp_xslStylesheet_string load error vprj_status: " & vprj_status & " ErrorCode: " & vprj_errorCode & " : " & vprj_reason)
			Wscript.Echo "Error 17 = cannot perform the requested operation"
			On Error goto 0
			WScript.Quit 17 ' Error 17 = cannot perform the requested operation
		End If
		on error resume Next 
		vprj_txtafter = vrdtvsp_xmlDoc.transformNode(vrdtvsp_xslDoc) ' transform using the xsl stylesheet
		Set vprj_objErr = vrdtvsp_xslDoc.parseError
		vprj_errorCode = vprj_objErr.errorCode
		vprj_reason = vprj_objErr.reason
		Set vprj_objErr = Nothing
		Err.clear
		on error goto 0
		If (vprj_errorCode <> 0) Then ' Error 0 is OK
			WScript.StdOut.WriteLine("VRDTVSP ERROR: vrdtvsp_ffiaft_pfis_Process_a_vprj ABORTING: XML/XSL transformNode error vprj_status: " & vprj_status & " ErrorCode: " & vprj_errorCode & " : " & vprj_reason)
			Wscript.Echo "Error 17 = cannot perform the requested operation"
			On Error goto 0
			WScript.Quit 17 ' Error 17 = cannot perform the requested operation
		End If
		vprj_xmlafter = vrdtvsp_xmlDoc.xml ' save the overall XML after we fix and transform
		If vrdtvsp_DEBUG Then
			WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_ffiaft_pfis_Process_a_vprj: vprj xml-node before: """ & vprj_txtbefore & """")
			WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_ffiaft_pfis_Process_a_vprj: vprj xml-node  after: """ & vprj_nNode.text & """")
			WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_ffiaft_pfis_Process_a_vprj: xml ALL before: " & vprj_xmlbefore & "")
			WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_ffiaft_pfis_Process_a_vprj: xml ALL  after: " & vprj_xmlafter & "")
		End If
		on error resume Next 
		If vrdtvsp_DEVELOPMENT_NO_ACTIONS Then ' DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV 
			WScript.StdOut.WriteLine("VRDTVSP DEV: vrdtvsp_DEVELOPMENT_NO_ACTIONS: DEV: vrdtvsp_ffiaft_pfis_Process_a_vprj NOT RE-WRITING vprj """ & Final_Renamed_vprj_AbsoluteFilename & """")
		Else
			vrdtvsp_xmlDoc.save(Final_Renamed_vprj_AbsoluteFilename) ' tell the XMLDOM processor to save the updated XML file
		End If
		Set vprj_objErr = vrdtvsp_xmlDoc.parseError
		vprj_errorCode = vprj_objErr.errorCode
		vprj_reason = vprj_objErr.reason
		Set vprj_objErr = Nothing
		Err.clear
		on error goto 0 
		If not vprj_status Then
			WScript.StdOut.WriteLine("VRDTVSP ERROR: vrdtvsp_ffiaft_pfis_Process_a_vprj ABORTING: Failed to save XML doc into .vprj file """ & Final_Renamed_vprj_AbsoluteFilename & """")
			WScript.StdOut.WriteLine("VRDTVSP ERROR: vrdtvsp_ffiaft_pfis_Rename_a_File ABORTING: XML error: " & vprj_errorCode & " : Reason: " & vprj_reason)
			On Error goto 0
			WScript.Quit 17 ' Error 17 = cannot perform the requested operation
		End If
		Set vrdtvsp_xmlDoc = Nothing
		WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_ffiaft_pfis_Process_a_vprj .vprj autofixed: """ & Original_vprj_AbsoluteFilename & """ into """ & Final_Renamed_vprj_AbsoluteFilename & """")
	Else
		If vrdtvsp_DEBUG Then 
			WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_ffiaft_pfis_Process_a_vprj: ********** NO matching .vprj file found to autofix: """ & Original_vprj_AbsoluteFilename & """")
		End If
	End If
	vrdtvsp_ffiaft_pfis_Process_a_vprj = 0
End Function
'
Function vrdtvsp_remove_tvs_classifying_stuff_from_string (theOriginalString)
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
	Next
	' replace legacy stuff at the middle and end of a string
	theNewString = Replace(theNewString, ".h264.", ".", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, ".h265.", ".", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, ".aac.", ".", 1, -1, vbTextCompare)
	theNewString = vrdtvsp_ReplaceEndStringCaseIndependent(theNewString, ".h264", "")
	theNewString = vrdtvsp_ReplaceEndStringCaseIndependent(theNewString, ".h265", "")
	theNewString = vrdtvsp_ReplaceEndStringCaseIndependent(theNewString, ".aac", "")
	'
	' THIS Next LEGACY CODE ALL IN A SPECIAL ORDER !  YUK.
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
	theNewString = Replace(theNewString, "__", "_", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "__", "_", 1, -1, vbTextCompare) ' yes again to catch all  replaces
	theNewString = Replace(theNewString, "__", "_", 1, -1, vbTextCompare) ' yes again to catch all  replaces
	theNewString = Replace(theNewString, "__", "_", 1, -1, vbTextCompare) ' yes again to catch all  replaces
	theNewString = Replace(theNewString, "__", "_", 1, -1, vbTextCompare) ' yes again to catch all  replaces
	'
	theNewString = Replace(theNewString, "--", "-", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "--", "-", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "--", "-", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "--", "-", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "--", "-", 1, -1, vbTextCompare)
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
	theNewString = Replace(theNewString, "..", ".", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "..", ".", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "..", ".", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "..", ".", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "..", ".", 1, -1, vbTextCompare)
	'
	' BELOW IS ALL LEGACY CODE ... too lazy to change it
	'
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie_Movie_", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie_", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "_Movie", "-Movie")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Action-Adventure-Comedy_", "Action-Adventure-Comedy-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Action-Adventure-Crime-Movie_", "Action-Adventure-Crime-Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Action-Adventure-Fantasy-Movie_", "Action-Adventure-Fantasy-Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Action-Adventure-Movie-Sci-Fi_", "Action-Adventure-Movie-Sci-Fi-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Action-Drama-Movie-Thriller_", "Action-Drama-Movie-Thriller-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Action-Drama-Movie-Thriller_", "Action-Drama-Movie-Thriller-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Action-Fantasy-Movie_", "Action-Fantasy-Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Action-Fantasy-Movie-Sci-Fi_", "Action-Fantasy-Movie-Sci-Fi-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Action-Movie-Thriller_", "Action-Movie-Thriller-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Adventure-Animation-Children-Entertainment_", "Adventure-Animation-Children-Entertainment-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Adventure-Family-Fantasy-Movie_", "Adventure-Family-Fantasy-Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Adventure-Movie_", "Adventure-Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Animation-Comedy-Family-Movie_", "Animation-Comedy-Family-Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Arts-Culture-Biography-Drama-Historical-Movie-Romance_", "Arts-Culture-Biography-Drama-Historical-Movie-Romance-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Arts-Culture-Documentary-Historical-Nature-Society-Culture-Travel_", "Arts-Culture-Documentary-Historical-Nature-Society-Culture-Travel-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Arts-Culture-Documentary-Historical-Society-Culture_", "Arts-Culture-Documentary-Historical-Society-Culture-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Arts-Culture-Drama-Movie_", "Arts-Culture-Drama-Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Biography-Comedy-Drama-Movie_", "Biography-Comedy-Drama-Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Biography-Documentary-Historical_", "Biography-Documentary-Historical-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Biography-Documentary-Historical-Mystery_", "Biography-Documentary-Historical-Mystery-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Biography-Documentary-Historical-Society-Culture_", "Biography-Documentary-Historical-Society-Culture-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Biography-Documentary-Music_", "Biography-Documentary-Music-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Biography-Drama-Historical_", "Biography-Drama-Historical-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Biography-Drama-Movie_", "Biography-Drama-Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Biography-Drama-Movie-Romance_", "Biography-Drama-Movie-Romance-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Children_", "Children-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Comedy_", "Comedy-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Comedy-Dance-Movie-Romance_", "Comedy-Dance-Movie-Romance-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Comedy-Drama-Fantasy-Movie-Romance_", "Comedy-Drama-Fantasy-Movie-Romance-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Comedy-Drama-Movie_", "Comedy-Drama-Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Comedy-Drama-Music_", "Comedy-Drama-Music-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Comedy-Family-Movie_", "Comedy-Family-Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Comedy-Family-Movie-Romance_", "Comedy-Family-Movie-Romance-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Comedy-Horror-Movie_", "Comedy-Horror-Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Comedy-Movie_", "Comedy-Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Comedy-Movie-Romance_", "Comedy-Movie-Romance-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Crime-Drama_", "Crime-Drama-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Crime-Drama-Murder-Mystery_", "Crime-Drama-Murder-Mystery-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Crime-Drama-Mystery_", "Crime-Drama-Mystery-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Current_", "Current-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Documentary_", "Documentary-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Documentary-Entertainment-Historical-Travel_", "Documentary-Entertainment-Historical-Travel-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Documentary-Historical_", "Documentary-Historical-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Documentary-Historical-Mini_", "Documentary-Historical-Mini-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Documentary-Historical-Mystery_", "Documentary-Historical-Mystery-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Documentary-Historical-War_", "Documentary-Historical-War-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Documentary-Medical-Science-Tech_", "Documentary-Medical-Science-Tech-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Documentary-Nature_", "Documentary-Nature-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Documentary-Science-Tech-Society-Culture_", "Documentary-Science-Tech-Society-Culture-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Documentary-Science-Tech-Travel_", "Documentary-Science-Tech-Travel-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Documentary-Society-Culture_", "Documentary-Society-Culture-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Drama_", "Drama-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Drama-Family-Movie_", "Drama-Family-Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Drama-Fantasy-Mystery_", "Drama-Fantasy-Mystery-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Drama-Historical_", "Drama-Historical-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Drama-Historical-Movie-Romance_", "Drama-Historical-Movie-Romance-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Drama-Horror-Movie-Mystery_", "Drama-Horror-Movie-Mystery-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Drama-Movie_", "Drama-Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Drama-Movie-Music-Romance_", "Drama-Movie-Music-Romance-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Drama-Movie-Mystery-Romance_", "Drama-Movie-Mystery-Romance-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Drama-Movie-Mystery-Sci-Fi_", "Drama-Movie-Mystery-Sci-Fi-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Drama-Movie-Romance_", "Drama-Movie-Romance-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Drama-Movie-Sci-Fi-Thriller_", "Drama-Movie-Sci-Fi-Thriller-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Drama-Movie-Thriller_", "Drama-Movie-Thriller-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Drama-Movie-Violence_", "Drama-Movie-Violence-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Drama-Murder-Mystery_", "Drama-Murder-Mystery-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Drama-Mystery_", "Drama-Mystery-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Drama-Mystery-Sci-Fi_", "Drama-Mystery-Sci-Fi-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Drama-Mystery-Violence_", "Drama-Mystery-Violence-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Drama-Romance-Sci-Fi_", "Drama-Romance-Sci-Fi-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Drama-Thriller_", "Drama-Thriller-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Education-Science_", "Education-Science-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Education-Science-Tech_", "Education-Science-Tech-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Entertainment_", "Entertainment-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Entertainment-Real_", "Entertainment-Real-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Horror-Movie_", "Horror-Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Infotainment-Real_", "Infotainment-Real-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Lifestyle-Medical-Science-Tech_", "Lifestyle-Medical-Science-Tech-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie_", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Mystery_", "Movie-Mystery-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Sci-Fi_", "Movie-Sci-Fi-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Sci-Fi-Thriller_", "Movie-Sci-Fi-Thriller-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Sci-Fi-Western_", "Movie-Sci-Fi-Western-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Thriller_", "Movie-Thriller-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Western_", "Movie-Western-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Sci-Fi_", "Sci-Fi-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Travel_", "Travel-")
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
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Adventure-Nature_", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Action-Adventure-Comedy-", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Action-Adventure-Drama_", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Action-Drama-Sci-Fi_", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Action-Drama_", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Adult-Crime-Drama-Society-Culture-", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Adult-Documentary-Real_Life-Society-Culture-", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Adventure-Cult-Sci-Fi_", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Adventure-Animation-Children-Entertainment-","")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Adventure-Documentary-Drama-Sci-Fi-Science-", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Adventure-Entertainment-Travel-", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Animation-Children-", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Arts-Culture-Documentary-Historical-Nature-Society-Culture-Travel-", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Arts-Culture-Documentary-Historical-Society-Culture-", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Arts-Culture-Entertainment-", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Biography-Documentary-Historical-", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Children-", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Comedy-", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Comedy_", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Cooking-", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Crime-Documentary-Historical-Mini_Series-Religion-Society-Culture_", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Crime-Documentary-Historical-Mini_Series-Religion-Society-Culture-", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Crime-Drama-Murder-Mystery-", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Crime-Drama-Mystery-", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Crime-Drama-Thriller_", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Crime-Drama-", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Crime-Drama_", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Crime-Mystery_", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Crime_", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Current-Affairs-Documentary_", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Documentary-Entertainment-Historical-Travel-", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Documentary-Entertainment-", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Documentary-Historical-", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Documentary-Historical-Mystery-", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Documentary-Historical-Religion-Society-Culture_", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Documentary-Historical-Science-Tech-Society-Culture-", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Documentary-Historical-Travel_", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Documentary-Historical-War-", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Documentary-Infotainment-", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Documentary-Medical-", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Documentary-Nature-Society-Culture-Travel-", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Documentary-Nature-", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Documentary-Real_Life-Society-Culture_", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Documentary-Science-Tech-Society-Culture-", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Documentary-Science-Tech-Travel-", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Documentary-Science-Tech_", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Documentary-Science-", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Documentary-Travel_", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Documentary-", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Drama-Murder-Mystery-", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Drama-Historical-Mystery-Sci-Fi-Thriller_", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Drama-Historical-", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Drama-Mystery-Sci-Fi-", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Drama-Mystery-", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Drama-Romance-Sci-Fi-", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Drama-Romance_", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Drama-Sci-Fi-Thriller_", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Drama-Thriller-", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Drama-", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Drama_", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Education-Entertainment-Game_Show-", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Education-Science-Tech-", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Education-Science-", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Education-Science_", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Entertainment-", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Family_Movie-", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Historical-Travel-", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Historical-Travel_", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Historical-Infotainment-Lifestyle-Real_Life-Society-Culture-", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Historical-Infotainment-Lifestyle-Real_Life-Society-Culture_", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Lifestyle-Medical-Science-Tech-", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Action-Adventure-Animation-", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Action-Adventure-Comedy-Sci-Fi-", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Action-Adventure-Comedy-", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Action-Adventure-Crime-Drama-", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Action-Adventure-Crime-", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Action-Adventure-Drama-Romance-", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Action-Adventure-Drama-", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Action-Adventure-Family-", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Action-Adventure-Fantasy-", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Action-Adventure-Historical-Sci-Fi-", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Action-Adventure-Mystery-", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Action-Adventure-Sci-Fi-", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Action-Adventure-", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Action-Comedy-", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Action-Crime-", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Action-Drama-Historical-", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Action-Drama-", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Action-Drama-Sci-Fi-", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Action-Drama-Thriller-", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Action-Drama-Western-", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Action-Fantasy-Sci-Fi-", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Action-Fantasy-", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Action-Horror-Sci-Fi-Thriller-", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Action-Sci-Fi-Thriller-", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Action-Sci-Fi-", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Action-Thriller-", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Action-", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Adventure-Animation-", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Adventure-Biography-Drama-", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Adventure-Children-Family-Sci-Fi-", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Adventure-Comedy-Drama-Romance-", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Adventure-Comedy-Drama-", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Adventure-Drama-Fantasy-", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Adventure-Drama-Historical-Romance-", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Adventure-Drama-Sci-Fi-", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Adventure-Family-Fantasy-", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Adventure-Fantasy-", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Adventure-Sci-Fi-", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Adventure-", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Animation-Children-Comedy-", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Animation-Comedy-Family-", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Animation-", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Arts-Culture-Biography-Drama-Historical-Romance-", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Arts-Culture-Drama-War_Movie-", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Arts-Culture-Drama-", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Biography-Comedy-Drama-", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Biography-Documentary-", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Biography-Drama-Historical-", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Biography-Drama-Romance-", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Biography-Drama-", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Biography-", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Children-Family-", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Comedy-Crime-", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Comedy-Dance-Romance-", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Comedy-Drama-Family-", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Comedy-Drama-Fantasy-", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Comedy-Drama-Fantasy-Romance-", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Comedy-Drama-Fantasy-", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Comedy-Drama-Historical-", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Comedy-Drama-Music-", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Comedy-Drama-Musical-Romance-", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Comedy-Drama-Music_Movie-", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Comedy-Drama-Romance-", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Comedy-Drama-Sci-Fi-", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Comedy-Drama-", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Comedy-Family-Romance-", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Comedy-Family-", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Comedy-Fantasy-Musical-", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Comedy-Fantasy-Romance-", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Comedy-Historical-", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Comedy-Horror-Romance-", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Comedy-Horror-", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Comedy-Music_Movie-", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Comedy-Romance-", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Comedy-Sci-Fi-", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Comedy-War_Movie-", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Comedy-War-", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Comedy-", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Crime-Drama-Fantasy-Horror-", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Crime-Drama-Mystery_Movie-", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Crime-Drama-Mystery-", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Crime-Mystery-", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Crime-Mystery_Movie-", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Crime-Romance-Thriller-", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Crime-", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Drama-Historical-Romance-", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Drama-Horror-Mystery-", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Drama-Horror-Romance-", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Drama-Music-Romance-", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Drama-Mystery-Romance-", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Drama-Mystery-Sci-Fi-", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Drama-Mystery-Thriller-", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Drama-Romance-", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Drama-Sci-Fi-Thriller-", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Drama-Sci-Fi-", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Drama-Thriller-", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Drama-Violence-", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Drama-War_Movie-", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Drama-", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Family-", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Family-Fantasy-", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Family-Musical-", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Fantasy-Horror-", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Fantasy-Sci-Fi-", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Fantasy-", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Horror-", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Horror-Mystery-Sci-Fi-", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Horror-Mystery-Thriller-", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Horror-Sci-Fi-Thriller-", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Horror-Sci-Fi-", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Horror-Thriller-", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Horror-", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Musical-Romance-", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Musical-", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Music_Movie-", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Mystery-Sci-Fi-Thriller-", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Mystery-Sci-Fi-", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Romance-", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Romance-Western-", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Sci-Fi-Thriller-", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Sci-Fi-Western-", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Sci-Fi-", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Thriller-", "Movie-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-Western-", "Movie-")
	'
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Extreme_Railways_Journeys_", "Extreme_Railways_Journeys-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Great_British_Railway_Journeys_", "Great_British_Railway_Journeys-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Great_American_Railroad_Journeys_", "Great_American_Railroad_Journeys-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Great_Continental_Railway_Journeys_", "Great_Continental_Railway_Journeys-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Great_Indian_Railway_Journeys_", "Great_Indian_Railway_Journeys-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Tony_Robinson-s_World_By_Rail_", "Tony_Robinson-s_World_By_Rail-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Railways_That_Built_Britain_", "Railways_That_Built_Britain-")
	'
	' On second thought, replace Movie at the start with Nothing ...
	'
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Movie-", "")
	'
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Action-Drama-Mini_Series-Sci-Fi-", "Sci-Fi-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Action-Drama-Mini_Series-Sci-Fi_", "Sci-Fi-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Adventure-Sci-Fi-", "Sci-Fi-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Adventure-Sci-Fi_", "Sci-Fi-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Adventure-Sci-Fi_", "Sci-Fi-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Adult-Documentary-Society-Culture_", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Adult-Documentary-Society-Culture-", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Arts-Culture-Biography-Historical_", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Arts-Culture-Documentary_", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Arts-Culture-Entertainment_", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Arts-Culture-Biography-Romance-", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Arts-Culture-War_", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Arts-Culture-", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Biography-Cult-Religion-Society-Culture_", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Biography-Documentary_", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Biography-Historical_", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Biography-Mini_Series_", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Biography-Tech_", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Biography-", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Entertainment_", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Family-Fantasy_", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Family-Fantasy-", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Food-Wine-Lifestyle-Science_", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Food-Wine-Society-Culture_", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Game_Show-", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Game_Show_", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Historical-", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Historical_", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Historical-Mini_Series-Science-Tech_", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Horror-Mystery-Thriller_", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Infotainment-Real-Life_", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Infotainment-", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Infotainment_", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Lifestyle-", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Lifestyle_", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Lifestyle-Science-Tech_", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Lifestyle-Travel_", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Medical_", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Mini_Series-Thriller_", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Mini_Series-War", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Mini-Series-Science-Tech-Society-Culture-Travel_", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Mini-Series-Society-Culture_", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Murder-Mystery-", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Murder-Mystery_", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Music-Romance_Movie-", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Music-Romance_Movie_", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Mystery-", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Mystery_", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Nature-Society-Culture_", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Nature_", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "News-Science-Tech-", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "News-Science-Tech_", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "News_", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Real_Life-Renovation-","")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Real_Life-Society-Culture_", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Real_Life-Travel_", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Real_Life_", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Real_Life-", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Religion-Society-Culture_", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Religion-Thriller-", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Religion_", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Romance-Society-Culture_", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Romance_", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Romance-", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Science-Tech_", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Science-Tech-", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Society-Culture_", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Society-Culture-", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Science-Tech-Society-Culture_", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Science-Tech-Special_", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Science-Tech_", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Science_", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Sci-Fi-Thriller_", "Sci-Fi-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Sitcom-", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Sitcom_", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Action-Sci-Fi_", "Sci-Fi-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Sci-Fi-", "Sci-Fi-")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Sci-Fi-", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Sci-Fi_", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Society-Culture_", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Sport-", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Sport_", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Thriller-", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Thriller_", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Tech-Travel_", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Tech-Travel-", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Travel_", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "Travel-", "")
	'
	theNewString = Replace(theNewString, "__", "_", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "__", "_", 1, -1, vbTextCompare) ' yes again to catch all  replaces
	theNewString = Replace(theNewString, "__", "_", 1, -1, vbTextCompare) ' yes again to catch all  replaces
	theNewString = Replace(theNewString, "__", "_", 1, -1, vbTextCompare) ' yes again to catch all  replaces
	theNewString = Replace(theNewString, "__", "_", 1, -1, vbTextCompare) ' yes again to catch all  replaces
	theNewString = Replace(theNewString, "__", "_", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "__", "_", 1, -1, vbTextCompare) ' yes again to catch all  replaces
	theNewString = Replace(theNewString, "__", "_", 1, -1, vbTextCompare) ' yes again to catch all  replaces
	theNewString = Replace(theNewString, "__", "_", 1, -1, vbTextCompare) ' yes again to catch all  replaces
	theNewString = Replace(theNewString, "__", "_", 1, -1, vbTextCompare) ' yes again to catch all  replaces
	'
	theNewString = Replace(theNewString, "--", "-", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "--", "-", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "--", "-", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "--", "-", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "--", "-", 1, -1, vbTextCompare)
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
	theNewString = Replace(theNewString, "..", ".", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "..", ".", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "..", ".", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "..", ".", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "..", ".", 1, -1, vbTextCompare)
	'
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "-", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, "_", "")
	theNewString = vrdtvsp_ReplaceStartStringCaseIndependent(theNewString, ".", "")
	theNewString = vrdtvsp_ReplaceEndStringCaseIndependent(theNewString, "-", "")
	theNewString = vrdtvsp_ReplaceEndStringCaseIndependent(theNewString, "_", "")
	theNewString = vrdtvsp_ReplaceEndStringCaseIndependent(theNewString, ".", "")
    vrdtvsp_remove_tvs_classifying_stuff_from_string = theNewString
End Function
'
Function vrdtvsp_Move_Date_to_End_of_String(theOriginalString)
    ' if a Date exists in a string, move it to the end of the string (used in renaming files with the date on the end)
    Dim theLeadingSearchCharacter, txtToSearchFor
	Dim searchformeArray(3) ' an array of valid leading characters to include in the search/replace
    Dim xyear, xmonth, xday, xDate, is_a_date_there
    Dim theNewString
	Dim timerStart_MDES, timerEnd_MDES
	timerStart_MDES = Timer
	timerEnd_MDES = Timer
    'If vrdtvsp_DEBUG Then WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_Move_Date_to_End_of_String: entered with original value """ & theOriginalString & """")
    searchformeArray(0)="-"
	searchformeArray(1)="_"
	searchformeArray(2)="."
	searchformeArray(3)=" " ' a space should not exist by the time it gets to here, but check/fix anyway
    theNewString = theOriginalString
    ' Brute force through dates, Nothing fancy here. Very slow but sure.
    ' But first, cheekily see if there's a date at all by checking for "20"
    is_a_date_there = False
    For Each theLeadingSearchCharacter In searchformeArray ' this is a QUICK FOR loop, only 4 iterations
        txtToSearchFor = theLeadingSearchCharacter & "20" ' assuming start of a date in the "2000" years, eg "2021"
		'If vrdtvsp_DEBUG Then WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_Move_Date_to_End_of_String: QUICK searching for """ & txtToSearchFor & """ in """ & theNewString & """") 
        If instr(1, theNewString, txtToSearchFor, vbTextCompare) > 0 Then 
            is_a_date_there = True
			'If vrdtvsp_DEBUG Then WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_Move_Date_to_End_of_String: QUICK FOUND """ & txtToSearchFor & """ in """ & theNewString & """ exiting Quick FOR Loop") 
            Exit For
        End If
    Next
	'If vrdtvsp_DEBUG Then WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_Move_Date_to_End_of_String: is_a_date_there=" & is_a_date_there)
    Do While is_a_date_there ' loop forever ... setting up for cheeky way to exit all FOR loops at once
		for xyear = 2017 to 2050
        'for xyear = 2021 to 2021 ' FORCE DEBUG
			'If vrdtvsp_DEBUG Then WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_Move_Date_to_End_of_String: Start    processing Year " & xyear & " ... with original value """ & theOriginalString & """")
	        for xmonth = 01 to 12
	            for xday = 01 to 31
	                xDate = vrdtvsp_Digits4(xyear) & "-" & vrdtvsp_Digits2(xmonth) & "-" & vrdtvsp_Digits2(xday) ' assume dates in the filename are always in format dd-mm-yyyy with leading zeroes
					'If vrdtvsp_DEBUG Then WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_Move_Date_to_End_of_String: About to process date " & xDate & " ")
                    For Each theLeadingSearchCharacter In searchformeArray
                        txtToSearchFor = theLeadingSearchCharacter & xDate
						'If vrdtvsp_DEBUG Then 
						'	WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_Move_Date_to_End_of_String: About to process " & xDate & " with txtToSearchFor: """ & txtToSearchFor & """ in """ & theOriginalString & """")
						'End If
						If instr(1, theOriginalString, txtToSearchFor, vbTextCompare) > 0 then                                                                ' we found date within the string
							'If vrdtvsp_DEBUG Then 
							'	WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_Move_Date_to_End_of_String: FOUND txtToSearchFor: """ & txtToSearchFor & """ in """ & theOriginalString & """")
							'End If
                            If right(theOriginalString, len(xDate)) <> xDate then ' ensure it's not already at the end of the string
                                theNewString = Replace(theOriginalString, txtToSearchFor, "", 1, -1, vbTextCompare) & theLeadingReplaceCharacter_ForMovingDates & xDate     ' move the date to the end of the string since it's not already there
								'If vrdtvsp_DEBUG Then 
                                '	WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_Move_Date_to_End_of_String: FOUND string with DATE NOT AT END <" & txtToSearchFor & ">=<" & theOriginalString & "> ... changing to <" & theNewString & ">")
								'	'Wscript.Sleep 1000 * 2
								'End If
                            End If
							is_a_date_there = False ' this only means exit the Do loop, not that there isn't one !!!
							Exit Do ' cheeky way to exit all the For loops at once, just Exit the outer Do Loop
							If vrdtvsp_DEBUG Then 
								WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_Move_Date_to_End_of_String: ?????? vrdtvsp_Move_Date_to_End_of_String should have exited Loop with Exit Do but has not ??????")
								Wscript.Echo "Error 17 = cannot perform the requested operation"
								On Error goto 0
								WScript.Quit 17 ' Error 17 = cannot perform the requested operation
						End If
					End If
                    Next
	            Next
	        Next
			'If vrdtvsp_DEBUG Then 
			'	WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_Move_Date_to_End_of_String: Finished processing Year " & xyear & " YEAR NOT IN STRING ... with original value """ & theOriginalString & """")
			'	'Wscript.Sleep 1000 * 2
			'End If
		Next
		is_a_date_there = False ' this only means exit the Do loop !!!
		Exit Do
    Loop
	theNewString = Replace(theNewString, "--", "-", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "..", ".", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "-.", ".", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, ".-", ".", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "_.", ".", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "._", ".", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "_-", "_", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "-_", "_", 1, -1, vbTextCompare)
	'
	theNewString = Replace(theNewString, "..", ".", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "..", ".", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "..", ".", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "..", ".", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "..", ".", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "--", "-", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "--", "-", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "--", "-", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "--", "-", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "--", "-", 1, -1, vbTextCompare)
	timerEnd_MDES = Timer
    'If vrdtvsp_DEBUG Then WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_Move_Date_to_End_of_String: exiting with return value   """ & theNewString & """ having Loop Elapsed Time " & vrdtvsp_Calculate_ElapsedTime_string(timerStart_MDES, timerEnd_MDES))
	vrdtvsp_Move_Date_to_End_of_String = theNewString
End Function
'
Function vrdtvsp_Digits2 (val)
    ' pad a number with leading zeroes, up to 2 characters in size total
    vrdtvsp_Digits2 = vrdtvsp_PadDigits(val, 2)
End Function
'
Function vrdtvsp_Digits4(val)
    ' pad a number with leading zeroes, up to 4 characters in size total
    vrdtvsp_Digits4 = vrdtvsp_PadDigits(val, 4)
End Function
'
Function vrdtvsp_PadDigits(val, digits) 
    ' pad a number with leading zeroes, up to a speified number of characters in size total
    vrdtvsp_PadDigits = Right(String(digits,"0") & val, digits)
End Function
'
Function vrdtvsp_ReplaceStartStringCaseIndependent(theString, theSearchString, theReplaceString)
	' replace string only at the start of a line
	dim L
	If lcase(left(theString,len(theSearchString))) = lcase(theSearchString) then
		L = len(theString) - len(theSearchString)
		'vrdtvsp_ReplaceStartStringCaseIndependent = Replace(theString, theSearchString, theReplaceString, 1, 1, vbTextCompare)
		vrdtvsp_ReplaceStartStringCaseIndependent = theReplaceString & right(theString,L)
	else
		vrdtvsp_ReplaceStartStringCaseIndependent = theString
	end if
End Function
'
Function vrdtvsp_ReplaceEndStringCaseIndependent(theString, theSearchString, theReplaceString)
	' replace string only at the end of a line
	dim L
	If lcase(right(theString,len(theSearchString))) = lcase(theSearchString) then
		L = len(theString) - len(theSearchString)
		''vrdtvsp_ReplaceStartStringCaseIndependent = Replace(theString, theSearchString, theReplaceString, 1, 1, vbTextCompare)
		vrdtvsp_ReplaceEndStringCaseIndependent =  left(theString,L) & theReplaceString
	else
		vrdtvsp_ReplaceEndStringCaseIndependent = theString
	end if
End Function
'----------------------------------------------------------------------------------------------------------------------------------------
'----------------------------------------------------------------------------------------------------------------------------------------
'----------------------------------------------------------------------------------------------------------------------------------------
'****************************************************************************************************************************************
'****************************************************************************************************************************************
'****************************************************************************************************************************************
'****************************************************************************************************************************************
'****************************************************************************************************************************************
'****************************************************************************************************************************************
'****************************************************************************************************************************************
'****************************************************************************************************************************************
'****************************************************************************************************************************************
'****************************************************************************************************************************************
'****************************************************************************************************************************************
'****************************************************************************************************************************************
'
Function vrdtvsp_Convert_files_in_a_folder(	byVal	C_source_TS_Folder, _
											byVal	C_done_TS_Folder, _
											byVal	C_destination_mp4_Folder, _
											byVal	C_failed_conversion_TS_Folder, _
											byVal	C_temp_path, _
											byVal	C_saved_ffmpeg_commands_filename, _
											byVal	C_do_Adscan, _
											byVal	C_do_audio_delay )
	' Loop and convert .TS .mp4 .mpg Source files in a folder into acceptable avc/aac .mp4 Destination files 
    ' Parameters: see below
	' NOTES: 
	'	Rely on these already being set Globally to True or False BEFORE invoking the conversion function: vrdtvsp_DEBUG, vrdtvsp_DEVELOPMENT_NO_ACTIONS, wso, fso, vrdtvsp_status
	'	Check for C_source_TS_Folder = C_destination_mp4_Folder since we don't permit that
	'	Convert .TS and .MP4 and .MPG files in the C_source_TS_Folder and create adscan .vprj files
	'	Resulting .mp4 and .vprj goes into C_destination_mp4_Folder
	'	Successfilly completed .TS and .MP4 and .MPG files (and associated .vprj, if any) goes into C_done_TS_Folder 
	'	Failed-to-convert .TS and .MP4 files (and associated .vprj, if any) goes into C_failed_conversion_TS_Folder 
	'	Use a scratch folder (on an SSD) in C_temp_path
	'	Create file C_saved_ffmpeg_commands_filename to store commands/data used for: qsf, dgindex, .vpy, ffmpeg, adscan
	'
	' log message just go directly to the console (no vrdlog)
	'
	Dim C_object_Folder, C_object_Folders_Collection
	Dim C_object_File, C_object_Files_Collection
	Dim C_FILE_AbsolutePathName, C_FILE_ParentFolderName, C_FILE_BaseName, C_FILE_Ext
	Dim C_object_saved_ffmpeg_commands
	Dim C_exe_cmd_string
	Dim C_exe_object
	Dim C_exe_status
	Dim C_tmp, c_status
	'
	WScript.StdOut.WriteLine("" & vrdtvsp_current_datetime_string())
	WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_files_in_a_folder STARTED: " & vrdtvsp_current_datetime_string())
	WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_files_in_a_folder:                C_source_TS_Folder=""" & C_source_TS_Folder & """")
	WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_files_in_a_folder:                  C_done_TS_Folder=""" & C_done_TS_Folder & """")
	WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_files_in_a_folder:          C_destination_mp4_Folder=""" & C_destination_mp4_Folder & """")
	WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_files_in_a_folder:     C_failed_conversion_TS_Folder=""" & C_failed_conversion_TS_Folder & """")
	WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_files_in_a_folder:                       C_temp_path=""" & C_temp_path & """")
	WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_files_in_a_folder:  C_saved_ffmpeg_commands_filename=""" & C_saved_ffmpeg_commands_filename & """")
	WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_files_in_a_folder:                       C_do_Adscan=""" & C_do_Adscan & """")
	WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_files_in_a_folder:               C_do_do_audio_delay=""" & C_do_audio_delay & """")

	'
	' force absolute PathNnames
	C_source_TS_Folder = fso.GetAbsolutePathName(C_source_TS_Folder & "\")
	C_done_TS_Folder = fso.GetAbsolutePathName(C_done_TS_Folder & "\")
	C_destination_mp4_Folder = fso.GetAbsolutePathName(C_destination_mp4_Folder & "\")
	C_failed_conversion_TS_Folder = fso.GetAbsolutePathName(C_failed_conversion_TS_Folder & "\")
	C_temp_path = fso.GetAbsolutePathName(C_temp_path & "\")
	C_saved_ffmpeg_commands_filename = fso.GetAbsolutePathName(C_saved_ffmpeg_commands_filename & "\")
	'
	If vrdtvsp_DEBUG Then 
		WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_Convert_files_in_a_folder - Entered with parameters: ")
		WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_Convert_files_in_a_folder Saved ffmpeg commands: """ & C_saved_ffmpeg_commands_filename & """")
		WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_Convert_files_in_a_folder Created on " & vrdtvsp_current_datetime_string)
		WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_Convert_files_in_a_folder                   ""vapoursynth_root=" & vapoursynth_root & """")
		WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_Convert_files_in_a_folder               ""vrdtvsp_mp4boxexex64=" & vrdtvsp_mp4boxexex64 & """")
		WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_Convert_files_in_a_folder             ""vrdtvsp_mediainfoexe64=" & vrdtvsp_mediainfoexe64 & """")
		WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_Convert_files_in_a_folder               ""vrdtvsp_ffprobeexe64=" & vrdtvsp_ffprobeexe64 & """")
		WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_Convert_files_in_a_folder                ""vrdtvsp_ffmpegexe64=" & vrdtvsp_ffmpegexe64 & """")
		WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_Convert_files_in_a_folder             ""vrdtvsp_dgindexNVexe64=" & vrdtvsp_dgindexNVexe64 & """")
		WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_Convert_files_in_a_folder              ""vrdtvsp_Insomniaexe64=" & vrdtvsp_Insomniaexe64 & """")
		WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_Convert_files_in_a_folder                 ""C_source_TS_Folder=" & C_source_TS_Folder & """")
		WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_Convert_files_in_a_folder                   ""C_done_TS_Folder=" & C_done_TS_Folder & """")
		WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_Convert_files_in_a_folder           ""C_destination_mp4_Folder=" & C_destination_mp4_Folder & """")
		WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_Convert_files_in_a_folder      ""C_failed_conversion_TS_Folder=" & C_failed_conversion_TS_Folder & """")
		WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_Convert_files_in_a_folder                        ""C_temp_path=" & C_temp_path & """")
		WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_Convert_files_in_a_folder ""vrdtvsp_profile_name_for_qsf_mpeg2=" & vrdtvsp_profile_name_for_qsf_mpeg2 & """")
		WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_Convert_files_in_a_folder            ""vrdtvsp_extension_mpeg2=" & vrdtvsp_extension_mpeg2 & """")
		WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_Convert_files_in_a_folder   ""vrdtvsp_profile_name_for_qsf_avc=" & vrdtvsp_profile_name_for_qsf_avc & """")
		WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_Convert_files_in_a_folder              ""vrdtvsp_extension_avc=" & vrdtvsp_extension_avc & """")
		WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_Convert_files_in_a_folder                ""vrd_version_for_qsf=" & vrd_version_for_qsf & """")
		WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_Convert_files_in_a_folder           ""vrdtvsp_path_for_qsf_vbs=" & vrdtvsp_path_for_qsf_vbs & """")
		WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_Convert_files_in_a_folder             ""vrd_version_for_adscan=" & vrd_version_for_adscan & """")
		WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_Convert_files_in_a_folder        ""vrdtvsp_path_for_adscan_vbs=" & vrdtvsp_path_for_adscan_vbs & """")
		WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_Convert_files_in_a_folder   ""C_saved_ffmpeg_commands_filename=" & C_saved_ffmpeg_commands_filename & """")
		WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_Convert_files_in_a_folder                        ""C_do_Adscan=" & C_do_Adscan & """")
		WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_Convert_files_in_a_folder                   ""C_do_audio_delay=" & C_do_audio_delay & """")
	End If
	'
	' delete the saved FFMPEG COMMANDS file silently 
	vrdtvsp_status = vrdtvsp_delete_a_file(C_saved_ffmpeg_commands_filename, True)
	If vrdtvsp_status <> 0 AND vrdtvsp_status <> 53 Then ' Something went wrong with deleting the file, but allow 53 "File not found"
		If vrdtvsp_DEBUG Then WScript.StdOut.WriteLine("VRDTVSP DEBUG: VRDTVSP ERROR vrdtvsp_Convert_files_in_a_folder - Error " & vrdtvsp_status & " from vrdtvsp_delete_a_file with saved FFMPEG COMMANDS """ & C_saved_ffmpeg_commands_filename & """... Aborting ...")
		WScript.StdOut.WriteLine("VRDTVSP ERROR vrdtvsp_Convert_files_in_a_folder - Error " & vrdtvsp_status & " from vrdtvsp_delete_a_file with saved FFMPEG COMMANDS """ & C_saved_ffmpeg_commands_filename & """... Aborting ...")
		Wscript.Echo "Error 17 = cannot perform the requested operation"
		On Error goto 0
		WScript.Quit 17 ' Error 17 = cannot perform the requested operation
	End If
	' create a new empty FFMPEG COMMANDS file with overwrite
	set C_object_saved_ffmpeg_commands = fso.CreateTextFile(C_saved_ffmpeg_commands_filename, True, False) ' *** make .BAT file ascii for compatibility, since vapoursynth fails with unicode files [ filename, Overwrite[, Unicode]])
	If C_object_saved_ffmpeg_commands is Nothing  Then ' Something went wrong with creating the file
		If vrdtvsp_DEBUG Then WScript.StdOut.WriteLine("VRDTVSP DEBUG: VRDTVSP ERROR vrdtvsp_Convert_files_in_a_folder - Error - Nothing object returned from fso.CreateTextFile with saved FFMPEG COMMANDS """ & C_saved_ffmpeg_commands_filename & """... Aborting ...")
		WScript.StdOut.WriteLine("VRDTVSP ERROR vrdtvsp_Convert_files_in_a_folder - Error - Nothing object returned from fso.CreateTextFile with saved FFMPEG COMMANDS """ & C_saved_ffmpeg_commands_filename & """... Aborting ...")
		Wscript.Echo "Error 17 = cannot perform the requested operation"
		On Error goto 0
		WScript.Quit 17 ' Error 17 = cannot perform the requested operation
	End If
	'
	' Initialize the saved-ffmpeg-commands file
	C_object_saved_ffmpeg_commands.WriteLine("@ECHO ON")
	C_object_saved_ffmpeg_commands.WriteLine("@setlocal ENABLEDELAYEDEXPANSION")
	C_object_saved_ffmpeg_commands.WriteLine("@setlocal enableextensions")
	C_object_saved_ffmpeg_commands.WriteLine("REM")
	C_object_saved_ffmpeg_commands.WriteLine("REM Computername=""" & vrdtvsp_ComputerName & """" )
	C_object_saved_ffmpeg_commands.WriteLine("REM Saved ffmpeg commands: """ & C_saved_ffmpeg_commands_filename & """")
	C_object_saved_ffmpeg_commands.WriteLine("REM Created " & vrdtvsp_current_datetime_string)
	C_object_saved_ffmpeg_commands.WriteLine("REM")
	C_object_saved_ffmpeg_commands.WriteLine("Set ""vapoursynth_root=" & vapoursynth_root & """")
	C_object_saved_ffmpeg_commands.WriteLine("Set ""vrdtvsp_mp4boxexex64=" & vrdtvsp_mp4boxexex64 & """")
	C_object_saved_ffmpeg_commands.WriteLine("Set ""vrdtvsp_mediainfoexe64=" & vrdtvsp_mediainfoexe64 & """")
	C_object_saved_ffmpeg_commands.WriteLine("Set ""vrdtvsp_ffprobeexe64=" & vrdtvsp_ffprobeexe64 & """")
	C_object_saved_ffmpeg_commands.WriteLine("Set ""vrdtvsp_ffmpegexe64=" & vrdtvsp_ffmpegexe64 & """")
	C_object_saved_ffmpeg_commands.WriteLine("Set ""vrdtvsp_dgindexNVexe64=" & vrdtvsp_dgindexNVexe64 & """")
	C_object_saved_ffmpeg_commands.WriteLine("Set ""vrdtvsp_Insomniaexe64=" & vrdtvsp_Insomniaexe64 & """")
	C_object_saved_ffmpeg_commands.WriteLine("REM")
	C_object_saved_ffmpeg_commands.WriteLine("Set ""C_source_TS_Folder=" & C_source_TS_Folder & """")
	C_object_saved_ffmpeg_commands.WriteLine("Set ""C_done_TS_Folder=" & C_done_TS_Folder & """")
	C_object_saved_ffmpeg_commands.WriteLine("Set ""C_destination_mp4_Folder=" & C_destination_mp4_Folder & """")
	C_object_saved_ffmpeg_commands.WriteLine("Set ""C_failed_conversion_TS_Folder=" & C_failed_conversion_TS_Folder & """")
	C_object_saved_ffmpeg_commands.WriteLine("Set ""C_temp_path=" & C_temp_path & """")
	C_object_saved_ffmpeg_commands.WriteLine("REM")
	C_object_saved_ffmpeg_commands.WriteLine("Set ""vrdtvsp_profile_name_for_qsf_mpeg2=" & vrdtvsp_profile_name_for_qsf_mpeg2 & """")
	C_object_saved_ffmpeg_commands.WriteLine("Set ""vrdtvsp_extension_mpeg2=" & vrdtvsp_extension_mpeg2 & """")
	C_object_saved_ffmpeg_commands.WriteLine("Set ""vrdtvsp_profile_name_for_qsf_avc=" & vrdtvsp_profile_name_for_qsf_avc & """")
	C_object_saved_ffmpeg_commands.WriteLine("Set ""vrdtvsp_extension_avc=" & vrdtvsp_extension_avc & """")
	C_object_saved_ffmpeg_commands.WriteLine("REM")
	C_object_saved_ffmpeg_commands.WriteLine("Set ""vrd_version_for_qsf=" & vrd_version_for_qsf & """")
	C_object_saved_ffmpeg_commands.WriteLine("Set ""vrdtvsp_path_for_qsf_vbs=" & vrdtvsp_path_for_qsf_vbs & """")
	C_object_saved_ffmpeg_commands.WriteLine("Set ""vrd_version_for_adscan=" & vrd_version_for_adscan & """")
	C_object_saved_ffmpeg_commands.WriteLine("Set ""vrdtvsp_path_for_adscan_vbs=" & vrdtvsp_path_for_adscan_vbs & """")
	C_object_saved_ffmpeg_commands.WriteLine("REM")
	C_object_saved_ffmpeg_commands.WriteLine("Set ""C_saved_ffmpeg_commands_filename=" & C_saved_ffmpeg_commands_filename & """")
	C_object_saved_ffmpeg_commands.WriteLine("Set ""C_do_Adscan=" & C_do_Adscan & """")
	C_object_saved_ffmpeg_commands.WriteLine("Set ""C_do_audio_delay=" & C_do_audio_delay & """")
	C_object_saved_ffmpeg_commands.WriteLine("REM")
	C_object_saved_ffmpeg_commands.WriteLine("REM NO FILES WILL BE MOVED between folders ")
	C_object_saved_ffmpeg_commands.WriteLine("REM the SOURCE      .TS and .mp4 and .mpg media files MUST already exist in folder: """ & C_source_TS_Folder & """")
	C_object_saved_ffmpeg_commands.WriteLine("REM the DESTINATION .mp4 and .vprj files will be created (overwritten) in folder  : """ & C_destination_mp4_Folder & """")
	C_object_saved_ffmpeg_commands.WriteLine("REM NO FILES WILL BE MOVED between folders ")
	C_object_saved_ffmpeg_commands.WriteLine("REM")
	'	
	' ' loop through all files in the source folder, treating each one according to its Extension
	Set C_object_Folder = fso.GetFolder(C_source_TS_Folder)
	Set C_object_Files_Collection = C_object_Folder.Files
	For Each C_object_File in C_object_Files_Collection ' loop through all files in the source folder, treating each one according to its Extension
		C_FILE_AbsolutePathName = fso.GetAbsolutePathName(C_object_File.Path)
		C_FILE_ParentFolderName = fso.GetParentFolderName(C_FILE_AbsolutePathName)
		C_FILE_BaseName = fso.GetBaseName(C_FILE_AbsolutePathName)
		C_FILE_Ext = fso.GetExtensionName(C_FILE_AbsolutePathName)
        '********* FILTER BY FILE EXTENSION *********
		If Ucase(C_FILE_Ext) = Ucase("ts") OR Ucase(C_FILE_Ext) = Ucase("mp4") OR Ucase(C_FILE_Ext) = Ucase("mpg") OR Ucase(C_FILE_Ext) = Ucase("vprj") Then ' ********** only process specific file extensions
			WScript.StdOut.WriteLine("======================================================================================================================================================")
			WScript.StdOut.WriteLine("#################### PROCESSING file C_FILE_AbsolutePathName=""" & C_FILE_AbsolutePathName & """ ========== " &  vrdtvsp_current_datetime_string())
			WScript.StdOut.WriteLine("#################### PROCESSING file C_FILE_AbsolutePathName=""" & C_FILE_AbsolutePathName & """ ========== " &  vrdtvsp_current_datetime_string())
			WScript.StdOut.WriteLine(" ")
			Select Case Ucase(C_FILE_Ext)
			Case Ucase("vprj") 										' it's in the source folder, ignore it
			Case Ucase("ts"), Ucase("mp4"), Ucase("mpg")			' if it's one of these then convert it
				vrdtvsp_status = vrdtvsp_Convert_File(	C_FILE_AbsolutePathName, _
														C_object_saved_ffmpeg_commands, _
														C_source_TS_Folder, _
														C_done_TS_Folder, _
														C_destination_mp4_Folder, _
														C_failed_conversion_TS_Folder, _
														C_temp_path, _
														C_saved_ffmpeg_commands_filename, _
														C_do_Adscan, _
														C_do_audio_delay )
				' hmm, looks like status checking is ignored ... eg "-1" for failed conversion
				If vrdtvsp_status <> 0 Then
					WScript.StdOut.WriteLine("VRDTVSP ERROR vrdtvsp_Convert_files_in_a_folder - Error - SOURCE FILE NOT CONVERTED, ASSUMED FILE(S) HAVE BEEN MOVED TO FAILED FOLDER. File: """ & C_FILE_AbsolutePathName & """... Continuing ...")
				End If
			Case Else	' extension not recognised, do Nothing
			End Select 
			WScript.StdOut.WriteLine(" ")
			WScript.StdOut.WriteLine("#################### FINISHED PROCESSING file C_FILE_AbsolutePathName=""" & C_FILE_AbsolutePathName & """ ========== " & vrdtvsp_current_datetime_string())
			WScript.StdOut.WriteLine("#################### FINISHED PROCESSING file C_FILE_AbsolutePathName=""" & C_FILE_AbsolutePathName & """ ========== " & vrdtvsp_current_datetime_string())
			WScript.StdOut.WriteLine("======================================================================================================================================================")
		End If
	Next
	'
	vrdtvsp_status = C_object_saved_ffmpeg_commands.Close
	Set C_object_saved_ffmpeg_commands = Nothing
	WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_files_in_a_folder FINISHED: " & vrdtvsp_current_datetime_string())
	WScript.StdOut.WriteLine("" & vrdtvsp_current_datetime_string())
	vrdtvsp_Convert_files_in_a_folder = 0 ' return success
End Function
'
Function vrdtvsp_exec_a_command_and_show_stdout_stderr (byVAL eac_command_string)
	Const sleep_amount = 1000	' 1 second = 1000 ms
	Dim cumulative_sleep
	Dim  eac_exe_cmd_string, eac_exe_object, eac_exe_status, eac_tmp
	If eac_command_string = "" then
		vrdtvsp_exec_a_command_and_show_stdout_stderr = 0
		Exit Function
	End If
	WScript.StdOut.WriteLine("======================================================================================================================================================")
	WScript.StdOut.WriteLine("vrdtvsp_exec_a_command_and_show_stdout_stderr " & vrdtvsp_current_datetime_string())
	' Examples with and without CMD and 2>&1
	'		eac_exe_cmd_string = "CMD /C ""something"""
	'		eac_exe_cmd_string = "CMD /C ""something"" 2>&1"
	'		eac_exe_cmd_string = "Taskkill ""something"""
	'		eac_exe_cmd_string = "Taskkill ""something"" 2>&1"
	If vrdtvsp_DEVELOPMENT_NO_ACTIONS Then ' DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV 
		eac_exe_object = "REM " & eac_command_string ' comment out any action
	End If
	WScript.StdOut.WriteLine("EXEC command: " & eac_command_string)
	cumulative_sleep = 0
	set eac_exe_object = wso.Exec(eac_command_string)
	Do While eac_exe_object.Status = 0 '0 is running and 1 is ending
		Wscript.Echo "vrdtvsp_exec_a_command_and_show_stdout_stderr About to sleep for " & sleep_amount & " ms (slept " & (cumulative_sleep/1000) & " seconds so far)"
	 	Wscript.Sleep sleep_amount
		cumulative_sleep = cumulative_sleep + sleep_amount
	Loop
	WScript.StdOut.WriteLine("START StdOut: ")
	Do Until eac_exe_object.StdOut.AtEndOfStream
		eac_tmp = eac_exe_object.StdOut.ReadLine()
		WScript.StdOut.WriteLine(eac_tmp)
	Loop
	WScript.StdOut.WriteLine("END   StdOut: ")
	WScript.StdOut.WriteLine("START StdErr: ")
	Do Until eac_exe_object.StdErr.AtEndOfStream
		eac_tmp = eac_exe_object.StdErr.ReadLine()
		WScript.StdOut.WriteLine(eac_tmp)
	Loop
	WScript.StdOut.WriteLine("END   StdErr: ")
	eac_exe_status = eac_exe_object.ExitCode
	WScript.StdOut.WriteLine("EXIT STATUS: " & eac_exe_status)
	Set eac_exe_object = Nothing
	If vrdtvsp_DEBUG Then WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_exec_a_command_and_show_stdout_stderr exiting with status=""" & eac_exe_status & """")
	WScript.StdOut.WriteLine("vrdtvsp_exec_a_command_and_show_stdout_stderr " & vrdtvsp_current_datetime_string())
	WScript.StdOut.WriteLine("======================================================================================================================================================")
	vrdtvsp_exec_a_command_and_show_stdout_stderr = eac_exe_status
End Function
'
Function vrdtvsp_exec_a_FFMPEG_command_and_show_stderr_only (byVAL eac_command_string)
	Dim  eac_exe_cmd_string, eac_exe_object, eac_exe_status, eac_tmp
	If eac_command_string = "" then
		vrdtvsp_exec_a_FFMPEG_command_and_show_stderr_only = 0
		Exit Function
	End If
	WScript.StdOut.WriteLine("======================================================================================================================================================")
	WScript.StdOut.WriteLine("vrdtvsp_exec_a_FFMPEG_command_and_show_stderr_only " & vrdtvsp_current_datetime_string())
	If vrdtvsp_DEVELOPMENT_NO_ACTIONS Then ' DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV 
		eac_exe_object = "REM " & eac_command_string ' comment out any action
	End If
	WScript.StdOut.WriteLine("EXEC command: " & eac_command_string)
	set eac_exe_object = wso.Exec(eac_command_string)
	Do While eac_exe_object.Status = 0 '0 is running and 1 is ending
	 	Wscript.Sleep 100
		'Wscript.Echo "vrdtvsp_exec_a_FFMPEG_command_and_show_stderr_only About to sleep for 5 seconds"
		'Wscript.Sleep 5000
	Loop
	'WScript.StdOut.WriteLine("vrdtvsp_exec_a_command_and_show_stdout_stderr START StdOut: ")
	'Do Until eac_exe_object.StdOut.AtEndOfStream
	'	eac_tmp = eac_exe_object.StdOut.ReadLine()
	'	WScript.StdOut.WriteLine(eac_tmp)
	'Loop
	'WScript.StdOut.WriteLine("vrdtvsp_exec_a_command_and_show_stdout_stderr END   StdOut: ")
	WScript.StdOut.WriteLine("START StdErr: ")
	Do Until eac_exe_object.StdErr.AtEndOfStream
		eac_tmp = eac_exe_object.StdErr.ReadLine()
		WScript.StdOut.WriteLine(eac_tmp)
	Loop
	WScript.StdOut.WriteLine("END   StdErr: ")
	eac_exe_status = eac_exe_object.ExitCode
	WScript.StdOut.WriteLine("EXIT STATUS: " & eac_exe_status)
	Set eac_exe_object = Nothing
	If vrdtvsp_DEBUG Then WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_exec_a_command_and_show_stdout_stderr exiting with status=""" & eac_exe_status & """")
	WScript.StdOut.WriteLine("vrdtvsp_exec_a_FFMPEG_command_and_show_stderr_only " & vrdtvsp_current_datetime_string())
	WScript.StdOut.WriteLine("======================================================================================================================================================")
	vrdtvsp_exec_a_command_and_show_stdout_stderr = eac_exe_status
End Function
'
Function vrdtvsp_Convert_File (	byVal	CF_FILE_AbsolutePathName, _
								byRef	CF_object_saved_ffmpeg_commands, _
								byVAL 	CF_source_TS_Folder, _
								byVAL 	CF_done_TS_Folder, _
								byVAL 	CF_destination_mp4_Folder, _
								byVAL 	CF_failed_conversion_TS_Folder, _
								byVAL 	CF_temp_path, _
								byVAL 	CF_saved_ffmpeg_commands_filename, _
								byVAL 	CF_do_Adscan, _
								byVal	CF_do_audio_delay )
	'Dim CF_FILE_AbsolutePathName
	Dim                             CF_FILE_ParentFolderName,   CF_FILE_BaseName,   CF_FILE_Ext
	Dim CF_QSF_AbsolutePathName,    CF_QSF_ParentFolderName,    CF_QSF_BaseName,    CF_QSF_Ext
	Dim CF_QSFxml_AbsolutePathName, CF_QSFxml_ParentFolderName, CF_QSFxml_BaseName, CF_QSFxml_Ext
	Dim CF_TARGET_AbsolutePathName, CF_TARGET_ParentFolderName, CF_TARGET_BaseName, CF_TARGET_Ext
	Dim CF_vprj_AbsolutePathName,   CF_vprj_ParentFolderName,   CF_vprj_BaseName,   CF_vprj_Ext
	Dim CF_VPY_AbsolutePathName,    CF_VPY_ParentFolderName,    CF_VPY_BaseName,    CF_VPY_Ext, CF_VPY_object, CF_VPY_string
	Dim CF_DGI_AbsolutePathName,    CF_DGI_ParentFolderName,    CF_DGI_BaseName,    CF_DGI_Ext
	Dim CF_DGIlog_AbsolutePathName, CF_DGIlog_ParentFolderName, CF_DGIlog_BaseName, CF_DGIlog_Ext
	'
	Dim fallback_vrdtvsp_profile_name_for_qsfv5
	Dim   V_IsAVC,   V_IsMPEG2,   V_IsProgressive,   V_IsInterlaced
	Dim Q_V_IsAVC, Q_V_IsMPEG2, Q_V_IsProgressive, Q_V_IsInterlaced
	Dim T_V_IsAVC, T_V_IsMPEG2, T_V_IsProgressive, T_V_IsInterlaced
	'
	Dim ff_cmd_string, ff_tmp_object, ff_tmp_string, ff_logfile, ff_batfile, ff_cmd_string_for_bat, ff_run_errorlevel
	'
	Dim CF_exe_cmd_string_0, CF_exe_cmd_string
	Dim CF_exe_object
	Dim CF_exe_status
	Dim CF_tmp, CF_val
	Dim CF_status
	'
	Dim ff_timerStart, ff_timerEnd
	'
	Dim V_Codec_legacy
	Dim V_Format_legacy
	Dim V_DisplayAspectRatio_String
	Dim V_PixelAspectRatio
	Dim V_ScanType
	Dim V_ScanOrder
	Dim V_Width
	Dim V_Height
	Dim V_BitRate
	Dim V_BitRate_Minimum
	Dim V_BitRate_Maximum
	Dim A_Codec_legacy
	Dim A_CodecID_legacy
	Dim A_Format_legacy
	Dim A_Video_Delay_ms_legacy
	Dim A_CodecID
	Dim A_CodecID_String
	Dim A_Video_Delay_ms
	Dim V_CodecID_FF
	Dim V_CodecID_String_FF
	Dim V_Width_FF
	Dim V_Height_FF
	Dim V_Duration_s_FF
	Dim V_BitRate_FF
	Dim V_BitRate_Maximum_FF
	Dim V_DisplayAspectRatio_String_slash
	Dim A_Audio_Delay_ms
	Dim A_Audio_Delay_ms_legacy
	'
	Dim Q_V_Codec_legacy
	Dim Q_V_Format_legacy
	Dim Q_V_DisplayAspectRatio_String
	Dim Q_V_PixelAspectRatio
	Dim Q_V_ScanType
	Dim Q_V_ScanOrder
	Dim Q_V_Width
	Dim Q_V_Height
	Dim Q_V_BitRate
	Dim Q_V_BitRate_Minimum
	Dim Q_V_BitRate_Maximum
	Dim Q_A_Codec_legacy
	Dim Q_A_CodecID_legacy
	Dim Q_A_Format_legacy
	Dim Q_A_Video_Delay_ms_legacy
	Dim Q_A_CodecID
	Dim Q_A_CodecID_String
	Dim Q_A_Video_Delay_ms
	Dim Q_V_CodecID_FF
	Dim Q_V_CodecID_String_FF
	Dim Q_V_Width_FF
	Dim Q_V_Height_FF
	Dim Q_V_Duration_s_FF
	Dim Q_V_BitRate_FF
	Dim Q_V_BitRate_Maximum_FF
	Dim Q_V_DisplayAspectRatio_String_slash
	Dim Q_A_Audio_Delay_ms
	Dim Q_A_Audio_Delay_ms_legacy
	'
	Dim T_V_Codec_legacy
	Dim T_V_Format_legacy
	Dim T_V_DisplayAspectRatio_String
	Dim T_V_PixelAspectRatio
	Dim T_V_ScanType
	Dim T_V_ScanOrder
	Dim T_V_Width
	Dim T_V_Height
	Dim T_V_BitRate
	Dim T_V_BitRate_Minimum
	Dim T_V_BitRate_Maximum
	Dim T_A_Codec_legacy
	Dim T_A_CodecID_legacy
	Dim T_A_Format_legacy
	Dim T_A_Video_Delay_ms_legacy
	Dim T_A_CodecID
	Dim T_A_CodecID_String
	Dim T_A_Video_Delay_ms
	Dim T_V_CodecID_FF
	Dim T_V_CodecID_String_FF
	Dim T_V_Width_FF
	Dim T_V_Height_FF
	Dim T_V_Duration_s_FF
	Dim T_V_BitRate_FF
	Dim T_V_BitRate_Maximum_FF
	Dim T_V_DisplayAspectRatio_String_slash
	Dim T_A_Audio_Delay_ms
	Dim T_A_Audio_Delay_ms_legacy
	'
	Dim Q_ACTUAL_QSF_XML_BITRATE
	Dim V_INCOMING_BITRATE
	Dim V_INCOMING_BITRATE_MEDIAINFO
	Dim V_INCOMING_BITRATE_FFPROBE
	Dim V_INCOMING_BITRATE_QSF_XML
	'
	Dim vrdtvsp_final_RTX2060super_extra_flags
	'
	Dim FF_V_Target_BitRate
	Dim FF_V_Target_Minimum_BitRate
	Dim FF_V_Target_Maximum_BitRate
	Dim FF_V_Target_BufSize
	Dim x_cq0, x_cq24, PROPOSED_x_cq_options
	Dim vrdtvsp_final_cq_options
	'
	Dim vrdtvsp_final_dg_tff
	Dim vrdtvsp_final_dg_deinterlace
	'
	Dim Footy_found
	Dim Footy_FF_V_Target_BitRate
	Dim Footy_FF_V_Target_Minimum_BitRate
	Dim Footy_FF_V_Target_Maximum_BitRate
	Dim Footy_FF_V_Target_BufSize
	'
	Dim vrdtvsp_create_VPY
	Dim vpy_denoise
	Dim vpy_dsharpen
	Dim af_audio_delay_filter, it_video_delay
	'
	Dim Q_V_FrameRate
	Dim Q_V_FrameRate_String
	Dim Q_V_Frame_Rate_FF
	Dim Q_V_Avg_Frame_Rate_FF
	'
	Dim xmlDict, xmlDict_key
	'
	V_IsAVC = False
	V_IsMPEG2 = False
	V_IsProgressive = False
	V_IsInterlaced = False
	'
	CF_temp_path = fso.GetAbsolutePathName(CF_temp_path & "\")
	CF_FILE_AbsolutePathName = fso.GetAbsolutePathName(CF_FILE_AbsolutePathName) ' ENSURE AN ABSOLUTE
	CF_FILE_ParentFolderName = fso.GetParentFolderName(CF_FILE_AbsolutePathName)
	CF_FILE_BaseName = fso.GetBaseName(CF_FILE_AbsolutePathName)
	CF_FILE_Ext = fso.GetExtensionName(CF_FILE_AbsolutePathName)
	'
	' Now that we know the Video Codec and have determined that proper QSF File extension to use, set things up
	CF_TARGET_ParentFolderName = CF_destination_mp4_Folder
	CF_TARGET_BaseName = CF_FILE_BaseName
	CF_TARGET_Ext = "mp4"		' always .mp4
	CF_TARGET_AbsolutePathName = fso.GetAbsolutePathName(fso.BuildPath(CF_TARGET_ParentFolderName,CF_TARGET_BaseName & "." & CF_TARGET_Ext))
	'
	CF_vprj_ParentFolderName = CF_destination_mp4_Folder
	CF_vprj_BaseName = CF_TARGET_BaseName
	CF_vprj_Ext = "vprj"		' always .vprj
	CF_vprj_AbsolutePathName = fso.GetAbsolutePathName(fso.BuildPath(CF_vprj_ParentFolderName,CF_vprj_BaseName & "." & CF_vprj_Ext))
	'
	CF_QSF_ParentFolderName = CF_temp_path
	CF_QSF_BaseName = CF_FILE_BaseName & ".QSF"
	vrdtvsp_extension = vrdtvsp_extension_avc ' ******************** default to AVC for initialization purposes
	CF_QSF_Ext = vrdtvsp_extension ' set above based on incoming codec
	CF_QSF_AbsolutePathName = fso.GetAbsolutePathName(fso.BuildPath(CF_QSF_ParentFolderName,CF_QSF_BaseName & "." & CF_QSF_Ext))
	'
	CF_QSFxml_ParentFolderName = CF_temp_path
	CF_QSFxml_BaseName = CF_FILE_BaseName & ".QSF"
	CF_QSFxml_Ext = "xml"
	CF_QSFxml_AbsolutePathName = fso.GetAbsolutePathName(fso.BuildPath(CF_QSF_ParentFolderName,CF_QSF_BaseName & "." & CF_QSFxml_Ext))
	'
	CF_VPY_ParentFolderName = CF_temp_path
	CF_VPY_BaseName = CF_QSF_BaseName
	CF_VPY_Ext = "vpy"			' always .vpy
	CF_VPY_AbsolutePathName = fso.GetAbsolutePathName(fso.BuildPath(CF_VPY_ParentFolderName,CF_VPY_BaseName & "." & CF_VPY_Ext))
	'
	CF_DGI_ParentFolderName = CF_temp_path
	CF_DGI_BaseName = CF_QSF_BaseName
	CF_DGI_Ext = "dgi"			' always .dgi
	CF_DGI_AbsolutePathName = fso.GetAbsolutePathName(fso.BuildPath(CF_DGI_ParentFolderName,CF_DGI_BaseName & "." & CF_DGI_Ext))
	'
	CF_DGIlog_ParentFolderName = CF_temp_path
	CF_DGIlog_BaseName = CF_QSF_BaseName
	CF_DGIlog_Ext = "log"			' always .log
	CF_DGIlog_AbsolutePathName = fso.GetAbsolutePathName(fso.BuildPath(CF_DGI_ParentFolderName,CF_DGIlog_BaseName & "." & CF_DGIlog_Ext))
	'	
	WScript.StdOut.WriteLine(" ")
	WScript.StdOut.WriteLine("======================================================================================================================================================")
	WScript.StdOut.WriteLine("" & vrdtvsp_current_datetime_string())
	WScript.StdOut.WriteLine("vrdtvsp_Convert_File STARTED " & vrdtvsp_current_datetime_string())
	WScript.StdOut.WriteLine(" ")
	WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File:           CF_FILE_AbsolutePathName=""" & CF_FILE_AbsolutePathName & """")
	WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File:                CF_source_TS_Folder=""" & CF_source_TS_Folder & """")
	WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File:                  CF_done_TS_Folder=""" & CF_done_TS_Folder & """")
	WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File:          CF_destination_mp4_Folder=""" & CF_destination_mp4_Folder & """")
	WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File:     CF_failed_conversion_TS_Folder=""" & CF_failed_conversion_TS_Folder & """")
	WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File:                       CF_temp_path=""" & CF_temp_path & """")
	WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File:  CF_saved_ffmpeg_commands_filename=""" & CF_saved_ffmpeg_commands_filename & """")
	WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File:                       CF_do_Adscan=""" & CF_do_Adscan & """")
	WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File:                  CF_do_audio_delay=""" & CF_do_audio_delay & """")
	'
	If NOT fso.FileExists(CF_FILE_AbsolutePathName) Then
		If vrdtvsp_DEBUG Then WScript.StdOut.WriteLine("VRDTVSP DEBUG: VRDTVSP ERROR vrdtvsp_Convert_File - Error - SUPPOSEDLY VALID SOURCE FILE NOT FOUND """ & CF_FILE_AbsolutePathName & """... Aborting ...")
		WScript.StdOut.WriteLine("VRDTVSP ERROR vrdtvsp_Convert_File - Error - SUPPOSEDLY VALID SOURCE FILE NOT FOUND """ & CF_FILE_AbsolutePathName & """... Aborting ...")
		WScript.StdOut.WriteLine("VRDTVSP ERROR vrdtvsp_Convert_File - Error - SUPPOSEDLY VALID SOURCE FILE NOT FOUND """ & CF_FILE_AbsolutePathName & """... Aborting ...")
		WScript.StdOut.WriteLine("VRDTVSP ERROR vrdtvsp_Convert_File - Error - SUPPOSEDLY VALID SOURCE FILE NOT FOUND """ & CF_FILE_AbsolutePathName & """... Aborting ...")
		WScript.StdOut.WriteLine("VRDTVSP ERROR vrdtvsp_Convert_File - Error - SUPPOSEDLY VALID SOURCE FILE NOT FOUND """ & CF_FILE_AbsolutePathName & """... Aborting ...")
		WScript.StdOut.WriteLine("VRDTVSP ERROR vrdtvsp_Convert_File - Error - SUPPOSEDLY VALID SOURCE FILE NOT FOUND """ & CF_FILE_AbsolutePathName & """... Aborting ...")
		On Error goto 0
		vrdtvsp_status = vrdtvsp_move_files_to_folder(CF_FILE_AbsolutePathName, CF_failed_conversion_TS_Folder)
		vrdtvsp_status = vrdtvsp_move_files_to_folder(CF_vprj_AbsolutePathName, CF_failed_conversion_TS_Folder)
		'vrdtvsp_status = vrdtvsp_delete_a_file(CF_DGI_AbsolutePathName, True)
		'vrdtvsp_status = vrdtvsp_delete_a_file(CF_VPY_AbsolutePathName, True)
		'vrdtvsp_status = vrdtvsp_delete_a_file(CF_QSF_AbsolutePathName, True)
		WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File: - ???????????????????? moved FAILED CONVERSION file to FAILED folder: """ & CF_FILE_AbsolutePathName & """ to """ & CF_failed_conversion_TS_Folder & """")
		WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File: - ???????????????????? moved FAILED CONVERSION file to FAILED folder: """ & CF_FILE_AbsolutePathName & """ to """ & CF_failed_conversion_TS_Folder & """")
		WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File: - ???????????????????? moved FAILED CONVERSION file to FAILED folder: """ & CF_FILE_AbsolutePathName & """ to """ & CF_failed_conversion_TS_Folder & """")
		WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File: - ???????????????????? moved FAILED CONVERSION file to FAILED folder: """ & CF_FILE_AbsolutePathName & """ to """ & CF_failed_conversion_TS_Folder & """")
		WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File: - ???????????????????? moved FAILED CONVERSION file to FAILED folder: """ & CF_FILE_AbsolutePathName & """ to """ & CF_failed_conversion_TS_Folder & """")
		WScript.StdOut.WriteLine(" ")
		WScript.StdOut.WriteLine("vrdtvsp_Convert_File FINISHED " & vrdtvsp_current_datetime_string())
		WScript.StdOut.WriteLine("" & vrdtvsp_current_datetime_string())
		WScript.StdOut.WriteLine("======================================================================================================================================================")
		WScript.StdOut.WriteLine(" ")
		vrdtvsp_Convert_File = -1
		Exit Function
	End If
	If vrdtvsp_DEBUG Then
		If vrdtvsp_DEBUG Then WScript.StdOut.WriteLine("VRDTVSP DEBUG: Entered vrdtvsp_Convert_File with VALID SOURCE FILE """ & CF_FILE_AbsolutePathName & """")
	End If
	'
	' GET a bunch of useful info from the SOURCE media file via mediainfo
	V_Codec_legacy						= vrdtvsp_get_mediainfo_parameter("Video", "Codec", CF_FILE_AbsolutePathName, "--Legacy") 
	If V_Codec_legacy = "" Then
		'If blank codec returned by mediainfo, the files is in error
		WScript.StdOut.WriteLine("VRDTVSP ERROR vrdtvsp_Convert_File - Error - BLANK CODEC DETECTED BY MEDIAINFO, HAS TO BE A BAD FILE;  """ & CF_FILE_AbsolutePathName & """... Aborting ...")
		WScript.StdOut.WriteLine("VRDTVSP ERROR vrdtvsp_Convert_File - Error - BLANK CODEC DETECTED BY MEDIAINFO, HAS TO BE A BAD FILE;  """ & CF_FILE_AbsolutePathName & """... Aborting ...")
		WScript.StdOut.WriteLine("VRDTVSP ERROR vrdtvsp_Convert_File - Error - BLANK CODEC DETECTED BY MEDIAINFO, HAS TO BE A BAD FILE;  """ & CF_FILE_AbsolutePathName & """... Aborting ...")
		WScript.StdOut.WriteLine("VRDTVSP ERROR vrdtvsp_Convert_File - Error - BLANK CODEC DETECTED BY MEDIAINFO, HAS TO BE A BAD FILE;  """ & CF_FILE_AbsolutePathName & """... Aborting ...")
		WScript.StdOut.WriteLine("VRDTVSP ERROR vrdtvsp_Convert_File - Error - BLANK CODEC DETECTED BY MEDIAINFO, HAS TO BE A BAD FILE;  """ & CF_FILE_AbsolutePathName & """... Aborting ...")
		On Error goto 0
		vrdtvsp_status = vrdtvsp_move_files_to_folder(CF_FILE_AbsolutePathName, CF_failed_conversion_TS_Folder)
		vrdtvsp_status = vrdtvsp_move_files_to_folder(CF_vprj_AbsolutePathName, CF_failed_conversion_TS_Folder)
		'vrdtvsp_status = vrdtvsp_delete_a_file(CF_DGI_AbsolutePathName, True)
		'vrdtvsp_status = vrdtvsp_delete_a_file(CF_VPY_AbsolutePathName, True)
		'vrdtvsp_status = vrdtvsp_delete_a_file(CF_QSF_AbsolutePathName, True)
		WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File: - ???????????????????? moved FAILED CONVERSION file to FAILED folder: """ & CF_FILE_AbsolutePathName & """ to """ & CF_failed_conversion_TS_Folder & """")
		WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File: - ???????????????????? moved FAILED CONVERSION file to FAILED folder: """ & CF_FILE_AbsolutePathName & """ to """ & CF_failed_conversion_TS_Folder & """")
		WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File: - ???????????????????? moved FAILED CONVERSION file to FAILED folder: """ & CF_FILE_AbsolutePathName & """ to """ & CF_failed_conversion_TS_Folder & """")
		WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File: - ???????????????????? moved FAILED CONVERSION file to FAILED folder: """ & CF_FILE_AbsolutePathName & """ to """ & CF_failed_conversion_TS_Folder & """")
		WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File: - ???????????????????? moved FAILED CONVERSION file to FAILED folder: """ & CF_FILE_AbsolutePathName & """ to """ & CF_failed_conversion_TS_Folder & """")
		WScript.StdOut.WriteLine(" ")
		WScript.StdOut.WriteLine("vrdtvsp_Convert_File FINISHED " & vrdtvsp_current_datetime_string())
		WScript.StdOut.WriteLine("" & vrdtvsp_current_datetime_string())
		WScript.StdOut.WriteLine("======================================================================================================================================================")
		WScript.StdOut.WriteLine(" ")
		vrdtvsp_Convert_File = -1
		Exit Function
	End If
	V_Format_legacy						= vrdtvsp_get_mediainfo_parameter("Video", "Format", CF_FILE_AbsolutePathName, "--Legacy") 
	V_DisplayAspectRatio_String			= vrdtvsp_get_mediainfo_parameter("Video", "DisplayAspectRatio/String", CF_FILE_AbsolutePathName, "")
	V_PixelAspectRatio					= vrdtvsp_get_mediainfo_parameter("Video", "PixelAspectRatio", CF_FILE_AbsolutePathName, "")
	V_ScanType							= vrdtvsp_get_mediainfo_parameter("Video", "ScanType", CF_FILE_AbsolutePathName, "")
	V_ScanOrder 						= vrdtvsp_get_mediainfo_parameter("Video", "ScanOrder", CF_FILE_AbsolutePathName, "")
	V_Width								= vrdtvsp_get_mediainfo_parameter("Video", "Width", CF_FILE_AbsolutePathName, "")
	V_Height							= vrdtvsp_get_mediainfo_parameter("Video", "Height", CF_FILE_AbsolutePathName, "")
	V_BitRate							= vrdtvsp_get_mediainfo_parameter("Video", "BitRate", CF_FILE_AbsolutePathName, "")
	V_BitRate_Minimum					= vrdtvsp_get_mediainfo_parameter("Video", "BitRate_Minimum", CF_FILE_AbsolutePathName, "")
	V_BitRate_Maximum					= vrdtvsp_get_mediainfo_parameter("Video", "BitRate_Maximum", CF_FILE_AbsolutePathName, "")
	A_Codec_legacy						= vrdtvsp_get_mediainfo_parameter("Audio", "Codec", CF_FILE_AbsolutePathName, "--Legacy")
	A_CodecID_legacy					= vrdtvsp_get_mediainfo_parameter("Audio", "CodecID", CF_FILE_AbsolutePathName, "--Legacy") 
	A_Format_legacy						= vrdtvsp_get_mediainfo_parameter("Audio", "Format", CF_FILE_AbsolutePathName, "--Legacy") 
	A_Video_Delay_ms_legacy				= vrdtvsp_get_mediainfo_parameter("Audio", "Video_Delay", CF_FILE_AbsolutePathName, "--Legacy") 
	A_CodecID							= vrdtvsp_get_mediainfo_parameter("Audio", "CodecID", CF_FILE_AbsolutePathName, "")
	A_CodecID_String					= vrdtvsp_get_mediainfo_parameter("Audio", "CodecID/String", CF_FILE_AbsolutePathName, "")
	A_Video_Delay_ms					= vrdtvsp_get_mediainfo_parameter("Audio", "Video_Delay", CF_FILE_AbsolutePathName, "")
	Dim V_FrameRate
	Dim V_FrameRate_String
	Dim V_Frame_Rate_FF
	Dim V_Avg_Frame_Rate_FF
	V_FrameRate = vrdtvsp_get_mediainfo_parameter("Video", "FrameRate", CF_FILE_AbsolutePathName, "")
	V_FrameRate_String = vrdtvsp_get_mediainfo_parameter("Video", "FrameRate/String", CF_FILE_AbsolutePathName, "")
	' Obtain SOURCE media file characteristics via ffprobe 
	V_CodecID_FF						= vrdtvsp_get_ffprobe_video_stream_parameter("codec_name", CF_FILE_AbsolutePathName)  
	V_CodecID_String_FF					= vrdtvsp_get_ffprobe_video_stream_parameter("codec_tag_string", CF_FILE_AbsolutePathName)  
	V_Width_FF							= vrdtvsp_get_ffprobe_video_stream_parameter("width", CF_FILE_AbsolutePathName)  
	V_Height_FF							= vrdtvsp_get_ffprobe_video_stream_parameter("height", CF_FILE_AbsolutePathName)  
	V_Duration_s_FF						= vrdtvsp_get_ffprobe_video_stream_parameter("duration", CF_FILE_AbsolutePathName)  
	V_BitRate_FF						= vrdtvsp_get_ffprobe_video_stream_parameter("bit_rate", CF_FILE_AbsolutePathName)  
	V_BitRate_Maximum_FF				= vrdtvsp_get_ffprobe_video_stream_parameter("max_bit_rate", CF_FILE_AbsolutePathName)
	V_Frame_Rate_FF						= vrdtvsp_get_ffprobe_video_stream_parameter("r_frame_rate", CF_FILE_AbsolutePathName)
	V_Avg_Frame_Rate_FF					= vrdtvsp_get_ffprobe_video_stream_parameter("avg_frame_rate", CF_FILE_AbsolutePathName)
	' Fix up the mediainfo parameters retrieved
	V_FrameRate = ROUND(V_FrameRate)
	V_DisplayAspectRatio_String_slash	= Replace(V_DisplayAspectRatio_String,":","/",1,-1,vbTextCompare)  ' Replace(string,find,replacewith[,start[,count[,compare]]])
	'
	If Ucase(V_Codec_legacy) = Ucase("MPEG-2V") Then
		V_IsAVC = False
		V_IsMPEG2 = True
		vrdtvsp_extension = vrdtvsp_extension_mpeg2
		vrdtvsp_profile_name_for_qsf = vrdtvsp_profile_name_for_qsf_mpeg2
	ElseIf Ucase(V_Codec_legacy) = Ucase("AVC") Then
		V_IsAVC = True
		V_IsMPEG2 = False
		vrdtvsp_extension = vrdtvsp_extension_avc
		vrdtvsp_profile_name_for_qsf = vrdtvsp_profile_name_for_qsf_avc
	Else
		If vrdtvsp_DEBUG Then WScript.StdOut.WriteLine("VRDTVSP DEBUG: VRDTVSP ERROR vrdtvsp_Convert_File - Error - Unrecognised video codec """ & CF_FILE_AbsolutePathName & """ """ & V_Codec_legacy & """ ... Ignoring file ...")
		WScript.StdOut.WriteLine("VRDTVSP ERROR vrdtvsp_Convert_File - Error - Unrecognised video codec """ & CF_FILE_AbsolutePathName & """ """ & V_Codec_legacy & """ ... Ignoring file ...")
		If vrdtvsp_DEVELOPMENT_NO_ACTIONS Then ' DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV 
			Wscript.Echo "Error 17 = cannot perform the requested operation"
			On Error goto 0
			WScript.Quit 17 ' Error 17 = cannot perform the requested operation
		End If
		vrdtvsp_status = vrdtvsp_move_files_to_folder(CF_FILE_AbsolutePathName, CF_failed_conversion_TS_Folder)
		vrdtvsp_status = vrdtvsp_move_files_to_folder(CF_vprj_AbsolutePathName, CF_failed_conversion_TS_Folder)
		'vrdtvsp_status = vrdtvsp_delete_a_file(CF_DGI_AbsolutePathName, True)
		'vrdtvsp_status = vrdtvsp_delete_a_file(CF_VPY_AbsolutePathName, True)
		'vrdtvsp_status = vrdtvsp_delete_a_file(CF_QSF_AbsolutePathName, True)
		WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File: - ???????????????????? moved FAILED CONVERSION file to FAILED folder: """ & CF_FILE_AbsolutePathName & """ to """ & CF_failed_conversion_TS_Folder & """")
		WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File: - ???????????????????? moved FAILED CONVERSION file to FAILED folder: """ & CF_FILE_AbsolutePathName & """ to """ & CF_failed_conversion_TS_Folder & """")
		WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File: - ???????????????????? moved FAILED CONVERSION file to FAILED folder: """ & CF_FILE_AbsolutePathName & """ to """ & CF_failed_conversion_TS_Folder & """")
		WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File: - ???????????????????? moved FAILED CONVERSION file to FAILED folder: """ & CF_FILE_AbsolutePathName & """ to """ & CF_failed_conversion_TS_Folder & """")
		WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File: - ???????????????????? moved FAILED CONVERSION file to FAILED folder: """ & CF_FILE_AbsolutePathName & """ to """ & CF_failed_conversion_TS_Folder & """")
		WScript.StdOut.WriteLine(" ")
		WScript.StdOut.WriteLine("vrdtvsp_Convert_File FINISHED " & vrdtvsp_current_datetime_string())
		WScript.StdOut.WriteLine("" & vrdtvsp_current_datetime_string())
		WScript.StdOut.WriteLine("======================================================================================================================================================")
		WScript.StdOut.WriteLine(" ")
		vrdtvsp_Convert_File = -1
		Exit Function
	End If
	If A_Video_Delay_ms_legacy = "" Then
		A_Video_Delay_ms_legacy = 0
		A_Audio_Delay_ms_legacy = 0
	Else
		A_Audio_Delay_ms_legacy = 0 - A_Video_Delay_ms_legacy
	End If
	If A_Video_Delay_ms = "" Then
		A_Video_Delay_ms = 0
		A_Audio_Delay_ms = 0
	Else
		A_Audio_Delay_ms = 0 - A_Video_Delay_ms
	End If
	If V_ScanType = "" Then
		V_ScanType = "Progressive" ' Default to Progressive
	End If
	If V_ScanType = "MBAFF" Then
		V_ScanType = "Interlaced"
	End If
	If Ucase(V_ScanType) = Ucase("Interlaced") Then
		V_IsProgressive = False
		V_IsInterlaced = True
	ElseIf Ucase(V_ScanType) = Ucase("Progressive") Then
		V_IsProgressive = True
		V_IsInterlaced = False
	Else
		If vrdtvsp_DEBUG Then WScript.StdOut.WriteLine("VRDTVSP DEBUG: VRDTVSP ERROR vrdtvsp_Convert_File - Error - DO NOT KNOW IF SOURCE IS INTERLACED OR PROGRESSIVE """ & CF_FILE_AbsolutePathName & """ V_Codec_legacy=""" & V_Codec_legacy & """ V_ScanType=""" & V_ScanType & """ ... Ignoring file ...")
		WScript.StdOut.WriteLine("VRDTVSP ERROR vrdtvsp_Convert_File - Error - DO NOT KNOW IF SOURCE IS INTERLACED OR PROGRESSIVE """ & CF_FILE_AbsolutePathName & """ V_Codec_legacy=""" & V_Codec_legacy & """ V_ScanType=""" & V_ScanType & """ ... Ignoring file ...")
		If vrdtvsp_DEVELOPMENT_NO_ACTIONS Then ' DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV 
			Wscript.Echo "Error 17 = cannot perform the requested operation"
			On Error goto 0
			WScript.Quit 17 ' Error 17 = cannot perform the requested operation
		End If
		vrdtvsp_status = vrdtvsp_move_files_to_folder(CF_FILE_AbsolutePathName, CF_failed_conversion_TS_Folder)
		vrdtvsp_status = vrdtvsp_move_files_to_folder(CF_vprj_AbsolutePathName, CF_failed_conversion_TS_Folder)
		'vrdtvsp_status = vrdtvsp_delete_a_file(CF_DGI_AbsolutePathName, True)
		'vrdtvsp_status = vrdtvsp_delete_a_file(CF_VPY_AbsolutePathName, True)
		'vrdtvsp_status = vrdtvsp_delete_a_file(CF_QSF_AbsolutePathName, True)
		WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File: - ???????????????????? moved FAILED CONVERSION file to FAILED folder: """ & CF_FILE_AbsolutePathName & """ to """ & CF_failed_conversion_TS_Folder & """")
		WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File: - ???????????????????? moved FAILED CONVERSION file to FAILED folder: """ & CF_FILE_AbsolutePathName & """ to """ & CF_failed_conversion_TS_Folder & """")
		WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File: - ???????????????????? moved FAILED CONVERSION file to FAILED folder: """ & CF_FILE_AbsolutePathName & """ to """ & CF_failed_conversion_TS_Folder & """")
		WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File: - ???????????????????? moved FAILED CONVERSION file to FAILED folder: """ & CF_FILE_AbsolutePathName & """ to """ & CF_failed_conversion_TS_Folder & """")
		WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File: - ???????????????????? moved FAILED CONVERSION file to FAILED folder: """ & CF_FILE_AbsolutePathName & """ to """ & CF_failed_conversion_TS_Folder & """")
		WScript.StdOut.WriteLine(" ")
		WScript.StdOut.WriteLine("vrdtvsp_Convert_File FINISHED " & vrdtvsp_current_datetime_string())
		WScript.StdOut.WriteLine("" & vrdtvsp_current_datetime_string())
		WScript.StdOut.WriteLine("======================================================================================================================================================")
		WScript.StdOut.WriteLine(" ")
		vrdtvsp_Convert_File = -1
		Exit Function
	End If
	If V_ScanOrder = "" Then
		V_ScanOrder = "TFF" ' Default to Top Field First
	End If
	If vrdtvsp_DEBUG Then
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvsp_Convert_File adjusted SOURCE media characteristics below:") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvsp_Convert_File V_Codec_legacy=""" & V_Codec_legacy & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvsp_Convert_File V_Format_legacy=""" & V_Format_legacy & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvsp_Convert_File V_DisplayAspectRatio_String_slash=""" & V_DisplayAspectRatio_String_slash & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvsp_Convert_File V_PixelAspectRatio=""" & V_PixelAspectRatio & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvsp_Convert_File V_ScanType=""" & V_ScanType & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvsp_Convert_File V_ScanOrder=""" & V_ScanOrder & """")
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvsp_Convert_File V_IsProgressive=""" & V_IsProgressive & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvsp_Convert_File V_IsInterlaced=""" & V_IsInterlaced & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvsp_Convert_File V_Width=""" & V_Width & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvsp_Convert_File V_Height=""" & V_Height & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvsp_Convert_File V_BitRate=""" & V_BitRate & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvsp_Convert_File V_BitRate_Minimum=""" & V_BitRate_Minimum & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvsp_Convert_File V_BitRate_Maximum=""" & V_BitRate_Maximum & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvsp_Convert_File A_Codec_legacy=""" & A_Codec_legacy & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvsp_Convert_File A_CodecID_legacy=""" & A_CodecID_legacy & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvsp_Convert_File A_Format_legacy=""" & A_Format_legacy & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvsp_Convert_File A_Video_Delay_ms=""" & A_Video_Delay_ms & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvsp_Convert_File A_Video_Delay_ms_legacy=""" & A_Video_Delay_ms_legacy & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvsp_Convert_File A_Audio_Delay_ms=""" & A_Audio_Delay_ms & """")
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvsp_Convert_File A_Audio_Delay_ms_legacy=""" & A_Audio_Delay_ms_legacy & """")
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvsp_Convert_File A_CodecID=""" & A_CodecID & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvsp_Convert_File A_CodecID_String=""" & A_CodecID_String & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvsp_Convert_File V_CodecID_FF=""" & V_CodecID_FF & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvsp_Convert_File V_CodecID_String_FF=""" & V_CodecID_String_FF & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvsp_Convert_File V_Width_FF=""" & V_Width_FF & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvsp_Convert_File V_Height_FF=""" & V_Height_FF & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvsp_Convert_File V_Duration_s_FF=""" & V_Duration_s_FF & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvsp_Convert_File V_BitRate_FF=""" & V_BitRate_FF & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvsp_Convert_File V_BitRate_Maximum_FF=""" & V_BitRate_Maximum_FF & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvsp_Convert_File V_FrameRate=""" & V_FrameRate & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvsp_Convert_File V_FrameRate_String=""" & V_FrameRate_String & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvsp_Convert_File V_Frame_Rate_FF=""" & V_Frame_Rate_FF & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvsp_Convert_File V_Avg_Frame_Rate_FF=""" & V_Avg_Frame_Rate_FF & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvsp_Convert_File adjusted SOURCE media characteristics above") 
	End If
	WScript.StdOut.WriteLine("======================================================================================================================================================")
	WScript.StdOut.WriteLine("" & vrdtvsp_current_datetime_string())
	WScript.StdOut.WriteLine("End Examining of SOURCE """ & CF_FILE_AbsolutePathName & """")
	WScript.StdOut.WriteLine("SOURCE file: " & " V_FrameRate=" & V_FrameRate & " (V_Frame_Rate_FF=" & V_Frame_Rate_FF & ") V_Codec_legacy: """ & V_Codec_legacy & """ V_ScanType: """ & V_ScanType & """ V_ScanOrder: """ & V_ScanOrder & """ " & V_Width & "x" & V_Height & " dar=" & V_DisplayAspectRatio_String_slash & " sar=" & V_PixelAspectRatio & " A_Codec_legacy: " & A_Codec_legacy & " A_Audio_Delay_ms: " & A_Audio_Delay_ms & " A_Audio_Delay_ms_legacy: " & A_Audio_Delay_ms_legacy & " A_Video_Delay_ms: " &  A_Video_Delay_ms & " A_Video_Delay_ms_legacy: " &  A_Video_Delay_ms_legacy)
	WScript.StdOut.WriteLine("End Exmaining of SOURCE """ & CF_FILE_AbsolutePathName & """")
	WScript.StdOut.WriteLine("" & vrdtvsp_current_datetime_string())
	WScript.StdOut.WriteLine("======================================================================================================================================================")
	'
	' Now that we know the Video Codec and have determined that proper QSF File extension to use, set things up
	CF_TARGET_ParentFolderName = CF_destination_mp4_Folder
	CF_TARGET_BaseName = CF_FILE_BaseName
	CF_TARGET_Ext = "mp4"		' always .mp4
	CF_TARGET_AbsolutePathName = fso.GetAbsolutePathName(fso.BuildPath(CF_TARGET_ParentFolderName,CF_TARGET_BaseName & "." & CF_TARGET_Ext))
	'
	CF_vprj_ParentFolderName = CF_destination_mp4_Folder
	CF_vprj_BaseName = CF_TARGET_BaseName
	CF_vprj_Ext = "vprj"		' always .vprj
	CF_vprj_AbsolutePathName = fso.GetAbsolutePathName(fso.BuildPath(CF_vprj_ParentFolderName,CF_vprj_BaseName & "." & CF_vprj_Ext))
	'
	CF_QSF_ParentFolderName = CF_temp_path
	CF_QSF_BaseName = CF_FILE_BaseName & ".QSF"
	CF_QSF_Ext = vrdtvsp_extension ' set above based on incoming codec
	CF_QSF_AbsolutePathName = fso.GetAbsolutePathName(fso.BuildPath(CF_QSF_ParentFolderName,CF_QSF_BaseName & "." & CF_QSF_Ext))
	'
	CF_QSFxml_ParentFolderName = CF_temp_path
	CF_QSFxml_BaseName = CF_FILE_BaseName & ".QSF"
	CF_QSFxml_Ext = "xml"
	CF_QSFxml_AbsolutePathName = fso.GetAbsolutePathName(fso.BuildPath(CF_QSF_ParentFolderName,CF_QSF_BaseName & "." & CF_QSFxml_Ext))
	'
	CF_VPY_ParentFolderName = CF_temp_path
	CF_VPY_BaseName = CF_QSF_BaseName
	CF_VPY_Ext = "vpy"			' always .vpy
	CF_VPY_AbsolutePathName = fso.GetAbsolutePathName(fso.BuildPath(CF_VPY_ParentFolderName,CF_VPY_BaseName & "." & CF_VPY_Ext))
	'
	CF_DGI_ParentFolderName = CF_temp_path
	CF_DGI_BaseName = CF_QSF_BaseName
	CF_DGI_Ext = "dgi"			' always .dgi
	CF_DGI_AbsolutePathName = fso.GetAbsolutePathName(fso.BuildPath(CF_DGI_ParentFolderName,CF_DGI_BaseName & "." & CF_DGI_Ext))
	'
	CF_DGIlog_ParentFolderName = CF_temp_path
	CF_DGIlog_BaseName = CF_QSF_BaseName
	CF_DGIlog_Ext = "log"			' always .log
	CF_DGIlog_AbsolutePathName = fso.GetAbsolutePathName(fso.BuildPath(CF_DGI_ParentFolderName,CF_DGIlog_BaseName & "." & CF_DGIlog_Ext))
	'
	' START ======================================================  Do the QSF ... IF FLAGGED TO DO DO ======================================================
	' If doing a QSF, do it
	' If NOT doing a QSF, just copy the SOURCE  file (usually .ts), file over to the QSF file whilst retaining most of the QSF functionality
	' ++++ START Run the QSF command
	ff_timerStart = Timer
	vrdtvsp_status = vrdtvsp_delete_a_file(CF_QSF_AbsolutePathName, True) ' True=silently delete it
	vrdtvsp_status = vrdtvsp_delete_a_file(CF_QSFxml_AbsolutePathName, True) ' True=silently delete it
	vrdtvsp_status = vrdtvsp_delete_a_file(vrdtvsp_logfile_wildcard_QSF, True) ' True=silently delete it 	' is a wildcard, in fso.DeleteFile the filespec can contain wildcard characters in the last path component
	vrdtvsp_status = vrdtvsp_delete_a_file(vrdtvsp_logfile_wildcard_ADSCAN, True) ' True=silently delete it	' is a wildcard, in fso.DeleteFile the filespec can contain wildcard characters in the last path component
	' save QSF command	
	CF_object_saved_ffmpeg_commands.WriteLine("REM")
	CF_object_saved_ffmpeg_commands.WriteLine("REM ===============================================================================================================")
	CF_object_saved_ffmpeg_commands.WriteLine("REM SOURCE """ & CF_FILE_AbsolutePathName & """")
	CF_object_saved_ffmpeg_commands.WriteLine("REM ===============================================================================================================")
	CF_object_saved_ffmpeg_commands.WriteLine("REM  adjusted SOURCE media characteristics below:") 
	CF_object_saved_ffmpeg_commands.WriteLine("REM  V_Codec_legacy=""" & V_Codec_legacy & """") 
	CF_object_saved_ffmpeg_commands.WriteLine("REM  V_Format_legacy=""" & V_Format_legacy & """") 
	CF_object_saved_ffmpeg_commands.WriteLine("REM  V_DisplayAspectRatio_String=""" & V_DisplayAspectRatio_String & """") 
	CF_object_saved_ffmpeg_commands.WriteLine("REM  V_PixelAspectRatio=""" & V_PixelAspectRatio & """") 
	CF_object_saved_ffmpeg_commands.WriteLine("REM  V_ScanType=""" & V_ScanType & """") 
	CF_object_saved_ffmpeg_commands.WriteLine("REM  V_ScanOrder=""" & V_ScanOrder & """") 
	CF_object_saved_ffmpeg_commands.WriteLine("REM  V_IsProgressive=""" & V_IsProgressive & """") 
	CF_object_saved_ffmpeg_commands.WriteLine("REM  V_IsInterlaced=""" & V_IsInterlaced & """") 
	CF_object_saved_ffmpeg_commands.WriteLine("REM  V_Width=""" & V_Width & """") 
	CF_object_saved_ffmpeg_commands.WriteLine("REM  V_Height=""" & V_Height & """") 
	CF_object_saved_ffmpeg_commands.WriteLine("REM  V_BitRate=""" & V_BitRate & """") 
	CF_object_saved_ffmpeg_commands.WriteLine("REM  V_BitRate_Minimum=""" & V_BitRate_Minimum & """") 
	CF_object_saved_ffmpeg_commands.WriteLine("REM  V_BitRate_Maximum=""" & V_BitRate_Maximum & """") 
	CF_object_saved_ffmpeg_commands.WriteLine("REM  A_Codec_legacy=""" & A_Codec_legacy & """") 
	CF_object_saved_ffmpeg_commands.WriteLine("REM  A_CodecID_legacy=""" & A_CodecID_legacy & """") 
	CF_object_saved_ffmpeg_commands.WriteLine("REM  A_Format_legacy=""" & A_Format_legacy & """") 
	CF_object_saved_ffmpeg_commands.WriteLine("REM  A_Video_Delay_ms=""" & A_Video_Delay_ms & """") 
	CF_object_saved_ffmpeg_commands.WriteLine("REM  A_Video_Delay_ms_legacy=""" & A_Video_Delay_ms_legacy & """") 
	CF_object_saved_ffmpeg_commands.WriteLine("REM  A_Audio_Delay_ms=""" & A_Audio_Delay_ms & """")
	CF_object_saved_ffmpeg_commands.WriteLine("REM  A_Audio_Delay_ms_legacy=""" & A_Audio_Delay_ms_legacy & """")
	CF_object_saved_ffmpeg_commands.WriteLine("REM  A_CodecID=""" & A_CodecID & """") 
	CF_object_saved_ffmpeg_commands.WriteLine("REM  A_CodecID_String=""" & A_CodecID_String & """") 
	CF_object_saved_ffmpeg_commands.WriteLine("REM  V_CodecID_FF=""" & V_CodecID_FF & """") 
	CF_object_saved_ffmpeg_commands.WriteLine("REM  V_CodecID_String_FF=""" & V_CodecID_String_FF & """") 
	CF_object_saved_ffmpeg_commands.WriteLine("REM  V_Width_FF=""" & V_Width_FF & """") 
	CF_object_saved_ffmpeg_commands.WriteLine("REM  V_Height_FF=""" & V_Height_FF & """") 
	CF_object_saved_ffmpeg_commands.WriteLine("REM  V_Duration_s_FF=""" & V_Duration_s_FF & """") 
	CF_object_saved_ffmpeg_commands.WriteLine("REM  V_BitRate_FF=""" & V_BitRate_FF & """") 
	CF_object_saved_ffmpeg_commands.WriteLine("REM  V_BitRate_Maximum_FF=""" & V_BitRate_Maximum_FF & """") 
	CF_object_saved_ffmpeg_commands.WriteLine("REM  V_FrameRate=""" & V_FrameRate & """") 
	CF_object_saved_ffmpeg_commands.WriteLine("REM  V_FrameRate_String=""" & V_FrameRate_String & """") 
	CF_object_saved_ffmpeg_commands.WriteLine("REM  V_Frame_Rate_FF=""" & V_Frame_Rate_FF & """") 
	CF_object_saved_ffmpeg_commands.WriteLine("REM  V_Avg_Frame_Rate_FF=""" & V_Avg_Frame_Rate_FF & """") 
	CF_object_saved_ffmpeg_commands.WriteLine("REM  adjusted SOURCE media characteristics above") 
	CF_object_saved_ffmpeg_commands.WriteLine("REM")
	CF_object_saved_ffmpeg_commands.WriteLine("REM Do the QSF for """ & CF_FILE_AbsolutePathName & """ ... " & V_ScanType & " " & V_ScanOrder & " """ & V_Codec_legacy & """/""" & A_Codec_legacy & """")
	CF_object_saved_ffmpeg_commands.WriteLine("REM")
	'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	' Here is where we actually do the QSF
	' The OLD way:
	'	CF_exe_cmd_string = "cscript //Nologo """ & vrdtvsp_path_for_qsf_vbs & """ """ & CF_FILE_AbsolutePathName & """  """ & CF_QSF_AbsolutePathName & """ /qsf /p """ & vrdtvsp_profile_name_for_qsf & """ /q /na"
	' The NEW way:
	CF_exe_cmd_string = "cscript //Nologo """ & vrdtvsp_path_for_qsf_vbs & """ """ & CF_FILE_AbsolutePathName & """  """ & CF_QSF_AbsolutePathName & """  """ & vrdtvsp_profile_name_for_qsf & """ """ & CF_QSFxml_AbsolutePathName & """"
		' Args(0) is input video file path - a fully qualified path name
		' Args(1) is path/name of output QSF'd file - a fully qualified path name
		' Args(2) is name of QSF Output Profile created in VRD v6
		' Args(3) is path/name of a file of XML associated with the output QSF'd file - a fully qualified path name
	'
	If vrdtvsp_DEBUG Then 
		WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_Convert_File """ & CF_FILE_AbsolutePathName & """ V_Codec_legacy=""" & V_Codec_legacy & """ do QSF with CF_exe_cmd_string=""" & CF_exe_cmd_string & """")
	End If
	' do the actual QSF command (delete the QSF file first)
	WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File: Doing QSF for """ & CF_FILE_AbsolutePathName & """ ... " & V_ScanType & " " & V_ScanOrder & " """ & V_Codec_legacy & """/""" & A_Codec_legacy & """")
	WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File: QSF command: " & CF_exe_cmd_string)
	CF_object_saved_ffmpeg_commands.WriteLine("DEL /F """ & CF_QSFxml_AbsolutePathName & """")
	CF_object_saved_ffmpeg_commands.WriteLine("DEL /F """ & CF_QSF_AbsolutePathName & """")
	CF_object_saved_ffmpeg_commands.WriteLine("REM ====================================================================================================================================================================")
	CF_object_saved_ffmpeg_commands.WriteLine("ECHO !DATE! !TIME!")
	CF_object_saved_ffmpeg_commands.WriteLine(CF_exe_cmd_string) ' write the QSF String to be executed, only if we're doing a QSF
	CF_object_saved_ffmpeg_commands.WriteLine("ECHO !DATE! !TIME!")
	CF_object_saved_ffmpeg_commands.WriteLine("TYPE """ & CF_QSFxml_AbsolutePathName & """")
	CF_object_saved_ffmpeg_commands.WriteLine("REM ====================================================================================================================================================================")
	'
	WScript.StdOut.WriteLine("======================================================================================================================================================")
	WScript.StdOut.WriteLine("" & vrdtvsp_current_datetime_string())
	vrdtvsp_status = vrdtvsp_delete_a_file(CF_QSF_AbsolutePathName, True) ' True=silently delete it
	' the OLD way:
	'	 CF_exe_status = vrdtvsp_exec_a_command_and_show_stdout_stderr(CF_exe_cmd_string) ????? do the QSF in the DOS batch file like adscan
	' the NEW way:
	'ReDim vrdtvsp_Exec_in_a_DOS_BAT_file_cmd_array(4) ' base 0, so the dimension is always 1 less than the number of commands
	'vrdtvsp_Exec_in_a_DOS_BAT_file_cmd_array(0) = "DEL /F """ & CF_QSFxml_AbsolutePathName & """"
	'vrdtvsp_Exec_in_a_DOS_BAT_file_cmd_array(1) = "DEL /F """ & CF_QSF_AbsolutePathName & """"
	'vrdtvsp_Exec_in_a_DOS_BAT_file_cmd_array(2) = CF_exe_cmd_string ' for the final return status to be good, this must be the final command in the array
	''vrdtvsp_Exec_in_a_DOS_BAT_file_cmd_array(3) = "REM ECHO TYPE """ & CF_QSFxml_AbsolutePathName & """"	' DO NOT DO THIS - the errorlevel returned ins based on the LAST command run
	''vrdtvsp_Exec_in_a_DOS_BAT_file_cmd_array(4) = "REM TYPE """ & CF_QSFxml_AbsolutePathName & """"		' DO NOT DO THIS - the errorlevel returned ins based on the LAST command run
	'CF_exe_status = vrdtvsp_Exec_in_a_DOS_BAT_file(vrdtvsp_Exec_in_a_DOS_BAT_file_cmd_array, True, True) ' print .bat, do the commands, print .log - the safer way of doing it
	'Erase vrdtvsp_Exec_in_a_DOS_BAT_file_cmd_array
	'WScript.StdOut.WriteLine(vrdtvsp_current_datetime_string() & " ====================================================================================================================================================================")
	'WScript.StdOut.WriteLine(vrdtvsp_current_datetime_string() & " ====================================================================================================================================================================")
	' 2021.02.25 the NEWER way, which returns a Dict object with these keys:
	'	"outputFile" string ... eg value retrieved like: v = xmlDict.Item("outputFile")
	'	"OutputType" string
	'	"OutputDurationSecs" long integer
	'	"OutputDuration" hh:mm:ss
	'	"OutputSizeMB" long integer
	'	"OutputSceneCount" long integer
	'	"VideoOutputFrameCount" long integer
	'	"AudioOutputFrameCount" long integer
	'	"ActualVideoBitrate" long integer ... eg value retrieved like: v = xmlDict.Item("ActualVideoBitrate")
	Set xmlDict = vrdtvsp_run_inlineQSF_only_with_vrd_5_and_6 (vrd_version_for_qsf, CF_FILE_AbsolutePathName, CF_QSF_AbsolutePathName, vrdtvsp_profile_name_for_qsf)
	If xmlDict is Nothing Then
		' eek, did not QSF properly 
		' ... if was v6 QSF, try a v5 QSF, then if that also fails then try to exit in such a way that the source file is moved to "failed" folder and the process continues with other files
		If vrd_version_for_qsf = 6 Then ' retry with QSFv5, so use v5 equivalent v5 PROFILE name
			If V_IsMPEG2 Then
				fallback_vrdtvsp_profile_name_for_qsfv5 = const_vrd5_profile_mpeg2
			ElseIf V_IsAVC Then
				fallback_vrdtvsp_profile_name_for_qsfv5 = const_vrd5_profile_avc
			Else
				WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File: - ???????????????????? CODEC NOT DETERMINED FOR FALBACK QSF : """ & CF_FILE_AbsolutePathName & """ - was v6 """ & vrdtvsp_profile_name_for_qsf & """")
				Wscript.Echo "Error 17 = cannot perform the requested operation"
				On Error goto 0
				WScript.Quit 17 ' Error 17 = cannot perform the requested operation
			End If
			Set xmlDict = vrdtvsp_run_inlineQSF_only_with_vrd_5_and_6 (5, CF_FILE_AbsolutePathName, CF_QSF_AbsolutePathName, fallback_vrdtvsp_profile_name_for_qsfv5) ' fallback to try a v5 QSF
		End If
		If xmlDict is Nothing Then	' it must have failed QSF in both version 5 and version 6
			WScript.StdOut.WriteLine("VRDTVSP ERROR vrdtvsp_Convert_File - Error - Failed to QSF after re-trying with v5 QSF """ & CF_FILE_AbsolutePathName & """ V_Codec_legacy=""" & V_Codec_legacy & """ CF_exe_cmd_string=""" & CF_exe_cmd_string & """")
			vrdtvsp_status = vrdtvsp_move_files_to_folder(CF_FILE_AbsolutePathName, CF_failed_conversion_TS_Folder)
			vrdtvsp_status = vrdtvsp_move_files_to_folder(CF_vprj_AbsolutePathName, CF_failed_conversion_TS_Folder)
			'vrdtvsp_status = vrdtvsp_delete_a_file(CF_DGI_AbsolutePathName, True)
			'vrdtvsp_status = vrdtvsp_delete_a_file(CF_VPY_AbsolutePathName, True)
			'vrdtvsp_status = vrdtvsp_delete_a_file(CF_QSF_AbsolutePathName, True)
			WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File: - ???????????????????? moved FAILED CONVERSION file to FAILED folder: """ & CF_FILE_AbsolutePathName & """ to """ & CF_failed_conversion_TS_Folder & """")
			WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File: - ???????????????????? moved FAILED CONVERSION file to FAILED folder: """ & CF_FILE_AbsolutePathName & """ to """ & CF_failed_conversion_TS_Folder & """")
			WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File: - ???????????????????? moved FAILED CONVERSION file to FAILED folder: """ & CF_FILE_AbsolutePathName & """ to """ & CF_failed_conversion_TS_Folder & """")
			WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File: - ???????????????????? moved FAILED CONVERSION file to FAILED folder: """ & CF_FILE_AbsolutePathName & """ to """ & CF_failed_conversion_TS_Folder & """")
			WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File: - ???????????????????? moved FAILED CONVERSION file to FAILED folder: """ & CF_FILE_AbsolutePathName & """ to """ & CF_failed_conversion_TS_Folder & """")
			WScript.StdOut.WriteLine(" ")
			WScript.StdOut.WriteLine("vrdtvsp_Convert_File FINISHED " & vrdtvsp_current_datetime_string())
			WScript.StdOut.WriteLine("" & vrdtvsp_current_datetime_string())
			WScript.StdOut.WriteLine("======================================================================================================================================================")
			WScript.StdOut.WriteLine(" ")
			vrdtvsp_Convert_File = -1 ' just exit and hope the source file is moved to "failed" folder and the process continues with other files
			Exit Function
		End If
	End If
	For Each xmlDict_key In xmlDict
		wscript.echo "vrdtvsp_Convert_File: VRD QSF returned XML data: xmlDict_key=""" & xmlDict_key & """ xmlDict_value= """ & xmlDict.Item(xmlDict_key) & """"
	Next
	'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	'
	' no longer testing for exe status because it's now inline ............
	'
	'If CF_exe_status <> 0 OR NOT fso.FileExists(CF_QSF_AbsolutePathName) Then
	If NOT fso.FileExists(CF_QSF_AbsolutePathName) Then
		If vrdtvsp_DEBUG Then WScript.StdOut.WriteLine("VRDTVSP DEBUG: ERROR vrdtvsp_Convert_File - Error - Failed to QSF, no QSF file produced """ & CF_FILE_AbsolutePathName & """ V_Codec_legacy=""" & V_Codec_legacy & """ CF_exe_cmd_string=""" & CF_exe_cmd_string & """")
		WScript.StdOut.WriteLine("VRDTVSP ERROR vrdtvsp_Convert_File - Error - Failed to QSF, no QSF file produced """ & CF_FILE_AbsolutePathName & """ V_Codec_legacy=""" & V_Codec_legacy & """ CF_exe_cmd_string=""" & CF_exe_cmd_string & """")
		If vrdtvsp_DEVELOPMENT_NO_ACTIONS Then ' DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV 
			Wscript.Echo "Error 17 = cannot perform the requested operation"
			On Error goto 0
			WScript.Quit 17 ' Error 17 = cannot perform the requested operation
		End If
		vrdtvsp_status = vrdtvsp_move_files_to_folder(CF_FILE_AbsolutePathName, CF_failed_conversion_TS_Folder)
		vrdtvsp_status = vrdtvsp_move_files_to_folder(CF_vprj_AbsolutePathName, CF_failed_conversion_TS_Folder)
		WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File: - ???????????????????? moved FAILED CONVERSION file to FAILED folder: """ & CF_FILE_AbsolutePathName & """ to """ & CF_failed_conversion_TS_Folder & """")
		WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File: - ???????????????????? moved FAILED CONVERSION file to FAILED folder: """ & CF_FILE_AbsolutePathName & """ to """ & CF_failed_conversion_TS_Folder & """")
		WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File: - ???????????????????? moved FAILED CONVERSION file to FAILED folder: """ & CF_FILE_AbsolutePathName & """ to """ & CF_failed_conversion_TS_Folder & """")
		WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File: - ???????????????????? moved FAILED CONVERSION file to FAILED folder: """ & CF_FILE_AbsolutePathName & """ to """ & CF_failed_conversion_TS_Folder & """")
		WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File: - ???????????????????? moved FAILED CONVERSION file to FAILED folder: """ & CF_FILE_AbsolutePathName & """ to """ & CF_failed_conversion_TS_Folder & """")
		WScript.StdOut.WriteLine(" ")
		WScript.StdOut.WriteLine("vrdtvsp_Convert_File FINISHED " & vrdtvsp_current_datetime_string())
		WScript.StdOut.WriteLine("" & vrdtvsp_current_datetime_string())
		WScript.StdOut.WriteLine("======================================================================================================================================================")
		WScript.StdOut.WriteLine(" ")
		vrdtvsp_Convert_File = -1 ' just exit and hope the source file is moved to "failed" folder and the process continues with other files
		Exit Function
	End If
	'
	ff_timerEnd = Timer
	WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File: - QSF command completed with Elapsed Time " & vrdtvsp_Calculate_ElapsedTime_string(ff_timerStart, ff_timerEnd))
	' ++++ END Run the QSF command
	'
	' ++++ START do a mediainfo of the SOURCE so we can compare them !!!
	If vrdtvsp_DEBUG OR vrdtvsp_show_mediainfo Then
		WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File ---------- doing mediainfo on SOURCE """ & CF_FILE_AbsolutePathName & """ V_Codec_legacy=""" & V_Codec_legacy & """ ----------")
		vrdtvsp_REM = ""
	Else
		vrdtvsp_REM = "REM "
	End If
	ReDim vrdtvsp_Exec_in_a_DOS_BAT_file_cmd_array(3) ' base 0, so the dimension is always 1 less than the number of commands
	vrdtvsp_Exec_in_a_DOS_BAT_file_cmd_array(0) = "REM " & vrdtvsp_current_datetime_string()
	vrdtvsp_Exec_in_a_DOS_BAT_file_cmd_array(1) = "ECHO !DATE! !TIME!"
	vrdtvsp_Exec_in_a_DOS_BAT_file_cmd_array(2) = vrdtvsp_REM & """" & vrdtvsp_mediainfoexe64 & """ --Legacy """ & CF_FILE_AbsolutePathName & """"
	vrdtvsp_Exec_in_a_DOS_BAT_file_cmd_array(3) = vrdtvsp_REM & """" & vrdtvsp_mediainfoexe64 & """ --Legacy ""--Inform=Video;%FrameRate%\r\n"" """ & CF_FILE_AbsolutePathName & """"
	vrdtvsp_Exec_in_a_DOS_BAT_file_cmd_array(3) = Replace(vrdtvsp_Exec_in_a_DOS_BAT_file_cmd_array(3), "%", "%%", 1, -1, vbTextCompare) ' just for the mediainfo command run from WITHIN in a .BAT file ' for the final return status to be good, this must be the final command in the array
	CF_object_saved_ffmpeg_commands.WriteLine("REM")
	for iii=0 to 3
		CF_object_saved_ffmpeg_commands.WriteLine(vrdtvsp_Exec_in_a_DOS_BAT_file_cmd_array(iii))
	Next
	CF_object_saved_ffmpeg_commands.WriteLine("REM")
	If vrdtvsp_DEBUG OR vrdtvsp_show_mediainfo Then
		CF_exe_status = vrdtvsp_Exec_in_a_DOS_BAT_file(vrdtvsp_Exec_in_a_DOS_BAT_file_cmd_array, True, True) ' print .bat, do the commands, print .log
	End If
	Erase vrdtvsp_Exec_in_a_DOS_BAT_file_cmd_array
	' ++++ END do a mediainfo of the SOURCE so we can compare them !!!
	' ++++ START do a mediainfo of the QSF so we can compare them !!!
	If vrdtvsp_DEBUG OR vrdtvsp_show_mediainfo Then
		WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File ---------- doing mediainfo on QSF """ & CF_QSF_AbsolutePathName & """ Q_V_Codec_legacy=""" & Q_V_Codec_legacy & """ ----------")
		vrdtvsp_REM = ""
	Else
		vrdtvsp_REM = "REM "
	End If
	ReDim vrdtvsp_Exec_in_a_DOS_BAT_file_cmd_array(3) ' base 0, so the dimension is always 1 less than the number of commands
	vrdtvsp_Exec_in_a_DOS_BAT_file_cmd_array(0) = "REM " & vrdtvsp_current_datetime_string()
	vrdtvsp_Exec_in_a_DOS_BAT_file_cmd_array(1) = "ECHO !DATE! !TIME!"
	vrdtvsp_Exec_in_a_DOS_BAT_file_cmd_array(2) = vrdtvsp_REM & """" & vrdtvsp_mediainfoexe64 & """ --Legacy """ & CF_QSF_AbsolutePathName & """"
	vrdtvsp_Exec_in_a_DOS_BAT_file_cmd_array(3) = vrdtvsp_REM & """" & vrdtvsp_mediainfoexe64 & """ --Legacy ""--Inform=Video;%FrameRate%\r\n"" """ & CF_QSF_AbsolutePathName & """"
	vrdtvsp_Exec_in_a_DOS_BAT_file_cmd_array(3) = Replace(vrdtvsp_Exec_in_a_DOS_BAT_file_cmd_array(3), "%", "%%", 1, -1, vbTextCompare) ' just for the mediainfo command run from WITHIN in a .BAT file ' for the final return status to be good, this must be the final command in the array
	CF_object_saved_ffmpeg_commands.WriteLine("REM")
	for iii=0 to 3
		CF_object_saved_ffmpeg_commands.WriteLine(vrdtvsp_Exec_in_a_DOS_BAT_file_cmd_array(iii))
	Next
	CF_object_saved_ffmpeg_commands.WriteLine("REM")
	If vrdtvsp_DEBUG OR vrdtvsp_show_mediainfo Then
		CF_exe_status = vrdtvsp_Exec_in_a_DOS_BAT_file(vrdtvsp_Exec_in_a_DOS_BAT_file_cmd_array, True, True) ' print .bat, do the commands, print .log
	End If
	Erase vrdtvsp_Exec_in_a_DOS_BAT_file_cmd_array
	' ++++ END do a mediainfo of the QSF so we can compare them !!! (DGIndex got the FPS wrong)
	' End ======================================================  Do the QSF ======================================================
	'
	' PROCESS the bitrate value from the QSF returned XML
	'
	If IsNumeric(xmlDict.Item("ActualVideoBitrate")) Then
		Q_ACTUAL_QSF_XML_BITRATE = xmlDict.Item("ActualVideoBitrate")
	Else
		Q_ACTUAL_QSF_XML_BITRATE = V_BitRate ' BAD qsf VALUE found (use the mediainfo value)
	End If
	'
	' Obtain QSF file characteristics via mediainfo 
	Q_V_Codec_legacy					= vrdtvsp_get_mediainfo_parameter("Video", "Codec", CF_QSF_AbsolutePathName, "--Legacy") 
	Q_V_Format_legacy					= vrdtvsp_get_mediainfo_parameter("Video", "Format", CF_QSF_AbsolutePathName, "--Legacy") 
	Q_V_DisplayAspectRatio_String		= vrdtvsp_get_mediainfo_parameter("Video", "DisplayAspectRatio/String", CF_QSF_AbsolutePathName, "")
	Q_V_PixelAspectRatio				= vrdtvsp_get_mediainfo_parameter("Video", "PixelAspectRatio", CF_QSF_AbsolutePathName, "")
	Q_V_ScanType						= vrdtvsp_get_mediainfo_parameter("Video", "ScanType", CF_QSF_AbsolutePathName, "")
	Q_V_ScanOrder 						= vrdtvsp_get_mediainfo_parameter("Video", "ScanOrder", CF_QSF_AbsolutePathName, "")
	Q_V_Width							= vrdtvsp_get_mediainfo_parameter("Video", "Width", CF_QSF_AbsolutePathName, "")
	Q_V_Height							= vrdtvsp_get_mediainfo_parameter("Video", "Height", CF_QSF_AbsolutePathName, "")
	Q_V_BitRate							= vrdtvsp_get_mediainfo_parameter("Video", "BitRate", CF_QSF_AbsolutePathName, "")
	Q_V_BitRate_Minimum					= vrdtvsp_get_mediainfo_parameter("Video", "BitRate_Minimum", CF_QSF_AbsolutePathName, "")
	Q_V_BitRate_Maximum					= vrdtvsp_get_mediainfo_parameter("Video", "BitRate_Maximum", CF_QSF_AbsolutePathName, "")
	Q_A_Codec_legacy					= vrdtvsp_get_mediainfo_parameter("Audio", "Codec", CF_QSF_AbsolutePathName, "--Legacy")
	Q_A_CodecID_legacy					= vrdtvsp_get_mediainfo_parameter("Audio", "CodecID", CF_QSF_AbsolutePathName, "--Legacy") 
	Q_A_Format_legacy					= vrdtvsp_get_mediainfo_parameter("Audio", "Format", CF_QSF_AbsolutePathName, "--Legacy") 
	Q_A_Video_Delay_ms_legacy			= vrdtvsp_get_mediainfo_parameter("Audio", "Video_Delay", CF_QSF_AbsolutePathName, "--Legacy") 
	Q_A_CodecID							= vrdtvsp_get_mediainfo_parameter("Audio", "CodecID", CF_QSF_AbsolutePathName, "")
	Q_A_CodecID_String					= vrdtvsp_get_mediainfo_parameter("Audio", "CodecID/String", CF_QSF_AbsolutePathName, "")
	Q_A_Video_Delay_ms					= vrdtvsp_get_mediainfo_parameter("Audio", "Video_Delay", CF_QSF_AbsolutePathName, "")
	Q_V_FrameRate						= vrdtvsp_get_mediainfo_parameter("Video", "FrameRate", CF_QSF_AbsolutePathName, "")
	Q_V_FrameRate_String				= vrdtvsp_get_mediainfo_parameter("Video", "FrameRate/String", CF_QSF_AbsolutePathName, "")
	' Obtain QSF file characteristics via ffprobe 
	Q_V_CodecID_FF						= vrdtvsp_get_ffprobe_video_stream_parameter("codec_name", CF_QSF_AbsolutePathName)  
	Q_V_CodecID_String_FF				= vrdtvsp_get_ffprobe_video_stream_parameter("codec_tag_string", CF_QSF_AbsolutePathName)  
	Q_V_Width_FF						= vrdtvsp_get_ffprobe_video_stream_parameter("width", CF_QSF_AbsolutePathName)  
	Q_V_Height_FF						= vrdtvsp_get_ffprobe_video_stream_parameter("height", CF_QSF_AbsolutePathName)  
	Q_V_Duration_s_FF					= vrdtvsp_get_ffprobe_video_stream_parameter("duration", CF_QSF_AbsolutePathName)  
	Q_V_BitRate_FF						= vrdtvsp_get_ffprobe_video_stream_parameter("bit_rate", CF_QSF_AbsolutePathName)  
	Q_V_BitRate_Maximum_FF				= vrdtvsp_get_ffprobe_video_stream_parameter("max_bit_rate", CF_QSF_AbsolutePathName)
	Q_V_Frame_Rate_FF					= vrdtvsp_get_ffprobe_video_stream_parameter("r_frame_rate", CF_QSF_AbsolutePathName)
	Q_V_Avg_Frame_Rate_FF				= vrdtvsp_get_ffprobe_video_stream_parameter("avg_frame_rate", CF_QSF_AbsolutePathName)
	' Fix up the QSF mediainfo parameters retrieved
	Q_V_FrameRate = ROUND(Q_V_FrameRate)
	Q_V_DisplayAspectRatio_String_slash	= Replace(Q_V_DisplayAspectRatio_String,":","/",1,-1,vbTextCompare)  ' Replace(string,find,replacewith[,start[,count[,compare]]])
	'
	If Ucase(Q_V_Codec_legacy) = Ucase("MPEG-2V") Then
		Q_V_IsAVC = False
		Q_V_IsMPEG2 = True
		'vrdtvsp_extension = vrdtvsp_extension_mpeg2
		'vrdtvsp_profile_name_for_qsf = vrdtvsp_profile_name_for_qsf_mpeg2
	ElseIf Ucase(Q_V_Codec_legacy) = Ucase("AVC") Then
		Q_V_IsAVC = True
		Q_V_IsMPEG2 = False
		'vrdtvsp_extension = vrdtvsp_extension_avc
		'vrdtvsp_profile_name_for_qsf = vrdtvsp_profile_name_for_qsf_avc
	Else
		If vrdtvsp_DEBUG Then WScript.StdOut.WriteLine("VRDTVSP DEBUG: VRDTVSP ERROR vrdtvsp_Convert_File - Error - Unrecognised Q_V_Codec_legacy video codec """ & CF_QSF_AbsolutePathName & """ Q_V_Codec_legacy=""" & Q_V_Codec_legacy & """ ... Ignoring file ...")
		WScript.StdOut.WriteLine("VRDTVSP ERROR vrdtvsp_Convert_File - Error - Unrecognised Q_V_Codec_legacy video codec """ & CF_QSF_AbsolutePathName & """ Q_V_Codec_legacy=""" & Q_V_Codec_legacy & """ ... Ignoring file ...")
		If vrdtvsp_DEVELOPMENT_NO_ACTIONS Then ' DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV 
			Wscript.Echo "Error 17 = cannot perform the requested operation"
			On Error goto 0
			WScript.Quit 17 ' Error 17 = cannot perform the requested operation
		End If
		WScript.StdOut.WriteLine("VRDTVSP ERROR vrdtvsp_Convert_File - Error - Failed to QSF Unrecognised Q_V_Codec_legacy video codec """ & CF_FILE_AbsolutePathName & """ V_Codec_legacy=""" & V_Codec_legacy & """ CF_exe_cmd_string=""" & CF_exe_cmd_string & """")
		vrdtvsp_status = vrdtvsp_move_files_to_folder(CF_FILE_AbsolutePathName, CF_failed_conversion_TS_Folder)
		vrdtvsp_status = vrdtvsp_move_files_to_folder(CF_vprj_AbsolutePathName, CF_failed_conversion_TS_Folder)
		'vrdtvsp_status = vrdtvsp_delete_a_file(CF_DGI_AbsolutePathName, True)
		'vrdtvsp_status = vrdtvsp_delete_a_file(CF_VPY_AbsolutePathName, True)
		'vrdtvsp_status = vrdtvsp_delete_a_file(CF_QSF_AbsolutePathName, True)
		WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File: - ???????????????????? moved FAILED CONVERSION file to FAILED folder: """ & CF_FILE_AbsolutePathName & """ to """ & CF_failed_conversion_TS_Folder & """")
		WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File: - ???????????????????? moved FAILED CONVERSION file to FAILED folder: """ & CF_FILE_AbsolutePathName & """ to """ & CF_failed_conversion_TS_Folder & """")
		WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File: - ???????????????????? moved FAILED CONVERSION file to FAILED folder: """ & CF_FILE_AbsolutePathName & """ to """ & CF_failed_conversion_TS_Folder & """")
		WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File: - ???????????????????? moved FAILED CONVERSION file to FAILED folder: """ & CF_FILE_AbsolutePathName & """ to """ & CF_failed_conversion_TS_Folder & """")
		WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File: - ???????????????????? moved FAILED CONVERSION file to FAILED folder: """ & CF_FILE_AbsolutePathName & """ to """ & CF_failed_conversion_TS_Folder & """")
		WScript.StdOut.WriteLine(" ")
		WScript.StdOut.WriteLine("vrdtvsp_Convert_File FINISHED " & vrdtvsp_current_datetime_string())
		WScript.StdOut.WriteLine("" & vrdtvsp_current_datetime_string())
		WScript.StdOut.WriteLine("======================================================================================================================================================")
		WScript.StdOut.WriteLine(" ")
		vrdtvsp_Convert_File = -1 ' just exit and hope the source file is moved to "failed" folder and the process continues with other files
		Exit Function
	End If
	If Q_A_Video_Delay_ms_legacy = "" Then
		Q_A_Video_Delay_ms_legacy = 0
		Q_A_Audio_Delay_ms_legacy = 0
	Else
		Q_A_Audio_Delay_ms_legacy = 0 - Q_A_Video_Delay_ms_legacy
	End If
	If Q_A_Video_Delay_ms = "" Then
		Q_A_Video_Delay_ms = 0
		Q_A_Audio_Delay_ms = 0
	Else
		Q_A_Audio_Delay_ms = 0 - Q_A_Video_Delay_ms
	End If
	If Q_V_ScanType = "" Then
		Q_V_ScanType = "Progressive" ' Default to Progressive
	End If
	If Q_V_ScanType = "MBAFF" Then
		Q_V_ScanType = "Interlaced"
	End If
	If Ucase(Q_V_ScanType) = Ucase("Interlaced") Then
		Q_V_IsProgressive = False
		Q_V_IsInterlaced = True
	ElseIf Ucase(Q_V_ScanType) = Ucase("Progressive") Then
		Q_V_IsProgressive = True
		Q_V_IsInterlaced = False
	Else
		If vrdtvsp_DEBUG Then WScript.StdOut.WriteLine("VRDTVSP DEBUG: VRDTVSP ERROR vrdtvsp_Convert_File - Error - DO NOT KNOW IF QSF IS INTERLACED OR PROGRESSIVE """ & CF_QSF_AbsolutePathName & """ Q_V_Codec_legacy=""" & Q_V_Codec_legacy & """ V_ScanType=""" & Q_V_ScanType & """ ... Ignoring file ...")
		WScript.StdOut.WriteLine("VRDTVSP ERROR vrdtvsp_Convert_File - Error - DO NOT KNOW IF QSF IS INTERLACED OR PROGRESSIVE """ & CF_QSF_AbsolutePathName & """ Q_V_Codec_legacy=""" & Q_V_Codec_legacy & """ Q_V_ScanType=""" & Q_V_ScanType & """ ... Ignoring file ...")
		If vrdtvsp_DEVELOPMENT_NO_ACTIONS Then ' DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV 
			Wscript.Echo "Error 17 = cannot perform the requested operation"
			On Error goto 0
			WScript.Quit 17 ' Error 17 = cannot perform the requested operation
		End If
		vrdtvsp_status = vrdtvsp_move_files_to_folder(CF_FILE_AbsolutePathName, CF_failed_conversion_TS_Folder)
		vrdtvsp_status = vrdtvsp_move_files_to_folder(CF_vprj_AbsolutePathName, CF_failed_conversion_TS_Folder)
		'vrdtvsp_status = vrdtvsp_delete_a_file(CF_DGI_AbsolutePathName, True)
		'vrdtvsp_status = vrdtvsp_delete_a_file(CF_VPY_AbsolutePathName, True)
		'vrdtvsp_status = vrdtvsp_delete_a_file(CF_QSF_AbsolutePathName, True)
		WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File: - ???????????????????? moved FAILED CONVERSION file to FAILED folder: """ & CF_FILE_AbsolutePathName & """ to """ & CF_failed_conversion_TS_Folder & """")
		WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File: - ???????????????????? moved FAILED CONVERSION file to FAILED folder: """ & CF_FILE_AbsolutePathName & """ to """ & CF_failed_conversion_TS_Folder & """")
		WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File: - ???????????????????? moved FAILED CONVERSION file to FAILED folder: """ & CF_FILE_AbsolutePathName & """ to """ & CF_failed_conversion_TS_Folder & """")
		WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File: - ???????????????????? moved FAILED CONVERSION file to FAILED folder: """ & CF_FILE_AbsolutePathName & """ to """ & CF_failed_conversion_TS_Folder & """")
		WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File: - ???????????????????? moved FAILED CONVERSION file to FAILED folder: """ & CF_FILE_AbsolutePathName & """ to """ & CF_failed_conversion_TS_Folder & """")
		WScript.StdOut.WriteLine(" ")
		WScript.StdOut.WriteLine("vrdtvsp_Convert_File FINISHED " & vrdtvsp_current_datetime_string())
		WScript.StdOut.WriteLine("" & vrdtvsp_current_datetime_string())
		WScript.StdOut.WriteLine("======================================================================================================================================================")
		WScript.StdOut.WriteLine(" ")
		vrdtvsp_Convert_File = -1 ' just exit and hope the source file is moved to "failed" folder and the process continues with other files
		Exit Function
	End If
	If Q_V_ScanOrder = "" Then
		Q_V_ScanOrder = "TFF" ' Default to Top Field First
	End If
	If (V_IsProgressive <> Q_V_IsProgressive) OR (V_IsInterlaced <> Q_V_IsInterlaced) Then
		If vrdtvsp_DEBUG Then WScript.StdOut.WriteLine("VRDTVSP DEBUG: VRDTVSP ERROR vrdtvsp_Convert_File - Error - UNEQUAL SOURCE AND QSF INTERLACED/PROGRESSIVE V_ScanType=""" & V_ScanType & """ Q_V_ScanType=""" & Q_V_ScanType &  """ ... Ignoring file ...")
		WScript.StdOut.WriteLine("VRDTVSP ERROR vrdtvsp_Convert_File - Error - UNEQUAL SOURCE AND QSF INTERLACED/PROGRESSIVE V_ScanType=""" & V_ScanType & """ Q_V_ScanType=""" & Q_V_ScanType & """ ... Ignoring file ...")
		If vrdtvsp_DEVELOPMENT_NO_ACTIONS Then ' DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV 
			Wscript.Echo "Error 17 = cannot perform the requested operation"
			On Error goto 0
			WScript.Quit 17 ' Error 17 = cannot perform the requested operation
		End If
		vrdtvsp_status = vrdtvsp_move_files_to_folder(CF_FILE_AbsolutePathName, CF_failed_conversion_TS_Folder)
		vrdtvsp_status = vrdtvsp_move_files_to_folder(CF_vprj_AbsolutePathName, CF_failed_conversion_TS_Folder)
		'vrdtvsp_status = vrdtvsp_delete_a_file(CF_DGI_AbsolutePathName, True)
		'vrdtvsp_status = vrdtvsp_delete_a_file(CF_VPY_AbsolutePathName, True)
		'vrdtvsp_status = vrdtvsp_delete_a_file(CF_QSF_AbsolutePathName, True)
		WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File: - ???????????????????? moved FAILED CONVERSION file to FAILED folder: """ & CF_FILE_AbsolutePathName & """ to """ & CF_failed_conversion_TS_Folder & """")
		WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File: - ???????????????????? moved FAILED CONVERSION file to FAILED folder: """ & CF_FILE_AbsolutePathName & """ to """ & CF_failed_conversion_TS_Folder & """")
		WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File: - ???????????????????? moved FAILED CONVERSION file to FAILED folder: """ & CF_FILE_AbsolutePathName & """ to """ & CF_failed_conversion_TS_Folder & """")
		WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File: - ???????????????????? moved FAILED CONVERSION file to FAILED folder: """ & CF_FILE_AbsolutePathName & """ to """ & CF_failed_conversion_TS_Folder & """")
		WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File: - ???????????????????? moved FAILED CONVERSION file to FAILED folder: """ & CF_FILE_AbsolutePathName & """ to """ & CF_failed_conversion_TS_Folder & """")
		WScript.StdOut.WriteLine(" ")
		WScript.StdOut.WriteLine("vrdtvsp_Convert_File FINISHED " & vrdtvsp_current_datetime_string())
		WScript.StdOut.WriteLine("" & vrdtvsp_current_datetime_string())
		WScript.StdOut.WriteLine("======================================================================================================================================================")
		WScript.StdOut.WriteLine(" ")
		vrdtvsp_Convert_File = -1 ' just exit and hope the source file is moved to "failed" folder and the process continues with other files
		Exit Function
	End If
	'
	' Choose the most likely video bitrate of the SOURCE file from amongst the various options. 
	' Sometimes ffprobe mis-reports the qsf'd file's bitrate and is perhaps double the others. 
	' It looks to be correct though.
	' Cross-check with other tool values.
	' NOTE: use the maximum of MEDIAINFO bitrate and QSF bitrate from log (QSF bitrate from log is an "average actual").
	'       also, note we seek biotrate values of the QSF'd file not the original TS which can have problematic values.
	V_INCOMING_BITRATE = 0
	V_INCOMING_BITRATE_MEDIAINFO = 0
	V_INCOMING_BITRATE_FFPROBE = 0
	V_INCOMING_BITRATE_QSF_XML = 0
	'REM Check if supposed numbers are NUMERIC.
	If IsNumeric(Q_V_BitRate) Then 				V_INCOMING_BITRATE_MEDIAINFO = Q_V_BitRate
	If IsNumeric(Q_V_BitRate_FF) Then 			V_INCOMING_BITRATE_FFPROBE = Q_V_BitRate_FF
	If IsNumeric(Q_ACTUAL_QSF_XML_BITRATE) Then	V_INCOMING_BITRATE_QSF_XML = Q_ACTUAL_QSF_XML_BITRATE
	'USE the ffprobe bitrate value, sometimes it mis-reports as a much larger bitrate value but it seems to be correct.
	IF V_INCOMING_BITRATE_FFPROBE   > V_INCOMING_BITRATE Then 
		V_INCOMING_BITRATE = V_INCOMING_BITRATE_FFPROBE
		WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File: updating to use V_INCOMING_BITRATE = V_INCOMING_BITRATE_FFPROBE = " & V_INCOMING_BITRATE_FFPROBE)
	End If
	IF V_INCOMING_BITRATE_MEDIAINFO > V_INCOMING_BITRATE Then 
		V_INCOMING_BITRATE = V_INCOMING_BITRATE_MEDIAINFO
		WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File: updating to use V_INCOMING_BITRATE = V_INCOMING_BITRATE_MEDIAINFO = " & V_INCOMING_BITRATE_MEDIAINFO)
	End If
	IF V_INCOMING_BITRATE_QSF_XML   > V_INCOMING_BITRATE Then 
		V_INCOMING_BITRATE = V_INCOMING_BITRATE_QSF_XML
		WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File: updating to use V_INCOMING_BITRATE = V_INCOMING_BITRATE_QSF_XML = " & V_INCOMING_BITRATE_MEDIAINFO)
	End If
IF V_INCOMING_BITRATE = 0  Then
		' Jolly Bother and Dash it all, no valid bitrate found anywhere, we need to set an artifical incoming bitrate. Choose 4Mb/s for AVC
		V_INCOMING_BITRATE = 4000000
	End If
	If vrdtvsp_DEBUG Then
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvsp_Convert_File adjusted QSF media characteristics below:") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvsp_Convert_File Q_V_Codec_legacy=""" & Q_V_Codec_legacy & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvsp_Convert_File Q_V_Format_legacy=""" & Q_V_Format_legacy & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvsp_Convert_File Q_V_DisplayAspectRatio_String_slash=""" & Q_V_DisplayAspectRatio_String_slash & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvsp_Convert_File Q_V_PixelAspectRatio=""" & Q_V_PixelAspectRatio & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvsp_Convert_File Q_V_ScanType=""" & Q_V_ScanType & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvsp_Convert_File Q_V_ScanOrder=""" & Q_V_ScanOrder & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvsp_Convert_File Q_V_IsProgressive=""" & Q_V_IsProgressive & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvsp_Convert_File Q_V_IsInterlaced=""" & Q_V_IsInterlaced & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvsp_Convert_File Q_V_Width=""" & Q_V_Width & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvsp_Convert_File Q_V_Height=""" & Q_V_Height & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvsp_Convert_File Q_V_BitRate=""" & Q_V_BitRate & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvsp_Convert_File Q_V_BitRate_Minimum=""" & Q_V_BitRate_Minimum & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvsp_Convert_File Q_V_BitRate_Maximum=""" & Q_V_BitRate_Maximum & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvsp_Convert_File Q_A_Codec_legacy=""" & Q_A_Codec_legacy & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvsp_Convert_File Q_A_CodecID_legacy=""" & Q_A_CodecID_legacy & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvsp_Convert_File Q_A_Format_legacy=""" & Q_A_Format_legacy & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvsp_Convert_File Q_A_Video_Delay_ms=""" & Q_A_Video_Delay_ms & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvsp_Convert_File Q_A_Video_Delay_ms_legacy=""" & Q_A_Video_Delay_ms_legacy & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvsp_Convert_File Q_A_Audio_Delay_ms=""" & Q_A_Audio_Delay_ms & """")
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvsp_Convert_File Q_A_Audio_Delay_ms_legacy=""" & Q_A_Audio_Delay_ms_legacy & """")
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvsp_Convert_File Q_A_CodecID=""" & Q_A_CodecID & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvsp_Convert_File Q_A_CodecID_String=""" & Q_A_CodecID_String & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvsp_Convert_File Q_V_CodecID_FF=""" & Q_V_CodecID_FF & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvsp_Convert_File Q_V_CodecID_String_FF=""" & Q_V_CodecID_String_FF & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvsp_Convert_File Q_V_Width_FF=""" & Q_V_Width_FF & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvsp_Convert_File Q_V_Height_FF=""" & Q_V_Height_FF & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvsp_Convert_File Q_V_Duration_s_FF=""" & Q_V_Duration_s_FF & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvsp_Convert_File Q_V_BitRate_FF=""" & Q_V_BitRate_FF & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvsp_Convert_File Q_V_BitRate_Maximum_FF=""" & Q_V_BitRate_Maximum_FF & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvsp_Convert_File Q_V_FrameRate=""" & Q_V_FrameRate & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvsp_Convert_File Q_V_FrameRate_String=""" & Q_V_FrameRate_String & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvsp_Convert_File Q_V_Frame_Rate_FF=""" & Q_V_Frame_Rate_FF & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvsp_Convert_File Q_V_Avg_Frame_Rate_FF=""" & Q_V_Avg_Frame_Rate_FF & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvsp_Convert_File V_INCOMING_BITRATE_MEDIAINFO=""" & V_INCOMING_BITRATE_MEDIAINFO & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvsp_Convert_File V_INCOMING_BITRATE_FFPROBE=""" & V_INCOMING_BITRATE_FFPROBE & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvsp_Convert_File V_INCOMING_BITRATE_QSF_XML=""" & V_INCOMING_BITRATE_QSF_XML & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvsp_Convert_File V_INCOMING_BITRATE=""" & V_INCOMING_BITRATE & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvsp_Convert_File adjusted QSF media characteristics above") 
	End If
	WScript.StdOut.WriteLine("======================================================================================================================================================")
	WScript.StdOut.WriteLine("" & vrdtvsp_current_datetime_string())
	WScript.StdOut.WriteLine("End QSF of """ & CF_FILE_AbsolutePathName & """ into """ & CF_QSF_AbsolutePathName & """")
	WScript.StdOut.WriteLine("output QSF file: " & " Q_V_FrameRate=" & Q_V_FrameRate & " (Q_V_Frame_Rate_FF=" & Q_V_Frame_Rate_FF & ") Q_V_Codec_legacy: """ & Q_V_Codec_legacy & """ Q_V_ScanType: """ & Q_V_ScanType & """ Q_V_ScanOrder: """ & Q_V_ScanOrder & """ " & Q_V_Width & "x" & Q_V_Height & " dar=" & Q_V_DisplayAspectRatio_String_slash & " sar=" & Q_V_PixelAspectRatio & " Q_A_Codec_legacy: " & Q_A_Codec_legacy & " Q_A_Audio_Delay_ms: " & Q_A_Audio_Delay_ms & " Q_A_Audio_Delay_ms_legacy: " & Q_A_Audio_Delay_ms_legacy & " Q_A_Video_Delay_ms: " &  Q_A_Video_Delay_ms & " Q_A_Video_Delay_ms_legacy: " &  Q_A_Video_Delay_ms_legacy)
	WScript.StdOut.WriteLine(" ====================================================================================================================================================================")
	WScript.StdOut.WriteLine("V_INCOMING_BITRATE: Using """ & CF_FILE_AbsolutePathName & """ and """ & CF_QSF_AbsolutePathName & """ The V_INCOMING_BITRATE=""" & V_INCOMING_BITRATE & """")
	WScript.StdOut.WriteLine("" & vrdtvsp_current_datetime_string())
	WScript.StdOut.WriteLine("======================================================================================================================================================")
	'
	' Cross-Check SOURCE ScanType and ScanOrder with QSF ScanType and ScanOrder and bail if not the same
	If Ucase(V_ScanType) <> Ucase(Q_V_ScanType) Then
		If vrdtvsp_DEBUG Then WScript.StdOut.WriteLine("VRDTVSP DEBUG: VRDTVSP ERROR vrdtvsp_Convert_File - Error - Ucase(V_ScanType) """ & Ucase(V_ScanType) & """ <> Ucase(Q_V_ScanType) """ & Ucase(Q_V_ScanType) & """  """ & CF_QSF_AbsolutePathName & """ """ & Q_V_Codec_legacy & """ ... Ignoring file ...")
		WScript.StdOut.WriteLine("VRDTVSP ERROR vrdtvsp_Convert_File - Error - Ucase(V_ScanType) """ & Ucase(V_ScanType) & """ <> Ucase(Q_V_ScanType) """ & Ucase(Q_V_ScanType) & """  """ & CF_QSF_AbsolutePathName & """ """ & Q_V_Codec_legacy & """ ... Ignoring file ...")
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File adjusted SOURCE media characteristics below:") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File V_Codec_legacy=""" & V_Codec_legacy & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File V_Format_legacy=""" & V_Format_legacy & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File V_DisplayAspectRatio_String_slash=""" & V_DisplayAspectRatio_String_slash & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File V_PixelAspectRatio=""" & V_PixelAspectRatio & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File V_ScanType=""" & V_ScanType & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File V_ScanOrder=""" & V_ScanOrder & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File V_IsProgressive=""" & V_IsProgressive & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File V_IsInterlaced=""" & V_IsInterlaced & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File V_Width=""" & V_Width & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File V_Height=""" & V_Height & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File V_BitRate=""" & V_BitRate & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File V_BitRate_Minimum=""" & V_BitRate_Minimum & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File V_BitRate_Maximum=""" & V_BitRate_Maximum & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File A_Codec_legacy=""" & A_Codec_legacy & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File A_CodecID_legacy=""" & A_CodecID_legacy & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File A_Format_legacy=""" & A_Format_legacy & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File A_Video_Delay_ms=""" & A_Video_Delay_ms & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File A_Video_Delay_ms_legacy=""" & A_Video_Delay_ms_legacy & """")
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File A_Audio_Delay_ms=""" & A_Audio_Delay_ms & """")
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File A_Audio_Delay_ms_legacy=""" & A_Audio_Delay_ms_legacy & """")
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File A_CodecID=""" & A_CodecID & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File A_CodecID_String=""" & A_CodecID_String & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File V_CodecID_FF=""" & V_CodecID_FF & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File V_CodecID_String_FF=""" & V_CodecID_String_FF & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File V_Width_FF=""" & V_Width_FF & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File V_Height_FF=""" & V_Height_FF & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File V_Duration_s_FF=""" & V_Duration_s_FF & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File V_BitRate_FF=""" & V_BitRate_FF & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File V_BitRate_Maximum_FF=""" & V_BitRate_Maximum_FF & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File adjusted SOURCE media characteristics above") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File Q_V_Codec_legacy=""" & Q_V_Codec_legacy & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File Q_V_Format_legacy=""" & Q_V_Format_legacy & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File Q_V_DisplayAspectRatio_String_slash=""" & Q_V_DisplayAspectRatio_String_slash & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File Q_V_PixelAspectRatio=""" & Q_V_PixelAspectRatio & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File Q_V_ScanType=""" & Q_V_ScanType & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File Q_V_ScanOrder=""" & Q_V_ScanOrder & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File Q_V_IsProgressive=""" & Q_V_IsProgressive & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File Q_V_IsInterlaced=""" & Q_V_IsInterlaced & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File Q_V_Width=""" & Q_V_Width & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File Q_V_Height=""" & Q_V_Height & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File Q_V_BitRate=""" & Q_V_BitRate & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File Q_V_BitRate_Minimum=""" & Q_V_BitRate_Minimum & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File Q_V_BitRate_Maximum=""" & Q_V_BitRate_Maximum & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File Q_A_Codec_legacy=""" & Q_A_Codec_legacy & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File Q_A_CodecID_legacy=""" & Q_A_CodecID_legacy & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File Q_A_Format_legacy=""" & Q_A_Format_legacy & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File Q_A_Video_Delay_ms=""" & Q_A_Video_Delay_ms & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File Q_A_Video_Delay_ms_legacy=""" & Q_A_Video_Delay_ms_legacy & """")
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File Q_A_Audio_Delay_ms=""" & Q_A_Audio_Delay_ms & """")
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File Q_A_Audio_Delay_ms_legacy=""" & Q_A_Audio_Delay_ms_legacy & """")
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File Q_A_CodecID=""" & Q_A_CodecID & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File Q_A_CodecID_String=""" & Q_A_CodecID_String & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File Q_V_CodecID_FF=""" & Q_V_CodecID_FF & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File Q_V_CodecID_String_FF=""" & Q_V_CodecID_String_FF & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File Q_V_Width_FF=""" & Q_V_Width_FF & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File Q_V_Height_FF=""" & Q_V_Height_FF & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File Q_V_Duration_s_FF=""" & Q_V_Duration_s_FF & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File Q_V_BitRate_FF=""" & Q_V_BitRate_FF & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File Q_V_BitRate_Maximum_FF=""" & Q_V_BitRate_Maximum_FF & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File Q_V_FrameRate=""" & Q_V_FrameRate & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File Q_V_FrameRate_String=""" & Q_V_FrameRate_String & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File Q_V_Frame_Rate_FF=""" & Q_V_Frame_Rate_FF & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File Q_V_Avg_Frame_Rate_FF=""" & Q_V_Avg_Frame_Rate_FF & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File V_INCOMING_BITRATE_MEDIAINFO=""" & V_INCOMING_BITRATE_MEDIAINFO & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File V_INCOMING_BITRATE_FFPROBE=""" & V_INCOMING_BITRATE_FFPROBE & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File V_INCOMING_BITRATE_QSF_XML=""" & V_INCOMING_BITRATE_QSF_XML & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File V_INCOMING_BITRATE=""" & V_INCOMING_BITRATE & """") 
		If vrdtvsp_DEVELOPMENT_NO_ACTIONS Then ' DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV 
			Wscript.Echo "Error 17 = cannot perform the requested operation"
			On Error goto 0
			WScript.Quit 17 ' Error 17 = cannot perform the requested operation
		End If
		WScript.StdOut.WriteLine("VRDTVSP ERROR vrdtvsp_Convert_File - Error - Failed to QSF, unequal SCANTYPES """ & CF_FILE_AbsolutePathName & """ V_Codec_legacy=""" & V_Codec_legacy & """ CF_exe_cmd_string=""" & CF_exe_cmd_string & """")
		vrdtvsp_status = vrdtvsp_move_files_to_folder(CF_FILE_AbsolutePathName, CF_failed_conversion_TS_Folder)
		vrdtvsp_status = vrdtvsp_move_files_to_folder(CF_vprj_AbsolutePathName, CF_failed_conversion_TS_Folder)
		'vrdtvsp_status = vrdtvsp_delete_a_file(CF_DGI_AbsolutePathName, True)
		'vrdtvsp_status = vrdtvsp_delete_a_file(CF_VPY_AbsolutePathName, True)
		'vrdtvsp_status = vrdtvsp_delete_a_file(CF_QSF_AbsolutePathName, True)
		WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File: - ???????????????????? moved FAILED CONVERSION file to FAILED folder: """ & CF_FILE_AbsolutePathName & """ to """ & CF_failed_conversion_TS_Folder & """")
		WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File: - ???????????????????? moved FAILED CONVERSION file to FAILED folder: """ & CF_FILE_AbsolutePathName & """ to """ & CF_failed_conversion_TS_Folder & """")
		WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File: - ???????????????????? moved FAILED CONVERSION file to FAILED folder: """ & CF_FILE_AbsolutePathName & """ to """ & CF_failed_conversion_TS_Folder & """")
		WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File: - ???????????????????? moved FAILED CONVERSION file to FAILED folder: """ & CF_FILE_AbsolutePathName & """ to """ & CF_failed_conversion_TS_Folder & """")
		WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File: - ???????????????????? moved FAILED CONVERSION file to FAILED folder: """ & CF_FILE_AbsolutePathName & """ to """ & CF_failed_conversion_TS_Folder & """")
		WScript.StdOut.WriteLine(" ")
		WScript.StdOut.WriteLine("vrdtvsp_Convert_File FINISHED " & vrdtvsp_current_datetime_string())
		WScript.StdOut.WriteLine("" & vrdtvsp_current_datetime_string())
		WScript.StdOut.WriteLine("======================================================================================================================================================")
		WScript.StdOut.WriteLine(" ")
		vrdtvsp_Convert_File = -1 ' just exit and hope the source file is moved to "failed" folder and the process continues with other files
		Exit Function
	End If
	If Ucase(V_ScanOrder) <> Ucase(Q_V_ScanOrder) Then
		If vrdtvsp_DEBUG Then WScript.StdOut.WriteLine("VRDTVSP DEBUG: VRDTVSP ERROR vrdtvsp_Convert_File - Error - Ucase(V_ScanOrder) """ & Ucase(V_ScanOrder) & """ <> Ucase(Q_V_ScanOrder) """ & Ucase(Q_V_ScanOrder) & """  """ & CF_QSF_AbsolutePathName & """ """ & Q_V_Codec_legacy & """ ... Ignoring file ...")
		WScript.StdOut.WriteLine("VRDTVSP ERROR vrdtvsp_Convert_File - Error - Ucase(V_ScanOrder) """ & Ucase(V_ScanOrder) & """ <> Ucase(Q_V_ScanOrder) """ & Ucase(Q_V_ScanOrder) & """ """ & CF_QSF_AbsolutePathName & """ """ & Q_V_Codec_legacy & """ ... Ignoring file ...")
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File adjusted SOURCE media characteristics below:") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File V_Codec_legacy=""" & V_Codec_legacy & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File V_Format_legacy=""" & V_Format_legacy & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File V_DisplayAspectRatio_String_slash=""" & V_DisplayAspectRatio_String_slash & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File V_PixelAspectRatio=""" & V_PixelAspectRatio & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File V_ScanType=""" & V_ScanType & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File V_ScanOrder=""" & V_ScanOrder & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File V_Width=""" & V_Width & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File V_Height=""" & V_Height & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File V_BitRate=""" & V_BitRate & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File V_BitRate_Minimum=""" & V_BitRate_Minimum & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File V_BitRate_Maximum=""" & V_BitRate_Maximum & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File A_Codec_legacy=""" & A_Codec_legacy & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File A_CodecID_legacy=""" & A_CodecID_legacy & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File A_Format_legacy=""" & A_Format_legacy & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File A_Video_Delay_ms=""" & A_Video_Delay_ms & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File A_Video_Delay_ms_legacy=""" & A_Video_Delay_ms_legacy & """")
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File A_Audio_Delay_ms=""" & A_Audio_Delay_ms & """")
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File A_Audio_Delay_ms_legacy=""" & A_Audio_Delay_ms_legacy & """")
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File A_CodecID=""" & A_CodecID & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File A_CodecID_String=""" & A_CodecID_String & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File V_CodecID_FF=""" & V_CodecID_FF & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File V_CodecID_String_FF=""" & V_CodecID_String_FF & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File V_Width_FF=""" & V_Width_FF & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File V_Height_FF=""" & V_Height_FF & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File V_Duration_s_FF=""" & V_Duration_s_FF & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File V_BitRate_FF=""" & V_BitRate_FF & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File V_BitRate_Maximum_FF=""" & V_BitRate_Maximum_FF & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File adjusted SOURCE media characteristics above") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File Q_V_Codec_legacy=""" & Q_V_Codec_legacy & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File Q_V_Format_legacy=""" & Q_V_Format_legacy & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File Q_V_DisplayAspectRatio_String_slash=""" & Q_V_DisplayAspectRatio_String_slash & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File Q_V_PixelAspectRatio=""" & Q_V_PixelAspectRatio & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File Q_V_ScanType=""" & Q_V_ScanType & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File Q_V_ScanOrder=""" & Q_V_ScanOrder & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File Q_V_Width=""" & Q_V_Width & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File Q_V_Height=""" & Q_V_Height & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File Q_V_BitRate=""" & Q_V_BitRate & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File Q_V_BitRate_Minimum=""" & Q_V_BitRate_Minimum & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File Q_V_BitRate_Maximum=""" & Q_V_BitRate_Maximum & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File Q_A_Codec_legacy=""" & Q_A_Codec_legacy & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File Q_A_CodecID_legacy=""" & Q_A_CodecID_legacy & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File Q_A_Format_legacy=""" & Q_A_Format_legacy & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File Q_A_Video_Delay_ms=""" & Q_A_Video_Delay_ms & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File Q_A_Video_Delay_ms_legacy=""" & Q_A_Video_Delay_ms_legacy & """")
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File Q_A_Audio_Delay_ms=""" & Q_A_Audio_Delay_ms & """")
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File Q_A_Audio_Delay_ms_legacy=""" & Q_A_Audio_Delay_ms_legacy & """")
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File Q_A_CodecID=""" & Q_A_CodecID & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File Q_A_CodecID_String=""" & Q_A_CodecID_String & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File Q_V_CodecID_FF=""" & Q_V_CodecID_FF & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File Q_V_CodecID_String_FF=""" & Q_V_CodecID_String_FF & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File Q_V_Width_FF=""" & Q_V_Width_FF & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File Q_V_Height_FF=""" & Q_V_Height_FF & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File Q_V_Duration_s_FF=""" & Q_V_Duration_s_FF & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File Q_V_BitRate_FF=""" & Q_V_BitRate_FF & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File Q_V_BitRate_Maximum_FF=""" & Q_V_BitRate_Maximum_FF & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File Q_V_FrameRate=""" & Q_V_FrameRate & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File Q_V_FrameRate_String=""" & Q_V_FrameRate_String & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File Q_V_Frame_Rate_FF=""" & Q_V_Frame_Rate_FF & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File Q_V_Avg_Frame_Rate_FF=""" & Q_V_Avg_Frame_Rate_FF & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File V_INCOMING_BITRATE_MEDIAINFO=""" & V_INCOMING_BITRATE_MEDIAINFO & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File V_INCOMING_BITRATE_FFPROBE=""" & V_INCOMING_BITRATE_FFPROBE & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File V_INCOMING_BITRATE_QSF_XML=""" & V_INCOMING_BITRATE_QSF_XML & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvsp_Convert_File V_INCOMING_BITRATE=""" & V_INCOMING_BITRATE & """") 
		If vrdtvsp_DEVELOPMENT_NO_ACTIONS Then ' DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV 
			Wscript.Echo "Error 17 = cannot perform the requested operation"
			On Error goto 0
			WScript.Quit 17 ' Error 17 = cannot perform the requested operation
		End If
		WScript.StdOut.WriteLine("VRDTVSP ERROR vrdtvsp_Convert_File - Error - Failed to QSF, unequal SCANORDERS """ & CF_FILE_AbsolutePathName & """ V_Codec_legacy=""" & V_Codec_legacy & """ CF_exe_cmd_string=""" & CF_exe_cmd_string & """")
		vrdtvsp_status = vrdtvsp_move_files_to_folder(CF_FILE_AbsolutePathName, CF_failed_conversion_TS_Folder)
		vrdtvsp_status = vrdtvsp_move_files_to_folder(CF_vprj_AbsolutePathName, CF_failed_conversion_TS_Folder)
		'vrdtvsp_status = vrdtvsp_delete_a_file(CF_DGI_AbsolutePathName, True)
		'vrdtvsp_status = vrdtvsp_delete_a_file(CF_VPY_AbsolutePathName, True)
		'vrdtvsp_status = vrdtvsp_delete_a_file(CF_QSF_AbsolutePathName, True)
		WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File: - ???????????????????? moved FAILED CONVERSION file to FAILED folder: """ & CF_FILE_AbsolutePathName & """ to """ & CF_failed_conversion_TS_Folder & """")
		WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File: - ???????????????????? moved FAILED CONVERSION file to FAILED folder: """ & CF_FILE_AbsolutePathName & """ to """ & CF_failed_conversion_TS_Folder & """")
		WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File: - ???????????????????? moved FAILED CONVERSION file to FAILED folder: """ & CF_FILE_AbsolutePathName & """ to """ & CF_failed_conversion_TS_Folder & """")
		WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File: - ???????????????????? moved FAILED CONVERSION file to FAILED folder: """ & CF_FILE_AbsolutePathName & """ to """ & CF_failed_conversion_TS_Folder & """")
		WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File: - ???????????????????? moved FAILED CONVERSION file to FAILED folder: """ & CF_FILE_AbsolutePathName & """ to """ & CF_failed_conversion_TS_Folder & """")
		WScript.StdOut.WriteLine(" ")
		WScript.StdOut.WriteLine("vrdtvsp_Convert_File FINISHED " & vrdtvsp_current_datetime_string())
		WScript.StdOut.WriteLine("" & vrdtvsp_current_datetime_string())
		WScript.StdOut.WriteLine("======================================================================================================================================================")
		WScript.StdOut.WriteLine(" ")
		vrdtvsp_Convert_File = -1 ' just exit and hope the source file is moved to "failed" folder and the process continues with other files
		Exit Function
	End If
	'
	' +++++++++++++++++++++++++++ define initial FFMPEG video/audio conversion parameters +++++++++++++++++++++++++++
	'
	If Ucase(vrdtvsp_ComputerName) = Ucase("3900X") Then
		' -dpb_size 0		means automatic (default)
		' -bf:v 3			means use 3 b-frames (dont use more than 3)
		' -b_ref_mode 0		means B frames will not be used for reference
		vrdtvsp_final_RTX2060super_extra_flags = "-spatial-aq 1 -temporal-aq 1 -dpb_size 0 -bf:v 3 -b_ref_mode:v 0"	'2021.02.28 "-refs 3" replaced by -dpb_size 0 -bf:v 3 -b_ref_mode:v 0 https://trac.ffmpeg.org/ticket/9130#comment:8 https://trac.ffmpeg.org/ticket/7303#comment:3
	Else
		vrdtvsp_final_RTX2060super_extra_flags = ""
	End If
	'
	' Calculate the target minimum_bitrate, target_bitrate, maximum_bitrate, buffer size
	' Note that the only reliable variable obtained from the QSF file is Q_V_BitRate
	If V_IsAVC Then ' Ucase(Q_V_Codec_legacy) = Ucase("AVC")
		REM CALCULATE H.264 TARGET BITRATES FROM THE INCOMING BITRATE
		REM ffmpeg nvenc typically seems to undershoot the target bitrate, so bump it up.
		FF_V_Target_BitRate = ROUND(V_INCOMING_BITRATE * 1.05)			' + 5%
		FF_V_Target_Minimum_BitRate = ROUND(V_INCOMING_BITRATE * 0.20)	' 20%
		FF_V_Target_Maximum_BitRate = ROUND(FF_V_Target_BitRate * 2)	' double
		FF_V_Target_BufSize = ROUND(FF_V_Target_BitRate * 2)			' double
	Else ' by  the time it gets here it must be MPEG2 flagged as V_IsMPEG2
		REM is MPEG2 input, so GUESS at reasonable H.264 TARGET BITRATE
		FF_V_Target_BitRate = ROUND(2000000)
		FF_V_Target_Minimum_BitRate = ROUND(100000)
		FF_V_Target_Maximum_BitRate = ROUND(FF_V_Target_BitRate * 2)
		FF_V_Target_BufSize = ROUND(FF_V_Target_BitRate * 2)
	End If
	'
	' NOTE:	After testing, it has been found that ffprobe can mis-report bitrates in the QSF'd file by about double.
	'		Although mediainfo and the "QSF log" values are reasonably close, testing shows ffprobe gets it more "right" when encoding.
	'		Although hopefully correct, this can result in a much lower transcoded filesizes than the originals.
	'		For now, accept what we PROPOSE on whether to "Up" the CQ from 0 to 24.
	' Initial Default CQ options:
	x_cq0 = "-cq:v 0"
	x_cq24 = "-cq:v 24 -qmin 16 -qmax 48"
	vrdtvsp_final_cq_options = x_cq0 ' default to cq0
	PROPOSED_x_cq_options = vrdtvsp_final_cq_options
	If vrdtvsp_DEBUG Then 
		WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_Convert_File - INITIAL vrdtvsp_final_cq_options      =""" & vrdtvsp_final_cq_options & """ for " & Q_V_Codec_legacy)
		WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_Convert_File - INITIAL FF_V_Target_BitRate          =""" & FF_V_Target_BitRate & """ for " & Q_V_Codec_legacy)
		WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_Convert_File - INITIAL FF_V_Target_Minimum_BitRate  =""" & FF_V_Target_Minimum_BitRate & """ for " & Q_V_Codec_legacy)
		WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_Convert_File - INITIAL FF_V_Target_Maximum_BitRate  =""" & FF_V_Target_Maximum_BitRate & """ for " & Q_V_Codec_legacy)
		WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_Convert_File - INITIAL FF_V_Target_BufSize          =""" & FF_V_Target_BufSize & """ for " & Q_V_Codec_legacy)
	End If
	'
	' FOR AVC INPUT FILES ONLY, calculate the CQ to use (default to CQ0)
	' There are special cases where Mediainfo detects a lower bitrate than FFPROBE
	' and MediaInfo is likely right ... however FFPROBE is what we want it to be.
	' When this happens, if we just leave the bitrate CQ as-is then ffmpeg just undershoots 
	' even though we specify the higher bitrate of FFPROBE.
	' So ...
	' If we detect such a case, change to CQ24 instead of CQ0 and leave the 
	' specified bitrate unchanged ... which "should" fix it up.
	If V_IsAVC Then ' Ucase(Q_V_Codec_legacy) = Ucase("AVC") 
		'ECHO Example table of values and actions
		'ECHO	MI		FF		INCOMING	ACTION
		'ECHO	0		0		5Mb			set to CQ 0
		'ECHO	0		1.5Mb	1.5Mb		set to CQ 24
		'ECHO	0		4Mb		4Mb			set to CQ 0
		'ECHO	1.5Mb	0		1.5Mb		set to CQ 24
		'ECHO	1.5Mb 	1.5Mb	1.5Mb		set to CQ 24
		'ECHO	1.5Mb	4Mb		4Mb			set to CQ 24 *** this one
		'ECHO	4Mb		0		4Mb			set to CQ 0
		'ECHO	4Mb		1.5Mb	4Mb			set to CQ 0
		'ECHO	4Mb		5Mb		5Mb			set to CQ 0
		If V_INCOMING_BITRATE < 2200000 Then ' low bitrate, do not touch the bitrate itself, instead bump to CQ24
			PROPOSED_x_cq_options = x_cq24
		End If
		If V_INCOMING_BITRATE_MEDIAINFO > 0 AND V_INCOMING_BITRATE_MEDIAINFO < 2200000 AND V_INCOMING_BITRATE_FFPROBE < 3400000 Then
			PROPOSED_x_cq_options = x_cq24
		End If
	End If
	vrdtvsp_final_cq_options = PROPOSED_x_cq_options
	'
	' Now Check for Footy, after the final fiddling with bitrates and CQ.
	' If is footy, deinterlace to 50FPS 50p, doubling the framerate, rather than just 25p
	' so that we maintain the "motion fluidity" of 50i into 50p. It's better than Nothing.
	' We also need to set the field order, TFF etc
	If Ucase(V_ScanOrder) = Ucase("BFF") Then ' we default to TFF if not known
		vrdtvsp_final_dg_tff = False
	Else
		vrdtvsp_final_dg_tff = True
	End If
	Footy_found = False
	If Ucase(V_ScanType) = Ucase("Progressive") Then
		vrdtvsp_final_dg_deinterlace = 0	' no deinterlace for progressive files
	Else ' only check FOOTY for interlaced files
		If Instr(1,Ucase(fso.GetBaseName(CF_QSF_AbsolutePathName)), Ucase("AFL"), vbTextCompare) > 0 Then 
			Footy_found = True
			If vrdtvsp_DEBUG Then 
				WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_Convert_File - Footy_found: ""AFL"" found in filename.")
			End If
		End If
		If Instr(1,Ucase(fso.GetBaseName(CF_QSF_AbsolutePathName)), Ucase("SANFL"), vbTextCompare) > 0 Then
			Footy_found = True
			If vrdtvsp_DEBUG Then 
				WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_Convert_File - Footy_found: ""SANFL"" found in filename.")
			End If
		End If
		If Instr(1,Ucase(fso.GetBaseName(CF_QSF_AbsolutePathName)), Ucase("Adelaide Crows"), vbTextCompare) > 0 Then
			Footy_found = True
			If vrdtvsp_DEBUG Then 
				WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_Convert_File - Footy_found: ""Adelaide Crows"" found in filename.")
			End If
		End If
		If Instr(1,Ucase(fso.GetBaseName(CF_QSF_AbsolutePathName)), Ucase("Crows"), vbTextCompare) > 0 Then
			Footy_found = True
			If vrdtvsp_DEBUG Then 
				WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_Convert_File - Footy_found: ""Crows"" found in filename.")
			End If
		End If
	End If		
	vrdtvsp_final_dg_deinterlace = 1	' set for normal single framerate deinterlace BY DEFAULT (I mucked it up a few versions ago)
	If Footy_found Then ' bump up the bitrates due to double framerate deinterlacing
		WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File: - FOOTY detected ... setting extended Footy_FF_V_* bitates for double-framerate conversion.")
		vrdtvsp_final_dg_deinterlace = 2	' set for double framerate deinterlace
		Footy_FF_V_Target_BitRate = ROUND(FF_V_Target_BitRate * 1.75)
		Footy_FF_V_Target_Minimum_BitRate = ROUND(Footy_FF_V_Target_BitRate * 0.20)
		Footy_FF_V_Target_Maximum_BitRate = ROUND(Footy_FF_V_Target_BitRate * 2)
		Footy_FF_V_Target_BufSize = ROUND(Footy_FF_V_Target_BitRate * 2)
	Else ' default them back to non-footy settings
		vrdtvsp_final_dg_deinterlace = 1	' set for normal single framerate deinterlace
	'	Footy_FF_V_Target_BitRate = ROUND(FF_V_Target_BitRate)
	'	Footy_FF_V_Target_Minimum_BitRate = ROUND(FF_V_Target_Minimum_BitRate)
	'	Footy_FF_V_Target_Maximum_BitRate = ROUND(FF_V_Target_Maximum_BitRate)
	'	Footy_FF_V_Target_BufSize = ROUND(FF_V_Target_BufSize)
	End If
	If vrdtvsp_DEBUG Then 
		WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_Convert_File - CF_QSF_AbsolutePathName               =""" & CF_QSF_AbsolutePathName & """")
		WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_Convert_File - Q_V_Codec_legacy                      =""" & Q_V_Codec_legacy & """")
		WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_Convert_File - V_ScanType                            =""" & V_ScanType & """")
		WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_Convert_File - V_ScanOrder                           =""" & V_ScanOrder & """")
		WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_Convert_File - vrdtvsp_final_RTX2060super_extra_flags =""" & vrdtvsp_final_RTX2060super_extra_flags & """")
		WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_Convert_File - vrdtvsp_final_dg_tff                   =""" & vrdtvsp_final_dg_tff & """")
		WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_Convert_File - vrdtvsp_final_dg_deinterlace           =""" & vrdtvsp_final_dg_deinterlace & """")
		WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_Convert_File - vrdtvsp_final_cq_options               =""" & vrdtvsp_final_cq_options & """")
		WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_Convert_File - Footy_found                           =""" & Footy_found & """")
		If Footy_found Then
			WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_Convert_File - Footy found, should be using the Footy parameters below and deinterlace=2 above.")
		Else
			WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_Convert_File - Footy NOT found, be using the non-Footy parameters as below and deinterlace=1 above.")
		End If
		WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_Convert_File - Footy_FF_V_Target_BitRate             =""" & Footy_FF_V_Target_BitRate & """")
		WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_Convert_File - Footy_FF_V_Target_Minimum_BitRate     =""" & Footy_FF_V_Target_Minimum_BitRate & """")
		WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_Convert_File - Footy_FF_V_Target_Maximum_BitRate     =""" & Footy_FF_V_Target_Maximum_BitRate & """")
		WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_Convert_File - Footy_FF_V_Target_BufSize             =""" & Footy_FF_V_Target_BufSize & """")
		WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_Convert_File - non-Footy FF_V_Target_BitRate         =""" & FF_V_Target_BitRate & """")
		WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_Convert_File - non-Footy FF_V_Target_Minimum_BitRate =""" & FF_V_Target_Minimum_BitRate & """")
		WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_Convert_File - non-Footy FF_V_Target_Maximum_BitRate =""" & FF_V_Target_Maximum_BitRate & """")
		WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_Convert_File - non-Footy FF_V_Target_BufSize         =""" & FF_V_Target_BufSize & """")
	End If
	'
	' START ======================================================  Do the DGIndexNV ======================================================
	' ++++ START Run the DGIndexNV command
	ff_timerStart = Timer
	If V_IsProgressive AND V_IsAVC Then ' not required for Progressive-AVC where we just copy streams ' Ucase(V_ScanType) = Ucase("Progressive") AND Q_V_Codec_legacy <> "AVC"
		CF_object_saved_ffmpeg_commands.WriteLine("REM")
		CF_object_saved_ffmpeg_commands.WriteLine("REM ====================================================================================================================================================================")
		CF_object_saved_ffmpeg_commands.WriteLine("ECHO !DATE! !TIME!")
		CF_object_saved_ffmpeg_commands.WriteLine("REM DGIndexNV is NOT performed for Progressive-AVC where we just copy streams")
		CF_object_saved_ffmpeg_commands.WriteLine("ECHO !DATE! !TIME!")
		CF_object_saved_ffmpeg_commands.WriteLine("REM ====================================================================================================================================================================")
		CF_object_saved_ffmpeg_commands.WriteLine("REM")
		If vrdtvsp_DEBUG Then 
			WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_Convert_File - DGIndexNV is not performed for Progressive-AVC where we just copy streams")
		End If
	Else
		CF_object_saved_ffmpeg_commands.WriteLine("REM")
		CF_object_saved_ffmpeg_commands.WriteLine("REM DGIndexNV is ONLY *not* performed for the Progressive/AVC combination video")
		CF_object_saved_ffmpeg_commands.WriteLine("REM")
		If vrdtvsp_DEBUG Then 
			WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_Convert_File - DGIndexNV is performed for NON-Progressive OR NON-AVC video")
		End If
		CF_object_saved_ffmpeg_commands.WriteLine("DEL /F """ & CF_DGI_AbsolutePathName & """")
		CF_object_saved_ffmpeg_commands.WriteLine("DEL /F """ & CF_DGIlog_AbsolutePathName & """")
		CF_object_saved_ffmpeg_commands.WriteLine("REM ====================================================================================================================================================================")
		CF_object_saved_ffmpeg_commands.WriteLine("ECHO !DATE! !TIME!")
		CF_exe_cmd_string_0 = """" & vrdtvsp_dgindexNVexe64 & """ -version "	' show the version of DGIndexNV
		CF_object_saved_ffmpeg_commands.WriteLine(CF_exe_cmd_string_0) 			' write that DGIndexNV String to be executed
		CF_exe_cmd_string = """" & vrdtvsp_dgindexNVexe64 & """ -i """ & CF_QSF_AbsolutePathName & """ -e -h -o """ & CF_DGI_AbsolutePathName & """"	' the DGIndexNV command to do the index
		CF_object_saved_ffmpeg_commands.WriteLine(CF_exe_cmd_string)																					' write that DGIndexNV String to be executed
		CF_object_saved_ffmpeg_commands.WriteLine("ECHO !DATE! !TIME!")
		CF_object_saved_ffmpeg_commands.WriteLine("REM ====================================================================================================================================================================")
		CF_object_saved_ffmpeg_commands.WriteLine("REM")
		If vrdtvsp_DEBUG Then 
			WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_Convert_File run DGIndexNV """ & CF_QSF_AbsolutePathName & """ with CF_exe_cmd_string=""" & CF_exe_cmd_string & """")
		End If
		'
		' GRRRR ... Microsoft ...
		' No matter what I try with wso.Exec, since 2022.07.18 DGIndexNV never completes and wso.Exec always returns a status "0" and so runs forever. 
		' It used to run fine before a windows update.  Grrr.
		' Although ... the VERY SAME command, both directly and run in a .BAT file, works perfectly from a vanilla DOS command box.
		' Since we "may" require output from running DGIndexNV, and the commandline has parameters (some quoted),
		'	stick the command in a .bat file with message redirection to a log file
		'	and then synchronously Run the .bat file
		'	then examine the returned errorlevel and the logfile
		'WScript.StdOut.WriteLine("======================================================================================================================================================")
		'WScript.StdOut.WriteLine("START RUN DGIndexNV " & vrdtvsp_current_datetime_string())
		'vrdtvsp_status = vrdtvsp_delete_a_file(CF_DGI_AbsolutePathName, True)		' Delete the DGI file to be created by DGIndexNV
		'vrdtvsp_status = vrdtvsp_delete_a_file(CF_DGIlog_AbsolutePathName, True)	' Delete the DGIlog file to be created by DGIndexNV
		'CF_exe_status = vrdtvsp_exec_a_command_and_show_stdout_stderr(CF_exe_cmd_string_0)	' defined above
		'CF_exe_status = vrdtvsp_exec_a_command_and_show_stdout_stderr(CF_exe_cmd_string)	' defined above
		'WScript.StdOut.WriteLine("FINISH RUN DGIndexNV " & vrdtvsp_current_datetime_string())
		'WScript.StdOut.WriteLine("======================================================================================================================================================")
		vrdtvsp_status = vrdtvsp_delete_a_file(CF_DGI_AbsolutePathName, True)		' Delete the DGI file to be created by DGIndexNV
		vrdtvsp_status = vrdtvsp_delete_a_file(CF_DGIlog_AbsolutePathName, True)	' Delete the DGIlog file to be created by DGIndexNV
		ReDim vrdtvsp_Exec_in_a_DOS_BAT_file_cmd_array(5) ' base 0, so the dimension is always 1 less than the number of commands
		vrdtvsp_Exec_in_a_DOS_BAT_file_cmd_array(0) = "REM " & vrdtvsp_current_datetime_string()
		vrdtvsp_Exec_in_a_DOS_BAT_file_cmd_array(1) = "ECHO !DATE! !TIME!"
		vrdtvsp_Exec_in_a_DOS_BAT_file_cmd_array(2) = "DEL /F """ & CF_DGI_AbsolutePathName & """"
		vrdtvsp_Exec_in_a_DOS_BAT_file_cmd_array(3) = "DEL /F """ & CF_DGIlog_AbsolutePathName & """"
		vrdtvsp_Exec_in_a_DOS_BAT_file_cmd_array(4) = CF_exe_cmd_string_0	' show the version of DGIndexNV
		vrdtvsp_Exec_in_a_DOS_BAT_file_cmd_array(5) = CF_exe_cmd_string		' for the final return status to be good, this must be the final command in the array
		CF_exe_status = vrdtvsp_Exec_in_a_DOS_BAT_file(vrdtvsp_Exec_in_a_DOS_BAT_file_cmd_array, True, True) ' print .bat, do the commands, print .log
		Erase vrdtvsp_Exec_in_a_DOS_BAT_file_cmd_array
		CF_tmp = vrdtvsp_exec_a_command_and_show_stdout_stderr("CMD /C ""TYPE " & CF_DGIlog_AbsolutePathName & """")
		If CF_exe_status <> 0 OR NOT fso.FileExists(CF_DGI_AbsolutePathName) Then
			If vrdtvsp_DEBUG Then 
				WScript.StdOut.WriteLine("")
				WScript.StdOut.WriteLine("VRDTVSP DEBUG: ERROR vrdtvsp_Convert_File - Error - run DGIndexNV """ & CF_QSF_AbsolutePathName & """ with CF_exe_cmd_string=""" & CF_exe_cmd_string & """ CF_exe_status=" & CF_exe_status)
			End If
			WScript.StdOut.WriteLine("")
			WScript.StdOut.WriteLine("VRDTVSP ERROR vrdtvsp_Convert_File - Error - run DGIndexNV """ & CF_QSF_AbsolutePathName & """ with CF_exe_cmd_string=""" & CF_exe_cmd_string & """ CF_exe_status=" & CF_exe_status)
			If vrdtvsp_DEVELOPMENT_NO_ACTIONS Then ' DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV 
				Wscript.Echo "DEV error after DGindexNV " & CF_exe_status
				Wscript.Echo "Error 17 = cannot perform the requested operation"
				On Error goto 0
				WScript.Quit 17 ' Error 17 = cannot perform the requested operation
			End If
			vrdtvsp_status = vrdtvsp_move_files_to_folder(CF_FILE_AbsolutePathName, CF_failed_conversion_TS_Folder)
			vrdtvsp_status = vrdtvsp_move_files_to_folder(CF_vprj_AbsolutePathName, CF_failed_conversion_TS_Folder)
			'vrdtvsp_status = vrdtvsp_delete_a_file(CF_DGI_AbsolutePathName, True)
			'vrdtvsp_status = vrdtvsp_delete_a_file(CF_VPY_AbsolutePathName, True)
			'vrdtvsp_status = vrdtvsp_delete_a_file(CF_QSF_AbsolutePathName, True)
			WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File: - ???????????????????? moved FAILED CONVERSION file to FAILED folder: """ & CF_FILE_AbsolutePathName & """ to """ & CF_failed_conversion_TS_Folder & """")
			WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File: - ???????????????????? moved FAILED CONVERSION file to FAILED folder: """ & CF_FILE_AbsolutePathName & """ to """ & CF_failed_conversion_TS_Folder & """")
			WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File: - ???????????????????? moved FAILED CONVERSION file to FAILED folder: """ & CF_FILE_AbsolutePathName & """ to """ & CF_failed_conversion_TS_Folder & """")
			WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File: - ???????????????????? moved FAILED CONVERSION file to FAILED folder: """ & CF_FILE_AbsolutePathName & """ to """ & CF_failed_conversion_TS_Folder & """")
			WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File: - ???????????????????? moved FAILED CONVERSION file to FAILED folder: """ & CF_FILE_AbsolutePathName & """ to """ & CF_failed_conversion_TS_Folder & """")
			WScript.StdOut.WriteLine(" ")
			WScript.StdOut.WriteLine("vrdtvsp_Convert_File FINISHED " & vrdtvsp_current_datetime_string())
			WScript.StdOut.WriteLine("" & vrdtvsp_current_datetime_string())
			WScript.StdOut.WriteLine("======================================================================================================================================================")
			WScript.StdOut.WriteLine(" ")
			vrdtvsp_Convert_File = -1 ' just exit and hope the source file is moved to "failed" folder and the process continues with other files
			Exit Function
		End If
		If vrdtvsp_DEBUG Then
			WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_Convert_File about to delete DG autolog " & CF_DGIlog_AbsolutePathName)
		End If
		CF_object_saved_ffmpeg_commands.WriteLine("DEL /F """ & CF_DGIlog_AbsolutePathName & """")
		vrdtvsp_status = vrdtvsp_delete_a_file (CF_DGIlog_AbsolutePathName, True)	' Delete the DGIlog file created by DGIndexNV
	End If
	ff_timerEnd = Timer
	WScript.StdOut.WriteLine("************** DGIndexNV command completed with Elapsed Time " & vrdtvsp_Calculate_ElapsedTime_string(ff_timerStart, ff_timerEnd))
	' ++++ END Run the DGIndexNV command
	' END  ======================================================  Do the DGIndexNV ======================================================
	'
	' START  ======================================================  Create the .VPY and FFMPEG COmmand string ======================================================
	vrdtvsp_create_VPY = True
	vpy_denoise  = ""
	vpy_dsharpen = ""
	af_audio_delay_filter = " "
	it_video_delay = " "
	' It turns out Audio Delays after QSF are not worth worrying about, so leave them out by default
	If CF_do_audio_delay Then
		If Q_A_Audio_Delay_ms > 0 Then	' video before audio
			af_audio_delay_filter = "-af ""adelay=delays=" & Q_A_Audio_Delay_ms & "ms:all=1"" "
			it_video_delay = " "
		ElseIf Q_A_Audio_Delay_ms < 0 Then	' audio before video
			af_audio_delay_filter = " "
			it_video_delay = " -itsoffset " & Q_A_Video_Delay_ms & "ms "	' JUST BEFORE VIDEO INPUT FILE
		Else	' 0ms delays
			af_audio_delay_filter = " "
			it_video_delay = " "
		End If
	End If
	If V_IsProgressive Then ' Ucase(V_ScanType) = Ucase("Progressive")
		If V_IsAVC Then ' Ucase(Q_V_Codec_legacy) = Ucase("AVC") 
			vrdtvsp_create_VPY = False ' this is a NO-OP
			vpy_denoise = ""								' flag no denoising for progressive AVC
			vpy_dsharpen = ""								' flag no sharpening for progressive AVC
			' probesize 200 Mb, analyzeduration 200 seconds 2021.02.17
			ff_cmd_string =	"""" & vrdtvsp_ffmpegexe64 & """ " &_
							"-hide_banner -v verbose -nostats " &_
							"-probesize 200M -analyzeduration 200M " &_
							"-i """ & CF_QSF_AbsolutePathName & """ " &_
							"-c:v copy " &_
							"-vsync 0 -sws_flags lanczos+accurate_rnd+full_chroma_int+full_chroma_inp -strict experimental " &_
							"-movflags +faststart+write_colr "
							' removed this line, since ffmpeg throws an error due to "-c:v copy" and this together: "-vf ""setdar=" & V_DisplayAspectRatio_String_slash & """ " &_
							' removed this line since ffmpeg throws an error "-profile:v high -level 5.2 -movflags +faststart+write_colr " &_
			If Ucase(A_Codec_legacy) = Ucase("AAC LC") Then
				ff_cmd_string =	ff_cmd_string & "-c:a copy "
			Else
				'ff_cmd_string =	ff_cmd_string & "-af ""adelay=delays=" & A_Audio_Delay_ms & "ms:all=1"" -c:a libfdk_aac -cutoff 20000 -ab 256k -ar 48000 "
				ff_cmd_string =	ff_cmd_string & "-af ""adelay=delays=" & A_Audio_Delay_ms & "ms:all=1"" -c:a libfdk_aac -cutoff 18000 -ab 256k -ar 48000 " ' reduce from 20000 to 18000 to improve overall quality
			End If
			ff_cmd_string =	ff_cmd_string & " -y """ & CF_TARGET_AbsolutePathName & """"
							WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File: ========== Created ffmpeg_cmd_string, hopefully Progressive/AVC vs file: " & V_ScanType & " " & V_ScanOrder & " """ & V_Codec_legacy & """/""" & A_Codec_legacy & """")
			WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File: ========== Created ffmpeg_cmd_string <" & ff_cmd_string & ">")
		ElseIf V_IsMPEG2 Then 'Ucase(Q_V_Codec_legacy) = Ucase("MPEG2-2V")
			vpy_denoise  = "strength=0.06, cstrength=0.06"	' flag denoising  for progressive mpeg2
			vpy_dsharpen = "strength=0.3"					' flag sharpening for progressive mpeg2
			' probesize 120 Mb, analyzeduration 120 seconds 2021.02.17
			ff_cmd_string =	"""" & vrdtvsp_ffmpegexe64 & """ " &_
							"-hide_banner -v verbose -nostats " &_
							"-f vapoursynth -i """ & CF_VPY_AbsolutePathName & """ " &_
							"-probesize 200M -analyzeduration 200M " &_
							it_video_delay &_
							"-i """ & CF_QSF_AbsolutePathName & """ " &_
							"-map 0:v:0 -map 1:a:0 " &_
							"-vf ""setdar=" & V_DisplayAspectRatio_String_slash & """ " &_
							"-vsync 0 -sws_flags lanczos+accurate_rnd+full_chroma_int+full_chroma_inp -strict experimental " &_
							"-c:v h264_nvenc -pix_fmt nv12 -preset p7 -multipass fullres -forced-idr 1 -g 25 -coder:v cabac " &_
							vrdtvsp_final_RTX2060super_extra_flags & " " &_
							"-rc:v vbr " &_
							"-cq:v 0" & " " &_
							"-b:v " & FF_V_Target_BitRate & " " &_
							"-minrate:v " & FF_V_Target_Minimum_BitRate & " " &_
							"-maxrate:v " & FF_V_Target_Maximum_BitRate & " " &_
							"-bufsize " & FF_V_Target_BufSize & " " &_
							"-profile:v high -level 5.2 -movflags +faststart+write_colr " &_
							af_audio_delay_filter &_
							"-c:a libfdk_aac -cutoff 20000 -ab 256k -ar 48000 " &_
							" -y """ & CF_TARGET_AbsolutePathName & """"
			WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File: ========== Created ffmpeg_cmd_string, hopefully Progressive/MPEG2 vs file: " & V_ScanType & " " & V_ScanOrder & " """ & V_Codec_legacy & """/""" & A_Codec_legacy & """")
			WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File: ========== Created ffmpeg_cmd_string <" & ff_cmd_string & ">")
		Else
			WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File: ERROR - Unable to create ff_cmd_string Progressive avc/mpeg2 - unknown codec " & Q_V_Codec_legacy)
			vrdtvsp_status = vrdtvsp_move_files_to_folder(CF_FILE_AbsolutePathName, CF_failed_conversion_TS_Folder)
			vrdtvsp_status = vrdtvsp_move_files_to_folder(CF_vprj_AbsolutePathName, CF_failed_conversion_TS_Folder)
			'vrdtvsp_status = vrdtvsp_delete_a_file(CF_DGI_AbsolutePathName, True)
			'vrdtvsp_status = vrdtvsp_delete_a_file(CF_VPY_AbsolutePathName, True)
			'vrdtvsp_status = vrdtvsp_delete_a_file(CF_QSF_AbsolutePathName, True)
			WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File: - ???????????????????? moved FAILED CONVERSION file to FAILED folder: """ & CF_FILE_AbsolutePathName & """ to """ & CF_failed_conversion_TS_Folder & """")
			WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File: - ???????????????????? moved FAILED CONVERSION file to FAILED folder: """ & CF_FILE_AbsolutePathName & """ to """ & CF_failed_conversion_TS_Folder & """")
			WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File: - ???????????????????? moved FAILED CONVERSION file to FAILED folder: """ & CF_FILE_AbsolutePathName & """ to """ & CF_failed_conversion_TS_Folder & """")
			WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File: - ???????????????????? moved FAILED CONVERSION file to FAILED folder: """ & CF_FILE_AbsolutePathName & """ to """ & CF_failed_conversion_TS_Folder & """")
			WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File: - ???????????????????? moved FAILED CONVERSION file to FAILED folder: """ & CF_FILE_AbsolutePathName & """ to """ & CF_failed_conversion_TS_Folder & """")
			WScript.StdOut.WriteLine(" ")
			WScript.StdOut.WriteLine("vrdtvsp_Convert_File FINISHED " & vrdtvsp_current_datetime_string())
			WScript.StdOut.WriteLine("" & vrdtvsp_current_datetime_string())
			WScript.StdOut.WriteLine("======================================================================================================================================================")
			WScript.StdOut.WriteLine(" ")
			vrdtvsp_Convert_File = -1 ' just exit and hope the source file is moved to "failed" folder and the process continues with other files
			Exit Function
		End If
	ElseIf V_IsInterlaced Then
		if V_IsAVC Then
			vpy_denoise = ""								' flag no denoising for interlaced AVC
			vpy_dsharpen = "strength=0.2"					' flag sharpening   for interlaced AVC
			' probesize 120 Mb, analyzeduration 120 seconds 2021.02.17
			ff_cmd_string =	"""" & vrdtvsp_ffmpegexe64 & """ " &_
							"-hide_banner -v verbose -nostats " &_
							"-f vapoursynth -i """ & CF_VPY_AbsolutePathName & """ " &_
							"-probesize 200M -analyzeduration 200M " &_
							it_video_delay &_
							"-i """ & CF_QSF_AbsolutePathName & """ " &_
							"-map 0:v:0 -map 1:a:0 " &_
							"-vf ""setdar=" & V_DisplayAspectRatio_String_slash & """ " &_
							"-vsync 0 -sws_flags lanczos+accurate_rnd+full_chroma_int+full_chroma_inp -strict experimental " &_
							"-c:v h264_nvenc -pix_fmt nv12 -preset p7 -multipass fullres -forced-idr 1 -g 25 -coder:v cabac " &_
							vrdtvsp_final_RTX2060super_extra_flags & " " &_
							"-rc:v vbr " &_
							vrdtvsp_final_cq_options & " " &_
							"-b:v " & FF_V_Target_BitRate & " " &_
							"-minrate:v " & FF_V_Target_Minimum_BitRate & " " &_
							"-maxrate:v " & FF_V_Target_Maximum_BitRate & " " &_
							"-bufsize " & FF_V_Target_BufSize & " " &_
							"-profile:v high -level 5.2 -movflags +faststart+write_colr " &_
							af_audio_delay_filter &_
							"-c:a libfdk_aac -cutoff 20000 -ab 256k -ar 48000 " &_
							" -y """ & CF_TARGET_AbsolutePathName & """"
			If Footy_found Then	' Must be AVC Interlaced Footy to pass this test, USE DIFFERENT SETTINGS since we deinterlace with double framerate (and use -g 25)
				' probesize 120 Mb, analyzeduration 120 seconds 2021.02.17
				vpy_denoise  = "strength=0.05, cstrength=0.05"	' flag denoising  for footy interlaced avc, since it seems to be blurry nad noisy as at 2022.06
				vpy_dsharpen = "strength=0.25"					' flag sharpening for footy interlaced avc, since it seems to be blurry nad noisy as at 2022.06
				ff_cmd_string =	"""" & vrdtvsp_ffmpegexe64 & """ " &_
								"-hide_banner -v verbose -nostats " &_
								"-f vapoursynth -i """ & CF_VPY_AbsolutePathName & """ " &_
								"-probesize 200M -analyzeduration 200M " &_
								it_video_delay &_
								"-i """ & CF_QSF_AbsolutePathName & """ " &_
								"-map 0:v:0 -map 1:a:0 " &_
								"-vf ""setdar=" & V_DisplayAspectRatio_String_slash & """ " &_
								"-vsync 0 -sws_flags lanczos+accurate_rnd+full_chroma_int+full_chroma_inp -strict experimental " &_
								"-c:v h264_nvenc -pix_fmt nv12 -preset p7 -multipass fullres -forced-idr 1 -g 50 -coder:v cabac " &_
								vrdtvsp_final_RTX2060super_extra_flags & " " &_
								"-rc:v vbr " &_
								vrdtvsp_final_cq_options & " " &_
								"-b:v " & Footy_FF_V_Target_BitRate & " " &_
								"-minrate:v " & Footy_FF_V_Target_Minimum_BitRate & " " &_
								"-maxrate:v " & Footy_FF_V_Target_Maximum_BitRate & " " &_
								"-bufsize " & Footy_FF_V_Target_BufSize & " " &_
								"-profile:v high -level 5.2 -movflags +faststart+write_colr " &_
								af_audio_delay_filter &_
								"-c:a libfdk_aac -cutoff 20000 -ab 256k -ar 48000 " &_
								" -y """ & CF_TARGET_AbsolutePathName & """"
				WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File: ========== FOOTY detected, hopefully Interlaced/AVC vs file: " & V_ScanType & " " & V_ScanOrder & " """ & V_Codec_legacy & """/""" & A_Codec_legacy & """")
			End If
			WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File: ========== Created ffmpeg_cmd_string, hopefully Interlaced/AVC vs file: " & V_ScanType & " " & V_ScanOrder & " """ & V_Codec_legacy & """/""" & A_Codec_legacy & """")
			WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File: ========== Created ffmpeg_cmd_string <" & ff_cmd_string & ">")
		ElseIf V_IsMPEG2 Then
			vpy_denoise = "strength=0.06, cstrength=0.06"	' flag denoising  for interlaced mpeg2
			vpy_dsharpen = "strength=0.3"					' flag sharpening for interlaced mpeg2
			' probesize 120 Mb, analyzeduration 120 seconds 2021.02.17
			ff_cmd_string =	"""" & vrdtvsp_ffmpegexe64 & """ " &_
							"-hide_banner -v verbose -nostats " &_
							"-f vapoursynth -i """ & CF_VPY_AbsolutePathName & """ " &_
							"-probesize 200M -analyzeduration 200M " &_
							it_video_delay &_
							"-i """ & CF_QSF_AbsolutePathName & """ " &_
							"-map 0:v:0 -map 1:a:0 " &_
							"-vf ""setdar=" & V_DisplayAspectRatio_String_slash & """ " &_
							"-vsync 0 -sws_flags lanczos+accurate_rnd+full_chroma_int+full_chroma_inp -strict experimental " &_
							"-c:v h264_nvenc -pix_fmt nv12 -preset p7 -multipass fullres -forced-idr 1 -g 25 -coder:v cabac " &_
							vrdtvsp_final_RTX2060super_extra_flags & " " &_
							"-rc:v vbr " &_
							vrdtvsp_final_cq_options & " " &_
							"-b:v " & FF_V_Target_BitRate & " " &_
							"-minrate:v " & FF_V_Target_Minimum_BitRate & " " &_
							"-maxrate:v " & FF_V_Target_Maximum_BitRate & " " &_
							"-bufsize " & FF_V_Target_BufSize & " " &_
							"-profile:v high -level 5.2 -movflags +faststart+write_colr " &_
							af_audio_delay_filter &_
							"-c:a libfdk_aac -cutoff 20000 -ab 256k -ar 48000 " &_
							" -y """ & CF_TARGET_AbsolutePathName & """"
			' Leave MPEG2 Interlaced Footy alone, as if it were a normal video file ... no code for MPEG2 Interlaced Footy in here
			WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File: ========== Created ffmpeg_cmd_string, hopefully Interlaced/MPEG2 vs file: " & V_ScanType & " " & V_ScanOrder & " """ & V_Codec_legacy & """/""" & A_Codec_legacy & """")
			WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File: ========== Created ffmpeg_cmd_string <" & ff_cmd_string & ">")
		Else
			WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File: ERROR - Unable to create ff_cmd_string Interlaced avc/mpeg2 - unknown codec " & Q_V_Codec_legacy)
			vrdtvsp_status = vrdtvsp_move_files_to_folder(CF_FILE_AbsolutePathName, CF_failed_conversion_TS_Folder)
			vrdtvsp_status = vrdtvsp_move_files_to_folder(CF_vprj_AbsolutePathName, CF_failed_conversion_TS_Folder)
			'vrdtvsp_status = vrdtvsp_delete_a_file(CF_DGI_AbsolutePathName, True)
			'vrdtvsp_status = vrdtvsp_delete_a_file(CF_VPY_AbsolutePathName, True)
			'vrdtvsp_status = vrdtvsp_delete_a_file(CF_QSF_AbsolutePathName, True)
			WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File: - ???????????????????? moved FAILED CONVERSION file to FAILED folder: """ & CF_FILE_AbsolutePathName & """ to """ & CF_failed_conversion_TS_Folder & """")
			WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File: - ???????????????????? moved FAILED CONVERSION file to FAILED folder: """ & CF_FILE_AbsolutePathName & """ to """ & CF_failed_conversion_TS_Folder & """")
			WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File: - ???????????????????? moved FAILED CONVERSION file to FAILED folder: """ & CF_FILE_AbsolutePathName & """ to """ & CF_failed_conversion_TS_Folder & """")
			WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File: - ???????????????????? moved FAILED CONVERSION file to FAILED folder: """ & CF_FILE_AbsolutePathName & """ to """ & CF_failed_conversion_TS_Folder & """")
			WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File: - ???????????????????? moved FAILED CONVERSION file to FAILED folder: """ & CF_FILE_AbsolutePathName & """ to """ & CF_failed_conversion_TS_Folder & """")
			WScript.StdOut.WriteLine(" ")
			WScript.StdOut.WriteLine("vrdtvsp_Convert_File FINISHED " & vrdtvsp_current_datetime_string())
			WScript.StdOut.WriteLine("" & vrdtvsp_current_datetime_string())
			WScript.StdOut.WriteLine("======================================================================================================================================================")
			WScript.StdOut.WriteLine(" ")
			vrdtvsp_Convert_File = -1 ' just exit and hope the source file is moved to "failed" folder and the process continues with other files
			Exit Function
		End If
	Else
		'??????????????print diagnostics and exit since not Progressive nor Interlaced ...
		WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File: ERROR - Unable to create ff_cmd_string as flag is neither Interlaced nor Progressive .. V_IsInterlaced=" & V_IsInterlaced & " V_IsProgressive=" & V_IsProgressive)
		vrdtvsp_status = vrdtvsp_move_files_to_folder(CF_FILE_AbsolutePathName, CF_failed_conversion_TS_Folder)
		vrdtvsp_status = vrdtvsp_move_files_to_folder(CF_vprj_AbsolutePathName, CF_failed_conversion_TS_Folder)
		'vrdtvsp_status = vrdtvsp_delete_a_file(CF_DGI_AbsolutePathName, True)
		'vrdtvsp_status = vrdtvsp_delete_a_file(CF_VPY_AbsolutePathName, True)
		'vrdtvsp_status = vrdtvsp_delete_a_file(CF_QSF_AbsolutePathName, True)
		WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File: - ???????????????????? moved FAILED CONVERSION file to FAILED folder: """ & CF_FILE_AbsolutePathName & """ to """ & CF_failed_conversion_TS_Folder & """")
		WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File: - ???????????????????? moved FAILED CONVERSION file to FAILED folder: """ & CF_FILE_AbsolutePathName & """ to """ & CF_failed_conversion_TS_Folder & """")
		WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File: - ???????????????????? moved FAILED CONVERSION file to FAILED folder: """ & CF_FILE_AbsolutePathName & """ to """ & CF_failed_conversion_TS_Folder & """")
		WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File: - ???????????????????? moved FAILED CONVERSION file to FAILED folder: """ & CF_FILE_AbsolutePathName & """ to """ & CF_failed_conversion_TS_Folder & """")
		WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File: - ???????????????????? moved FAILED CONVERSION file to FAILED folder: """ & CF_FILE_AbsolutePathName & """ to """ & CF_failed_conversion_TS_Folder & """")
		WScript.StdOut.WriteLine(" ")
		WScript.StdOut.WriteLine("vrdtvsp_Convert_File FINISHED " & vrdtvsp_current_datetime_string())
		WScript.StdOut.WriteLine("" & vrdtvsp_current_datetime_string())
		WScript.StdOut.WriteLine("======================================================================================================================================================")
		WScript.StdOut.WriteLine(" ")
		vrdtvsp_Convert_File = -1 ' just exit and hope the source file is moved to "failed" folder and the process continues with other files
		Exit Function
	End If
	If vrdtvsp_create_VPY Then
		'create the vpy file
		vrdtvsp_status = vrdtvsp_delete_a_file(CF_VPY_AbsolutePathName, True)		' Delete the VPY file to be created
		set CF_VPY_object = fso.CreateTextFile(CF_VPY_AbsolutePathName, True, False) ' *** vapoursynth fails with unicode input file *** [ filename, Overwrite[, Unicode]])
		If CF_VPY_object is Nothing  Then ' Something went wrong with creating the file
			If vrdtvsp_DEBUG Then WScript.StdOut.WriteLine("VRDTVSP DEBUG: VRDTVSP ERROR vrdtvsp_Convert_File - Error - Nothing object returned from fso.CreateTextFile with VPY file """ & CF_VPY_AbsolutePathName & """... Aborting ...")
			WScript.StdOut.WriteLine("VRDTVSP ERROR vrdtvsp_Convert_File - Error - Nothing object returned from fso.CreateTextFile with VPY file  """ & CF_VPY_AbsolutePathName & """... Aborting ...")
			vrdtvsp_status = vrdtvsp_move_files_to_folder(CF_FILE_AbsolutePathName, CF_failed_conversion_TS_Folder)
			vrdtvsp_status = vrdtvsp_move_files_to_folder(CF_vprj_AbsolutePathName, CF_failed_conversion_TS_Folder)
			'vrdtvsp_status = vrdtvsp_delete_a_file(CF_DGI_AbsolutePathName, True)
			'vrdtvsp_status = vrdtvsp_delete_a_file(CF_VPY_AbsolutePathName, True)
			'vrdtvsp_status = vrdtvsp_delete_a_file(CF_QSF_AbsolutePathName, True)
			WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File: - ???????????????????? moved FAILED CONVERSION file to FAILED folder: """ & CF_FILE_AbsolutePathName & """ to """ & CF_failed_conversion_TS_Folder & """")
			WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File: - ???????????????????? moved FAILED CONVERSION file to FAILED folder: """ & CF_FILE_AbsolutePathName & """ to """ & CF_failed_conversion_TS_Folder & """")
			WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File: - ???????????????????? moved FAILED CONVERSION file to FAILED folder: """ & CF_FILE_AbsolutePathName & """ to """ & CF_failed_conversion_TS_Folder & """")
			WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File: - ???????????????????? moved FAILED CONVERSION file to FAILED folder: """ & CF_FILE_AbsolutePathName & """ to """ & CF_failed_conversion_TS_Folder & """")
			WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File: - ???????????????????? moved FAILED CONVERSION file to FAILED folder: """ & CF_FILE_AbsolutePathName & """ to """ & CF_failed_conversion_TS_Folder & """")
			WScript.StdOut.WriteLine(" ")
			WScript.StdOut.WriteLine("vrdtvsp_Convert_File FINISHED " & vrdtvsp_current_datetime_string())
			WScript.StdOut.WriteLine("" & vrdtvsp_current_datetime_string())
			WScript.StdOut.WriteLine("======================================================================================================================================================")
			WScript.StdOut.WriteLine(" ")
			vrdtvsp_Convert_File = -1 ' just exit and hope the source file is moved to "failed" folder and the process continues with other files
			Exit Function
		End If
		CF_object_saved_ffmpeg_commands.WriteLine("REM")
		CF_object_saved_ffmpeg_commands.WriteLine("DEL /F """ & CF_VPY_AbsolutePathName & """")
		CF_object_saved_ffmpeg_commands.WriteLine("REM ====================================================================================================================================================================")
		CF_object_saved_ffmpeg_commands.WriteLine("ECHO !DATE! !TIME!")
		CF_object_saved_ffmpeg_commands.WriteLine("SET ""_VPY_file=" & CF_VPY_AbsolutePathName & """")		
		CF_status = vrdtvsp_writeline_for_vpy (CF_VPY_object, CF_object_saved_ffmpeg_commands, "import vapoursynth as vs		# this allows use of constants eg vs.YUV420P8", "ECHO ", " >> ""!_VPY_file!"" 2>&1")
		CF_status = vrdtvsp_writeline_for_vpy (CF_VPY_object, CF_object_saved_ffmpeg_commands, "from vapoursynth import core	# actual vapoursynth core", "ECHO ", " >> ""!_VPY_file!"" 2>&1")
		CF_status = vrdtvsp_writeline_for_vpy (CF_VPY_object, CF_object_saved_ffmpeg_commands, "#import functool", "ECHO ", " >> ""!_VPY_file!"" 2>&1")
		CF_status = vrdtvsp_writeline_for_vpy (CF_VPY_object, CF_object_saved_ffmpeg_commands, "#import mvsfunc as mvs			# this relies on the .py residing at the VS folder root level - see run_vsrepo.bat", "ECHO ", " >> ""!_VPY_file!"" 2>&1")
		CF_status = vrdtvsp_writeline_for_vpy (CF_VPY_object, CF_object_saved_ffmpeg_commands, "#import havsfunc as haf		# this relies on the .py residing at the VS folder root level - see run_vsrepo.bat", "ECHO ", " >> ""!_VPY_file!"" 2>&1")
		CF_status = vrdtvsp_writeline_for_vpy (CF_VPY_object, CF_object_saved_ffmpeg_commands, "core.std.LoadPlugin(r'" & vapoursynth_root & "\DGIndex\DGDecodeNV.dll') # do it like gonca https://forum.doom9.org/showthread.php?p=1877765#post1877765", "ECHO ", " >> ""!_VPY_file!"" 2>&1")
		CF_status = vrdtvsp_writeline_for_vpy (CF_VPY_object, CF_object_saved_ffmpeg_commands, "core.avs.LoadPlugin(r'" & vapoursynth_root & "\DGIndex\DGDecodeNV.dll') # do it like gonca https://forum.doom9.org/showthread.php?p=1877765#post1877765", "ECHO ", " >> ""!_VPY_file!"" 2>&1")
		CF_status = vrdtvsp_writeline_for_vpy (CF_VPY_object, CF_object_saved_ffmpeg_commands, "# NOTE: deinterlace=" & vrdtvsp_final_dg_deinterlace & ", use_top_field=" & vrdtvsp_final_dg_tff & " for """ & V_ScanType & """/""" & V_ScanOrder & """ """ & V_Codec_legacy & """/""" & A_Codec_legacy & """", "ECHO ", " >> ""!_VPY_file!"" 2>&1")
		CF_status = vrdtvsp_writeline_for_vpy (CF_VPY_object, CF_object_saved_ffmpeg_commands, "video = core.dgdecodenv.DGSource(r'" & CF_DGI_AbsolutePathName & "', deinterlace=" & vrdtvsp_final_dg_deinterlace & ", use_top_field=" & vrdtvsp_final_dg_tff & ", use_pf=False)", "ECHO ", " >> ""!_VPY_file!"" 2>&1")
		CF_status = vrdtvsp_writeline_for_vpy (CF_VPY_object, CF_object_saved_ffmpeg_commands, "# DGDecNV changes -", "ECHO ", " >> ""!_VPY_file!"" 2>&1")
		CF_status = vrdtvsp_writeline_for_vpy (CF_VPY_object, CF_object_saved_ffmpeg_commands, "# 2020.10.21 Added new parameters cstrength and cblend to independently control the chroma denoising.", "ECHO ", " >> ""!_VPY_file!"" 2>&1")
		CF_status = vrdtvsp_writeline_for_vpy (CF_VPY_object, CF_object_saved_ffmpeg_commands, "# 2020.11.07 Revised DGDenoise parameters. The 'chroma' option is removed.", "ECHO ", " >> ""!_VPY_file!"" 2>&1")
		CF_status = vrdtvsp_writeline_for_vpy (CF_VPY_object, CF_object_saved_ffmpeg_commands, "#            Now, if 'strength' is set to 0.0 then luma denoising is disabled,", "ECHO ", " >> ""!_VPY_file!"" 2>&1")
		CF_status = vrdtvsp_writeline_for_vpy (CF_VPY_object, CF_object_saved_ffmpeg_commands, "#            and if cstrength is set to 0.0 then chroma denoising is disabled.", "ECHO ", " >> ""!_VPY_file!"" 2>&1")
		CF_status = vrdtvsp_writeline_for_vpy (CF_VPY_object, CF_object_saved_ffmpeg_commands, "#            'cstrength' is now defaulted to 0.0, and 'searchw' is defaulted to 9.", "ECHO ", " >> ""!_VPY_file!"" 2>&1")
		CF_status = vrdtvsp_writeline_for_vpy (CF_VPY_object, CF_object_saved_ffmpeg_commands, "# example: video = core.avs.DGDenoise(video, strength=0.06, cstrength=0.06) # replaced chroma=True", "ECHO ", " >> ""!_VPY_file!"" 2>&1")
		If vpy_denoise <> "" Then CF_status = vrdtvsp_writeline_for_vpy (CF_VPY_object, CF_object_saved_ffmpeg_commands, "video = core.avs.DGDenoise(video, " & vpy_denoise & ") # replaced chroma=True", "ECHO ", " >> ""!_VPY_file!"" 2>&1")
		CF_status = vrdtvsp_writeline_for_vpy (CF_VPY_object, CF_object_saved_ffmpeg_commands, "# example: video = core.avs.DGSharpen(video, strength=0.3)", "ECHO ", " >> ""!_VPY_file!"" 2>&1")
		If vpy_dsharpen <> "" Then CF_status = vrdtvsp_writeline_for_vpy (CF_VPY_object, CF_object_saved_ffmpeg_commands, "video = core.avs.DGSharpen(video, " & vpy_dsharpen & ")", "ECHO ", " >> ""!_VPY_file!"" 2>&1")
		'If vrdtvsp_DEBUG Then 
		'	CF_status = vrdtvsp_writeline_for_vpy (CF_VPY_object, CF_object_saved_ffmpeg_commands, "video = vs.core.text.ClipInfo(video)", "ECHO ", " >> ""!_VPY_file!"" 2>&1")
		'Else
		'	CF_status = vrdtvsp_writeline_for_vpy (CF_VPY_object, CF_object_saved_ffmpeg_commands, "#video = vs.core.text.ClipInfo(video)", "ECHO ", " >> ""!_VPY_file!"" 2>&1")
		'End If
		CF_status = vrdtvsp_writeline_for_vpy (CF_VPY_object, CF_object_saved_ffmpeg_commands, "#video = vs.core.text.ClipInfo(video)", "ECHO ", " >> ""!_VPY_file!"" 2>&1")
		CF_status = vrdtvsp_writeline_for_vpy (CF_VPY_object, CF_object_saved_ffmpeg_commands, "video.set_output()", "ECHO ", " >> ""!_VPY_file!"" 2>&1")
		CF_status = CF_VPY_object.Close
		Set CF_VPY_object = Nothing
		WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File: - Created VPY file """ & CF_VPY_AbsolutePathName & """ NOTE: used deinterlace=" & vrdtvsp_final_dg_deinterlace & ", use_top_field=" & vrdtvsp_final_dg_tff & " for """ & V_ScanType & """/""" & V_ScanOrder & """ """ & V_Codec_legacy & """/""" & A_Codec_legacy & """")
		CF_object_saved_ffmpeg_commands.WriteLine("ECHO ---------------------------- 2>&1")
		CF_object_saved_ffmpeg_commands.WriteLine("TYPE ""!_VPY_file!"" 2>&1")
		CF_object_saved_ffmpeg_commands.WriteLine("ECHO ---------------------------- 2>&1")
		CF_object_saved_ffmpeg_commands.WriteLine("ECHO !DATE! !TIME!")
		CF_object_saved_ffmpeg_commands.WriteLine("REM ====================================================================================================================================================================")
		' display the content of .VPY file
		WScript.StdOut.WriteLine("======================================================================================================================================================")
		WScript.StdOut.WriteLine("" & vrdtvsp_current_datetime_string())
		WScript.StdOut.WriteLine("Content of VPY file """ & CF_VPY_AbsolutePathName & """ Below --------------------------------------------------------------------------------------------------------------------")
		Set CF_VPY_object = fso.OpenTextFile(CF_VPY_AbsolutePathName, ForReading)
		Do Until CF_VPY_object.AtEndOfStream
			CF_VPY_string = CF_VPY_object.ReadLine
			WScript.StdOut.WriteLine(CF_VPY_string)
		Loop			
		CF_status = CF_VPY_object.Close
		Set CF_VPY_object = Nothing
		WScript.StdOut.WriteLine("Content of VPY file """ & CF_VPY_AbsolutePathName & """ Above --------------------------------------------------------------------------------------------------------------------")
		WScript.StdOut.WriteLine("" & vrdtvsp_current_datetime_string())
		WScript.StdOut.WriteLine("======================================================================================================================================================")
	Else ' Else is previously flagged as not creating a VPY since incoming stream is Progressive/AVC
	End If
	'
	CF_object_saved_ffmpeg_commands.WriteLine("REM")
	If Footy_found Then
		WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File: - Footy Found, using Footy double-framerate deinterlacing and bitrate settings")
		CF_object_saved_ffmpeg_commands.WriteLine("REM Footy Found, using Footy double-framerate deinterlacing and bitrate settings")
		CF_object_saved_ffmpeg_commands.WriteLine("REM")
	End If
	CF_object_saved_ffmpeg_commands.WriteLine("DEL /F """ & CF_TARGET_AbsolutePathName & """")
	CF_object_saved_ffmpeg_commands.WriteLine("REM ====================================================================================================================================================================")
	CF_object_saved_ffmpeg_commands.WriteLine("ECHO !DATE! !TIME!")
	CF_object_saved_ffmpeg_commands.WriteLine(ff_cmd_string)
	CF_object_saved_ffmpeg_commands.WriteLine("ECHO !DATE! !TIME!")
	CF_object_saved_ffmpeg_commands.WriteLine("REM ====================================================================================================================================================================")
		'
	' ++++ START Run the ffmpeg command
	WScript.StdOut.WriteLine("======================================================================================================================================================")
	WScript.StdOut.WriteLine("" & vrdtvsp_current_datetime_string())
	WScript.StdOut.WriteLine("###################################################### START Run the ffmpeg command " & vrdtvsp_current_datetime_string())
	ff_timerStart = Timer
	vrdtvsp_status = vrdtvsp_delete_a_file(CF_TARGET_AbsolutePathName, True)
	'???????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????
	'???????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????
	' GRRRRRRRRRRRRRRRRRRRR ...
	' No matter what I do with wso.Exec, ffmpeg never completes and the Exec object always returns a status "0" and so runs forever. Grrr.
	' Although ... the VERY SAME command, both directly and run in a .BAT file, works perfectly from a vanilla DOS command box.
	' Since we require output from running ffmpeg, and the commandline has a LOT of parameters (some quoted),
	'	stick the command in a .bat file with message redirection to a log file
	'	and then synchronously Run the .bat file
	'	then examine the returned errorlevel and the logfile
	'
	ReDim vrdtvsp_Exec_in_a_DOS_BAT_file_cmd_array(5) ' base 0, so the dimension is always 1 less than the number of commands
	vrdtvsp_Exec_in_a_DOS_BAT_file_cmd_array(0) = "REM " & vrdtvsp_current_datetime_string()
	vrdtvsp_Exec_in_a_DOS_BAT_file_cmd_array(1) = "ECHO !DATE! !TIME!"
	vrdtvsp_Exec_in_a_DOS_BAT_file_cmd_array(2) = "DEL /F """ & CF_TARGET_AbsolutePathName & """"
	vrdtvsp_Exec_in_a_DOS_BAT_file_cmd_array(3) = "REM """ & vrdtvsp_ffmpegexe64 & """ -hide_banner -v verbose -init_hw_device list"
	vrdtvsp_Exec_in_a_DOS_BAT_file_cmd_array(4) = "REM """ & vrdtvsp_ffmpegexe64 & """ -hide_banner -v verbose -hide_banner -h encoder=hevc_nvenc"
	vrdtvsp_Exec_in_a_DOS_BAT_file_cmd_array(5) = ff_cmd_string ' for the final return status to be good, this must be the final command in the array
	CF_exe_status = vrdtvsp_Exec_in_a_DOS_BAT_file(vrdtvsp_Exec_in_a_DOS_BAT_file_cmd_array, True, True) ' print .bat, do the commands, print .log 
	Erase vrdtvsp_Exec_in_a_DOS_BAT_file_cmd_array
	If (CF_exe_status <> 0) OR (NOT fso.FileExists(CF_TARGET_AbsolutePathName)) Then
		If vrdtvsp_DEBUG Then WScript.StdOut.WriteLine("VRDTVSP DEBUG: ERROR vrdtvsp_Convert_File - FFMPEG Error - CF_exe_status=""" & CF_exe_status & """ with ff_cmd_string=""" & ff_cmd_string)
		WScript.StdOut.WriteLine("VRDTVSP ERROR vrdtvsp_Convert_File - FFMPEG Error - CF_exe_status=""" & CF_exe_status & """ with ff_cmd_string=""" & ff_cmd_string)
		If vrdtvsp_DEVELOPMENT_NO_ACTIONS Then ' DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV 
			WScript.StdOut.WriteLine("VRDTVSP DEV: vrdtvsp_DEVELOPMENT_NO_ACTIONS: DEV: vrdtvsp_Convert_File NOT moving file to FAILED folder: """ & CF_FILE_AbsolutePathName & """ to """ & CF_failed_conversion_TS_Folder & """")
			On Error goto 0
			WScript.Quit 17 ' Error 17 = cannot perform the requested operation
		End If
		On Error goto 0
		'WScript.Quit 17 ' Error 17 = cannot perform the requested operation
		vrdtvsp_status = vrdtvsp_move_files_to_folder(CF_FILE_AbsolutePathName, CF_failed_conversion_TS_Folder)
		vrdtvsp_status = vrdtvsp_move_files_to_folder(CF_vprj_AbsolutePathName, CF_failed_conversion_TS_Folder)
		'vrdtvsp_status = vrdtvsp_delete_a_file(CF_DGI_AbsolutePathName, True)
		'vrdtvsp_status = vrdtvsp_delete_a_file(CF_VPY_AbsolutePathName, True)
		'vrdtvsp_status = vrdtvsp_delete_a_file(CF_QSF_AbsolutePathName, True)
		WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File: - ???????????????????? moved FAILED CONVERSION file to FAILED folder: """ & CF_FILE_AbsolutePathName & """ to """ & CF_failed_conversion_TS_Folder & """")
		WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File: - ???????????????????? moved FAILED CONVERSION file to FAILED folder: """ & CF_FILE_AbsolutePathName & """ to """ & CF_failed_conversion_TS_Folder & """")
		WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File: - ???????????????????? moved FAILED CONVERSION file to FAILED folder: """ & CF_FILE_AbsolutePathName & """ to """ & CF_failed_conversion_TS_Folder & """")
		WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File: - ???????????????????? moved FAILED CONVERSION file to FAILED folder: """ & CF_FILE_AbsolutePathName & """ to """ & CF_failed_conversion_TS_Folder & """")
		WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File: - ???????????????????? moved FAILED CONVERSION file to FAILED folder: """ & CF_FILE_AbsolutePathName & """ to """ & CF_failed_conversion_TS_Folder & """")
		WScript.StdOut.WriteLine(" ")
		WScript.StdOut.WriteLine("vrdtvsp_Convert_File FINISHED " & vrdtvsp_current_datetime_string())
		WScript.StdOut.WriteLine("" & vrdtvsp_current_datetime_string())
		WScript.StdOut.WriteLine("======================================================================================================================================================")
		WScript.StdOut.WriteLine(" ")
		vrdtvsp_Convert_File = -1 ' just exit and hope the source file is moved to "failed" folder and the process continues with other files
		Exit Function
	End If
	WScript.StdOut.WriteLine("###################################################### FINISH Run the ffmpeg command " & vrdtvsp_current_datetime_string())
	WScript.StdOut.WriteLine("======================================================================================================================================================")
	vrdtvsp_status = vrdtvsp_delete_a_file(ff_logfile, True)		' Delete the .bat file to be created with the ffmpeg command
	vrdtvsp_status = vrdtvsp_delete_a_file(ff_batfile, True)		' Delete the .bat file to be created with the ffmpeg command
	ff_timerEnd = Timer
    WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File: - ffmpeg command completed with Elapsed Time " & vrdtvsp_Calculate_ElapsedTime_string(ff_timerStart, ff_timerEnd))
	' ++++ END Run the ffmpeg command
	' Obtain TARGET file characteristics via mediainfo 
	T_V_Codec_legacy					= vrdtvsp_get_mediainfo_parameter("Video", "Codec", CF_TARGET_AbsolutePathName, "--Legacy") 
	T_V_Format_legacy					= vrdtvsp_get_mediainfo_parameter("Video", "Format", CF_TARGET_AbsolutePathName, "--Legacy") 
	T_V_DisplayAspectRatio_String		= vrdtvsp_get_mediainfo_parameter("Video", "DisplayAspectRatio/String", CF_TARGET_AbsolutePathName, "")
	T_V_PixelAspectRatio				= vrdtvsp_get_mediainfo_parameter("Video", "PixelAspectRatio", CF_TARGET_AbsolutePathName, "")
	T_V_ScanType						= vrdtvsp_get_mediainfo_parameter("Video", "ScanType", CF_TARGET_AbsolutePathName, "")
	T_V_ScanOrder 						= vrdtvsp_get_mediainfo_parameter("Video", "ScanOrder", CF_TARGET_AbsolutePathName, "")
	T_V_Width							= vrdtvsp_get_mediainfo_parameter("Video", "Width", CF_TARGET_AbsolutePathName, "")
	T_V_Height							= vrdtvsp_get_mediainfo_parameter("Video", "Height", CF_TARGET_AbsolutePathName, "")
	T_V_BitRate							= vrdtvsp_get_mediainfo_parameter("Video", "BitRate", CF_TARGET_AbsolutePathName, "")
	T_V_BitRate_Minimum					= vrdtvsp_get_mediainfo_parameter("Video", "BitRate_Minimum", CF_TARGET_AbsolutePathName, "")
	T_V_BitRate_Maximum					= vrdtvsp_get_mediainfo_parameter("Video", "BitRate_Maximum", CF_TARGET_AbsolutePathName, "")
	T_A_Codec_legacy					= vrdtvsp_get_mediainfo_parameter("Audio", "Codec", CF_TARGET_AbsolutePathName, "--Legacy")
	T_A_CodecID_legacy					= vrdtvsp_get_mediainfo_parameter("Audio", "CodecID", CF_TARGET_AbsolutePathName, "--Legacy") 
	T_A_Format_legacy					= vrdtvsp_get_mediainfo_parameter("Audio", "Format", CF_TARGET_AbsolutePathName, "--Legacy") 
	T_A_Video_Delay_ms_legacy			= vrdtvsp_get_mediainfo_parameter("Audio", "Video_Delay", CF_TARGET_AbsolutePathName, "--Legacy") 
	T_A_CodecID							= vrdtvsp_get_mediainfo_parameter("Audio", "CodecID", CF_TARGET_AbsolutePathName, "")
	T_A_CodecID_String					= vrdtvsp_get_mediainfo_parameter("Audio", "CodecID/String", CF_TARGET_AbsolutePathName, "")
	T_A_Video_Delay_ms					= vrdtvsp_get_mediainfo_parameter("Audio", "Video_Delay", CF_TARGET_AbsolutePathName, "")
	Dim T_V_FrameRate
	Dim T_V_FrameRate_String
	Dim T_V_Frame_Rate_FF
	Dim T_V_Avg_Frame_Rate_FF
	T_V_FrameRate = vrdtvsp_get_mediainfo_parameter("Video", "FrameRate", CF_TARGET_AbsolutePathName, "")
	T_V_FrameRate_String = vrdtvsp_get_mediainfo_parameter("Video", "FrameRate/String", CF_TARGET_AbsolutePathName, "")
	' Obtain TARGET file characteristics via ffprobe 
	T_V_CodecID_FF						= vrdtvsp_get_ffprobe_video_stream_parameter("codec_name", CF_TARGET_AbsolutePathName)  
	T_V_CodecID_String_FF				= vrdtvsp_get_ffprobe_video_stream_parameter("codec_tag_string", CF_TARGET_AbsolutePathName)  
	T_V_Width_FF						= vrdtvsp_get_ffprobe_video_stream_parameter("width", CF_TARGET_AbsolutePathName)  
	T_V_Height_FF						= vrdtvsp_get_ffprobe_video_stream_parameter("height", CF_TARGET_AbsolutePathName)  
	T_V_Duration_s_FF					= vrdtvsp_get_ffprobe_video_stream_parameter("duration", CF_TARGET_AbsolutePathName)  
	T_V_BitRate_FF						= vrdtvsp_get_ffprobe_video_stream_parameter("bit_rate", CF_TARGET_AbsolutePathName)  
	T_V_BitRate_Maximum_FF				= vrdtvsp_get_ffprobe_video_stream_parameter("max_bit_rate", CF_TARGET_AbsolutePathName)
	T_V_Frame_Rate_FF					= vrdtvsp_get_ffprobe_video_stream_parameter("r_frame_rate", CF_TARGET_AbsolutePathName)
	T_V_Avg_Frame_Rate_FF				= vrdtvsp_get_ffprobe_video_stream_parameter("avg_frame_rate", CF_TARGET_AbsolutePathName)
	' Fix up the TARGET mediainfo parameters retrieved
	T_V_FrameRate = ROUND(T_V_FrameRate)
	T_V_DisplayAspectRatio_String_slash	= Replace(T_V_DisplayAspectRatio_String,":","/",1,-1,vbTextCompare)  ' Replace(string,find,replacewith[,start[,count[,compare]]])
	'
	If Ucase(T_V_Codec_legacy) = Ucase("MPEG-2V") Then
		T_V_IsAVC = False
		T_V_IsMPEG2 = True
		'vrdtvsp_extension = vrdtvsp_extension_mpeg2
		'vrdtvsp_profile_name_for_qsf = vrdtvsp_profile_name_for_qsf_mpeg2
	ElseIf Ucase(T_V_Codec_legacy) = Ucase("AVC") Then
		T_V_IsAVC = True
		T_V_IsMPEG2 = False
		'vrdtvsp_extension = vrdtvsp_extension_avc
		'vrdtvsp_profile_name_for_qsf = vrdtvsp_profile_name_for_qsf_avc
	Else
		If vrdtvsp_DEBUG Then WScript.StdOut.WriteLine("VRDTVSP DEBUG: VRDTVSP ERROR vrdtvsp_Convert_File - Error - Unrecognised T_V_Codec_legacy video codec """ & CF_TARGET_AbsolutePathName & """ T_V_Codec_legacy=""" & T_V_Codec_legacy & """ ... Ignoring file ...")
		WScript.StdOut.WriteLine("VRDTVSP ERROR vrdtvsp_Convert_File - Error - Unrecognised T_V_Codec_legacy video codec """ & CF_TARGET_AbsolutePathName & """ T_V_Codec_legacy=""" & T_V_Codec_legacy & """ ... Ignoring file ...")
		If vrdtvsp_DEVELOPMENT_NO_ACTIONS Then ' DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV 
			Wscript.Echo "Error 17 = cannot perform the requested operation"
			On Error goto 0
			WScript.Quit 17 ' Error 17 = cannot perform the requested operation
		End If
		vrdtvsp_status = vrdtvsp_move_files_to_folder(CF_FILE_AbsolutePathName, CF_failed_conversion_TS_Folder)
		vrdtvsp_status = vrdtvsp_move_files_to_folder(CF_vprj_AbsolutePathName, CF_failed_conversion_TS_Folder)
		'vrdtvsp_status = vrdtvsp_delete_a_file(CF_DGI_AbsolutePathName, True)
		'vrdtvsp_status = vrdtvsp_delete_a_file(CF_VPY_AbsolutePathName, True)
		'vrdtvsp_status = vrdtvsp_delete_a_file(CF_QSF_AbsolutePathName, True)
		WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File: - ???????????????????? moved FAILED CONVERSION file to FAILED folder: """ & CF_FILE_AbsolutePathName & """ to """ & CF_failed_conversion_TS_Folder & """")
		WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File: - ???????????????????? moved FAILED CONVERSION file to FAILED folder: """ & CF_FILE_AbsolutePathName & """ to """ & CF_failed_conversion_TS_Folder & """")
		WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File: - ???????????????????? moved FAILED CONVERSION file to FAILED folder: """ & CF_FILE_AbsolutePathName & """ to """ & CF_failed_conversion_TS_Folder & """")
		WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File: - ???????????????????? moved FAILED CONVERSION file to FAILED folder: """ & CF_FILE_AbsolutePathName & """ to """ & CF_failed_conversion_TS_Folder & """")
		WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File: - ???????????????????? moved FAILED CONVERSION file to FAILED folder: """ & CF_FILE_AbsolutePathName & """ to """ & CF_failed_conversion_TS_Folder & """")
		WScript.StdOut.WriteLine(" ")
		WScript.StdOut.WriteLine("vrdtvsp_Convert_File FINISHED " & vrdtvsp_current_datetime_string())
		WScript.StdOut.WriteLine("" & vrdtvsp_current_datetime_string())
		WScript.StdOut.WriteLine("======================================================================================================================================================")
		WScript.StdOut.WriteLine(" ")
		vrdtvsp_Convert_File = -1
		Exit Function
	End If
	If T_A_Video_Delay_ms_legacy = "" Then
		T_A_Video_Delay_ms_legacy = 0
		T_A_Audio_Delay_ms_legacy = 0
	Else
		T_A_Audio_Delay_ms_legacy = 0 - T_A_Video_Delay_ms_legacy
	End If
	If T_A_Video_Delay_ms = "" Then
		T_A_Video_Delay_ms = 0
		T_A_Audio_Delay_ms = 0
	Else
		T_A_Audio_Delay_ms = 0 - T_A_Video_Delay_ms
	End If
	If T_V_ScanType = "" Then
		T_V_ScanType = "Progressive" ' Default to Progressive
	End If
	If T_V_ScanType = "MBAFF" Then
		T_V_ScanType = "Interlaced"
	End If
	If Ucase(T_V_ScanType) = Ucase("Interlaced") Then
		T_V_IsProgressive = False
		T_V_IsInterlaced = True
	ElseIf Ucase(T_V_ScanType) = Ucase("Progressive") Then
		T_V_IsProgressive = True
		T_V_IsInterlaced = False
	Else
		If vrdtvsp_DEBUG Then WScript.StdOut.WriteLine("VRDTVSP DEBUG: VRDTVSP ERROR vrdtvsp_Convert_File - Error - DO NOT KNOW IF TARGET IS INTERLACED OR PROGRESSIVE """ & CF_TARGET_AbsolutePathName & """ T_V_Codec_legacy=""" & T_V_Codec_legacy & """ V_ScanType=""" & T_V_ScanType & """ ... Ignoring file ...")
		WScript.StdOut.WriteLine("VRDTVSP ERROR vrdtvsp_Convert_File - Error - DO NOT KNOW IF TARGET IS INTERLACED OR PROGRESSIVE """ & CF_TARGET_AbsolutePathName & """ T_V_Codec_legacy=""" & T_V_Codec_legacy & """ T_V_ScanType=""" & T_V_ScanType & """ ... Ignoring file ...")
		If vrdtvsp_DEVELOPMENT_NO_ACTIONS Then ' DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV 
			Wscript.Echo "Error 17 = cannot perform the requested operation"
			On Error goto 0
			WScript.Quit 17 ' Error 17 = cannot perform the requested operation
		Else
			Wscript.Echo "Error 17 = cannot perform the requested operation"
			On Error goto 0
			WScript.Quit 17 ' Error 17 = cannot perform the requested operation
		End If
	End If
	'If (V_IsProgressive <> T_V_IsProgressive) OR (V_IsInterlaced <> T_V_IsInterlaced) Then
	'	If vrdtvsp_DEBUG Then WScript.StdOut.WriteLine("VRDTVSP DEBUG: VRDTVSP ERROR vrdtvsp_Convert_File - Error - UNEQUAL SOURCE AND TARGET INTERLACED/PROGRESSIVE V_ScanType=""" & V_ScanType & """ T_V_ScanType=""" & T_V_ScanType &  """ ... Ignoring file ...")
	'	WScript.StdOut.WriteLine("VRDTVSP ERROR vrdtvsp_Convert_File - Error - UNEQUAL SOURCE AND TARGET INTERLACED/PROGRESSIVE V_ScanType=""" & V_ScanType & """ T_V_ScanType=""" & T_V_ScanType & """ ... Ignoring file ...")
	'	If vrdtvsp_DEVELOPMENT_NO_ACTIONS Then ' DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV 
	'		Wscript.Echo "Error 17 = cannot perform the requested operation"
	'		On Error goto 0
	'		WScript.Quit 17 ' Error 17 = cannot perform the requested operation
	'	Else
	'		Wscript.Echo "Error 17 = cannot perform the requested operation"
	'		On Error goto 0
	'		WScript.Quit 17 ' Error 17 = cannot perform the requested operation
	'	End If
	'End If
	If T_V_ScanOrder = "" Then
		T_V_ScanOrder = "TFF" ' Default to Top Field First
	End If
	If NOT T_V_IsProgressive Then 'by now the Target MUST be progressive
		If vrdtvsp_DEBUG Then WScript.StdOut.WriteLine("VRDTVSP DEBUG: VRDTVSP ERROR vrdtvsp_Convert_File - Error - TARGET SHOULD BE PROGRESSIVE BUT IS NOT - V_ScanType=""" & V_ScanType & """ T_V_ScanType=""" & T_V_ScanType & """ """ & CF_TARGET_AbsolutePathName & """ ... Ignoring file ...")
		WScript.StdOut.WriteLine("VRDTVSP ERROR vrdtvsp_Convert_File - Error - TARGET SHOULD BE PROGRESSIVE BUT IS NOT - V_ScanType=""" & V_ScanType & """ T_V_ScanType=""" & T_V_ScanType & """ """ & CF_TARGET_AbsolutePathName & """ ... Ignoring file ...")
		If vrdtvsp_DEVELOPMENT_NO_ACTIONS Then ' DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV 
			Wscript.Echo "Error 17 = cannot perform the requested operation"
			On Error goto 0
			WScript.Quit 17 ' Error 17 = cannot perform the requested operation
		End If
		vrdtvsp_status = vrdtvsp_move_files_to_folder(CF_FILE_AbsolutePathName, CF_failed_conversion_TS_Folder)
		vrdtvsp_status = vrdtvsp_move_files_to_folder(CF_vprj_AbsolutePathName, CF_failed_conversion_TS_Folder)
		'vrdtvsp_status = vrdtvsp_delete_a_file(CF_DGI_AbsolutePathName, True)
		'vrdtvsp_status = vrdtvsp_delete_a_file(CF_VPY_AbsolutePathName, True)
		'vrdtvsp_status = vrdtvsp_delete_a_file(CF_QSF_AbsolutePathName, True)
		WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File: - ???????????????????? moved FAILED CONVERSION file to FAILED folder: """ & CF_FILE_AbsolutePathName & """ to """ & CF_failed_conversion_TS_Folder & """")
		WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File: - ???????????????????? moved FAILED CONVERSION file to FAILED folder: """ & CF_FILE_AbsolutePathName & """ to """ & CF_failed_conversion_TS_Folder & """")
		WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File: - ???????????????????? moved FAILED CONVERSION file to FAILED folder: """ & CF_FILE_AbsolutePathName & """ to """ & CF_failed_conversion_TS_Folder & """")
		WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File: - ???????????????????? moved FAILED CONVERSION file to FAILED folder: """ & CF_FILE_AbsolutePathName & """ to """ & CF_failed_conversion_TS_Folder & """")
		WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File: - ???????????????????? moved FAILED CONVERSION file to FAILED folder: """ & CF_FILE_AbsolutePathName & """ to """ & CF_failed_conversion_TS_Folder & """")
		WScript.StdOut.WriteLine(" ")
		WScript.StdOut.WriteLine("vrdtvsp_Convert_File FINISHED " & vrdtvsp_current_datetime_string())
		WScript.StdOut.WriteLine("" & vrdtvsp_current_datetime_string())
		WScript.StdOut.WriteLine("======================================================================================================================================================")
		WScript.StdOut.WriteLine(" ")
		vrdtvsp_Convert_File = -1 ' just exit and hope the source file is moved to "failed" folder and the process continues with other files
		Exit Function
	End If
	If vrdtvsp_DEBUG Then
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvsp_Convert_File adjusted TARGET media characteristics below:") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvsp_Convert_File T_V_Codec_legacy=""" & T_V_Codec_legacy & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvsp_Convert_File T_V_Format_legacy=""" & T_V_Format_legacy & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvsp_Convert_File T_V_DisplayAspectRatio_String_slash=""" & T_V_DisplayAspectRatio_String_slash & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvsp_Convert_File T_V_PixelAspectRatio=""" & T_V_PixelAspectRatio & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvsp_Convert_File T_V_ScanType=""" & T_V_ScanType & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvsp_Convert_File T_V_ScanOrder=""" & T_V_ScanOrder & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvsp_Convert_File T_V_IsProgressive=""" & T_V_IsProgressive & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvsp_Convert_File T_V_IsInterlaced=""" & T_V_IsInterlaced & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvsp_Convert_File T_V_Width=""" & T_V_Width & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvsp_Convert_File T_V_Height=""" & T_V_Height & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvsp_Convert_File T_V_BitRate=""" & T_V_BitRate & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvsp_Convert_File T_V_BitRate_Minimum=""" & T_V_BitRate_Minimum & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvsp_Convert_File T_V_BitRate_Maximum=""" & T_V_BitRate_Maximum & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvsp_Convert_File T_A_Codec_legacy=""" & T_A_Codec_legacy & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvsp_Convert_File T_A_CodecID_legacy=""" & T_A_CodecID_legacy & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvsp_Convert_File T_A_Format_legacy=""" & T_A_Format_legacy & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvsp_Convert_File T_A_Video_Delay_ms=""" & T_A_Video_Delay_ms & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvsp_Convert_File T_A_Video_Delay_ms_legacy=""" & T_A_Video_Delay_ms_legacy & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvsp_Convert_File T_A_Audio_Delay_ms=""" & T_A_Audio_Delay_ms & """")
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvsp_Convert_File T_A_Audio_Delay_ms_legacy=""" & T_A_Audio_Delay_ms_legacy & """")
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvsp_Convert_File T_A_CodecID=""" & T_A_CodecID & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvsp_Convert_File T_A_CodecID_String=""" & T_A_CodecID_String & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvsp_Convert_File T_V_CodecID_FF=""" & T_V_CodecID_FF & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvsp_Convert_File T_V_CodecID_String_FF=""" & T_V_CodecID_String_FF & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvsp_Convert_File T_V_Width_FF=""" & T_V_Width_FF & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvsp_Convert_File T_V_Height_FF=""" & T_V_Height_FF & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvsp_Convert_File T_V_Duration_s_FF=""" & T_V_Duration_s_FF & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvsp_Convert_File T_V_BitRate_FF=""" & T_V_BitRate_FF & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvsp_Convert_File T_V_BitRate_Maximum_FF=""" & T_V_BitRate_Maximum_FF & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvsp_Convert_File T_V_FrameRate=""" & T_V_FrameRate & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvsp_Convert_File T_V_FrameRate_String=""" & T_V_FrameRate_String & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvsp_Convert_File T_V_Frame_Rate_FF=""" & T_V_Frame_Rate_FF & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvsp_Convert_File T_V_Avg_Frame_Rate_FF=""" & T_V_Avg_Frame_Rate_FF & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvsp_Convert_File V_INCOMING_BITRATE_MEDIAINFO=""" & V_INCOMING_BITRATE_MEDIAINFO & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvsp_Convert_File V_INCOMING_BITRATE_FFPROBE=""" & V_INCOMING_BITRATE_FFPROBE & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvsp_Convert_File V_INCOMING_BITRATE_QSF_XML=""" & V_INCOMING_BITRATE_QSF_XML & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvsp_Convert_File V_INCOMING_BITRATE=""" & V_INCOMING_BITRATE & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvsp_Convert_File adjusted TARGET media characteristics above") 
	End If
	WScript.StdOut.WriteLine("======================================================================================================================================================")
	WScript.StdOut.WriteLine("" & vrdtvsp_current_datetime_string())
	WScript.StdOut.WriteLine("End FFMPEG of """ & CF_FILE_AbsolutePathName & """ into """ & CF_TARGET_AbsolutePathName & """")
	WScript.StdOut.WriteLine("output TARGET file: " & " T_V_FrameRate=" & T_V_FrameRate & " (T_V_Frame_Rate_FF=" & T_V_Frame_Rate_FF & ") T_V_Codec_legacy: """ & T_V_Codec_legacy & """ T_V_ScanType: """ & T_V_ScanType & """ T_V_ScanOrder: """ & T_V_ScanOrder & """ " & T_V_Width & "x" & T_V_Height & " dar=" & T_V_DisplayAspectRatio_String_slash & " sar=" & T_V_PixelAspectRatio & " T_A_Codec_legacy: " & T_A_Codec_legacy & " T_A_Audio_Delay_ms: " & T_A_Audio_Delay_ms & " T_A_Audio_Delay_ms_legacy: " & T_A_Audio_Delay_ms_legacy & " T_A_Video_Delay_ms: " &  T_A_Video_Delay_ms & " T_A_Video_Delay_ms_legacy: " &  T_A_Video_Delay_ms_legacy)
	WScript.StdOut.WriteLine("======================================================================================================================================================")
	WScript.StdOut.WriteLine("V_INCOMING_BITRATE: Using """ & CF_FILE_AbsolutePathName & """ and """ & CF_TARGET_AbsolutePathName & """ The V_INCOMING_BITRATE=""" & V_INCOMING_BITRATE & """")
	WScript.StdOut.WriteLine("" & vrdtvsp_current_datetime_string())
	WScript.StdOut.WriteLine("======================================================================================================================================================")
	'
	' ++++ START do a mediainfo of the TARGET so we can compare them !!! (DGIndex got the FPS wrong)
	If vrdtvsp_DEBUG OR vrdtvsp_show_mediainfo Then
		WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File ---------- doing mediainfo on TARGET """ & CF_TARGET_AbsolutePathName & """ T_V_Codec_legacy=""" & T_V_Codec_legacy & """ ----------")
		vrdtvsp_REM = ""
	Else
		vrdtvsp_REM = "REM "
	End If
	ReDim vrdtvsp_Exec_in_a_DOS_BAT_file_cmd_array(3) ' base 0, so the dimension is always 1 less than the number of commands
	vrdtvsp_Exec_in_a_DOS_BAT_file_cmd_array(0) = "REM " & vrdtvsp_current_datetime_string()
	vrdtvsp_Exec_in_a_DOS_BAT_file_cmd_array(1) = "ECHO !DATE! !TIME!"
	vrdtvsp_Exec_in_a_DOS_BAT_file_cmd_array(2) = vrdtvsp_REM & """" & vrdtvsp_mediainfoexe64 & """ --Legacy """ & CF_TARGET_AbsolutePathName & """"
	vrdtvsp_Exec_in_a_DOS_BAT_file_cmd_array(3) = vrdtvsp_REM & """" & vrdtvsp_mediainfoexe64 & """ --Legacy ""--Inform=Video;%FrameRate%\r\n"" """ & CF_TARGET_AbsolutePathName & """"
	vrdtvsp_Exec_in_a_DOS_BAT_file_cmd_array(3) = Replace(vrdtvsp_Exec_in_a_DOS_BAT_file_cmd_array(3), "%", "%%", 1, -1, vbTextCompare) ' just for the mediainfo command run from WITHIN in a .BAT file ' for the final return status to be good, this must be the final command in the array
	CF_object_saved_ffmpeg_commands.WriteLine("REM")
	for iii=0 to 3
		CF_object_saved_ffmpeg_commands.WriteLine(vrdtvsp_Exec_in_a_DOS_BAT_file_cmd_array(iii))
	Next
	CF_object_saved_ffmpeg_commands.WriteLine("REM")
	If vrdtvsp_DEBUG OR vrdtvsp_show_mediainfo Then
		CF_exe_status = vrdtvsp_Exec_in_a_DOS_BAT_file(vrdtvsp_Exec_in_a_DOS_BAT_file_cmd_array, True, True) ' print .bat, do the commands, print .log
	End If
	Erase vrdtvsp_Exec_in_a_DOS_BAT_file_cmd_array
	' ++++ END do a mediainfo of the TARGET so we can compare them !!! (DGIndex got the FPS wrong)
	'
	'------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	' after ffmpeg, do an ADSCAN over the TARGET file and save the .vprj in the target folder as an "associated .vprj" which will be picked up by auto-vprj-processing during bulk file renames :)
	If CF_do_Adscan Then
		' ++++ START Run the ADSCAN command
		ff_timerStart = Timer
		vrdtvsp_status = vrdtvsp_delete_a_file(vrdtvsp_logfile_wildcard_ADSCAN, True) ' True=silently delete it	' is a wildcard, in fso.DeleteFile the filespec can contain wildcard characters in the last path component
		If vrd_version_for_adscan = 5 Then
			CF_exe_cmd_string = "cscript //Nologo """ & vrdtvsp_path_for_adscan_vbs & """ """ & CF_TARGET_AbsolutePathName & """  """ & CF_vprj_AbsolutePathName & """ /q"
		ElseIf vrd_version_for_adscan = 6 Then ' v6 uses a different scheme, we have a custom temporary script we created
			CF_exe_cmd_string = "cscript //Nologo """ & vrdtvsp_path_for_adscan_vbs & """ """ & CF_TARGET_AbsolutePathName & """  """ & CF_vprj_AbsolutePathName & """ """ & const_vrd6_adscan_profile_name & """"
		Else
			WScript.StdOut.WriteLine("VRDTVSP ERROR - vrdtvsp_path_for_adscan_vbs can only be 5 or 6 ... Aborting ...")
			Wscript.Echo "Error 17 = cannot perform the requested operation"
			On Error goto 0
			WScript.Quit 17 ' Error 17 = cannot perform the requested operation
		End If
		If vrdtvsp_DEBUG Then 
			WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_Convert_File """ & CF_TARGET_AbsolutePathName & """ V_Codec_legacy=""" & V_Codec_legacy & """ do ADSCAN with CF_exe_cmd_string=""" & CF_exe_cmd_string & """")
		End If
		' save ADSCAN command
		CF_object_saved_ffmpeg_commands.WriteLine("REM")
		CF_object_saved_ffmpeg_commands.WriteLine("REM Do the ADSCAN for """ & CF_TARGET_AbsolutePathName & """ ... ")
		CF_object_saved_ffmpeg_commands.WriteLine("REM")
		CF_object_saved_ffmpeg_commands.WriteLine("DEL /F """ & CF_vprj_AbsolutePathName & """")
		CF_object_saved_ffmpeg_commands.WriteLine("REM ====================================================================================================================================================================")
		CF_object_saved_ffmpeg_commands.WriteLine("ECHO !DATE! !TIME!")
		CF_object_saved_ffmpeg_commands.WriteLine(CF_exe_cmd_string) ' write the ADSCAN String to be executed
		CF_object_saved_ffmpeg_commands.WriteLine("ECHO !DATE! !TIME!")
		CF_object_saved_ffmpeg_commands.WriteLine("REM ====================================================================================================================================================================")
		CF_object_saved_ffmpeg_commands.WriteLine("REM")
		' do the actual ADCSAN command (delete the vprj file first)
		WScript.StdOut.WriteLine("======================================================================================================================================================")
		WScript.StdOut.WriteLine("" & vrdtvsp_current_datetime_string())
		WScript.StdOut.WriteLine("******************** Start of run ADSCAN """ & CF_exe_cmd_string & """ :")
		WScript.StdOut.WriteLine("Doing ADSCAN for """ & CF_TARGET_AbsolutePathName & """ ... ")
		WScript.StdOut.WriteLine("ADSCAN command: " & CF_exe_cmd_string)
		''' vrdtvsp_status = vrdtvsp_delete_a_file(CF_vprj_AbsolutePathName, True) ' True=silently delete it ' - the old way of doing it
		''' CF_exe_status = vrdtvsp_exec_a_command_and_show_stdout_stderr(CF_exe_cmd_string) ' - the old way of doing it
		ReDim vrdtvsp_Exec_in_a_DOS_BAT_file_cmd_array(3) ' base 0, so the dimension is always 1 less than the number of commands
		vrdtvsp_Exec_in_a_DOS_BAT_file_cmd_array(0) = "REM " & vrdtvsp_current_datetime_string()
		vrdtvsp_Exec_in_a_DOS_BAT_file_cmd_array(1) = "ECHO !DATE! !TIME!"
		vrdtvsp_Exec_in_a_DOS_BAT_file_cmd_array(2) = "DEL /F """ & CF_vprj_AbsolutePathName & """"
		vrdtvsp_Exec_in_a_DOS_BAT_file_cmd_array(3) = CF_exe_cmd_string ' for the final return status to be good, this must be the final command in the array
		CF_exe_status = vrdtvsp_Exec_in_a_DOS_BAT_file(vrdtvsp_Exec_in_a_DOS_BAT_file_cmd_array, True, True) ' print .bat, do the commands, print .log - the safer way of doing it
		Erase vrdtvsp_Exec_in_a_DOS_BAT_file_cmd_array
		WScript.StdOut.WriteLine("******************** Finished run ADSCAN """ & CF_exe_cmd_string & """ :")
		WScript.StdOut.WriteLine("Done ADSCAN for """ & CF_TARGET_AbsolutePathName & """ ... ")
		WScript.StdOut.WriteLine("ADSCAN command: " & CF_exe_cmd_string)
		WScript.StdOut.WriteLine("" & vrdtvsp_current_datetime_string())
		WScript.StdOut.WriteLine("======================================================================================================================================================")
		If CF_exe_status <> 0 OR NOT fso.FileExists(CF_vprj_AbsolutePathName) Then
			If vrdtvsp_DEBUG Then WScript.StdOut.WriteLine("VRDTVSP DEBUG: ERROR vrdtvsp_Convert_File - Error - Failed to ADSCAN, ExitStatus=" & CF_exe_status & " """ & CF_TARGET_AbsolutePathName & """ V_Codec_legacy=""" & V_Codec_legacy & """ CF_exe_cmd_string=""" & CF_exe_cmd_string & """")
			WScript.StdOut.WriteLine("VRDTVSP ERROR vrdtvsp_Convert_File - Error - Failed to ADSCAN, ExitStatus=" & CF_exe_status & " """ & CF_TARGET_AbsolutePathName & """ V_Codec_legacy=""" & V_Codec_legacy & """ CF_exe_cmd_string=""" & CF_exe_cmd_string & """")
			If vrdtvsp_DEVELOPMENT_NO_ACTIONS Then ' DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV 
				Wscript.Echo "Error 17 = cannot perform the requested operation"
				On Error goto 0
				WScript.Quit 17 ' Error 17 = cannot perform the requested operation
			End If
			vrdtvsp_status = vrdtvsp_move_files_to_folder(CF_FILE_AbsolutePathName, CF_failed_conversion_TS_Folder)
			vrdtvsp_status = vrdtvsp_move_files_to_folder(CF_vprj_AbsolutePathName, CF_failed_conversion_TS_Folder)
			'vrdtvsp_status = vrdtvsp_delete_a_file(CF_DGI_AbsolutePathName, True)
			'vrdtvsp_status = vrdtvsp_delete_a_file(CF_VPY_AbsolutePathName, True)
			'vrdtvsp_status = vrdtvsp_delete_a_file(CF_QSF_AbsolutePathName, True)
			WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File: - ???????????????????? moved FAILED CONVERSION file to FAILED folder: """ & CF_FILE_AbsolutePathName & """ to """ & CF_failed_conversion_TS_Folder & """")
			WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File: - ???????????????????? moved FAILED CONVERSION file to FAILED folder: """ & CF_FILE_AbsolutePathName & """ to """ & CF_failed_conversion_TS_Folder & """")
			WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File: - ???????????????????? moved FAILED CONVERSION file to FAILED folder: """ & CF_FILE_AbsolutePathName & """ to """ & CF_failed_conversion_TS_Folder & """")
			WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File: - ???????????????????? moved FAILED CONVERSION file to FAILED folder: """ & CF_FILE_AbsolutePathName & """ to """ & CF_failed_conversion_TS_Folder & """")
			WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File: - ???????????????????? moved FAILED CONVERSION file to FAILED folder: """ & CF_FILE_AbsolutePathName & """ to """ & CF_failed_conversion_TS_Folder & """")
			WScript.StdOut.WriteLine(" ")
			WScript.StdOut.WriteLine("vrdtvsp_Convert_File FINISHED " & vrdtvsp_current_datetime_string())
			WScript.StdOut.WriteLine("" & vrdtvsp_current_datetime_string())
			WScript.StdOut.WriteLine("======================================================================================================================================================")
			WScript.StdOut.WriteLine(" ")
			vrdtvsp_Convert_File = -1
			Exit Function
		End If
		ff_timerEnd = Timer
		WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File: - ADSCAN command completed with Elapsed Time " & vrdtvsp_Calculate_ElapsedTime_string(ff_timerStart, ff_timerEnd))
		' ++++ END Run the ADSCAN command
	End If
	'
	'???????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????
	'???????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????
	'
	' Cleanup files
	CF_object_saved_ffmpeg_commands.WriteLine("REM")
	CF_object_saved_ffmpeg_commands.WriteLine("DEL /F """ & CF_DGI_AbsolutePathName & """")
	CF_object_saved_ffmpeg_commands.WriteLine("DEL /F """ & CF_VPY_AbsolutePathName & """")
	CF_object_saved_ffmpeg_commands.WriteLine("DEL /F """ & CF_QSF_AbsolutePathName & """")
	CF_object_saved_ffmpeg_commands.WriteLine("REM")
	vrdtvsp_status = vrdtvsp_delete_a_file(CF_DGI_AbsolutePathName, True)
	vrdtvsp_status = vrdtvsp_delete_a_file(CF_VPY_AbsolutePathName, True)
	vrdtvsp_status = vrdtvsp_delete_a_file(CF_QSF_AbsolutePathName, True)
	If vrdtvsp_DEVELOPMENT_NO_ACTIONS Then ' DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV 
		WScript.StdOut.WriteLine("VRDTVSP DEV: vrdtvsp_DEVELOPMENT_NO_ACTIONS: DEV: vrdtvsp_Convert_File NOT moving file to DONE folder: """ & CF_FILE_AbsolutePathName & """ to """ & CF_done_TS_Folder & """")
	Else
		vrdtvsp_status = vrdtvsp_move_files_to_folder(CF_FILE_AbsolutePathName, CF_done_TS_Folder)
		WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_Convert_File: moved file to DONE folder: """ & CF_FILE_AbsolutePathName & """ to """ & CF_done_TS_Folder & """")
	End If
	WScript.StdOut.WriteLine(" ")
	WScript.StdOut.WriteLine("vrdtvsp_Convert_File FINISHED " & vrdtvsp_current_datetime_string())
	WScript.StdOut.WriteLine("" & vrdtvsp_current_datetime_string())
	WScript.StdOut.WriteLine("======================================================================================================================================================")
	WScript.StdOut.WriteLine(" ")
	vrdtvsp_Convert_File = 0	
End Function
'
Function vrdtvsp_writeline_for_vpy (vpy_filename_object, bat_filename_object, a_vpy_statement, prepend_string, append_string)
	' Write vpy statements to a "normal" .vpy file and ".BAT-escaped" to the batch file used to re-create the .vpy file
	' Parameters
	'		vpy_filename_object		ALREADY OPENED FOR WRITE
	'		bat_filename_object		ALREADY OPENED FOR WRITE
	'		prepend_string			eg "ECHO " including a trailing space
	'		append_string			eg " >> "!_VPY_file!" 2>&1"  including a trailing space
	Dim escaped_vpy_statement
	If vrdtvsp_DEBUG Then
		WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_writeline_for_vpy about to writeline vpy_filename_object       a_vpy_statement" & Space(Len(prepend_string)) & "=<" & a_vpy_statement & ">")
	End If
	vpy_filename_object.WriteLine(a_vpy_statement)
	escaped_vpy_statement = a_vpy_statement
	escaped_vpy_statement = Replace(escaped_vpy_statement, "(", "^(", 1, -1, vbTextCompare)
	escaped_vpy_statement = Replace(escaped_vpy_statement, ")", "^)", 1, -1, vbTextCompare)
	escaped_vpy_statement = Replace(escaped_vpy_statement, "<", "^<", 1, -1, vbTextCompare)
	escaped_vpy_statement = Replace(escaped_vpy_statement, ">", "^>", 1, -1, vbTextCompare)
	escaped_vpy_statement = prepend_string & escaped_vpy_statement & append_string
	If vrdtvsp_DEBUG Then
		WScript.StdOut.WriteLine("VRDTVSP DEBUG: vrdtvsp_writeline_for_vpy about to writeline bat_filename_object escaped_vpy_statement=<" & escaped_vpy_statement & ">")
	End If
	bat_filename_object.WriteLine(escaped_vpy_statement)
	vrdtvsp_writeline_for_vpy = 0
End Function
'
Function vrdtvsp_Exec_in_a_DOS_BAT_file (byVAL eiadbf_cmd_string_array, byVAL eiadbf_print_batfile, byVAL eiadbf_print_logfile)
	' Run commands in a DOS .BAT file - use for badly behaved programs like mediainfo and ffmpeg where they never exit properly.
	' Parameters:
	'	eiadbf_cmd		an array of commandstrings to be executed, the exit status is taken from the last one in the array
	'						eg dim x(5) will yield lbound=0, ubound=5
	'	eiadbf_print_batfile	True or False
	'	eiadbf_print_logfile	True or False
	'
	Dim eiadbf_batfilename, eiadbf_batfilename_object
	Dim eiadbf_logfilename, eiadbf_logfilename_object
	Dim eiadbf_cmd_string_for_bat
	Dim eiadbf_lbound, eiadbf_ubound
	Dim eiadbf_object
	Dim i, c
	Dim eiadbf_status, eiadbf_tmp, eiadbf_errorlevel
	'
	eiadbf_batfilename = vrdtvsp_gimme_a_temporary_absolute_filename ("vrdtvsp_Exec_in_a_DOS_BAT_file-" & vrdtvsp_run_datetime) & ".BAT"
	eiadbf_logfilename = vrdtvsp_gimme_a_temporary_absolute_filename ("vrdtvsp_Exec_in_a_DOS_BAT_file-" & vrdtvsp_run_datetime) & ".log"
	eiadbf_status = vrdtvsp_delete_a_file(eiadbf_batfilename, True)
	eiadbf_status = vrdtvsp_delete_a_file(eiadbf_logfilename, True)
	eiadbf_lbound = LBOUND(eiadbf_cmd_string_array)
	eiadbf_ubound = UBOUND(eiadbf_cmd_string_array)
	set eiadbf_batfilename_object = fso.CreateTextFile(eiadbf_batfilename, True, False) ' true to overwrite, false so no unicode please, some things bail with that
	eiadbf_batfilename_object.WriteLine("@ECHO ON")
	eiadbf_batfilename_object.WriteLine("@setlocal ENABLEDELAYEDEXPANSION")
	eiadbf_batfilename_object.WriteLine("@setlocal enableextensions")
	eiadbf_batfilename_object.WriteLine("DEL /F """ & eiadbf_logfilename & """")
	eiadbf_batfilename_object.WriteLine("Set EL=0")
	'eiadbf_batfilename_object.WriteLine("ECHO !DATE! !TIME! STARTED *************************************************************************** >>""" & eiadbf_logfilename & """ 2>&1")
	for i = eiadbf_lbound to eiadbf_ubound STEP 1
		'eiadbf_batfilename_object.WriteLine("ECHO !DATE! !TIME! ------------------------" & " >>""" & eiadbf_logfilename & """ 2>&1")	' redirect both stdout and stderr to the logfile
		eiadbf_batfilename_object.WriteLine("ECHO " & eiadbf_cmd_string_array(i) & " >>""" & eiadbf_logfilename & """ 2>&1")			' redirect both stdout and stderr to the logfile
		eiadbf_batfilename_object.WriteLine(eiadbf_cmd_string_array(i) & " >>""" & eiadbf_logfilename & """ 2>&1")						' redirect both stdout and stderr to the logfile
		eiadbf_batfilename_object.WriteLine("Set EL=%ERRORLEVEL%" & " >>""" & eiadbf_logfilename & """ 2>&1")							' redirect both stdout and stderr to the logfile
		'eiadbf_batfilename_object.WriteLine("ECHO that returned Errorlevel=%EL%" & " >>""" & eiadbf_logfilename & """ 2>&1")			' redirect both stdout and stderr to the logfile
	Next
	'eiadbf_batfilename_object.WriteLine("ECHO !DATE! !TIME! ------------------------" & " >>""" & eiadbf_logfilename & """ 2>&1")	' redirect both stdout and stderr to the logfile
	'eiadbf_batfilename_object.WriteLine("ECHO !DATE! !TIME! FINISHED *************************************************************************** >>""" & eiadbf_logfilename & """ 2>&1")
	eiadbf_batfilename_object.WriteLine("EXIT %EL%")
	eiadbf_batfilename_object.close
	set eiadbf_batfilename_object = Nothing
	'
	If eiadbf_print_batfile Then
		WScript.StdOut.WriteLine("---------- START Content of """ & eiadbf_batfilename & """ Below ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------")
		Set eiadbf_batfilename_object = fso.OpenTextFile(eiadbf_batfilename, ForReading) ' ForReading is global
		Do Until eiadbf_batfilename_object.AtEndOfStream
			eiadbf_tmp = eiadbf_batfilename_object.ReadLine
			WScript.StdOut.WriteLine(eiadbf_tmp)
		Loop			
		eiadbf_status = eiadbf_batfilename_object.Close
		Set eiadbf_batfilename_object = Nothing
		WScript.StdOut.WriteLine("---------- END   Content of """ & eiadbf_batfilename & """ Above ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------")
	End If
	'
	' Now .Run the .bat
	WScript.StdOut.WriteLine("########## Start .Run """ & eiadbf_batfilename & """ " & vrdtvsp_current_datetime_string() & " ########################################################################################################################################################################################################################################")
	eiadbf_errorlevel = wso.Run("CMD /C """ & eiadbf_batfilename & """", 7, True) '(strCommand, [intWindowStyle], [bWaitOnReturn]) ' https://ss64.com/vb/run.html
	WScript.StdOut.WriteLine("########## End   .Run """ & eiadbf_batfilename & """ " & vrdtvsp_current_datetime_string() & " Final Exit status :" & eiadbf_errorlevel & " ########################################################################################################################################################################################################################################")
	'
	If eiadbf_print_logfile Then
		WScript.StdOut.WriteLine("++++++++++ START Content of """ & eiadbf_logfilename & """ Below ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++")
		Set eiadbf_logfilename_object = fso.OpenTextFile(eiadbf_logfilename, ForReading) ' ForReading is global
		Do Until eiadbf_logfilename_object.AtEndOfStream
			eiadbf_tmp = eiadbf_logfilename_object.ReadLine
			WScript.StdOut.WriteLine(eiadbf_tmp)
		Loop			
		eiadbf_status = eiadbf_logfilename_object.Close
		Set eiadbf_logfilename_object = Nothing
		WScript.StdOut.WriteLine("++++++++++ END   Content of """ & eiadbf_logfilename & """ Above ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++")
	End If
	eiadbf_status = vrdtvsp_delete_a_file(eiadbf_batfilename, True)
	eiadbf_status = vrdtvsp_delete_a_file(eiadbf_logfilename, True)
	vrdtvsp_Exec_in_a_DOS_BAT_file = eiadbf_errorlevel
End Function
'
Function vrdtvsp_create_custom_adscan_script_vrd6()
	' Create a custome Adscan Script for use with VRD v6 (VideoReDo does not provide a v6 one which works)
	' Return the Absolute filename of the script
	Dim ccvas_Absolute_script_name
	Dim ccvas_object
	Dim ccvas_status
	Dim ccvas(), i, c
	'
	ccvas_Absolute_script_name = vrdtvsp_gimme_a_temporary_absolute_filename("vrdtvsp_custom_vrd6_adscan_script-" & vrdtvsp_run_datetime) & ".vbs"
	c = -1 ' base 0
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "Option Explicit"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "' File: """ & ccvas_Absolute_script_name & """"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "' Example VRD6 VBScript to do AdScan with Adscan Profile"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "' Args(0) is input video file path - a fully qualified path name"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "' Args(1) is path/name of output project file - a fully qualified path name"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "' Args(2) is name of AdScan Output Profile created in VRD v6"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "'"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "Dim Args, argCount"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "Dim inputFile"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "Dim vprjFile"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "Dim adscan_profile_name"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "Dim VideoReDoSilent"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "Dim VideoReDo"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "Dim openflag, closeflag, outputOK, OutputGetState, percentComplete"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "Dim percent"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "Dim i, profile_count, adscan_profile_count, matching_adscan_profile, a_profile_name, is_adscan"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "Dim Adscan_Profile_Names()"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "'"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "Set Args = Wscript.Arguments"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "argCount = Wscript.Arguments.Count"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "If argCount <> 3 Then"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "	Wscript.StdOut.WriteLine(""VRDTVS_VRD6_AdScan: ERROR: arg count should be 3, but is "" & argCount)"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "	Wscript.StdOut.WriteLine(""VRDTVS_VRD6_AdScan:			Args(0) is the fully qualified path/name of the input video file"")"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "	Wscript.StdOut.WriteLine(""VRDTVS_VRD6_AdScan:			Args(1) is the fully qualified path/name of the output project (.vprj) file."")"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "	Wscript.StdOut.WriteLine(""VRDTVS_VRD6_AdScan:			Args(2) is name of AdScan Output Profile already created and saved inside VRD v6"")"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "	Wscript.Quit 5"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "End If"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "'"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "inputFile = Args(0)"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "vprjFile = Args(1)				' including extension .vprj"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "adscan_profile_name = Args(2)"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "'"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "Set VideoReDoSilent = WScript.CreateObject(""VideoReDo6.VideoReDoSilent"")"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "Set VideoReDo = VideoReDoSilent.VRDInterface"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "VideoReDo.ProgramSetAudioAlert(False)"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "'"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "adscan_profile_count = 0"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "profile_count = VideoReDo.ProfilesGetCount()"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "For i = 0 to profile_count-1"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "	a_profile_name = VideoReDo.ProfilesGetProfileName( i )"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "	is_adscan = VideoReDo.ProfilesGetProfileIsAdScan( i )"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "	If ( is_adscan ) Then"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "		adscan_profile_count = adscan_profile_count + 1"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "		ReDim Preserve Adscan_Profile_Names(adscan_profile_count-1) ' base 0, remember"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "		Adscan_Profile_Names(adscan_profile_count-1) = a_profile_name"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "	End If"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "Next"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "If adscan_profile_count < 1 Then"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "	Wscript.StdOut.WriteLine(""VRDTVS_VRD6_AdScan: ERROR: no VRD6 AdScan profiles were returned by VRD v6"")"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "	Wscript.StdOut.WriteLine(""VRDTVS_VRD6_AdScan: Exiting with errorlevel code 5"")"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "	'on error resume Next"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "	on error goto 0"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "	VideoReDo.ProgramExit()"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "	on error goto 0"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "	Wscript.StdOut.WriteLine(""VRDTVS_VRD6_AdScan: Exiting with errorlevel code 5"")"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "	Wscript.Quit 5"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "End If"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "matching_adscan_profile = False"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "For i = 0 to (adscan_profile_count-1)"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "	If adscan_profile_name = Adscan_Profile_Names(i) Then"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "		matching_adscan_profile = True"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "		Exit For"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "	End If"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "Next"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "If NOT matching_adscan_profile Then"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "	Wscript.StdOut.WriteLine(""VRDTVS_VRD6_AdScan: ERROR: no VRD6 AdScan profile was located matching your specified profile: """""" & adscan_profile_name & """""""")"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "	For i = 0 to profile_count-1"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "		a_profile_name = VideoReDo.ProfilesGetProfileName( i )"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "		is_adscan = VideoReDo.ProfilesGetProfileIsAdScan( i )"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "		If ( is_adscan ) Then"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "			adscan_profile_count = adscan_profile_count + 1"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "			Wscript.StdOut.WriteLine(""VRDTVS_VRD6_AdScan: Profile ("" & i & "")="""""" & a_profile_name & """""" is an adscan profile"")"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "		End If"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "	Next"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "	Wscript.StdOut.WriteLine(""VRDTVS_VRD6_AdScan: Adscan Profile count: "" & adscan_profile_count )"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "	Wscript.StdOut.WriteLine(""VRDTVS_VRD6_AdScan: Exiting with errorlevel code 5"")"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "	on error resume Next"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "	VideoReDo.ProgramExit()"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "	on error goto 0"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "	Wscript.StdOut.WriteLine(""VRDTVS_VRD6_AdScan: Exiting with errorlevel code 5"")"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "	Wscript.Quit 5"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "End If"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "'"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "VideoReDo.ProgramSetAudioAlert(False)"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "openflag = VideoReDo.FileOpen(inputFile, False) ' False means not QSF mode"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "If openflag = False Then"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "	Wscript.StdOut.WriteLine(""VRDTVS_VRD6_AdScan: ERROR: VideoReDo failed to open file: """""" & inputFile & """""""")"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "	'on error resume Next"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "	on error goto 0"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "	VideoReDo.ProgramExit()"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "	on error goto 0"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "	Wscript.StdOut.WriteLine(""VRDTVS_VRD6_AdScan: Exiting with errorlevel code 5"")"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "	Wscript.Quit 5"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "End If"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "outputOK = VideoReDo.FileSaveAs(vprjFile, adscan_profile_name)"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "If NOT outputOK = True Then"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "	Wscript.StdOut.WriteLine(""VRDTVS_VRD6_AdScan: ERROR: VideoReDo failed to create AdScan file: """""" & vprjFile & """""" using profile:"""""" & adscan_profile_name & """""""")"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "	'on error resume Next"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "	on error goto 0"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "	closeflag = VideoReDo.FileClose()"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "	VideoReDo.ProgramExit()"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "	on error goto 0"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "	Wscript.StdOut.WriteLine(""VRDTVS_VRD6_AdScan: Exiting with errorlevel code 5"")"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "	Wscript.Quit 5"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "End If"

	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "Wscript.StdOut.Write(""VRDTVS_VRD6_AdScan: working: "")"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "'Wscript.StdOut.Write(""VRDTVS_VRD6_AdScan: Percent Complete: "")"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "OutputGetState = VideoRedo.OutputGetState()"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "While( OutputGetState <> 0 )"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "	'on error resume Next"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "	on error goto 0"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "	percentComplete = CLng(VideoReDo.OutputGetPercentComplete())"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "	'if NOT err.number = 0 then"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "	'	percentComplete = 0"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "	'end if"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "	'Wscript.StdOut.Write("" "" & percent & ""% "")"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "	'Wscript.StdOut.Write(""."")"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "	Wscript.StdOut.Write( ""."" & OutputGetState)"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "	on error goto 0"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "	Wscript.Sleep 2000"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "	OutputGetState = VideoRedo.OutputGetState()"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "Wend"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "closeflag = VideoReDo.FileClose()"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "Wscript.StdOut.WriteLine( ""."" & OutputGetState & ""."")"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "Wscript.StdOut.WriteLine(""VRDTVS_VRD6_AdScan AdScan 100% Complete."")"
	
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "Wscript.StdOut.WriteLine(""VRDTVS_VRD6_AdScan: Exiting"")"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "	'on error resume Next"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "	on error goto 0"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "VideoReDo.ProgramExit()"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "on error goto 0"
	c=c+1 : ReDim Preserve ccvas(c) : ccvas(c) = "Wscript.Quit 0"
	' Create the new custom ADSCAN script in the nominated file
	ccvas_status = vrdtvsp_delete_a_file(ccvas_Absolute_script_name, True) 	' delete the file first
	set ccvas_object = fso.CreateTextFile(ccvas_Absolute_script_name, True, False) ' *** vapoursynth fails with unicode input file *** [ filename, Overwrite[, Unicode]])
	If ccvas_object is Nothing  Then ' Something went wrong with creating the file
		If vrdtvsp_DEBUG Then WScript.StdOut.WriteLine("VRDTVSP DEBUG: VRDTVSP ERROR vrdtvsp_create_custom_adscan_script_vrd6 - Error - Nothing object returned from fso.CreateTextFile for file """ & ccvas_Absolute_script_name & """... Aborting ...")
		WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_create_custom_adscan_script_vrd6 - Error - Nothing object returned from fso.CreateTextFile for file """ & ccvas_Absolute_script_name & """... Aborting ...")
		Wscript.Echo "Error 17 = cannot perform the requested operation"
		On Error goto 0
		WScript.Quit 17 ' Error 17 = cannot perform the requested operation
	End If
	For i = Lbound(ccvas) to UBound(ccvas) Step 1
		ccvas_object.WriteLine ccvas(i)
	Next
	ccvas_object.close
	set ccvas_object = Nothing
	vrdtvsp_create_custom_adscan_script_vrd6 = ccvas_Absolute_script_name
End Function
'
Function vrdtvsp_create_custom_QSF_vbscript_vrd_5_AND_6( byVAL ccqsfs_vrd_version )
	' Create a custom QSF Script for use with VRD v6
	' Return the Absolute filename of the script
	Dim ccqsfs_Absolute_script_name
	Dim ccqsfs_object
	Dim ccqsfs_status
	Dim ccqsfs(), i, c
	'
	ccqsfs_Absolute_script_name = vrdtvsp_gimme_a_temporary_absolute_filename("vrdtvsp_custom_vrd" & ccqsfs_vrd_version & "_QSF_script-" & vrdtvsp_run_datetime) & ".vbs"
	c = -1 ' base 0
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "Option Explicit"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "' File: """ & ccqsfs_Absolute_script_name & """"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "' Example VRD VBScript to do QSF with QSF Profile and save an XML file of characteristics"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "' Args(0) is input video file path - a fully qualified path name"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "' Args(1) is path/name of output QSF'd file - a fully qualified path name"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "' Args(2) is name of QSF Output Profile created in VRD v6"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "' Args(3) is path/name of a file of XML associated with the output QSF'd file - a fully qualified path name"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "' Note: An additional file is created, with the same full filename/ext as Args(1) with .xml added on the end."
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "'       This .xml file contains complete info for the most recently completed output file "
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "'       (hopefully the QSF) from a call to OutputGetCompletedInfo() or FileGetOpenedFileProgramInfo()."
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "'       With any luck, the timing of concurrent workflow doing calls works out for us, although we should still check the filename from the XML."
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "'"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "' Example Returned xml string: from VideoReDo.FileGetOpenedFileProgramInfo()"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "' This is a well-formed single-item XML string, which make it really easy to find things"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "'<?xml version=""1.0"" encoding=""UTF-8"" standalone=""yes""?>"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "'<VRDProgramInfo>"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "'  <FileName d=""Name"">somefilename.qsf.vrd6.mp4</FileName>"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "'  <FileSize f=""0.029 GB"" d=""Size"">28519136</FileSize>"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "'  <ProgramDuration f=""00:01:04.84"" d=""Duration"" total_frames=""1622"">5835601</ProgramDuration>"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "'  <FileType d=""Mux type"">MP4</FileType>"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "'  <Video>"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "'    <Encoding>H.264</Encoding>"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "'    <VideoStreamID>x201</VideoStreamID>"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "'    <FrameRate f=""25.00 fps"" d=""Frame rate"">25.000000</FrameRate>"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "'    <constant_frame_rate_flag d=""Frame rate flag"">Constant</constant_frame_rate_flag>"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "'    <EncodingDimensions d=""Encoding size"" width=""1920"" height=""1080"">1920 x 1080</EncodingDimensions>"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "'    <AspectRatio d=""Aspect ratio"">16:9</AspectRatio>"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "'    <HeaderBitRate f=""25.000 Mbps"" d=""Header bit rate"">25000000</HeaderBitRate>"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "'    <VBVBufferSize f=""572 KBytes"" d=""VBV buffer"">572</VBVBufferSize>"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "'    <Profile>High/4.0</Profile>"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "'    <Progressive f=""Interlaced"">False</Progressive>"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "'    <Chroma chroma_value=""1"">4:2:0</Chroma>"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "'    <EntropyCodingMode d=""Entropy mode"">CABAC</EntropyCodingMode>"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "'    <EstimatedVideoBitrate f=""2.992 Mbps"" d=""Bit rate"">2992213</EstimatedVideoBitrate>"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "'  </Video>"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "'  <AudioStreams>"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "'    <AudioStream StreamNumber=""1"" Primary=""true"">"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "'    <AudioCodec d=""Codec"">AC3</AudioCodec>"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "'    <Format>AC3 stream</Format>"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "'    <AudioChannels d=""Channels"">5.1</AudioChannels>"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "'    <Language>eng</Language>"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "'    <PID>x202</PID>"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "'    <PESStreamId d=""PES Stream Id"">xBD</PESStreamId>"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "'    <AudioBitRate f=""448 Kbps"" d=""Bit rate"">448000</AudioBitRate>"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "'    <AudioSampleRate d=""Sampling rate"">48000</AudioSampleRate>"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "'    <BitsPerSample d=""Sample size"" f=""16 bits"">16</BitsPerSample>"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "'    </AudioStream>"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "'    </AudioStreams>"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "'  <SubtitleStreams/>"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "'</VRDProgramInfo>"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "'"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "' Example Returned xml string: from VideoReDo.OutputGetCompletedInfo()"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "' VideoReDo.OutputGetCompletedInfo() MUST be called immediately AFTER a QSF FileSaveAs and BEFORE the .Close of the source file for the QSF"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "' This is a well-formed single-item XML string, which make it really easy to find things"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "'<VRDOutputInfo outputFile=""G:\HDTV\000-TO-BE-PROCESSED\zzz-TEST\VRDTVSP-Source\News-National_Nine_News_Afternoon_Edition.2021-02-05.ts.QSF"">"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "'  <OutputType desc=""Output format:"" hidden=""1"">MP4</OutputType>"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "'  <OutputDurationSecs desc=""Video length:"" val_type=""int"" hidden=""1"">65</OutputDurationSecs>"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "'  <OutputDuration desc=""Video length:"">00:01:05</OutputDuration>"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "'  <OutputSizeMB desc=""Video size:"" val_type=""int"" val_format=""%dMB"">27</OutputSizeMB>"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "'  <OutputSceneCount desc=""Output scenes:"" val_type=""int"">1</OutputSceneCount>"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "'  <VideoOutputFrameCount desc=""Video output frames:"" val_type=""int"">1625</VideoOutputFrameCount>"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "'  <AudioOutputFrameCount desc=""Audio output frames:"" val_type=""int"">2033</AudioOutputFrameCount>"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "'  <ProcessingTimeSecs desc=""Processing time (secs):"" val_type=""int"">1</ProcessingTimeSecs>"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "'  <ProcessedFramePerSec desc=""Processed frames/sec:"" val_type=""float"" val_format=""%.2f"">1625.000000</ProcessedFramePerSec>"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "'  <ActualVideoBitrate desc=""Actual Video Bitrate:"" desc_format=""%24s"" val_type=""float"" val_format=""%0.2f Mbps"">2.912357</ActualVideoBitrate>"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "'  <lkfs_values hidden=""1""/>"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "'  <audio_level_changes hidden=""1""/>"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "'</VRDOutputInfo>"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "'"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "Dim Args, argCount"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "Dim inputFile"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "Dim qsfFile"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "Dim QSF_profile_name"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "Dim xmlFile"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "Dim VideoReDoSilent"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "Dim VideoReDo"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "Dim openflag, closeflag, outputOK, OutputGetState, percentComplete"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "Dim percent"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "Dim i, profile_count, QSF_profile_count, matching_QSF_profile, a_profile_name, is_QSF"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "Dim QSF_Profile_Names()"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "Dim xml_string, xml_string_openedfile, xml_string_completedfile"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "Dim xmlDoc,	xml_status, xml_objErr, xml_errorCode, xml_reason"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "Dim actual_outputFile, actual_VideoOutputFrameCount, actual_ActualVideoBitrate"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "Dim estimated_outputFile, estimated_VideoOutputFrameCount, estimated_ActualVideoBitrate"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "Dim fso, fileObj"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "'"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "Set Args = Wscript.Arguments"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "argCount = Wscript.Arguments.Count"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "If argCount <> 4 Then"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "	Wscript.StdOut.WriteLine(""VRDTVS_VRD_QSF: ERROR: arg count should be 3, but is "" & argCount)"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "	Wscript.StdOut.WriteLine(""VRDTVS_VRD_QSF:			Args(0) is the fully qualified path/name of the input video file"")"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "	Wscript.StdOut.WriteLine(""VRDTVS_VRD_QSF:			Args(1) is the fully qualified path/name of the output project (.vprj) file."")"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "	Wscript.StdOut.WriteLine(""VRDTVS_VRD_QSF:			Args(2) is name of QSF Output Profile already created and saved inside VRD v6"")"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "	Wscript.StdOut.WriteLine(""VRDTVS_VRD_QSF:			Args(3) ist he fully qualified path/name of an output XML file of QSF file characteristics."")"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "	Wscript.Quit 5"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "End If"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "'"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "inputFile = Args(0)"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "qsfFile = Args(1)				' including extension .vprj"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "QSF_profile_name = Args(2)"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "xmlFile = Args(3)				' including extension .xml"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "'"
	If ccqsfs_vrd_version = 5 Then
		c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "Set VideoReDoSilent = WScript.CreateObject(""VideoReDo5.VideoReDoSilent"")"
	ElseIf ccqsfs_vrd_version = 6 Then
		c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "Set VideoReDoSilent = WScript.CreateObject(""VideoReDo6.VideoReDoSilent"")"
	Else
		WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_create_custom_QSF_vbscript_vrd_5_AND_6 - Error - VRD version must be 5 or 6, not """ & ccqsfs_vrd_version & """... Aborting ...")
		Wscript.Echo "Error 17 = cannot perform the requested operation"
		On Error goto 0
		WScript.Quit 17 ' Error 17 = cannot perform the requested operation
	End If
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "Set VideoReDo = VideoReDoSilent.VRDInterface"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "VideoReDo.ProgramSetAudioAlert(False)"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "'"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "QSF_profile_count = 0"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "profile_count = VideoReDo.ProfilesGetCount()"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "For i = 0 to profile_count-1"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "	a_profile_name = VideoReDo.ProfilesGetProfileName( i )"
	If ccqsfs_vrd_version = 5 Then
		c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "	is_QSF = True"
	ElseIf ccqsfs_vrd_version = 6 Then
		c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "	is_QSF = NOT VideoReDo.ProfilesGetProfileIsAdScan( i )"
	End If
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "	If ( is_QSF ) Then"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "		QSF_profile_count = QSF_profile_count + 1"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "		ReDim Preserve QSF_Profile_Names(QSF_profile_count-1) ' base 0, remember"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "		QSF_Profile_Names(QSF_profile_count-1) = a_profile_name"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "	End If"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "Next"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "If QSF_profile_count < 1 Then"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "	Wscript.StdOut.WriteLine(""VRDTVS_VRD_QSF: ERROR: no VRD QSF profiles were returned by VRD"")"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "	Wscript.StdOut.WriteLine(""VRDTVS_VRD_QSF: Exiting with errorlevel code 5"")"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "	'on error resume Next"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "	on error goto 0"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "	VideoReDo.ProgramExit()"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "	on error goto 0"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "	Wscript.StdOut.WriteLine(""VRDTVS_VRD_QSF: Exiting with errorlevel code 5"")"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "	Wscript.Quit 5"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "End If"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "matching_QSF_profile = False"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "For i = 0 to (QSF_profile_count-1)"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "	If QSF_profile_name = QSF_Profile_Names(i) Then"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "		matching_QSF_profile = True"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "		Exit For"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "	End If"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "Next"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "If NOT matching_QSF_profile Then"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "	Wscript.StdOut.WriteLine(""VRDTVS_VRD_QSF: ERROR: no VRD QSF profile was located matching your specified profile: """""" & QSF_profile_name & """""""")"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "	For i = 0 to profile_count-1"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "		a_profile_name = VideoReDo.ProfilesGetProfileName( i )"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "		is_QSF = NOT VideoReDo.ProfilesGetProfileIsAdScan( i )"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "		If ( is_QSF ) Then"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "			QSF_profile_count = QSF_profile_count + 1"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "			Wscript.StdOut.WriteLine(""VRDTVS_VRD_QSF: Profile ("" & i & "")="""""" & a_profile_name & """""" is an QSF profile"")"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "		End If"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "	Next"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "	Wscript.StdOut.WriteLine(""VRDTVS_VRD_QSF: QSF Profile count: "" & QSF_profile_count )"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "	Wscript.StdOut.WriteLine(""VRDTVS_VRD_QSF: Exiting with errorlevel code 5"")"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "	'on error resume Next"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "	on error goto 0"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "	VideoReDo.ProgramExit()"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "	on error goto 0"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "	Wscript.StdOut.WriteLine(""VRDTVS_VRD_QSF: Exiting with errorlevel code 5"")"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "	Wscript.Quit 5"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "End If"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "'"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "openflag = VideoReDo.FileOpen(inputFile, True) ' True means QSF mode" 
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "If openflag = False Then"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "	Wscript.StdOut.WriteLine(""VRDTVS_VRD_QSF: ERROR: VideoReDo failed to open file: """""" & inputFile & """""""")"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "	'on error resume Next"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "	on error goto 0"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "	VideoReDo.ProgramExit()"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "	on error goto 0"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "	Wscript.StdOut.WriteLine(""VRDTVS_VRD_QSF: Exiting with errorlevel code 5"")"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "	Wscript.Quit 5"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "End If"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "outputOK = VideoReDo.FileSaveAs(qsfFile, QSF_profile_name) ' save the QSF file"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "If NOT outputOK = True Then"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "	Wscript.StdOut.WriteLine(""VRDTVS_VRD_QSF: ERROR: VideoReDo failed to create QSF file: """""" & qsfFile & """""" using profile:"""""" & QSF_profile_name & """""""")"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "	'on error resume Next"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "	on error goto 0"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "	closeflag = VideoReDo.FileClose()"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "	VideoReDo.ProgramExit()"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "	on error goto 0"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "	Wscript.StdOut.WriteLine(""VRDTVS_VRD_QSF: Exiting with errorlevel code 5"")"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "	Wscript.Quit 5"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "End If"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "Wscript.StdOut.Write(""VRDTVS_VRD_QSF: working: "")"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "'Wscript.StdOut.Write(""VRDTVS_VRD_QSF: Percent Complete: "")"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "OutputGetState = VideoRedo.OutputGetState()"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "While( OutputGetState <> 0 )"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "	'on error resume Next"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "	on error goto 0"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "		percentComplete = CLng(VideoReDo.OutputGetPercentComplete())"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "	'if NOT err.number = 0 then"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "	'	percentComplete = 0"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "	'end if"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "	'Wscript.StdOut.Write("" "" & percent & ""% "")"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "	Wscript.StdOut.Write( ""."" & OutputGetState)"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "	on error goto 0"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "	Wscript.Sleep 2000"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "	OutputGetState = VideoRedo.OutputGetState()"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "Wend"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "Wscript.StdOut.WriteLine( ""."" & OutputGetState & ""."")"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "Wscript.StdOut.WriteLine(""VRDTVS_VRD_QSF: QSF 100% Complete."")"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "' Grab the *Actual* info about the ""VRD latest save"" and hope it is the QSF file)"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "'on error resume Next"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "on error goto 0"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "xml_string_completedfile = """" "
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "xml_string_completedfile = VideoReDo.OutputGetCompletedInfo() ' which is the most recently completed output file (hopefully the QSF file) https://www.videoredo.com/TVSuite_Application_Notes/output_complete_info_xml_forma.html"" "
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "on error goto 0"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "closeflag = VideoReDo.FileClose()"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "Wscript.StdOut.WriteLine("" QSF 100% Complete."")"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "' Grab the *Estimated* info about the QSF file by a quick open and close"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "'on error resume Next"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "on error goto 0"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "openflag = VideoReDo.FileOpen(qsfFile, False)' True means QSF mode"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "xml_string_openedfile = """" "
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "xml_string_openedfile = VideoReDo.FileGetOpenedFileProgramInfo() ' https://www.videoredo.com/TVSuite_Application_Notes/program_info_xml_format.html"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "closeflag = VideoReDo.FileClose()"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "on error goto 0"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "'"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "Wscript.StdOut.WriteLine(""VRDTVS_VRD_QSF: xml_string_completedfile="") "
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "Wscript.StdOut.WriteLine(xml_string_completedfile) "
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "Wscript.StdOut.WriteLine(""VRDTVS_VRD_QSF: xml_string_openedfile="") "
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "Wscript.StdOut.WriteLine(xml_string_openedfile) "
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "'"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "''''' Get Actual data obtained during the QSF process"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "Set xmlDoc = WScript.CreateObject(""Msxml2.DOMDocument.6.0"")"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "xmlDoc.async = False"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "'on error resume Next"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "on error goto 0"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "xml_status = xmlDoc.loadXML(xml_string_completedfile) "
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "Set xml_objErr = xmlDoc.parseError"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "xml_errorCode = xml_objErr.errorCode"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "xml_reason = xml_objErr.reason"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "Set xml_objErr = Nothing"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "Err.clear"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "on error goto 0 "
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "If NOT xml_status Then"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "	Set xmlDoc = Nothing"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "	WScript.StdOut.WriteLine(""VRDTVS_VRD_QSF: ABORTING: Failed to load xml_string_completedfile="" & xml_string_completedfile)"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "	WScript.StdOut.WriteLine(""VRDTVS_VRD_QSF: ABORTING: xml_status: "" & xml_status & "" XML error: "" & xml_errorCode & "" : "" & xml_reason)"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "	Wscript.Echo ""Error 17 = cannot perform the requested operation"""
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "	On Error goto 0"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "	WScript.Quit 17 ' Error 17 = cannot perform the requested operation"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "End If"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "actual_outputFile = gimme_xml_named_attribute(xmlDoc, ""//VRDOutputInfo"", ""outputFile"")"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "actual_VideoOutputFrameCount = gimme_xml_named_value(xmlDoc, ""//VRDOutputInfo/VideoOutputFrameCount"")"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "actual_ActualVideoBitrate = gimme_xml_named_value(xmlDoc, ""//VRDOutputInfo/ActualVideoBitrate"") ' decimal number in Mbps"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "If actual_ActualVideoBitrate = """" Then actual_ActualVideoBitrate = 0"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "actual_ActualVideoBitrate = CLng(CDbl(actual_ActualVideoBitrate) * CDbl(1000000.0)) ' convert from dedcimal Mpbs to bps"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "Set xmlDoc = Nothing"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "'"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "''''' Get Estimated data from a quick open and close of the the QSF file"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "Set xmlDoc = WScript.CreateObject(""Msxml2.DOMDocument.6.0"")"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "xmlDoc.async = False"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "'on error resume Next"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "on error goto 0"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "xml_status = xmlDoc.loadXML(xml_string_openedfile) "
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "Set xml_objErr = xmlDoc.parseError"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "xml_errorCode = xml_objErr.errorCode"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "xml_reason = xml_objErr.reason"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "Set xml_objErr = Nothing"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "Err.clear"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "on error goto 0 "
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "If NOT xml_status Then"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "	Set xmlDoc = Nothing"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "	WScript.StdOut.WriteLine(""VRDTVS_VRD_QSF: ABORTING: Failed to load xml_string_openedfile="" & xml_string_openedfile)"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "	WScript.StdOut.WriteLine(""VRDTVS_VRD_QSF: ABORTING: xml_status: "" & xml_status & "" XML error: "" & xml_errorCode & "" : "" & xml_reason)"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "	Wscript.Echo ""Error 17 = cannot perform the requested operation"""
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "	On Error goto 0"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "	WScript.Quit 17 ' Error 17 = cannot perform the requested operation"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "End If"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "estimated_outputFile = gimme_xml_named_value(xmlDoc, ""//VRDProgramInfo/FileName"")"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "estimated_VideoOutputFrameCount = gimme_xml_named_attribute(xmlDoc, ""//VRDProgramInfo/ProgramDuration"", ""total_frames"")"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "estimated_ActualVideoBitrate = gimme_xml_named_value(xmlDoc, ""//VRDProgramInfo/Video/EstimatedVideoBitrate"") ' decimal number in Mbps"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "Set xmlDoc = Nothing"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "'"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "' Write our own version of the XML values to the specified XML file so that the calling script can read them later"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "Set fso = CreateObject(""Scripting.FileSystemObject"")"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "Set fileObj = fso.CreateTextFile(xmlFile, True, False) ' *** vapoursynth fails with unicode input file *** [ filename, Overwrite[, Unicode]])"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "If Ucase(actual_outputFile) = Ucase(qsfFile) Then ' Use the Actual QSF values"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "	fileObj.WriteLine(""<QSFinfo>"")"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "	fileObj.WriteLine(""   <type>actual</actual_type>"")"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "	fileObj.WriteLine(""   <outputFile>"""""" & actual_outputFile & """"""</outputFile>"")"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "	fileObj.WriteLine(""   <VideoOutputFrameCount>"" & actual_VideoOutputFrameCount & ""</VideoOutputFrameCount>"")"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "	fileObj.WriteLine(""   <Bitrate>"" & actual_ActualVideoBitrate & ""<Bitrate>"")"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "	fileObj.WriteLine(""</QSFinfo>"")"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "Else ' Use the Estimated QSF values"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "	fileObj.WriteLine(""   <QSFinfo>"")"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "	fileObj.WriteLine(""   <type>estimated</type>"")"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "	fileObj.WriteLine(""   <outputFile>"""""" & estimated_outputFile & """"""</outputFile>"")"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "	fileObj.WriteLine(""   <VideoOutputFrameCount>"" & estimated_VideoOutputFrameCount & ""</VideoOutputFrameCount>"")"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "	fileObj.WriteLine(""   <Bitrate>"" & estimated_ActualVideoBitrate & ""<Bitrate>"")"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "	fileObj.WriteLine(""</QSFinfo>"")"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "End If"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "fileObj.close"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "Set fileObj = Nothing"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "Set fso = Nothing"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "'"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "Wscript.StdOut.WriteLine(""VRDTVS_VRD_QSF: actual_outputFile="""""" & actual_outputFile & """""""") "
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "Wscript.StdOut.WriteLine(""VRDTVS_VRD_QSF: actual_VideoOutputFrameCount="" & actual_VideoOutputFrameCount) "
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "Wscript.StdOut.WriteLine(""VRDTVS_VRD_QSF: actual_ActualVideoBitrate="" & actual_ActualVideoBitrate) "
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "Wscript.StdOut.WriteLine(""VRDTVS_VRD_QSF: estimated_outputFile="""""" & estimated_outputFile & """""""") "
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "Wscript.StdOut.WriteLine(""VRDTVS_VRD_QSF: estimated_VideoOutputFrameCount="" & estimated_VideoOutputFrameCount) "
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "Wscript.StdOut.WriteLine(""VRDTVS_VRD_QSF: estimated_ActualVideoBitrate="" & estimated_ActualVideoBitrate) "
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "'"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "Wscript.StdOut.WriteLine(""VRDTVS_VRD_QSF: Exiting"")"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "'on error resume Next"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "on error goto 0"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "VideoReDo.ProgramExit()"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "on error goto 0"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "Wscript.Quit 0"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "Function gimme_xml_named_value (xmlDoc_object, byVAL xml_item_name) ' assumes the xml doc is already loaded in xmlDoc_object"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "	'	Parameters:"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "	'		xmlDoc_object 	the DOM xml object with the xml string already loaded"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "	'		xml_item_name 	a string like //VRDProgramInfo/Video/EstimatedVideoBitrate"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "	Dim item_nNode, item_text"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "	Set item_nNode = xmlDoc_object.selectsinglenode(xml_item_name) ' eg '//VRDProgramInfo/Video/EstimatedVideoBitrate' CAREFUL, this is case sensitive"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "	If item_nNode is Nothing Then"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "		WScript.StdOut.WriteLine(""ABORTING: Could not find XML node "" & xml_item_name & "" in xmlDoc_object"")"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "		Wscript.Echo ""Error 17 = cannot perform the requested operation"""
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "		Set xmlDoc_object = Nothing"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "		On Error goto 0"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "		WScript.Quit 17 ' Error 17 = cannot perform the requested operation exit with an error ... soft or hard ?"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "	End If"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "	gimme_xml_named_value = item_nNode.text ' eg the text for that item //VideoReDoProject/EstimatedVideoBitrate"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "End Function"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "Function gimme_xml_named_attribute (xmlDoc_object, byVAL xml_item_name, byVAL xml_item_attribute_name)"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "	'	Parameters:"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "	'		xmlDoc_object 	the DOM xml object with the xml string already loaded"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "	'		xml_item_name 	a string like //VideoReDoProject/EncodingDimensions"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "	Dim item_nNode, item_text"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "	Set item_nNode = xmlDoc_object.selectsinglenode(xml_item_name) ' eg '//VideoReDoProject/EncodingDimensions' CAREFUL, this is case sensitive"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "	If item_nNode is Nothing Then"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "		WScript.StdOut.WriteLine(""ABORTING: Could not find XML node "" & xml_item_name & "" in xmlDoc_object"")"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "		Wscript.Echo ""Error 17 = cannot perform the requested operation"""
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "		Set xmlDoc_object = Nothing"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "		On Error goto 0"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "		WScript.Quit 17 ' Error 17 = cannot perform the requested operation exit with an error ... soft or hard ?"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "	End If"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "	item_text = item_nNode.text ' eg the text for that item //VideoReDoProject/EncodingDimensions"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "	gimme_xml_named_attribute = item_nNode.getAttribute(xml_item_attribute_name)"
	c=c+1 : ReDim Preserve ccqsfs(c) : ccqsfs(c) = "End Function"
	' Create the new custom QSF script in the nominated file from the array above
	ccqsfs_status = vrdtvsp_delete_a_file(ccqsfs_Absolute_script_name, True) 	' delete the file first
	Set ccqsfs_object = fso.CreateTextFile(ccqsfs_Absolute_script_name, True, False) ' *** vapoursynth fails with unicode input file *** [ filename, Overwrite[, Unicode]])
	If ccqsfs_object is Nothing  Then ' Something went wrong with creating the file
		If vrdtvsp_DEBUG Then WScript.StdOut.WriteLine("VRDTVSP DEBUG: VRDTVSP ERROR vrdtvsp_create_custom_QSF_vbscript_vrd_5_AND_6 - Error - Nothing object returned from fso.CreateTextFile for file """ & ccqsfs_Absolute_script_name & """... Aborting ...")
		WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_create_custom_QSF_vbscript_vrd_5_AND_6 - Error - Nothing object returned from fso.CreateTextFile for file """ & ccqsfs_Absolute_script_name & """... Aborting ...")
		Wscript.Echo "Error 17 = cannot perform the requested operation"
		On Error goto 0
		WScript.Quit 17 ' Error 17 = cannot perform the requested operation
	End If
	For i = Lbound(ccqsfs) to UBound(ccqsfs) Step 1
		ccqsfs_object.WriteLine ccqsfs(i)
	Next
	ccqsfs_object.close
	Set ccqsfs_object = Nothing
	vrdtvsp_create_custom_QSF_vbscript_vrd_5_AND_6 = ccqsfs_Absolute_script_name
End Function
'
Function vrdtvsp_run_inlineQSF_only_with_vrd_5_and_6 (byVAL riqowv_vrd_version, byVAL riqowv_FILE_AbsolutePathName, byVAL riqowv_QSF_AbsolutePathName, byVAL riqowv_vrd6_profile_name)
	' This script should ALWAYS be reconciled with that created by function vrdtvsp_create_custom_QSF_vbscript_vrd_5_AND_6
	' Parameters: 
	'				riqowv_vrd_version				is the version of vrd to be used
	'				riqowv_FILE_AbsolutePathName	is path/name of output QSF'd file - a fully qualified path name
	'				riqowv_QSF_AbsolutePathName		is input video file path - a fully qualified path name, eg a .TS file
	'				riqowv_vrd6_profile_name		is name of a valid  QSF Output Profile created in VRD v6
	' Returns:
	'				a dictionary object populated with key/item pairs of data about the resulting QSF file (see xml from VideoReDo.OutputGetCompletedInfo() below ; xml attributes are also added as well as xml items)
	'
	' Example xml string: from VideoReDo.FileGetOpenedFileProgramInfo()
	' This is a well-formed single-item XML string, which make it really easy to find things.
	'<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
	'<VRDProgramInfo>
	'  <FileName d="Name">somefilename.qsf.vrd6.mp4</FileName>
	'  <FileSize f="0.029 GB" d="Size">28519136</FileSize>
	'  <ProgramDuration f="00:01:04.84" d="Duration" total_frames="1622">5835601</ProgramDuration>
	'  <FileType d="Mux type">MP4</FileType>
	'  <Video>
	'    <Encoding>H.264</Encoding>
	'    <VideoStreamID>x201</VideoStreamID>
	'    <FrameRate f="25.00 fps" d="Frame rate">25.000000</FrameRate>
	'    <constant_frame_rate_flag d="Frame rate flag">Constant</constant_frame_rate_flag>
	'    <EncodingDimensions d="Encoding size" width="1920" height="1080">1920 x 1080</EncodingDimensions>
	'    <AspectRatio d="Aspect ratio">16:9</AspectRatio>
	'    <HeaderBitRate f="25.000 Mbps" d="Header bit rate">25000000</HeaderBitRate>
	'    <VBVBufferSize f="572 KBytes" d="VBV buffer">572</VBVBufferSize>
	'    <Profile>High/4.0</Profile>
	'    <Progressive f="Interlaced">False</Progressive>
	'    <Chroma chroma_value="1">4:2:0</Chroma>
	'    <EntropyCodingMode d="Entropy mode">CABAC</EntropyCodingMode>
	'    <EstimatedVideoBitrate f="2.992 Mbps" d="Bit rate">2992213</EstimatedVideoBitrate>
	'  </Video>
	'  <AudioStreams>
	'    <AudioStream StreamNumber="1" Primary="true">
	'    <AudioCodec d="Codec">AC3</AudioCodec>
	'    <Format>AC3 stream</Format>
	'    <AudioChannels d="Channels">5.1</AudioChannels>
	'    <Language>eng</Language>
	'    <PID>x202</PID>
	'    <PESStreamId d="PES Stream Id">xBD</PESStreamId>
	'    <AudioBitRate f="448 Kbps" d="Bit rate">448000</AudioBitRate>
	'    <AudioSampleRate d="Sampling rate">48000</AudioSampleRate>
	'    <BitsPerSample d="Sample size" f="16 bits">16</BitsPerSample>
	'    </AudioStream>
	'    </AudioStreams>
	'  <SubtitleStreams/>
	'</VRDProgramInfo>
	'
	' Example xml string: from VideoReDo.OutputGetCompletedInfo()
	' VideoReDo.OutputGetCompletedInfo() MUST be called immediately AFTER a QSF FileSaveAs and BEFORE the .Close of the source file for the QSF
	' This is a well-formed single-item XML string, which make it really easy to find things.
	'<VRDOutputInfo outputFile="G:\HDTV\000-TO-BE-PROCESSED\zzz-TEST\VRDTVSP-Source\News-National_Nine_News_Afternoon_Edition.2021-02-05.ts.QSF">
	'  <OutputType desc="Output format:" hidden="1">MP4</OutputType>
	'  <OutputDurationSecs desc="Video length:" val_type="int" hidden="1">65</OutputDurationSecs>
	'  <OutputDuration desc="Video length:">00:01:05</OutputDuration>
	'  <OutputSizeMB desc="Video size:" val_type="int" val_format="%dMB">27</OutputSizeMB>
	'  <OutputSceneCount desc="Output scenes:" val_type="int">1</OutputSceneCount>
	'  <VideoOutputFrameCount desc="Video output frames:" val_type="int">1625</VideoOutputFrameCount>
	'  <AudioOutputFrameCount desc="Audio output frames:" val_type="int">2033</AudioOutputFrameCount>
	'  <ProcessingTimeSecs desc="Processing time (secs):" val_type="int">1</ProcessingTimeSecs>
	'  <ProcessedFramePerSec desc="Processed frames/sec:" val_type="float" val_format="%.2f">1625.000000</ProcessedFramePerSec>
	'  <ActualVideoBitrate desc="Actual Video Bitrate:" desc_format="%24s" val_type="float" val_format="%0.2f Mbps">2.912357</ActualVideoBitrate>
	'  <lkfs_values hidden="1"/>
	'  <audio_level_changes hidden="1"/>
	'</VRDOutputInfo>
	'
	Const wait_ms = 2000 ' in milliseconds
	Dim dot_count_linebreak_interval, two_hours_in_ms, one_hour_in_ms, half_hour_in_ms, quarter_hour_in_ms, ten_minutes_in_ms, giveup_interval_count
	Dim xmlDict	' this is a dictionary object returned with Set vrdtvsp_run_inlineQSF_only_with_vrd_5_and_6 = xmlDict 
	Dim VideoReDoSilent
	Dim VideoReDo
	Dim openflag, closeflag, outputOK, OutputGetState, percentComplete
	Dim percent
	Dim i, profile_count, QSF_profile_count, matching_QSF_profile, a_profile_name, is_QSF
	Dim QSF_Profile_Names()
	Dim xml_string, xml_string_openedfile, xml_string_completedfile
	Dim xmlDoc,	xml_status, xml_objErr, xml_errorCode, xml_reason
	'
	Dim actual_outputFile, actual_VideoOutputFrameCount, actual_ActualVideoBitrate
	Dim estimated_outputFile, estimated_VideoOutputFrameCount, estimated_ActualVideoBitrate
	'
	two_hours_in_ms = CLng( 2 * 60 * 60 * 1000 )
	one_hour_in_ms = ROUND(two_hours_in_ms / 2)
	half_hour_in_ms = ROUND(one_hour_in_ms / 2)
	quarter_hour_in_ms = ROUND(half_hour_in_ms / 2)
	ten_minutes_in_ms = ROUND(two_hours_in_ms / 6)
	dot_count_linebreak_interval = CLng(CLng(120) * CLng(1000) / CLng(wait_ms))		' for 2000 ms, this is 120 seconds worth of intervals
	giveup_interval_count = CLng( CLng(one_hour_in_ms) / CLng( wait_ms ) )	' an hour worth of intervals
	'
	riqowv_FILE_AbsolutePathName = fso.GetAbsolutePathName(riqowv_FILE_AbsolutePathName)		' was passed byVal
	riqowv_QSF_AbsolutePathName = fso.GetAbsolutePathName(riqowv_QSF_AbsolutePathName)			' was passed byVal
	'
	WScript.StdOut.WriteLine("======================================================================================================================================================")
	WScript.StdOut.WriteLine("" & vrdtvsp_current_datetime_string())
	WScript.StdOut.WriteLine("START vrdtvsp_run_inlineQSF_only_with_vrd_5_and_6 - QSF VRD VERSION SPECIFIED TO BE USED IS: """ & riqowv_vrd_version & """")
	'
	If riqowv_vrd_version = 5 Then
		Set VideoReDoSilent = WScript.CreateObject("VideoReDo5.VideoReDoSilent")
	ElseIf riqowv_vrd_version = 6 Then
		Set VideoReDoSilent = WScript.CreateObject("VideoReDo6.VideoReDoSilent")
	Else
		WScript.StdOut.WriteLine("VRDTVSP vrdtvsp_run_inlineQSF_only_with_vrd_5_and_6 - Error - VRD version must be 5 or 6, not """ & riqowv_vrd_version & """... Aborting ...")
		Wscript.Echo "Error 17 = cannot perform the requested operation"
		On Error goto 0
		WScript.Quit 17 ' Error 17 = cannot perform the requested operation
	End If
	Set VideoReDo = VideoReDoSilent.VRDInterface
	VideoReDo.ProgramSetAudioAlert(False)
	'
	' Validate the specified VRD QSF profile exists
	'
	QSF_profile_count = 0
	profile_count = VideoReDo.ProfilesGetCount()
	For i = 0 to profile_count-1
		a_profile_name = VideoReDo.ProfilesGetProfileName( i )
		If riqowv_vrd_version = 5 Then
			is_QSF = True
		ElseIf riqowv_vrd_version = 6 Then
			is_QSF = NOT VideoReDo.ProfilesGetProfileIsAdScan( i )
		End If
		If ( is_QSF ) Then
			QSF_profile_count = QSF_profile_count + 1
			ReDim Preserve QSF_Profile_Names(QSF_profile_count-1) ' base 0, remember
			QSF_Profile_Names(QSF_profile_count-1) = a_profile_name
		End If
	Next
	If QSF_profile_count < 1 Then
		Wscript.StdOut.WriteLine("vrdtvsp_run_inlineQSF_only_with_vrd_5_and_6: ERROR: no VRD QSF profiles were returned by VRD")
		'on error resume Next
		on error goto 0
		VideoReDo.ProgramExit()
		on error goto 0
		Wscript.StdOut.WriteLine("vrdtvsp_run_inlineQSF_only_with_vrd_5_and_6: Exiting with errorlevel code 5")
		Wscript.Quit 5
	End If
	matching_QSF_profile = False
	For i = 0 to (QSF_profile_count-1)
		If riqowv_vrd6_profile_name = QSF_Profile_Names(i) Then
			matching_QSF_profile = True
			Exit For
		End If
	Next
	If NOT matching_QSF_profile Then
		Wscript.StdOut.WriteLine("vrdtvsp_run_inlineQSF_only_with_vrd_5_and_6: ERROR: no VRD6 QSF profile was located matching your specified profile: """ & riqowv_vrd6_profile_name & """")
		For i = 0 to profile_count-1
			a_profile_name = VideoReDo.ProfilesGetProfileName( i )
			is_QSF = NOT VideoReDo.ProfilesGetProfileIsAdScan( i )
			If ( is_QSF ) Then
				QSF_profile_count = QSF_profile_count + 1
				Wscript.StdOut.WriteLine("vrdtvsp_run_inlineQSF_only_with_vrd_5_and_6F: Profile (" & i & ")=""" & a_profile_name & """ is an QSF profile")
			End If
		Next
		Wscript.StdOut.WriteLine("vrdtvsp_run_inlineQSF_only_with_vrd_5_and_6: QSF Profile count: " & QSF_profile_count )
		Wscript.StdOut.WriteLine("vrdtvsp_run_inlineQSF_only_with_vrd_5_and_6: Exiting with errorlevel code 5")
		'on error resume Next
		on error goto 0
		VideoReDo.ProgramExit()
		on error goto 0
		Wscript.StdOut.WriteLine("vrdtvsp_run_inlineQSF_only_with_vrd_5_and_6: Exiting with errorlevel code 5")
		Wscript.Quit 5
	End If
	' 
	' Open the Input file and QSF SaveAs to the output file
	'
	Wscript.StdOut.WriteLine("vrdtvsp_run_inlineQSF_only_with_vrd_5_and_6: Commencing WITH SPECIFIED VRD VERSION : " & riqowv_vrd_version & " at: " & vrdtvsp_current_datetime_string())
	openflag = VideoReDo.FileOpen(riqowv_FILE_AbsolutePathName, True) ' True means QSF mode
	If openflag = False Then
		Wscript.StdOut.WriteLine("vrdtvsp_run_inlineQSF_only_with_vrd_5_and_6: ERROR: VideoReDo failed to open file: """ & riqowv_FILE_AbsolutePathName & """")
		'on error resume Next
		on error goto 0
		VideoReDo.ProgramExit()
		' change hard fail to a soft fail so this source file can be ignored and moved and the process continue with the Next source file
		on error goto 0
		set vrdtvsp_run_inlineQSF_only_with_vrd_5_and_6 = Nothing
		exit function
		'Wscript.StdOut.WriteLine("vrdtvsp_run_inlineQSF_only_with_vrd_5_and_6: Exiting with errorlevel code 5")
		'Wscript.Quit 5
	End If
	outputOK = VideoReDo.FileSaveAs(riqowv_QSF_AbsolutePathName, riqowv_vrd6_profile_name) ' save the QSF file using the specified QSF profile
	If NOT outputOK = True Then
		Wscript.StdOut.WriteLine("vrdtvsp_run_inlineQSF_only_with_vrd_5_and_6: ERROR: VideoReDo failed to create QSF file: """ & riqowv_QSF_AbsolutePathName & """ using profile:""" & riqowv_vrd6_profile_name & """")
		'on error resume Next
		on error goto 0
		closeflag = VideoReDo.FileClose()
		VideoReDo.ProgramExit()
		' change hard fail to a soft fail so this source file can be ignored and moved and the process continue with the Next source file
		on error goto 0
		set vrdtvsp_run_inlineQSF_only_with_vrd_5_and_6 = Nothing
		exit function
		'Wscript.StdOut.WriteLine("vrdtvsp_run_inlineQSF_only_with_vrd_5_and_6: Exiting with errorlevel code 5")
		'Wscript.Quit 5
	End If
	Wscript.StdOut.WriteLine("QSF working: ")
	'Wscript.StdOut.Write("VRDTVS_VRD_QSF: Percent Complete: ")
	i = 0
	OutputGetState = VideoRedo.OutputGetState()
	While( OutputGetState <> 0 )
		i = i + 1
		If ((i MOD dot_count_linebreak_interval) = 0) Then Wscript.StdOut.WriteLine(" " & ((i * wait_ms)/1000) & " Seconds")
		If i > giveup_interval_count Then
			Wscript.StdOut.WriteLine("vrdtvsp_run_inlineQSF_only_with_vrd_5_and_6: ERROR: VideoReDo timeout after " & ((i * wait_ms)/1000) & " seconds waiting for QSF to complete ... Exiting ...")
			'on error resume Next
			on error goto 0
			closeflag = VideoReDo.FileClose()
			VideoReDo.ProgramExit()
			' change hard fail to a soft fail so this source file can be ignored and moved and the process continue with the Next source file
			on error goto 0
			set vrdtvsp_run_inlineQSF_only_with_vrd_5_and_6 = Nothing
			exit function
			'Wscript.StdOut.WriteLine("vrdtvsp_run_inlineQSF_only_with_vrd_5_and_6: Exiting with errorlevel code 5")
			'Wscript.Quit 5
		End If
		'on error resume Next
		on error goto 0
		percentComplete = CLng(VideoReDo.OutputGetPercentComplete())
		'if NOT err.number = 0 then
		'	percentComplete = 0
		'end if
		'Wscript.StdOut.Write(" " & percent & "% ")
		Wscript.StdOut.Write( "." & OutputGetState)
		on error goto 0
		Wscript.Sleep wait_ms
		OutputGetState = VideoRedo.OutputGetState()
	Wend
	Wscript.StdOut.WriteLine( "." & OutputGetState & ".")
	'
	' Grab the *Actual* info about the "VRD latest save" and hope it is the QSF file)
	'	
	'on error resume Next
	on error goto 0
	xml_string_completedfile = "" 
	xml_string_completedfile = VideoReDo.OutputGetCompletedInfo() ' which is the most recently completed output file (hopefully the QSF file) https://www.videoredo.com/TVSuite_Application_Notes/output_complete_info_xml_forma.html" 
	on error goto 0
	Wscript.StdOut.WriteLine("QSF 100% Completed: " & vrdtvsp_current_datetime_string())
	closeflag = VideoReDo.FileClose()
	'on error resume Next
	on error goto 0
	VideoReDo.ProgramExit()
	on error goto 0
	Set VideoReDo = Nothing
 	Set VideoReDoSilent = Nothing
	Wscript.StdOut.WriteLine("QSF xml_string_completedfile=") 
	Wscript.StdOut.WriteLine(xml_string_completedfile) 
	'
	' Get some of the data obtained during the QSF process and populate a Dict object to return
	'
	Set xmlDict = CreateObject("Scripting.Dictionary")
	xmlDict.CompareMode = vbTextCompare ' set case insensitive key lookups. You can set the CompareMode property only when the dictionary is empty.
	Set xmlDoc = WScript.CreateObject("Msxml2.DOMDocument.6.0")
	xmlDoc.async = False
	'on error resume Next
	on error goto 0
	xml_status = xmlDoc.loadXML(xml_string_completedfile) 
	Set xml_objErr = xmlDoc.parseError
	xml_errorCode = xml_objErr.errorCode
	xml_reason = xml_objErr.reason
	Set xml_objErr = Nothing
	Err.clear
	on error goto 0 
	If NOT xml_status Then
		Set xmlDoc = Nothing
		WScript.StdOut.WriteLine("vrdtvsp_run_inlineQSF_only_with_vrd_5_and_6: ABORTING: Failed to load string from VideoReDo.OutputGetCompletedInfo() xml_string_completedfile=" & xml_string_completedfile)
		WScript.StdOut.WriteLine("vrdtvsp_run_inlineQSF_only_with_vrd_5_and_6: ABORTING: xml_status: " & xml_status & " XML error: " & xml_errorCode & " : " & xml_reason)
		' change hard fail to a soft fail so this source file can be ignored and moved and the process continue with the Next source file
		on error goto 0
		set vrdtvsp_run_inlineQSF_only_with_vrd_5_and_6 = Nothing
		exit function
		'Wscript.Echo "Error 17 = cannot perform the requested operation"
		'WScript.Quit 17 ' Error 17 = cannot perform the requested operation
	End If
	'
	'Call vrdtvs_DumpNodes_from_xml(xmlDoc.childNodes, 0)	' PRINT INTERESTING INFORMATION FORM WITH THE XML DOCUMENT
	'
	xmlDict.Add "outputFile", gimme_xml_named_attribute(xmlDoc, "//VRDOutputInfo", "outputFile")
	xmlDict.Add "OutputType", gimme_xml_named_value(xmlDoc, "//VRDOutputInfo/OutputType")
	xmlDict.Add "OutputDurationSecs", gimme_xml_named_value(xmlDoc, "//VRDOutputInfo/OutputDurationSecs")
	xmlDict.Add "OutputDuration", gimme_xml_named_value(xmlDoc, "//VRDOutputInfo/OutputDuration")
	xmlDict.Add "OutputSizeMB", gimme_xml_named_value(xmlDoc, "//VRDOutputInfo/OutputSizeMB")
	xmlDict.Add "OutputSceneCount", gimme_xml_named_value(xmlDoc, "//VRDOutputInfo/OutputSceneCount")
	xmlDict.Add "VideoOutputFrameCount", gimme_xml_named_value(xmlDoc, "//VRDOutputInfo/VideoOutputFrameCount")
	xmlDict.Add "AudioOutputFrameCount", gimme_xml_named_value(xmlDoc, "//VRDOutputInfo/AudioOutputFrameCount")
	xmlDict.Add "ActualVideoBitrate", CLng(CDbl(gimme_xml_named_value(xmlDoc, "//VRDOutputInfo/ActualVideoBitrate")) * CDbl(1000000.0)) ' convert from dedcimal Mpbs to bps
	If NOT xmlDict.Exists("outputFile") Then 
		Set xmlDoc = Nothing
		WScript.StdOut.WriteLine("vrdtvsp_run_inlineQSF_only_with_vrd_5_and_6: ABORTING: outputFile string from VideoReDo.OutputGetCompletedInfo() not in Dict, xml_string_completedfile=" & xml_string_completedfile)
		Wscript.Echo "Error 17 = cannot perform the requested operation"
		On Error goto 0
		Set xmlDoc = Nothing
		' change hard fail to a soft fail so this source file can be ignored and moved and the process continue with the Next source file
		on error goto 0
		set vrdtvsp_run_inlineQSF_only_with_vrd_5_and_6 = Nothing
		exit function
		'Wscript.StdOut.WriteLine("vrdtvsp_run_inlineQSF_only_with_vrd_5_and_6: Exiting with errorlevel code 17")
		'WScript.Quit 17 ' Error 17 = cannot perform the requested operation
	ElseIf NOT ( Ucase(xmlDict.Item("outputFile")) =  Ucase(riqowv_QSF_AbsolutePathName) ) Then 
		Set xmlDoc = Nothing
		WScript.StdOut.WriteLine("vrdtvsp_run_inlineQSF_only_with_vrd_5_and_6: ABORTING: outputFile from VideoReDo.OutputGetCompletedInfo() not equal QSFfilename: xml_string_completedfile=" & xml_string_completedfile & " riqowv_QSF_AbsolutePathName=" & riqowv_QSF_AbsolutePathName)
		Wscript.Echo "Error 17 = cannot perform the requested operation"
		On Error goto 0
		Set xmlDoc = Nothing
		' change hard fail to a soft fail so this source file can be ignored and moved and the process continue with the Next source file
		on error goto 0
		set vrdtvsp_run_inlineQSF_only_with_vrd_5_and_6 = Nothing
		exit function
		'Wscript.StdOut.WriteLine("vrdtvsp_run_inlineQSF_only_with_vrd_5_and_6: Exiting with errorlevel code 17")
		'WScript.Quit 17 ' Error 17 = cannot perform the requested operation
	End If
	on error goto 0
	Set xmlDoc = Nothing
	WScript.StdOut.WriteLine("END vrdtvsp_run_inlineQSF_only_with_vrd_5_and_6 - QSF VRD VERSION SPECIFIED TO BE USED WAS: """ & riqowv_vrd_version & """")
	WScript.StdOut.WriteLine("" & vrdtvsp_current_datetime_string())
	WScript.StdOut.WriteLine("======================================================================================================================================================")
	Set vrdtvsp_run_inlineQSF_only_with_vrd_5_and_6 = xmlDict
	' Can use the returned Dict like this:
	'	Dim vrdtvs_dict
	'	Set vrdtvs_dict = CreateObject("Scripting.Dictionary")
	'	vrdtvs_dict.CompareMode = vbTextCompare ' case insensitive key lookups. You can set the CompareMode property only when the dictionary is empty.
	'	vrdtvs_dict.Add key, item
	'	vrdtvs_dict.Remove (key)
	'	vrdtvs_dict.RemoveAll
	'	If vrdtvs_dict.Exists(key) Then temp = vrdtvs_dict.Item(key) Else temp = ""
	'	End If
	'	For Each key In vrdtvs_dict
	'		wscript.echo "Dict key=" & key & " value= " & vrdtvs_dict.Item(key)
	'	Next
	'	vrdtvs_dict.Items().Count ' count of items in the dictionary
	'	vrdtvs_dict.Keys().(i)	' the value, say in a for/Next loop, base 0 (0 to Count-1)
	'	vrdtvs_dict.Items().(i)	' the value, say in a for/Next loop, base 0 (0 to Count-1)
	'	vrdtvs_dict.Remove vrdtvs_dict.Keys()(i)
	'	vrdtvs_dict.Key(key) = newkey ' but You can't change a value in a key-value pair.  If you want a different value, you need to delete the item, then add a new one.
End Function
Function gimme_xml_named_value (xmlDoc_object, byVAL xml_item_name) ' assumes the xml doc is already loaded in xmlDoc_object
	'	Parameters:
	'		xmlDoc_object 	the DOM xml object with the xml string already loaded
	'		xml_item_name 	a CASE-SENSITIVE string like //VRDProgramInfo/Video/EstimatedVideoBitrate
	Dim item_nNode, item_text
	Set item_nNode = xmlDoc_object.selectsinglenode(xml_item_name) ' eg '//VRDProgramInfo/Video/EstimatedVideoBitrate' CAREFUL, this is case sensitive
	If item_nNode is Nothing Then
		WScript.StdOut.WriteLine("VRDTVS gimme_xml_named_value ABORTING : Could not find XML node " & xml_item_name & " in xmlDoc_object")
		Wscript.Echo "Error 17 = cannot perform the requested operation"
		Set xmlDoc_object = Nothing
		' change hard fail to a soft fail so this source file can be ignored and moved and the process continue with the Next source file
		on error goto 0
		gimme_xml_named_value = "no xml node to get data from"
		exit function
		'Wscript.StdOut.WriteLine("gimme_xml_named_value: Exiting with errorlevel code 17")
		'WScript.Quit 17 ' Error 17 = cannot perform the requested operation exit with an error ... soft or hard ?
	End If
	gimme_xml_named_value = item_nNode.text ' eg the text for that item //VideoReDoProject/EstimatedVideoBitrate
	End Function
Function gimme_xml_named_attribute (xmlDoc_object, byVAL xml_item_name, byVAL xml_item_attribute_name)
	'	Parameters:
	'		xmlDoc_object 				the DOM xml object with the xml string already loaded
	'		xml_item_name 				a CASE-SENSITIVE string like //VideoReDoProject/EncodingDimensions
	'		xml_item_attribute_name		a CASE-SENSITIVE string like "width"
	Dim item_nNode, item_text
	Set item_nNode = xmlDoc_object.selectsinglenode(xml_item_name) ' eg '//VideoReDoProject/EncodingDimensions' CAREFUL, this is case sensitive
	If item_nNode is Nothing Then
		WScript.StdOut.WriteLine("VRDTVS gimme_xml_named_attribute ABORTING: Could not find XML node " & xml_item_name & " in xmlDoc_object")
		Wscript.Echo "Error 17 = cannot perform the requested operation"
		Set xmlDoc_object = Nothing
		' change hard fail to a soft fail so this source file can be ignored and moved and the process continue with the Next source file
		on error goto 0
		gimme_xml_named_attribute = "no xml node to get data from"
		exit function
		'Wscript.StdOut.WriteLine("gimme_xml_named_attribute: Exiting with errorlevel code 17")
		'WScript.Quit 17 ' Error 17 = cannot perform the requested operation exit with an error ... soft or hard ?
	End If
	item_text = item_nNode.text ' eg the text for that item //VideoReDoProject/EncodingDimensions
	gimme_xml_named_attribute = item_nNode.getAttribute(xml_item_attribute_name)
End Function
Sub vrdtvs_DumpNodes_from_xml(dnfx_Nodes, dnfx_Indent_Size)
	'	Dump useful information from the xmlDoc object which contains XML data
	'	Called like:
	'		Call vrdtvs_DumpNodes_from_xml(xmlDoc.childNodes, 0)
	Dim dnfx_xNode
	For Each dnfx_xNode In dnfx_Nodes
		Select Case dnfx_xNode.nodeType ' 1=NODE ELEMENT, 3=NODE VALUE
			Case 1:   ' NODE_ELEMENT
				If dnfx_xNode.nodeName <> "#document" Then ' looks like a hack for the top level
					' change "vrdtvs_DisplayAttributes_from_xml_node(dnfx_xNode, dnfx_Indent_Size + 2)" to "vrdtvs_DisplayAttributes_from_xml_node(dnfx_xNode, 0)" to see inline attributes rather than indented
					WScript.Echo String(dnfx_Indent_Size," ") & "<" & dnfx_xNode.nodeName & vrdtvs_DisplayAttributes_from_xml_node(dnfx_xNode, dnfx_Indent_Size + 2) & ">" ' this is the nodename and note attributes THE START OF THE NODE
					If dnfx_xNode.hasChildNodes Then
					Call DisplayNode_from_xml(dnfx_xNode.childNodes, dnfx_Indent_Size + 2)	' THIS IS THE CHILD NODES OF THE CURRENT NODE
					End If
					WScript.Echo String(dnfx_Indent_Size," ") & "</" & dnfx_xNode.nodeName & ">"	' THIS IS THE END OF THE NODE 
				Else 'NODENAME =  "#document" 		' looks like a hack for the top level
					If dnfx_xNode.hasChildNodes Then
						Call DisplayNode_from_xml(dnfx_xNode.childNodes, dnfx_Indent_Size + 2)
					End If
				End If
			Case 3:   ' value                       
				WScript.Echo String(dnfx_Indent_Size," ") & "" & dnfx_xNode.nodeValue ' this is the value of the node ' <-- THIS IS THE VALUE
		End Select
	Next
End Sub
Function vrdtvs_DisplayAttributes_from_xml_node(dafxn_Node, dafxn_Indent_Size)
	Dim dafxn_xAttr, dafxn_res
	dafxn_res = ""
	For Each dafxn_xAttr In dafxn_Node.attributes
		If dafxn_Indent_Size = 0 Then
			dafxn_res = dafxn_res & " " & dafxn_xAttr.name & "=""" & dafxn_xAttr.value & """"
		Else 
			dafxn_res = dafxn_res & vbCrLf & String(dafxn_Indent_Size," ") & "" & dafxn_xAttr.name & """" & dafxn_xAttr.value & """"
		End If
	Next
	vrdtvs_DisplayAttributes_from_xml_node = dafxn_res
End Function
'
Function vrdtvsp_fix_timestamps_in_a_folder_tree (byVal ftiaft_folder_name, byVal ftiaft_do_the_tree)
	'	create a powershell .ps1 script to
	'		affix Timestamps in a specified folder (tree) basd n the dtae in the file's filename
	'	Parameters:
	'		ftiaft_folder_name		the folder name containing files to process; we must check and ensure no trailing "\" in it
	'		ftiaft_do_the_tree		True if we are to recurse subfolders as well
	Dim ftiaft_temp_powershell_filename
	Dim ftiaft_path
	Dim ftiaft_status
	Dim ftiaft_exit_code
	Dim vrdtvsp_ps1_file_object
	Dim ftiaft_ps1_string
	Dim ftiaft_ps1_cmd_string
	'
	' First check for and get rid of any trailing backslash in the incoming folder name
	ftiaft_path = ftiaft_folder_name
	If Right(ftiaft_path,1) <> "\" Then
		ftiaft_path = ftiaft_path & "\"
	End if
	ftiaft_path = fso.GetAbsolutePathName(ftiaft_folder_name) ' this gets rid of trailing slash, but do not rely on that since a trailing \ can kill the .ps1 script
	If Right(ftiaft_path,1) = "\" Then
		ftiaft_path = left(ftiaft_path,len(ftiaft_path)-1)
	End if
	If NOT fso.FolderExists(ftiaft_path & "\") Then    
		vrdtvsp_fix_timestamps_in_a_folder_tree = -1
		Exit Function
	End If
	'wscript.echo "incoming ftiaft_folder_name=" & ftiaft_folder_name
	'wscript.echo "GetAbsolutePathName, ftiaft_path=" & ftiaft_path
	'
	' Create the .ps1 powershell script to do the work
	ftiaft_temp_powershell_filename = vrdtvsp_gimme_a_temporary_absolute_filename("vrdtvsp_ps1_to_fix_timestamps-" & vrdtvsp_run_datetime) & ".ps1"
	ftiaft_exit_code = vrdtvsp_delete_a_file(ftiaft_temp_powershell_filename, True) ' True=silently delete it even though it should never pre-exist	
	set vrdtvsp_ps1_file_object = fso.CreateTextFile(ftiaft_temp_powershell_filename, True, False) ' *** make .BAT file ascii for compatibility, since vapoursynth fails with unicode files [ filename, Overwrite[, Unicode]])
	If vrdtvsp_ps1_file_object is Nothing  Then ' Something went wrong with creating the file
		If vrdtvsp_DEBUG Then WScript.StdOut.WriteLine("VRDTVSP DEBUG: VRDTVSP ERROR vrdtvsp_fix_timestamps_in_a_folder_tree - Error - Nothing object returned from fso.CreateTextFile with .ps1 file """ & ftiaft_temp_powershell_filename & """... Aborting ...")
		WScript.StdOut.WriteLine("VRDTVSP ERROR vrdtvsp_fix_timestamps_in_a_folder_tree - Error - Nothing object returned from fso.CreateTextFile with .ps1 file """ & ftiaft_temp_powershell_filename & """... Aborting ...")
		Wscript.Echo "Error 17 = cannot perform the requested operation"
		On Error goto 0
		set vrdtvsp_ps1_file_object = Nothing
		WScript.Quit 17 ' Error 17 = cannot perform the requested operation
	End If
	vrdtvsp_ps1_file_object.WriteLine("param ( [Parameter(Mandatory=$False)] [string]$Folder = """ & ftiaft_path & """ , [Parameter(Mandatory=$False)] [switch]$Recurse = $False )" )
	vrdtvsp_ps1_file_object.WriteLine("[console]::BufferWidth = 512")
	vrdtvsp_ps1_file_object.WriteLine("echo '*** Ignore the error: Exception setting ""BufferWidth"": ""The handle is invalid.""' ")
	vrdtvsp_ps1_file_object.WriteLine("echo '*** Ignore the error: Exception setting ""BufferWidth"": ""The handle is invalid.""' ")
	vrdtvsp_ps1_file_object.WriteLine("echo '*** Ignore the error: Exception setting ""BufferWidth"": ""The handle is invalid.""' ")
	vrdtvsp_ps1_file_object.WriteLine("#")
	vrdtvsp_ps1_file_object.WriteLine("# Powershell script to make timestamps equal to the date in the filename itself")
	vrdtvsp_ps1_file_object.WriteLine("# BEFORE this powershell script is invoked, ensure the incoming folder has no trailing ""\""")
	vrdtvsp_ps1_file_object.WriteLine("# OTHERWISE the trailing double-quote "" becomes 'escaped', thus everything on the commandline after it gets included in that parameter value.")
	vrdtvsp_ps1_file_object.WriteLine("# eg in a .bat:#")
	vrdtvsp_ps1_file_object.WriteLine("#set ""the_folder=G:\HDTV\000-TO-BE-PROCESSED""")
	vrdtvsp_ps1_file_object.WriteLine("#set ""rightmost_character=!the_folder:~-1!""")
	vrdtvsp_ps1_file_object.WriteLine("#if /I ""!rightmost_character!"" == ""\"" (set ""the_folder=!the_folder:~,-1!""")
	vrdtvsp_ps1_file_object.WriteLine("#powershell -NoLogo -ExecutionPolicy Unrestricted -Sta -NonInteractive -WindowStyle Normal -File ""G:\HDTV\000-TO-BE-PROCESSED\something.ps1"" -Folder ""G:\HDTV\000-TO-BE-PROCESSED"" -Recurse")
	vrdtvsp_ps1_file_object.WriteLine("#")
	vrdtvsp_ps1_file_object.WriteLine("# The following checks are still necessary if an incoming foldername string STILL has a trailing \")
	vrdtvsp_ps1_file_object.WriteLine("#echo ""Set file date-time timestamps: Incoming Folder = '$Folder'"" ")
	vrdtvsp_ps1_file_object.WriteLine("if ($Folder.Substring($Folder.Length-2,2) -eq '"" ') {$Folder=$Folder -Replace ""..$""} # removes the last 2 characters")
	vrdtvsp_ps1_file_object.WriteLine("if ($Folder.Substring($Folder.Length-2,2) -eq ' ""') {$Folder=$Folder -Replace ""..$""} # removes the last 2 characters")
	vrdtvsp_ps1_file_object.WriteLine("if ($Folder.Substring($Folder.Length-2,2) -eq "" '"") {$Folder=$Folder -Replace ""..$""} # removes the last 2 characters")
	vrdtvsp_ps1_file_object.WriteLine("if ($Folder.Substring($Folder.Length-1,1) -eq ""\"")  {$Folder=$Folder -Replace "".$""}  # removes the last 1 character")
	vrdtvsp_ps1_file_object.WriteLine("if ($Folder.Substring(0,1) -eq ""'"" -And $Folder.Substring($Folder.Length-1,1) -eq ""'"") {$Folder=$Folder.Trim(""'"")} # removes the specified character ' from both ends of the string")
	vrdtvsp_ps1_file_object.WriteLine("#")
	vrdtvsp_ps1_file_object.WriteLine("# Now set the date-created and date-modified")
	vrdtvsp_ps1_file_object.WriteLine("if ($Recurse) {")
	vrdtvsp_ps1_file_object.WriteLine("	# note we add -Recurse and leave ""\*"" off of the folder name")
	vrdtvsp_ps1_file_object.WriteLine("	$ft_string=""tree"" ")
	vrdtvsp_ps1_file_object.WriteLine("	echo ""Set file date-time timestamps: START WITH RECURSE for folder $ft_string '$Folder'"" ")
	vrdtvsp_ps1_file_object.WriteLine("	$FileList = Get-ChildItem -Path ""$Folder"" -Recurse -File -Include '*.ts','*.mp4','*.mpg','*.vprj'")
	vrdtvsp_ps1_file_object.WriteLine("} else {")
	vrdtvsp_ps1_file_object.WriteLine("	# note we add ""\*"" to the folder name")
	vrdtvsp_ps1_file_object.WriteLine("	$ft_string="""" ")
	vrdtvsp_ps1_file_object.WriteLine("	echo ""Set file date-time timestamps: START WITH NON-RECURSE for folder $ft_string '$Folder'"" ")
	vrdtvsp_ps1_file_object.WriteLine("	$FileList = Get-ChildItem -Path ""$Folder\*"" -File -Include '*.ts','*.mp4','*.mpg','*.vprj'")
	vrdtvsp_ps1_file_object.WriteLine("}")
	vrdtvsp_ps1_file_object.WriteLine("$DateFormat = ""yyyy-MM-dd""")
	vrdtvsp_ps1_file_object.WriteLine("foreach ($FL_Item in $FileList) {")
	vrdtvsp_ps1_file_object.WriteLine("	$fn = $FL_Item.FullName")
	vrdtvsp_ps1_file_object.WriteLine("	#echo ""Set file date-time timestamps: Processing Timestamp for 'fn'"" ")
	vrdtvsp_ps1_file_object.WriteLine("	$ixxx = $FL_Item.BaseName -match '(?<DateString>\d{4}-\d{2}-\d{2})'")
	vrdtvsp_ps1_file_object.WriteLine("	if($ixxx){")
	vrdtvsp_ps1_file_object.WriteLine("		$DateString = $Matches.DateString")
	vrdtvsp_ps1_file_object.WriteLine("		$date_from_file = [datetime]::ParseExact($DateString, $DateFormat, $Null)")
	vrdtvsp_ps1_file_object.WriteLine("	} else {")
	vrdtvsp_ps1_file_object.WriteLine("		$date_from_file = $FL_Item.CreationTime.Date # .Date removes the time component; use the existing date-created")
	vrdtvsp_ps1_file_object.WriteLine("	}")
	vrdtvsp_ps1_file_object.WriteLine("	$FL_Item.CreationTime = $date_from_file")
	vrdtvsp_ps1_file_object.WriteLine("	$FL_Item.LastWriteTime = $date_from_file")
	vrdtvsp_ps1_file_object.WriteLine("	$df=$date_from_file.ToString()")
	vrdtvsp_ps1_file_object.WriteLine("	$cd=$FL_Item.CreationTime.ToString()")
	vrdtvsp_ps1_file_object.WriteLine("	$lw=$FL_Item.LastWriteTime.ToString()")
	vrdtvsp_ps1_file_object.WriteLine("	echo ""Set file date-time timestamps: Set '$df' as Creation-date: '$cd' Modification-Date: '$lw' on '$fn'"" ")
	vrdtvsp_ps1_file_object.WriteLine("}")
	vrdtvsp_ps1_file_object.WriteLine("echo ""Set file date-time timestamps: FINISH in folder $ft_string '$Folder' ..."" ")
	vrdtvsp_ps1_file_object.WriteLine("## regex [^a-zA-Z0-9-_. ]+")
	vrdtvsp_ps1_file_object.WriteLine("## the leading hat ^ character means NOT in any of the set, trailing + means any number of matches in the set")
	vrdtvsp_ps1_file_object.WriteLine("## a-z")
	vrdtvsp_ps1_file_object.WriteLine("## A-Z")
	vrdtvsp_ps1_file_object.WriteLine("## 0-9")
	vrdtvsp_ps1_file_object.WriteLine("## - underscore . space")
	vrdtvsp_ps1_file_object.Close
	Set vrdtvsp_ps1_file_object = Nothing
	'
	' display the content of .ps1 powershell script
	WScript.StdOut.WriteLine("Content of PowerShell .ps1 file """ & ftiaft_temp_powershell_filename & """ Below --------------------------------------------------------------------------------------------------------------------")
	Set vrdtvsp_ps1_file_object = fso.OpenTextFile(ftiaft_temp_powershell_filename, ForReading)
	Do Until vrdtvsp_ps1_file_object.AtEndOfStream
		ftiaft_ps1_string = vrdtvsp_ps1_file_object.ReadLine
		WScript.StdOut.WriteLine(ftiaft_ps1_string)
	Loop			
	vrdtvsp_ps1_file_object.Close
	Set vrdtvsp_ps1_file_object = Nothing
	WScript.StdOut.WriteLine("Content of PowerShell .ps1 file """ & ftiaft_temp_powershell_filename & """ Above --------------------------------------------------------------------------------------------------------------------")
	'
	' Run the .ps1 in a DOS box and print the results
	ftiaft_ps1_cmd_string = "" ' use trailing spaces in strings below
	ftiaft_ps1_cmd_string = ftiaft_ps1_cmd_string & "powershell -NoLogo -ExecutionPolicy Unrestricted -Sta -NonInteractive -WindowStyle Normal "
	ftiaft_ps1_cmd_string = ftiaft_ps1_cmd_string & "-File """ & ftiaft_temp_powershell_filename & """ "
	If ftiaft_do_the_tree Then
		ftiaft_ps1_cmd_string = ftiaft_ps1_cmd_string & "-Recurse "	' add "-Recurse " to the commandline if subfolders need to be processed as well
	Else
		ftiaft_ps1_cmd_string = ftiaft_ps1_cmd_string & " "			' otherwise just leave off "-Recurse " since it defaults to False
	End If
	ftiaft_ps1_cmd_string = ftiaft_ps1_cmd_string & "-Folder """ & ftiaft_path & """ "
	WScript.StdOut.WriteLine("======================================================================================================================================================")
	WScript.StdOut.WriteLine("" & vrdtvsp_current_datetime_string())
	WScript.StdOut.WriteLine("******************** Start of run FIXING TIMESTAMPS """ & ftiaft_ps1_cmd_string & """ :")
	WScript.StdOut.WriteLine("Doing FIXING TIMESTAMPS for """ & ftiaft_path & """ ... ")
	WScript.StdOut.WriteLine("FIXING TIMESTAMPS command: " & ftiaft_ps1_cmd_string)
	ReDim vrdtvsp_Exec_in_a_DOS_BAT_file_cmd_array(2) ' base 0, so the dimension is always 1 less than the number of commands
	vrdtvsp_Exec_in_a_DOS_BAT_file_cmd_array(0) = "REM " & vrdtvsp_current_datetime_string()
	vrdtvsp_Exec_in_a_DOS_BAT_file_cmd_array(1) = "ECHO !DATE! !TIME!"
	vrdtvsp_Exec_in_a_DOS_BAT_file_cmd_array(2) = ftiaft_ps1_cmd_string ' for the final return status to be good, this must be the final command in the array
	If vrdtvsp_DEVELOPMENT_NO_ACTIONS Then
		ftiaft_status = 0
		WScript.StdOut.WriteLine("DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV ---- DID NOT RUN FIXING TIMESTAMPS """ & ftiaft_ps1_cmd_string & """ :")
	Else
		ftiaft_status = vrdtvsp_Exec_in_a_DOS_BAT_file(vrdtvsp_Exec_in_a_DOS_BAT_file_cmd_array, True, True) ' print .bat, do the commands, print .log - the safer way of doing it
	End If
	Erase vrdtvsp_Exec_in_a_DOS_BAT_file_cmd_array
	WScript.StdOut.WriteLine("******************** Finished run FIXING TIMESTAMPS """ & ftiaft_ps1_cmd_string & """ :")
	WScript.StdOut.WriteLine("Done FIXING TIMESTAMPS for """ & ftiaft_path & """ ... ")
	WScript.StdOut.WriteLine("FIXING TIMESTAMPS command: " & ftiaft_ps1_cmd_string)
	WScript.StdOut.WriteLine("" & vrdtvsp_current_datetime_string())
	WScript.StdOut.WriteLine("======================================================================================================================================================")
	If ftiaft_status <> 0  Then
		If vrdtvsp_DEBUG Then WScript.StdOut.WriteLine("VRDTVSP DEBUG: ERROR vrdtvsp_fix_timestamps_in_a_folder_tree - Error - Failed to FIX TIMESTAMPS, ExitStatus=" & ftiaft_status & " """ & ftiaft_path & """ ftiaft_ps1_cmd_string=""" & ftiaft_ps1_cmd_string & """")
		WScript.StdOut.WriteLine("VRDTVSP ERROR vrdtvsp_fix_timestamps_in_a_folder_tree - Error - Failed to FIX TIMESTAMPS, ExitStatus=" & ftiaft_status & " """ & ftiaft_path & """ ftiaft_ps1_cmd_string=""" & ftiaft_ps1_cmd_string & """")
		If vrdtvsp_DEVELOPMENT_NO_ACTIONS Then ' DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV 
			Wscript.Echo "Error 17 = cannot perform the requested operation"
			On Error goto 0
			WScript.Quit 17 ' Error 17 = cannot perform the requested operation
		End If
		vrdtvsp_fix_timestamps_in_a_folder_tree = ftiaft_status
		Exit Function
	End If
	'
	' Cleanup and exit
	ftiaft_exit_code = vrdtvsp_delete_a_file(ftiaft_temp_powershell_filename, True) ' True=silently delete it
	vrdtvsp_fix_timestamps_in_a_folder_tree = 0
End Function
