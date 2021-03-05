Option explicit
'' NOTE:    For ANY of this to work, the vb script MUST be run under Cscript host - or, things like stdout fail to work.
''          Thus, call the vbscript like this:
''              cscript //NOLOGO "vbscript_path_and_file" "parameter 1" "parameter 2"
'----------------------------------
WScript.StdOut.WriteLine "1. ------------------------------------------------------------------------------------------------------"
Dim  cscript_wshShell, cscript_strEngine
Set cscript_wshShell = CreateObject( "WScript.Shell" )
cscript_strEngine = UCase( Right( WScript.FullName, 12 ) )
If UCase(cscript_strEngine) <> UCase("\CSCRIPT.EXE") Then
    ' exit immediately with error code 17 cannot perform the requested operation
    ' since it was not run like:
    '      cscript //NOLOGO "vbscript_path_and_file" "parameter 1" "parameter 2"
    '      cscript //NOLOGO "test.vbs" /p1:"This is the value for p1" /p2:500
    ' Err.Raise 17 ' Error 17 = cannot perform the requested operation
	WScript.Quit 17 ' Error 17 = cannot perform the requested operation
End If
WScript.StdOut.WriteLine "cscript Engine = """ & cscript_strEngine & """"
WScript.StdOut.WriteLine "------------------------------------------------------------------------------------------------------"

'----------------------------------
' Run a command and capture output and errors
WScript.StdOut.WriteLine "2. ------------------------------------------------------------------------------------------------------"
dim wso, the_exe, the_cmd, x
set wso = CreateObject("Wscript.Shell")
the_cmd = "cmd /c dirx /s /b d:\temp\h*.jpg 2>&1"
WScript.StdOut.WriteLine("Exec command: " & the_cmd)
set the_exe = wso.Exec(the_cmd)
Do While the_exe.Status = 0 '0 is running and 1 is ending
     Wscript.Sleep 250
Loop
Do Until the_exe.StdOut.AtEndOfStream
    x=the_exe.StdOut.ReadLine()
    WScript.StdOut.WriteLine("StdOut: " & x)
    'Wscript.echo x
Loop
Do Until the_exe.StdErr.AtEndOfStream
    x=the_exe.StdErr.ReadLine()
    WScript.StdOut.WriteLin("StdErr: " & x)
    'Wscript.echo(x)
Loop
x=the_exe.ExitCode
WScript.StdOut.WriteLine("Exit Status: " & x)
'Wscript.echo(x)
Set the_exe = Nothing
Set wso = Nothing
WScript.StdOut.WriteLine "------------------------------------------------------------------------------------------------------"

'----------------------------------
' How to parse commandline aruments in vbscript

' Firstly, using standard arguments
' Example 1 cscript //nologo test.vbs /p1:"This is the value for p1" /p2:500dim i, c, NamedArgs, p1, p2
WScript.StdOut.WriteLine "3. ------------------------------------------------------------------------------------------------------"
dim NamedArgs
dim c, i
dim p1, p2
c = WScript.Arguments.Count
if c>0 then
    for i=0 to (c-1)
        WScript.StdOut.WriteLine "Unnamed Argument " & i & "=" & WScript.Arguments(i)
    next
end if
' Secondly, using named arguments 
' Example 2 cscript //nologo test.vbs /p1:"This is the value for p1" /p2:500
c = WScript.Arguments.Count
set NamedArgs = WScript.Arguments.Named
if NamedArgs.Exists("p1") and NOT IsEmpty(NamedArgs("p1")) then 
    p1 = NamedArgs.Item("p1")
else
    p1 = "some default for p1" ' default value if not specified on commandline
end if
if NamedArgs.Exists("p2")  and NOT  IsEmpty(NamedArgs("p2")) then 
    p2 = NamedArgs.Item("p2")
else
    p2 = 2 ' default value if not specified on commandline
end if
WScript.StdOut.WriteLine "Named Argument value for p1=" & p1
WScript.StdOut.WriteLine "Named Argument value for p2=" & p2
WScript.StdOut.WriteLine "------------------------------------------------------------------------------------------------------"

'----------------------------------
' REGEX
WScript.StdOut.WriteLine "4. ------------------------------------------------------------------------------------------------------"
Const replacement_character="."
Const regex_pattern="[^a-zA-Z0-9-_. ]+"      ' ^ means not matching
dim myRegExp
dim input_string
dim result_string
input_string="ABCabc!@#$%^&*()_+-={}[}|\;:`~'""<>,.?/_-+=1234567890."
Set myRegExp = New RegExp
myRegExp.IgnoreCase = False
myRegExp.Global = True  
myRegExp.Pattern = regex_pattern
result_string = myRegExp.Replace(input_string,replacement_character) ' in this case replace all matching characters with ".", in this case all non-standard characters
Set myRegExp = Nothing
WScript.StdOut.WriteLine "regex_pattern        =""" & regex_pattern & """"
WScript.StdOut.WriteLine "replacement_character=""" & replacement_character & """"
WScript.StdOut.WriteLine "Input String         =""" & input_string & """"
WScript.StdOut.WriteLine "Result String        =""" & result_string & """"
WScript.StdOut.WriteLine "------------------------------------------------------------------------------------------------------"

'----------------------------------
' Delete a file
WScript.StdOut.WriteLine "5. ------------------------------------------------------------------------------------------------------"
Dim fso
Dim the_Err_number, the_Err_Description, the_Err_Helpfile, the_Err_HelpContext
Dim the_filename_to_delete
Set fso = CreateObject("Scripting.FileSystemObject")
the_filename_to_delete = "c:\temp\some_existing_file.txt"
WScript.StdOut.WriteLine "Deleting file: """ & the_filename_to_delete & """"
'If fso.FileExists(the_filename_to_delete) Then
	On Error Resume Next
	fso.DeleteFile "c:\somefile.txt", True ' fso.DeleteFile ( filespec[, force] ) ' it also supports wildcards, allowing delete of multiple files ...
	the_Err_number = Err.Number
    the_Err_Description = Err.Description
    the_Err_Helpfile = Err.Helpfile
    the_Err_HelpContext = Err.HelpContext
    If the_Err_number <> 0 Then
        WScript.StdOut.WriteLine "Error " &  the_Err_number &  " " &  the_Err_Description & " : raised when Deleting file """ & the_filename_to_delete & """"
	    Err.Clear
    Else
        WScript.StdOut.WriteLine "Deleted file """ & the_filename_to_delete & """"
    End if
	On Error Goto 0 ' now continue
'End If
set fso=Nothing

Function delete_a_file (filename_to_delete, do_it_silently)
    Dim daf_fso
    Dim daf_Err_number, daf_Err_Description, daf_Err_Helpfile, daf_Err_HelpContext
    Dim daf_filename_to_delete
    If NOT do_it_silently Then
        WScript.StdOut.WriteLine "Deleting file: """ & filename_to_delete & """"
    End If
    Set daf_fso=CreateObject("Scripting.FileSystemObject")
    'If daf_fso.FileExists(filename_to_delete) Then
    	On Error Resume Next
	    daf_fso.DeleteFile filename_to_delete, True ' daf_fso.DeleteFile ( filespec[, force] ) ' it also supports wildcards, allowing delete of multiple files ...
	    daf_Err_number = Err.Number
        daf_Err_Description = Err.Description
        daf_Err_Helpfile = Err.Helpfile
        daf_Err_HelpContext = Err.HelpContext
        If daf_Err_number <> 0 Then
            If NOT do_it_silently Then
                WScript.StdOut.WriteLine "Error " &  daf_Err_number &  " " &  daf_Err_Description & " : raised when Deleting file """ & filename_to_delete & """"
            End If
	        Err.Clear
        Else
            If NOT do_it_silently Then
                WScript.StdOut.WriteLine "Deleted file """ & filename_to_delete & """"
            End If
        End if
	    On Error Goto 0 ' now continue
    'End If
    set daf_fso=Nothing
    delete_a_file = daf_Err_number
End Function

WScript.StdOut.WriteLine "------------------------------------------------------------------------------------------------------"

'----------------------------------
' Build a fully qualified filename from a path and filename and a temporary filename
WScript.StdOut.WriteLine "6. ------------------------------------------------------------------------------------------------------"
Dim fso1, objFile
Dim the_path, the_file, the_result, The_AbsolutePath, theBaseName, theExtName, theFileName, theDriveName
Dim theParentFolderName, theParentFolderName2, temp_Filename
Set fso1 = CreateObject("Scripting.FileSystemObject")
'
the_path = "c:\test\"
the_file = "abcd.def"
the_result = fso1.BuildPath(the_path,the_file)  ' Path can be absolute or relative and need not specify an existing folder.
The_AbsolutePath = fso1.GetAbsolutePathName(the_result)
theBaseName = fso1.GetBaseName(The_AbsolutePath)
theExtName = fso1.GetExtensionName(The_AbsolutePath) ' does not include  the "."
theFileName = fso1.GetFileName(The_AbsolutePath) ' includes filename and "." and extension
theDriveName = fso1.GetDriveName(The_AbsolutePath) ' includes driver letter and ":"
theParentFolderName = fso1.GetParentFolderName(The_AbsolutePath) ' the drive and folder name without any trailing "\"
WScript.StdOut.WriteLine "Buildpath  path=""" & the_path & """ file=""" & the_file & """ Result=""" & the_result & """"
WScript.StdOut.WriteLine "AbsolutePathName=""" & The_AbsolutePath & """"
WScript.StdOut.WriteLine "theBaseName=""" & theBaseName  & """"
WScript.StdOut.WriteLine "theExtName=""" & theExtName  & """"
WScript.StdOut.WriteLine "theFileName=""" & theFileName  & """"
WScript.StdOut.WriteLine "theDriveName=""" & theDriveName  & """"
WScript.StdOut.WriteLine "theParentFolderName=""" & theParentFolderName  & """"
WScript.StdOut.WriteLine ""
'
the_path = "c:\temp"
the_file = "abcd.def"
the_result = fso1.BuildPath(the_path,the_file)  ' Path can be absolute or relative and need not specify an existing folder.
The_AbsolutePath = fso1.GetAbsolutePathName(the_result)
theBaseName = fso1.GetBaseName(The_AbsolutePath)
theExtName = fso1.GetExtensionName(The_AbsolutePath) ' does not include  the "."
theFileName = fso1.GetFileName(The_AbsolutePath) ' includes filename and "." and extension
theDriveName = fso1.GetDriveName(The_AbsolutePath) ' includes driver letter and ":"
theParentFolderName = fso1.GetParentFolderName(The_AbsolutePath) ' the drive and folder name of the file without any trailing "\"
WScript.StdOut.WriteLine "Buildpath  path=""" & the_path & """ file=""" & the_file & """ Result=""" & the_result & """"
WScript.StdOut.WriteLine "AbsolutePathName=""" & The_AbsolutePath & """"
WScript.StdOut.WriteLine "theBaseName=""" & theBaseName  & """"
WScript.StdOut.WriteLine "theExtName=""" & theExtName  & """"
WScript.StdOut.WriteLine "theFileName=""" & theFileName  & """"
WScript.StdOut.WriteLine "theDriveName=""" & theDriveName  & """"
WScript.StdOut.WriteLine "theParentFolderName=""" & theParentFolderName  & """"
WScript.StdOut.WriteLine ""
'
the_path = ".\"
the_file = "abcd.def"
the_result = fso1.BuildPath(the_path,the_file)  ' Path can be absolute or relative and need not specify an existing folder.
The_AbsolutePath = fso1.GetAbsolutePathName(the_result)
theBaseName = fso1.GetBaseName(The_AbsolutePath)
theExtName = fso1.GetExtensionName(The_AbsolutePath) ' does not include  the "."
theFileName = fso1.GetFileName(The_AbsolutePath) ' includes filename and "." and extension
theDriveName = fso1.GetDriveName(The_AbsolutePath) ' includes driver letter and ":"
theParentFolderName = fso1.GetParentFolderName(The_AbsolutePath) ' the drive and folder name of the file without any trailing "\"
WScript.StdOut.WriteLine "Buildpath  path=""" & the_path & """ file=""" & the_file & """ Result=""" & the_result & """"
WScript.StdOut.WriteLine "AbsolutePathName=""" & The_AbsolutePath & """"
WScript.StdOut.WriteLine "theBaseName=""" & theBaseName  & """"
WScript.StdOut.WriteLine "theExtName=""" & theExtName  & """"
WScript.StdOut.WriteLine "theFileName=""" & theFileName  & """"
WScript.StdOut.WriteLine "theDriveName=""" & theDriveName  & """"
WScript.StdOut.WriteLine "theParentFolderName=""" & theParentFolderName  & """"
WScript.StdOut.WriteLine ""
'
the_path = "..\\"
the_file = "abcd.def"
the_result = fso1.BuildPath(the_path,the_file)  ' Path can be absolute or relative and need not specify an existing folder.
The_AbsolutePath = fso1.GetAbsolutePathName(the_result)
theBaseName = fso1.GetBaseName(The_AbsolutePath)
theExtName = fso1.GetExtensionName(The_AbsolutePath) ' does not include  the "."
theFileName = fso1.GetFileName(The_AbsolutePath) ' includes filename and "." and extension
theDriveName = fso1.GetDriveName(The_AbsolutePath) ' includes driver letter and ":"
theParentFolderName = fso1.GetParentFolderName(The_AbsolutePath) ' the drive and folder name of the file without any trailing "\"
theParentFolderName2 = fso1.GetParentFolderName(the_path & the_file) ' input a relative path also returns a good relative path
WScript.StdOut.WriteLine "Buildpath  path=""" & the_path & """ file=""" & the_file & """ Result=""" & the_result & """"
WScript.StdOut.WriteLine "AbsolutePathName=""" & The_AbsolutePath & """"
WScript.StdOut.WriteLine "theBaseName=""" & theBaseName  & """"
WScript.StdOut.WriteLine "theExtName=""" & theExtName  & """"
WScript.StdOut.WriteLine "theFileName=""" & theFileName  & """"
WScript.StdOut.WriteLine "theDriveName=""" & theDriveName  & """"
WScript.StdOut.WriteLine "theParentFolderName (of absolute path)=""" & theParentFolderName  & """"
WScript.StdOut.WriteLine "for a relative path=""" & the_path & the_file & """ theParentFolderName2=""" & theParentFolderName2  & """"
WScript.StdOut.WriteLine ""
'
The_AbsolutePath = fso1.GetAbsolutePathName("C:\000-Essential-tasks\get-my-ip.bat")
Set objFile = fso1.GetFile(The_AbsolutePath)
WScript.StdOut.WriteLine "for existing FileName=""" & The_AbsolutePath & """ FullyQualifiedFileName=""" & objFile.Path & """ Created: """ & objFile.DateCreated & """ Last Modified: """ & objFile.DateLastModified & """ Last Accessed: """ & objFile.DateLastAccessed & """"
WScript.StdOut.WriteLine ""
'
' this next one crashes since the file does not exist -  "Microsoft VBScript runtime error: File not found"
'The_AbsolutePath = fso1.GetAbsolutePathName("C:\test\nonexistentfile.txt")
'Set objFile = fso1.GetFile(The_AbsolutePath)
'WScript.StdOut.WriteLine "for AbsolutePathName=""" & The_AbsolutePath & """ FullyQualifiedFileName=""" & objFile.Path & """ Created: """ & objFile.DateCreated & """ Last Accessed: """ & objFile.DateLastAccessed & """ Last Modified: """ & objFile.DateLastModified & """"
'WScript.StdOut.WriteLine ""
'
' Generate a temporary filename in a nominated folder (does not create the file)
the_path = "..\\"
temp_Filename = fso1.GetTempName
the_result = fso1.BuildPath(the_path,temp_Filename) ' Path can be absolute or relative and need not specify an existing folder.
The_AbsolutePath = fso1.GetAbsolutePathName(the_result)
WScript.StdOut.WriteLine "generated temp_Filename=""" & temp_Filename & """ The_AbsolutePath=""" & The_AbsolutePath & """"
WScript.StdOut.WriteLine ""
'
set objFile=Nothing
set fso1=Nothing



Dim vrdtvs_temp_path
vrdtvs_temp_path = "D:\VRDTVS-SCRATCH\"
Function gimme_a_temporary_absolute_filename
    ' rely on global variable "vrdtvs_temp_path" being set to a valid path
    Dim atf_fso, atf_temp
    Set atf_fso=CreateObject("Scripting.FileSystemObject")
    atf_temp = atf_fso.GetTempName & ".tmp"
    atf_temp = atf_fso.BuildPath(vrdtvs_temp_path,atf_temp) ' rely on global variable "vrdtvs_temp_path" already being set to a valid path
    atf_temp = atf_fso.GetAbsolutePathName(atf_temp)
    'WScript.StdOut.WriteLine "generated a_temporary_filename=""" & a_temporary_filename & """"
    Set mi_fso=Nothing
    gimme_a_temporary_absolute_filename = atf_temp
End Function


WScript.StdOut.WriteLine "------------------------------------------------------------------------------------------------------"

'----------------------------------
' do elapsed time calculations
WScript.StdOut.WriteLine "7. ------------------------------------------------------------------------------------------------------"

dim timer_StartTime, timer_EndTime, timer_ElapsedTime
timer_StartTime = Timer()
Wscript.Sleep 750 ' milliseconds
timer_EndTime = Timer()
timer_ElapsedTime = FormatNumber(timer_EndTime - timer_StartTime, 3)
WScript.StdOut.WriteLine "1. straight calculation Elapsed Time in Seconds to 3 decimal places: " & timer_ElapsedTime

timer_StartTime = Timer()
Wscript.Sleep 750 ' milliseconds
timer_EndTime = Timer()
Wscript.Echo "2. Function Elapsed Time in ms : " & Calculate_ElapsedTime_ms(timer_StartTime, timer_EndTime)
Wscript.Echo "2. Function Elapsed Time String: " & Calculate_ElapsedTime_string(timer_StartTime, timer_EndTime)

Function Calculate_ElapsedTime_ms (timer_StartTime, timer_EndTime)
    Calculate_ElapsedTime_ms = Round(timer_EndTime - timer_StartTime, 3) * 1000 ' round to 3 decimal places is milliseconds
End Function
Function Calculate_ElapsedTime_string (timer_StartTime, timer_EndTime)
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
        Calculate_ElapsedTime_string = FormatNumber(seconds,3) & " second" & seconds_plural
        Exit Function
    End If
    If seconds < SECONDS_IN_HOUR Then 
        minutes = seconds / SECONDS_IN_MINUTE
        seconds = seconds MOD SECONDS_IN_MINUTE
        Calculate_ElapsedTime_string = Int(minutes) & " minutes " & FormatNumber(seconds,3) & " second" & seconds_plural
        Exit Function
    End If
    If seconds < SECONDS_IN_DAY Then
        hours   = seconds / SECONDS_IN_HOUR
        minutes = (seconds MOD SECONDS_IN_HOUR) / SECONDS_IN_MINUTE
        seconds = (seconds MOD SECONDS_IN_HOUR) MOD SECONDS_IN_MINUTE
        Calculate_ElapsedTime_string = Int(hours) & " hours " & Int(minutes) & " minutes " & FormatNumber(seconds,3) & " second" & seconds_plural
        Exit Function
    End If
    If seconds < SECONDS_IN_WEEK Then
        days    = seconds / SECONDS_IN_DAY
        hours   = (seconds MOD SECONDS_IN_DAY) / SECONDS_IN_HOUR
        minutes = ((seconds MOD SECONDS_IN_DAY) MOD SECONDS_IN_HOUR) / SECONDS_IN_MINUTE
        seconds = ((seconds MOD SECONDS_IN_DAY) MOD SECONDS_IN_HOUR) MOD SECONDS_IN_MINUTE
        Calculate_ElapsedTime_string = Int(days) & " days " & Int(hours) & " hours " & Int(minutes) & " minutes " & FormatNumber(seconds,3) & " second" & seconds_plural
        Exit Function
    End If
End Function
WScript.StdOut.WriteLine "------------------------------------------------------------------------------------------------------"


'----------------------------------
' Can we somehow open and use external .DLL files such as mediainfo.dll
'
' Answer: NO.  use the old method and use it the same for ffprobe too

WScript.StdOut.WriteLine "8. ------------------------------------------------------------------------------------------------------"

Dim vrdtvs_mediainfoexe
vrdtvs_mediainfoexe = "C:\SOFTWARE\MediaInfo\MediaInfo.exe"
dim V_Width, V_Height, V_DisplayAspectRatio, V_DisplayAspectRatio_string, V_DisplayAspectRatio_string_slash, A_Video_Delay_ms, A_Audio_Delay_ms

V_Width = get_mediainfo_parameter("Video","Width","G:\HDTV\000-TO-BE-PROCESSED\zzz-TEST\VRDTVS-Converted\News-ABC_Evening_News.2021-02-05.mp4", "")
V_Height = get_mediainfo_parameter("Video","Height","G:\HDTV\000-TO-BE-PROCESSED\zzz-TEST\VRDTVS-Converted\News-ABC_Evening_News.2021-02-05.mp4", "")
V_DisplayAspectRatio = get_mediainfo_parameter("Video","DisplayAspectRatio","G:\HDTV\000-TO-BE-PROCESSED\zzz-TEST\VRDTVS-Converted\News-ABC_Evening_News.2021-02-05.mp4", "")
V_DisplayAspectRatio_string = get_mediainfo_parameter("Video","DisplayAspectRatio/String","G:\HDTV\000-TO-BE-PROCESSED\zzz-TEST\VRDTVS-Converted\News-ABC_Evening_News.2021-02-05.mp4", "")
V_DisplayAspectRatio_string_slash = Replace(V_DisplayAspectRatio_string,":","/",1,-1,1)
A_Video_Delay_ms =  get_mediainfo_parameter("Audio","Video_Delay","G:\HDTV\000-TO-BE-PROCESSED\zzz-TEST\VRDTVS-Converted\News-ABC_Evening_News.2021-02-05.mp4", "")
If A_Video_Delay_ms = "" Then
	A_Video_Delay_ms = 0
	A_Audio_Delay_ms = 0
Else
	A_Audio_Delay_ms = 0 - A_Video_Delay_ms
End If
Wscript.echo("V_Width=" & V_Width & " V_Height=" & V_Height)
Wscript.echo("V_DisplayAspectRatio=" & V_DisplayAspectRatio)
Wscript.echo("V_DisplayAspectRatio_string=" & V_DisplayAspectRatio_string & " V_DisplayAspectRatio_string_slash=" & V_DisplayAspectRatio_string_slash)
Wscript.echo("A_Video_Delay_ms=" & A_Video_Delay_ms)
Wscript.echo("A_Audio_Delay_ms=" & A_Audio_Delay_ms)

Function get_mediainfo_parameter (mi_Section, mi_Parameter, mi_MediaFilename, mi_Legacy) 
    '        1. a global variable vrdtvs_mediainfoexe exists pointing to the mediainfo exe
    ' Note \r\n is Windows new-line, 
    ' Which in the case of multiple audio streams, outputs a result for each stream on a new line, 
    ' the first stream being the first entry, and the first audio stream should be the one we need. 
    Dim mi_fso, mi_status
    'Dim mi_temp_Filename
    Dim mi_wso, mi_exe, mi_cmd, mi_tmp
    If Ucase(mi_Legacy) <> Ucase("--Legacy") AND Ucase(mi_Legacy) <> "" Then
        WScript.StdOut.WriteLine("get_mediainfo_parameter UNRECOGNISED LEGACY PARAMETER: " & mi_Legacy & " : it should only be an empty string or --Legacy")
        ' Err.Raise 17 ' Error 17 = cannot perform the requested operation
	    WScript.Quit 17 ' Error 17 = cannot perform the requested operation
    End If
    Set mi_fso = CreateObject("Scripting.FileSystemObject")
    set mi_wso = CreateObject("Wscript.Shell")
    '
    ' If piping to a temporary file, cmd looks something like this:
    ' mi_temp_Filename = gimme_a_temporary_absolute_filename() ' generate a fully qualified temporary filename from the function
    ' mi_status = delete_a_file (mi_temp_Filename, True)
    ' mi_cmd =  """" & vrdtvs_mediainfoexe & """ " & mi_Legacy & " ""--Inform=" & mi_Section & ";%" & mi_Parameter & "%\r\n"" """ & mi_MediaFilename & """ > """ & mi_temp_Filename & """"
    '
    mi_cmd = """" & vrdtvs_mediainfoexe & """ " & mi_Legacy & " ""--Inform=" & mi_Section & ";%" & mi_Parameter & "%\r\n"" """ & mi_MediaFilename & """"
    'WScript.StdOut.WriteLine("DEBUG: get_mediainfo_parameter Exec command: " & mi_cmd)
    set mi_exe = mi_wso.Exec(mi_cmd)
    Do While mi_exe.Status = 0 '0 is running and 1 is ending
        Wscript.Sleep 100
    Loop
    Do Until mi_exe.StdErr.AtEndOfStream
        mi_tmp = mi_exe.StdErr.ReadLine()
        WScript.StdOut.WriteLine("ERROR: get_mediainfo_parameter StdErr: " & mi_tmp)
    Loop
    mi_status = mi_exe.ExitCode
    If mi_status <> 0 then
        WScript.StdOut.WriteLine("ERROR: get_mediainfo_parameter ABORTING Exec command: " & mi_cmd)
        WScript.StdOut.WriteLine("ERROR: get_mediainfo_parameter ABORTING with Exit Status: " & mi_status)
        ' Err.Raise 17 ' Error 17 = cannot perform the requested operation
	    WScript.Quit 17 ' Error 17 = cannot perform the requested operation
    End If
    mi_tmp="" ' default to nothing
    Do Until mi_exe.StdOut.AtEndOfStream ' we need to read only one line though
        mi_tmp = mi_exe.StdOut.ReadLine()
        'WScript.StdOut.WriteLine("DEBUG: get_mediainfo_parameter StdOut: " & mi_tmp)
        Exit Do ' we need to read only one line so exit loop immediately
    Loop
    Set mi_exe = Nothing
    Set mi_wso = Nothing
    Set mi_fso = Nothing
    get_mediainfo_parameter = mi_tmp
