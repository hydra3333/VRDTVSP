@ECHO on
@setlocal ENABLEDELAYEDEXPANSION
@setlocal enableextensions
REM
SET VRDTVSP_current_bat_name=!~dpnx0!
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
SET VRDTVSP_HDTV=G:\HDTV\
REM ---------Setup Folders ---------
REM
REM --------- resolve any relative paths into absolute paths --------- 
REM --------- ensure NO spaces between brackets and end of SET statement --------- 
REM this also puts a trailing "\" on the end
REM ECHO !DATE! !TIME! before VRDTVSP_HDTV="%VRDTVSP_HDTV%"
FOR /F %%i IN ("%VRDTVSP_HDTV%") DO (SET VRDTVSP_HDTV=%%~fi)
REM ECHO !DATE! !TIME! after VRDTVSP_HDTV="%VRDTVSP_HDTV%"
REM --------- resolve any relative paths into absolute paths --------- 

COPY /Y /B /Z /V /D ".\*.bat" "!VRDTVSP_HDTV!"
COPY /Y /B /Z /V /D ".\*.xml" "!VRDTVSP_HDTV!"
COPY /Y /B /Z /V /D ".\*.xml" "!VRDTVSP_HDTV!"
COPY /Y /B /Z /V /D ".\*.vbs" "!VRDTVSP_HDTV!"
COPY /Y /B /Z /V /D ".\VRD_profiles\*.xml" "!VRDTVSP_HDTV!"

COPY /Y /B /Z /V /D ".\copy_to_hdtv.bat" "!VRDTVSP_HDTV!"

pause
exit
