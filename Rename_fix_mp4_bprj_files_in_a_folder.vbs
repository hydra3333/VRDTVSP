Option Explicit
Const powershell_script_filename = "G:\HDTV\Rename_files_selected_folders_ModifyDateStamps.ps1"
Dim Args, p, i
Dim objStdOut
Dim fso, rcount, fcount, acount, bcount
Dim fix_timestamps
Dim theLogfile 
theLogfile = Wscript.ScriptFullName & "-" & theDateTimeString() & ".log"
Set objStdOut = WScript.StdOut
Set fso = CreateObject("Scripting.FileSystemObject")
Call Create_powershell_script(powershell_script_filename,theLogfile)
rcount = 0
fcount = 0
acount = 0
bcount = 0
'on error resume next					
WScript.StdOut.WriteLine "vbs_rename_files: Started"
set Args = Wscript.Arguments
if Args.Count < 3 then
	wscript.echo( "? Invalid number of arguments " & Args.Count & " - usage is: ")
	wscript.echo( " cscript this.vbs ""y"" <powershell_log_filename> <source_folder1> <source_folder2> <source_folder3> <source_folder4> <source_folder5>" )
	wscript.echo( "    P1  ""y"" or ""n"" to fix timestamps" )
	wscript.echo( "    P2 the log filename for powershell to append to" )
	wscript.echo( "    P3 onwards are folder names" )
	Wscript.Quit 1
end if
'for i = 0 to (Args.Count - 1)
'	p = Args(i)
'	if Right(p,1) = "\" OR Right(p,1) = "/" then
'		p = Left(p, Len(p) - 1) 
'	end if
'	wscript.echo( "arg(" & i & ")=<" & p & ">")
'next
if lcase(Args(0)) = "y" then
	fix_timestamps = True
else
	fix_timestamps = False
end if
theLogfile = lcase(Args(1))
for i = 2 to (Args.Count - 1)
	p = Args(i)
	if Right(p,1) = "\" OR Right(p,1) = "/" then
		p = Left(p, Len(p) - 1) 
	end if
	Call Do_a_folder(p, fix_timestamps, powershell_script_filename, theLogfile)
next
WScript.StdOut.WriteLine "vbs_rename_files: Finished"
WScript.StdOut.WriteLine "vbs_rename_files: Files examined=" & acount & " Files matched=" & fcount & " Files renamed=" & rcount & " .bprj Files updated=" & bcount
Set fso = Nothing
Wscript.Quit

Public Sub Do_a_folder (aPath, fix_timestamps, powershell_script_filename, theLogfile)
' inherit global variables fso, rcount, fcount, acount, bcount
Dim fldr, f, objWscriptShell, powershell_cmdline
If NOT fso.FolderExists(aPath) Then
	WScript.StdOut.WriteLine "vbs_rename_files: Folder does NOT EXIST <" & aPath & "> ... not processed"
	Exit Sub
