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
WScript.StdOut.WriteLine "------------------------------------------------------------------------------------------------------"

'----------------------------------
' do elapsed time calculations

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