End Function

WScript.StdOut.WriteLine "------------------------------------------------------------------------------------------------------"


'----------------------------------
' Can we somehow open and use external FFPROBE
'
' Answer: Yes, like medianfo.exe

WScript.StdOut.WriteLine "9. ------------------------------------------------------------------------------------------------------"

Dim vrdtvs_ffprobeexe
vrdtvs_ffprobeexe = "C:\SOFTWARE\Vapoursynth-x64\ffprobe.exe"

dim V_Width_FF, V_Height_FF, V_Duration_s_FF, V_BitRate_FF, V_BitRate_Maximum_FF

V_Width_FF = get_ffprobe_video_stream_parameter("width","G:\HDTV\000-TO-BE-PROCESSED\zzz-TEST\VRDTVS-Converted\News-ABC_Evening_News.2021-02-05.mp4")
V_Height_FF = get_ffprobe_video_stream_parameter("height","G:\HDTV\000-TO-BE-PROCESSED\zzz-TEST\VRDTVS-Converted\News-ABC_Evening_News.2021-02-05.mp4")
V_Duration_s_FF = get_ffprobe_video_stream_parameter("duration","G:\HDTV\000-TO-BE-PROCESSED\zzz-TEST\VRDTVS-Converted\News-ABC_Evening_News.2021-02-05.mp4")
V_BitRate_FF = get_ffprobe_video_stream_parameter("bit_rate","G:\HDTV\000-TO-BE-PROCESSED\zzz-TEST\VRDTVS-Converted\News-ABC_Evening_News.2021-02-05.mp4")
V_BitRate_Maximum_FF = get_ffprobe_video_stream_parameter("max_bit_rate","G:\HDTV\000-TO-BE-PROCESSED\zzz-TEST\VRDTVS-Converted\News-ABC_Evening_News.2021-02-05.mp4")
Wscript.echo("V_Width_FF=" & V_Width_FF & " V_Height_FF=" & V_Height_FF)
Wscript.echo("V_Duration_s_FF=" & V_Duration_s_FF)
Wscript.echo("V_BitRate_FF=" & V_BitRate_FF)
Wscript.echo("V_BitRate_Maximum_FF=" & V_BitRate_Maximum_FF)

