'''''	??? add testing of processing audio/video delay - 0 and positive and negative - for the large-number delays
'''''		-af "adelay=delays=64ms:all=1"
'''''		-itsoffset 384ms JUST BEFORE INPUT FILE


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
'/vrd_version_for_adscan:5 ^
'/do_qsf:False
'/do_adscan:false
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
WScript.StdOut.WriteLine("------------------------------------------------------------------------------------------------------")
Dim  cscript_wshShell, cscript_strEngine
Dim vrdtvs_ComputerName
'
Set cscript_wshShell = CreateObject( "WScript.Shell" )
cscript_strEngine = UCase( Right( WScript.FullName, 12 ) )
vrdtvs_ComputerName = cscript_wshShell.ExpandEnvironmentStrings( "%COMPUTERNAME%" )
'Dim wshNetwork
'Set wshNetwork = CreateObject( "WScript.Network" )
'vrdtvs_ComputerName = wshNetwork.ComputerName
'WScript.StdOut.WriteLine("wshNetwork.ComputerName Computer Name: " & vrdtvs_ComputerName)
'set wshNetwork = Nothing
'Dim objSysInfo
'Set objSysInfo = CreateObject( "WinNTSystemInfo" )
'vrdtvs_ComputerName = objSysInfo.ComputerName
'WScript.StdOut.WriteLine("objSysInfo.ComputerName Computer Name: " & vrdtvs_ComputerName)
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
	WScript.Quit 17 ' Error 17 = cannot perform the requested operation
End If
WScript.StdOut.WriteLine("VRDTVS cscript Engine: """ & cscript_strEngine & """")
WScript.StdOut.WriteLine("VRDTVS    Script name: " & Wscript.ScriptName)
WScript.StdOut.WriteLine("VRDTVS    Script path: " & Wscript.ScriptFullName)
WScript.StdOut.WriteLine("VRDTVS   ComputerName: " & vrdtvs_ComputerName)
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
Dim HDTV_root
Dim vs_root
Dim vrdtvs_mp4boxexex64
Dim vrdtvs_mediainfoexe64
Dim vrdtvs_ffprobeexe64
Dim vrdtvs_ffmpegexe64
Dim vrdtvs_dgindexNVexe64
Dim vrdtvs_Insomniaexe64
Dim vrdtvs_Insomnia64_tmp_filename, vrdtvs_Insomnia64_ProcessID
'
HDTV_root = fso.GetAbsolutePathName("G:\HDTV\") ' where vrd applicationlogs are
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
Dim vrd_profile_name_for_qsf
Dim vrd_profile_name_for_adscan
Dim vrd_extension_mpeg2
Dim vrd_extension_avc
Dim vrd_extension
Dim vrd_logfile_wildcard_QSF
Dim vrd_logfile_wildcard_ADSCAN
Dim vrd_do_qsf
Dim vrd_do_adscan
'
Const const_vrd5_path = "C:\Program Files (x86)\VideoReDoTVSuite5"
Const const_vrd5_profile_mpeg2 = "zzz-MPEG2ps"
Const const_vrd5_profile_avc = "zzz-H.264-MP4-general"
Const const_vrd5_extension_mpeg2 = "mpg"
Const const_vrd5_extension_avc = "mp4"
Dim vrd5_logfile_wildcard
vrd5_logfile_wildcard =  fso.GetAbsolutePathName(HDTV_root & "\") & "\VideoReDo-5_*.Log"
'
Const const_vrd6_path =  "C:\Program Files (x86)\VideoReDoTVSuite6"
Const const_vrd6_profile_mpeg2 = "VRDTVS-for-QSF-MPEG2"
Const const_vrd6_profile_avc = "VRDTVS-for-QSF-H264"
Const const_vrd6_extension_mpeg2 = "mpg"
Const const_vrd6_extension_avc = "mp4"
Dim vrd6_logfile_wildcard
vrd6_logfile_wildcard =  fso.GetAbsolutePathName(HDTV_root & "\") & "\VideoReDo6_*.Log"
'
vrd_version_for_qsf = 6
vrd_version_for_adscan = 5
vrd_do_qsf = False
vrd_do_adscan = False
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
vrd_version_for_adscan = vrdtvs_get_commandline_parameter("vrd_version_for_adscan",vrd_version_for_adscan)                                          ' /vrd_version_for_adscan:5
vrd_do_qsf = vrdtvs_get_commandline_parameter("do_qsf",vrd_do_qsf) 			                     		                    						' /do_qsf:False
vrd_do_adscan = vrdtvs_get_commandline_parameter("do_adscan",vrd_do_adscan)                      		                    						' /do_adscan:False

If vrd_version_for_qsf = 5 Then '*** QSF
    vrd_path_for_qsf_vbs = fso.GetAbsolutePathName(fso.BuildPath(const_vrd5_path,"vp.vbs"))
    vrd_profile_name_for_qsf_mpeg2 = const_vrd5_profile_mpeg2
    vrd_profile_name_for_qsf_avc = const_vrd5_profile_avc
    vrd_extension_mpeg2 = const_vrd5_extension_mpeg2
    vrd_extension_avc = const_vrd5_extension_avc
	vrd_logfile_wildcard_QSF = vrd5_logfile_wildcard
ElseIf vrd_version_for_qsf = 6 Then
    vrd_path_for_qsf_vbs = fso.GetAbsolutePathName(fso.BuildPath(const_vrd6_path,"vp.vbs"))
    vrd_profile_name_for_qsf_mpeg2 = const_vrd6_profile_mpeg2
    vrd_profile_name_for_qsf_avc = const_vrd6_profile_avc
    vrd_extension_mpeg2 = const_vrd6_extension_mpeg2
    vrd_extension_avc = const_vrd6_extension_avc
	vrd_logfile_wildcard_QSF = vrd6_logfile_wildcard
Else
    WScript.StdOut.WriteLine("VRDTVS ERROR - vrd_version_for_qsf can only be 5 or 6 ... Aborting ...")
    On Error goto 0
	WScript.Quit 17 ' Error 17 = cannot perform the requested operation
End If
If vrd_version_for_adscan = 5 Then '*** AdScan
    vrd_path_for_adscan_vbs = fso.GetAbsolutePathName(fso.BuildPath(const_vrd5_path,"AdScan.vbs"))
	vrd_logfile_wildcard_ADSCAN = vrd5_logfile_wildcard
ElseIf vrd_version_for_adscan = 6 Then
    vrd_path_for_adscan_vbs = fso.GetAbsolutePathName(fso.BuildPath(const_vrd6_path,"AdScan2.vbs"))
	vrd_logfile_wildcard_ADSCAN= vrd6_logfile_wildcard
Else
    WScript.StdOut.WriteLine("VRDTVS ERROR - vrd_path_for_adscan_vbs can only be 5 or 6 ... Aborting ...")
	Wscript.Echo "Error 17 = cannot perform the requested operation"
	On Error goto 0
	WScript.Quit 17 ' Error 17 = cannot perform the requested operation
End If
WScript.StdOut.WriteLine("VRDTVS NOTE: final                       vrdtvs_DEBUG=" & vrdtvs_DEBUG)
WScript.StdOut.WriteLine("VRDTVS NOTE: final      vrdtvs_DEVELOPMENT_NO_ACTIONS=" & vrdtvs_DEVELOPMENT_NO_ACTIONS)
WScript.StdOut.WriteLine("VRDTVS NOTE: final                vrdtvs_ComputerName=""" & vrdtvs_ComputerName & """")
WScript.StdOut.WriteLine("VRDTVS NOTE: final                       vrdtvs_DEBUG=" & vrdtvs_DEBUG)
WScript.StdOut.WriteLine("VRDTVS NOTE: final      vrdtvs_DEVELOPMENT_NO_ACTIONS=" & vrdtvs_DEVELOPMENT_NO_ACTIONS & """")
WScript.StdOut.WriteLine("VRDTVS NOTE: final           vrdtvs_CAPTURE_TS_Folder=""" & vrdtvs_CAPTURE_TS_Folder & """")
WScript.StdOut.WriteLine("VRDTVS NOTE: final            vrdtvs_source_TS_Folder=""" & vrdtvs_source_TS_Folder & """")
WScript.StdOut.WriteLine("VRDTVS NOTE: final              vrdtvs_done_TS_Folder=""" & vrdtvs_done_TS_Folder & """")
WScript.StdOut.WriteLine("VRDTVS NOTE: final      vrdtvs_destination_mp4_Folder=""" & vrdtvs_destination_mp4_Folder & """")
WScript.StdOut.WriteLine("VRDTVS NOTE: final vrdtvs_failed_conversion_TS_Folder=""" & vrdtvs_failed_conversion_TS_Folder & """")
WScript.StdOut.WriteLine("VRDTVS NOTE: final                   vrdtvs_temp_path=""" & vrdtvs_temp_path & """")
WScript.StdOut.WriteLine("VRDTVS NOTE: final                vrd_version_for_qsf=" & vrd_version_for_qsf)
WScript.StdOut.WriteLine("VRDTVS NOTE: final               vrd_path_for_qsf_vbs=""" & vrd_path_for_qsf_vbs & """")
WScript.StdOut.WriteLine("VRDTVS NOTE: final     vrd_profile_name_for_qsf_mpeg2=""" & vrd_profile_name_for_qsf_mpeg2 & """")
WScript.StdOut.WriteLine("VRDTVS NOTE: final       vrd_profile_name_for_qsf_avc=""" & vrd_profile_name_for_qsf_avc & """")
WScript.StdOut.WriteLine("VRDTVS NOTE: final                vrd_extension_mpeg2=""" & vrd_extension_mpeg2 & """")
WScript.StdOut.WriteLine("VRDTVS NOTE: final                  vrd_extension_avc=""" & vrd_extension_avc & """")
WScript.StdOut.WriteLine("VRDTVS NOTE: final             vrd_version_for_adscan=" & vrd_version_for_adscan)
WScript.StdOut.WriteLine("VRDTVS NOTE: final            vrd_path_for_adscan_vbs=""" & vrd_path_for_adscan_vbs & """")
WScript.StdOut.WriteLine("VRDTVS NOTE: final                         vrd_do_qsf=" & vrd_do_qsf)
WScript.StdOut.WriteLine("VRDTVS NOTE: final                      vrd_do_adscan=" & vrd_do_adscan)
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
vrdtvs_Insomnia64_tmp_filename = vrdtvs_gimme_a_temporary_absolute_filename("VRDTVS_Insomnia64_copy-" & vrdtvs_run_datetime) & ".exe"
If vrdtvs_DEBUG Then WScript.StdOut.WriteLine("VRDTVS DEBUG: Insomnia: Creating and running Insomnia vrdtvs_Insomnia64_tmp_filename=" & vrdtvs_Insomnia64_tmp_filename)
vrdtvs_exit_code = vrdtvs_delete_a_file(vrdtvs_Insomnia64_tmp_filename, True) ' True=silently delete it even though it should never pre-exist
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
	Wscript.Echo "Error 17 = cannot perform the requested operation"
	On Error goto 0
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
	Wscript.Echo "Error 17 = cannot perform the requested operation"
	On Error goto 0
	WScript.Quit 17 ' Error 17 = cannot perform the requested operation
End If
WScript.StdOut.WriteLine("VTDRVS Insomnia: Exec Exit Status: " & vrdtvs_status)
If vrdtvs_DEBUG Then WScript.StdOut.WriteLine("VRDTVS DEBUG: Insomnia: Exec Exit Status: " & vrdtvs_status)
'
'----------------------------------------------------------------------------------------------------------------------------------------
' Move .ts .mp4 .mpg .brpj files from the Source Folder to the source folder sincethat is where we process from
'
If vrdtvs_CAPTURE_TS_Folder <> "" Then
	WScript.StdOut.WriteLine("VRDTVS Insomnia: ERROR - Insomnia START command created ProcessID is zero ... Aborting ...")
    vrdtvs_status = vrdtvs_move_files_to_folder(vrdtvs_CAPTURE_TS_Folder & "\*.ts", vrdtvs_source_TS_Folder & "\")    ' ignore any status
    vrdtvs_status = vrdtvs_move_files_to_folder(vrdtvs_CAPTURE_TS_Folder & "\*.mp4", vrdtvs_source_TS_Folder & "\")   ' ignore any status
    vrdtvs_status = vrdtvs_move_files_to_folder(vrdtvs_CAPTURE_TS_Folder & "\*.mpg", vrdtvs_source_TS_Folder & "\")   ' ignore any status
    vrdtvs_status = vrdtvs_move_files_to_folder(vrdtvs_CAPTURE_TS_Folder & "\*.bprj", vrdtvs_source_TS_Folder & "\")  ' ignore any status '.bprj are associated with .mp4 of the same BaseName
End If
'
'----------------------------------------------------------------------------------------------------------------------------------------
' In Top Level Folders: Source
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
	Wscript.Echo "Error 17 = cannot perform the requested operation"
	On Error goto 0
	WScript.Quit 17 ' Error 17 = cannot perform the requested operation
End If
'
'----------------------------------------------------------------------------------------------------------------------------------------
' Convert Video files and create the associated .bprj files by running adscan on the media file
' The function filters for file Extensions: .ts .mp4 .mpg and creates .bprj
'
'.................. START video processing for the FULL SOURCE TS folder (not tree) - the function has a big loop - converts .TS .mp4 .mpg Source files then moves them to Done or Failed
' ***** Rely on these already being defined/set Globally BEFORE invoking the conversion function
' ***** 	vrdtvs_DEBUG
' ***** 	vrdtvs_DEVELOPMENT_NO_ACTIONS
' ***** 	wso, fso, vrdtvs_status
' generate a unique filename to save FFMPEG and related commands
vrdtvs_saved_ffmpeg_commands_filename = fso.GetAbsolutePathName(fso.BuildPath(vrdtvs_source_TS_Folder, "vrdtvs_saved_ffmpeg_commands-" & vrdtvs_run_datetime & ".bat"))
' process the files
vrdtvs_status = vrdtvs_Convert_files_in_a_folder(	vrdtvs_source_TS_Folder, _
													vrdtvs_done_TS_Folder, _
													vrdtvs_destination_mp4_Folder, _
													vrdtvs_failed_conversion_TS_Folder, _
													vrdtvs_temp_path, _
													vrdtvs_saved_ffmpeg_commands_filename, _
													vrd_do_qsf, _
													vrd_do_adscan )
If vrdtvs_status <> 0 Then ' Something bad went wrong (invididual conversion failures just result in moving the source file to the Failed folder)
	If vrdtvs_DEBUG Then WScript.StdOut.WriteLine("VRDTVS DEBUG: VRDTVS ERROR - Error " & vrdtvs_status & " from vrdtvs_Convert_files_in_a_folder ... Aborting ...")
	WScript.StdOut.WriteLine("VRDTVS ERROR  VRDTVS ERROR - Error " & vrdtvs_status & " from vrdtvs_Convert_files_in_a_folder ... Aborting ...")
	Wscript.Echo "Error 17 = cannot perform the requested operation"
	On Error goto 0
	WScript.Quit 17 ' Error 17 = cannot perform the requested operation
End If
'.................. END video processing for the FULL SOURCE TS folder (not tree) - the function has a big loop - converts Source files then moves them to Done or Failed
'
'----------------------------------------------------------------------------------------------------------------------------------------
' In Top Level Folders: Destination 
' (the function filters for file Extensions: .ts .mp4 .mpg, and autofixes .bprj which are associated with .mpg and .mp4 and should have the same BaseName)
'   a) Remove special characters in filenames for file Extensions: .ts .mp4 .mpg and autofix .bprj
'   b) Modify the filenames based on the filename content including reformatting the date in the filename
'	c) Also Modily content of associated .bprj files (they are .xml content) to link to the new media filename since we are modifying the pair
'
'If vrdtvs_DEBUG Then WScript.StdOut.WriteLine("VRDTVS DEBUG: about to call vrdtvs_fix_filenames_in_a_folder_tree(""" & vrdtvs_destination_mp4_Folder & """, True)")
vrdtvs_status = vrdtvs_fix_filenames_in_a_folder_tree(vrdtvs_destination_mp4_Folder, True) ' this does (a) and (b) and (c).  True indicates to process the top level folder including SUBFOLDERS
If vrdtvs_status <> 0 Then ' Something went wrong with processing files in the Destination folder ... check for 53 not found ?
	If vrdtvs_DEBUG Then WScript.StdOut.WriteLine("VRDTVS DEBUG: VRDTVS ERROR - Error " & vrdtvs_status & " from vrdtvs_fix_filenames_in_a_folder_tree in """ & vrdtvs_destination_mp4_Folder & """... Aborting ...")
	WScript.StdOut.WriteLine("VRDTVS ERROR - Error " & vrdtvs_status & " from vrdtvs_fix_filenames_in_a_folder_tree in """ & vrdtvs_destination_mp4_Folder & """ ... Aborting ...")
	Wscript.Echo "Error " & vrdtvs_status
	Wscript.Quit vrdtvs_status
End If
'
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
'	WScript.StdOut.WriteLine("vbs_rename_files: ***** Fixing file dates using:<" & vrdtvs_temp_powershell_cmd & ">")
'	???? objWscriptShell.??? exec run vrdtvs_temp_powershell_cmd, True ?????????? use exec instead with stdout stderr etc
'	Set objWscriptShell = Nothing
'	WScript.StdOut.WriteLine("vbs_rename_files: --- FINISHED for folder <" & aPath & ">")
'end if
'????????????????????????????
'scratch_local_timerEnd = Timer
'WScript.StdOut.WriteLine("VRDTVS Finished Powershell file timestamp fixing for folder tree """ & ffiaft_folder_tree & """ with Elapsed Time " & vrdtvs_Calculate_ElapsedTime_string(scratch_local_timerStart, scratch_local_timerEnd))
'vrdtvs_status = vrdtvs_delete_a_file(vrdtvs_temp_powershell_filename, True)
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
' taskkill /t /f /im "%iFile%"
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
'Delete the temporary Insomnia .exe file
vrdtvs_exit_code = vrdtvs_delete_a_file(vrdtvs_Insomnia64_tmp_filename, True) ' True=silently delete. Ignore any errors.

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
    If NOT do_it_silently Then WScript.StdOut.WriteLine("VRDTVS vrdtvs_delete_a_file Deleting file: """ & filename_to_delete & """")
    If vrdtvs_DEBUG Then WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_delete_a_file Deleting file: """ & filename_to_delete & """")
    'If fso.FileExists(filename_to_delete) Then
    	On Error Resume Next
	    fso.DeleteFile filename_to_delete, True ' fso.DeleteFile ( filespec[, force] ) ' it also supports wildcards, allowing delete of multiple files ...
	    daf_Err_number = Err.Number
        daf_Err_Description = Err.Description
        daf_Err_Helpfile = Err.Helpfile
        daf_Err_HelpContext = Err.HelpContext
        If daf_Err_number <> 0 Then
            If NOT do_it_silently Then WScript.StdOut.WriteLine("VRDTVS ERROR: vrdtvs_delete_a_file error " &  daf_Err_number &  " """ &  daf_Err_Description & """ : raised when Deleting file """ & filename_to_delete & """")
            'If vrdtvs_DEBUG Then WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_delete_a_file Error " &  daf_Err_number &  " """ &  daf_Err_Description & """ : raised when Deleting file """ & filename_to_delete & """")
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
        WScript.StdOut.WriteLine("vrdtvs_move_files_to_folder StdErr: " & mf_tmp)
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
Function vrdtvs_get_mediainfo_parameter (byVal mi_Section, byVal mi_Parameter, byVal mi_MediaFilename, byVal mi_Legacy) 
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
    '       dim V_Width, V_Height
    '       V_Width = get_mediainfo_parameter("Video","Width","G:\HDTV\000-TO-BE-PROCESSED\zzz-TEST\VRDTVS-Converted\News-ABC_Evening_News.2021-02-05.mp4", "")
    '       V_Height = get_mediainfo_parameter("Video","Height","G:\HDTV\000-TO-BE-PROCESSED\zzz-TEST\VRDTVS-Converted\News-ABC_Evening_News.2021-02-05.mp4", "")
	'
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
		Wscript.Echo "Error 17 = cannot perform the requested operation"
		On Error goto 0
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
		Wscript.Echo "Error 17 = cannot perform the requested operation"
		On Error goto 0
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
Function vrdtvs_get_ffprobe_video_stream_parameter (byVal ffp_Parameter, byVal ffp_MediaFilename) 
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
		Wscript.Echo "Error 17 = cannot perform the requested operation"
		On Error goto 0
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
	Dim Original_BPRJ_AbsoluteFilename, Final_Renamed_BPRJ_AbsoluteFilename
	Dim local_timerStart, local_timerEnd
	local_timerStart = Timer
	local_timerEnd = Timer
    theOriginalAbsoluteFilename = fso.GetAbsolutePathName(objSpecifiedFile.Path) ' should already be fully qualified but do it anyway just to be safe
    theOriginalParentFolderName = fso.GetParentFolderName(theOriginalAbsoluteFilename)
    theOriginalBaseName = fso.GetBaseName(theOriginalAbsoluteFilename)
    theOriginalExtName = fso.GetExtensionName(theOriginalAbsoluteFilename) ' does not include  the "."
    '
    If vrdtvs_DEBUG Then WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_ffiaft_pfis_Rename_a_File: entered Sub with original BaseName """ & theOriginalBaseName & """ from """ & theOriginalAbsoluteFilename & """")
    NewBaseName = theOriginalBaseName ' initialize so we can keep the original stuff if we need i in the future
    NewBaseName = vrdtvs_remove_special_characters_from_string(NewBaseName, False) ' flag is not an Absolute filename by passing False to the function
    'If vrdtvs_DEBUG Then WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_ffiaft_pfis_Rename_a_File: after vrdtvs_remove_special_characters_from_string original BaseName """ & theOriginalBaseName & """ NewBaseName """ & NewBaseName & """")
    NewBaseName = vrdtvs_remove_tvs_classifying_stuff_from_string(NewBaseName)
    'If vrdtvs_DEBUG Then WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_ffiaft_pfis_Rename_a_File: after vrdtvs_remove_tvs_classifying_stuff_from_string original BaseName """ & theOriginalBaseName & """ NewBaseName """ & NewBaseName & """")
    NewBaseName = vrdtvs_Move_Date_to_End_of_String(NewBaseName)
    If vrdtvs_DEBUG Then WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_ffiaft_pfis_Rename_a_File: after vrdtvs_Move_Date_to_End_of_String original BaseName """ & theOriginalBaseName & """ NewBaseName """ & NewBaseName & """")
	'
	'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	newAbsoluteFilename = fso.GetAbsolutePathName(fso.BuildPath(theOriginalParentFolderName,NewBaseName & "." & theOriginalExtName))
	If ucase(NewBaseName) = Ucase(theOriginalBaseName) Then ' no change to filename
		If vrdtvs_DEBUG Then 
		'	WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_ffiaft_pfis_Rename_a_File: NO NEED for a Rename, no change: theOriginalBaseName=""" & theOriginalBaseName & """" )
		'	WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_ffiaft_pfis_Rename_a_File: NO NEED for a Rename, no change: theOriginalAbsoluteFilename=""" & theOriginalAbsoluteFilename & """" )
		End If
		Final_Renamed_AbsoluteFilename_AfterRetries = theOriginalAbsoluteFilename
		Final_Renamed_ParentFolderName = fso.GetParentFolderName(theOriginalAbsoluteFilename)
		Final_Renamed_BaseName = fso.GetBaseName(theOriginalAbsoluteFilename)
		Final_Renamed_ExtName = fso.GetExtensionName(theOriginalAbsoluteFilename) ' does not include  the "."
	Else ' is a change to the filename
		If vrdtvs_DEBUG Then 
			'WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_ffiaft_pfis_Rename_a_File: needs a Rename using theOriginalBaseName=""" & theOriginalBaseName & """" )
			'WScript.StdOut.WriteLine("                                                                       NewBaseName=""" & NewBaseName & """" )
			'WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_ffiaft_pfis_Rename_a_File: needs a Rename using theOriginalAbsoluteFilename=""" & theOriginalAbsoluteFilename & """" )
			'WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_ffiaft_pfis_Rename_a_File:                              newAbsoluteFilename=""" & newAbsoluteFilename & """" )
		End If
		Final_Renamed_AbsoluteFilename_AfterRetries = vrdtvs_do_a_Rename_Try99Times(theOriginalAbsoluteFilename, newAbsoluteFilename) ' AUTOFIXING a .BPRJ OCCURS AFTER THIS FUNCTION
		If Final_Renamed_AbsoluteFilename_AfterRetries = "" Then
			' Silly Error detected here, it should never occur unless we have some sort of logic issue ;)
			WScript.StdOut.WriteLine("VRDTVS ERROR: vrdtvs_ffiaft_pfis_Rename_a_File ABORTING: Final_Renamed_AbsoluteFilename_AfterRetries is not properly set after vrdtvs_do_a_Rename_Try99Times <" & Final_Renamed_AbsoluteFilename_AfterRetries & ">")
			Wscript.Echo "Error 17 = cannot perform the requested operation"
			On Error goto 0
			WScript.Quit 17 ' Error 17 = cannot perform the requested operation
		End If
		Final_Renamed_ParentFolderName = fso.GetParentFolderName(Final_Renamed_AbsoluteFilename_AfterRetries)
		Final_Renamed_BaseName = fso.GetBaseName(Final_Renamed_AbsoluteFilename_AfterRetries)
		Final_Renamed_ExtName = fso.GetExtensionName(Final_Renamed_AbsoluteFilename_AfterRetries) ' does not include  the "."
	End If
	'
	' Process an associated .bprj, if one exists
	vrdtvs_status = vrdtvs_ffiaft_pfis_Process_a_BPRJ(theOriginalParentFolderName, theOriginalBaseName, Final_Renamed_ParentFolderName, Final_Renamed_BaseName)
	If vrdtvs_status <> 0 Then ' Something went wrong with processing .BPRJ
		If vrdtvs_DEBUG Then WScript.StdOut.WriteLine("VRDTVS DEBUG: VRDTVS ERROR - vrdtvs_ffiaft_pfis_Rename_a_File Error " & vrdtvs_status & " returned from vrdtvs_ffiaft_pfis_Process_a_BPRJ ... Aborting ...")
		WScript.StdOut.WriteLine("VRDTVS ERROR - vrdtvs_ffiaft_pfis_Rename_a_File Error " & vrdtvs_status & " returned from vrdtvs_ffiaft_pfis_Process_a_BPRJ ... Aborting ...")
		Wscript.Echo "Error 17 = cannot perform the requested operation"
		On Error goto 0
		WScript.Quit 17 ' Error 17 = cannot perform the requested operation
	End If
	'
	'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	'
	local_timerEnd = Timer
    If vrdtvs_DEBUG Then 
		WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_ffiaft_pfis_Rename_a_File: Exit having Elapsed Time " & vrdtvs_Calculate_ElapsedTime_string(local_timerStart, local_timerEnd))
	End If
	' vrdtvs_ffiaft_pfis_Rename_a_File is a Sub, hence no return values
End Sub
'
Function vrdtvs_do_a_Rename_Try99Times(OriginalAbsoluteFilename, TargetAbsoluteFilename)
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
		'WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_do_a_Rename_Try99Times:  incoming Original filename <" & OriginalAbsoluteFilename & ">")
		'WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_do_a_Rename_Try99Times:    incoming Target filename <" & TargetAbsoluteFilename & ">")
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
	WScript.StdOut.WriteLine("VRDTVS vrdtvs_do_a_Rename_Try99Times:  rename <" & theOriginalAbsoluteFilename & ">")
	WScript.StdOut.WriteLine("VRDTVS vrdtvs_do_a_Rename_Try99Times:      to <" & theTargetAbsoluteFilename & ">")
	on error resume next
	If vrdtvs_DEVELOPMENT_NO_ACTIONS Then ' DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV 
		'WScript.StdOut.WriteLine("VRDTVS DEV: vrdtvs_DEVELOPMENT_NO_ACTIONS: DEV: vrdtvs_do_a_Rename_Try99Times NOT DOING 'fso.MoveFile theOriginalAbsoluteFilename, theTargetAbsoluteFilename'")
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
		WScript.StdOut.WriteLine("VRDTVS ERROR: vrdtvs_do_a_Rename_Try99Times ABORTING: error " & vrdtvs_t99tr_ErrNo & " " & vrdtvs_t99tr_ErrDescription & " ... ABORTING since vbscript non-error-58 was detected at first attempt")
		On Error goto 0
		WScript.Quit 17 ' Error 17 = cannot perform the requested operation ' vrdtvs_t99tr_ErrNo
		vrdtvs_do_a_Rename_Try99Times = ""
		Exit Function
	Else ' if it gets to here then it MUST be error 58 = File already exists ... meaning we must re-try up to vrdtvs_t99tr_MaxReTries times
		vrdtvs_t99tr_ErrCount = 0
		vrdtvs_t99tr_ErrNo = 58 ' should already be 58 but set it anyway
		While (vrdtvs_t99tr_ErrNo = 58 AND vrdtvs_t99tr_ErrCount < vrdtvs_t99tr_MaxReTries) ' only vrdtvs_t99tr_MaxReTries number of retries
			vrdtvs_t99tr_ErrCount = vrdtvs_t99tr_ErrCount + 1
			theTargetBaseName = vrdtvs_Move_Date_to_End_of_String(saved_theTargetBaseName & theLeadingCharacterForRetries & vrdtvs_Digits2(vrdtvs_t99tr_ErrCount)) ' REMEMBER TO RE-PUT THE DATE BACK ON THE END OF THE FILENAME STRING
			theTargetAbsoluteFilename =  fso.GetAbsolutePathName(fso.BuildPath(saved_theTargetParentFolderName, theTargetBaseName & "." & saved_theTargetExtName))
			WScript.StdOut.WriteLine("VRDTVS vrdtvs_do_a_Rename_Try99Times:   Retry <" & theTargetAbsoluteFilename & "> Attempt " & vrdtvs_Digits2(vrdtvs_t99tr_ErrCount))
			on error resume next
			If vrdtvs_DEVELOPMENT_NO_ACTIONS Then ' DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV 
				'WScript.StdOut.WriteLine("VRDTVS DEV: vrdtvs_DEVELOPMENT_NO_ACTIONS: DEV: vrdtvs_do_a_Rename_Try99Times retry NOT DOING 'fso.MoveFile theOriginalAbsoluteFilename, theTargetAbsoluteFilename'")
			Else
				fso.MoveFile theOriginalAbsoluteFilename, theTargetAbsoluteFilename ' this is the actual File Rename and theTargetAbsoluteFilename contains an updated Absolte filename to use
			End If
			vrdtvs_t99tr_ErrNo = Err.Number
			vrdtvs_t99tr_ErrDescription = Err.Description
			Err.Clear
			on error goto 0
			If (vrdtvs_t99tr_ErrNo <> 0 AND vrdtvs_t99tr_ErrNo <> 58) Then ' catch any non-0 non-58 error and abort ... it catches everything like that before a Wend
				WScript.StdOut.WriteLine("VRDTVS ERROR: vrdtvs_do_a_Rename_Try99Times ABORTING: error " & vrdtvs_t99tr_ErrNo & " " & vrdtvs_t99tr_ErrDescription & " ... ABORTING since vbscript non-error-58 was detected during retries")
				On Error goto 0
				WScript.Quit 17 ' Error 17 = cannot perform the requested operation ' vrdtvs_t99tr_ErrNo
				vrdtvs_do_a_Rename_Try99Times = ""
				Exit Function
			End If
		Wend ' should Wend on non-58 error number (including 0) or reached max retries
		If (vrdtvs_t99tr_ErrNo = 58 and vrdtvs_t99tr_ErrCount >= vrdtvs_t99tr_MaxReTries) Then ' Error 0 is OK and doesn't get caught by this test
			WScript.StdOut.WriteLine("VRDTVS ERROR: vrdtvs_do_a_Rename_Try99Times ABORTING: error " & vrdtvs_t99tr_ErrNo & " - ABORTING since done " & vrdtvs_t99tr_ErrCount & " retries and still detected error-58 File already exists")
			Wscript.Echo "Error 17 = cannot perform the requested operation"
			On Error goto 0
			WScript.Quit 17 ' Error 17 = cannot perform the requested operation
			vrdtvs_do_a_Rename_Try99Times = ""
			Exit Function
		End If
	End If
	on error goto 0
	vrdtvs_do_a_Rename_Try99Times = theTargetAbsoluteFilename ' Final Renamed AbsoluteFilename After Retries
End Function
'
Function vrdtvs_ffiaft_pfis_Process_a_BPRJ (byVal theOriginalParentFolderName, byVal theOriginalBaseName, byVal Final_Renamed_ParentFolderName, byVal Final_Renamed_BaseName)
    ' Parameters:
	'		theOriginalParentFolderName		byVal	Folder of the filename to be renamed and/or fixed
	'		theOriginalBaseName				byVal	BaseName of the filename to be renamed and/or fixed
	'		Final_Renamed_ParentFolderName	byVal	Optional Folder of the filename to be renamed into (the target)   ... if "" then becomes theOriginalParentFolderName
	'		Final_Renamed_BaseName			byVal	Optional BaseName of the filename to be renamed into (the target) ... if "" then becomes theOriginalBaseName
	' byVal means any changes to the parmater won't be transferred back to the caller
	'
	Dim Original_BPRJ_AbsoluteFilename
	Dim Final_Renamed_BPRJ_AbsoluteFilename
	Dim xml_file_to_load
	Dim bprj_status, bprj_objErr, bprj_errorCode, bprj_reason
	Dim bprj_nNode, bprj_i, bprj_txtbefore, bprj_txtafter, bprj_ErrNo, bprj_ErrDescription
	Dim vrdtvs_xmlDoc, bprj_xmlbefore, bprj_xmlafter
	Dim vrdtvs_xslDoc
	Const vrdtvs_xslStylesheet_string = "<xsl:stylesheet version=""3.0"" xmlns:xsl=""http://www.w3.org/1999/XSL/Transform"" xmlns=""http://www.w3.org/1999/xhtml""><xsl:output method=""xml"" indent=""yes""/><xsl:template match=""/""><xsl:copy-of select="".""/></xsl:template></xsl:stylesheet>"
	'Const vrdtvs_xslStylesheet_string = _
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
	' ***** If a matching .bprj file exists in the same folder, (a) rename it to match the new filename (b) fix the content of .bprj file (it's xml) to match the media filename 
	' ***** note: .bprj files should only exist for files aready converted to .mp4 ... ie in the destination folder
	' *****       however, in this code we choose to re-process/fix the associated .bprj files REGARDLESS of whether they are renamed or not !!!!!
	If Final_Renamed_ParentFolderName = "" OR Final_Renamed_BaseName = "" Then ' if the target is "" then make it the same name as the source so that no file renme occurs
		Final_Renamed_ParentFolderName = theOriginalParentFolderName
		Final_Renamed_BaseName = theOriginalBaseName
	End If
	Original_BPRJ_AbsoluteFilename = fso.GetAbsolutePathName( fso.BuildPath(theOriginalParentFolderName,theOriginalBaseName & ".bprj"))
	Final_Renamed_BPRJ_AbsoluteFilename = fso.GetAbsolutePathName( fso.BuildPath(Final_Renamed_ParentFolderName,Final_Renamed_BaseName & ".bprj"))
	If fso.FileExists(Original_BPRJ_AbsoluteFilename) Then 
		' yeppity, a matching .bprj file is FOUND for the original media filename
		If vrdtvs_DEBUG Then 
			WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_ffiaft_pfis_Process_a_BPRJ: ********** found a matching .bprj file to autofix: """ & Original_BPRJ_AbsoluteFilename & """")
		End If
		If Original_BPRJ_AbsoluteFilename = Final_Renamed_BPRJ_AbsoluteFilename Then
			WScript.StdOut.WriteLine("VRDTVS vrdtvs_ffiaft_pfis_Process_a_BPRJ same filenames, NOT RENAMING """ & Original_BPRJ_AbsoluteFilename & """ to """ & Final_Renamed_BPRJ_AbsoluteFilename & """")
			If vrdtvs_DEBUG Then WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_ffiaft_pfis_Process_a_BPRJ: same filenames, NOT RENAMING """ & Original_BPRJ_AbsoluteFilename & """ to """ & Final_Renamed_BPRJ_AbsoluteFilename & """")
		Else
			' a) rename the .bprj file to match the new BaseName of the media file ... abort on a failure to simply rename the .bprj file
			on error resume next
			If vrdtvs_DEVELOPMENT_NO_ACTIONS Then ' DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV 
				WScript.StdOut.WriteLine("VRDTVS DEV: vrdtvs_DEVELOPMENT_NO_ACTIONS: DEV: vrdtvs_ffiaft_pfis_Process_a_BPRJ NOT RENAMING """ & Original_BPRJ_AbsoluteFilename & """ to """ & Final_Renamed_BPRJ_AbsoluteFilename & """")
			Else
				fso.MoveFile Original_BPRJ_AbsoluteFilename, Final_Renamed_BPRJ_AbsoluteFilename ' this is the actual File Rename
			End If
			bprj_ErrNo = Err.Number
			bprj_ErrDescription = Err.Description
			Err.Clear
			on error goto 0
			If (bprj_ErrNo <> 0) Then ' Error 0 is OK meaning it renamed just fine
				WScript.StdOut.WriteLine("VRDTVS ERROR: vrdtvs_ffiaft_pfis_Process_a_BPRJ ABORTING: error renaming .bprj ErrorNo: " & bprj_ErrNo & " Description: " & bprj_ErrDescription)
				WScript.StdOut.WriteLine("VRDTVS ERROR: vrdtvs_ffiaft_pfis_Process_a_BPRJ ABORTING: error renaming .bprj      Original_BPRJ_AbsoluteFilename=""" & Original_BPRJ_AbsoluteFilename & """")
				WScript.StdOut.WriteLine("VRDTVS ERROR: vrdtvs_ffiaft_pfis_Process_a_BPRJ ABORTING: error renaming .bprj Final_Renamed_BPRJ_AbsoluteFilename=""" & Final_Renamed_BPRJ_AbsoluteFilename & """")
				Wscript.Echo "Error 17 = cannot perform the requested operation"
				On Error goto 0
				WScript.Quit 17 ' Error 17 = cannot perform the requested operation
			End If
		End If
		' b) process/fix the content of .bprj file (it's xml) so the media filename in it is updated to match the renamed media filename
		' load the file Final_Renamed_BPRJ_AbsoluteFilename and replace the file part with Final_Renamed_BaseName in it
		Set vrdtvs_xmlDoc = CreateObject("Microsoft.XMLDOM")
		vrdtvs_xmlDoc.async = False
		on error resume next 
		xml_file_to_load = Final_Renamed_BPRJ_AbsoluteFilename
		If vrdtvs_DEVELOPMENT_NO_ACTIONS Then ' DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV 
			xml_file_to_load = Original_BPRJ_AbsoluteFilename
			If vrdtvs_DEBUG Then WScript.StdOut.WriteLine("VRDTVS DEV: vrdtvs_ffiaft_pfis_Process_a_BPRJ: about to LOAD vrdtvs_xmlDoc.load ORIGINAL file """ & Original_BPRJ_AbsoluteFilename & """")
			bprj_status = vrdtvs_xmlDoc.load(Original_BPRJ_AbsoluteFilename) 
		Else
			xml_file_to_load = Final_Renamed_BPRJ_AbsoluteFilename
			If vrdtvs_DEBUG Then WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_ffiaft_pfis_Process_a_BPRJ: about to LOAD vrdtvs_xmlDoc.load file """ & Final_Renamed_BPRJ_AbsoluteFilename & """")
			bprj_status = vrdtvs_xmlDoc.load(Final_Renamed_BPRJ_AbsoluteFilename) 
		End If
		Set bprj_objErr = vrdtvs_xmlDoc.parseError
		bprj_errorCode = bprj_objErr.errorCode
		bprj_reason = bprj_objErr.reason
		Set bprj_objErr = Nothing
		Err.clear
		on error goto 0 
		If NOT bprj_status Then
			WScript.StdOut.WriteLine("VRDTVS ERROR: vrdtvs_ffiaft_pfis_Process_a_BPRJ ABORTING: Failed to load XML doc .BPRJ file """ & xml_file_to_load & """")
			WScript.StdOut.WriteLine("VRDTVS ERROR: vrdtvs_ffiaft_pfis_Process_a_BPRJ ABORTING: bprj_status: " & bprj_status & " XML error: " & bprj_errorCode & " : " & bprj_reason)
			Wscript.Echo "Error 17 = cannot perform the requested operation"
			On Error goto 0
			WScript.Quit 17 ' Error 17 = cannot perform the requested operation
		End If
		'WScript.StdOut.WriteLine("vbs_rename_files: debug: loaded xml doc " & new_name)
		'Locate the desired node. Note the use of XPATH instead of looping over all the child nodes.
		Set bprj_nNode = vrdtvs_xmlDoc.selectsinglenode ("//VideoReDoProject/Filename")
		If bprj_nNode is Nothing Then
			WScript.StdOut.WriteLine("VRDTVS ERROR: vrdtvs_ffiaft_pfis_Process_a_BPRJ ABORTING: Could not find XML node //VideoReDoProject/Filename in file " & xml_file_to_load)
			Wscript.Echo "Error 17 = cannot perform the requested operation"
			On Error goto 0
			WScript.Quit 17 ' Error 17 = cannot perform the requested operation exit with an error ... soft or hard ?
		End If
		bprj_txtbefore = bprj_nNode.text ' this is the pathname to the associated media file 
		' find the rightmost \ then replace everything at it to the start with .\ ... i.e. replace the full path of the associated media file with "\."
		' if a \ doesn't exist, add .\ to the start
		bprj_i = InStrRev(bprj_txtbefore,"\",-1,vbTextCompare)
		If bprj_i > 0 Then
			bprj_txtafter = ".\" & mid(bprj_txtbefore,bprj_i+1)
		Else
			bprj_txtafter = ".\" & bprj_txtbefore
		End If
		' replace the old basename portion of the associated media filename with the renamed basename portion
		bprj_txtafter = Replace(bprj_txtafter, fso.GetBaseName(Original_BPRJ_AbsoluteFilename), fso.GetBaseName(Final_Renamed_BPRJ_AbsoluteFilename), 1, -1, vbTextCompare)
		bprj_xmlbefore = vrdtvs_xmlDoc.xml ' save the overall XML before we fix and transform
		bprj_nNode.text = bprj_txtafter ' load the edited text back intothe XML document
		'''' ??????????? try to in-place transform the XML string using an XSL stylesheet  per https://blogs.iis.net/robert_mcmurray/creating-quot-pretty-quot-xml-using-xsl-and-vbscript
		Set vrdtvs_xslDoc = CreateObject("Microsoft.XMLDOM") ' or perhaps this instead: Set vrdtvs_xslDoc = WScript.CreateObject("Msxml2.DOMDocument") ' assume no error
		vrdtvs_xslDoc.async = False
		If vrdtvs_DEBUG Then
			WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_ffiaft_pfis_Process_a_BPRJ: about to load XSL vrdtvs_xslStylesheet_string: ")
			WScript.StdOut.WriteLine("" & vrdtvs_xslStylesheet_string & "")
		End If
		on error resume next 
		bprj_status = vrdtvs_xslDoc.loadXML(vrdtvs_xslStylesheet_string) ' load the xsl stylesheet string
		Set bprj_objErr = vrdtvs_xslDoc.parseError
		bprj_errorCode = bprj_objErr.errorCode
		bprj_reason = bprj_objErr.reason
		Set bprj_objErr = Nothing
		Err.clear
		on error goto 0
		If NOT bprj_status Then ' Error 0 is OK
			WScript.StdOut.WriteLine("VRDTVS ERROR: vrdtvs_ffiaft_pfis_Process_a_BPRJ ABORTING: XSL vrdtvs_xslStylesheet_string load error bprj_status: " & bprj_status & " ErrorCode: " & bprj_errorCode & " : " & bprj_reason)
			Wscript.Echo "Error 17 = cannot perform the requested operation"
			On Error goto 0
			WScript.Quit 17 ' Error 17 = cannot perform the requested operation
		End If
		on error resume next 
		bprj_txtafter = vrdtvs_xmlDoc.transformNode(vrdtvs_xslDoc) ' transform using the xsl stylesheet
		Set bprj_objErr = vrdtvs_xslDoc.parseError
		bprj_errorCode = bprj_objErr.errorCode
		bprj_reason = bprj_objErr.reason
		Set bprj_objErr = Nothing
		Err.clear
		on error goto 0
		If (bprj_errorCode <> 0) Then ' Error 0 is OK
			WScript.StdOut.WriteLine("VRDTVS ERROR: vrdtvs_ffiaft_pfis_Process_a_BPRJ ABORTING: XML/XSL transformNode error bprj_status: " & bprj_status & " ErrorCode: " & bprj_errorCode & " : " & bprj_reason)
			Wscript.Echo "Error 17 = cannot perform the requested operation"
			On Error goto 0
			WScript.Quit 17 ' Error 17 = cannot perform the requested operation
		End If
		bprj_xmlafter = vrdtvs_xmlDoc.xml ' save the overall XML after we fix and transform
		If vrdtvs_DEBUG Then
			WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_ffiaft_pfis_Process_a_BPRJ: bprj xml-node before: """ & bprj_txtbefore & """")
			WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_ffiaft_pfis_Process_a_BPRJ: bprj xml-node  after: """ & bprj_nNode.text & """")
			WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_ffiaft_pfis_Process_a_BPRJ: xml ALL before: " & bprj_xmlbefore & "")
			WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_ffiaft_pfis_Process_a_BPRJ: xml ALL  after: " & bprj_xmlafter & "")
		End If
		on error resume next 
		If vrdtvs_DEVELOPMENT_NO_ACTIONS Then ' DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV 
			WScript.StdOut.WriteLine("VRDTVS DEV: vrdtvs_DEVELOPMENT_NO_ACTIONS: DEV: vrdtvs_ffiaft_pfis_Process_a_BPRJ NOT RE-WRITING bprj """ & Final_Renamed_BPRJ_AbsoluteFilename & """")
		Else
			vrdtvs_xmlDoc.save(Final_Renamed_BPRJ_AbsoluteFilename) ' tell the XMLDOM processor to save the updated XML file
		End If
		Set bprj_objErr = vrdtvs_xmlDoc.parseError
		bprj_errorCode = bprj_objErr.errorCode
		bprj_reason = bprj_objErr.reason
		Set bprj_objErr = Nothing
		Err.clear
		on error goto 0 
		If not bprj_status Then
			WScript.StdOut.WriteLine("VRDTVS ERROR: vrdtvs_ffiaft_pfis_Process_a_BPRJ ABORTING: Failed to save XML doc into .BPRJ file """ & Final_Renamed_BPRJ_AbsoluteFilename & """")
			WScript.StdOut.WriteLine("VRDTVS ERROR: vrdtvs_ffiaft_pfis_Rename_a_File ABORTING: XML error: " & bprj_errorCode & " : Reason: " & bprj_reason)
			On Error goto 0
			WScript.Quit 17 ' Error 17 = cannot perform the requested operation
		End If
		Set vrdtvs_xmlDoc = Nothing
		WScript.StdOut.WriteLine("VRDTVS vrdtvs_ffiaft_pfis_Process_a_BPRJ .bprj autofixed: """ & Original_BPRJ_AbsoluteFilename & """ into """ & Final_Renamed_BPRJ_AbsoluteFilename & """")
	Else
		If vrdtvs_DEBUG Then 
			WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_ffiaft_pfis_Process_a_BPRJ: ********** NO matching .bprj file found to autofix: """ & Original_BPRJ_AbsoluteFilename & """")
		End If
	End If
	vrdtvs_ffiaft_pfis_Process_a_BPRJ = 0
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
								Wscript.Echo "Error 17 = cannot perform the requested operation"
								On Error goto 0
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
	theNewString = Replace(theNewString, "--", "-", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "..", ".", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "-.", ".", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, ".-", ".", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "_.", ".", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "._", ".", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "_-", "_", 1, -1, vbTextCompare)
	theNewString = Replace(theNewString, "-_", "_", 1, -1, vbTextCompare)
	timerEnd_MDES = Timer
    'If vrdtvs_DEBUG Then WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_Move_Date_to_End_of_String: exiting with return value   """ & theNewString & """ having Loop Elapsed Time " & vrdtvs_Calculate_ElapsedTime_string(timerStart_MDES, timerEnd_MDES))
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
		'vrdtvs_ReplaceStartStringCaseIndependent = Replace(theString, theSearchString, theReplaceString, 1, 1, vbTextCompare)
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
Function vrdtvs_Convert_files_in_a_folder(	byVal	C_source_TS_Folder, _
											byVal	C_done_TS_Folder, _
											byVal	C_destination_mp4_Folder, _
											byVal	C_failed_conversion_TS_Folder, _
											byVal	C_temp_path, _
											byVal	C_saved_ffmpeg_commands_filename, _
											byVal	C_do_qsf, _
											byVal	C_do_Adcsan )
	' Loop and convert .TS .mp4 .mpg Source files in a folder into acceptable avc/aac .mp4 Destination files 
    ' Parameters: see below
	' NOTES: 
	'	Rely on these already being set Globally to True or False BEFORE invoking the conversion function: vrdtvs_DEBUG, vrdtvs_DEVELOPMENT_NO_ACTIONS, wso, fso, vrdtvs_status
	'	Check for C_source_TS_Folder = C_destination_mp4_Folder since we don't permit that
	'	Convert .TS and .MP4 and .MPG files in the C_source_TS_Folder and create adscan .BPRJ files
	'	Resulting .mp4 and .bprj goes into C_destination_mp4_Folder
	'	Successfilly completed .TS and .MP4 and .MPG files (and associated .BPRJ, if any) goes into C_done_TS_Folder 
	'	Failed-to-convert .TS and .MP4 files (and associated .BPRJ, if any) goes into C_failed_conversion_TS_Folder 
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
	WScript.StdOut.WriteLine("VRDTVS vrdtvs_Convert_files_in_a_folder STARTED " & vrdtvs_current_datetime_string() & " ======================================================================================================================================================")
	WScript.StdOut.WriteLine("VRDTVS vrdtvs_Convert_files_in_a_folder:                C_source_TS_Folder=""" & C_source_TS_Folder & """")
	WScript.StdOut.WriteLine("VRDTVS vrdtvs_Convert_files_in_a_folder:                  C_done_TS_Folder=""" & C_done_TS_Folder & """")
	WScript.StdOut.WriteLine("VRDTVS vrdtvs_Convert_files_in_a_folder:          C_destination_mp4_Folder=""" & C_destination_mp4_Folder & """")
	WScript.StdOut.WriteLine("VRDTVS vrdtvs_Convert_files_in_a_folder:     C_failed_conversion_TS_Folder=""" & C_failed_conversion_TS_Folder & """")
	WScript.StdOut.WriteLine("VRDTVS vrdtvs_Convert_files_in_a_folder:                       C_temp_path=""" & C_temp_path & """")
	WScript.StdOut.WriteLine("VRDTVS vrdtvs_Convert_files_in_a_folder:  C_saved_ffmpeg_commands_filename=""" & C_saved_ffmpeg_commands_filename & """")
	WScript.StdOut.WriteLine("VRDTVS vrdtvs_Convert_files_in_a_folder:                          C_do_qsf=""" & C_do_qsf & """")
	WScript.StdOut.WriteLine("VRDTVS vrdtvs_Convert_files_in_a_folder:                       C_do_Adcsan=""" & C_do_Adcsan & """")
	'
	' force absolute PathNnames
	C_source_TS_Folder = fso.GetAbsolutePathName(C_source_TS_Folder & "\")
	C_done_TS_Folder = fso.GetAbsolutePathName(C_done_TS_Folder & "\")
	C_destination_mp4_Folder = fso.GetAbsolutePathName(C_destination_mp4_Folder & "\")
	C_failed_conversion_TS_Folder = fso.GetAbsolutePathName(C_failed_conversion_TS_Folder & "\")
	C_temp_path = fso.GetAbsolutePathName(C_temp_path & "\")
	C_saved_ffmpeg_commands_filename = fso.GetAbsolutePathName(C_saved_ffmpeg_commands_filename & "\")
	'
	If vrdtvs_DEBUG Then 
		WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_Convert_files_in_a_folder - Entered with parameters: ")
		WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_Convert_files_in_a_folder Saved ffmpeg commands: """ & C_saved_ffmpeg_commands_filename & """")
		WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_Convert_files_in_a_folder Created on " & vrdtvs_current_datetime_string)
		WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_Convert_files_in_a_folder                          ""vs_root=" & vs_root & """")
		WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_Convert_files_in_a_folder              ""vrdtvs_mp4boxexex64=" & vrdtvs_mp4boxexex64 & """")
		WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_Convert_files_in_a_folder            ""vrdtvs_mediainfoexe64=" & vrdtvs_mediainfoexe64 & """")
		WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_Convert_files_in_a_folder              ""vrdtvs_ffprobeexe64=" & vrdtvs_ffprobeexe64 & """")
		WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_Convert_files_in_a_folder               ""vrdtvs_ffmpegexe64=" & vrdtvs_ffmpegexe64 & """")
		WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_Convert_files_in_a_folder            ""vrdtvs_dgindexNVexe64=" & vrdtvs_dgindexNVexe64 & """")
		WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_Convert_files_in_a_folder             ""vrdtvs_Insomniaexe64=" & vrdtvs_Insomniaexe64 & """")
		WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_Convert_files_in_a_folder               ""C_source_TS_Folder=" & C_source_TS_Folder & """")
		WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_Convert_files_in_a_folder                 ""C_done_TS_Folder=" & C_done_TS_Folder & """")
		WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_Convert_files_in_a_folder         ""C_destination_mp4_Folder=" & C_destination_mp4_Folder & """")
		WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_Convert_files_in_a_folder    ""C_failed_conversion_TS_Folder=" & C_failed_conversion_TS_Folder & """")
		WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_Convert_files_in_a_folder                      ""C_temp_path=" & C_temp_path & """")
		WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_Convert_files_in_a_folder   ""vrd_profile_name_for_qsf_mpeg2=" & vrd_profile_name_for_qsf_mpeg2 & """")
		WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_Convert_files_in_a_folder              ""vrd_extension_mpeg2=" & vrd_extension_mpeg2 & """")
		WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_Convert_files_in_a_folder     ""vrd_profile_name_for_qsf_avc=" & vrd_profile_name_for_qsf_avc & """")
		WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_Convert_files_in_a_folder                ""vrd_extension_avc=" & vrd_extension_avc & """")
		WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_Convert_files_in_a_folder              ""vrd_version_for_qsf=" & vrd_version_for_qsf & """")
		WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_Convert_files_in_a_folder             ""vrd_path_for_qsf_vbs=" & vrd_path_for_qsf_vbs & """")
		WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_Convert_files_in_a_folder           ""vrd_version_for_adscan=" & vrd_version_for_adscan & """")
		WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_Convert_files_in_a_folder          ""vrd_path_for_adscan_vbs=" & vrd_path_for_adscan_vbs & """")
		WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_Convert_files_in_a_folder ""C_saved_ffmpeg_commands_filename=" & C_saved_ffmpeg_commands_filename & """")
		WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_Convert_files_in_a_folder                         ""C_do_qsf=" & C_do_qsf & """")
		WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_Convert_files_in_a_folder                      ""C_do_Adcsan=" & C_do_Adcsan & """")
	End If
	'
	' delete the saved FFMPEG COMMANDS file silently 
	vrdtvs_status = vrdtvs_delete_a_file(C_saved_ffmpeg_commands_filename, True)
	If vrdtvs_status <> 0 AND vrdtvs_status <> 53 Then ' Something went wrong with deleting the file, but allow 53 "File not found"
		If vrdtvs_DEBUG Then WScript.StdOut.WriteLine("VRDTVS DEBUG: VRDTVS ERROR vrdtvs_Convert_files_in_a_folder - Error " & vrdtvs_status & " from vrdtvs_delete_a_file with saved FFMPEG COMMANDS """ & C_saved_ffmpeg_commands_filename & """... Aborting ...")
		WScript.StdOut.WriteLine("VRDTVS ERROR vrdtvs_Convert_files_in_a_folder - Error " & vrdtvs_status & " from vrdtvs_delete_a_file with saved FFMPEG COMMANDS """ & C_saved_ffmpeg_commands_filename & """... Aborting ...")
		Wscript.Echo "Error 17 = cannot perform the requested operation"
		On Error goto 0
		WScript.Quit 17 ' Error 17 = cannot perform the requested operation
	End If
	' create a new empty FFMPEG COMMANDS file with overwrite
	set C_object_saved_ffmpeg_commands = fso.CreateTextFile(C_saved_ffmpeg_commands_filename, True, False) ' *** make .BAT file ascii for compatibility, since vapoursynth fails with unicode files [ filename, Overwrite[, Unicode]])
	If C_object_saved_ffmpeg_commands is Nothing  Then ' Something went wrong with creating the file
		If vrdtvs_DEBUG Then WScript.StdOut.WriteLine("VRDTVS DEBUG: VRDTVS ERROR vrdtvs_Convert_files_in_a_folder - Error - Nothing object returned from fso.CreateTextFile with saved FFMPEG COMMANDS """ & C_saved_ffmpeg_commands_filename & """... Aborting ...")
		WScript.StdOut.WriteLine("VRDTVS ERROR vrdtvs_Convert_files_in_a_folder - Error - Nothing object returned from fso.CreateTextFile with saved FFMPEG COMMANDS """ & C_saved_ffmpeg_commands_filename & """... Aborting ...")
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
	C_object_saved_ffmpeg_commands.WriteLine("REM Computername=""" & vrdtvs_ComputerName & """" )
	C_object_saved_ffmpeg_commands.WriteLine("REM Saved ffmpeg commands: """ & C_saved_ffmpeg_commands_filename & """")
	C_object_saved_ffmpeg_commands.WriteLine("REM Created " & vrdtvs_current_datetime_string)
	C_object_saved_ffmpeg_commands.WriteLine("REM")
	C_object_saved_ffmpeg_commands.WriteLine("Set ""vs_root=" & vs_root & """")
	C_object_saved_ffmpeg_commands.WriteLine("Set ""vrdtvs_mp4boxexex64=" & vrdtvs_mp4boxexex64 & """")
	C_object_saved_ffmpeg_commands.WriteLine("Set ""vrdtvs_mediainfoexe64=" & vrdtvs_mediainfoexe64 & """")
	C_object_saved_ffmpeg_commands.WriteLine("Set ""vrdtvs_ffprobeexe64=" & vrdtvs_ffprobeexe64 & """")
	C_object_saved_ffmpeg_commands.WriteLine("Set ""vrdtvs_ffmpegexe64=" & vrdtvs_ffmpegexe64 & """")
	C_object_saved_ffmpeg_commands.WriteLine("Set ""vrdtvs_dgindexNVexe64=" & vrdtvs_dgindexNVexe64 & """")
	C_object_saved_ffmpeg_commands.WriteLine("Set ""vrdtvs_Insomniaexe64=" & vrdtvs_Insomniaexe64 & """")
	C_object_saved_ffmpeg_commands.WriteLine("REM")
	C_object_saved_ffmpeg_commands.WriteLine("Set ""C_source_TS_Folder=" & C_source_TS_Folder & """")
	C_object_saved_ffmpeg_commands.WriteLine("Set ""C_done_TS_Folder=" & C_done_TS_Folder & """")
	C_object_saved_ffmpeg_commands.WriteLine("Set ""C_destination_mp4_Folder=" & C_destination_mp4_Folder & """")
	C_object_saved_ffmpeg_commands.WriteLine("Set ""C_failed_conversion_TS_Folder=" & C_failed_conversion_TS_Folder & """")
	C_object_saved_ffmpeg_commands.WriteLine("Set ""C_temp_path=" & C_temp_path & """")
	C_object_saved_ffmpeg_commands.WriteLine("REM")
	C_object_saved_ffmpeg_commands.WriteLine("Set ""vrd_profile_name_for_qsf_mpeg2=" & vrd_profile_name_for_qsf_mpeg2 & """")
	C_object_saved_ffmpeg_commands.WriteLine("Set ""vrd_extension_mpeg2=" & vrd_extension_mpeg2 & """")
	C_object_saved_ffmpeg_commands.WriteLine("Set ""vrd_profile_name_for_qsf_avc=" & vrd_profile_name_for_qsf_avc & """")
	C_object_saved_ffmpeg_commands.WriteLine("Set ""vrd_extension_avc=" & vrd_extension_avc & """")
	C_object_saved_ffmpeg_commands.WriteLine("REM")
	C_object_saved_ffmpeg_commands.WriteLine("Set ""vrd_version_for_qsf=" & vrd_version_for_qsf & """")
	C_object_saved_ffmpeg_commands.WriteLine("Set ""vrd_path_for_qsf_vbs=" & vrd_path_for_qsf_vbs & """")
	C_object_saved_ffmpeg_commands.WriteLine("Set ""vrd_version_for_adscan=" & vrd_version_for_adscan & """")
	C_object_saved_ffmpeg_commands.WriteLine("Set ""vrd_path_for_adscan_vbs=" & vrd_path_for_adscan_vbs & """")
	C_object_saved_ffmpeg_commands.WriteLine("REM")
	C_object_saved_ffmpeg_commands.WriteLine("Set ""C_saved_ffmpeg_commands_filename=" & C_saved_ffmpeg_commands_filename & """")
	C_object_saved_ffmpeg_commands.WriteLine("Set ""C_do_qsf=" & C_do_qsf & """")
	C_object_saved_ffmpeg_commands.WriteLine("Set ""C_do_Adcsan=" & C_do_Adcsan & """")
	C_object_saved_ffmpeg_commands.WriteLine("REM")
	C_object_saved_ffmpeg_commands.WriteLine("REM NO FILES WILL BE MOVED between folders ")
	C_object_saved_ffmpeg_commands.WriteLine("REM the SOURCE      .TS and .mp4 and .mpg media files MUST already exist in folder: """ & C_source_TS_Folder & """")
	C_object_saved_ffmpeg_commands.WriteLine("REM the DESTINATION .mp4 and .bprj files will be created (overwritten) in folder  : """ & C_destination_mp4_Folder & """")
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
		If Ucase(C_FILE_Ext) = Ucase("ts") OR Ucase(C_FILE_Ext) = Ucase("mp4") OR Ucase(C_FILE_Ext) = Ucase("mpg") OR Ucase(C_FILE_Ext) = Ucase("bprj") Then ' ********** only process specific file extensions
			WScript.StdOut.WriteLine(" ")
			WScript.StdOut.WriteLine(" ")
			WScript.StdOut.WriteLine("VRDTVS vrdtvs_Convert_files_in_a_folder ========== Processing C_FILE_AbsolutePathName=""" & C_FILE_AbsolutePathName & """ ==========")
			Select Case Ucase(C_FILE_Ext)
			Case Ucase("bprj") 										' it's in the source folder, ignore it
			Case Ucase("ts"), Ucase("mp4"), Ucase("mpg")			' if it's one of these then convert it
				vrdtvs_status = vrdtvs_Convert_File(	C_FILE_AbsolutePathName, _
														C_object_saved_ffmpeg_commands, _
														C_source_TS_Folder, _
														C_done_TS_Folder, _
														C_destination_mp4_Folder, _
														C_failed_conversion_TS_Folder, _
														C_temp_path, _
														C_saved_ffmpeg_commands_filename, _
														C_do_qsf, _
														C_do_Adcsan )
			Case Else	' extension not recognised, do nothing
			End Select 
		End If
	Next
	'
	vrdtvs_status = C_object_saved_ffmpeg_commands.Close
	Set C_object_saved_ffmpeg_commands = Nothing
	WScript.StdOut.WriteLine("VRDTVS vrdtvs_Convert_files_in_a_folder FINISHED " & vrdtvs_current_datetime_string() & " ======================================================================================================================================================")
	vrdtvs_Convert_files_in_a_folder = 0 ' return success
End Function
'
Function vrdtvs_exec_a_command_and_show_stdout_stderr (byVal eac_command_string)
	Dim  eac_exe_cmd_string, eac_exe_object, eac_exe_status, eac_tmp
	If eac_command_string = "" then
		vrdtvs_exec_a_command = 0
		Exit Function
	End If
	' Examples with and without CMD and 2>&1
	'		eac_exe_cmd_string = "CMD /C ""something"""
	'		eac_exe_cmd_string = "CMD /C ""something"" 2>&1"
	'		eac_exe_cmd_string = "Taskkill ""something"""
	'		eac_exe_cmd_string = "Taskkill ""something"" 2>&1"
	If vrdtvs_DEVELOPMENT_NO_ACTIONS Then ' DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV 
		eac_exe_object = "REM " & eac_command_string ' comment out any action
	End If
	WScript.StdOut.WriteLine("vrdtvs_exec_a_command_and_show_stdout_stderr Exec command: " & eac_command_string)
	set eac_exe_object = wso.Exec(eac_command_string)
	Do While eac_exe_object.Status = 0 '0 is running and 1 is ending
	 	Wscript.Sleep 100
		 'Wscript.Echo "vrdtvs_exec_a_command_and_show_stdout_stderr About to sleep for 5 seconds"
		 'Wscript.Sleep 5000
	Loop
	WScript.StdOut.WriteLine("vrdtvs_exec_a_command_and_show_stdout_stderr START StdOut: ")
	Do Until eac_exe_object.StdOut.AtEndOfStream
		eac_tmp = eac_exe_object.StdOut.ReadLine()
		WScript.StdOut.WriteLine(eac_tmp)
	Loop
	WScript.StdOut.WriteLine("vrdtvs_exec_a_command_and_show_stdout_stderr END   StdOut: ")
	WScript.StdOut.WriteLine("vrdtvs_exec_a_command_and_show_stdout_stderr START StdErr: ")
	Do Until eac_exe_object.StdErr.AtEndOfStream
		eac_tmp = eac_exe_object.StdErr.ReadLine()
		WScript.StdOut.WriteLine(eac_tmp)
	Loop
	WScript.StdOut.WriteLine("vrdtvs_exec_a_command_and_show_stdout_stderr END   StdErr: ")
	eac_exe_status = eac_exe_object.ExitCode
	WScript.StdOut.WriteLine("vrdtvs_exec_a_command_and_show_stdout_stderr Exit Status: " & eac_exe_status)
	Set eac_exe_object = Nothing
	If vrdtvs_DEBUG Then WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_exec_a_command_and_show_stdout_stderr exiting with status=""" & eac_exe_status & """")
	vrdtvs_exec_a_command_and_show_stdout_stderr = eac_exe_status
End Function
'
Function vrdtvs_exec_a_FFMPEG_command_and_show_stderr_only (byVal eac_command_string)
	Dim  eac_exe_cmd_string, eac_exe_object, eac_exe_status, eac_tmp
	If eac_command_string = "" then
		vrdtvs_exec_a_command = 0
		Exit Function
	End If
	If vrdtvs_DEVELOPMENT_NO_ACTIONS Then ' DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV 
		eac_exe_object = "REM " & eac_command_string ' comment out any action
	End If
	WScript.StdOut.WriteLine("vrdtvs_exec_a_command_and_show_stdout_stderr Exec command: " & eac_command_string)
	set eac_exe_object = wso.Exec(eac_command_string)
	Do While eac_exe_object.Status = 0 '0 is running and 1 is ending
	 	Wscript.Sleep 100
		'Wscript.Echo "vrdtvs_exec_a_FFMPEG_command_and_show_stderr_only About to sleep for 5 seconds"
		'Wscript.Sleep 5000
	Loop
	'WScript.StdOut.WriteLine("vrdtvs_exec_a_command_and_show_stdout_stderr START StdOut: ")
	'Do Until eac_exe_object.StdOut.AtEndOfStream
	'	eac_tmp = eac_exe_object.StdOut.ReadLine()
	'	WScript.StdOut.WriteLine(eac_tmp)
	'Loop
	'WScript.StdOut.WriteLine("vrdtvs_exec_a_command_and_show_stdout_stderr END   StdOut: ")
	WScript.StdOut.WriteLine("vrdtvs_exec_a_command_and_show_stdout_stderr START StdErr: ")
	Do Until eac_exe_object.StdErr.AtEndOfStream
		eac_tmp = eac_exe_object.StdErr.ReadLine()
		WScript.StdOut.WriteLine(eac_tmp)
	Loop
	WScript.StdOut.WriteLine("vrdtvs_exec_a_command_and_show_stdout_stderr END   StdErr: ")
	eac_exe_status = eac_exe_object.ExitCode
	WScript.StdOut.WriteLine("vrdtvs_exec_a_command_and_show_stdout_stderr Exit Status: " & eac_exe_status)
	Set eac_exe_object = Nothing
	If vrdtvs_DEBUG Then WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_exec_a_command_and_show_stdout_stderr exiting with status=""" & eac_exe_status & """")
	vrdtvs_exec_a_command_and_show_stdout_stderr = eac_exe_status
End Function
'
Function vrdtvs_Convert_File (	byVal	CF_FILE_AbsolutePathName, _
								byRef	CF_object_saved_ffmpeg_commands, _
								byVal 	CF_source_TS_Folder, _
								byVal 	CF_done_TS_Folder, _
								byVal 	CF_destination_mp4_Folder, _
								byVal 	CF_failed_conversion_TS_Folder, _
								byVal 	CF_temp_path, _
								byVal 	CF_saved_ffmpeg_commands_filename, _
								byVal 	CF_do_qsf, _
								byVal 	CF_do_Adcsan )
	'Dim CF_FILE_AbsolutePathName
	Dim                             CF_FILE_ParentFolderName,   CF_FILE_BaseName,   CF_FILE_Ext
	Dim CF_QSF_AbsolutePathName,    CF_QSF_ParentFolderName,    CF_QSF_BaseName,    CF_QSF_Ext
	Dim CF_TARGET_AbsolutePathName, CF_TARGET_ParentFolderName, CF_TARGET_BaseName, CF_TARGET_Ext
	Dim CF_BPRJ_AbsolutePathName,   CF_BPRJ_ParentFolderName,   CF_BPRJ_BaseName,   CF_BPRJ_Ext
	Dim CF_VPY_AbsolutePathName,    CF_VPY_ParentFolderName,    CF_VPY_BaseName,    CF_VPY_Ext, CF_VPY_object, CF_VPY_string
	Dim CF_DGI_AbsolutePathName,    CF_DGI_ParentFolderName,    CF_DGI_BaseName,    CF_DGI_Ext
	Dim CF_DGIlog_AbsolutePathName, CF_DGIlog_ParentFolderName, CF_DGIlog_BaseName, CF_DGIlog_Ext
	'
	Dim vrdtvs_IsAVC, vrdtvs_IsMPEG2, vrdtvs_IsProgressive, vrdtvs_IsInterlaced, Q_vrdtvs_IsProgressive, Q_vrdtvs_IsInterlaced
	Dim ff_cmd_string, ff_tmp_object, ff_tmp_string, ff_logfile, ff_batfile, ff_cmd_string_for_bat, ff_run_errorlevel
	'
	Dim CF_QSF_logfile, CF_QSF_logfile_object, CF_QSF_logfile_line, CF_QSF_logfile_string, CF_QSF_string_array
	'
	Dim CF_exe_cmd_string
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
	Dim Q_ACTUAL_QSF_LOG_BITRATE
	Dim V_INCOMING_BITRATE
	Dim V_INCOMING_BITRATE_MEDIAINFO
	Dim V_INCOMING_BITRATE_FFPROBE
	Dim V_INCOMING_BITRATE_QSF_LOG
	'
	Dim vrdtvs_final_RTX2060super_extra_flags
	'
	Dim FF_V_Target_BitRate
	Dim FF_V_Target_Minimum_BitRate
	Dim FF_V_Target_Maximum_BitRate
	Dim FF_V_Target_BufSize
	Dim x_cq0, x_cq24, PROPOSED_x_cq_options
	Dim vrdtvs_final_cq_options
	'
	Dim vrdtvs_final_dg_tff
	Dim vrdtvs_final_dg_deinterlace
	'
	Dim Footy_found
	Dim Footy_FF_V_Target_BitRate
	Dim Footy_FF_V_Target_Minimum_BitRate
	Dim Footy_FF_V_Target_Maximum_BitRate
	Dim Footy_FF_V_Target_BufSize
	'
	Dim vrdtvs_create_VPY
	Dim vpy_denoise
	Dim vpy_dsharpen
	'
	WScript.StdOut.WriteLine(" ")
	WScript.StdOut.WriteLine(" ")
	WScript.StdOut.WriteLine("VRDTVS vrdtvs_Convert_File: STARTED " & vrdtvs_current_datetime_string() & " ======================================================================================================================================================")
	WScript.StdOut.WriteLine("VRDTVS vrdtvs_Convert_File: STARTED " & vrdtvs_current_datetime_string() & " ======================================================================================================================================================")
	WScript.StdOut.WriteLine("VRDTVS vrdtvs_Convert_File:           CF_FILE_AbsolutePathName=""" & CF_FILE_AbsolutePathName & """")
	WScript.StdOut.WriteLine("VRDTVS vrdtvs_Convert_File:                CF_source_TS_Folder=""" & CF_source_TS_Folder & """")
	WScript.StdOut.WriteLine("VRDTVS vrdtvs_Convert_File:                  CF_done_TS_Folder=""" & CF_done_TS_Folder & """")
	WScript.StdOut.WriteLine("VRDTVS vrdtvs_Convert_File:          CF_destination_mp4_Folder=""" & CF_destination_mp4_Folder & """")
	WScript.StdOut.WriteLine("VRDTVS vrdtvs_Convert_File:     CF_failed_conversion_TS_Folder=""" & CF_failed_conversion_TS_Folder & """")
	WScript.StdOut.WriteLine("VRDTVS vrdtvs_Convert_File:                       CF_temp_path=""" & CF_temp_path & """")
	WScript.StdOut.WriteLine("VRDTVS vrdtvs_Convert_File:  CF_saved_ffmpeg_commands_filename=""" & CF_saved_ffmpeg_commands_filename & """")
	WScript.StdOut.WriteLine("VRDTVS vrdtvs_Convert_File:                          CF_do_qsf=""" & CF_do_qsf & """")
	WScript.StdOut.WriteLine("VRDTVS vrdtvs_Convert_File:                       CF_do_Adcsan=""" & CF_do_Adcsan & """")
	'
	If NOT fso.FileExists(CF_FILE_AbsolutePathName) Then
		If vrdtvs_DEBUG Then WScript.StdOut.WriteLine("VRDTVS DEBUG: VRDTVS ERROR vrdtvs_Convert_File - Error - SUPPOSEDLY VALID SOURCE FILE NOT FOUND """ & CF_FILE_AbsolutePathName & """... Aborting ...")
		WScript.StdOut.WriteLine("VRDTVS ERROR vrdtvs_Convert_File - Error - SUPPOSEDLY VALID SOURCE FILE NOT FOUND """ & CF_FILE_AbsolutePathName & """... Aborting ...")
		On Error goto 0
		WScript.Quit 17 ' Error 17 = cannot perform the requested operation
	End If
	If vrdtvs_DEBUG Then
		If vrdtvs_DEBUG Then WScript.StdOut.WriteLine("VRDTVS DEBUG: Entered vrdtvs_Convert_File with VALID SOURCE FILE """ & CF_FILE_AbsolutePathName & """")
	End If
	'
	vrdtvs_IsAVC = False
	vrdtvs_IsMPEG2 = False
	vrdtvs_IsProgressive = False
	vrdtvs_IsInterlaced = False
	'
	CF_temp_path = fso.GetAbsolutePathName(CF_temp_path & "\")
	CF_FILE_AbsolutePathName = fso.GetAbsolutePathName(CF_FILE_AbsolutePathName) ' ENSURE AN ABSOLUTE
	CF_FILE_ParentFolderName = fso.GetParentFolderName(CF_FILE_AbsolutePathName)
	CF_FILE_BaseName = fso.GetBaseName(CF_FILE_AbsolutePathName)
	CF_FILE_Ext = fso.GetExtensionName(CF_FILE_AbsolutePathName)
	'
	' GET a bunch of useful info from the SOURCE media file via mediainfo
	V_Codec_legacy						= vrdtvs_get_mediainfo_parameter("Video", "Codec", CF_FILE_AbsolutePathName, "--Legacy") 
	V_Format_legacy						= vrdtvs_get_mediainfo_parameter("Video", "Format", CF_FILE_AbsolutePathName, "--Legacy") 
	V_DisplayAspectRatio_String			= vrdtvs_get_mediainfo_parameter("Video", "DisplayAspectRatio/String", CF_FILE_AbsolutePathName, "")
	V_PixelAspectRatio					= vrdtvs_get_mediainfo_parameter("Video", "PixelAspectRatio", CF_FILE_AbsolutePathName, "")
	V_ScanType							= vrdtvs_get_mediainfo_parameter("Video", "ScanType", CF_FILE_AbsolutePathName, "")
	V_ScanOrder 						= vrdtvs_get_mediainfo_parameter("Video", "ScanOrder", CF_FILE_AbsolutePathName, "")
	V_Width								= vrdtvs_get_mediainfo_parameter("Video", "Width", CF_FILE_AbsolutePathName, "")
	V_Height							= vrdtvs_get_mediainfo_parameter("Video", "Height", CF_FILE_AbsolutePathName, "")
	V_BitRate							= vrdtvs_get_mediainfo_parameter("Video", "BitRate", CF_FILE_AbsolutePathName, "")
	V_BitRate_Minimum					= vrdtvs_get_mediainfo_parameter("Video", "BitRate_Minimum", CF_FILE_AbsolutePathName, "")
	V_BitRate_Maximum					= vrdtvs_get_mediainfo_parameter("Video", "BitRate_Maximum", CF_FILE_AbsolutePathName, "")
	A_Codec_legacy						= vrdtvs_get_mediainfo_parameter("Audio", "Codec", CF_FILE_AbsolutePathName, "--Legacy")
	A_CodecID_legacy					= vrdtvs_get_mediainfo_parameter("Audio", "CodecID", CF_FILE_AbsolutePathName, "--Legacy") 
	A_Format_legacy						= vrdtvs_get_mediainfo_parameter("Audio", "Format", CF_FILE_AbsolutePathName, "--Legacy") 
	A_Video_Delay_ms_legacy				= vrdtvs_get_mediainfo_parameter("Audio", "Video_Delay", CF_FILE_AbsolutePathName, "--Legacy") 
	A_CodecID							= vrdtvs_get_mediainfo_parameter("Audio", "CodecID", CF_FILE_AbsolutePathName, "")
	A_CodecID_String					= vrdtvs_get_mediainfo_parameter("Audio", "CodecID/String", CF_FILE_AbsolutePathName, "")
	A_Video_Delay_ms					= vrdtvs_get_mediainfo_parameter("Audio", "Video_Delay", CF_FILE_AbsolutePathName, "")
	' Obtain SOURCE media file characteristics via ffprobe 
	V_CodecID_FF						= vrdtvs_get_ffprobe_video_stream_parameter("codec_name", CF_FILE_AbsolutePathName)  
	V_CodecID_String_FF					= vrdtvs_get_ffprobe_video_stream_parameter("codec_tag_string", CF_FILE_AbsolutePathName)  
	V_Width_FF							= vrdtvs_get_ffprobe_video_stream_parameter("width", CF_FILE_AbsolutePathName)  
	V_Height_FF							= vrdtvs_get_ffprobe_video_stream_parameter("height", CF_FILE_AbsolutePathName)  
	V_Duration_s_FF						= vrdtvs_get_ffprobe_video_stream_parameter("duration", CF_FILE_AbsolutePathName)  
	V_BitRate_FF						= vrdtvs_get_ffprobe_video_stream_parameter("bit_rate", CF_FILE_AbsolutePathName)  
	V_BitRate_Maximum_FF				= vrdtvs_get_ffprobe_video_stream_parameter("max_bit_rate", CF_FILE_AbsolutePathName)  
	' Fix up the mediainfo parameters retrieved
	V_DisplayAspectRatio_String_slash	= Replace(V_DisplayAspectRatio_String,":","/",1,-1,vbTextCompare)  ' Replace(string,find,replacewith[,start[,count[,compare]]])
	If Ucase(V_Codec_legacy) = Ucase("MPEG-2V") Then
		vrdtvs_IsAVC = False
		vrdtvs_IsMPEG2 = True
		vrd_extension = vrd_extension_mpeg2
		vrd_profile_name_for_qsf = vrd_profile_name_for_qsf_mpeg2
	ElseIf Ucase(V_Codec_legacy) = Ucase("AVC") Then
		vrdtvs_IsAVC = True
		vrdtvs_IsMPEG2 = False
		vrd_extension = vrd_extension_avc
		vrd_profile_name_for_qsf = vrd_profile_name_for_qsf_avc
	Else
		If vrdtvs_DEBUG Then WScript.StdOut.WriteLine("VRDTVS DEBUG: VRDTVS ERROR vrdtvs_Convert_File - Error - Unrecognised video codec """ & CF_FILE_AbsolutePathName & """ """ & V_Codec_legacy & """ ... Ignoring file ...")
		WScript.StdOut.WriteLine("VRDTVS ERROR vrdtvs_Convert_File - Error - Unrecognised video codec """ & CF_FILE_AbsolutePathName & """ """ & V_Codec_legacy & """ ... Ignoring file ...")
		If vrdtvs_DEVELOPMENT_NO_ACTIONS Then ' DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV 
			Wscript.Echo "Error 17 = cannot perform the requested operation"
			On Error goto 0
			WScript.Quit 17 ' Error 17 = cannot perform the requested operation
		Else
			Wscript.Echo "Error 17 = cannot perform the requested operation"
			On Error goto 0
			WScript.Quit 17 ' Error 17 = cannot perform the requested operation
		End If
		vrdtvs_Convert_File = -1
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
		vrdtvs_IsProgressive = False
		vrdtvs_IsInterlaced = True
	ElseIf Ucase(V_ScanType) = Ucase("Progressive") Then
		vrdtvs_IsProgressive = True
		vrdtvs_IsInterlaced = False
	Else
		If vrdtvs_DEBUG Then WScript.StdOut.WriteLine("VRDTVS DEBUG: VRDTVS ERROR vrdtvs_Convert_File - Error - DO NOT KNOW IF SOURCE IS INTERLACED OR PROGRESSIVE """ & CF_FILE_AbsolutePathName & """ V_Codec_legacy=""" & V_Codec_legacy & """ V_ScanType=""" & V_ScanType & """ ... Ignoring file ...")
		WScript.StdOut.WriteLine("VRDTVS ERROR vrdtvs_Convert_File - Error - DO NOT KNOW IF SOURCE IS INTERLACED OR PROGRESSIVE """ & CF_FILE_AbsolutePathName & """ V_Codec_legacy=""" & V_Codec_legacy & """ V_ScanType=""" & V_ScanType & """ ... Ignoring file ...")
		If vrdtvs_DEVELOPMENT_NO_ACTIONS Then ' DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV 
			Wscript.Echo "Error 17 = cannot perform the requested operation"
			On Error goto 0
			WScript.Quit 17 ' Error 17 = cannot perform the requested operation
		Else
			Wscript.Echo "Error 17 = cannot perform the requested operation"
			On Error goto 0
			WScript.Quit 17 ' Error 17 = cannot perform the requested operation
		End If
	End If
	If V_ScanOrder = "" Then
		V_ScanOrder = "TFF" ' Default to Top Field First
	End If
	If vrdtvs_DEBUG Then
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvs_Convert_File adjusted SOURCE media characteristics below:") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvs_Convert_File V_Codec_legacy=""" & V_Codec_legacy & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvs_Convert_File V_Format_legacy=""" & V_Format_legacy & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvs_Convert_File V_DisplayAspectRatio_String_slash=""" & V_DisplayAspectRatio_String_slash & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvs_Convert_File V_PixelAspectRatio=""" & V_PixelAspectRatio & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvs_Convert_File V_ScanType=""" & V_ScanType & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvs_Convert_File V_ScanOrder=""" & V_ScanOrder & """")
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvs_Convert_File vrdtvs_IsProgressive=""" & q_vrdtvs_IsProgressive & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvs_Convert_File vrdtvs_IsInterlaced=""" & q_vrdtvs_IsInterlaced & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvs_Convert_File V_Width=""" & V_Width & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvs_Convert_File V_Height=""" & V_Height & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvs_Convert_File V_BitRate=""" & V_BitRate & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvs_Convert_File V_BitRate_Minimum=""" & V_BitRate_Minimum & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvs_Convert_File V_BitRate_Maximum=""" & V_BitRate_Maximum & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvs_Convert_File A_Codec_legacy=""" & A_Codec_legacy & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvs_Convert_File A_CodecID_legacy=""" & A_CodecID_legacy & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvs_Convert_File A_Format_legacy=""" & A_Format_legacy & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvs_Convert_File A_Video_Delay_ms=""" & A_Video_Delay_ms & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvs_Convert_File A_Video_Delay_ms_legacy=""" & A_Video_Delay_ms_legacy & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvs_Convert_File A_Audio_Delay_ms=""" & A_Audio_Delay_ms & """")
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvs_Convert_File A_Audio_Delay_ms_legacy=""" & A_Audio_Delay_ms_legacy & """")
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvs_Convert_File A_CodecID=""" & A_CodecID & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvs_Convert_File A_CodecID_String=""" & A_CodecID_String & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvs_Convert_File V_CodecID_FF=""" & V_CodecID_FF & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvs_Convert_File V_CodecID_String_FF=""" & V_CodecID_String_FF & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvs_Convert_File V_Width_FF=""" & V_Width_FF & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvs_Convert_File V_Height_FF=""" & V_Height_FF & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvs_Convert_File V_Duration_s_FF=""" & V_Duration_s_FF & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvs_Convert_File V_BitRate_FF=""" & V_BitRate_FF & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvs_Convert_File V_BitRate_Maximum_FF=""" & V_BitRate_Maximum_FF & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvs_Convert_File adjusted SOURCE media characteristics above") 
	End If
	WScript.StdOut.WriteLine("VRDTVS vrdtvs_Convert_File: ======================================================================================================================================================")
	WScript.StdOut.WriteLine("VRDTVS vrdtvs_Convert_File: End Examining of SOURCE """ & CF_FILE_AbsolutePathName & """")
	WScript.StdOut.WriteLine("VRDTVS vrdtvs_Convert_File: SOURCE file: V_Codec_legacy: """ & V_Codec_legacy & """ V_ScanType: """ & V_ScanType & """ V_ScanOrder: """ & V_ScanOrder & """ " & V_Width & "x" & V_Height & " dar=" & V_DisplayAspectRatio_String_slash & " sar=" & V_PixelAspectRatio & " A_Codec_legacy: " & A_Codec_legacy & " A_Audio_Delay_ms: " & A_Audio_Delay_ms & " A_Audio_Delay_ms_legacy: " & A_Audio_Delay_ms_legacy & " A_Video_Delay_ms: " &  A_Video_Delay_ms & " A_Video_Delay_ms_legacy: " &  A_Video_Delay_ms_legacy)
	WScript.StdOut.WriteLine("VRDTVS vrdtvs_Convert_File: End Exmaining of SOURCE """ & CF_FILE_AbsolutePathName & """")
	WScript.StdOut.WriteLine("VRDTVS vrdtvs_Convert_File: ======================================================================================================================================================")
	'
	' Now that we know the Video Codec and have determined that proper QSF File extension to use, set things up
	CF_QSF_ParentFolderName = CF_temp_path
	CF_QSF_BaseName = CF_FILE_BaseName
	CF_QSF_Ext = vrd_extension ' set above based on incoming codec
	CF_QSF_AbsolutePathName = fso.GetAbsolutePathName(fso.BuildPath(CF_QSF_ParentFolderName,CF_QSF_BaseName & ".VRDTVS.QSF." & CF_QSF_Ext))
	'
	CF_TARGET_ParentFolderName = CF_destination_mp4_Folder
	CF_TARGET_BaseName = CF_FILE_BaseName
	CF_TARGET_Ext = "mp4"		' always .mp4
	CF_TARGET_AbsolutePathName = fso.GetAbsolutePathName(fso.BuildPath(CF_TARGET_ParentFolderName,CF_TARGET_BaseName & "." & CF_TARGET_Ext))
	'
	CF_VPY_ParentFolderName = CF_temp_path
	CF_VPY_BaseName = CF_FILE_BaseName
	CF_VPY_Ext = "vpy"			' always .vpy
	CF_VPY_AbsolutePathName = fso.GetAbsolutePathName(fso.BuildPath(CF_VPY_ParentFolderName,CF_VPY_BaseName & "." & CF_VPY_Ext))
	'
	CF_DGI_ParentFolderName = CF_temp_path
	CF_DGI_BaseName = CF_FILE_BaseName
	CF_DGI_Ext = "dgi"			' always .dgi
	CF_DGI_AbsolutePathName = fso.GetAbsolutePathName(fso.BuildPath(CF_DGI_ParentFolderName,CF_QSF_BaseName & "." & CF_DGI_Ext))
	'
	CF_DGIlog_ParentFolderName = CF_temp_path
	CF_DGIlog_BaseName = CF_FILE_BaseName
	CF_DGIlog_Ext = "log"			' always .log
	CF_DGIlog_AbsolutePathName = fso.GetAbsolutePathName(fso.BuildPath(CF_DGI_ParentFolderName,CF_QSF_BaseName & "." & CF_DGIlog_Ext))
	'
	CF_BPRJ_ParentFolderName = CF_destination_mp4_Folder
	CF_BPRJ_BaseName = CF_FILE_BaseName
	CF_BPRJ_Ext = "bprj"		' always .bprj
	CF_BPRJ_AbsolutePathName = fso.GetAbsolutePathName(fso.BuildPath(CF_BPRJ_ParentFolderName,CF_BPRJ_BaseName & "." & CF_BPRJ_Ext))
	'
	' START ======================================================  Do the QSF ... IF FLAGGED TO DO DO ======================================================
	' If doing a QSF, do it
	' If NOT doing a QSF, just copy the SOURCE  file (usually .ts), file over to the QSF file whilst retaining most of the QSF functionality
	' ++++ START Run the QSF command
	ff_timerStart = Timer
	vrdtvs_status = vrdtvs_delete_a_file(CF_QSF_AbsolutePathName, True) ' True=silently delete it
	vrdtvs_status = vrdtvs_delete_a_file(vrd_logfile_wildcard_QSF, True) ' True=silently delete it 	' is a wildcard, in fso.DeleteFile the filespec can contain wildcard characters in the last path component
	vrdtvs_status = vrdtvs_delete_a_file(vrd_logfile_wildcard_ADSCAN, True) ' True=silently delete it	' is a wildcard, in fso.DeleteFile the filespec can contain wildcard characters in the last path component
	CF_exe_cmd_string = "cscript //Nologo """ & vrd_path_for_qsf_vbs & """ """ & CF_FILE_AbsolutePathName & """  """ & CF_QSF_AbsolutePathName & """ /qsf /p """ & vrd_profile_name_for_qsf & """ /q /na"
	If vrdtvs_DEBUG Then 
		WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_Convert_File """ & CF_FILE_AbsolutePathName & """ V_Codec_legacy=""" & V_Codec_legacy & """ do QSF with CF_exe_cmd_string=""" & CF_exe_cmd_string & """")
	End If
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
	CF_object_saved_ffmpeg_commands.WriteLine("REM  vrdtvs_Convert_File q_vrdtvs_IsProgressive=""" & q_vrdtvs_IsProgressive & """") 
	CF_object_saved_ffmpeg_commands.WriteLine("REM  vrdtvs_Convert_File q_vrdtvs_IsInterlaced=""" & q_vrdtvs_IsInterlaced & """") 
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
	CF_object_saved_ffmpeg_commands.WriteLine("REM  adjusted SOURCE media characteristics above") 
	CF_object_saved_ffmpeg_commands.WriteLine("REM")
	CF_object_saved_ffmpeg_commands.WriteLine("REM Do the QSF for """ & CF_FILE_AbsolutePathName & """ ... " & V_ScanType & " " & V_ScanOrder & " """ & V_Codec_legacy & """/""" & A_Codec_legacy & """")
	CF_object_saved_ffmpeg_commands.WriteLine("REM")
	' do the actual QSF command (delete the QSF file first)
	'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	' Here is where we actually do the QSF or just copy the SOURCE file and pretend it is a .QSF'd file
	' NOTE: we actually to the QSF (so we can determine the Bitrate form the QSF logfile) then delete the QSF file and replace it with a copy of the source file
	WScript.StdOut.WriteLine("VRDTVS vrdtvs_Convert_File: Doing QSF for """ & CF_FILE_AbsolutePathName & """ ... " & V_ScanType & " " & V_ScanOrder & " """ & V_Codec_legacy & """/""" & A_Codec_legacy & """")
	WScript.StdOut.WriteLine("VRDTVS vrdtvs_Convert_File: QSF command: " & CF_exe_cmd_string)
	CF_object_saved_ffmpeg_commands.WriteLine("DEL /F """ & CF_QSF_AbsolutePathName & """")
	CF_object_saved_ffmpeg_commands.WriteLine(CF_exe_cmd_string) ' write the QSF String to be executed
	vrdtvs_status = vrdtvs_delete_a_file(CF_QSF_AbsolutePathName, True) ' True=silently delete it
	CF_exe_status = vrdtvs_exec_a_command_and_show_stdout_stderr(CF_exe_cmd_string)
	If CF_do_qsf Then
		CF_object_saved_ffmpeg_commands.WriteLine(CF_exe_cmd_string) ' write the QSF String to be executed, only if we're doing a QSF
	Else ' proceed with creating the "pretend" QSF file
		vrdtvs_status = vrdtvs_delete_a_file(CF_QSF_AbsolutePathName, True) ' True=silently delete it
		CF_QSF_Ext = CF_FILE_Ext ' NOT "vrd_extension" CF_FILE_AbsolutePathName
		CF_QSF_AbsolutePathName = fso.GetAbsolutePathName(fso.BuildPath(CF_QSF_ParentFolderName,CF_QSF_BaseName & ".VRDTVS.NON-QSF." & CF_QSF_Ext))		
		CF_exe_cmd_string = "COPY /Y /V /Z /B """ & CF_FILE_AbsolutePathName & """ """ & CF_QSF_AbsolutePathName & """"
		If vrdtvs_DEBUG Then WScript.StdOut.WriteLine("VRDTVS DEBUG: ----- Instead-of-QSF: Copying """ & CF_FILE_AbsolutePathName & """ to """ & CF_QSF_AbsolutePathName & """ with: " & CF_exe_cmd_string)
		WScript.StdOut.WriteLine("VRDTVS vrdtvs_Convert_File: ----- Instead-of-QSF for """ & CF_FILE_AbsolutePathName & """ ... " & V_ScanType & " " & V_ScanOrder & " """ & V_Codec_legacy & """/""" & A_Codec_legacy & """")
		WScript.StdOut.WriteLine("VRDTVS vrdtvs_Convert_File: ----- Copying: """ & CF_FILE_AbsolutePathName & """ to """ & CF_QSF_AbsolutePathName & """ with: " & CF_exe_cmd_string)
		CF_object_saved_ffmpeg_commands.WriteLine("DEL /F """ & CF_QSF_AbsolutePathName & """")
		CF_object_saved_ffmpeg_commands.WriteLine(CF_exe_cmd_string) ' write the pretend QSF String to be executed
		On Error Resume Next
		fso.CopyFile CF_FILE_AbsolutePathName, CF_QSF_AbsolutePathName, True ' copy file with overwrite
		vrdrvs_Err_Code = Err.Number
		vrdrvs_Err_Description = Err.Description
		On Error Goto 0
		'If vrdtvs_DEBUG Then WScript.StdOut.WriteLine("VRDTVS DEBUG: Insomnia: File Copy returned error code: " & vrdrvs_Err_Code & " Descrption: " & vrdrvs_Err_Description)
		If vrdrvs_Err_Code <> 0 Then
    		Err.Clear
    		WScript.StdOut.WriteLine("VRDTVS vrdtvs_Convert_File: ERROR - Error " & vrdrvs_Err_Code & " Copying: """ & CF_FILE_AbsolutePathName & """ to """ & CF_QSF_AbsolutePathName & """ ... Aborting ...")
    		WScript.StdOut.WriteLine("VRDTVS vrdtvs_Convert_File: ERROR - " & vrdrvs_Err_Description)
    		' Err.Raise 17 ' Error 17 = cannot perform the requested operation
			Wscript.Echo "Error 17 = cannot perform the requested operation"
			On Error goto 0
			WScript.Quit 17 ' Error 17 = cannot perform the requested operation
		End If
		CF_exe_status = 0
	End If
	'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	If CF_exe_status <> 0 OR NOT fso.FileExists(CF_QSF_AbsolutePathName) Then
		If vrdtvs_DEBUG Then WScript.StdOut.WriteLine("VRDTVS DEBUG: ERROR vrdtvs_Convert_File - Error - Failed to QSF """ & CF_FILE_AbsolutePathName & """ V_Codec_legacy=""" & V_Codec_legacy & """ CF_exe_cmd_string=""" & CF_exe_cmd_string & """")
		WScript.StdOut.WriteLine("VRDTVS ERROR vrdtvs_Convert_File - Error - Failed to QSF """ & CF_FILE_AbsolutePathName & """ V_Codec_legacy=""" & V_Codec_legacy & """ CF_exe_cmd_string=""" & CF_exe_cmd_string & """")
		If vrdtvs_DEVELOPMENT_NO_ACTIONS Then ' DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV 
			Wscript.Echo "Error 17 = cannot perform the requested operation"
			On Error goto 0
			WScript.Quit 17 ' Error 17 = cannot perform the requested operation
		Else
			Wscript.Echo "Error 17 = cannot perform the requested operation"
			On Error goto 0
			WScript.Quit 17 ' Error 17 = cannot perform the requested operation
		End If
		vrdtvs_Convert_File = -1
		Exit Function
	End If
	ff_timerEnd = Timer
	WScript.StdOut.WriteLine("VRDTVS vrdtvs_Convert_File: - QSF command completed with Elapsed Time " & vrdtvs_Calculate_ElapsedTime_string(ff_timerStart, ff_timerEnd))
	' ++++ END Run the QSF command
	' End ======================================================  Do the QSF ======================================================
	'
	' Copy the QSF log so we can search it for a bitrate value
	CF_QSF_logfile =  CF_QSF_AbsolutePathName & ".log"
	vrdtvs_status = vrdtvs_delete_a_file(CF_QSF_logfile, True) ' True=silently delete it
	CF_exe_cmd_string = "CMD /C COPY /Y """ & vrd_logfile_wildcard_QSF & """ """ & CF_QSF_logfile & """ 2>&1"
	If vrdtvs_DEBUG Then 
		WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_Convert_File """ & CF_FILE_AbsolutePathName & """ V_Codec_legacy=""" & V_Codec_legacy & """ copy log with CF_exe_cmd_string=""" & CF_exe_cmd_string & """")
	End If
	CF_exe_status = vrdtvs_exec_a_command_and_show_stdout_stderr(CF_exe_cmd_string)
	If CF_exe_status <> 0 OR NOT fso.FileExists(CF_QSF_AbsolutePathName) Then
		If vrdtvs_DEBUG Then WScript.StdOut.WriteLine("VRDTVS DEBUG: ERROR vrdtvs_Convert_File - Error - Failed to copy QSF log """ & CF_FILE_AbsolutePathName & """ V_Codec_legacy=""" & V_Codec_legacy & """ CF_exe_cmd_string=""" & CF_exe_cmd_string & """")
		WScript.StdOut.WriteLine("VRDTVS ERROR vrdtvs_Convert_File - Error - Failed to copy QSF log """ & CF_FILE_AbsolutePathName & """ V_Codec_legacy=""" & V_Codec_legacy & """ CF_exe_cmd_string=""" & CF_exe_cmd_string & """")
		If vrdtvs_DEVELOPMENT_NO_ACTIONS Then ' DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV 
			Wscript.Echo "Error 17 = cannot perform the requested operation"
			On Error goto 0
			WScript.Quit 17 ' Error 17 = cannot perform the requested operation
		Else
			Wscript.Echo "Error 17 = cannot perform the requested operation"
			On Error goto 0
			WScript.Quit 17 ' Error 17 = cannot perform the requested operation
		End If
		vrdtvs_Convert_File = -1
		Exit Function
	End If
	'
	' Search the QSF logfile for the "Actual Video Bitrate"
	Set CF_QSF_logfile_object = fso.OpenTextFile(CF_QSF_logfile, ForReading)
	Const CF_Search_for_this_for_bitrate_in_QSF_logfile = "Actual Video Bitrate: " ' the trailing space is important
	Q_ACTUAL_QSF_LOG_BITRATE = 0
	Do Until CF_QSF_logfile_object.AtEndOfStream
		CF_QSF_logfile_line = CF_QSF_logfile_object.ReadLine
		CF_tmp = instr(1,CF_QSF_logfile_line, CF_Search_for_this_for_bitrate_in_QSF_logfile, vbTextCompare)
		If CF_tmp > 0 Then ' InStr([start, ]string1, string2[, compare])
			' OK, the line looks like "Actual Video Bitrate: 3.74 Mbps"
			CF_QSF_logfile_string = Mid(CF_QSF_logfile_line,(CF_tmp+len(CF_Search_for_this_for_bitrate_in_QSF_logfile)))	' Mid(string, start[, length]))
			CF_QSF_string_array = Split(CF_QSF_logfile_string," ",2,vbTextCompare) 				' Split(expression[,delimiter[,count[,compare]]])
			CF_QSF_logfile_string = Replace(CF_QSF_string_array(0)," ","",1,-1,vbTextCompare)	' Replace(string,find,replacewith[,start[,count[,compare]]]) 'Always assume units is Mbps ...
			If IsNumeric(CF_QSF_logfile_string) Then ' assume it's a decimal Mbps, convert it to 
				Q_ACTUAL_QSF_LOG_BITRATE = CDbl(CF_QSF_logfile_string) * 1000000  ' expand the decimal number into a full integer number of Mbps
			End If
			Exit Do ' exits the READLINES Do loop at the first detection of the constant
		End If
	Loop
	CF_QSF_logfile_object.Close
	Set CF_QSF_logfile_object = Nothing
	vrdtvs_status = vrdtvs_delete_a_file(CF_QSF_logfile, True) ' True=silently delete the QSF logfile
	'
	' Obtain QSF file characteristics via mediainfo 
	Q_V_Codec_legacy					= vrdtvs_get_mediainfo_parameter("Video", "Codec", CF_QSF_AbsolutePathName, "--Legacy") 
	Q_V_Format_legacy					= vrdtvs_get_mediainfo_parameter("Video", "Format", CF_QSF_AbsolutePathName, "--Legacy") 
	Q_V_DisplayAspectRatio_String		= vrdtvs_get_mediainfo_parameter("Video", "DisplayAspectRatio/String", CF_QSF_AbsolutePathName, "")
	Q_V_PixelAspectRatio				= vrdtvs_get_mediainfo_parameter("Video", "PixelAspectRatio", CF_QSF_AbsolutePathName, "")
	Q_V_ScanType						= vrdtvs_get_mediainfo_parameter("Video", "ScanType", CF_QSF_AbsolutePathName, "")
	Q_V_ScanOrder 						= vrdtvs_get_mediainfo_parameter("Video", "ScanOrder", CF_QSF_AbsolutePathName, "")
	Q_V_Width							= vrdtvs_get_mediainfo_parameter("Video", "Width", CF_QSF_AbsolutePathName, "")
	Q_V_Height							= vrdtvs_get_mediainfo_parameter("Video", "Height", CF_QSF_AbsolutePathName, "")
	Q_V_BitRate							= vrdtvs_get_mediainfo_parameter("Video", "BitRate", CF_QSF_AbsolutePathName, "")
	Q_V_BitRate_Minimum					= vrdtvs_get_mediainfo_parameter("Video", "BitRate_Minimum", CF_QSF_AbsolutePathName, "")
	Q_V_BitRate_Maximum					= vrdtvs_get_mediainfo_parameter("Video", "BitRate_Maximum", CF_QSF_AbsolutePathName, "")
	Q_A_Codec_legacy					= vrdtvs_get_mediainfo_parameter("Audio", "Codec", CF_QSF_AbsolutePathName, "--Legacy")
	Q_A_CodecID_legacy					= vrdtvs_get_mediainfo_parameter("Audio", "CodecID", CF_QSF_AbsolutePathName, "--Legacy") 
	Q_A_Format_legacy					= vrdtvs_get_mediainfo_parameter("Audio", "Format", CF_QSF_AbsolutePathName, "--Legacy") 
	Q_A_Video_Delay_ms_legacy			= vrdtvs_get_mediainfo_parameter("Audio", "Video_Delay", CF_QSF_AbsolutePathName, "--Legacy") 
	Q_A_CodecID							= vrdtvs_get_mediainfo_parameter("Audio", "CodecID", CF_QSF_AbsolutePathName, "")
	Q_A_CodecID_String					= vrdtvs_get_mediainfo_parameter("Audio", "CodecID/String", CF_QSF_AbsolutePathName, "")
	Q_A_Video_Delay_ms					= vrdtvs_get_mediainfo_parameter("Audio", "Video_Delay", CF_QSF_AbsolutePathName, "")
	Q_V_BitRate_FF						= vrdtvs_get_ffprobe_video_stream_parameter("bit_rate",CF_QSF_AbsolutePathName)  
	Q_V_BitRate_Maximum_FF				= vrdtvs_get_ffprobe_video_stream_parameter("max_bit_rate", CF_QSF_AbsolutePathName)  
	' Obtain QSF file characteristics via ffprobe 
	Q_V_CodecID_FF						= vrdtvs_get_ffprobe_video_stream_parameter("codec_name", CF_QSF_AbsolutePathName)  
	Q_V_CodecID_String_FF				= vrdtvs_get_ffprobe_video_stream_parameter("codec_tag_string", CF_QSF_AbsolutePathName)  
	Q_V_Width_FF						= vrdtvs_get_ffprobe_video_stream_parameter("width", CF_QSF_AbsolutePathName)  
	Q_V_Height_FF						= vrdtvs_get_ffprobe_video_stream_parameter("height", CF_QSF_AbsolutePathName)  
	Q_V_Duration_s_FF					= vrdtvs_get_ffprobe_video_stream_parameter("duration", CF_QSF_AbsolutePathName)  
	Q_V_BitRate_FF						= vrdtvs_get_ffprobe_video_stream_parameter("bit_rate", CF_QSF_AbsolutePathName)  
	Q_V_BitRate_Maximum_FF				= vrdtvs_get_ffprobe_video_stream_parameter("max_bit_rate", CF_QSF_AbsolutePathName)
	' Fix up the QSF mediainfo parameters retrieved
	Q_V_DisplayAspectRatio_String_slash	= Replace(Q_V_DisplayAspectRatio_String,":","/",1,-1,vbTextCompare)  ' Replace(string,find,replacewith[,start[,count[,compare]]])
	'
	If vrdtvs_IsMPEG2 Then ' (Ucase(Q_V_Codec_legacy) = Ucase("MPEG-2V") 
	ElseIf vrdtvs_IsAVC Then ' (Ucase(Q_V_Codec_legacy) = Ucase("AVC") 
	Else
		If vrdtvs_DEBUG Then WScript.StdOut.WriteLine("VRDTVS DEBUG: VRDTVS ERROR vrdtvs_Convert_File - Error - Unrecognised Q_V_Codec_legacy video codec """ & CF_QSF_AbsolutePathName & """ Q_V_Codec_legacy=""" & Q_V_Codec_legacy & """ ... Ignoring file ...")
		WScript.StdOut.WriteLine("VRDTVS ERROR vrdtvs_Convert_File - Error - Unrecognised Q_V_Codec_legacy video codec """ & CF_QSF_AbsolutePathName & """ Q_V_Codec_legacy=""" & Q_V_Codec_legacy & """ ... Ignoring file ...")
		If vrdtvs_DEVELOPMENT_NO_ACTIONS Then ' DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV 
			Wscript.Echo "Error 17 = cannot perform the requested operation"
			On Error goto 0
			WScript.Quit 17 ' Error 17 = cannot perform the requested operation
		Else
			Wscript.Echo "Error 17 = cannot perform the requested operation"
			On Error goto 0
			WScript.Quit 17 ' Error 17 = cannot perform the requested operation
		End If
		vrdtvs_Convert_File = -1
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
		q_vrdtvs_IsProgressive = False
		q_vrdtvs_IsInterlaced = True
	ElseIf Ucase(Q_V_ScanType) = Ucase("Progressive") Then
		q_vrdtvs_IsProgressive = True
		q_vrdtvs_IsInterlaced = False
	Else
		If vrdtvs_DEBUG Then WScript.StdOut.WriteLine("VRDTVS DEBUG: VRDTVS ERROR vrdtvs_Convert_File - Error - DO NOT KNOW IF QSF IS INTERLACED OR PROGRESSIVE """ & CF_QSF_AbsolutePathName & """ Q_V_Codec_legacy=""" & Q_V_Codec_legacy & """ V_ScanType=""" & Q_V_ScanType & """ ... Ignoring file ...")
		WScript.StdOut.WriteLine("VRDTVS ERROR vrdtvs_Convert_File - Error - DO NOT KNOW IF QSF IS INTERLACED OR PROGRESSIVE """ & CF_QSF_AbsolutePathName & """ Q_V_Codec_legacy=""" & Q_V_Codec_legacy & """ Q_V_ScanType=""" & Q_V_ScanType & """ ... Ignoring file ...")
		If vrdtvs_DEVELOPMENT_NO_ACTIONS Then ' DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV 
			Wscript.Echo "Error 17 = cannot perform the requested operation"
			On Error goto 0
			WScript.Quit 17 ' Error 17 = cannot perform the requested operation
		Else
			Wscript.Echo "Error 17 = cannot perform the requested operation"
			On Error goto 0
			WScript.Quit 17 ' Error 17 = cannot perform the requested operation
		End If
	End If
	If (vrdtvs_IsProgressive <> q_vrdtvs_IsProgressive) OR (vrdtvs_IsInterlaced <> q_vrdtvs_IsInterlaced) Then
		If vrdtvs_DEBUG Then WScript.StdOut.WriteLine("VRDTVS DEBUG: VRDTVS ERROR vrdtvs_Convert_File - Error - UNEQUAL SOURCE AND QSF INTERLACED/PROGRESSIVE V_ScanType=""" & V_ScanType & """ Q_V_ScanType=""" & Q_V_ScanType &  """ ... Ignoring file ...")
		WScript.StdOut.WriteLine("VRDTVS ERROR vrdtvs_Convert_File - Error - UNEQUAL SOURCE AND QSF INTERLACED/PROGRESSIVE V_ScanType=""" & V_ScanType & """ Q_V_ScanType=""" & Q_V_ScanType & """ ... Ignoring file ...")
		If vrdtvs_DEVELOPMENT_NO_ACTIONS Then ' DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV 
			Wscript.Echo "Error 17 = cannot perform the requested operation"
			On Error goto 0
			WScript.Quit 17 ' Error 17 = cannot perform the requested operation
		Else
			Wscript.Echo "Error 17 = cannot perform the requested operation"
			On Error goto 0
			WScript.Quit 17 ' Error 17 = cannot perform the requested operation
		End If
	End If
	If Q_V_ScanOrder = "" Then
		Q_V_ScanOrder = "TFF" ' Default to Top Field First
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
	V_INCOMING_BITRATE_QSF_LOG = 0
	'REM Check if supposed numbers are NUMERIC.
	If IsNumeric(Q_V_BitRate) Then 				V_INCOMING_BITRATE_MEDIAINFO = Q_V_BitRate
	If IsNumeric(Q_V_BitRate_FF) Then 			V_INCOMING_BITRATE_FFPROBE = Q_V_BitRate_FF
	If IsNumeric(Q_ACTUAL_QSF_LOG_BITRATE) Then	V_INCOMING_BITRATE_MEDIAINFO = Q_ACTUAL_QSF_LOG_BITRATE
	'USE the ffprobe bitrate value, sometimes it mis-reports as a much larger bitrate value but it seems to be correct.
	IF V_INCOMING_BITRATE_FFPROBE   > V_INCOMING_BITRATE Then V_INCOMING_BITRATE = V_INCOMING_BITRATE_FFPROBE
	IF V_INCOMING_BITRATE_MEDIAINFO > V_INCOMING_BITRATE Then V_INCOMING_BITRATE = V_INCOMING_BITRATE_MEDIAINFO
	IF V_INCOMING_BITRATE_QSF_LOG   > V_INCOMING_BITRATE Then V_INCOMING_BITRATE = V_INCOMING_BITRATE_QSF_LOG
	IF V_INCOMING_BITRATE = 0  Then
		' Jolly Bother and Dash it all, no valid bitrate found anywhere, we need to set an artifical incoming bitrate. Choose 4Mb/s for AVC
		V_INCOMING_BITRATE = 4000000
	End If
	If vrdtvs_DEBUG Then
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvs_Convert_File adjusted QSF media characteristics below:") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvs_Convert_File Q_V_Codec_legacy=""" & Q_V_Codec_legacy & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvs_Convert_File Q_V_Format_legacy=""" & Q_V_Format_legacy & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvs_Convert_File Q_V_DisplayAspectRatio_String_slash=""" & Q_V_DisplayAspectRatio_String_slash & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvs_Convert_File Q_V_PixelAspectRatio=""" & Q_V_PixelAspectRatio & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvs_Convert_File Q_V_ScanType=""" & Q_V_ScanType & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvs_Convert_File Q_V_ScanOrder=""" & Q_V_ScanOrder & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvs_Convert_File q_vrdtvs_IsProgressive=""" & q_vrdtvs_IsProgressive & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvs_Convert_File q_vrdtvs_IsInterlaced=""" & q_vrdtvs_IsInterlaced & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvs_Convert_File Q_V_Width=""" & Q_V_Width & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvs_Convert_File Q_V_Height=""" & Q_V_Height & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvs_Convert_File Q_V_BitRate=""" & Q_V_BitRate & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvs_Convert_File Q_V_BitRate_Minimum=""" & Q_V_BitRate_Minimum & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvs_Convert_File Q_V_BitRate_Maximum=""" & Q_V_BitRate_Maximum & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvs_Convert_File Q_A_Codec_legacy=""" & Q_A_Codec_legacy & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvs_Convert_File Q_A_CodecID_legacy=""" & Q_A_CodecID_legacy & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvs_Convert_File Q_A_Format_legacy=""" & Q_A_Format_legacy & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvs_Convert_File Q_A_Video_Delay_ms=""" & Q_A_Video_Delay_ms & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvs_Convert_File Q_A_Video_Delay_ms_legacy=""" & Q_A_Video_Delay_ms_legacy & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvs_Convert_File Q_A_Audio_Delay_ms=""" & Q_A_Audio_Delay_ms & """")
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvs_Convert_File Q_A_Audio_Delay_ms_legacy=""" & Q_A_Audio_Delay_ms_legacy & """")
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvs_Convert_File Q_A_CodecID=""" & Q_A_CodecID & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvs_Convert_File Q_A_CodecID_String=""" & Q_A_CodecID_String & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvs_Convert_File Q_V_CodecID_FF=""" & Q_V_CodecID_FF & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvs_Convert_File Q_V_CodecID_String_FF=""" & Q_V_CodecID_String_FF & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvs_Convert_File Q_V_Width_FF=""" & Q_V_Width_FF & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvs_Convert_File Q_V_Height_FF=""" & Q_V_Height_FF & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvs_Convert_File Q_V_Duration_s_FF=""" & Q_V_Duration_s_FF & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvs_Convert_File Q_V_BitRate_FF=""" & Q_V_BitRate_FF & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvs_Convert_File Q_V_BitRate_Maximum_FF=""" & Q_V_BitRate_Maximum_FF & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvs_Convert_File V_INCOMING_BITRATE_MEDIAINFO=""" & V_INCOMING_BITRATE_MEDIAINFO & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvs_Convert_File V_INCOMING_BITRATE_FFPROBE=""" & V_INCOMING_BITRATE_FFPROBE & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvs_Convert_File V_INCOMING_BITRATE_QSF_LOG=""" & V_INCOMING_BITRATE_QSF_LOG & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvs_Convert_File V_INCOMING_BITRATE=""" & V_INCOMING_BITRATE & """") 
		WScript.StdOut.WriteLine("VRDTVS: DEBUG: vrdtvs_Convert_File adjusted QSF media characteristics above") 
	End If
	WScript.StdOut.WriteLine("VRDTVS vrdtvs_Convert_File: ======================================================================================================================================================")
	WScript.StdOut.WriteLine("VRDTVS vrdtvs_Convert_File: End QSF of """ & CF_FILE_AbsolutePathName & """ into """ & CF_QSF_AbsolutePathName & """")
	WScript.StdOut.WriteLine("VRDTVS vrdtvs_Convert_File: output QSF file: Q_V_Codec_legacy: """ & Q_V_Codec_legacy & """ Q_V_ScanType: """ & Q_V_ScanType & """ Q_V_ScanOrder: """ & Q_V_ScanOrder & """ " & Q_V_Width & "x" & Q_V_Height & " dar=" & Q_V_DisplayAspectRatio_String_slash & " sar=" & Q_V_PixelAspectRatio & " Q_A_Codec_legacy: " & Q_A_Codec_legacy & " Q_A_Audio_Delay_ms: " & Q_A_Audio_Delay_ms & " Q_A_Audio_Delay_ms_legacy: " & Q_A_Audio_Delay_ms_legacy & " Q_A_Video_Delay_ms: " &  Q_A_Video_Delay_ms & " Q_A_Video_Delay_ms_legacy: " &  Q_A_Video_Delay_ms_legacy)
	WScript.StdOut.WriteLine("VRDTVS vrdtvs_Convert_File: End QSF of """ & CF_FILE_AbsolutePathName & """ into """ & CF_QSF_AbsolutePathName & """")
	WScript.StdOut.WriteLine("VRDTVS vrdtvs_Convert_File: ======================================================================================================================================================")
	WScript.StdOut.WriteLine("VRDTVS vrdtvs_Convert_File: V_INCOMING_BITRATE: Using """ & CF_FILE_AbsolutePathName & """ and """ & CF_QSF_AbsolutePathName & """ The V_INCOMING_BITRATE=""" & V_INCOMING_BITRATE & """")
	WScript.StdOut.WriteLine("VRDTVS vrdtvs_Convert_File: ======================================================================================================================================================")
	'
	' Cross-Check SOURCE ScanType and ScanOrder with QSF ScanType and ScanOrder and bail if not the same
	If Ucase(V_ScanType) <> Ucase(Q_V_ScanType) Then
		If vrdtvs_DEBUG Then WScript.StdOut.WriteLine("VRDTVS DEBUG: VRDTVS ERROR vrdtvs_Convert_File - Error - Ucase(V_ScanType) """ & Ucase(V_ScanType) & """ <> Ucase(Q_V_ScanType) """ & Ucase(Q_V_ScanType) & """  """ & CF_QSF_AbsolutePathName & """ """ & Q_V_Codec_legacy & """ ... Ignoring file ...")
		WScript.StdOut.WriteLine("VRDTVS ERROR vrdtvs_Convert_File - Error - Ucase(V_ScanType) """ & Ucase(V_ScanType) & """ <> Ucase(Q_V_ScanType) """ & Ucase(Q_V_ScanType) & """  """ & CF_QSF_AbsolutePathName & """ """ & Q_V_Codec_legacy & """ ... Ignoring file ...")
		WScript.StdOut.WriteLine("VRDTVS: vrdtvs_Convert_File adjusted SOURCE media characteristics below:") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvs_Convert_File V_Codec_legacy=""" & V_Codec_legacy & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvs_Convert_File V_Format_legacy=""" & V_Format_legacy & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvs_Convert_File V_DisplayAspectRatio_String_slash=""" & V_DisplayAspectRatio_String_slash & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvs_Convert_File V_PixelAspectRatio=""" & V_PixelAspectRatio & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvs_Convert_File V_ScanType=""" & V_ScanType & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvs_Convert_File V_ScanOrder=""" & V_ScanOrder & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvs_Convert_File vrdtvs_IsProgressive=""" & vrdtvs_IsProgressive & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvs_Convert_File vrdtvs_IsInterlaced=""" & vrdtvs_IsInterlaced & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvs_Convert_File V_Width=""" & V_Width & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvs_Convert_File V_Height=""" & V_Height & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvs_Convert_File V_BitRate=""" & V_BitRate & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvs_Convert_File V_BitRate_Minimum=""" & V_BitRate_Minimum & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvs_Convert_File V_BitRate_Maximum=""" & V_BitRate_Maximum & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvs_Convert_File A_Codec_legacy=""" & A_Codec_legacy & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvs_Convert_File A_CodecID_legacy=""" & A_CodecID_legacy & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvs_Convert_File A_Format_legacy=""" & A_Format_legacy & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvs_Convert_File A_Video_Delay_ms=""" & A_Video_Delay_ms & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvs_Convert_File A_Video_Delay_ms_legacy=""" & A_Video_Delay_ms_legacy & """")
		WScript.StdOut.WriteLine("VRDTVS: vrdtvs_Convert_File A_Audio_Delay_ms=""" & A_Audio_Delay_ms & """")
		WScript.StdOut.WriteLine("VRDTVS: vrdtvs_Convert_File A_Audio_Delay_ms_legacy=""" & A_Audio_Delay_ms_legacy & """")
		WScript.StdOut.WriteLine("VRDTVS: vrdtvs_Convert_File A_CodecID=""" & A_CodecID & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvs_Convert_File A_CodecID_String=""" & A_CodecID_String & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvs_Convert_File V_CodecID_FF=""" & V_CodecID_FF & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvs_Convert_File V_CodecID_String_FF=""" & V_CodecID_String_FF & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvs_Convert_File V_Width_FF=""" & V_Width_FF & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvs_Convert_File V_Height_FF=""" & V_Height_FF & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvs_Convert_File V_Duration_s_FF=""" & V_Duration_s_FF & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvs_Convert_File V_BitRate_FF=""" & V_BitRate_FF & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvs_Convert_File V_BitRate_Maximum_FF=""" & V_BitRate_Maximum_FF & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvs_Convert_File adjusted SOURCE media characteristics above") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvs_Convert_File Q_V_Codec_legacy=""" & Q_V_Codec_legacy & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvs_Convert_File Q_V_Format_legacy=""" & Q_V_Format_legacy & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvs_Convert_File Q_V_DisplayAspectRatio_String_slash=""" & Q_V_DisplayAspectRatio_String_slash & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvs_Convert_File Q_V_PixelAspectRatio=""" & Q_V_PixelAspectRatio & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvs_Convert_File Q_V_ScanType=""" & Q_V_ScanType & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvs_Convert_File Q_V_ScanOrder=""" & Q_V_ScanOrder & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvs_Convert_File q_vrdtvs_IsProgressive=""" & q_vrdtvs_IsProgressive & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvs_Convert_File q_vrdtvs_IsInterlaced=""" & q_vrdtvs_IsInterlaced & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvs_Convert_File Q_V_Width=""" & Q_V_Width & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvs_Convert_File Q_V_Height=""" & Q_V_Height & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvs_Convert_File Q_V_BitRate=""" & Q_V_BitRate & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvs_Convert_File Q_V_BitRate_Minimum=""" & Q_V_BitRate_Minimum & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvs_Convert_File Q_V_BitRate_Maximum=""" & Q_V_BitRate_Maximum & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvs_Convert_File Q_A_Codec_legacy=""" & Q_A_Codec_legacy & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvs_Convert_File Q_A_CodecID_legacy=""" & Q_A_CodecID_legacy & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvs_Convert_File Q_A_Format_legacy=""" & Q_A_Format_legacy & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvs_Convert_File Q_A_Video_Delay_ms=""" & Q_A_Video_Delay_ms & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvs_Convert_File Q_A_Video_Delay_ms_legacy=""" & Q_A_Video_Delay_ms_legacy & """")
		WScript.StdOut.WriteLine("VRDTVS: vrdtvs_Convert_File Q_A_Audio_Delay_ms=""" & Q_A_Audio_Delay_ms & """")
		WScript.StdOut.WriteLine("VRDTVS: vrdtvs_Convert_File Q_A_Audio_Delay_ms_legacy=""" & Q_A_Audio_Delay_ms_legacy & """")
		WScript.StdOut.WriteLine("VRDTVS: vrdtvs_Convert_File Q_A_CodecID=""" & Q_A_CodecID & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvs_Convert_File Q_A_CodecID_String=""" & Q_A_CodecID_String & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvs_Convert_File Q_V_CodecID_FF=""" & Q_V_CodecID_FF & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvs_Convert_File Q_V_CodecID_String_FF=""" & Q_V_CodecID_String_FF & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvs_Convert_File Q_V_Width_FF=""" & Q_V_Width_FF & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvs_Convert_File Q_V_Height_FF=""" & Q_V_Height_FF & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvs_Convert_File Q_V_Duration_s_FF=""" & Q_V_Duration_s_FF & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvs_Convert_File Q_V_BitRate_FF=""" & Q_V_BitRate_FF & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvs_Convert_File Q_V_BitRate_Maximum_FF=""" & Q_V_BitRate_Maximum_FF & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvs_Convert_File V_INCOMING_BITRATE_MEDIAINFO=""" & V_INCOMING_BITRATE_MEDIAINFO & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvs_Convert_File V_INCOMING_BITRATE_FFPROBE=""" & V_INCOMING_BITRATE_FFPROBE & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvs_Convert_File V_INCOMING_BITRATE_QSF_LOG=""" & V_INCOMING_BITRATE_QSF_LOG & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvs_Convert_File V_INCOMING_BITRATE=""" & V_INCOMING_BITRATE & """") 
		If vrdtvs_DEVELOPMENT_NO_ACTIONS Then ' DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV 
			Wscript.Echo "Error 17 = cannot perform the requested operation"
			On Error goto 0
			WScript.Quit 17 ' Error 17 = cannot perform the requested operation
		Else
			Wscript.Echo "Error 17 = cannot perform the requested operation"
			On Error goto 0
			WScript.Quit 17 ' Error 17 = cannot perform the requested operation
		End If
		vrdtvs_Convert_File = -1
		Exit Function
	End If
	If Ucase(V_ScanOrder) <> Ucase(Q_V_ScanOrder) Then
		If vrdtvs_DEBUG Then WScript.StdOut.WriteLine("VRDTVS DEBUG: VRDTVS ERROR vrdtvs_Convert_File - Error - Ucase(V_ScanOrder) """ & Ucase(V_ScanOrder) & """ <> Ucase(Q_V_ScanOrder) """ & Ucase(Q_V_ScanOrder) & """  """ & CF_QSF_AbsolutePathName & """ """ & Q_V_Codec_legacy & """ ... Ignoring file ...")
		WScript.StdOut.WriteLine("VRDTVS ERROR vrdtvs_Convert_File - Error - Ucase(V_ScanOrder) """ & Ucase(V_ScanOrder) & """ <> Ucase(Q_V_ScanOrder) """ & Ucase(Q_V_ScanOrder) & """ """ & CF_QSF_AbsolutePathName & """ """ & Q_V_Codec_legacy & """ ... Ignoring file ...")
		WScript.StdOut.WriteLine("VRDTVS: vrdtvs_Convert_File adjusted SOURCE media characteristics below:") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvs_Convert_File V_Codec_legacy=""" & V_Codec_legacy & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvs_Convert_File V_Format_legacy=""" & V_Format_legacy & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvs_Convert_File V_DisplayAspectRatio_String_slash=""" & V_DisplayAspectRatio_String_slash & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvs_Convert_File V_PixelAspectRatio=""" & V_PixelAspectRatio & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvs_Convert_File V_ScanType=""" & V_ScanType & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvs_Convert_File V_ScanOrder=""" & V_ScanOrder & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvs_Convert_File V_Width=""" & V_Width & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvs_Convert_File V_Height=""" & V_Height & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvs_Convert_File V_BitRate=""" & V_BitRate & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvs_Convert_File V_BitRate_Minimum=""" & V_BitRate_Minimum & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvs_Convert_File V_BitRate_Maximum=""" & V_BitRate_Maximum & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvs_Convert_File A_Codec_legacy=""" & A_Codec_legacy & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvs_Convert_File A_CodecID_legacy=""" & A_CodecID_legacy & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvs_Convert_File A_Format_legacy=""" & A_Format_legacy & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvs_Convert_File A_Video_Delay_ms=""" & A_Video_Delay_ms & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvs_Convert_File A_Video_Delay_ms_legacy=""" & A_Video_Delay_ms_legacy & """")
		WScript.StdOut.WriteLine("VRDTVS: vrdtvs_Convert_File A_Audio_Delay_ms=""" & A_Audio_Delay_ms & """")
		WScript.StdOut.WriteLine("VRDTVS: vrdtvs_Convert_File A_Audio_Delay_ms_legacy=""" & A_Audio_Delay_ms_legacy & """")
		WScript.StdOut.WriteLine("VRDTVS: vrdtvs_Convert_File A_CodecID=""" & A_CodecID & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvs_Convert_File A_CodecID_String=""" & A_CodecID_String & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvs_Convert_File V_CodecID_FF=""" & V_CodecID_FF & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvs_Convert_File V_CodecID_String_FF=""" & V_CodecID_String_FF & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvs_Convert_File V_Width_FF=""" & V_Width_FF & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvs_Convert_File V_Height_FF=""" & V_Height_FF & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvs_Convert_File V_Duration_s_FF=""" & V_Duration_s_FF & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvs_Convert_File V_BitRate_FF=""" & V_BitRate_FF & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvs_Convert_File V_BitRate_Maximum_FF=""" & V_BitRate_Maximum_FF & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvs_Convert_File adjusted SOURCE media characteristics above") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvs_Convert_File Q_V_Codec_legacy=""" & Q_V_Codec_legacy & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvs_Convert_File Q_V_Format_legacy=""" & Q_V_Format_legacy & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvs_Convert_File Q_V_DisplayAspectRatio_String_slash=""" & Q_V_DisplayAspectRatio_String_slash & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvs_Convert_File Q_V_PixelAspectRatio=""" & Q_V_PixelAspectRatio & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvs_Convert_File Q_V_ScanType=""" & Q_V_ScanType & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvs_Convert_File Q_V_ScanOrder=""" & Q_V_ScanOrder & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvs_Convert_File Q_V_Width=""" & Q_V_Width & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvs_Convert_File Q_V_Height=""" & Q_V_Height & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvs_Convert_File Q_V_BitRate=""" & Q_V_BitRate & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvs_Convert_File Q_V_BitRate_Minimum=""" & Q_V_BitRate_Minimum & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvs_Convert_File Q_V_BitRate_Maximum=""" & Q_V_BitRate_Maximum & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvs_Convert_File Q_A_Codec_legacy=""" & Q_A_Codec_legacy & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvs_Convert_File Q_A_CodecID_legacy=""" & Q_A_CodecID_legacy & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvs_Convert_File Q_A_Format_legacy=""" & Q_A_Format_legacy & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvs_Convert_File Q_A_Video_Delay_ms=""" & Q_A_Video_Delay_ms & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvs_Convert_File Q_A_Video_Delay_ms_legacy=""" & Q_A_Video_Delay_ms_legacy & """")
		WScript.StdOut.WriteLine("VRDTVS: vrdtvs_Convert_File Q_A_Audio_Delay_ms=""" & Q_A_Audio_Delay_ms & """")
		WScript.StdOut.WriteLine("VRDTVS: vrdtvs_Convert_File Q_A_Audio_Delay_ms_legacy=""" & Q_A_Audio_Delay_ms_legacy & """")
		WScript.StdOut.WriteLine("VRDTVS: vrdtvs_Convert_File Q_A_CodecID=""" & Q_A_CodecID & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvs_Convert_File Q_A_CodecID_String=""" & Q_A_CodecID_String & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvs_Convert_File Q_V_CodecID_FF=""" & Q_V_CodecID_FF & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvs_Convert_File Q_V_CodecID_String_FF=""" & Q_V_CodecID_String_FF & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvs_Convert_File Q_V_Width_FF=""" & Q_V_Width_FF & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvs_Convert_File Q_V_Height_FF=""" & Q_V_Height_FF & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvs_Convert_File Q_V_Duration_s_FF=""" & Q_V_Duration_s_FF & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvs_Convert_File Q_V_BitRate_FF=""" & Q_V_BitRate_FF & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvs_Convert_File Q_V_BitRate_Maximum_FF=""" & Q_V_BitRate_Maximum_FF & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvs_Convert_File V_INCOMING_BITRATE_MEDIAINFO=""" & V_INCOMING_BITRATE_MEDIAINFO & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvs_Convert_File V_INCOMING_BITRATE_FFPROBE=""" & V_INCOMING_BITRATE_FFPROBE & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvs_Convert_File V_INCOMING_BITRATE_QSF_LOG=""" & V_INCOMING_BITRATE_QSF_LOG & """") 
		WScript.StdOut.WriteLine("VRDTVS: vrdtvs_Convert_File V_INCOMING_BITRATE=""" & V_INCOMING_BITRATE & """") 
		If vrdtvs_DEVELOPMENT_NO_ACTIONS Then ' DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV 
			Wscript.Echo "Error 17 = cannot perform the requested operation"
			On Error goto 0
			WScript.Quit 17 ' Error 17 = cannot perform the requested operation
		Else
			Wscript.Echo "Error 17 = cannot perform the requested operation"
			On Error goto 0
			WScript.Quit 17 ' Error 17 = cannot perform the requested operation
		End If
		vrdtvs_Convert_File = -1
		Exit Function
	End If
	'
	' +++++++++++++++++++++++++++ define initial video/audio conversion parameters +++++++++++++++++++++++++++
	'
	If Ucase(vrdtvs_ComputerName) = Ucase("3900X") Then
		vrdtvs_final_RTX2060super_extra_flags = "-spatial-aq 1 -temporal-aq 1 -refs 3"
	Else
		vrdtvs_final_RTX2060super_extra_flags = ""
	End If
	'
	' Calculate the target minimum_bitrate, target_bitrate, maximum_bitrate, buffer size
	' Note that the only reliable variable obtained from the QSF file is Q_V_BitRate
	If vrdtvs_IsAVC Then ' Ucase(Q_V_Codec_legacy) = Ucase("AVC")
		REM CALCULATE H.264 TARGET BITRATES FROM THE INCOMING BITRATE
		REM ffmpeg nvenc typically seems to undershoot the target bitrate, so bump it up.
		FF_V_Target_BitRate = V_INCOMING_BITRATE * 1.05			' + 5%
		FF_V_Target_Minimum_BitRate = V_INCOMING_BITRATE * 0.20	' 20%
		FF_V_Target_Maximum_BitRate = FF_V_Target_BitRate * 2	' double
		FF_V_Target_BufSize = FF_V_Target_BitRate * 2			' double
	Else ' by  the time it gets here it must be MPEG2 flagged as vrdtvs_IsMPEG2
		REM is MPEG2 input, so GUESS at reasonable H.264 TARGET BITRATE
		FF_V_Target_BitRate = 2000000
		FF_V_Target_Minimum_BitRate = 100000
		FF_V_Target_Maximum_BitRate = FF_V_Target_BitRate * 2
		FF_V_Target_BufSize = FF_V_Target_BitRate * 2
	End If
	'
	' NOTE:	After testing, it has been found that ffprobe can mis-report bitrates in the QSF'd file by about double.
	'		Although mediainfo and the "QSF log" values are reasonably close, testing shows ffprobe gets it more "right" when encoding.
	'		Although hopefully correct, this can result in a much lower transcoded filesizes than the originals.
	'		For now, accept what we PROPOSE on whether to "Up" the CQ from 0 to 24.
	' Initial Default CQ options:
	x_cq0 = "-cq:v 0"
	x_cq24 = "-cq:v 24 -qmin 16 -qmax 48"
	vrdtvs_final_cq_options = x_cq0 ' default to cq0
	PROPOSED_x_cq_options = vrdtvs_final_cq_options
	'
	' FOR AVC INPUT FILES ONLY, calculate the CQ to use (default to CQ0)
	' There are special cases where Mediainfo detects a lower bitrate than FFPROBE
	' and MediaInfo is likely right ... however FFPROBE is what we want it to be.
	' When this happens, if we just leave the bitrate CQ as-is then ffmpeg just undershoots 
	' even though we specify the higher bitrate of FFPROBE.
	' So ...
	' If we detect such a case, change to CQ24 instead of CQ0 and leave the 
	' specified bitrate unchanged ... which "should" fix it up.
	If vrdtvs_IsAVC Then ' Ucase(Q_V_Codec_legacy) = Ucase("AVC") 
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
	vrdtvs_final_cq_options = PROPOSED_x_cq_options
	'
	' Now Check for Footy, after the final fiddling with bitrates and CQ.
	' If is footy, deinterlace to 50FPS 50p, doubling the framerate, rather than just 25p
	' so that we maintain the "motion fluidity" of 50i into 50p. It's better than nothing.
	' We also need to set the field order, TFF etc
	If Ucase(V_ScanOrder) = Ucase("BFF") Then ' we default to TFF if not known
		vrdtvs_final_dg_tff = False
	Else
		vrdtvs_final_dg_tff = True
	End If
	Footy_found = False
	If Ucase(V_ScanType) = Ucase("Progressive") Then ' 
		vrdtvs_final_dg_deinterlace = 0	' no deinterlace for progressive files
	Else ' only check FOOTY for interlaced files
		If Instr(1,Ucase(fso.GetBaseName(CF_QSF_AbsolutePathName)), Ucase("AFL"), vbTextCompare) > 0 Then Footy_found = True
		If Instr(1,Ucase(fso.GetBaseName(CF_QSF_AbsolutePathName)), Ucase("SANFL"), vbTextCompare) > 0 Then Footy_found = True
		If Instr(1,Ucase(fso.GetBaseName(CF_QSF_AbsolutePathName)), Ucase("Adelaide Crows"), vbTextCompare) > 0 Then Footy_found = True
		If Instr(1,Ucase(fso.GetBaseName(CF_QSF_AbsolutePathName)), Ucase("Crows"), vbTextCompare) > 0 Then Footy_found = True
	End If		
	If Footy_found Then ' bump up the bitrates due o double framerate deinterlacing
		WScript.StdOut.WriteLine("VRDTVS vrdtvs_Convert_File: - FOOTY detected ... setting extended Footy_FF_V_* bitates for double-framerate conversion.")
		vrdtvs_final_dg_deinterlace = 2	' set for double framerate deinterlace
		Footy_FF_V_Target_BitRate = FF_V_Target_BitRate * 1.75
		Footy_FF_V_Target_Minimum_BitRate = Footy_FF_V_Target_BitRate * 0.20
		Footy_FF_V_Target_Maximum_BitRate = Footy_FF_V_Target_BitRate * 2
		Footy_FF_V_Target_BufSize = Footy_FF_V_Target_BitRate * 2
	Else ' default them back to non-footy settngs
		vrdtvs_final_dg_deinterlace = 1	' set for normal single framerate deinterlace
		Footy_FF_V_Target_BitRate = FF_V_Target_BitRate
		Footy_FF_V_Target_Minimum_BitRate = FF_V_Target_Minimum_BitRate
		Footy_FF_V_Target_Maximum_BitRate = FF_V_Target_Maximum_BitRate
		Footy_FF_V_Target_BufSize = FF_V_Target_BufSize
	End If
	If vrdtvs_DEBUG Then 
		WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_Convert_File - CF_QSF_AbsolutePathName              =""" & CF_QSF_AbsolutePathName & """")
		WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_Convert_File - Q_V_Codec_legacy                     =""" & Q_V_Codec_legacy & """")
		WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_Convert_File - V_ScanType                           =""" & V_ScanType & """")
		WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_Convert_File - V_ScanOrder                          =""" & V_ScanOrder & """")
		WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_Convert_File - vrdtvs_final_RTX2060super_extra_flags=""" & vrdtvs_final_RTX2060super_extra_flags & """")
		WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_Convert_File - vrdtvs_final_dg_tff                  =""" & vrdtvs_final_dg_tff & """")
		WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_Convert_File - vrdtvs_final_dg_deinterlace          =""" & vrdtvs_final_dg_deinterlace & """")
		WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_Convert_File - Footy_found                          =""" & Footy_found & """")
		WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_Convert_File - Footy_FF_V_Target_BitRate            =""" & Footy_FF_V_Target_BitRate & """")
		WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_Convert_File - Footy_FF_V_Target_Minimum_BitRate    =""" & Footy_FF_V_Target_Minimum_BitRate & """")
		WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_Convert_File - Footy_FF_V_Target_Maximum_BitRate    =""" & Footy_FF_V_Target_Maximum_BitRate & """")
		WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_Convert_File - Footy_FF_V_Target_BufSize            =""" & Footy_FF_V_Target_BufSize & """")
		WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_Convert_File - vrdtvs_final_cq_options              =""" & vrdtvs_final_cq_options & """")
		WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_Convert_File - FF_V_Target_BitRate                  =""" & FF_V_Target_BitRate & """")
		WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_Convert_File - FF_V_Target_Minimum_BitRate          =""" & FF_V_Target_Minimum_BitRate & """")
		WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_Convert_File - FF_V_Target_Maximum_BitRate          =""" & FF_V_Target_Maximum_BitRate & """")
		WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_Convert_File - FF_V_Target_BufSize                  =""" & FF_V_Target_BufSize & """")
	End If
	'
	' START ======================================================  Do the DGIndexNV ======================================================
	' ++++ START Run the DGIndexNV command
	ff_timerStart = Timer
	If vrdtvs_IsProgressive AND vrdtvs_IsAVC Then ' not required for Progressive-AVC where we just copy streams ' Ucase(V_ScanType) = Ucase("Progressive") AND Q_V_Codec_legacy <> "AVC"
		CF_object_saved_ffmpeg_commands.WriteLine("REM")
		CF_object_saved_ffmpeg_commands.WriteLine("REM DGIndexNV is NOT performed for Progressive-AVC where we just copy streams")
		CF_object_saved_ffmpeg_commands.WriteLine("REM")
		If vrdtvs_DEBUG Then 
			WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_Convert_File - DGIndexNV is not performed for Progressive-AVC where we just copy streams")
		End If
	Else
		CF_object_saved_ffmpeg_commands.WriteLine("REM")
		CF_object_saved_ffmpeg_commands.WriteLine("REM DGIndexNV is ONLY *not* performed for Progressive/AVC combination video")
		CF_object_saved_ffmpeg_commands.WriteLine("REM")
		If vrdtvs_DEBUG Then 
			WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_Convert_File - DGIndexNV is performed for NON-Progressive OR NON-AVC video")
		End If
		CF_exe_cmd_string = """" & vrdtvs_dgindexNVexe64 & """ -i """ & CF_QSF_AbsolutePathName & """ -h -o """ & CF_DGI_AbsolutePathName & """"
		CF_object_saved_ffmpeg_commands.WriteLine("DEL /F """ & CF_DGI_AbsolutePathName & """")
		CF_object_saved_ffmpeg_commands.WriteLine("DEL /F """ & CF_DGIlog_AbsolutePathName & """")
		CF_object_saved_ffmpeg_commands.WriteLine(CF_exe_cmd_string) ' write the QSF String to be executed
		CF_object_saved_ffmpeg_commands.WriteLine("REM")
		If vrdtvs_DEBUG Then 
			WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_Convert_File run DGIndexNV """ & CF_QSF_AbsolutePathName & """ with CF_exe_cmd_string=""" & CF_exe_cmd_string & """")
		End If
		vrdtvs_status = vrdtvs_delete_a_file(CF_DGI_AbsolutePathName, True)		' Delete the DGI file to be created by DGIndexNV
		vrdtvs_status = vrdtvs_delete_a_file(CF_DGIlog_AbsolutePathName, True)	' Delete the DGIlog file to be created by DGIndexNV
		CF_exe_status = vrdtvs_exec_a_command_and_show_stdout_stderr(CF_exe_cmd_string)
		If CF_exe_status <> 0 OR NOT fso.FileExists(CF_DGI_AbsolutePathName) Then
			If vrdtvs_DEBUG Then 
				WScript.StdOut.WriteLine("")
				WScript.StdOut.WriteLine("VRDTVS DEBUG: ERROR vrdtvs_Convert_File - Error - run DGIndexNV """ & CF_QSF_AbsolutePathName & """ with CF_exe_cmd_string=""" & CF_exe_cmd_string & """ CF_exe_status=" & CF_exe_status)
			End If
			WScript.StdOut.WriteLine("")
			WScript.StdOut.WriteLine("VRDTVS ERROR vrdtvs_Convert_File - Error - run DGIndexNV """ & CF_QSF_AbsolutePathName & """ with CF_exe_cmd_string=""" & CF_exe_cmd_string & """ CF_exe_status=" & CF_exe_status)
			If vrdtvs_DEVELOPMENT_NO_ACTIONS Then ' DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV 
				Wscript.Echo "DEV error after DGindexNV " & CF_exe_status
				Wscript.Echo "Error 17 = cannot perform the requested operation"
				On Error goto 0
				WScript.Quit 17 ' Error 17 = cannot perform the requested operation
			Else
				Wscript.Echo "error after DGindexNV " & CF_exe_status
				Wscript.Echo "Error 17 = cannot perform the requested operation"
				On Error goto 0
				WScript.Quit 17 ' Error 17 = cannot perform the requested operation
			End If
		End If
		If vrdtvs_DEBUG Then
			WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_Convert_File about to delete DG autolog " & CF_DGIlog_AbsolutePathName)
		End If
		vrdtvs_status = vrdtvs_delete_a_file (CF_DGIlog_AbsolutePathName, False)	' Delete the DGIlog file created by DGIndexNV
	End If
	ff_timerEnd = Timer
	WScript.StdOut.WriteLine("VRDTVS vrdtvs_Convert_File: - DGIndexNV command completed with Elapsed Time " & vrdtvs_Calculate_ElapsedTime_string(ff_timerStart, ff_timerEnd))
	' ++++ END Run the DGIndexNV command
	' END  ======================================================  Do the DGIndexNV ======================================================
	'
	' START  ======================================================  Create the .VPY ======================================================
	vrdtvs_create_VPY = True
	vpy_denoise  = ""
	vpy_dsharpen = ""
	If vrdtvs_IsProgressive Then ' Ucase(V_ScanType) = Ucase("Progressive")
		If vrdtvs_IsAVC Then ' Ucase(Q_V_Codec_legacy) = Ucase("AVC") 
			vrdtvs_create_VPY = False ' this is a NO-OP
			vpy_denoise = ""								' flag no denoising for progressive AVC
			vpy_dsharpen = ""								' flag no sharpening for progressive AVC
			' probesize 120 Mb, analyzeduration 120 seconds 2021.02.17
			ff_cmd_string =	"""" & vrdtvs_ffmpegexe64 & """ " &_
							"-hide_banner -v verbose -nostats " &_
							"-probesize 120M -analyzeduration 120M " &_
							"-i """ & CF_QSF_AbsolutePathName & """ " &_
							"-c:v copy " &_
							"-vsync 0 -sws_flags lanczos+accurate_rnd+full_chroma_int+full_chroma_inp -strict experimental " &_
							"-movflags +faststart+write_colr " &_
							"-af ""adelay=delays=" & A_Audio_Delay_ms & "ms:all=1"""
							' removed this line, since ffmpeg throws an error due to "-c:v copy" and this together: "-vf ""setdar=" & V_DisplayAspectRatio_String_slash & """ " &_
							' removed this line since ffmpeg throws an error "-profile:v high -level 5.2 -movflags +faststart+write_colr " &_
			If Ucase(A_Codec_legacy) = Ucase("AAC LC") Then
				ff_cmd_string =	ff_cmd_string & "-c:a copy "
			Else
				ff_cmd_string =	ff_cmd_string & "-c:a libfdk_aac -cutoff 20000 -ab 256k -ar 48000 "
			End If
			ff_cmd_string =	ff_cmd_string & " -y """ & CF_TARGET_AbsolutePathName & """"
							WScript.StdOut.WriteLine("VRDTVS vrdtvs_Convert_File: ========== Created ffmpeg_cmd_string, hopefully Progressive/AVC vs file: " & V_ScanType & " " & V_ScanOrder & " """ & V_Codec_legacy & """/""" & A_Codec_legacy & """")
			WScript.StdOut.WriteLine("VRDTVS vrdtvs_Convert_File: ========== Created ffmpeg_cmd_string <" & ff_cmd_string & ">")
		ElseIf vrdtvs_IsMPEG2 Then 'Ucase(Q_V_Codec_legacy) = Ucase("MPEG2-2V")
			vpy_denoise  = "strength=0.06, cstrength=0.06"	' flag denoising  for progressive mpeg2
			vpy_dsharpen = "strength=0.3"					' flag sharpening for progressive mpeg2
			' probesize 120 Mb, analyzeduration 120 seconds 2021.02.17
			ff_cmd_string =	"""" & vrdtvs_ffmpegexe64 & """ " &_
							"-hide_banner -v verbose -nostats " &_
							"-f vapoursynth -i """ & CF_VPY_AbsolutePathName & """ " &_
							"-probesize 120M -analyzeduration 120M " &_
							"-i """ & CF_QSF_AbsolutePathName & """ " &_
							"-map 0:v:0 -map 1:a:0 " &_
							"-vf ""setdar=" & V_DisplayAspectRatio_String_slash & """ " &_
							"-vsync 0 -sws_flags lanczos+accurate_rnd+full_chroma_int+full_chroma_inp -strict experimental " &_
							"-c:v h264_nvenc -pix_fmt nv12 -preset p7 -multipass fullres " &_
							vrdtvs_final_RTX2060super_extra_flags & " " &_
							"-rc:v vbr " &_
							"-cq:v 0" & " " &_
							"-b:v " & FF_V_Target_BitRate & " " &_
							"-minrate:v " & FF_V_Target_Minimum_BitRate & " " &_
							"-maxrate:v " & FF_V_Target_Maximum_BitRate & " " &_
							"-bufsize " & FF_V_Target_BufSize & " " &_
							"-profile:v high -level 5.2 -movflags +faststart+write_colr " &_
							"-af ""adelay=delays=" & A_Audio_Delay_ms & "ms:all=1""" &_
							"-c:a libfdk_aac -cutoff 20000 -ab 256k -ar 48000 " &_
							" -y """ & CF_TARGET_AbsolutePathName & """"
			WScript.StdOut.WriteLine("VRDTVS vrdtvs_Convert_File: ========== Created ffmpeg_cmd_string, hopefully Progressive/MPEG2 vs file: " & V_ScanType & " " & V_ScanOrder & " """ & V_Codec_legacy & """/""" & A_Codec_legacy & """")
			WScript.StdOut.WriteLine("VRDTVS vrdtvs_Convert_File: ========== Created ffmpeg_cmd_string <" & ff_cmd_string & ">")
		Else
			Wscript.Echo "Unable to create ff_cmd_string Progressive avc/mpeg2 - unknown codec " & Q_V_Codec_legacy
			Wscript.Echo "Error 17 = cannot perform the requested operation"
			On Error goto 0
			WScript.Quit 17 ' Error 17 = cannot perform the requested operation
		End If
	ElseIf vrdtvs_IsInterlaced Then
		if vrdtvs_IsAVC Then
			vpy_denoise = ""								' flag no denoising for interlaced AVC
			vpy_dsharpen = "strength=0.2"					' flag sharpening   for interlaced AVC
			' probesize 120 Mb, analyzeduration 120 seconds 2021.02.17
			ff_cmd_string =	"""" & vrdtvs_ffmpegexe64 & """ " &_
							"-hide_banner -v verbose -nostats " &_
							"-f vapoursynth -i """ & CF_VPY_AbsolutePathName & """ " &_
							"-probesize 120M -analyzeduration 120M " &_
							"-i """ & CF_QSF_AbsolutePathName & """ " &_
							"-map 0:v:0 -map 1:a:0 " &_
							"-vf ""setdar=" & V_DisplayAspectRatio_String_slash & """ " &_
							"-vsync 0 -sws_flags lanczos+accurate_rnd+full_chroma_int+full_chroma_inp -strict experimental " &_
							"-c:v h264_nvenc -pix_fmt nv12 -preset p7 -multipass fullres " &_
							vrdtvs_final_RTX2060super_extra_flags & " " &_
							"-rc:v vbr " &_
							vrdtvs_final_cq_options & " " &_
							"-b:v " & FF_V_Target_BitRate & " " &_
							"-minrate:v " & FF_V_Target_Minimum_BitRate & " " &_
							"-maxrate:v " & FF_V_Target_Maximum_BitRate & " " &_
							"-bufsize " & FF_V_Target_BufSize & " " &_
							"-profile:v high -level 5.2 -movflags +faststart+write_colr " &_
							"-af ""adelay=delays=" & A_Audio_Delay_ms & "ms:all=1""" &_
							"-c:a libfdk_aac -cutoff 20000 -ab 256k -ar 48000 " &_
							" -y """ & CF_TARGET_AbsolutePathName & """"
			If Footy_found Then	' Must be AVC Interlaced Footy to pass this test, USE DIFFERENT SETTINGS since we deinterlace with double framerate
				' probesize 120 Mb, analyzeduration 120 seconds 2021.02.17
				ff_cmd_string =	"""" & vrdtvs_ffmpegexe64 & """ " &_
								"-hide_banner -v verbose -nostats " &_
								"-f vapoursynth -i """ & CF_VPY_AbsolutePathName & """ " &_
								"-probesize 120M -analyzeduration 120M " &_
								"-i """ & CF_QSF_AbsolutePathName & """ " &_
								"-map 0:v:0 -map 1:a:0 " &_
								"-vf ""setdar=" & V_DisplayAspectRatio_String_slash & """ " &_
								"-vsync 0 -sws_flags lanczos+accurate_rnd+full_chroma_int+full_chroma_inp -strict experimental " &_
								"-c:v h264_nvenc -pix_fmt nv12 -preset p7 -multipass fullres " &_
								vrdtvs_final_RTX2060super_extra_flags & " " &_
								"-rc:v vbr " &_
								vrdtvs_final_cq_options & " " &_
								"-b:v " & Footy_FF_V_Target_BitRate & " " &_
								"-minrate:v " & Footy_FF_V_Target_Minimum_BitRate & " " &_
								"-maxrate:v " & Footy_FF_V_Target_Maximum_BitRate & " " &_
								"-bufsize " & Footy_FF_V_Target_BufSize & " " &_
								"-profile:v high -level 5.2 -movflags +faststart+write_colr " &_
								"-af ""adelay=delays=" & A_Audio_Delay_ms & "ms:all=1""" &_
								"-c:a libfdk_aac -cutoff 20000 -ab 256k -ar 48000 " &_
								" -y """ & CF_TARGET_AbsolutePathName & """"
				WScript.StdOut.WriteLine("VRDTVS vrdtvs_Convert_File: ========== FOOTY detected, hopefully Interlaced/AVC vs file: " & V_ScanType & " " & V_ScanOrder & " """ & V_Codec_legacy & """/""" & A_Codec_legacy & """")
			End If
			WScript.StdOut.WriteLine("VRDTVS vrdtvs_Convert_File: ========== Created ffmpeg_cmd_string, hopefully Interlaced/AVC vs file: " & V_ScanType & " " & V_ScanOrder & " """ & V_Codec_legacy & """/""" & A_Codec_legacy & """")
			WScript.StdOut.WriteLine("VRDTVS vrdtvs_Convert_File: ========== Created ffmpeg_cmd_string <" & ff_cmd_string & ">")
		ElseIf vrdtvs_IsMPEG2 Then
			vpy_denoise = "strength=0.06, cstrength=0.06"	' flag denoising  for interlaced mpeg2
			vpy_dsharpen = "strength=0.3"					' flag sharpening for interlaced mpeg2
			' probesize 120 Mb, analyzeduration 120 seconds 2021.02.17
			ff_cmd_string =	"""" & vrdtvs_ffmpegexe64 & """ " &_
							"-hide_banner -v verbose -nostats " &_
							"-f vapoursynth -i """ & CF_VPY_AbsolutePathName & """ " &_
							"-probesize 120M -analyzeduration 120M " &_
							"-i """ & CF_QSF_AbsolutePathName & """ " &_
							"-map 0:v:0 -map 1:a:0 " &_
							"-vf ""setdar=" & V_DisplayAspectRatio_String_slash & """ " &_
							"-vsync 0 -sws_flags lanczos+accurate_rnd+full_chroma_int+full_chroma_inp -strict experimental " &_
							"-c:v h264_nvenc -pix_fmt nv12 -preset p7 -multipass fullres " &_
							vrdtvs_final_RTX2060super_extra_flags & " " &_
							"-rc:v vbr " &_
							vrdtvs_final_cq_options & " " &_
							"-b:v " & FF_V_Target_BitRate & " " &_
							"-minrate:v " & FF_V_Target_Minimum_BitRate & " " &_
							"-maxrate:v " & FF_V_Target_Maximum_BitRate & " " &_
							"-bufsize " & FF_V_Target_BufSize & " " &_
							"-profile:v high -level 5.2 -movflags +faststart+write_colr " &_
							"-af ""adelay=delays=" & A_Audio_Delay_ms & "ms:all=1""" &_
							"-c:a libfdk_aac -cutoff 20000 -ab 256k -ar 48000 " &_
							" -y """ & CF_TARGET_AbsolutePathName & """"
			' Leave MPEG2 Interlaced Footy alone, as if it were a normal video file ... no code for MPEG2 Interlaced Footy in here
			WScript.StdOut.WriteLine("VRDTVS vrdtvs_Convert_File: ========== Created ffmpeg_cmd_string, hopefully Interlaced/MPEG2 vs file: " & V_ScanType & " " & V_ScanOrder & " """ & V_Codec_legacy & """/""" & A_Codec_legacy & """")
			WScript.StdOut.WriteLine("VRDTVS vrdtvs_Convert_File: ========== Created ffmpeg_cmd_string <" & ff_cmd_string & ">")
		Else
			Wscript.Echo "Unable to create ff_cmd_string Interlaced avc/mpeg2 - unknown codec " & Q_V_Codec_legacy
			Wscript.Echo "Error 17 = cannot perform the requested operation"
			On Error goto 0
			WScript.Quit 17 ' Error 17 = cannot perform the requested operation
		End If
	Else
		'??????????????print diagnostics and exit since not Progressive nor Interlaced ...
		Wscript.Echo "Unable to create ff_cmd_string as flag is neither Interlaced nor Progressive .. vrdtvs_IsInterlaced=" & vrdtvs_IsInterlaced & " Progressive=" & vrdtvs_IsProgressive
		Wscript.Echo "Error 17 = cannot perform the requested operation"
		On Error goto 0
		WScript.Quit 17 ' Error 17 = cannot perform the requested operation
	End If
	If vrdtvs_create_VPY Then
		'create the vpy file
		vrdtvs_status = vrdtvs_delete_a_file(CF_VPY_AbsolutePathName, True)		' Delete the VPY file to be created
		set CF_VPY_object = fso.CreateTextFile(CF_VPY_AbsolutePathName, True, False) ' *** vapoursynth fails with unicode input file *** [ filename, Overwrite[, Unicode]])
		If CF_VPY_object is Nothing  Then ' Something went wrong with creating the file
			If vrdtvs_DEBUG Then WScript.StdOut.WriteLine("VRDTVS DEBUG: VRDTVS ERROR vrdtvs_Convert_File - Error - Nothing object returned from fso.CreateTextFile with VPY file """ & CF_VPY_AbsolutePathName & """... Aborting ...")
			WScript.StdOut.WriteLine("VRDTVS ERROR vrdtvs_Convert_File - Error - Nothing object returned from fso.CreateTextFile with VPY file  """ & CF_VPY_AbsolutePathName & """... Aborting ...")
			On Error goto 0
			WScript.Quit 17 ' Error 17 = cannot perform the requested operation
		End If
		CF_object_saved_ffmpeg_commands.WriteLine("REM")
		CF_object_saved_ffmpeg_commands.WriteLine("DEL /F """ & CF_VPY_AbsolutePathName & """")
		CF_object_saved_ffmpeg_commands.WriteLine("SET ""_VPY_file=" & CF_VPY_AbsolutePathName & """")		
		CF_status = vrdtvs_writeline_for_vpy (CF_VPY_object, CF_object_saved_ffmpeg_commands, "import vapoursynth as vs		# this allows use of constants eg vs.YUV420P8", "ECHO ", " >> ""!_VPY_file!"" 2>&1")
		CF_status = vrdtvs_writeline_for_vpy (CF_VPY_object, CF_object_saved_ffmpeg_commands, "from vapoursynth import core	# actual vapoursynth core", "ECHO ", " >> ""!_VPY_file!"" 2>&1")
		CF_status = vrdtvs_writeline_for_vpy (CF_VPY_object, CF_object_saved_ffmpeg_commands, "#import functool", "ECHO ", " >> ""!_VPY_file!"" 2>&1")
		CF_status = vrdtvs_writeline_for_vpy (CF_VPY_object, CF_object_saved_ffmpeg_commands, "#import mvsfunc as mvs			# this relies on the .py residing at the VS folder root level - see run_vsrepo.bat", "ECHO ", " >> ""!_VPY_file!"" 2>&1")
		CF_status = vrdtvs_writeline_for_vpy (CF_VPY_object, CF_object_saved_ffmpeg_commands, "#import havsfunc as haf		# this relies on the .py residing at the VS folder root level - see run_vsrepo.bat", "ECHO ", " >> ""!_VPY_file!"" 2>&1")
		CF_status = vrdtvs_writeline_for_vpy (CF_VPY_object, CF_object_saved_ffmpeg_commands, "core.std.LoadPlugin(r'" & vs_root & "\DGIndex\DGDecodeNV.dll') # do it like gonca https://forum.doom9.org/showthread.php?p=1877765#post1877765", "ECHO ", " >> ""!_VPY_file!"" 2>&1")
		CF_status = vrdtvs_writeline_for_vpy (CF_VPY_object, CF_object_saved_ffmpeg_commands, "core.avs.LoadPlugin(r'" & vs_root & "\DGIndex\DGDecodeNV.dll') # do it like gonca https://forum.doom9.org/showthread.php?p=1877765#post1877765", "ECHO ", " >> ""!_VPY_file!"" 2>&1")
		CF_status = vrdtvs_writeline_for_vpy (CF_VPY_object, CF_object_saved_ffmpeg_commands, "# NOTE: deinterlace=" & vrdtvs_final_dg_deinterlace & ", use_top_field=" & vrdtvs_final_dg_tff & " for """ & V_ScanType & """/""" & V_ScanOrder & """ """ & V_Codec_legacy & """/""" & A_Codec_legacy & """", "ECHO ", " >> ""!_VPY_file!"" 2>&1")
		CF_status = vrdtvs_writeline_for_vpy (CF_VPY_object, CF_object_saved_ffmpeg_commands, "video = core.dgdecodenv.DGSource(r'" & CF_DGI_AbsolutePathName & "', deinterlace=" & vrdtvs_final_dg_deinterlace & ", use_top_field=" & vrdtvs_final_dg_tff & ", use_pf=False)", "ECHO ", " >> ""!_VPY_file!"" 2>&1")
		CF_status = vrdtvs_writeline_for_vpy (CF_VPY_object, CF_object_saved_ffmpeg_commands, "# DGDecNV changes -", "ECHO ", " >> ""!_VPY_file!"" 2>&1")
		CF_status = vrdtvs_writeline_for_vpy (CF_VPY_object, CF_object_saved_ffmpeg_commands, "# 2020.10.21 Added new parameters cstrength and cblend to independently control the chroma denoising.", "ECHO ", " >> ""!_VPY_file!"" 2>&1")
		CF_status = vrdtvs_writeline_for_vpy (CF_VPY_object, CF_object_saved_ffmpeg_commands, "# 2020.11.07 Revised DGDenoise parameters. The 'chroma' option is removed.", "ECHO ", " >> ""!_VPY_file!"" 2>&1")
		CF_status = vrdtvs_writeline_for_vpy (CF_VPY_object, CF_object_saved_ffmpeg_commands, "#            Now, if 'strength' is set to 0.0 then luma denoising is disabled,", "ECHO ", " >> ""!_VPY_file!"" 2>&1")
		CF_status = vrdtvs_writeline_for_vpy (CF_VPY_object, CF_object_saved_ffmpeg_commands, "#            and if cstrength is set to 0.0 then chroma denoising is disabled.", "ECHO ", " >> ""!_VPY_file!"" 2>&1")
		CF_status = vrdtvs_writeline_for_vpy (CF_VPY_object, CF_object_saved_ffmpeg_commands, "#            'cstrength' is now defaulted to 0.0, and 'searchw' is defaulted to 9.", "ECHO ", " >> ""!_VPY_file!"" 2>&1")
		CF_status = vrdtvs_writeline_for_vpy (CF_VPY_object, CF_object_saved_ffmpeg_commands, "# example: video = core.avs.DGDenoise(video, strength=0.06, cstrength=0.06) # replaced chroma=True", "ECHO ", " >> ""!_VPY_file!"" 2>&1")
		If vpy_denoise <> "" Then CF_status = vrdtvs_writeline_for_vpy (CF_VPY_object, CF_object_saved_ffmpeg_commands, "video = core.avs.DGDenoise(video, " & vpy_denoise & ") # replaced chroma=True", "ECHO ", " >> ""!_VPY_file!"" 2>&1")
		CF_status = vrdtvs_writeline_for_vpy (CF_VPY_object, CF_object_saved_ffmpeg_commands, "# example: video = core.avs.DGSharpen(video, strength=0.3)", "ECHO ", " >> ""!_VPY_file!"" 2>&1")
		If vpy_dsharpen <> "" Then CF_status = vrdtvs_writeline_for_vpy (CF_VPY_object, CF_object_saved_ffmpeg_commands, "video = core.avs.DGSharpen(video, " & vpy_dsharpen & ")", "ECHO ", " >> ""!_VPY_file!"" 2>&1")
		CF_status = vrdtvs_writeline_for_vpy (CF_VPY_object, CF_object_saved_ffmpeg_commands, "#video = vs.core.text.ClipInfo(video)", "ECHO ", " >> ""!_VPY_file!"" 2>&1")
		CF_status = vrdtvs_writeline_for_vpy (CF_VPY_object, CF_object_saved_ffmpeg_commands, "video.set_output()", "ECHO ", " >> ""!_VPY_file!"" 2>&1")
		CF_status = CF_VPY_object.Close
		Set CF_VPY_object = Nothing
		WScript.StdOut.WriteLine("VRDTVS vrdtvs_Convert_File: - Created VPY file """ & CF_VPY_AbsolutePathName & """ NOTE: used deinterlace=" & vrdtvs_final_dg_deinterlace & ", use_top_field=" & vrdtvs_final_dg_tff & " for """ & V_ScanType & """/""" & V_ScanOrder & """ """ & V_Codec_legacy & """/""" & A_Codec_legacy & """")
		CF_object_saved_ffmpeg_commands.WriteLine("ECHO ---------------------------- 2>&1")
		CF_object_saved_ffmpeg_commands.WriteLine("TYPE ""!_VPY_file!"" 2>&1")
		CF_object_saved_ffmpeg_commands.WriteLine("ECHO ---------------------------- 2>&1")
		' display the content of .VPY file
		WScript.StdOut.WriteLine("VRDTVS vrdtvs_Convert_File: - Content of VPY file """ & CF_VPY_AbsolutePathName & """ Below :")
		Set CF_VPY_object = fso.OpenTextFile(CF_VPY_AbsolutePathName, ForReading)
		Do Until CF_VPY_object.AtEndOfStream
			CF_VPY_string = CF_VPY_object.ReadLine
			WScript.StdOut.WriteLine(CF_VPY_string)
		Loop			
		CF_status = CF_VPY_object.Close
		Set CF_VPY_object = Nothing
		WScript.StdOut.WriteLine("VRDTVS vrdtvs_Convert_File: - Content of VPY file """ & CF_VPY_AbsolutePathName & """ Above.")
	Else ' Else is previously flagged as not creating a VPY since incoming stream is Progressive/AVC
	End If
	'
	CF_object_saved_ffmpeg_commands.WriteLine("REM")
	If Footy_found Then
		WScript.StdOut.WriteLine("VRDTVS vrdtvs_Convert_File: - Footy Found, using Footy double-framerate deinterlacing and bitrate settings")
		CF_object_saved_ffmpeg_commands.WriteLine("REM Footy Found, using Footy double-framerate deinterlacing and bitrate settings")
		CF_object_saved_ffmpeg_commands.WriteLine("REM")
	End If
	CF_object_saved_ffmpeg_commands.WriteLine("DEL /F """ & CF_TARGET_AbsolutePathName & """")
	CF_object_saved_ffmpeg_commands.WriteLine("REM")
	CF_object_saved_ffmpeg_commands.WriteLine(ff_cmd_string)
	CF_object_saved_ffmpeg_commands.WriteLine("REM")
	'
	' ++++ START Run the ffmpeg command
	ff_timerStart = Timer
	vrdtvs_status = vrdtvs_delete_a_file(CF_TARGET_AbsolutePathName, True)
	'???????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????
	'???????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????
	' GRRRRRRRRRRRRRRRRRRRR ...
	' No matter what I do with wso.Exec, ffmpeg never completes and the Exec object always returns a status "0" and so runs forever. Grrr.
	' Although ... the VERY SAME command, both directly and run in a .BAT file, works perfectly from a vanilla DOS command box.
	' Since we require output from running ffmpeg, and the commandline has a LOT of parameters (some quoted),
	'	stick the command in a .bat file with message redirection to a log file
	'	and then synchronously Run the .bat file
	'	then examine the returned errorlevel and the logfile
	ff_logfile = vrdtvs_gimme_a_temporary_absolute_filename ("ffmpeg-command-output-" & vrdtvs_run_datetime) & ".log"
	ff_batfile = vrdtvs_gimme_a_temporary_absolute_filename ("ffmpeg-command-" & vrdtvs_run_datetime) & ".BAT"
	ff_cmd_string_for_bat = ff_cmd_string & " >""" & ff_logfile & """ 2>&1" ' redirect both stdout and stderr from ffmpeg to a file
	vrdtvs_status = vrdtvs_delete_a_file(ff_logfile, True)		' Delete the .bat file to be created with the ffmpeg command
	vrdtvs_status = vrdtvs_delete_a_file(ff_batfile, True)		' Delete the .bat file to be created with the ffmpeg command
	set ff_tmp_object = fso.CreateTextFile(ff_batfile, True, False) ' *** vapoursynth fails with unicode input file *** [ filename, Overwrite[, Unicode]])
	ff_tmp_object.WriteLine("@ECHO ON")
	ff_tmp_object.WriteLine("@setlocal ENABLEDELAYEDEXPANSION")
	ff_tmp_object.WriteLine("@setlocal enableextensions")
	ff_tmp_object.WriteLine("DEL /F """ & ff_logfile & """")
	ff_tmp_object.WriteLine("ECHO !DATE! !TIME! FFMPEG STARTED *************************************************************************** >>""" & ff_logfile & """ 2>&1")
	ff_tmp_object.WriteLine("ECHO !DATE! !TIME! FFMPEG STARTED *************************************************************************** >>""" & ff_logfile & """ 2>&1")
	ff_tmp_object.WriteLine(ff_cmd_string_for_bat)
	ff_tmp_object.WriteLine("Set EL=%ERRORLEVEL%")
	ff_tmp_object.WriteLine("ECHO The ffmpeg.exe returned Errorlevel = %EL% >>""" & ff_logfile & """ 2>&1")
	ff_tmp_object.WriteLine("ECHO !DATE! !TIME! FFMPEG FINISHED *************************************************************************** >>""" & ff_logfile & """ 2>&1")
	ff_tmp_object.WriteLine("ECHO !DATE! !TIME! FFMPEG FINISHED *************************************************************************** >>""" & ff_logfile & """ 2>&1")
	ff_tmp_object.WriteLine("EXIT %EL%")
	ff_tmp_object.close
	set ff_tmp_object = Nothing
	' let's dump the ffmpeg .BAT file
	WScript.StdOut.WriteLine("VRDTVS vrdtvs_Convert_File: - ******************** START Content of FFMPEG .BAT file """ & ff_batfile & """ Below:")
	Set ff_tmp_object = fso.OpenTextFile(ff_batfile, ForReading)
	Do Until ff_tmp_object.AtEndOfStream
		ff_tmp_string = ff_tmp_object.ReadLine
		WScript.StdOut.WriteLine(ff_tmp_string)
	Loop			
	CF_status = ff_tmp_object.Close
	Set ff_tmp_object = Nothing
	WScript.StdOut.WriteLine("VRDTVS vrdtvs_Convert_File: - ******************** END Content of FFMPEG .BAT file """ & ff_batfile & """ Above.")
	' Now .Run the .bat
	WScript.StdOut.WriteLine("VRDTVS vrdtvs_Convert_File: - ******************** About to .Run FFMPEG .BAT file """ & ff_batfile & """ :")
	ff_run_errorlevel = wso.Run("CMD /C """ & ff_batfile & """", 7, True) '(strCommand, [intWindowStyle], [bWaitOnReturn]) ' https://ss64.com/vb/run.html
	WScript.StdOut.WriteLine("VRDTVS vrdtvs_Convert_File: - ******************** .Run FFMPEG .BAT file """ & ff_batfile & """ Exit status :" & ff_run_errorlevel)
	' let's dump the resulting ffmpeg log
	WScript.StdOut.WriteLine("VRDTVS vrdtvs_Convert_File: - ******************** START Content of FFMPEG LOG file """ & ff_logfile & """ Below:")
	Set ff_tmp_object = fso.OpenTextFile(ff_logfile, ForReading)
	Do Until ff_tmp_object.AtEndOfStream
		ff_tmp_string = ff_tmp_object.ReadLine
		WScript.StdOut.WriteLine(ff_tmp_string)
	Loop			
	CF_status = ff_tmp_object.Close
	Set ff_tmp_object = Nothing
	WScript.StdOut.WriteLine("VRDTVS vrdtvs_Convert_File: - ******************** END Content of FFMPEG LOG file """ & ff_logfile & """ Above.")
	WScript.StdOut.WriteLine("VRDTVS vrdtvs_Convert_File: - ******************** RETURNED ff_run_errorlevel=" & ff_run_errorlevel)
	CF_exe_status = ff_run_errorlevel
	If (CF_exe_status <> 0) OR (NOT fso.FileExists(CF_TARGET_AbsolutePathName)) Then
		If vrdtvs_DEBUG Then WScript.StdOut.WriteLine("VRDTVS DEBUG: ERROR vrdtvs_Convert_File - FFMPEG Error - CF_exe_status=""" & CF_exe_status & """ with ff_cmd_string=""" & ff_cmd_string)
		WScript.StdOut.WriteLine("VRDTVS ERROR vrdtvs_Convert_File - FFMPEG Error - CF_exe_status=""" & CF_exe_status & """ with ff_cmd_string=""" & ff_cmd_string)
		If vrdtvs_DEVELOPMENT_NO_ACTIONS Then ' DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV 
			WScript.StdOut.WriteLine("VRDTVS DEV: vrdtvs_DEVELOPMENT_NO_ACTIONS: DEV: vrdtvs_Convert_File NOT moving file to FAILED folder: """ & CF_FILE_AbsolutePathName & """ to """ & CF_failed_conversion_TS_Folder & """")
		Else
			vrdtvs_status = vrdtvs_move_files_to_folder(CF_FILE_AbsolutePathName, CF_failed_conversion_TS_Folder)
			WScript.StdOut.WriteLine("VRDTVS vrdtvs_Convert_File: - ???????????????????? moved FAILED CONVERSION file to FAILED folder: """ & CF_FILE_AbsolutePathName & """ to """ & CF_failed_conversion_TS_Folder & """")
			WScript.StdOut.WriteLine("VRDTVS vrdtvs_Convert_File: - ???????????????????? moved FAILED CONVERSION file to FAILED folder: """ & CF_FILE_AbsolutePathName & """ to """ & CF_failed_conversion_TS_Folder & """")
			WScript.StdOut.WriteLine("VRDTVS vrdtvs_Convert_File: - ???????????????????? moved FAILED CONVERSION file to FAILED folder: """ & CF_FILE_AbsolutePathName & """ to """ & CF_failed_conversion_TS_Folder & """")
			WScript.StdOut.WriteLine("VRDTVS vrdtvs_Convert_File: - ???????????????????? moved FAILED CONVERSION file to FAILED folder: """ & CF_FILE_AbsolutePathName & """ to """ & CF_failed_conversion_TS_Folder & """")
			WScript.StdOut.WriteLine("VRDTVS vrdtvs_Convert_File: - ???????????????????? moved FAILED CONVERSION file to FAILED folder: """ & CF_FILE_AbsolutePathName & """ to """ & CF_failed_conversion_TS_Folder & """")
		End If
		On Error goto 0
		'WScript.Quit 17 ' Error 17 = cannot perform the requested operation
		vrdtvs_Convert_File = -1
		Exit Function
	End If
	vrdtvs_status = vrdtvs_delete_a_file(ff_logfile, True)		' Delete the .bat file to be created with the ffmpeg command
	vrdtvs_status = vrdtvs_delete_a_file(ff_batfile, True)		' Delete the .bat file to be created with the ffmpeg command
	ff_timerEnd = Timer
    WScript.StdOut.WriteLine("VRDTVS vrdtvs_Convert_File: - ffmpeg command completed with Elapsed Time " & vrdtvs_Calculate_ElapsedTime_string(ff_timerStart, ff_timerEnd))
	' ++++ END Run the ffmpeg command
	'
	' after ffmpeg, do an ADSCAN over the TARGET file and save the .bprj in the target folder as an "associated .bprj" which will be picked up by auto-bprj-processing during bulk file renames :)
	If CF_do_Adcsan Then
		' ++++ START Run the ADSCAN command
		ff_timerStart = Timer
		vrdtvs_status = vrdtvs_delete_a_file(vrd_logfile_wildcard_ADSCAN, True) ' True=silently delete it	' is a wildcard, in fso.DeleteFile the filespec can contain wildcard characters in the last path component
		CF_exe_cmd_string = "cscript //Nologo """ & vrd_path_for_adscan_vbs & """ """ & CF_TARGET_AbsolutePathName & """  """ & CF_BPRJ_AbsolutePathName & """ /q"
		If vrdtvs_DEBUG Then 
			WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_Convert_File """ & CF_TARGET_AbsolutePathName & """ V_Codec_legacy=""" & V_Codec_legacy & """ do ADSCAN with CF_exe_cmd_string=""" & CF_exe_cmd_string & """")
		End If
		' save ADSCAN command
		CF_object_saved_ffmpeg_commands.WriteLine("REM")
		CF_object_saved_ffmpeg_commands.WriteLine("REM Do the ADSCAN for """ & CF_TARGET_AbsolutePathName & """ ... ")
		CF_object_saved_ffmpeg_commands.WriteLine("REM")
		CF_object_saved_ffmpeg_commands.WriteLine("DEL /F """ & CF_BPRJ_AbsolutePathName & """")
		CF_object_saved_ffmpeg_commands.WriteLine(CF_exe_cmd_string) ' write the ADSCAN String to be executed
		CF_object_saved_ffmpeg_commands.WriteLine("REM")
		' do the actual ADCSAN command (delete the BPRJ file first)
		WScript.StdOut.WriteLine("VRDTVS vrdtvs_Convert_File: - ******************** Start of run ADSCAN """ & CF_exe_cmd_string & """ :")
		WScript.StdOut.WriteLine("VRDTVS vrdtvs_Convert_File: Doing ADSCAN for """ & CF_TARGET_AbsolutePathName & """ ... ")
		WScript.StdOut.WriteLine("VRDTVS vrdtvs_Convert_File: ADSCAN command: " & CF_exe_cmd_string)
		vrdtvs_status = vrdtvs_delete_a_file(CF_BPRJ_AbsolutePathName, True) ' True=silently delete it
		CF_exe_status = vrdtvs_exec_a_command_and_show_stdout_stderr(CF_exe_cmd_string)
		If CF_exe_status <> 0 OR NOT fso.FileExists(CF_BPRJ_AbsolutePathName) Then
			If vrdtvs_DEBUG Then WScript.StdOut.WriteLine("VRDTVS DEBUG: ERROR vrdtvs_Convert_File - Error - Failed to ADSCAN """ & CF_TARGET_AbsolutePathName & """ V_Codec_legacy=""" & V_Codec_legacy & """ CF_exe_cmd_string=""" & CF_exe_cmd_string & """")
			WScript.StdOut.WriteLine("VRDTVS ERROR vrdtvs_Convert_File - Error - Failed to ADSCAN """ & CF_TARGET_AbsolutePathName & """ V_Codec_legacy=""" & V_Codec_legacy & """ CF_exe_cmd_string=""" & CF_exe_cmd_string & """")
			If vrdtvs_DEVELOPMENT_NO_ACTIONS Then ' DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV 
				Wscript.Echo "Error 17 = cannot perform the requested operation"
				On Error goto 0
				WScript.Quit 17 ' Error 17 = cannot perform the requested operation
			Else
				Wscript.Echo "Error 17 = cannot perform the requested operation"
				On Error goto 0
				WScript.Quit 17 ' Error 17 = cannot perform the requested operation
			End If
			vrdtvs_Convert_File = -1
			Exit Function
		End If
		WScript.StdOut.WriteLine("VRDTVS vrdtvs_Convert_File: - ******************** End of run ADSCAN """ & CF_exe_cmd_string & """ ")
		ff_timerEnd = Timer
		WScript.StdOut.WriteLine("VRDTVS vrdtvs_Convert_File: - ADSCAN command completed with Elapsed Time " & vrdtvs_Calculate_ElapsedTime_string(ff_timerStart, ff_timerEnd))
		' ++++ END Run the ffmpeg command
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
	vrdtvs_status = vrdtvs_delete_a_file(CF_DGI_AbsolutePathName, True)
	vrdtvs_status = vrdtvs_delete_a_file(CF_VPY_AbsolutePathName, True)
	vrdtvs_status = vrdtvs_delete_a_file(CF_QSF_AbsolutePathName, True)
	If vrdtvs_DEVELOPMENT_NO_ACTIONS Then ' DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV DEV 
		WScript.StdOut.WriteLine("VRDTVS DEV: vrdtvs_DEVELOPMENT_NO_ACTIONS: DEV: vrdtvs_Convert_File NOT moving file to DONE folder: """ & CF_FILE_AbsolutePathName & """ to """ & CF_done_TS_Folder & """")
	Else
		vrdtvs_status = vrdtvs_move_files_to_folder(CF_FILE_AbsolutePathName, CF_done_TS_Folder)
		WScript.StdOut.WriteLine("VRDTVS vrdtvs_Convert_File: moved file to DONE folder: """ & CF_FILE_AbsolutePathName & """ to """ & CF_done_TS_Folder & """")
	End If
	vrdtvs_Convert_File = 0				
	WScript.StdOut.WriteLine("VRDTVS vrdtvs_Convert_File: FINISHED " & vrdtvs_current_datetime_string() & " ======================================================================================================================================================")
	WScript.StdOut.WriteLine("VRDTVS vrdtvs_Convert_File: FINISHED " & vrdtvs_current_datetime_string() & " ======================================================================================================================================================")
End Function
'
Function vrdtvs_writeline_for_vpy (vpy_filename_object, bat_filename_object, a_vpy_statement, prepend_string, append_string)
	' Write vpy statements to a "normal" .vpy file and ".BAT-escaped" to the batch file used to re-create the .vpy file
	' Parameters
	'		vpy_filename_object		ALREADY OPENED FOR WRITE
	'		bat_filename_object		ALREADY OPENED FOR WRITE
	'		prepend_string			eg "ECHO " including a trailing space
	'		append_string			eg " >> "!_VPY_file!" 2>&1"  including a trailing space
	Dim escaped_vpy_statement
	If vrdtvs_DEBUG Then
		WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_writeline_for_vpy about to writeline vpy_filename_object       a_vpy_statement" & Space(Len(prepend_string)) & "=<" & a_vpy_statement & ">")
	End If
	vpy_filename_object.WriteLine(a_vpy_statement)
	escaped_vpy_statement = a_vpy_statement
	escaped_vpy_statement = Replace(escaped_vpy_statement, "(", "^(", 1, -1, vbTextCompare)
	escaped_vpy_statement = Replace(escaped_vpy_statement, ")", "^)", 1, -1, vbTextCompare)
	escaped_vpy_statement = Replace(escaped_vpy_statement, "<", "^<", 1, -1, vbTextCompare)
	escaped_vpy_statement = Replace(escaped_vpy_statement, ">", "^>", 1, -1, vbTextCompare)
	escaped_vpy_statement = prepend_string & escaped_vpy_statement & append_string
	If vrdtvs_DEBUG Then
		WScript.StdOut.WriteLine("VRDTVS DEBUG: vrdtvs_writeline_for_vpy about to writeline bat_filename_object escaped_vpy_statement=<" & escaped_vpy_statement & ">")
	End If
	bat_filename_object.WriteLine(escaped_vpy_statement)
	vrdtvs_writeline_for_vpy = 0
End Function
