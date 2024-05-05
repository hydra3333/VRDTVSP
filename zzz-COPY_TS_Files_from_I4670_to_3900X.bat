@ECHO on
@setlocal ENABLEDELAYEDEXPANSION
@setlocal enableextensions

REM MOVE .TS Files from I4670 \\10.0.0.2\XFER to 3900X \\10.0.0.4
REM Assume they both run this exact same batch file

call :maketempheader
ECHO !COMPUTERNAME! !DATE! !TIME! tempheader="!tempheader!"

REM ***** PREVENT PC FROM GOING TO SLEEP *****
ECHO !COMPUTERNAME! !DATE! !TIME!
set iFile=!tempheader!-Insomnia.exe
ECHO copy "C:\SOFTWARE\Insomnia\32-bit\Insomnia.exe" ".\!iFile!"
copy "C:\SOFTWARE\Insomnia\32-bit\Insomnia.exe" ".\!iFile!"
start /min "!iFile!" ".\!iFile!"
ECHO !COMPUTERNAME! !DATE! !TIME!
REM ***** PREVENT PC FROM GOING TO SLEEP *****

REM DIR \\I4670\xfer\*.ts
REM DIR \\3900X\xfer\*.ts
REM DIR G:\HDTV\*.ts

REM wait for 3 minutes 3*60=180 seconds - until both computers are awake
ECHO !COMPUTERNAME! !DATE! !TIME!
TIMEOUT /T 180 > NUL

ECHO !COMPUTERNAME! !DATE! !TIME!
IF /I "!COMPUTERNAME!" == "3900X" (
   ECHO !COMPUTERNAME! !DATE! !TIME!
   DIR /S "\\I4670\xfer\*.TS" 
   ECHO Attempt to initiate the move on PC 3900X, moving .TS files from I4670 to 3900X
   REM https://ss64.com/nt/robocopy.html
   set RoboSwitches=/NP /LEV:1 /MOV /R:100 /W:10 /TS /FP /Z /J /COPY:DAT /TIMFIX /IS /IT /TEE /ETA /V
   set RoboFileset="*.TS"
   RoboCopy "\\I4670\xfer" "G:\HDTV" !RoboFileset! !RoboSwitches!
   REM RoboCopy "\\10.0.0.2\xfer" "\\10.0.0.4\xfer" !RoboFileset! !RoboSwitches!
   ECHO !COMPUTERNAME! !DATE! !TIME!
   DIR /S "\\I4670\xfer\*.TS" 
   ECHO !COMPUTERNAME! !DATE! !TIME!
) ELSE IF /I "!COMPUTERNAME!" == "I4670" (
   ECHO !COMPUTERNAME! !DATE! !TIME!
   DIR /S "G:\HDTV\*.TS"
   ECHO Waiting 4 hours = 240 Minutes - 14400 seconds - for the move process to finish. If it doesn't finish by then, so be it.
   ECHO !COMPUTERNAME! !DATE! !TIME!
   TIMEOUT /T 14400 > NUL
   DIR /S "G:\HDTV\*.TS"
   ECHO !COMPUTERNAME! !DATE! !TIME!
) ELSE (
   ECHO !COMPUTERNAME! !DATE! !TIME!
   ECHO "This is not running one one of PCs I4670,3900X. Nothing done.
   ECHO !COMPUTERNAME! !DATE! !TIME!
)
ECHO !COMPUTERNAME! !DATE! !TIME!

REM ***** ALLOW PC TO GO TO SLEEP AGAIN *****
ECHO !COMPUTERNAME! !DATE! !TIME!
REM "C:\000-PStools\pskill.exe" -t -nobanner "!iFile!"
taskkill /t /f /im "!iFile!"
del ".\!iFile!"
ECHO !COMPUTERNAME! !DATE! !TIME!
REM ***** ALLOW PC TO GO TO SLEEP AGAIN *****

REM pause
goto :eof

REM +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
REM +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
REM --- start set a temp header to date and time
:maketempheader
set "Datex=%DATE: =0%"
set yyyy=!Datex:~10,4!
set mm=!Datex:~7,2!
set dd=!Datex:~4,2!
set "Timex=%time: =0%"
set hh=!Timex:~0,2!
set min=!Timex:~3,2!
set ss=!Timex:~6,2!
set ms=!Timex:~9,2!
ECHO !DATE! !TIME! As at !yyyy!.!mm!.!dd!_!hh!.!min!.!ss!.!ms!  COMPUTERNAME="!COMPUTERNAME!"
set tempheader=!yyyy!.!mm!.!dd!.!hh!.!min!.!ss!.!ms!-!COMPUTERNAME!
REM --- end set a temp header to date and time
goto :eof
