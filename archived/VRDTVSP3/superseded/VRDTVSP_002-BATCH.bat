@ECHO on
@setlocal ENABLEDELAYEDEXPANSION
@setlocal enableextensions
REM
SET vrdtvsp_current_bat_name=!~dpnx0!
REM
REM -- Header ---------------------------------------------------------------------
REM --- start set header to date and time, replacing spaces with zeroes
set "Datex=%DATE: =0%"
set yyyy=%Datex:~10,4%
set mm=%Datex:~7,2%
set dd=%Datex:~4,2%
set "Timex=%time: =0%"
set hh=%Timex:~0,2%
set min=%Timex:~3,2%
set ss=%Timex:~6,2%
set ms=%Timex:~9,2%
ECHO !DATE! !TIME! As at %yyyy%.%mm%.%dd%_%hh%.%min%.%ss%.%ms%  COMPUTERNAME="%COMPUTERNAME%"
set header=%yyyy%.%mm%.%dd%.%hh%.%min%.%ss%.%ms%-%COMPUTERNAME%
ECHO !DATE! !TIME! header="%header%"
REM --- end set header to date and time, replacing spaces with zeroes
REM -- Header ---------------------------------------------------------------------
REM
REM ---------Setup Folders --------- (ensure trailing backslash exists)
SET vrdtvsp_HDTV=G:\HDTV\
SET vrdtvsp_vbs_script=!vrdtvsp_HDTV!\vrdtvsp_002.vbs
SET capture_TS_Folder=!vrdtvsp_HDTV!
SET source_TS_Folder=!vrdtvsp_HDTV!\000-TO-BE-PROCESSED\
SET done_TS_Folder=!source_TS_Folder!VRDTVSP-done\
SET failed_conversion_TS_Folder=!source_TS_Folder!VRDTVSP-Failed-Conversion\
SET scratch_Folder=D:\VRDTVSP-SCRATCH\
SET destination_mp4_Folder=T:\HDTV\VRDTVSP-Converted\
REM ---------Setup Folders ---------
REM
REM --------- resolve any relative paths into absolute paths --------- 
REM --------- ensure NO spaces between brackets and end of SET statement --------- 
REM this also puts a trailing "\" on the end
REM ECHO !DATE! !TIME! before vrdtvsp_vbs_script="%vrdtvsp_vbs_script%"
FOR /F %%i IN ("%vrdtvsp_vbs_script%") DO (SET vrdtvsp_vbs_script=%%~fi)
REM ECHO !DATE! !TIME! after vrdtvsp_vbs_script="%vrdtvsp_vbs_script%"
REM ECHO !DATE! !TIME! before vrdtvsp_HDTV="%vrdtvsp_HDTV%"
FOR /F %%i IN ("%vrdtvsp_HDTV%") DO (SET vrdtvsp_HDTV=%%~fi)
REM ECHO !DATE! !TIME! after vrdtvsp_HDTV="%vrdtvsp_HDTV%"
REM ECHO !DATE! !TIME! before capture_TS_Folder="%capture_TS_Folder%"
FOR /F %%i IN ("%capture_TS_Folder%") DO (SET capture_TS_Folder=%%~fi)
REM ECHO !DATE! !TIME! after capture_TS_Folder="%capture_TS_Folder%"
REM ECHO !DATE! !TIME! before source_TS_Folder="%source_TS_Folder%"
FOR /F %%i IN ("%source_TS_Folder%") DO (SET source_TS_Folder=%%~fi)
REM ECHO !DATE! !TIME! after source_TS_Folder="%source_TS_Folder%"
REM ECHO !DATE! !TIME! before done_TS_Folder="%done_TS_Folder%"
FOR /F %%i IN ("%done_TS_Folder%") DO (SET done_TS_Folder=%%~fi)
REM ECHO !DATE! !TIME! after done_TS_Folder="%done_TS_Folder%"
REM ECHO !DATE! !TIME! before scratch_Folder="%scratch_Folder%"
FOR /F %%i IN ("%scratch_Folder%") DO (SET scratch_Folder=%%~fi)
REM ECHO !DATE! !TIME! after scratch_Folder="%scratch_Folder%"
REM ECHO !DATE! !TIME! before destination_mp4_Folder="%destination_mp4_Folder%"
FOR /F %%i IN ("%destination_mp4_Folder%") DO (SET destination_mp4_Folder=%%~fi)
REM ECHO !DATE! !TIME! after destination_mp4_Folder="%destination_mp4_Folder%"
REM ECHO !DATE! !TIME! before failed_conversion_TS_Folder="%failed_conversion_TS_Folder%"
FOR /F %%i IN ("%failed_conversion_TS_Folder%") DO (SET failed_conversion_TS_Folder=%%~fi)
REM ECHO !DATE! !TIME! after failed_conversion_TS_Folder="%failed_conversion_TS_Folder%"
REM --------- ensure NO spaces between brackets and end of SET statement --------- 
REM ---------Setup Folders ---------
REM
REM --------- setup vrdtvsp LOG file ----------------------------
REM base the filename on the running script using %~n0
SET vrdtvsp_LOG=!source_TS_Folder!%~n0-!header!-vrdtvsp_LOG.log
ECHO !DATE! !TIME! DEL /F "!vrdtvsp_LOG!"
DEL /F "!vrdtvsp_LOG!" >NUL 2>&1
REM --------- setup vrdtvsp LOG file ----------------------------
REM
REM --------- setup TEMP filename for use later in this script ----------------------------
SET tempfile=!scratch_Folder!%~n0-!header!-tempfile.txt
ECHO !DATE! !TIME! DEL /F "!tempfile!"
DEL /F "!tempfile!" >NUL 2>&1
REM --------- setup TEMP filename for use later in this script ----------------------------

