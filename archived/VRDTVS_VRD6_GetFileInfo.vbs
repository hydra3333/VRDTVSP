Option Explicit
' File: ""
' Example VRD6 VBScript to retrieve video attribute values fom a file, eg a resulting QSF'd file.
' Args(0) is input video file path
'
Dim Args, argCount
Dim inputFile
Dim VideoReDoSilent
Dim VideoReDo
Dim openflag, closeflag
Dim xml_string
'
Set Args = Wscript.Arguments
argCount = Wscript.Arguments.Count
If argCount <> 1 Then
	Wscript.StdOut.WriteLine("VRDTVS_VRD6_GetFileInfo: ERROR: arg count should be 1, but is " & argCount)
	Wscript.Quit 5
End If
'
inputFile = Args(0)
'
Set VideoReDoSilent = WScript.CreateObject("VideoReDo6.VideoReDoSilent")
Set VideoReDo = VideoReDoSilent.VRDInterface
VideoReDo.ProgramSetAudioAlert(False)
'
openflag = VideoReDo.FileOpen(inputFile, False)
If openflag = False Then
	Wscript.StdOut.WriteLine("VRDTVS_VRD6_GetFileInfo: ERROR: VideoReDo failed to open file: """ & inputFile & """")
	on error resume next
	closeflag = VideoReDo.FileClose()
	VideoReDo.ProgramExit()
	on error goto 0
	Wscript.StdOut.WriteLine("VRDTVS_VRD6_GetFileInfo: Exiting with errorlevel code 5")
	Wscript.Quit 5
End If
xml_string = VideoReDo.FileGetOpenedFileProgramInfo() ' https://www.videoredo.com/TVSuite_Application_Notes/program_info_xml_format.html
closeflag = VideoReDo.FileClose()

Wscript.StdOut.WriteLine(" ")
Wscript.StdOut.WriteLine(xml_string)
Wscript.StdOut.WriteLine(" ")

Wscript.StdOut.WriteLine(" ")
Call Show_two_items(xml_string)
Wscript.StdOut.WriteLine(" ")

Wscript.StdOut.WriteLine("VRDTVS_VRD6_GetFileInfo: Exiting")
on error resume next
VideoReDo.ProgramExit()
on error goto 0
Wscript.Quit 0

Sub Show_two_items(ByVal xml_string)
Dim xmlDoc, xml_status, xml_objErr, xml_errorCode, xml_reason, item_text, item_nNode
'NOTIONALLY, Handy values in xml_string = FileGetOpenedFileProgramInfo()
' Encoding				The encoding type of the file. Possible values are MPEG1 or MPEG2
' EncodingDimensions	Top level node containing two sub nodes Horizontal and Vertical which contain the video dimensions in pixels
' DisplayDimensions		Top level node containing two sub nodes Horizontal and Vertical which contain the video display dimensions in pixels
' AspectRatio			The aspect ratio of the video expressed as H:V. (i.e. 4:3, 16:9, etc...)
' Framerate				The frame rate of the video multiplied by 1000. (i.e. 29.97 = 29970)
' Bitrate				The bit rate of the video in bits per second
' Progressive			If True then video is progressive only, if False then video is prog or int
' Chroma				The chroma value of the video. Possible values are... 4:2:0, 4:2:2. 4:4:4 or Unknown.
' AudioCodec			Audio codec type: LPCM, MPEG (for MPEG1 Layer 2), AC3, AAC, AAC-HE, SMPTE-302M
' AudioBitrate			The bit rate of the audio stream in bits per second
' AudioSampleRate		The audio sampling rate in Hz
'
' An ACTUAL returned xml string:
' This is a well-formed single-item XML string,
' which make it really easy to find things
'<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
'<VRDProgramInfo>
'<FileName d="Name">somefilename.qsf.vrd6.mp4</FileName>
'<FileSize f="0.029 GB" d="Size">28519136</FileSize>
'<ProgramDuration f="00:01:04.84" d="Duration" total_frames="1622">5835601</ProgramDuration>
'<FileType d="Mux type">MP4</FileType>
'<Video>
' <Encoding>H.264</Encoding>
' <VideoStreamID>x201</VideoStreamID>
' <FrameRate f="25.00 fps" d="Frame rate">25.000000</FrameRate>
' <constant_frame_rate_flag d="Frame rate flag">Constant</constant_frame_rate_flag>
' <EncodingDimensions d="Encoding size" width="1920" height="1080">1920 x 1080</EncodingDimensions>
' <AspectRatio d="Aspect ratio">16:9</AspectRatio>
' <HeaderBitRate f="25.000 Mbps" d="Header bit rate">25000000</HeaderBitRate>
' <VBVBufferSize f="572 KBytes" d="VBV buffer">572</VBVBufferSize>
' <Profile>High/4.0</Profile>
' <Progressive f="Interlaced">False</Progressive>
' <Chroma chroma_value="1">4:2:0</Chroma>
' <EntropyCodingMode d="Entropy mode">CABAC</EntropyCodingMode>
' <EstimatedVideoBitrate f="2.992 Mbps" d="Bit rate">2992213</EstimatedVideoBitrate>
'</Video>
'<AudioStreams>
' <AudioStream StreamNumber="1" Primary="true">
' <AudioCodec d="Codec">AC3</AudioCodec>
' <Format>AC3 stream</Format>
' <AudioChannels d="Channels">5.1</AudioChannels>
' <Language>eng</Language>
' <PID>x202</PID>
' <PESStreamId d="PES Stream Id">xBD</PESStreamId>
' <AudioBitRate f="448 Kbps" d="Bit rate">448000</AudioBitRate>
' <AudioSampleRate d="Sampling rate">48000</AudioSampleRate>
' <BitsPerSample d="Sample size" f="16 bits">16</BitsPerSample>
' </AudioStream>
'</AudioStreams>
'<SubtitleStreams/>
'</VRDProgramInfo>
'xml_string = ""
'xml_string = xml_string & "<?xml version=""1.0"" encoding=""UTF-8"" standalone=""yes""?>"
'xml_string = xml_string & "<VRDProgramInfo>"
'xml_string = xml_string & "<FileName d=""Name"">somefilename.qsf.vrd6.mp4</FileName>"
'xml_string = xml_string & "<FileSize f=""0.029 GB"" d=""Size"">28519136</FileSize>"
'xml_string = xml_string & "<ProgramDuration f=""00:01:04.84"" d=""Duration"" total_frames=""1622"">5835601</ProgramDuration>"
'xml_string = xml_string & "<FileType d=""Mux type"">MP4</FileType>"
'xml_string = xml_string & "<Video>"
' xml_string = xml_string & "<Encoding>H.264</Encoding>"
' xml_string = xml_string & "<VideoStreamID>x201</VideoStreamID>"
' xml_string = xml_string & "<FrameRate f=""25.00 fps"" d=""Frame rate"">25.000000</FrameRate>"
' xml_string = xml_string & "<constant_frame_rate_flag d=""Frame rate flag"">Constant</constant_frame_rate_flag>"
' xml_string = xml_string & "<EncodingDimensions d=""Encoding size"" width=""1920"" height=""1080"">1920 x 1080</EncodingDimensions>"
' xml_string = xml_string & "<AspectRatio d=""Aspect ratio"">16:9</AspectRatio>"
' xml_string = xml_string & "<HeaderBitRate f=""25.000 Mbps"" d=""Header bit rate"">25000000</HeaderBitRate>"
' xml_string = xml_string & "<VBVBufferSize f=""572 KBytes"" d=""VBV buffer"">572</VBVBufferSize>"
' xml_string = xml_string & "<Profile>High/4.0</Profile>"
' xml_string = xml_string & "<Progressive f=""Interlaced"">False</Progressive>"
' xml_string = xml_string & "<Chroma chroma_value=""1"">4:2:0</Chroma>"
' xml_string = xml_string & "<EntropyCodingMode d=""Entropy mode"">CABAC</EntropyCodingMode>"
' xml_string = xml_string & "<EstimatedVideoBitrate f=""2.992 Mbps"" d=""Bit rate"">2992213</EstimatedVideoBitrate>"
'xml_string = xml_string & "</Video>"
'xml_string = xml_string & "<AudioStreams>"
' xml_string = xml_string & "<AudioStream StreamNumber=""1"" Primary=""true"">"
' xml_string = xml_string & "<AudioCodec d=""Codec"">AC3</AudioCodec>"
' xml_string = xml_string & "<Format>AC3 stream</Format>"
' xml_string = xml_string & "<AudioChannels d=""Channels"">5.1</AudioChannels>"
' xml_string = xml_string & "<Language>eng</Language>"
' xml_string = xml_string & "<PID>x202</PID>"
' xml_string = xml_string & "<PESStreamId d=""PES Stream Id"">xBD</PESStreamId>"
' xml_string = xml_string & "<AudioBitRate f=""448 Kbps"" d=""Bit rate"">448000</AudioBitRate>"
' xml_string = xml_string & "<AudioSampleRate d=""Sampling rate"">48000</AudioSampleRate>"
' xml_string = xml_string & "<BitsPerSample d=""Sample size"" f=""16 bits"">16</BitsPerSample>"
' xml_string = xml_string & "</AudioStream>"
'xml_string = xml_string & "</AudioStreams>"
'xml_string = xml_string & "<SubtitleStreams/>"
'xml_string = xml_string & "</VRDProgramInfo>"
'
		Set xmlDoc = WScript.CreateObject("Msxml2.DOMDocument.6.0")
		xmlDoc.async = False
		on error resume next 
		xml_status = xmlDoc.loadXML(xml_string) 
		Set xml_objErr = xmlDoc.parseError
		xml_errorCode = xml_objErr.errorCode
		xml_reason = xml_objErr.reason
		Set xml_objErr = Nothing
		Err.clear
		on error goto 0 
		If NOT xml_status Then
			WScript.StdOut.WriteLine("ABORTING: Failed to load XML string """ & xml_string & """")
			WScript.StdOut.WriteLine("ABORTING: xml_status: " & xml_status & " XML error: " & xml_errorCode & " : " & xml_reason)
			Wscript.Echo "Error 17 = cannot perform the requested operation"
			On Error goto 0
			WScript.Quit 17 ' Error 17 = cannot perform the requested operation
		End If
'
		'Call DisplayNode_from_xml(xmlDoc.childNodes, 0)
'
		'Locate the desired node. Note the use of XPATH instead of looping over all the child nodes.
		Set item_nNode = xmlDoc.selectsinglenode ("//VRDProgramInfo/FileName") ' CAREFUL, this is case sensitive
		If item_nNode is Nothing Then
			WScript.StdOut.WriteLine("ABORTING: Could not find XML node //VRDProgramInfo/FileName in xml_string " & xml_string)
			Wscript.Echo "Error 17 = cannot perform the requested operation"
			On Error goto 0
			WScript.Quit 17 ' Error 17 = cannot perform the requested operation exit with an error ... soft or hard ?
		End If
		item_text = item_nNode.text ' this is the text for that item //VRDProgramInfo/FileName
		WScript.StdOut.WriteLine("Item " & "//VRDProgramInfo/FileName" & "=" & item_text)
'		
		'Locate the desired node. Note the use of XPATH instead of looping over all the child nodes.
		Set item_nNode = xmlDoc.selectsinglenode ("//VRDProgramInfo/Video/EstimatedVideoBitrate") ' CAREFUL, this is case sensitive
		If item_nNode is Nothing Then
			WScript.StdOut.WriteLine("ABORTING: Could not find XML node //VRDProgramInfo/Video/EstimatedVideoBitrate in xml_string " & xml_string)
			Wscript.Echo "Error 17 = cannot perform the requested operation"
			On Error goto 0
			WScript.Quit 17 ' Error 17 = cannot perform the requested operation exit with an error ... soft or hard ?
		End If
		item_text = item_nNode.text ' this is the text for that item //VideoReDoProject/EstimatedVideoBitrate
		WScript.StdOut.WriteLine("Item " & "//VRDProgramInfo/EstimatedVideoBitrate" & "=" & item_text)
'
		'Locate the desired node. Note the use of XPATH instead of looping over all the child nodes.
		Set item_nNode = xmlDoc.selectsinglenode ("//VRDProgramInfo/Video/Progressive") ' CAREFUL, this is case sensitive
		If item_nNode is Nothing Then
			WScript.StdOut.WriteLine("ABORTING: Could not find XML node //VRDProgramInfo/Video/Progressive in xml_string " & xml_string)
			Wscript.Echo "Error 17 = cannot perform the requested operation"
			On Error goto 0
			WScript.Quit 17 ' Error 17 = cannot perform the requested operation exit with an error ... soft or hard ?
		End If
		item_text = item_nNode.text ' this is the text for that item //VideoReDoProject/Progressive
		WScript.StdOut.WriteLine("Item " & "//VRDProgramInfo/Progressive" & "=" & item_text)
'
		'Locate the desired node. Note the use of XPATH instead of looping over all the child nodes.
		Set item_nNode = xmlDoc.selectsinglenode ("//VRDProgramInfo/Video/FrameRate") ' CAREFUL, this is case sensitive
		If item_nNode is Nothing Then
			WScript.StdOut.WriteLine("ABORTING: Could not find XML node //VRDProgramInfo/Video/FrameRate in xml_string " & xml_string)
			Wscript.Echo "Error 17 = cannot perform the requested operation"
			On Error goto 0
			WScript.Quit 17 ' Error 17 = cannot perform the requested operation exit with an error ... soft or hard ?
		End If
		item_text = item_nNode.text ' this is the text for that item //VideoReDoProject/FrameRate
		WScript.StdOut.WriteLine("Item " & "//VRDProgramInfo/FrameRate" & "=" & item_text)
'
		'Locate the desired node. Note the use of XPATH instead of looping over all the child nodes.
		Set item_nNode = xmlDoc.selectsinglenode ("//VRDProgramInfo/Video/EncodingDimensions") ' CAREFUL, this is case sensitive
		If item_nNode is Nothing Then
			WScript.StdOut.WriteLine("ABORTING: Could not find XML node //VRDProgramInfo/Video/EncodingDimensions in xml_string " & xml_string)
			Wscript.Echo "Error 17 = cannot perform the requested operation"
			On Error goto 0
			WScript.Quit 17 ' Error 17 = cannot perform the requested operation exit with an error ... soft or hard ?
		End If
		item_text = item_nNode.text ' this is the text for that item //VideoReDoProject/EncodingDimensions
		'WScript.StdOut.WriteLine("Item " & "//VRDProgramInfo/EncodingDimensions" & "=" & item_text)
		WScript.StdOut.WriteLine("Item " & "//VRDProgramInfo/EncodingDimensions/height" & "=" & item_nNode.getAttribute("height"))
		WScript.StdOut.WriteLine("Item " & "//VRDProgramInfo/EncodingDimensions/width" & "=" & item_nNode.getAttribute("width"))

		'Locate the desired node. Note the use of XPATH instead of looping over all the child nodes.
		Set item_nNode = xmlDoc.selectsinglenode ("//VRDProgramInfo/Video/AspectRatio") ' CAREFUL, this is case sensitive
		If item_nNode is Nothing Then
			WScript.StdOut.WriteLine("ABORTING: Could not find XML node //VRDProgramInfo/Video/AspectRatio in xml_string " & xml_string)
			Wscript.Echo "Error 17 = cannot perform the requested operation"
			On Error goto 0
			WScript.Quit 17 ' Error 17 = cannot perform the requested operation exit with an error ... soft or hard ?
		End If
		item_text = item_nNode.text ' this is the text for that item //VideoReDoProject/AspectRatio
		WScript.StdOut.WriteLine("Item " & "//VRDProgramInfo/AspectRatio" & "=" & item_text)

		
		'
Set xmlDoc = Nothing
End Sub
'
Sub DisplayNode_from_xml(Nodes, Indent)
   Dim xNode
   For Each xNode In Nodes
      Select Case xNode.nodeType ' 1=NODE ELEMENT, 3=NODE VALUE
        Case 1:   ' NODE_ELEMENT
          If xNode.nodeName <> "#document" Then
            ' change DisplayAttributes_from_xml_node(xNode, Indent + 2) to DisplayAttributes_from_xml_node(xNode, 0) for inline attributes
            WScript.Echo String(Indent," ") & "<" & xNode.nodeName & DisplayAttributes_from_xml_node(xNode, Indent + 2) & ">" ' this is the nodename and note attributes THE START OF THE NODE
            If xNode.hasChildNodes Then
              Call DisplayNode_from_xml(xNode.childNodes, Indent + 2)	' THIS IS THE CHILD NODES OF THE NODE
            End If
            WScript.Echo String(Indent," ") & "</" & xNode.nodeName & ">"	' THIS IS THE END OF THE NODE 
          Else 'NODENAME =  "#document" 
            If xNode.hasChildNodes Then
              Call DisplayNode_from_xml(xNode.childNodes, Indent + 2)
            End If
          End If
        Case 3:   ' value                       
          WScript.Echo String(Indent," ") & "" & xNode.nodeValue ' this is the value of the node ' <-- THIS IS THE VALUE
      End Select
   Next
End Sub
Function DisplayAttributes_from_xml_node(Node, Indent)
   Dim xAttr, res
   res = ""
   For Each xAttr In Node.attributes
      If Indent = 0 Then
        res = res & " " & xAttr.name & "=""" & xAttr.value & """"
      Else 
        res = res & vbCrLf & String(Indent," ") & "" & xAttr.name & """" & xAttr.value & """"
      End If
   Next
   DisplayAttributes_from_xml_node = res
End Function





		
