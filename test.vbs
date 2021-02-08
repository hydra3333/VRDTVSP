Option explicit
'' NOTE:    For ANY of this to work, the vb script MUST be run under Cscript host - or, things like stdout fail to work.
''          Thus, call the vbscript like this:   cscript //NOLOGO "vbscript_path_and_file" "parameter 1" "parameter 2"
dim wso, exe 
dim x
set wso = CreateObject("Wscript.Shell")
set exe = wso.Exec("cmd /c dirx /s /b d:\temp\h*.jpg 2>&1")
Do While exe.Status = 0 '0 is running and 1 is ending
     Wscript.Sleep 200
Loop
Do Until exe.StdOut.AtEndOfStream
    x=exe.StdOut.ReadLine()
    WScript.StdOut.WriteLine(x)
    'Wscript.echo x
Loop
Do Until exe.StdErr.AtEndOfStream
    x=exe.StdErr.ReadLine()
    WScript.StdOut.WriteLine(x)
    'Wscript.echo(x)
Loop
x=exe.ExitCode
WScript.StdOut.WriteLine(x)
'Wscript.echo(x)
Set exe = Nothing
Set wso = Nothing