REM =====================================================================================================================================
REM =====================================================================================================================================
REM =====================================================================================================================================
DEL /F "!vrdtvsp_LOG!" >NUL 2>&1
ECHO !DATE! !TIME! Started !vrdtvsp_current_bat_name! >> "!vrdtvsp_LOG!" 2>&1
MD "!capture_TS_Folder!" >NUL 2>&1
MD "!source_TS_Folder!" >NUL 2>&1
MD "!done_TS_Folder!" >NUL 2>&1
MD "!destination_mp4_Folder!" >NUL  2>&1
MD "!failed_conversion_TS_Folder!" >NUL  2>&1
MD "!scratch_Folder!" >NUL 2>&1 
SET vrdtvsp_CMD=cscript //nologo "!vrdtvsp_vbs_script!" ^
/DEBUG:False ^
/DEV:False ^
/capture_Folder:"!capture_TS_Folder!" ^
/source_Folder:"!source_TS_Folder!" ^
/done_Folder:"!done_TS_Folder!" ^
/destination_Folder:"!destination_mp4_Folder!" ^
/failed_Folder:"!failed_conversion_TS_Folder!" ^
/temp_path:"!scratch_Folder!" ^
/vrd_version_for_qsf:6 ^
/vrd_version_for_adscan:6 ^
/do_adscan:False ^
/do_audio_delay:True ^
/show_mediainfo:False
REM
ECHO !DATE! !TIME! ===================== >> "!vrdtvsp_LOG!" 2>&1
ECHO !vrdtvsp_CMD!
ECHO !vrdtvsp_CMD! >> "!vrdtvsp_LOG!" 2>&1
ECHO !DATE! !TIME! ===================== >> "!vrdtvsp_LOG!" 2>&1
!vrdtvsp_CMD! >> "!vrdtvsp_LOG!" 2>&1
SET EL=%ERRORLEVEL% >> "!vrdtvsp_LOG!" 2>&1
ECHO vrdtvsp EXIT ERRORLEVEL=!EL!
ECHO vrdtvsp EXIT ERRORLEVEL=!EL! >> "!vrdtvsp_LOG!" 2>&1
ECHO !DATE! !TIME! ===================== >> "!vrdtvsp_LOG!" 2>&1
ECHO !DATE! !TIME! Finished !vrdtvsp_current_bat_name! >> "!vrdtvsp_LOG!" 2>&1
ECHO !DATE! !TIME! ===================== >> "!vrdtvsp_LOG!" 2>&1
REM =====================================================================================================================================
REM =====================================================================================================================================
REM =====================================================================================================================================
REM
EXIT %EL%