Function get_ffprobe_video_stream_parameter (ffp_Parameter, ffp_MediaFilename) 
    '        1. a global variable vrdtvs_ffprobeexe exists pointing to the ffprobe exe
    ' Note \r\n is Windows new-line, which is for the case of multiple audio streams, 
    '      it outputs a result for each stream on a new line, the first stream being the first entry,
    '      and the first audio stream should be the one we need. 
    '      read the first line.
    '      see if -probesize 5000M  makes any difference
    Dim ffp_fso, ffp_status
    'Dim ffp_temp_Filename
    Dim ffp_wso, ffp_exe, ffp_cmd, ffp_tmp
    Set ffp_fso = CreateObject("Scripting.FileSystemObject")
    set ffp_wso = CreateObject("Wscript.Shell")
    '
    ' If piping to a temporary file, cmd looks something like this:
    ' ffp_temp_Filename = gimme_a_temporary_absolute_filename() ' generate a fully qualified temporary filename from the function
    ' ffp_status = delete_a_file (ffp_temp_Filename, True)
    ' ffp_cmd =  """" & vrdtvs_ffprobeexe & ???  & ffp_MediaFilename & """ > """ & ffp_temp_Filename & """"
    '
    ffp_cmd = """" & vrdtvs_ffprobeexe & """ -hide_banner -v quiet -select_streams v:0 -show_entries stream=" & ffp_Parameter & " -of default=noprint_wrappers=1:nokey=1 """ & ffp_MediaFilename & """"
    'WScript.StdOut.WriteLine("DEBUG: get_ffprobe_video_stream_parameter Exec command: " & ffp_cmd)
    set ffp_exe = ffp_wso.Exec(ffp_cmd)
    Do While ffp_exe.Status = 0 '0 is running and 1 is ending
        Wscript.Sleep 100
    Loop
    Do Until ffp_exe.StdErr.AtEndOfStream
        ffp_tmp = ffp_exe.StdErr.ReadLine()
        WScript.StdOut.WriteLine("ERROR: get_ffprobe_video_stream_parameter StdErr: " & ffp_tmp)
    Loop
    ffp_status = ffp_exe.ExitCode
    If ffp_status <> 0 then
        WScript.StdOut.WriteLine("ERROR: get_ffprobe_video_stream_parameter ABORTING Exec command: " & ffp_cmd)
        WScript.StdOut.WriteLine("ERROR: get_ffprobe_video_stream_parameter ABORTING with Exit Status: " & ffp_status)
        ' Err.Raise 17 ' Error 17 = cannot perform the requested operation
	    WScript.Quit 17 ' Error 17 = cannot perform the requested operation
End If
ffp_tmp="" ' default to nothing
Do Until ffp_exe.StdOut.AtEndOfStream ' we need to read only one line though
    ffp_tmp = ffp_exe.StdOut.ReadLine()
    'WScript.StdOut.WriteLine("DEBUG: get_ffprobe_video_stream_parameter StdOut: " & ffp_tmp)
    Exit Do ' we need to read only one line so exit loop immediately
Loop
Set ffp_exe = Nothing
Set ffp_wso = Nothing
Set ffp_fso = Nothing
get_ffprobe_video_stream_parameter = ffp_tmp
End Function
