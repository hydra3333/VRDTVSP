Option Explicit
' File: ".\z_created_qsf_script_for_v6.vbs"
' Example VRD VBScript to do QSF with QSF Profile and save an XML file of characteristics
' Args(0) is input video file path - a fully qualified path name
' Args(1) is path/name of output QSF'd file - a fully qualified path name
' Args(2) is name of QSF Output Profile created in VRD v6
' Args(3) is path/name of a file of XML associated with the output QSF'd file - a fully qualified path name
' Note: An additional file is created, with the same full filename/ext as Args(1) with .xml added on the end.
'       This .xml file contains complete info for the most recently completed output file 
'       (hopefully the QSF) from a call to OutputGetCompletedInfo() or FileGetOpenedFileProgramInfo().
'       With any luck, the timing of concurrent workflow doing calls works out for us, although we should still check the filename from the XML.
'
' Example Returned xml string: from VideoReDo.FileGetOpenedFileProgramInfo()
' This is a well-formed single-item XML string, which make it really easy to find things
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
' This is a well-formed single-item XML string, which make it really easy to find things
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
Dim Args, argCount
Dim inputFile
Dim qsfFile
Dim QSF_profile_name
Dim xmlFile
Dim VideoReDoSilent
Dim VideoReDo
Dim openflag, closeflag, outputOK, OutputGetState, percentComplete
Dim percent
Dim i, profile_count, QSF_profile_count, matching_QSF_profile, a_profile_name, is_QSF
Dim QSF_Profile_Names()
Dim xml_string, xml_string_openedfile, xml_string_completedfile
Dim xmlDoc,	xml_status, xml_objErr, xml_errorCode, xml_reason
Dim actual_outputFile, actual_VideoOutputFrameCount, actual_ActualVideoBitrate
Dim estimated_outputFile, estimated_VideoOutputFrameCount, estimated_ActualVideoBitrate
Dim fso, fileObj
'
Set Args = Wscript.Arguments
argCount = Wscript.Arguments.Count
If argCount <> 4 Then
	Wscript.StdOut.WriteLine("VRDTVSP_VRD_QSF: ERROR: arg count should be 3, but is " & argCount)
	Wscript.StdOut.WriteLine("VRDTVSP_VRD_QSF:			Args(0) is the fully qualified path/name of the input video file")
	Wscript.StdOut.WriteLine("VRDTVSP_VRD_QSF:			Args(1) is the fully qualified path/name of the output project (.vprj) file.")
	Wscript.StdOut.WriteLine("VRDTVSP_VRD_QSF:			Args(2) is name of QSF Output Profile already created and saved inside VRD v6")
	Wscript.StdOut.WriteLine("VRDTVSP_VRD_QSF:			Args(3) ist he fully qualified path/name of an output XML file of QSF file characteristics.")
	Wscript.Quit 5
End If
'
inputFile = Args(0)
qsfFile = Args(1)				' including extension .vprj
QSF_profile_name = Args(2)
xmlFile = Args(3)				' including extension .xml
'
Set VideoReDoSilent = WScript.CreateObject("VideoReDo6.VideoReDoSilent")
Set VideoReDo = VideoReDoSilent.VRDInterface
VideoReDo.ProgramSetAudioAlert(False)
'
QSF_profile_count = 0
profile_count = VideoReDo.ProfilesGetCount()
For i = 0 to profile_count-1
	a_profile_name = VideoReDo.ProfilesGetProfileName( i )
	is_QSF = NOT VideoReDo.ProfilesGetProfileIsAdScan( i )
	If ( is_QSF ) Then
		QSF_profile_count = QSF_profile_count + 1
		ReDim Preserve QSF_Profile_Names(QSF_profile_count-1) ' base 0, remember
		QSF_Profile_Names(QSF_profile_count-1) = a_profile_name
	End If