REM
REM -------------------------------------------------------------------------------------------------------------------------------------
REM -------------------------------------------------------------------------------------------------------------------------------------
REM -------------------------------------------------------------------------------------------------------------------------------------
REM -------------------------------------------------------------------------------------------------------------------------------------
REM -------------------------------------------------------------------------------------------------------------------------------------
REM
:get_mediainfo_parameter
REM DO NOT SET @setlocal ENABLEDELAYEDEXPANSION
REM DO NOT SET @setlocal enableextensions
REM ensure no trailing spaces in any of the lines in this routine !!
set mi_Section=%~1
set mi_Parameter=%~2
set mi_Variable=%~3
set mi_Filename=%~4
set "mi_var="
DEL /F "!tempfile!" >NUL 2>&1
REM Note \r\n is Windows new-line, which is for the case of multiple audio streams, 
REM it outputs a result for each stream on a new line, the first stream being the first entry,
REM and the first audio stream should be the one we need. 
REM Set /p from an input file reads the first line.
"!mediainfoexe!" "--Inform=!mi_Section!;%%!mi_Parameter!%%\r\n" "!mi_Filename!" > "!tempfile!"
set /p mi_var=<"!tempfile!"
set !mi_Variable!=!mi_var!
REM ECHO !DATE! !TIME! "!mi_Variable!=!mi_var!" from "!mi_Section!" "!mi_Parameter!"
REM ECHO !DATE! !TIME! "!mi_Variable!=!mi_var!" from "!mi_Section!" "!mi_Parameter!" >> "!vrdtvsp_LOG!" 2>&1
DEL /F "!tempfile!" >NUL 2>&1
goto :eof
REM
REM -------------------------------------------------------------------------------------------------------------------------------------
REM -------------------------------------------------------------------------------------------------------------------------------------
REM -------------------------------------------------------------------------------------------------------------------------------------
REM -------------------------------------------------------------------------------------------------------------------------------------
REM -------------------------------------------------------------------------------------------------------------------------------------
REM
:get_mediainfo_parameter_legacy
REM DO NOT SET @setlocal ENABLEDELAYEDEXPANSION
REM DO NOT SET @setlocal enableextensions
REM ensure no trailing spaces in any of the lines in this routine !!
set mi_Section=%~1
set mi_Parameter=%~2
set mi_Variable=%~3
set mi_Filename=%~4
set "mi_var="
DEL /F "!tempfile!" >NUL 2>&1
REM Note \r\n is Windows new-line, which is for the case of multiple audio streams, 
REM it outputs a result for each stream on a new line, the first stream being the first entry,
REM and the first audio stream should be the one we need. 
REM Set /p from an input file reads the first line.
"!mediainfoexe!" --Legacy "--Inform=!mi_Section!;%%!mi_Parameter!%%\r\n" "!mi_Filename!" > "!tempfile!"
set /p mi_var=<"!tempfile!"
set !mi_Variable!=!mi_var!
REM ECHO !DATE! !TIME! "!mi_Variable!=!mi_var!" from Legacy "!mi_Section!" "!mi_Parameter!"
REM ECHO !DATE! !TIME! "!mi_Variable!=!mi_var!" from Legacy "!mi_Section!" "!mi_Parameter!" >> "!vrdtvsp_LOG!" 2>&1
DEL /F "!tempfile!" >NUL 2>&1
goto :eof
REM
REM -------------------------------------------------------------------------------------------------------------------------------------
REM -------------------------------------------------------------------------------------------------------------------------------------
REM -------------------------------------------------------------------------------------------------------------------------------------
REM -------------------------------------------------------------------------------------------------------------------------------------
REM -------------------------------------------------------------------------------------------------------------------------------------
REM
:get_ffprobe_video_stream_parameter
REM DO NOT SET @setlocal ENABLEDELAYEDEXPANSION
REM DO NOT SET @setlocal enableextensions
REM ensure no trailing spaces in any of the lines in this routine !!
set mi_Parameter=%~1
set mi_Variable=%~2
set mi_Filename=%~3
set "mi_var="
DEL /F "!tempfile!" >NUL 2>&1
REM Note \r\n is Windows new-line, which is for the case of multiple audio streams, 
REM it outputs a result for each stream on a new line, the first stream being the first entry,
REM and the first audio stream should be the one we need. 
REM Set /p from an input file reads the first line.
REM see if -probesize 5000M  makes any difference
"!ffprobeexe64!" -hide_banner -v quiet -select_streams v:0 -show_entries stream=!mi_Parameter! -of default=noprint_wrappers=1:nokey=1 "!mi_Filename!" > "!tempfile!"
set /p mi_var=<"!tempfile!"
set !mi_Variable!=!mi_var!
REM ECHO !DATE! !TIME! "!mi_Variable!=!mi_var!" from ffprobe "!mi_Parameter!"
REM ECHO !DATE! !TIME! "!mi_Variable!=!mi_var!" from ffprobe "!mi_Parameter!" >> "!vrdtvsp_LOG!" 2>&1
DEL /F "!tempfile!" >NUL 2>&1
goto :eof
REM
REM -------------------------------------------------------------------------------------------------------------------------------------
REM -------------------------------------------------------------------------------------------------------------------------------------
REM -------------------------------------------------------------------------------------------------------------------------------------
REM -------------------------------------------------------------------------------------------------------------------------------------
REM -------------------------------------------------------------------------------------------------------------------------------------
REM
:LoCase
:: Subroutine to convert a variable VALUE to all lower case.
:: The argument for this subroutine is the variable NAME.
FOR %%i IN ("A=a" "B=b" "C=c" "D=d" "E=e" "F=f" "G=g" "H=h" "I=i" "J=j" "K=k" "L=l" "M=m" "N=n" "O=o" "P=p" "Q=q" "R=r" "S=s" "T=t" "U=u" "V=v" "W=w" "X=x" "Y=y" "Z=z") DO CALL SET "%1=%%%1:%%~i%%"
goto :eof

