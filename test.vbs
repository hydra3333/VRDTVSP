Option explicit
'' NOTE:    For ANY of this to work, the vb script MUST be run under Cscript host - or, things like stdout fail to work.
''          Thus, call the vbscript like this:
''              cscript //NOLOGO "vbscript_path_and_file" "parameter 1" "parameter 2"
'----------------------------------
dim wso, exe 
dim x
set wso = CreateObject("Wscript.Shell")
set exe = wso.Exec("cmd /c dirx /s /b d:\temp\h*.jpg 2>&1")
Do While exe.Status = 0 '0 is running and 1 is ending
     Wscript.Sleep 250
Loop
Do Until exe.StdOut.AtEndOfStream
    x=exe.StdOut.ReadLine()
    WScript.StdOut.WriteLine("StdOut: " & x)
    'Wscript.echo x
Loop
Do Until exe.StdErr.AtEndOfStream
    x=exe.StdErr.ReadLine()
    WScript.StdOut.WriteLin("StdErr: " & x)
    'Wscript.echo(x)
Loop
x=exe.ExitCode
WScript.StdOut.WriteLine("Exit Status: " & x)
'Wscript.echo(x)
Set exe = Nothing
Set wso = Nothing

'----------------------------------
' Firstly, using standard arguments
' Example 1 cscript //nologo test.vbs /p1:"This is the value for p1" /p2:500dim i, c, NamedArgs, p1, p2
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

'----------------------------------
' REGEX
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