Next
If QSF_profile_count < 1 Then
	Wscript.StdOut.WriteLine("VRDTVSP_VRD_QSF: ERROR: no VRD QSF profiles were returned by VRD")
	Wscript.StdOut.WriteLine("VRDTVSP_VRD_QSF: Exiting with errorlevel code 5")
	'on error resume Next
	on error goto 0
	VideoReDo.ProgramExit()
	on error goto 0
	Wscript.StdOut.WriteLine("VRDTVSP_VRD_QSF: Exiting with errorlevel code 5")
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
	Wscript.StdOut.WriteLine("VRDTVSP_VRD_QSF: ERROR: no VRD QSF profile was located matching your specified profile: """ & QSF_profile_name & """")
	For i = 0 to profile_count-1
		a_profile_name = VideoReDo.ProfilesGetProfileName( i )
		is_QSF = NOT VideoReDo.ProfilesGetProfileIsAdScan( i )
		If ( is_QSF ) Then
			QSF_profile_count = QSF_profile_count + 1
			Wscript.StdOut.WriteLine("VRDTVSP_VRD_QSF: Profile (" & i & ")=""" & a_profile_name & """ is an QSF profile")
		End If
	Next
	Wscript.StdOut.WriteLine("VRDTVSP_VRD_QSF: QSF Profile count: " & QSF_profile_count )
	Wscript.StdOut.WriteLine("VRDTVSP_VRD_QSF: Exiting with errorlevel code 5")
	'on error resume Next
	on error goto 0
	VideoReDo.ProgramExit()
	on error goto 0
	Wscript.StdOut.WriteLine("VRDTVSP_VRD_QSF: Exiting with errorlevel code 5")
	Wscript.Quit 5
End If
'
openflag = VideoReDo.FileOpen(inputFile, True) ' True means QSF mode
If openflag = False Then
	Wscript.StdOut.WriteLine("VRDTVSP_VRD_QSF: ERROR: VideoReDo failed to open file: """ & inputFile & """")
	'on error resume Next
	on error goto 0
	VideoReDo.ProgramExit()
	on error goto 0
	Wscript.StdOut.WriteLine("VRDTVSP_VRD_QSF: Exiting with errorlevel code 5")
	Wscript.Quit 5
End If
outputOK = VideoReDo.FileSaveAs(qsfFile, QSF_profile_name) ' save the QSF file
If NOT outputOK = True Then
	Wscript.StdOut.WriteLine("VRDTVSP_VRD_QSF: ERROR: VideoReDo failed to create QSF file: """ & qsfFile & """ using profile:""" & QSF_profile_name & """")
	'on error resume Next
	on error goto 0
	closeflag = VideoReDo.FileClose()
	VideoReDo.ProgramExit()
	on error goto 0
	Wscript.StdOut.WriteLine("VRDTVSP_VRD_QSF: Exiting with errorlevel code 5")
	Wscript.Quit 5
End If
Wscript.StdOut.Write("VRDTVSP_VRD_QSF: working: ")
'Wscript.StdOut.Write("VRDTVSP_VRD_QSF: Percent Complete: ")
OutputGetState = VideoRedo.OutputGetState()
While( OutputGetState <> 0 )
	'on error resume Next
	on error goto 0
		percentComplete = CLng(VideoReDo.OutputGetPercentComplete())
	'if NOT err.number = 0 then
	'	percentComplete = 0
	'end if
	'Wscript.StdOut.Write(" " & percent & "% ")
	Wscript.StdOut.Write( "." & OutputGetState)
	on error goto 0
	Wscript.Sleep 2000
	OutputGetState = VideoRedo.OutputGetState()
Wend
Wscript.StdOut.WriteLine( "." & OutputGetState & ".")
Wscript.StdOut.WriteLine("VRDTVSP_VRD_QSF: QSF 100% Complete.")
' Grab the *Actual* info about the "VRD latest save" and hope it is the QSF file)
'on error resume Next
on error goto 0
xml_string_completedfile = "" 
xml_string_completedfile = VideoReDo.OutputGetCompletedInfo() ' which is the most recently completed output file (hopefully the QSF file) https://www.videoredo.com/TVSuite_Application_Notes/output_complete_info_xml_forma.html" 
on error goto 0
closeflag = VideoReDo.FileClose()
Wscript.StdOut.WriteLine(" QSF 100% Complete.")
' Grab the *Estimated* info about the QSF file by a quick open and close
'on error resume Next
on error goto 0
openflag = VideoReDo.FileOpen(qsfFile, False)' True means QSF mode
xml_string_openedfile = "" 
xml_string_openedfile = VideoReDo.FileGetOpenedFileProgramInfo() ' https://www.videoredo.com/TVSuite_Application_Notes/program_info_xml_format.html
closeflag = VideoReDo.FileClose()
on error goto 0
'
Wscript.StdOut.WriteLine("VRDTVSP_VRD_QSF: xml_string_completedfile=") 
Wscript.StdOut.WriteLine(xml_string_completedfile) 
Wscript.StdOut.WriteLine("VRDTVSP_VRD_QSF: xml_string_openedfile=") 
Wscript.StdOut.WriteLine(xml_string_openedfile) 
'
''''' Get Actual data obtained during the QSF process
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
	WScript.StdOut.WriteLine("VRDTVSP_VRD_QSF: ABORTING: Failed to load xml_string_completedfile=" & xml_string_completedfile)
	WScript.StdOut.WriteLine("VRDTVSP_VRD_QSF: ABORTING: xml_status: " & xml_status & " XML error: " & xml_errorCode & " : " & xml_reason)
	Wscript.Echo "Error 17 = cannot perform the requested operation"
	On Error goto 0
	WScript.Quit 17 ' Error 17 = cannot perform the requested operation
End If
actual_outputFile = gimme_xml_named_attribute(xmlDoc, "//VRDOutputInfo", "outputFile")
actual_VideoOutputFrameCount = gimme_xml_named_value(xmlDoc, "//VRDOutputInfo/VideoOutputFrameCount")
actual_ActualVideoBitrate = gimme_xml_named_value(xmlDoc, "//VRDOutputInfo/ActualVideoBitrate") ' decimal number in Mbps
If actual_ActualVideoBitrate = "" Then actual_ActualVideoBitrate = 0
actual_ActualVideoBitrate = CLng(CDbl(actual_ActualVideoBitrate) * CDbl(1000000.0)) ' convert from dedcimal Mpbs to bps
Set xmlDoc = Nothing
'
''''' Get Estimated data from a quick open and close of the the QSF file
Set xmlDoc = WScript.CreateObject("Msxml2.DOMDocument.6.0")
xmlDoc.async = False
'on error resume Next
on error goto 0
xml_status = xmlDoc.loadXML(xml_string_openedfile) 
Set xml_objErr = xmlDoc.parseError
xml_errorCode = xml_objErr.errorCode
xml_reason = xml_objErr.reason
Set xml_objErr = Nothing
Err.clear
on error goto 0 
If NOT xml_status Then
	Set xmlDoc = Nothing
	WScript.StdOut.WriteLine("VRDTVSP_VRD_QSF: ABORTING: Failed to load xml_string_openedfile=" & xml_string_openedfile)
	WScript.StdOut.WriteLine("VRDTVSP_VRD_QSF: ABORTING: xml_status: " & xml_status & " XML error: " & xml_errorCode & " : " & xml_reason)
	Wscript.Echo "Error 17 = cannot perform the requested operation"
	On Error goto 0
	WScript.Quit 17 ' Error 17 = cannot perform the requested operation
End If
estimated_outputFile = gimme_xml_named_value(xmlDoc, "//VRDProgramInfo/FileName")
estimated_VideoOutputFrameCount = gimme_xml_named_attribute(xmlDoc, "//VRDProgramInfo/ProgramDuration", "total_frames")
estimated_ActualVideoBitrate = gimme_xml_named_value(xmlDoc, "//VRDProgramInfo/Video/EstimatedVideoBitrate") ' decimal number in Mbps
Set xmlDoc = Nothing
'
' Write our own version of the XML values to the specified XML file so that the calling script can read them later
Set fso = CreateObject("Scripting.FileSystemObject")
Set fileObj = fso.CreateTextFile(xmlFile, True, False) ' *** vapoursynth fails with unicode input file *** [ filename, Overwrite[, Unicode]])
If Ucase(actual_outputFile) = Ucase(qsfFile) Then ' Use the Actual QSF values
	fileObj.WriteLine("<QSFinfo>")
	fileObj.WriteLine("   <type>actual</actual_type>")
	fileObj.WriteLine("   <outputFile>""" & actual_outputFile & """</outputFile>")
	fileObj.WriteLine("   <VideoOutputFrameCount>" & actual_VideoOutputFrameCount & "</VideoOutputFrameCount>")
	fileObj.WriteLine("   <Bitrate>" & actual_ActualVideoBitrate & "<Bitrate>")
	fileObj.WriteLine("</QSFinfo>")
Else ' Use the Estimated QSF values
	fileObj.WriteLine("   <QSFinfo>")
	fileObj.WriteLine("   <type>estimated</type>")
	fileObj.WriteLine("   <outputFile>""" & estimated_outputFile & """</outputFile>")
	fileObj.WriteLine("   <VideoOutputFrameCount>" & estimated_VideoOutputFrameCount & "</VideoOutputFrameCount>")
	fileObj.WriteLine("   <Bitrate>" & estimated_ActualVideoBitrate & "<Bitrate>")
	fileObj.WriteLine("</QSFinfo>")
End If
fileObj.close
Set fileObj = Nothing
Set fso = Nothing
'
Wscript.StdOut.WriteLine("VRDTVSP_VRD_QSF: actual_outputFile=""" & actual_outputFile & """") 
Wscript.StdOut.WriteLine("VRDTVSP_VRD_QSF: actual_VideoOutputFrameCount=" & actual_VideoOutputFrameCount) 
Wscript.StdOut.WriteLine("VRDTVSP_VRD_QSF: actual_ActualVideoBitrate=" & actual_ActualVideoBitrate) 
Wscript.StdOut.WriteLine("VRDTVSP_VRD_QSF: estimated_outputFile=""" & estimated_outputFile & """") 
Wscript.StdOut.WriteLine("VRDTVSP_VRD_QSF: estimated_VideoOutputFrameCount=" & estimated_VideoOutputFrameCount) 
Wscript.StdOut.WriteLine("VRDTVSP_VRD_QSF: estimated_ActualVideoBitrate=" & estimated_ActualVideoBitrate) 
'
Wscript.StdOut.WriteLine("VRDTVSP_VRD_QSF: Exiting")
'on error resume Next
on error goto 0
VideoReDo.ProgramExit()
on error goto 0
Wscript.Quit 0
Function gimme_xml_named_value (xmlDoc_object, byVAL xml_item_name) ' assumes the xml doc is already loaded in xmlDoc_object
	'	Parameters:
	'		xmlDoc_object 	the DOM xml object with the xml string already loaded
	'		xml_item_name 	a string like //VRDProgramInfo/Video/EstimatedVideoBitrate
	Dim item_nNode, item_text
	Set item_nNode = xmlDoc_object.selectsinglenode(xml_item_name) ' eg '//VRDProgramInfo/Video/EstimatedVideoBitrate' CAREFUL, this is case sensitive
	If item_nNode is Nothing Then
		WScript.StdOut.WriteLine("ABORTING: Could not find XML node " & xml_item_name & " in xmlDoc_object")
		Wscript.Echo "Error 17 = cannot perform the requested operation"
		Set xmlDoc_object = Nothing
		On Error goto 0
		WScript.Quit 17 ' Error 17 = cannot perform the requested operation exit with an error ... soft or hard ?
	End If
	gimme_xml_named_value = item_nNode.text ' eg the text for that item //VideoReDoProject/EstimatedVideoBitrate
End Function
Function gimme_xml_named_attribute (xmlDoc_object, byVAL xml_item_name, byVAL xml_item_attribute_name)
	'	Parameters:
	'		xmlDoc_object 	the DOM xml object with the xml string already loaded
	'		xml_item_name 	a string like //VideoReDoProject/EncodingDimensions
	Dim item_nNode, item_text
	Set item_nNode = xmlDoc_object.selectsinglenode(xml_item_name) ' eg '//VideoReDoProject/EncodingDimensions' CAREFUL, this is case sensitive
	If item_nNode is Nothing Then
		WScript.StdOut.WriteLine("ABORTING: Could not find XML node " & xml_item_name & " in xmlDoc_object")
		Wscript.Echo "Error 17 = cannot perform the requested operation"
		Set xmlDoc_object = Nothing
		On Error goto 0
		WScript.Quit 17 ' Error 17 = cannot perform the requested operation exit with an error ... soft or hard ?
	End If
	item_text = item_nNode.text ' eg the text for that item //VideoReDoProject/EncodingDimensions
	gimme_xml_named_attribute = item_nNode.getAttribute(xml_item_attribute_name)
End Function
