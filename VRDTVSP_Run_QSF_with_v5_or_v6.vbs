Option Explicit
	' cscript //nologo "VRDTVSP_Run_QSF_with_v5_or_v6.vbs" "6" "c:\TEMP\input.ts" "c:\TEMP\output.QSF.MP4" "VRDTVS-for-QSF-H264_VRD6" "c:\TEMP\output_cmd_file.bat" "QSFinfo_" "5000000" "15"
	'                  name-of-script                args: 0   1                  2                        3                           4                             5         6         7
	'
	' cscript //nologo "VRDTVSP_Run_QSF_with_v5_or_v6.vbs" "6" "G:\TEST-vrdtvsp-v40\000-TO-BE-PROCESSED\Motor_Sport-Sport-Motorsport-Formula_One_Grand_Prix-2024-Australia-Day_3.2024-03-24.ts" "G:\TEST-vrdtvsp-v40\000-TO-BE-PROCESSED\Motor_Sport-Sport-Motorsport-Formula_One_Grand_Prix-2024-Australia-Day_3.2024-03-24.QSF.MP4" "VRDTVS-for-QSF-H264_VRD6" "G:\TEST-vrdtvsp-v40\z_temp_qsf_cmdfile.bat" "QSFinfo_" "5000000"
	'
	' VideoReDo VBScript to do QSF with QSF Profile and save an XML data into a file of DOS environment variable SET commands
	' The caller MUST already know the codec used in the input and hence the profile which applies
	' There are 7 mandatory parameters.
	'
	' Args(0) is a number: the version number ot use, "5" or "6"
	' Args(1) is input video file path - a fully qualified path name
	' Args(2) is path/name of output QSF'd file - a fully qualified path name
	' Args(3) is name of QSF Output Profile, already created in VRD v6
	' Args(4) is path/name of a file of a .bat which will contain SET commands for DOS environment variables from QSF XML values - a fully qualified path name
	' Args(5) a prefix eg "QSFinfo_" to be used as the variables prefix for the DOS variables in SET commands
	' Args(6) is a number: the ActualBitrate number, in bps, to use if "//VRDOutputInfo/ActualVideoBitrate" is not returned by VRD, eg 4000000
	' Args(7) is a number: the timeout in minutes before a QSF is deemed taking too long and is terminated, default 240
	'
	'       The .BAT cmd commands file contains data for the most recently completed output file 
	'       (hopefully the QSF) from a call to OutputGetCompletedInfo() or FileGetOpenedFileProgramInfo().
	'       With any luck, the timing of concurrent workflow doing calls works out for us.
	'
	' Example Returned xml string: from VideoReDo.FileGetOpenedFileProgramInfo()
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
' Example Returned xml string: from VideoReDo.OutputGetCompletedInfo()
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

dim vrd_version_for_qsf, input_AbsolutePathName, output_QSF_AbsolutePathName, profile_name_for_qsf, output_cmdfile_AbsolutePathName, qsf_cmd_variable_prefix, default_ActualBitrate_bps
Dim fso, wso, objFolder, fileObj
dim objDict
dim objDict_key
Dim Args, argCount
Dim qsf_timeout_minutes

Set wso = CreateObject("Wscript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")
Set objFolder = Nothing

Set Args = Wscript.Arguments
argCount = Wscript.Arguments.Count
If argCount < 7 Then	' 8 arguments, last is optional and defaults to 240
	Wscript.StdOut.WriteLine("VRDTVSP_Run_QSF_with_v5_or_v6 ERROR: arg count should be 6, but is " & argCount)
	Wscript.StdOut.WriteLine("VRDTVSP_Run_QSF_with_v5_or_v6	Args(0) is a number: the version number ot use, '5' or '6'")
	Wscript.StdOut.WriteLine("VRDTVSP_Run_QSF_with_v5_or_v6	Args(1) is input video file path - a fully qualified path name")
	Wscript.StdOut.WriteLine("VRDTVSP_Run_QSF_with_v5_or_v6	Args(2) is path/name of output QSF'd file - a fully qualified path name")
	Wscript.StdOut.WriteLine("VRDTVSP_Run_QSF_with_v5_or_v6	Args(3) name of QSF Output Profile, already created in VRD v6")
	Wscript.StdOut.WriteLine("VRDTVSP_Run_QSF_with_v5_or_v6	Args(4) is path/name of a file of a .bat which will contain SET commands for DOS environment variables from QSF XML values - a fully qualified path name")
	Wscript.StdOut.WriteLine("VRDTVSP_Run_QSF_with_v5_or_v6	Args(5) a prefix eg ""QSFinfo_"" to be used as the variables prefix for the DOS variables in SET commands")
	Wscript.StdOut.WriteLine("VRDTVSP_Run_QSF_with_v5_or_v6	Args(6) is a number: the ActualBitrate number, in bps, to use if '//VRDOutputInfo/ActualVideoBitrate' is not returned by VRD, eg 4000000")
	Wscript.StdOut.WriteLine("VRDTVSP_Run_QSF_with_v5_or_v6	Args(7) is a number: the timeout in minutes before a QSF is deemed taking too long and is terminated, default 240")
	Wscript.Quit 5
End If

vrd_version_for_qsf =  Args(0)
input_AbsolutePathName =  Args(1)
output_QSF_AbsolutePathName =  Args(2)
profile_name_for_qsf =  Args(3)
output_cmdfile_AbsolutePathName =  Args(4)
qsf_cmd_variable_prefix = Args(5)
default_ActualBitrate_bps =  Args(6)
If argCount >= 8 Then	' Arg 7 is optional (the 8th argument)
	qsf_timeout_minutes = Args(7)