Else
	WScript.StdOut.WriteLine "vbs_rename_files: --- STARTED for folder <" & aPath & ">"
	Set fldr = fso.GetFolder(aPath)
	'WScript.StdOut.WriteLine "vbs_rename_files: --- fldr.name=<" & fldr.name & ">"
	for each f in fldr.Files
		acount = acount + 1
		call Rename_File_in_a_Path(f)
	next
	Set fldr = Nothing
	if fix_timestamps = True then
		Set objWscriptShell = CreateObject("Wscript.shell")
		powershell_cmdline = "powershell -NoLogo -ExecutionPolicy Unrestricted -Sta -NonInteractive -WindowStyle Normal -File """ & powershell_script_filename & """ -Folder """ & aPath & """ -logFile """ &  theLogfile & """"
		WScript.StdOut.WriteLine "vbs_rename_files: ***** Fixing file dates using:<" & powershell_cmdline & ">"
		objWscriptShell.run powershell_cmdline,True
		Set objWscriptShell = Nothing
		WScript.StdOut.WriteLine "vbs_rename_files: --- FINISHED for folder <" & aPath & ">"
	end if
end if
End Sub

Public sub Rename_File_in_a_Path(byref f)
Dim ext, xbasename, new_basename, new_name, xmlDoc, sts, nNode, txtbefore, i, txtafter, iErrNo, iErrCount, new_name_2, new_basename_2
Dim xyear, xmonth, xday, xdate
ext = fso.GetExtensionName(f.path)
xbasename = fso.GetBaseName(f.path)
If LCase(ext) = LCase("mp4") or LCase(ext) = LCase("bprj") then
	fcount = fcount + 1
	' replace chars in the filename and if not same then rename the file
	new_basename = xbasename

	new_basename = ReplaceEndStringCaseIndependent(new_basename, ".h264", "")
	new_basename = ReplaceEndStringCaseIndependent(new_basename, ".h265", "")
	new_basename = ReplaceEndStringCaseIndependent(new_basename, ".aac", "")

	If instr(1, new_basename, "_2017-", vbTextCompare) > 0 then new_basename = Replace(new_basename, "_2013-", ".2017-", 1, -1, vbTextCompare)
	If instr(1, new_basename, "_2017-", vbTextCompare) > 0 then new_basename = Replace(new_basename, "_2014-", ".2017-", 1, -1, vbTextCompare)
	If instr(1, new_basename, "_2017-", vbTextCompare) > 0 then new_basename = Replace(new_basename, "_2015-", ".2017-", 1, -1, vbTextCompare)
	If instr(1, new_basename, "_2017-", vbTextCompare) > 0 then new_basename = Replace(new_basename, "_2016-", ".2017-", 1, -1, vbTextCompare)
	If instr(1, new_basename, "_2017-", vbTextCompare) > 0 then new_basename = Replace(new_basename, "_2017-", ".2017-", 1, -1, vbTextCompare)
	If instr(1, new_basename, "_2018-", vbTextCompare) > 0 then new_basename = Replace(new_basename, "_2018-", ".2018-", 1, -1, vbTextCompare)
	If instr(1, new_basename, "_2019-", vbTextCompare) > 0 then new_basename = Replace(new_basename, "_2019-", ".2019-", 1, -1, vbTextCompare)
	If instr(1, new_basename, "_2020-", vbTextCompare) > 0 then new_basename = Replace(new_basename, "_2020-", ".2020-", 1, -1, vbTextCompare)
	If instr(1, new_basename, "_2021-", vbTextCompare) > 0 then new_basename = Replace(new_basename, "_2021-", ".2021-", 1, -1, vbTextCompare)
	If instr(1, new_basename, "_2022-", vbTextCompare) > 0 then new_basename = Replace(new_basename, "_2022-", ".2022-", 1, -1, vbTextCompare)
	If instr(1, new_basename, "_2023-", vbTextCompare) > 0 then new_basename = Replace(new_basename, "_2023-", ".2023-", 1, -1, vbTextCompare)
	If instr(1, new_basename, "_2024-", vbTextCompare) > 0 then new_basename = Replace(new_basename, "_2024-", ".2024-", 1, -1, vbTextCompare)
	If instr(1, new_basename, "_2025-", vbTextCompare) > 0 then new_basename = Replace(new_basename, "_2025-", ".2025-", 1, -1, vbTextCompare)
	If instr(1, new_basename, "_2026-", vbTextCompare) > 0 then new_basename = Replace(new_basename, "_2026-", ".2026-", 1, -1, vbTextCompare)
	If instr(1, new_basename, "_2027-", vbTextCompare) > 0 then new_basename = Replace(new_basename, "_2027-", ".2027-", 1, -1, vbTextCompare)
	If instr(1, new_basename, "_2028-", vbTextCompare) > 0 then new_basename = Replace(new_basename, "_2028-", ".2028-", 1, -1, vbTextCompare)
	If instr(1, new_basename, "_2029-", vbTextCompare) > 0 then new_basename = Replace(new_basename, "_2029-", ".2029-", 1, -1, vbTextCompare)
	If instr(1, new_basename, "_2030-", vbTextCompare) > 0 then new_basename = Replace(new_basename, "_2030-", ".2030-", 1, -1, vbTextCompare)
	If instr(1, new_basename, "_2031-", vbTextCompare) > 0 then new_basename = Replace(new_basename, "_2031-", ".2031-", 1, -1, vbTextCompare)
	If instr(1, new_basename, "_2032-", vbTextCompare) > 0 then new_basename = Replace(new_basename, "_2032-", ".2032-", 1, -1, vbTextCompare)
	If instr(1, new_basename, "_2033-", vbTextCompare) > 0 then new_basename = Replace(new_basename, "_2033-", ".2033-", 1, -1, vbTextCompare)
	If instr(1, new_basename, "_2034-", vbTextCompare) > 0 then new_basename = Replace(new_basename, "_2034-", ".2034-", 1, -1, vbTextCompare)
	If instr(1, new_basename, "_2035-", vbTextCompare) > 0 then new_basename = Replace(new_basename, "_2035-", ".2035-", 1, -1, vbTextCompare)
	If instr(1, new_basename, "_2036-", vbTextCompare) > 0 then new_basename = Replace(new_basename, "_2036-", ".2036-", 1, -1, vbTextCompare)
	If instr(1, new_basename, "_2037-", vbTextCompare) > 0 then new_basename = Replace(new_basename, "_2037-", ".2037-", 1, -1, vbTextCompare)
	If instr(1, new_basename, "_2038-", vbTextCompare) > 0 then new_basename = Replace(new_basename, "_2038-", ".2038-", 1, -1, vbTextCompare)
	If instr(1, new_basename, "_2039-", vbTextCompare) > 0 then new_basename = Replace(new_basename, "_2039-", ".2039-", 1, -1, vbTextCompare)
	If instr(1, new_basename, "_2040-", vbTextCompare) > 0 then new_basename = Replace(new_basename, "_2040-", ".2040-", 1, -1, vbTextCompare)
	If instr(1, new_basename, "_2041-", vbTextCompare) > 0 then new_basename = Replace(new_basename, "_2041-", ".2041-", 1, -1, vbTextCompare)
	If instr(1, new_basename, "_2042-", vbTextCompare) > 0 then new_basename = Replace(new_basename, "_2042-", ".2042-", 1, -1, vbTextCompare)
	If instr(1, new_basename, "_2043-", vbTextCompare) > 0 then new_basename = Replace(new_basename, "_2043-", ".2043-", 1, -1, vbTextCompare)
	If instr(1, new_basename, "_2044-", vbTextCompare) > 0 then new_basename = Replace(new_basename, "_2044-", ".2044-", 1, -1, vbTextCompare)
	If instr(1, new_basename, "_2045-", vbTextCompare) > 0 then new_basename = Replace(new_basename, "_2045-", ".2045-", 1, -1, vbTextCompare)
	If instr(1, new_basename, "_2046-", vbTextCompare) > 0 then new_basename = Replace(new_basename, "_2046-", ".2046-", 1, -1, vbTextCompare)
	If instr(1, new_basename, "_2047-", vbTextCompare) > 0 then new_basename = Replace(new_basename, "_2047-", ".2047-", 1, -1, vbTextCompare)
	If instr(1, new_basename, "_2048-", vbTextCompare) > 0 then new_basename = Replace(new_basename, "_2048-", ".2048-", 1, -1, vbTextCompare)
	If instr(1, new_basename, "_2049-", vbTextCompare) > 0 then new_basename = Replace(new_basename, "_2049-", ".2049-", 1, -1, vbTextCompare)
	If instr(1, new_basename, "_2050-", vbTextCompare) > 0 then new_basename = Replace(new_basename, "_2050-", ".2050-", 1, -1, vbTextCompare)

	If instr(1, new_basename, " - ", vbTextCompare) > 0 then new_basename = Replace(new_basename, " - ", "-", 1, -1, vbTextCompare)
	If instr(1, new_basename, "  ", vbTextCompare) > 0 then new_basename = Replace(new_basename, "  ", " ", 1, -1, vbTextCompare)
	If instr(1, new_basename, "  ", vbTextCompare) > 0 then new_basename = Replace(new_basename, "  ", " ", 1, -1, vbTextCompare)
	If instr(1, new_basename, "  ", vbTextCompare) > 0 then new_basename = Replace(new_basename, "  ", " ", 1, -1, vbTextCompare)
	''' If instr(1, new_basename, "- ", vbTextCompare) > 0 then WScript.StdOut.WriteLine "vbs_rename_files: Fixing file with '- ':<" & xbasename & ">"
	If instr(1, new_basename, "- ", vbTextCompare) > 0 then new_basename = Replace(new_basename, "- ", "-", 1, -1, vbTextCompare)
	''' If instr(1, new_basename, " -", vbTextCompare) > 0 then WScript.StdOut.WriteLine "vbs_rename_files: Fixing file with ' -':<" & xbasename & ">"
	If instr(1, new_basename, " -", vbTextCompare) > 0 then new_basename = Replace(new_basename, " -", "-", 1, -1, vbTextCompare)
	If instr(1, new_basename, "..", vbTextCompare) > 0 then new_basename = Replace(new_basename, "..", ".", 1, -1, vbTextCompare)
	If instr(1, new_basename, "..", vbTextCompare) > 0 then new_basename = Replace(new_basename, "..", ".", 1, -1, vbTextCompare)
	If instr(1, new_basename, "..", vbTextCompare) > 0 then new_basename = Replace(new_basename, "..", ".", 1, -1, vbTextCompare)
	''' If instr(1, new_basename, "--", vbTextCompare) > 0 then WScript.StdOut.WriteLine "vbs_rename_files: Fixing file with '--':<" & xbasename & ">"
	If instr(1, new_basename, "--", vbTextCompare) > 0 then new_basename = Replace(new_basename, "--", "-", 1, -1, vbTextCompare)
	If instr(1, new_basename, "--", vbTextCompare) > 0 then new_basename = Replace(new_basename, "--", "-", 1, -1, vbTextCompare)
	If instr(1, new_basename, "--", vbTextCompare) > 0 then new_basename = Replace(new_basename, "--", "-", 1, -1, vbTextCompare)
	' Replace all spaces in filenames (but not folder names !!!) with underscores
	new_basename = Replace(new_basename, " ", "_", 1, -1, vbTextCompare)
	new_basename = Replace(new_basename, "[", "_", 1, -1, vbTextCompare)
	new_basename = Replace(new_basename, "]", "_", 1, -1, vbTextCompare)
	new_basename = Replace(new_basename, "(", "_", 1, -1, vbTextCompare)
	new_basename = Replace(new_basename, ")", "_", 1, -1, vbTextCompare)
	
	' THESE ARE ALL IN A SPECIAL ORDER !
	'
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Drama-Mystery-Sci-Fi-The X-Files ", "Drama-Mystery-Sci-Fi-The X-Files-")
	'
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie Movie ", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie ", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, " Movie", "-Movie")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Action-Adventure-Comedy ", "Action-Adventure-Comedy-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Action-Adventure-Crime-Movie ", "Action-Adventure-Crime-Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Action-Adventure-Fantasy-Movie ", "Action-Adventure-Fantasy-Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Adventure-Documentary-Travel ", "Adventure-Documentary-Travel-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Action-Adventure-Movie-Sci-Fi ", "Action-Adventure-Movie-Sci-Fi-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Action-Drama-Movie-Thriller ", "Action-Drama-Movie-Thriller-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Action-Drama-Movie-Thriller ", "Action-Drama-Movie-Thriller-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Action-Fantasy-Movie ", "Action-Fantasy-Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Action-Fantasy-Movie-Sci-Fi ", "Action-Fantasy-Movie-Sci-Fi-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Action-Movie-Thriller ", "Action-Movie-Thriller-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Adventure-Family-Fantasy-Movie ", "Adventure-Family-Fantasy-Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Adventure-Movie ", "Adventure-Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Animation-Comedy-Family-Movie ", "Animation-Comedy-Family-Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Arts-Culture-Biography-Drama-Historical-Movie-Romance ", "Arts-Culture-Biography-Drama-Historical-Movie-Romance-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Arts-Culture-Documentary-Historical-Nature-Society-Culture-Travel ", "Arts-Culture-Documentary-Historical-Nature-Society-Culture-Travel-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Arts-Culture-Documentary-Historical-Society-Culture ", "Arts-Culture-Documentary-Historical-Society-Culture-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Arts-Culture-Drama-Movie ", "Arts-Culture-Drama-Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Biography-Comedy-Drama-Movie ", "Biography-Comedy-Drama-Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Biography-Documentary-Historical ", "Biography-Documentary-Historical-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Biography-Documentary-Historical-Mystery ", "Biography-Documentary-Historical-Mystery-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Biography-Documentary-Historical-Society-Culture ", "Biography-Documentary-Historical-Society-Culture-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Biography-Documentary-Music ", "Biography-Documentary-Music-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Biography-Drama-Historical ", "Biography-Drama-Historical-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Biography-Drama-Movie ", "Biography-Drama-Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Biography-Drama-Movie-Romance ", "Biography-Drama-Movie-Romance-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Children ", "Children-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Comedy ", "Comedy-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Comedy-Dance-Movie-Romance ", "Comedy-Dance-Movie-Romance-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Comedy-Drama-Fantasy-Movie-Romance ", "Comedy-Drama-Fantasy-Movie-Romance-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Comedy-Drama-Movie ", "Comedy-Drama-Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Comedy-Drama-Music ", "Comedy-Drama-Music-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Comedy-Family-Movie ", "Comedy-Family-Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Comedy-Family-Movie-Romance ", "Comedy-Family-Movie-Romance-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Comedy-Horror-Movie ", "Comedy-Horror-Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Comedy-Movie ", "Comedy-Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Comedy-Movie-Romance ", "Comedy-Movie-Romance-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Crime-Drama ", "Crime-Drama-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Crime-Drama-Murder-Mystery ", "Crime-Drama-Murder-Mystery-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Crime-Drama-Mystery ", "Crime-Drama-Mystery-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Current ", "Current-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Documentary ", "Documentary-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Documentary-Entertainment-Historical-Travel ", "Documentary-Entertainment-Historical-Travel-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Documentary-Historical ", "Documentary-Historical-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Documentary-Historical-Mini ", "Documentary-Historical-Mini-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Documentary-Historical-Mystery ", "Documentary-Historical-Mystery-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Documentary-Historical-War ", "Documentary-Historical-War-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Documentary-Medical-Science-Tech ", "Documentary-Medical-Science-Tech-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Documentary-Nature ", "Documentary-Nature-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Documentary-Science-Tech-Society-Culture ", "Documentary-Science-Tech-Society-Culture-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Documentary-Science-Tech-Travel ", "Documentary-Science-Tech-Travel-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Documentary-Society-Culture ", "Documentary-Society-Culture-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Drama ", "Drama-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Drama-Family-Movie ", "Drama-Family-Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Drama-Fantasy-Mystery ", "Drama-Fantasy-Mystery-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Drama-Historical ", "Drama-Historical-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Drama-Historical-Movie-Romance ", "Drama-Historical-Movie-Romance-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Drama-Horror-Movie-Mystery ", "Drama-Horror-Movie-Mystery-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Drama-Movie ", "Drama-Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Drama-Movie-Music-Romance ", "Drama-Movie-Music-Romance-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Drama-Movie-Mystery-Romance ", "Drama-Movie-Mystery-Romance-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Drama-Movie-Mystery-Sci-Fi ", "Drama-Movie-Mystery-Sci-Fi-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Drama-Movie-Romance ", "Drama-Movie-Romance-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Drama-Movie-Sci-Fi-Thriller ", "Drama-Movie-Sci-Fi-Thriller-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Drama-Movie-Thriller ", "Drama-Movie-Thriller-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Drama-Movie-Violence ", "Drama-Movie-Violence-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Drama-Murder-Mystery ", "Drama-Murder-Mystery-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Drama-Mystery ", "Drama-Mystery-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Drama-Mystery-Sci-Fi ", "Drama-Mystery-Sci-Fi-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Drama-Mystery-Violence ", "Drama-Mystery-Violence-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Drama-Romance-Sci-Fi ", "Drama-Romance-Sci-Fi-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Drama-Thriller ", "Drama-Thriller-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Education-Science ", "Education-Science-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Education-Science-Tech ", "Education-Science-Tech-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Entertainment ", "Entertainment-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Entertainment-Real ", "Entertainment-Real-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Horror-Movie ", "Horror-Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Infotainment-Real ", "Infotainment-Real-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Lifestyle-Medical-Science-Tech ", "Lifestyle-Medical-Science-Tech-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie ", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Mystery ", "Movie-Mystery-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Sci-Fi ", "Movie-Sci-Fi-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Sci-Fi-Thriller ", "Movie-Sci-Fi-Thriller-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Sci-Fi-Western ", "Movie-Sci-Fi-Western-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Thriller ", "Movie-Thriller-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Western ", "Movie-Western-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Sci-Fi ", "Sci-Fi-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Travel ", "Travel-")

	new_basename = Replace(new_basename, "-44_Adelaide", "", 1, -1, vbTextCompare)
	new_basename = Replace(new_basename, "_44_Adelaide", "", 1, -1, vbTextCompare)
	new_basename = Replace(new_basename, "-SBS_ONE_HD", "", 1, -1, vbTextCompare)
	new_basename = Replace(new_basename, "_SBS_ONE_HD", "", 1, -1, vbTextCompare)
	new_basename = Replace(new_basename, "-SBS_VICELAND_HD", "", 1, -1, vbTextCompare)
	new_basename = Replace(new_basename, "_SBS_VICELAND_HD", "", 1, -1, vbTextCompare)
	new_basename = Replace(new_basename, "-SBS_World_Movies", "", 1, -1, vbTextCompare)
	new_basename = Replace(new_basename, "_SBS_World_Movies", "", 1, -1, vbTextCompare)
	new_basename = Replace(new_basename, "-ABC_HD", "", 1, -1, vbTextCompare)
	new_basename = Replace(new_basename, "_ABC_HD", "", 1, -1, vbTextCompare)
	new_basename = Replace(new_basename, "-ABC_ME", "", 1, -1, vbTextCompare)
	new_basename = Replace(new_basename, "_ABC_ME", "", 1, -1, vbTextCompare)
	new_basename = Replace(new_basename, "-ABCKids-Kids", "", 1, -1, vbTextCompare)
	new_basename = Replace(new_basename, "_ABCKids-Kids", "", 1, -1, vbTextCompare)
	new_basename = Replace(new_basename, "-ABC-Kids", "", 1, -1, vbTextCompare)
	new_basename = Replace(new_basename, "_ABC-Kids", "", 1, -1, vbTextCompare)
	new_basename = Replace(new_basename, "-ABCKids", "", 1, -1, vbTextCompare)
	new_basename = Replace(new_basename, "_ABCKids", "", 1, -1, vbTextCompare)
	new_basename = Replace(new_basename, "-ABCComedy-Kids", "", 1, -1, vbTextCompare)
	new_basename = Replace(new_basename, "_ABCComedy-Kids", "", 1, -1, vbTextCompare)
	new_basename = Replace(new_basename, "-ABC_COMEDY", "", 1, -1, vbTextCompare)
	new_basename = Replace(new_basename, "_ABC_COMEDY", "", 1, -1, vbTextCompare)
	new_basename = Replace(new_basename, "-ABC_NEWS", "", 1, -1, vbTextCompare)
	new_basename = Replace(new_basename, "_ABC_NEWS", "", 1, -1, vbTextCompare)
	new_basename = Replace(new_basename, "-9Gem_HD_Adelaide", "", 1, -1, vbTextCompare)
	new_basename = Replace(new_basename, "_9Gem_HD_Adelaide", "", 1, -1, vbTextCompare)
	new_basename = Replace(new_basename, "-9Gem", "", 1, -1, vbTextCompare)
	new_basename = Replace(new_basename, "_9Gem", "", 1, -1, vbTextCompare)
	new_basename = Replace(new_basename, "-9HD_Adelaide", "", 1, -1, vbTextCompare)
	new_basename = Replace(new_basename, "_9HD_Adelaide", "", 1, -1, vbTextCompare)
	new_basename = Replace(new_basename, "-9HD", "", 1, -1, vbTextCompare)
	new_basename = Replace(new_basename, "_9HD", "", 1, -1, vbTextCompare)
	new_basename = Replace(new_basename, "-9Go-", "", 1, -1, vbTextCompare)
	new_basename = Replace(new_basename, "_9Go-", "", 1, -1, vbTextCompare)
	new_basename = Replace(new_basename, "-9Life", "", 1, -1, vbTextCompare)
	new_basename = Replace(new_basename, "_9Life", "", 1, -1, vbTextCompare)
	new_basename = Replace(new_basename, "-10_HD_Adelaide", "", 1, -1, vbTextCompare)
	new_basename = Replace(new_basename, "_10_HD_Adelaide", "", 1, -1, vbTextCompare)
	new_basename = Replace(new_basename, "-10_HD", "", 1, -1, vbTextCompare)
	new_basename = Replace(new_basename, "_10_HD", "", 1, -1, vbTextCompare)
	new_basename = Replace(new_basename, "-10_BOLD", "", 1, -1, vbTextCompare)
	new_basename = Replace(new_basename, "_10_BOLD", "", 1, -1, vbTextCompare)
	new_basename = Replace(new_basename, "-10_Peach", "", 1, -1, vbTextCompare)
	new_basename = Replace(new_basename, "_10_Peach", "", 1, -1, vbTextCompare)
	new_basename = Replace(new_basename, "-TEN_HD", "", 1, -1, vbTextCompare)
	new_basename = Replace(new_basename, "_TEN_HD", "", 1, -1, vbTextCompare)
	new_basename = Replace(new_basename, "-7TWO_Adelaide", "", 1, -1, vbTextCompare)
	new_basename = Replace(new_basename, "_7TWO_Adelaide", "", 1, -1, vbTextCompare)
	new_basename = Replace(new_basename, "-7flix_Adelaide", "", 1, -1, vbTextCompare)
	new_basename = Replace(new_basename, "_7flix_Adelaide", "", 1, -1, vbTextCompare)
	new_basename = Replace(new_basename, "-7HD_Adelaide", "", 1, -1, vbTextCompare)
	new_basename = Replace(new_basename, "_7HD_Adelaide", "", 1, -1, vbTextCompare)
	new_basename = Replace(new_basename, "-7HD", "", 1, -1, vbTextCompare)
	new_basename = Replace(new_basename, "_7HD", "", 1, -1, vbTextCompare)
	new_basename = Replace(new_basename, "-7mate_Adelaide", "", 1, -1, vbTextCompare)
	new_basename = Replace(new_basename, "_7mate_Adelaide", "", 1, -1, vbTextCompare)
	new_basename = Replace(new_basename, "-7mateHD", "", 1, -1, vbTextCompare)
	new_basename = Replace(new_basename, "_7mateHD", "", 1, -1, vbTextCompare)
	new_basename = Replace(new_basename, "-NITV", "", 1, -1, vbTextCompare)
	new_basename = Replace(new_basename, "_NITV", "", 1, -1, vbTextCompare)
	new_basename = Replace(new_basename, "-HD_Adelaide", "", 1, -1, vbTextCompare)
	new_basename = Replace(new_basename, "_HD_Adelaide", "", 1, -1, vbTextCompare)
	
	new_basename = Replace(new_basename, "_Adelaide.", ".", 1, -1, vbTextCompare)

	If instr(1, new_basename, "Movie-Movie", vbTextCompare) > 0 then new_basename = Replace(new_basename, "Movie-Movie", "Movie", 1, -1, vbTextCompare)
	If instr(1, new_basename, "Sci-Fi Movie", vbTextCompare) > 0 then new_basename = Replace(new_basename, "Sci-Fi Movie", "Sci-Fi-Movie", 1, -1, vbTextCompare)
	If instr(1, new_basename, "Movie-Sci-Fi-Movie", vbTextCompare) > 0 then new_basename = Replace(new_basename, "Movie-Sci-Fi-Movie", "Movie-Sci-Fi", 1, -1, vbTextCompare)
	If instr(1, new_basename, "Movie-Thriller-Movie", vbTextCompare) > 0 then new_basename = Replace(new_basename, "Movie-Thriller-Movie", "Movie-Thriller", 1, -1, vbTextCompare)
	If instr(1, new_basename, "Western-Movie", vbTextCompare) > 0 then new_basename = Replace(new_basename, "Western-Movie", "Western", 1, -1, vbTextCompare)
	If instr(1, new_basename, "Western Movie", vbTextCompare) > 0 then new_basename = Replace(new_basename, "Western Movie", "Western", 1, -1, vbTextCompare)
	If instr(1, new_basename, "Romance-Movie", vbTextCompare) > 0 then new_basename = Replace(new_basename, "Romance-Movie", "Romance", 1, -1, vbTextCompare)
	If instr(1, new_basename, "Romance Movie", vbTextCompare) > 0 then new_basename = Replace(new_basename, "Romance Movie", "Romance", 1, -1, vbTextCompare)
	If instr(1, new_basename, "Thriller-Movie", vbTextCompare) > 0 then new_basename = Replace(new_basename, "Thriller-Movie", "Thriller", 1, -1, vbTextCompare)
	If instr(1, new_basename, "Thriller Movie", vbTextCompare) > 0 then new_basename = Replace(new_basename, "Thriller Movie", "Thriller", 1, -1, vbTextCompare)

	If instr(1, new_basename, "-Movie Movie-", vbTextCompare) > 0 then new_basename = Replace(new_basename, "-Movie Movie-", "-Movie-", 1, -1, vbTextCompare)
	If instr(1, new_basename, "-Movie_Movie-", vbTextCompare) > 0 then new_basename = Replace(new_basename, "-Movie_Movie-", "-Movie-", 1, -1, vbTextCompare)
	If instr(1, new_basename, "-Movie-Movie-", vbTextCompare) > 0 then new_basename = Replace(new_basename, "-Movie-Movie-", "-Movie-", 1, -1, vbTextCompare)
	If instr(1, new_basename, "-Movie- ", vbTextCompare) > 0 then new_basename = Replace(new_basename, "-Movie- ", "-Movie-", 1, -1, vbTextCompare)

	If instr(1, new_basename, "Agatha_Christie-s_Poirot_", vbTextCompare) > 0 then new_basename = Replace(new_basename, "Agatha_Christie-s_Poirot_", "Agatha_Christie-s_Poirot-", 1, -1, vbTextCompare)
	If instr(1, new_basename, "Murder-Mystery_Agatha_Christie-s_Poirot_", vbTextCompare) > 0 then new_basename = Replace(new_basename, "Murder-Mystery_Agatha_Christie-s_Poirot_", "Agatha_Christie-s_Poirot-", 1, -1, vbTextCompare)
	If instr(1, new_basename, "Murder-Mystery_Agatha_Christie-s_Poirot-", vbTextCompare) > 0 then new_basename = Replace(new_basename, "Murder-Mystery_Agatha_Christie-s_Poirot-", "Agatha_Christie-s_Poirot-", 1, -1, vbTextCompare)
	If instr(1, new_basename, "Back_Roads_", vbTextCompare) > 0 then new_basename = Replace(new_basename, "Back_Roads_", "Back_Roads-", 1, -1, vbTextCompare)
	If instr(1, new_basename, "Catalyst_", vbTextCompare) > 0 then new_basename = Replace(new_basename, "Catalyst_", "Catalyst-", 1, -1, vbTextCompare)
	If instr(1, new_basename, "Tech_Catalyst_", vbTextCompare) > 0 then new_basename = Replace(new_basename, "Tech_Catalyst_", "Catalyst-", 1, -1, vbTextCompare)
	If instr(1, new_basename, "Tech_Catalyst-", vbTextCompare) > 0 then new_basename = Replace(new_basename, "Tech_Catalyst-", "Catalyst-", 1, -1, vbTextCompare)
	If instr(1, new_basename, "Berlin_Station_", vbTextCompare) > 0 then new_basename = Replace(new_basename, "Berlin_Station_", "Berlin_Station-", 1, -1, vbTextCompare)
	If instr(1, new_basename, "Foyle-s_War_", vbTextCompare) > 0 then new_basename = Replace(new_basename, "Foyle-s_War_", "Foyle-s_War-", 1, -1, vbTextCompare)
	If instr(1, new_basename, "Killing_Eve_", vbTextCompare) > 0 then new_basename = Replace(new_basename, "Killing_Eve_", "Killing_Eve-", 1, -1, vbTextCompare)
	If instr(1, new_basename, "Medici-Masters_Of_Florence_", vbTextCompare) > 0 then new_basename = Replace(new_basename, "Medici-Masters_Of_Florence_", "Medici-Masters_Of_Florence-", 1, -1, vbTextCompare)
	If instr(1, new_basename, "Mistresses_", vbTextCompare) > 0 then new_basename = Replace(new_basename, "Mistresses_", "Mistresses-", 1, -1, vbTextCompare)
	If instr(1, new_basename, "Orphan_Black_", vbTextCompare) > 0 then new_basename = Replace(new_basename, "Orphan_Black_", "Orphan_Black-", 1, -1, vbTextCompare)
	If instr(1, new_basename, "Plebs_", vbTextCompare) > 0 then new_basename = Replace(new_basename, "Plebs_", "Plebs-", 1, -1, vbTextCompare)
	If instr(1, new_basename, "Pope-The_Most_Powerful_Man_In_History_", vbTextCompare) > 0 then new_basename = Replace(new_basename, "Pope-The_Most_Powerful_Man_In_History_", "Pope-The_Most_Powerful_Man_In_History-", 1, -1, vbTextCompare)
	If instr(1, new_basename, "Scandal_", vbTextCompare) > 0 then new_basename = Replace(new_basename, "Scandal_", "Scandal-", 1, -1, vbTextCompare)
	If instr(1, new_basename, "Star_Trek_", vbTextCompare) > 0 then new_basename = Replace(new_basename, "Star_Trek_", "Star_Trek-", 1, -1, vbTextCompare)
	If instr(1, new_basename, "The.Expanse_", vbTextCompare) > 0 then new_basename = Replace(new_basename, "The.Expanse_", "The.Expanse-", 1, -1, vbTextCompare)
	If instr(1, new_basename, "The_Expanse_", vbTextCompare) > 0 then new_basename = Replace(new_basename, "The_Expanse_", "The_Expanse-", 1, -1, vbTextCompare)
	If instr(1, new_basename, "The_Girlfriend_Experience_", vbTextCompare) > 0 then new_basename = Replace(new_basename, "The_Girlfriend_Experience_", "The_Girlfriend_Experience-", 1, -1, vbTextCompare)
	If instr(1, new_basename, "The_Inspector_Lynley_Mysteries_", vbTextCompare) > 0 then new_basename = Replace(new_basename, "The_Inspector_Lynley_Mysteries_", "The_Inspector_Lynley_Mysteries-", 1, -1, vbTextCompare)
	If instr(1, new_basename, "The_IT_Crowd_", vbTextCompare) > 0 then new_basename = Replace(new_basename, "The_IT_Crowd_", "The_IT_Crowd-", 1, -1, vbTextCompare)
	If instr(1, new_basename, "the.it.crowd.", vbTextCompare) > 0 then new_basename = Replace(new_basename, "the.it.crowd.", "The_IT_Crowd-", 1, -1, vbTextCompare)
	If instr(1, new_basename, "The_Young_Pope_", vbTextCompare) > 0 then new_basename = Replace(new_basename, "The_Young_Pope_", "The_Young_Pope-", 1, -1, vbTextCompare)
	If instr(1, new_basename, "The_Two_Ronnies_", vbTextCompare) > 0 then new_basename = Replace(new_basename, "The_Two_Ronnies_", "The_Two_Ronnies-", 1, -1, vbTextCompare)
	If instr(1, new_basename, "The_Games_", vbTextCompare) > 0 then new_basename = Replace(new_basename, "The_Games_", "The_Games-", 1, -1, vbTextCompare)
	If instr(1, new_basename, "Utopia_", vbTextCompare) > 0 then new_basename = Replace(new_basename, "Utopia_", "Utopia-", 1, -1, vbTextCompare)
	If instr(1, new_basename, "The_X-Files_", vbTextCompare) > 0 then new_basename = Replace(new_basename, "The_X-Files_", "The_X-Files-", 1, -1, vbTextCompare)
	
	If instr(1, new_basename, "-Movie-", vbTextCompare) > 0 then ' move "movie" to the front of the string
		new_basename = "Movie-" & Replace(new_basename, "-Movie-", "-", 1, -1, vbTextCompare)
	end if

	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Adventure-Nature_", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Action-Adventure-Comedy-", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Action-Adventure-Drama_", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Adventure-Documentary-Travel_", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Adventure-Documentary-Travel-", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Action-Drama-Sci-Fi_", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Action-Drama_", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Adult-Crime-Drama-Society-Culture-", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Adult-Documentary-Real_Life-Society-Culture-", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Adventure-Cult-Sci-Fi_", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Adventure-Documentary-Drama-Sci-Fi-Science-", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Adventure-Entertainment-Travel-", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Arts-Culture-Documentary-Historical-Nature-Society-Culture-Travel-", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Arts-Culture-Documentary-Historical-Society-Culture-", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Arts-Culture-Entertainment-", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Biography-Documentary-Historical-", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Children-", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Comedy-", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Comedy_", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Cooking-", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Crime-Documentary-Historical-Mini_Series-Religion-Society-Culture_", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Crime-Documentary-Historical-Mini_Series-Religion-Society-Culture-", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Crime-Drama-Murder-Mystery-", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Crime-Drama-Mystery-", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Crime-Drama-Thriller_", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Crime-Drama-", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Crime-Drama_", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Crime-Mystery_", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Crime_", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Current-Affairs-Documentary_", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Documentary-Entertainment-Historical-Travel-", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Documentary-Entertainment-", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Documentary-Historical-", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Documentary-Historical-Mystery-", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Documentary-Historical-Religion-Society-Culture_", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Documentary-Historical-Science-Tech-Society-Culture-", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Documentary-Historical-Travel_", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Documentary-Historical-War-", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Documentary-Infotainment-", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Documentary-Medical-", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Documentary-Nature-Society-Culture-Travel-", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Documentary-Nature-", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Documentary-Real_Life-Society-Culture_", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Documentary-Science-Tech-Society-Culture-", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Documentary-Science-Tech-Travel-", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Documentary-Science-Tech_", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Documentary-Science-", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Documentary-Travel_", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Documentary-", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Drama-Murder-Mystery-", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Drama-Historical-Mystery-Sci-Fi-Thriller_", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Drama-Historical-", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Drama-Mystery-Sci-Fi-", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Drama-Mystery-", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Drama-Romance-Sci-Fi-", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Drama-Romance_", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Drama-Sci-Fi-Thriller_", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Drama-Thriller-", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Drama-", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Drama_", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Education-Science-Tech-", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Education-Science-", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Education-Science_", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Entertainment-", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Family_Movie-", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Historical-Travel-", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Historical-Travel_", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Historical-Infotainment-Lifestyle-Real_Life-Society-Culture-", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Historical-Infotainment-Lifestyle-Real_Life-Society-Culture_", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Lifestyle-Medical-Science-Tech-", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Action-Adventure-Animation-", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Action-Adventure-Comedy-Sci-Fi-", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Action-Adventure-Comedy-", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Action-Adventure-Crime-Drama-", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Action-Adventure-Crime-", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Action-Adventure-Drama-Romance-", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Action-Adventure-Drama-", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Action-Adventure-Family-", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Action-Adventure-Fantasy-", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Action-Adventure-Historical-Sci-Fi-", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Action-Adventure-Mystery-", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Action-Adventure-Sci-Fi-", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Action-Adventure-", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Action-Comedy-", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Action-Crime-", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Action-Drama-Historical-", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Action-Drama-", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Action-Drama-Sci-Fi-", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Action-Drama-Thriller-", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Action-Drama-Western-", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Action-Fantasy-Sci-Fi-", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Action-Fantasy-", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Action-Horror-Sci-Fi-Thriller-", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Action-Sci-Fi-Thriller-", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Action-Sci-Fi-", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Action-Thriller-", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Action-", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Adventure-Animation-", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Adventure-Biography-Drama-", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Adventure-Children-Family-Sci-Fi-", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Adventure-Comedy-Drama-Romance-", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Adventure-Comedy-Drama-", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Adventure-Drama-Fantasy-", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Adventure-Drama-Historical-Romance-", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Adventure-Drama-Sci-Fi-", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Adventure-Family-Fantasy-", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Adventure-Fantasy-", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Adventure-Sci-Fi-", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Adventure-", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Animation-Children-Comedy-", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Animation-Comedy-Family-", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Animation-", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Arts-Culture-Biography-Drama-Historical-Romance-", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Arts-Culture-Drama-War_Movie-", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Arts-Culture-Drama-", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Biography-Comedy-Drama-", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Biography-Documentary-", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Biography-Drama-Historical-", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Biography-Drama-Romance-", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Biography-Drama-", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Biography-", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Children-Family-", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Comedy-Crime-", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Comedy-Dance-Romance-", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Comedy-Drama-Family-", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Comedy-Drama-Fantasy-", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Comedy-Drama-Fantasy-Romance-", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Comedy-Drama-Fantasy-", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Comedy-Drama-Historical-", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Comedy-Drama-Music-", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Comedy-Drama-Musical-Romance-", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Comedy-Drama-Music_Movie-", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Comedy-Drama-Romance-", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Comedy-Drama-Sci-Fi-", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Comedy-Drama-", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Comedy-Family-Romance-", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Comedy-Family-", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Comedy-Fantasy-Musical-", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Comedy-Fantasy-Romance-", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Comedy-Historical-", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Comedy-Horror-Romance-", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Comedy-Horror-", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Comedy-Music_Movie-", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Comedy-Romance-", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Comedy-Sci-Fi-", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Comedy-War_Movie-", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Comedy-War-", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Comedy-", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Crime-Drama-Fantasy-Horror-", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Crime-Drama-Mystery_Movie-", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Crime-Drama-Mystery-", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Crime-Mystery-", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Crime-Mystery_Movie-", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Crime-Romance-Thriller-", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Crime-", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Drama-Historical-Romance-", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Drama-Horror-Mystery-", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Drama-Horror-Romance-", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Drama-Music-Romance-", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Drama-Mystery-Romance-", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Drama-Mystery-Sci-Fi-", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Drama-Mystery-Thriller-", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Drama-Romance-", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Drama-Sci-Fi-Thriller-", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Drama-Sci-Fi-", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Drama-Thriller-", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Drama-Violence-", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Drama-War_Movie-", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Drama-", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Family-", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Family-Fantasy-", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Family-Musical-", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Fantasy-Horror-", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Fantasy-Sci-Fi-", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Fantasy-", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Horror-", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Horror-Mystery-Sci-Fi-", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Horror-Mystery-Thriller-", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Horror-Sci-Fi-Thriller-", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Horror-Sci-Fi-", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Horror-Thriller-", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Horror-", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Musical-Romance-", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Musical-", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Music_Movie-", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Mystery-Sci-Fi-Thriller-", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Mystery-Sci-Fi-", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Romance-", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Romance-Western-", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Sci-Fi-Thriller-", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Sci-Fi-Western-", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Sci-Fi-", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Thriller-", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-Western-", "Movie-")

	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Extreme_Railways_Journeys_", "Extreme_Railways_Journeys-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Great_British_Railway_Journeys_", "Great_British_Railway_Journeys-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Great_American_Railroad_Journeys_", "Great_American_Railroad_Journeys-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Great_Continental_Railway_Journeys_", "Great_Continental_Railway_Journeys-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Great_Indian_Railway_Journeys_", "Great_Indian_Railway_Journeys-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Tony_Robinson-s_World_By_Rail_", "Tony_Robinson-s_World_By_Rail-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Railways_That_Built_Britain_", "Railways_That_Built_Britain-")

	' On second thought, replace Movie at the start with nothing ...
	'new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-", "Movie-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Movie-", "")

	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Action-Drama-Mini_Series-Sci-Fi-", "Sci-Fi-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Action-Drama-Mini_Series-Sci-Fi_", "Sci-Fi-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Adventure-Sci-Fi-", "Sci-Fi-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Adventure-Sci-Fi_", "Sci-Fi-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Adventure-Sci-Fi_", "Sci-Fi-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Adult-Documentary-Society-Culture_", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Adult-Documentary-Society-Culture-", "")
	
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Arts-Culture-Biography-Historical_", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Arts-Culture-Documentary_", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Arts-Culture-Entertainment_", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Arts-Culture-Biography-Romance-", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Arts-Culture-War_", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Arts-Culture-", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Biography-Cult-Religion-Society-Culture_", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Biography-Documentary_", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Biography-Historical_", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Biography-Mini_Series_", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Biography-Tech_", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Biography-", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Entertainment_", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Family-Fantasy_", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Family-Fantasy-", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Food-Wine-Lifestyle-Science_", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Food-Wine-Society-Culture_", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Historical-", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Historical_", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Historical-Mini_Series-Science-Tech_", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Horror-Mystery-Thriller_", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Infotainment-Real-Life_", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Infotainment-", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Infotainment_", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Lifestyle-", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Lifestyle_", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Lifestyle-Science-Tech_", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Lifestyle-Travel_", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Medical_", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Mini_Series-Thriller_", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Mini_Series-War", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Mini-Series-Science-Tech-Society-Culture-Travel_", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Mini-Series-Society-Culture_", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Murder-Mystery-", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Murder-Mystery_", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Music-Romance_Movie-", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Music-Romance_Movie_", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Mystery-", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Mystery_", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Nature-Society-Culture_", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Nature_", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "News-Science-Tech-", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "News-Science-Tech_", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "News_", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Real_Life-Society-Culture_", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Real_Life-Travel_", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Real_Life_", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Religion-Society-Culture_", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Religion-Thriller-", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Religion_", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Romance-Society-Culture_", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Romance_", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Romance-", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Science-Tech_", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Science-Tech-", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Society-Culture_", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Society-Culture-", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Science-Tech-Society-Culture_", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Science-Tech-Special_", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Science-Tech_", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Science_", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Sci-Fi-Thriller_", "Sci-Fi-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Action-Sci-Fi_", "Sci-Fi-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Sci-Fi-", "Sci-Fi-")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Sci-Fi-", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Sci-Fi_", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Society-Culture_", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Thriller-", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Thriller_", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Tech-Travel_", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Tech-Travel-", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Travel_", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Travel-", "")
	
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Agatha_Christie_", "Agatha_Christie_")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Agatha_Christie-", "Agatha_Christie_")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Agatha-Christie_", "Agatha_Christie_")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Agatha-Christie-", "Agatha_Christie_")
	
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Agatha_Christie_s_", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Agatha_Christie_s-", "")

	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Adventure_Documentary_Nature_", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Adventure_Documentary-Nature_", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Adventure-Documentary_Nature_", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Adventure-Documentary_Nature_", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Adventure_Documentary_Nature-", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Adventure_Documentary-Nature-", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Adventure-Documentary_Nature-", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Adventure-Documentary_Nature-", "")
	
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Adventure_Lifestyle_", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Adventure_Lifestyle-", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Adventure-Lifestyle_", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Adventure-Lifestyle-", "")
	
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Crime_Mystery_", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Crime_Mystery-", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Crime-Mystery_", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Crime-Mystery-", "")
	
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Chris_Tarrant_", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Chris_Tarrant-", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Chris-Tarrant_", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "Chris-Tarrant-", "")
	'new_basename = Replace(new_basename, "", "", 1, -1, vbTextCompare)

	new_basename = Replace(new_basename, ".h264.", ".", 1, -1, vbTextCompare)
	new_basename = Replace(new_basename, ".h265.", ".", 1, -1, vbTextCompare)
	new_basename = Replace(new_basename, ".aac.", ".", 1, -1, vbTextCompare)
	
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "-", "")
	new_basename = ReplaceStartStringCaseIndependent(new_basename, "_", "")
	' FINALLY replace all spaces in filenames (but not folder names !!!) with underscores
	new_basename = Replace(new_basename, " ", "_", 1, -1, vbTextCompare)
	new_basename = Replace(new_basename, "[", "_", 1, -1, vbTextCompare)
	new_basename = Replace(new_basename, "]", "_", 1, -1, vbTextCompare)
	new_basename = Replace(new_basename, "(", "_", 1, -1, vbTextCompare)
	new_basename = Replace(new_basename, ")", "_", 1, -1, vbTextCompare)
	
'----------------------------------------------------------------------------------------------------------------------------------
'----------------------------------------------------------------------------------------------------------------------------------
	for xyear = 2013 to 2050
		for xmonth = 01 to 12
			for xday = 01 to 31
				xDate = Digits4(xyear) & "-" & Digits2(xmonth) & "-" & Digits2(xday)
				new_basename = Move_Date_to_end(new_basename, xDate, ".")
			next
		next
	next
'----------------------------------------------------------------------------------------------------------------------------------
'----------------------------------------------------------------------------------------------------------------------------------
	
	new_name = f.parentfolder & "\" & new_basename & "." & fso.GetExtensionName(f.path)
	If new_basename <> xbasename then ' filename changed sp rename it
		rcount = rcount + 1 ' only set this if something replaced
		WScript.StdOut.WriteLine "vbs_rename_files: Rename <" & f.path & ">"
		WScript.StdOut.WriteLine "vbs_rename_files:     to <" & new_name & ">" 
		iErrNo = 0
		on error resume next
		fso.MoveFile f.path, new_name '???????????????????????????????????????????????????????????????????????????????????????????????
		iErrNo = Err.Number
		on error goto 0
		Err.Clear
		If iErrNo <> 0 then
			if iErrNo = 58 then ' Error 58 = File already exists
				iErrCount = 0
				while (iErrNo = 58 and iErrCount<=1000) ' only 1000 retries
					iErrCount = iErrCount + 1
					new_basename_2  = new_basename & "." & iErrCount
					new_name_2 = f.parentfolder & "\" & new_basename_2 & "." & fso.GetExtensionName(f.path)	
					WScript.StdOut.WriteLine "vbs_rename_files:  retry <" & new_name_2 & ">" 
					on error resume next
					fso.MoveFile f.path, new_name_2 '???????????????????????????????????????????????????????????????????????????????????????????????
					iErrNo = Err.Number
					on error goto 0
				wend
				if (iErrNo = 58 and iErrCount>1000) then
					WScript.StdOut.WriteLine "vbs_rename_files: vbscript error " & iErrNo & " - quit since done 1000 retries and sill a 58 File already exists" 
					Wscript.Quit iErrNo
				end if
				new_basename = new_basename_2
				new_name = new_name_2
			else
				WScript.StdOut.WriteLine "vbs_rename_files: vbscript error " & iErrNo & " - quit since a vbscript non-58 error was detected" 
				Wscript.Quit iErrNo
			end if
		end if
		on error goto 0
	end if
	
	''' if 1  = 0  then '???????????????????????????????????????????????????????????????????????????????????????????????
	If (new_basename <> xbasename) AND (LCase(ext) = LCase("bprj")) then ' always process .bprj files whether renamed or not
		bcount = bcount +1
		' open the file and replace the xbasename with new_basename in it
		Set xmlDoc = CreateObject("Microsoft.XMLDOM")
		xmlDoc.async = False
		on error resume next 
		'WScript.StdOut.WriteLine "vbs_rename_files: debug: about to xmlDoc.load file " & new_name
		sts = xmlDoc.load(new_name) '???????????????????????????????????????????????????????????????????????????????????????????????
		'sts = xmlDoc.load(f.path) '???????????????????????????????????????????????????????????????????????????????????????????????
		on error goto 0 
		If not sts Then
			Dim myErr
			Set myErr = xmlDoc.parseError
			WScript.StdOut.WriteLine "vbs_rename_files: Aborted. Failed to load XML doc .BPRJ file " & new_name
			WScript.StdOut.WriteLine "vbs_rename_files: XML error: " & myErr.errorCode & " : " & myErr.reason
			WScript.Quit 1
		End If
		'WScript.StdOut.WriteLine "vbs_rename_files: debug: loaded xml doc " & new_name
		'Locate the desired node. Note the use of XPATH instead of looping over all the child nodes.
		Set nNode = xmlDoc.selectsinglenode ("//VideoReDoProject/Filename")
		If nNode is Nothing then
			WScript.StdOut.WriteLine "vbs_rename_files: Aborted. Could not find XML node //VideoReDoProject/Filename in file " & new_name
			WScript.quit 1
		End If
		txtbefore = nNode.text
		' find the rightmost \ then replace everything at and it to the start with .\
		' if a \ doesn't exist, add .\ to the start
		i = InStrRev(txtbefore,"\",-1,vbTextCompare)
		if i > 0 then
			txtafter = ".\" & mid(txtbefore,i+1)
		else
			txtafter = ".\" & txtbefore
		end if
		' replace the xbasename portion of the string with the new_basename portion
		txtafter = Replace(txtafter, xbasename, new_basename, 1, -1, vbTextCompare)
		nNode.text = txtafter
		WScript.StdOut.WriteLine "vbs_rename_files: Update bprj xml node before:<" & txtbefore & ">"
		WScript.StdOut.WriteLine "vbs_rename_files:                       after:<" & nNode.text & ">"
		xmlDoc.save(new_name) '???????????????????????????????????????????????????????????????????????????????????????????????
		Set xmlDoc=nothing
	end if
	''' end if '???????????????????????????????????????????????????????????????????????????????????????????????
	
end if
end sub

Public Function Move_Date_to_end(theFilename, theDate, theLeadingReplaceCharacter)
	Dim txt, theLeadingSearchCharacter, newFilename
	Dim searchme(3)
	searchme(0)="-"
	searchme(1)="_"
	searchme(2)=" "
	searchme(3)="."
	newFilename = theFilename
	For Each theLeadingSearchCharacter In searchme
		txt = theLeadingSearchCharacter & theDate
		If instr(1, theFilename, txt, vbTextCompare) > 0 then ' found date withing the filename	
			If right(theFilename, len(theDate)) <> theDate then ' ensure it's not already at the end of the string
				newFilename = Replace(theFilename, txt, "", 1, -1, vbTextCompare) & theLeadingReplaceCharacter & theDate
				WScript.StdOut.WriteLine "vbs_rename_files: *** found filename with date not at end <" & txt & ">=<" & theFilename & "> ... Renaming to <" & newFilename & ">"
			End if
		End if
	Next
	Move_Date_to_end = newFilename
End Function

Public Function Digits2 (val)
	Digits2 = PadDigits(val, 2)
End Function
Public Function Digits4(val)
	Digits4 = PadDigits(val, 4)
End Function
Public Function PadDigits(val, digits)
  PadDigits = Right(String(digits,"0") & val, digits)
End Function

Public Function theDateTimeString()
  Dim dd, mm, yyyy, hh, nn, ss, ms
  Dim datevalue, timevalue, dtsnow, dtsvalue, secs_since_midnight, milliseconds
  'Store DateTimeStamp once.
  dtsnow = Now()
  secs_since_midnight = Timer
  milliseconds = Int((secs_since_midnight - Int(secs_since_midnight)) * 1000)
  'Individual date components
  dd = Right("00" & Day(dtsnow), 2)
  mm = Right("00" & Month(dtsnow), 2)
  yyyy = Year(dtsnow)
  hh = Right("00" & Hour(dtsnow), 2)
  nn = Right("00" & Minute(dtsnow), 2)
  ss = Right("00" & Second(dtsnow), 2)
  ms = Right("0000" & milliseconds, 4)
  theDateTimeString = yyyy & "." & mm & "." & dd & "." & hh & "." & nn & "." & ss & "." & ms
End Function

Public Function ReplaceStartStringCaseIndependent(theString, theSearchString, theReplaceString)
	dim L
	If lcase(left(theString,len(theSearchString))) = lcase(theSearchString) then
		L = len(theString) - len(theSearchString)
		'ReplaceStartStringCaseIndependent = Replace(theString, theSearchString, theReplaceString, 1, 1, vbTextCompare)
		ReplaceStartStringCaseIndependent = theReplaceString & right(theString,L)
	else
		ReplaceStartStringCaseIndependent = theString
	end if
End Function
Public Function ReplaceEndStringCaseIndependent(theString, theSearchString, theReplaceString)
	dim L
	If lcase(right(theString,len(theSearchString))) = lcase(theSearchString) then
		L = len(theString) - len(theSearchString)
		'ReplaceStartStringCaseIndependent = Replace(theString, theSearchString, theReplaceString, 1, 1, vbTextCompare)
		ReplaceEndStringCaseIndependent =  left(theString,L) & theReplaceString
	else
		ReplaceEndStringCaseIndependent = theString
	end if
End Function

'=======================================================================================================================================================

Public Sub Create_powershell_PS1_script(pFilename,the_PS1_Logfile)
' assume fso already created
Dim objFile, p_cmd
Set objFile = fso.CreateTextFile(pFilename,True) ' filename,overwrite,unicode
objFile.WriteLine("param ( [Parameter(Mandatory=$False)] [string]$Folder = ""T:\HDTV\VRDTVSP-Converted"" , [Parameter(Mandatory=$False)] [switch]$Recurse = $False , [Parameter(Mandatory=$False)] [string]$logFile = """ & the_PS1_Logfile & """)")
objFile.WriteLine("[console]::BufferWidth = 512  ")
objFile.WriteLine("echo 'Rename files to remove special characters and fix timestamps: *** Ignore the error: Exception setting ""BufferWidth"": ""The handle is invalid.""' >>""$logFile""")
objFile.WriteLine("#")
objFile.WriteLine("# Powershell script to rename files to remove all special characters and fix timestamps.")
objFile.WriteLine("# BEFORE this powershell script is invoked by the calling batch file, ensure the incoming folder has no trailing ""\""")
objFile.WriteLine("# OTHERWISE the trailing double-quote "" becomes 'escaped', thus everything on the commandline after it gets included in that parameter value.")
objFile.WriteLine("# eg")
objFile.WriteLine("#")
objFile.WriteLine("#set ""the_folder=G:\HDTV\000-TO-BE-PROCESSED""")
objFile.WriteLine("#set ""rightmost_character=!the_folder:~-1!""")
objFile.WriteLine("#if /I ""!rightmost_character!"" == ""\"" (set ""the_folder=!the_folder:~,-1!""")
objFile.WriteLine("#powershell -NoLogo -ExecutionPolicy Unrestricted -Sta -NonInteractive -WindowStyle Normal -File ""G:\HDTV\000-TO-BE-PROCESSED\something.ps1"" -Recurse:$False -Folder ""G:\HDTV\000-TO-BE-PROCESSED""")
objFile.WriteLine("#")
objFile.WriteLine("# The following is necessary if an incoming foldername string STILL has a trailing \ and DOS quoting does not work")
objFile.WriteLine("#echo ""Rename files to remove special characters and fix timestamps: Incoming Folder = '$Folder'"" >>""$logFile""")
objFile.WriteLine("if ($Folder.Substring($Folder.Length-2,2) -eq '"" ') {$Folder=$Folder -Replace ""..$""} # removes the last 2 characters")
objFile.WriteLine("if ($Folder.Substring($Folder.Length-2,2) -eq ' ""') {$Folder=$Folder -Replace ""..$""} # removes the last 2 characters")
objFile.WriteLine("if ($Folder.Substring($Folder.Length-2,2) -eq "" '"") {$Folder=$Folder -Replace ""..$""} # removes the last 2 characters")
objFile.WriteLine("if ($Folder.Substring($Folder.Length-1,1) -eq ""\"")  {$Folder=$Folder -Replace "".$""}  # removes the last 1 character")
objFile.WriteLine("if ($Folder.Substring(0,1) -eq ""'"" -And $Folder.Substring($Folder.Length-1,1) -eq ""'"") {$Folder=$Folder.Trim(""'"")} # removes the specified character from both ends of the string")
objFile.WriteLine("#echo ""Rename files to remove special characters: Fixed Folder = '$Folder'"" >>""$logFile""")
objFile.WriteLine("#echo ""Rename files to remove special characters: START in folder tree '$Folder' to remove special characters in every .mp4 filename by Matching them with a regex match in Powershell ..."" >>""$logFile""")
objFile.WriteLine("if ($Recurse) {")
objFile.WriteLine("	echo ""Rename files to remove special characters: RECURSE for tree '$Folder'"" >>""$logFile""")
objFile.WriteLine("	# note we add -Recurse and leave ""\*"" off of the folder name")
objFile.WriteLine("	$FileList = Get-ChildItem -Path ""$Folder"" -Recurse -File -Include '*.mp4'")
objFile.WriteLine("} else {")
objFile.WriteLine("	# note we add ""\*"" to the folder name")
objFile.WriteLine("	echo ""Rename files to remove special characters: NON RECURSE for only '$Folder'"" >>""$logFile""")
objFile.WriteLine("	$FileList = Get-ChildItem -Path ""$Folder\*"" -File -Include '*.mp4'")
objFile.WriteLine("}")
objFile.WriteLine("foreach ($FL_Item in $FileList) {")
objFile.WriteLine("	#$FL_Item.FullName")
objFile.WriteLine("	#$FL_Item | Select-Object Name,CreationTime,LastWriteTime")
objFile.WriteLine("	$old_full_filename=$FL_Item.FullName")
objFile.WriteLine("	$old_filename=$FL_Item.Name")
objFile.WriteLine("	# regex replace all successive matches by a single . since there is a trailing + in the regex.  means NOT the following.")
objFile.WriteLine("	$new_filename=$FL_Item.Name -replace '[^a-zA-Z0-9-_. ]+','.'")
objFile.WriteLine("	if($old_filename -ne $new_filename){")
objFile.WriteLine("		echo ""Renaming: '$old_full_filename' to '$new_filename'"" >>""$logFile""")
objFile.WriteLine("		$FL_Item | Rename-Item -NewName {$new_filename}")
objFile.WriteLine("	} else {")
objFile.WriteLine("		#echo ""Left alone: '$old_full_filename'"" >>""$logFile""")
objFile.WriteLine("	}")
objFile.WriteLine("}")
objFile.WriteLine("echo ""Rename files to remove special characters: FINISH  in folder tree '$Folder' to remove special characters in every .mp4 filename by Matching them with a regex match in Powershell ..."" >>""$logFile""")
objFile.WriteLine("# Now set the date-ctreated and date-modified")
objFile.WriteLine("#echo ""Set file date-time timestamps: START in folder tree '$Folder' ..."" >>""$logFile""") 
objFile.WriteLine("if ($Recurse) {")
objFile.WriteLine("	echo ""Set file date-time timestamps: RECURSE for tree '$Folder'"" >>""$logFile""")
objFile.WriteLine("	# note we add -Recurse and leave ""\*"" off of the folder name")
objFile.WriteLine("	$FileList = Get-ChildItem -Path ""$Folder"" -Recurse -File -Include '*.mp4'")
objFile.WriteLine("} else {")
objFile.WriteLine("	# note we add ""\*"" to the folder name")
objFile.WriteLine("	echo ""Set file date-time timestamps: NON RECURSE for only '$Folder'"" >>""$logFile""")
objFile.WriteLine("	$FileList = Get-ChildItem -Path ""$Folder\*"" -File -Include '*.mp4'")
objFile.WriteLine("}")
objFile.WriteLine("$DateFormat = ""yyyy-MM-dd""")
objFile.WriteLine("foreach ($FL_Item in $FileList) {")
objFile.WriteLine("	$fn = $FL_Item.FullName")
objFile.WriteLine("	#echo ""Processing Timestamp for 'fn'"" >>""$logFile""")
objFile.WriteLine("	# -match ")
objFile.WriteLine("	$ixxx = $FL_Item.BaseName -match '(?<DateString>\d{4}-\d{2}-\d{2})'")
objFile.WriteLine("	#echo ""Processing Timestamp for 'fn'"" >>""$logFile""")
objFile.WriteLine("	if($ixxx){")
objFile.WriteLine("		$DateString = $Matches.DateString")
objFile.WriteLine("		$date_from_file = [datetime]::ParseExact($DateString, $DateFormat, $Null)")
objFile.WriteLine("	} else {")
objFile.WriteLine("		$date_from_file = $FL_Item.CreationTime.Date # .Date removes the time component")
objFile.WriteLine("	}")
objFile.WriteLine("	$FL_Item.CreationTime = $date_from_file")
objFile.WriteLine("	$FL_Item.LastWriteTime = $date_from_file")
objFile.WriteLine("	$df=$date_from_file.ToString()")
objFile.WriteLine("	$cd=$FL_Item.CreationTime.ToString()")
objFile.WriteLine("	$lw=$FL_Item.LastWriteTime.ToString()")
objFile.WriteLine("	echo ""Set '$df' as Creation-date: '$cd' Modification-Date: '$lw' on '$fn'"" >>""$logFile""")
objFile.WriteLine("}")
objFile.WriteLine("echo ""Set file date-time timestamps: FINISH in folder tree '$Folder' ..."" >>""$logFile""")
objFile.WriteLine("## regex [^a-zA-Z0-9-_. ]+")
objFile.WriteLine("## the leading hat ^ character means NOT in any of the set, trailing + means any number of matches in the set")
objFile.WriteLine("## a-z")
objFile.WriteLine("## A-Z")
objFile.WriteLine("## 0-9")
objFile.WriteLine("## - underscore . space")
objFile.Close
Set objFile = Nothing
End Sub

'=======================================================================================================================================================