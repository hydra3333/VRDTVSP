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
' Build a fully qualified filename from a path and filename
WScript.StdOut.WriteLine "6. ------------------------------------------------------------------------------------------------------"
Dim fso1
Dim the_path, the_file, the_result, The_AbsolutePath
Set fso1 = CreateObject("Scripting.FileSystemObject")
the_path = "c:\test\"
the_file = "abd.def"
the_result = fso1.BuildPath(the_path,the_file)  ' Path can be absolute or relative and need not specify an existing folder.
The_AbsolutePath = fso1.GetAbsolutePathName(the_result)
WScript.StdOut.WriteLine "Buildpath  path=""" & the_path & """ file=""" & the_file & """ Result=""" & the_result & """ AbsolutePathName=""" & The_AbsolutePath  & """"
the_path = "c:\temp"
the_file = "abd.def"
the_result = fso1.BuildPath(the_path,the_file)  ' Path can be absolute or relative and need not specify an existing folder.
The_AbsolutePath = fso1.GetAbsolutePathName(the_result)
WScript.StdOut.WriteLine "Buildpath  path=""" & the_path & """ file=""" & the_file & """ Result=""" & the_result & """ AbsolutePathName=""" & The_AbsolutePath  & """"
the_path = ".\"
the_file = "abd.def"
the_result = fso1.BuildPath(the_path,the_file)  ' Path can be absolute or relative and need not specify an existing folder.
The_AbsolutePath = fso1.GetAbsolutePathName(the_result)
WScript.StdOut.WriteLine "Buildpath  path=""" & the_path & """ file=""" & the_file & """ Result=""" & the_result & """ AbsolutePathName=""" & The_AbsolutePath  & """"
set fso1=Nothing
WScript.StdOut.WriteLine "------------------------------------------------------------------------------------------------------"