Else
	qsf_timeout_minutes = Null
End If

' Check the argument values, in the order of the commandline parameters

vrd_version_for_qsf = CStr(Trim(vrd_version_for_qsf))
If (not IsNumeric(vrd_version_for_qsf)) or (InStr(1, vrd_version_for_qsf, ".") <> 0) or ((vrd_version_for_qsf <> "5") and (vrd_version_for_qsf <> "6")) Then
	Wscript.StdOut.WriteLine("VRDTVSP_Run_QSF_with_v5_or_v6 ERROR: vrd_version_for_qsf should ONLY be 5 or 6, but is '" & vrd_version_for_qsf & "'")
	Wscript.Quit 5
End If
vrd_version_for_qsf = CLng(vrd_version_for_qsf)

If input_AbsolutePathName = output_QSF_AbsolutePathName Then
	Wscript.StdOut.WriteLine("VRDTVSP_Run_QSF_with_v5_or_v6 ERROR: input_AbsolutePathName '" & input_AbsolutePathName & "' MUST NOT equal output_QSF_AbsolutePathName '" & output_QSF_AbsolutePathName & "'")
	Wscript.Quit 5
End If
If not fso.FileExists(input_AbsolutePathName) Then
	Wscript.StdOut.WriteLine("VRDTVSP_Run_QSF_with_v5_or_v6 ERROR: input_AbsolutePathName '" & input_AbsolutePathName & "' DOES NOT EXIST")
	Wscript.Quit 5
End If

If fso.FileExists(output_QSF_AbsolutePathName) then
	Wscript.StdOut.WriteLine("VRDTVSP_Run_QSF_with_v5_or_v6 WARNING: input_AbsolutePathName '" & output_QSF_AbsolutePathName & "' ALREADY EXISTS, deleting it before continuing with QSF ..." )
	fso.DeleteFile output_QSF_AbsolutePathName
End If

' We check the existence of 'profile_name_for_qsf' in the function 'VRDTVSP_Run_QSF_with_v5_or_v6' rather than here

If fso.FileExists(output_cmdfile_AbsolutePathName) then
	Wscript.StdOut.WriteLine("VRDTVSP_Run_QSF_with_v5_or_v6 WARNING: output_cmdfile_AbsolutePathName '" & output_cmdfile_AbsolutePathName & "' ALREADY EXISTS, deleting it before continuing with QSF ..." )
	fso.DeleteFile output_cmdfile_AbsolutePathName
End If

qsf_cmd_variable_prefix = Trim(qsf_cmd_variable_prefix)
If qsf_cmd_variable_prefix = "" Then
	Wscript.StdOut.WriteLine("VRDTVSP_Run_QSF_with_v5_or_v6 ERROR: qsf_cmd_variable_prefix '" & qsf_cmd_variable_prefix & "' MUST be a string with no spaces or special characters")
	Wscript.Quit 5
End If

default_ActualBitrate_bps = CStr(Trim(default_ActualBitrate_bps))
If (not IsNumeric(default_ActualBitrate_bps)) or (InStr(1, default_ActualBitrate_bps, ".") <> 0) Then
	Wscript.StdOut.WriteLine("VRDTVSP_Run_QSF_with_v5_or_v6 ERROR: default_ActualBitrate_bps should ONLY be an integer, eg 5000000, but is '" & default_ActualBitrate_bps & "'")
	Wscript.Quit 5
End If
default_ActualBitrate_bps = CLng(default_ActualBitrate_bps)

If IsNull(qsf_timeout_minutes) Then
	qsf_timeout_minutes = 240
	Wscript.StdOut.WriteLine("VRDTVSP_Run_QSF_with_v5_or_v6 WARNING: qsf_timeout_minutes (a) DEFAULTED TO '" & qsf_timeout_minutes & "'")
ElseIf IsEmpty(qsf_timeout_minutes) Then
	qsf_timeout_minutes = 240
	Wscript.StdOut.WriteLine("VRDTVSP_Run_QSF_with_v5_or_v6 WARNING: qsf_timeout_minutes (b) DEFAULTED TO '" & qsf_timeout_minutes & "'")
ElseIf qsf_timeout_minutes = "" Then
	qsf_timeout_minutes = 240
	Wscript.StdOut.WriteLine("VRDTVSP_Run_QSF_with_v5_or_v6 WARNING: qsf_timeout_minutes (c) DEFAULTED TO '" & qsf_timeout_minutes & "'")
ElseIf (not IsNumeric(qsf_timeout_minutes)) or (InStr(1, qsf_timeout_minutes, ".") <> 0) Then
	qsf_timeout_minutes = 240
	Wscript.StdOut.WriteLine("VRDTVSP_Run_QSF_with_v5_or_v6 WARNING: qsf_timeout_minutes (d) DEFAULTED TO '" & qsf_timeout_minutes & "'")
Else
	qsf_timeout_minutes = CLng(qsf_timeout_minutes)
End If

' Do the QSF with the function which measures it, provides feedback, and kills it if a timeout occurs
' It returns a vbscript DICT object with filtered values in it
Set objDict = VRDTVSP_Run_QSF_with_v5_or_v6(vrd_version_for_qsf, input_AbsolutePathName, output_QSF_AbsolutePathName, profile_name_for_qsf, default_ActualBitrate_bps, qsf_timeout_minutes)