:UpCase
:: Subroutine to convert a variable VALUE to all UPPER CASE.
:: The argument for this subroutine is the variable NAME.
FOR %%i IN ("a=A" "b=B" "c=C" "d=D" "e=E" "f=F" "g=G" "h=H" "i=I" "j=J" "k=K" "l=L" "m=M" "n=N" "o=O" "p=P" "q=Q" "r=R" "s=S" "t=T" "u=U" "v=V" "w=W" "x=X" "y=Y" "z=Z") DO CALL SET "%1=%%%1:%%~i%%"
goto :eof

:TCase
:: Subroutine to convert a variable VALUE to Title Case.
:: The argument for this subroutine is the variable NAME.
FOR %%i IN (" a= A" " b= B" " c= C" " d= D" " e= E" " f= F" " g= G" " h= H" " i= I" " j= J" " k= K" " l= L" " m= M" " n= N" " o= O" " p= P" " q= Q" " r= R" " s= S" " t= T" " u= U" " v= V" " w= W" " x= X" " y= Y" " z= Z") DO CALL SET "%1=%%%1:%%~i%%"
goto :eof
REM
REM -------------------------------------------------------------------------------------------------------------------------------------
REM -------------------------------------------------------------------------------------------------------------------------------------
REM -------------------------------------------------------------------------------------------------------------------------------------
REM -------------------------------------------------------------------------------------------------------------------------------------
REM -------------------------------------------------------------------------------------------------------------------------------------
REM
:calc_single_number_result
REM use VBS to evaluate an incoming formula strng which has no embedded special characters 
REM and yield a result which has no embedded special characters
REM eg   CALL :calc_single_number_result "Int((1+2+3+4+5+6)/10.0)" "return_variable_name"
set "Datey=%DATE: =0%"
set "Timey=%time: =0%"
set VTDTVS_eval_datetime=!Datey:~10,4!-!Datey:~7,2!-!Datey:~4,2!.!Timey:~0,2!.!Timey:~3,2!.!Timey:~6,2!.!Timey:~9,2!
set VTDTVS_eval_datetime=!VTDTVS_eval_datetime: =0!
set VTDTVS_eval_formula_vbs=!temp!\VTDTVS_eval_formula-!VTDTVS_eval_datetime!.vbs
set vrdtvsp_eval_formula=%~1
set vrdtvsp_eval_variable=%~2
set "vrdtvsp_eval_single_number_result="
REM echo 'cscript //nologo "!VTDTVS_eval_formula_vbs!" "!vrdtvsp_eval_formula!"'
echo wscript.echo eval(wscript.arguments(0))>"!VTDTVS_eval_formula_vbs!"
for /f %%A in ('cscript //nologo "!VTDTVS_eval_formula_vbs!" "!vrdtvsp_eval_formula!"') do (
    set "!vrdtvsp_eval_variable!=%%A"
    set "vrdtvsp_eval_single_number_result=%%A"
)
DEL /F "!VTDTVS_eval_formula_vbs!" >NUL 2>&1
REM echo "VTDTVS_eval_formula_vbs=!VTDTVS_eval_formula_vbs!"
REM echo "vrdtvsp_eval_variable=!vrdtvsp_eval_variable! vrdtvsp_eval_formula=!vrdtvsp_eval_formula! vrdtvsp_eval_single_number_result=!vrdtvsp_eval_single_number_result!"
goto :eof
REM -------------------------------------------------------------------------------------------------------------------------------------
REM -------------------------------------------------------------------------------------------------------------------------------------
REM -------------------------------------------------------------------------------------------------------------------------------------
REM -------------------------------------------------------------------------------------------------------------------------------------
REM -------------------------------------------------------------------------------------------------------------------------------------
REM