If objDict is Nothing Then
		Wscript.StdOut.WriteLine("")
		WScript.StdOut.WriteLine("??????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????")
		WScript.StdOut.WriteLine("VRDTVSP_Run_QSF_with_v5_or_v6 ERROR: - Failed to QSF '" & input_AbsolutePathName & "' into '" & output_QSF_AbsolutePathName & "'")
		WScript.StdOut.WriteLine("??????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????")
		Wscript.StdOut.WriteLine("")
		WScript.Quit 17
End If

'create the .BAT cmdfile file from objDict
'Wscript.StdOut.WriteLine("DEBUG: Creating cmdfile '" & output_cmdfile_AbsolutePathName & "'")
Set fileObj = fso.CreateTextFile(output_cmdfile_AbsolutePathName, True, False) ' *** vapoursynth fails with unicode input file *** [ filename, Overwrite[, Unicode]])

fileObj.WriteLine("REM ---")
fileObj.WriteLine("DEL /F "".\tmp_echo_status.log"">NUL 2>&1")
fileObj.WriteLine("@ECHO>"".\tmp_echo_status.log"" 2>&1")
fileObj.WriteLine("set /p initial_echo_status=<"".\tmp_echo_status.log""")
fileObj.WriteLine("DEL /F "".\tmp_echo_status.log"">NUL 2>&1")
fileObj.WriteLine("set ""initial_echo_status=!initial_echo_status:ECHO is =!""")
fileObj.WriteLine("set ""initial_echo_status=!initial_echo_status:.=!""")
fileObj.WriteLine("REM ---")
fileObj.WriteLine("@ECHO OFF")
fileObj.WriteLine("echo qsf_cmd_variable_prefix='" & qsf_cmd_variable_prefix & "'")
fileObj.WriteLine("REM List of DOS SET commands to define DOS variables")
fileObj.WriteLine("REM First, clear the variables with the chosen prefix '" & qsf_cmd_variable_prefix & "'")
fileObj.WriteLine("FOR /F ""tokens=1,* delims=="" %%G IN ('SET " & qsf_cmd_variable_prefix & "') DO (SET ""%%G="")")
For Each objDict_key In objDict
	'WScript.StdOut.WriteLine("DEBUG: " & "SET """ & qsf_cmd_variable_prefix & Trim(objDict_key) & "=" & Trim(objDict.Item(objDict_key)) & """")
	fileObj.WriteLine("SET """ & qsf_cmd_variable_prefix & Trim(objDict_key) & "=" & Trim(objDict.Item(objDict_key)) & """")
Next
fileObj.WriteLine("@ECHO !initial_echo_status!")
fileObj.WriteLine("set ""initial_echo_status=""")
fileObj.WriteLine("goto :eof")
fileObj.close
Set fileObj = Nothing
'Wscript.StdOut.WriteLine("DEBUG: Created cmdfile '" & output_cmdfile_AbsolutePathName & "'")

' Show how to create an XML file of the same thing
'Set fileObj = fso.CreateTextFile(output_XMLfile_AbsolutePathName, True, False) ' *** vapoursynth fails with unicode input file *** [ filename, Overwrite[, Unicode]])
'fileObj.WriteLine("<QSFinfo>")
'fileObj.WriteLine("   <outputFile>""" & actual_outputFile & """</outputFile>")
'fileObj.WriteLine("   <VideoOutputFrameCount>" & actual_VideoOutputFrameCount & "</VideoOutputFrameCount>")
'fileObj.WriteLine("   <Bitrate>" & actual_ActualVideoBitrate & "<Bitrate>")
'fileObj.WriteLine("   <QSFvalues>")
'For Each objDict_key In objDict
'	fileObj.WriteLine("   <""" & objDict_key & """> """ & objDict.Item(objDict_key) & """>")
'Next
'fileObj.WriteLine("   </QSFvalues>")
'fileObj.WriteLine("</QSFinfo>")
'fileObj.close
'Set fileObj = Nothing

' Finish nicely
WScript.Quit


Function VRDTVSP_current_datetime_string()
 Dim dt
    dt = Now
    VRDTVSP_current_datetime_string = FormatDateTime(dt, vbLongDate) & " " & FormatDateTime(dt, vbLongTime)
End Function

Function VRDTVSP_Run_QSF_with_v5_or_v6(	byVAL vrd_version_number, _
										byVAL input_file, _
										byVAL output_QSF_file, _
										byVAL QSF_profile_name, _
										byVAL ActualBitrate, _
										byVAL qsf_timeout_minutes _
										)
	' Parameters: 
	'				vrd_version_number				is the version of vrd to be used , "5" or "6"
	'				input_file						is input video file path - a fully qualified path name, eg a .TS file
	'				output_QSF_file					is path/name of output QSF'd file - a fully qualified path name
	'				QSF_profile_name				is name of a valid  QSF Output Profile created in VRD v6
	'				ActualBitrate					is the ActualBitrate number, in bps, to use if "//VRDOutputInfo/ActualVideoBitrate" is not returned by VRD, eg 4000000
	'
	' Returns:
	'				a dictionary object populated with key/item pairs of data about the resulting QSF file (see xml from VideoReDo.OutputGetCompletedInfo() below ; xml attributes are also added as well as xml items)
	'
	' NOTE:
	' 	Args(4) is not passed here since an XML string is returned to the caller for it to create the XML file
	'

	Const wait_ms = 2000	' in milliseconds, the time to break a line of dots
	'Const giveup_hours = 4	' in hours, the time to let it run before giving up (eg for vrd v6 it can take ages)
	'Const giveup_minutes = 240	' in minutes, the time to let it run before giving up (eg for vrd v6 it can take ages)
	Dim giveup_minutes, one_minute_in_ms
	
	Dim dot_count_linebreak_interval, two_hours_in_ms, one_hour_in_ms, half_hour_in_ms, quarter_hour_in_ms, ten_minutes_in_ms, giveup_interval_count
	Dim xmlDict	' this is a DICTIONARY OBJECT (NOT an XML object) returned with Set VRDTVSP_Run_QSF_with_v5_or_v6 = objDict 
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
	Dim x
	'
	giveup_minutes = qsf_timeout_minutes
	'
	one_minute_in_ms = ROUND(1 * 60 * 1000)
	two_hours_in_ms = CLng( 2 * 60 * 60 * 1000 )
	one_hour_in_ms = ROUND(two_hours_in_ms / 2)
	half_hour_in_ms = ROUND(one_hour_in_ms / 2)
	quarter_hour_in_ms = ROUND(half_hour_in_ms / 2)
	ten_minutes_in_ms = ROUND(two_hours_in_ms / 6)
	dot_count_linebreak_interval = CLng(CLng(120) * CLng(1000) / CLng(wait_ms))		' for 5000 ms, this is 120 seconds worth of intervals
	'giveup_interval_count = CLng( CDbl(giveup_hours) * CDbl(CDbl(CDbl(one_hour_in_ms) / CDbl(wait_ms) )))	' "giveup_hours" worth of intervals, so 4 hours for QSF to finish and before fail with "timeout"
	giveup_interval_count = CLng( CDbl(giveup_minutes) * CDbl(CDbl(CDbl(one_minute_in_ms) / CDbl(wait_ms) )))	' "giveup_minutes" worth of intervals, so 4 hours for QSF to finish and before fail with "timeout"
	'
	input_file = fso.GetAbsolutePathName(input_file)		' was passed byVal
	output_QSF_file = fso.GetAbsolutePathName(output_QSF_file)			' was passed byVal
	'
	WScript.StdOut.WriteLine("======================================================================================================================================================")
	WScript.StdOut.WriteLine("VRDTVSP_Run_QSF_with_v5_or_v6 Commencing: QSF VRD VERSION SPECIFIED: """ & vrd_version_number & """   timeout giveup_minutes=" & giveup_minutes & "   at " &VRDTVSP_current_datetime_string())
	WScript.StdOut.WriteLine("Source file: '" & input_file & "'")
	'
	If vrd_version_number = 5 Then
		Set VideoReDoSilent = WScript.CreateObject("VideoReDo5.VideoReDoSilent")
	ElseIf vrd_version_number = 6 Then
		Set VideoReDoSilent = WScript.CreateObject("VideoReDo6.VideoReDoSilent")
	Else
		WScript.StdOut.WriteLine("VRDTVSP VRDTVSP_Run_QSF_with_v5_or_v6 - Error - VRD version must be 5 or 6, not """ & vrd_version_number & """... Aborting ...")
		WScript.StdOut.WriteLine("Error 17 = cannot perform the requested operation")
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
		If vrd_version_number = 5 Then
			is_QSF = True
		ElseIf vrd_version_number = 6 Then
			is_QSF = NOT VideoReDo.ProfilesGetProfileIsAdScan( i )
		End If
		If ( is_QSF ) Then
			QSF_profile_count = QSF_profile_count + 1
			ReDim Preserve QSF_Profile_Names(QSF_profile_count-1) ' base 0, remember
			QSF_Profile_Names(QSF_profile_count-1) = a_profile_name
		End If
	Next
	If QSF_profile_count < 1 Then
		Wscript.StdOut.WriteLine("VRDTVSP_Run_QSF_with_v5_or_v6: ERROR: no VRD QSF profiles were returned by VRD")
		'on error resume Next
		on error goto 0
		VideoReDo.ProgramExit()
		on error goto 0
		Wscript.StdOut.WriteLine("VRDTVSP_Run_QSF_with_v5_or_v6: Exiting with errorlevel code 5")
		Wscript.Quit 5
	End If
	matching_QSF_profile = False
	For i = 0 to (QSF_profile_count-1)
		If QSF_profile_name = QSF_Profile_Names(i) Then
			matching_QSF_profile = True
			Exit For
		End If
	Next
	If NOT matching_QSF_profile Then
		Wscript.StdOut.WriteLine("VRDTVSP_Run_QSF_with_v5_or_v6: ERROR: no VRD6 QSF profile was located matching your specified profile: """ & QSF_profile_name & """")
		For i = 0 to profile_count-1
			a_profile_name = VideoReDo.ProfilesGetProfileName( i )
			is_QSF = NOT VideoReDo.ProfilesGetProfileIsAdScan( i )
			If ( is_QSF ) Then
				QSF_profile_count = QSF_profile_count + 1
				Wscript.StdOut.WriteLine("VRDTVSP_Run_QSF_with_v5_or_v6F: Profile (" & i & ")=""" & a_profile_name & """ is an QSF profile")
			End If
		Next
		Wscript.StdOut.WriteLine("VRDTVSP_Run_QSF_with_v5_or_v6: QSF Profile count: " & QSF_profile_count )
		Wscript.StdOut.WriteLine("VRDTVSP_Run_QSF_with_v5_or_v6: Exiting with errorlevel code 5")
		'on error resume Next
		on error goto 0
		VideoReDo.ProgramExit()
		on error goto 0
		Wscript.StdOut.WriteLine("VRDTVSP_Run_QSF_with_v5_or_v6: Exiting with errorlevel code 5")
		Wscript.Quit 5
	End If
	' 
	' Open the Input file and QSF SaveAs to the output file
	'
	Err.Clear
	'Wscript.StdOut.WriteLine("VRDTVSP_Run_QSF_with_v5_or_v6: Commencing WITH SPECIFIED VRD VERSION : " & vrd_version_number & " at: " & VRDTVSP_current_datetime_string())
	on error resume next
	openflag = VideoReDo.FileOpen(input_file, True) ' True means QSF mode
	if Err.Number <> 0 Then
		Wscript.StdOut.WriteLine("")
		Wscript.StdOut.WriteLine("VRDTVSP_Run_QSF_with_v5_or_v6: VideoReDo.FileOpen File " & output_QSF_file & " : Error #" & CStr(Err.Number) & " " & Err.Description)
		Wscript.StdOut.WriteLine("VRDTVSP_Run_QSF_with_v5_or_v6: VideoReDo.FileOpen Error #" & CStr(Err.Number) & " " & Err.Description & " at: " & VRDTVSP_current_datetime_string())
		set VRDTVSP_Run_QSF_with_v5_or_v6 = Nothing
		Err.Clear
		openflag  = False
	End If
	on error goto 0
	If openflag = False Then
		Wscript.StdOut.WriteLine("VRDTVSP_Run_QSF_with_v5_or_v6: ERROR: VideoReDo failed to open file: """ & input_file & """")
		'on error goto 0
		on error resume Next
		VideoReDo.ProgramExit()
		' change hard fail to a soft fail so this source file can be ignored and moved and the process continue with the Next source file
		Err.Clear
		on error goto 0
		set VRDTVSP_Run_QSF_with_v5_or_v6 = Nothing
		Exit Function
		'Wscript.StdOut.WriteLine("VRDTVSP_Run_QSF_with_v5_or_v6: Exiting with errorlevel code 5")
		'Wscript.Quit 5
	End If
	on error resume next
	outputOK = VideoReDo.FileSaveAs(output_QSF_file, QSF_profile_name) ' save the QSF file using the specified QSF profile
	If NOT outputOK = True Then
		Wscript.StdOut.WriteLine("VRDTVSP_Run_QSF_with_v5_or_v6: ERROR: VideoReDo failed to create QSF file: """ & output_QSF_file & """ using profile:""" & QSF_profile_name & """")
		on error resume Next
		'on error goto 0
		closeflag = VideoReDo.FileClose()
		Err.Clear
		VideoReDo.ProgramExit()
		Err.Clear
		' change hard fail to a soft fail so this source file can be ignored and moved and the process continue with the Next source file
		on error goto 0
		set VRDTVSP_Run_QSF_with_v5_or_v6 = Nothing
		Exit Function
		'Wscript.StdOut.WriteLine("VRDTVSP_Run_QSF_with_v5_or_v6: Exiting with errorlevel code 5")
		'Wscript.Quit 5
	End If
	Wscript.StdOut.WriteLine("QSF working: ")
	'Wscript.StdOut.Write("VRDTVSP_Run_QSF_with_v5_or_v6 Percent Complete: ")
	i = 0
	OutputGetState = VideoRedo.OutputGetState()
	While( OutputGetState <> 0 )
		i = i + 1
		If ((i MOD dot_count_linebreak_interval) = 0) Then Wscript.StdOut.WriteLine(" " & ((i * wait_ms)/1000) & " Seconds")
		If i > giveup_interval_count Then
			Wscript.StdOut.WriteLine("VRDTVSP_Run_QSF_with_v5_or_v6: ERROR: VideoReDo timeout after " & ((i * wait_ms)/1000) & " seconds waiting for QSF to complete ... Exiting ...")
			'on error resume Next
			on error goto 0
			closeflag = VideoReDo.FileClose()
			VideoReDo.ProgramExit()
			' change hard fail to a soft fail so this source file can be ignored and moved and the process continue with the Next source file
			on error goto 0
			set VRDTVSP_Run_QSF_with_v5_or_v6 = Nothing
			Exit Function
			'Wscript.StdOut.WriteLine("VRDTVSP_Run_QSF_with_v5_or_v6: Exiting with errorlevel code 5")
			'Wscript.Quit 5
		End If
		'on error resume Next
		on error goto 0
		percentComplete = CLng(VideoReDo.OutputGetPercentComplete())
		'if NOT err.number = 0 then
		'	percentComplete = 0
		'End If
		'Wscript.StdOut.Write(" " & percent & "% ")
		Wscript.StdOut.Write( "." & OutputGetState)
		' 2023.12.23 Changed to continue processing if error (new error has started popping up: Error # 462 The remote server machine does not exist or is unavailable)
		Err.Clear
		on error resume Next
		'on error goto 0
		Wscript.Sleep wait_ms
		OutputGetState = VideoRedo.OutputGetState()
		if Err.Number <> 0 Then
			Wscript.StdOut.WriteLine("")
			Wscript.StdOut.WriteLine("VRDTVSP_Run_QSF_with_v5_or_v6: File " & output_QSF_file & " : Error #" & CStr(Err.Number) & " " & Err.Description)
			Wscript.StdOut.WriteLine("VRDTVSP_Run_QSF_with_v5_or_v6: Error #" & CStr(Err.Number) & " " & Err.Description & " at: " & VRDTVSP_current_datetime_string())
			set VRDTVSP_Run_QSF_with_v5_or_v6 = Nothing
			Err.Clear
			on error goto 0
			Exit Function
			'WScript.Quit Err.Number
		End If
	Wend
	Wscript.StdOut.WriteLine( "." & OutputGetState & ".")
	'
	' Grab the *Actual* info about the "VRD latest save" and hope it is the current QSF file)
	'	
	Wscript.StdOut.WriteLine("QSF 100% Completed: " & VRDTVSP_current_datetime_string())
	'Wscript.StdOut.WriteLine("Using VideoReDo.OutputGetCompletedInfo() TRY #1 to Grab the *Actual* info about the 'VRD latest save' and hope it is the current QSF file)")
    Wscript.Sleep 100
	'on error resume Next
	on error goto 0
	xml_string_completedfile = "" 
	xml_string_completedfile = VideoReDo.OutputGetCompletedInfo() ' which is the most recently completed output file (hopefully the QSF file) https://www.videoredo.com/TVSuite_Application_Notes/output_complete_info_xml_forma.html" 
	on error goto 0
	'Wscript.StdOut.WriteLine("DEBUG: QSF xml_string_completedfile='" & xml_string_completedfile & "'")
	if xml_string_completedfile = "" Then	' 2023.12.23 ' re-try to grab xml file Try #2
		'Wscript.StdOut.WriteLine("Using VideoReDo.OutputGetCompletedInfo() TRY #2 to Grab the *Actual* info about the 'VRD latest save' and hope it is the current QSF file)")
	    Wscript.Sleep 100
		'on error resume Next
		on error goto 0
		xml_string_completedfile = "" 
		xml_string_completedfile = VideoReDo.OutputGetCompletedInfo() ' which is the most recently completed output file (hopefully the QSF file) https://www.videoredo.com/TVSuite_Application_Notes/output_complete_info_xml_forma.html" 
		on error goto 0
	End If
	if xml_string_completedfile = "" Then	' 2023.12.23 ' re-try to grab xml file Try #3
		'Wscript.StdOut.WriteLine("Using VideoReDo.OutputGetCompletedInfo() TRY #3 to Grab the *Actual* info about the 'VRD latest save' and hope it is the current QSF file)")
	    Wscript.Sleep 100
		'on error resume Next
		on error goto 0
		xml_string_completedfile = "" 
		xml_string_completedfile = VideoReDo.OutputGetCompletedInfo() ' which is the most recently completed output file (hopefully the QSF file) https://www.videoredo.com/TVSuite_Application_Notes/output_complete_info_xml_forma.html" 
		on error goto 0
	End If
	if xml_string_completedfile = "" Then	' 2023.12.23 ' re-try to grab xml file Try #4
		'Wscript.StdOut.WriteLine("Using VideoReDo.OutputGetCompletedInfo() TRY #4 to Grab the *Actual* info about the 'VRD latest save' and hope it is the current QSF file)")
	    Wscript.Sleep 100
		'on error resume Next
		on error goto 0
		xml_string_completedfile = "" 
		xml_string_completedfile = VideoReDo.OutputGetCompletedInfo() ' which is the most recently completed output file (hopefully the QSF file) https://www.videoredo.com/TVSuite_Application_Notes/output_complete_info_xml_forma.html" 
		on error goto 0
	End If
	if xml_string_completedfile = "" Then	' 2023.12.23 ' re-try to grab xml file Try #5
		'Wscript.StdOut.WriteLine("Using VideoReDo.OutputGetCompletedInfo() TRY #6 to Grab the *Actual* info about the 'VRD latest save' and hope it is the current QSF file)")
	    Wscript.Sleep 100
		'on error resume Next
		on error goto 0
		xml_string_completedfile = "" 
		xml_string_completedfile = VideoReDo.OutputGetCompletedInfo() ' which is the most recently completed output file (hopefully the QSF file) https://www.videoredo.com/TVSuite_Application_Notes/output_complete_info_xml_forma.html" 
		on error goto 0
	End If
	closeflag = VideoReDo.FileClose()
	'on error resume Next
	on error goto 0
	VideoReDo.ProgramExit()
	on error goto 0
	Set VideoReDo = Nothing
 	Set VideoReDoSilent = Nothing
	'
	' Get some of the data obtained during the QSF process and populate a Dict object to return
	'
	Set objDict = CreateObject("Scripting.Dictionary")
	objDict.CompareMode = vbTextCompare ' set case insensitive key lookups. You can set the CompareMode property only when the dictionary is empty.
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
		WScript.StdOut.WriteLine("VRDTVSP_Run_QSF_with_v5_or_v6: ABORTING: Failed to load string from VideoReDo.OutputGetCompletedInfo() xml_string_completedfile=" & xml_string_completedfile)
		WScript.StdOut.WriteLine("VRDTVSP_Run_QSF_with_v5_or_v6: ABORTING: xml_status: " & xml_status & " XML error: " & xml_errorCode & " : " & xml_reason)
		' change hard fail to a soft fail so this source file can be ignored and moved and the process continue with the Next source file
		on error goto 0
		set VRDTVSP_Run_QSF_with_v5_or_v6 = Nothing
		Exit Function
		'WScript.StdOut.WriteLine("Error 17 = cannot perform the requested operation")
		'WScript.Quit 17 ' Error 17 = cannot perform the requested operation
	End If
	'
	' DEBUG:
	'Call VRDTVSP_DumpNodes_from_xml(xmlDoc.childNodes, 0)	' PRINT INTERESTING INFORMATION FORM WITH THE XML DOCUMENT
	'
	objDict.Add "outputFile", gimme_xml_named_attribute(xmlDoc, "//VRDOutputInfo", "outputFile")
	objDict.Add "OutputType", gimme_xml_named_value(xmlDoc, "//VRDOutputInfo/OutputType")
	objDict.Add "OutputDurationSecs", gimme_xml_named_value(xmlDoc, "//VRDOutputInfo/OutputDurationSecs")
	objDict.Add "OutputDuration", gimme_xml_named_value(xmlDoc, "//VRDOutputInfo/OutputDuration")
	objDict.Add "OutputSizeMB", gimme_xml_named_value(xmlDoc, "//VRDOutputInfo/OutputSizeMB")
	objDict.Add "OutputSceneCount", gimme_xml_named_value(xmlDoc, "//VRDOutputInfo/OutputSceneCount")
	objDict.Add "VideoOutputFrameCount", gimme_xml_named_value(xmlDoc, "//VRDOutputInfo/VideoOutputFrameCount")
	objDict.Add "AudioOutputFrameCount", gimme_xml_named_value(xmlDoc, "//VRDOutputInfo/AudioOutputFrameCount")
	' 2023.12.26 Rarely, there is text in the supposedlynueric field "//VRDOutputInfo/ActualVideoBitrate"
	x = gimme_xml_named_value(xmlDoc, "//VRDOutputInfo/ActualVideoBitrate")
	if IsNumeric(x) Then
		objDict.Add "ActualVideoBitrate", CLng(CDbl(x) * CDbl(1000000.0)) ' convert from decimal Mpbs to bps
	else
		objDict.Add "ActualVideoBitrate", default_ActualBitrate_bps	' assume h.264, guess or use bitrate from mediainfo/ffprobe
		'if gimme_xml_named_value(xmlDoc, "//VRDOutputInfo/OutputType") = Ucase("MP4") Then
		'	objDict.Add "ActualVideoBitrate", 4000000	' assume h.264, guess or use bitrate from mediainfo/ffprobe
		'else
		'	objDict.Add "ActualVideoBitrate", 2000000	' assume mpeg2, guess or use bitrate from mediainfo/ffprobe
		'End If
	End If
	If NOT objDict.Exists("outputFile") Then 
		Set xmlDoc = Nothing
		WScript.StdOut.WriteLine("VRDTVSP_Run_QSF_with_v5_or_v6: ABORTING: outputFile string from VideoReDo.OutputGetCompletedInfo() not in Dict, xml_string_completedfile=" & xml_string_completedfile)
		WScript.StdOut.WriteLine("Error 17 = cannot perform the requested operation")
		On Error goto 0
		Set xmlDoc = Nothing
		' change hard fail to a soft fail so this source file can be ignored and moved and the process continue with the Next source file
		on error goto 0
		set VRDTVSP_Run_QSF_with_v5_or_v6 = Nothing
		Exit Function
		'Wscript.StdOut.WriteLine("VRDTVSP_Run_QSF_with_v5_or_v6: Exiting with errorlevel code 17")
		'WScript.Quit 17 ' Error 17 = cannot perform the requested operation
	ElseIf NOT ( Ucase(objDict.Item("outputFile")) =  Ucase(output_QSF_file) ) Then 
		Set xmlDoc = Nothing
		WScript.StdOut.WriteLine("VRDTVSP_Run_QSF_with_v5_or_v6: ABORTING: outputFile from VideoReDo.OutputGetCompletedInfo() not equal QSFfilename: xml_string_completedfile=" & xml_string_completedfile & " output_QSF_file=" & output_QSF_file)
		WScript.StdOut.WriteLine("Error 17 = cannot perform the requested operation")
		On Error goto 0
		Set xmlDoc = Nothing
		' change hard fail to a soft fail so this source file can be ignored and moved and the process continue with the Next source file
		on error goto 0
		set VRDTVSP_Run_QSF_with_v5_or_v6 = Nothing
		Exit Function
		'Wscript.StdOut.WriteLine("VRDTVSP_Run_QSF_with_v5_or_v6: Exiting with errorlevel code 17")
		'WScript.Quit 17 ' Error 17 = cannot perform the requested operation
	End If
	on error goto 0
	Set xmlDoc = Nothing
	WScript.StdOut.WriteLine("END VRDTVSP_Run_QSF_with_v5_or_v6 - QSF VRD VERSION SPECIFIED: """ & vrd_version_number & """")
	WScript.StdOut.WriteLine("" & VRDTVSP_current_datetime_string())
	WScript.StdOut.WriteLine("======================================================================================================================================================")
	Set VRDTVSP_Run_QSF_with_v5_or_v6 = objDict
	' Can use the returned Dict like this:
	'	Dim objDict
	'	Set objDict = CreateObject("Scripting.Dictionary")
	'	objDict.CompareMode = vbTextCompare ' case insensitive key lookups. You can set the CompareMode property only when the dictionary is empty.
	'	objDict.Add key, item
	'	objDict.Remove (key)
	'	objDict.RemoveAll
	'	If objDict.Exists(key) Then temp = objDict.Item(key) Else temp = ""
	'	End If
	'	For Each key In objDict
	'		WScript.StdOut.WriteLine("Dict key=" & key & " value= " & objDict.Item(key))
	'	Next
	'	objDict.Items().Count ' count of items in the dictionary
	'	objDict.Keys().(i)	' the value, say in a for/Next loop, base 0 (0 to Count-1)
	'	objDict.Items().(i)	' the value, say in a for/Next loop, base 0 (0 to Count-1)
	'	objDict.Remove objDict.Keys()(i)
	'	objDict.Key(key) = newkey ' but You can't change a value in a key-value pair.  If you want a different value, you need to delete the item, then add a new one.
End Function

Function gimme_xml_named_value (xmlDoc_object, byVAL xml_item_name) ' assumes the xml doc is already loaded in xmlDoc_object
	'	Parameters:
	'		xmlDoc_object 	the DOM xml object with the xml string already loaded
	'		xml_item_name 	a CASE-SENSITIVE string like //VRDProgramInfo/Video/EstimatedVideoBitrate
	Dim item_nNode, item_text
	Set item_nNode = xmlDoc_object.selectsinglenode(xml_item_name) ' eg '//VRDProgramInfo/Video/EstimatedVideoBitrate' CAREFUL, this is case sensitive
	If item_nNode is Nothing Then
		WScript.StdOut.WriteLine("VRDTVS gimme_xml_named_value ABORTING : Could not find XML node " & xml_item_name & " in xmlDoc_object")
		WScript.StdOut.WriteLine("Error 17 = cannot perform the requested operation")
		Set xmlDoc_object = Nothing
		' change hard fail to a soft fail so this source file can be ignored and moved and the process continue with the Next source file
		on error goto 0
		gimme_xml_named_value = "no xml node to get data from"
		Exit Function
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
		WScript.StdOut.WriteLine("Error 17 = cannot perform the requested operation")
		Set xmlDoc_object = Nothing
		' change hard fail to a soft fail so this source file can be ignored and moved and the process continue with the Next source file
		on error goto 0
		gimme_xml_named_attribute = "no xml node to get data from"
		Exit Function
		'Wscript.StdOut.WriteLine("gimme_xml_named_attribute: Exiting with errorlevel code 17")
		'WScript.Quit 17 ' Error 17 = cannot perform the requested operation exit with an error ... soft or hard ?
	End If
	item_text = item_nNode.text ' eg the text for that item //VideoReDoProject/EncodingDimensions
	gimme_xml_named_attribute = item_nNode.getAttribute(xml_item_attribute_name)
End Function

Sub VRDTVSP_DumpNodes_from_xml(dnfx_Nodes, dnfx_Indent_Size)
	'	Dump useful information from the xmlDoc object which contains XML data
	'	Called like:
	'		Call VRDTVSP_DumpNodes_from_xml(xmlDoc.childNodes, 0)
	Dim dnfx_xNode
	For Each dnfx_xNode In dnfx_Nodes
		Select Case dnfx_xNode.nodeType ' 1=NODE ELEMENT, 3=NODE VALUE
			Case 1:   ' NODE_ELEMENT
				If dnfx_xNode.nodeName <> "#document" Then ' looks like a hack for the top level
					' change "VRDTVSP_DisplayAttributes_from_xml_node(dnfx_xNode, dnfx_Indent_Size + 2)" to "VRDTVSP_DisplayAttributes_from_xml_node(dnfx_xNode, 0)" to see inline attributes rather than indented
					WScript.StdOut.WriteLine("DEBUG: " & String(dnfx_Indent_Size," ") & "<" & dnfx_xNode.nodeName & VRDTVSP_DisplayAttributes_from_xml_node(dnfx_xNode, dnfx_Indent_Size + 2) & ">") ' this is the nodename and note attributes THE START OF THE NODE
					If dnfx_xNode.hasChildNodes Then
						'Call DisplayNode_from_xml(dnfx_xNode.childNodes, dnfx_Indent_Size + 2)	' THIS IS THE CHILD NODES OF THE CURRENT NODE
						Call VRDTVSP_DumpNodes_from_xml(dnfx_xNode.childNodes, dnfx_Indent_Size + 2)	' THIS IS THE CHILD NODES OF THE CURRENT NODE
					End If
					WScript.StdOut.WriteLine("DEBUG: " & String(dnfx_Indent_Size," ") & "</" & dnfx_xNode.nodeName & ">")	' THIS IS THE END OF THE NODE 
				Else 'NODENAME =  "#document" 		' looks like a hack for the top level
					If dnfx_xNode.hasChildNodes Then
						'Call DisplayNode_from_xml(dnfx_xNode.childNodes, dnfx_Indent_Size + 2)
						Call VRDTVSP_DumpNodes_from_xml(dnfx_xNode.childNodes, dnfx_Indent_Size + 2)
					End If
				End If
			Case 3:   ' value                       
				WScript.StdOut.WriteLine("DEBUG: " & String(dnfx_Indent_Size," ") & "" & dnfx_xNode.nodeValue) ' this is the value of the node ' <-- THIS IS THE VALUE
		End Select
	Next
End Sub

Function VRDTVSP_DisplayAttributes_from_xml_node(dafxn_Node, dafxn_Indent_Size)
	Dim dafxn_xAttr, dafxn_res
	dafxn_res = ""
	For Each dafxn_xAttr In dafxn_Node.attributes
		If dafxn_Indent_Size = 0 Then
			dafxn_res = dafxn_res & " " & dafxn_xAttr.name & "=""" & dafxn_xAttr.value & """"
		Else 
			dafxn_res = dafxn_res & vbCrLf & String(dafxn_Indent_Size," ") & "" & dafxn_xAttr.name & """" & dafxn_xAttr.value & """"
		End If
	Next
	VRDTVSP_DisplayAttributes_from_xml_node = dafxn_res
End Function
