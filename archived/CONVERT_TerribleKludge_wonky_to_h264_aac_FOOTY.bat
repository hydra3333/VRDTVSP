@ECHO ON
@setlocal ENABLEDELAYEDEXPANSION
@setlocal enableextensions

REM --------- set whether pause statements take effect ----------------------------
REM SET "xPAUSE=REM"
set "xPAUSE=PAUSE"
REM --------- set whether pause statements take effect ----------------------------

REM --------- setup paths and exe filenames ----------------------------

set "root=F:\CONVERT\"
set "vs_root=C:\SOFTWARE\Vapoursynth-x64\"
set "scratch_Folder=D:\VRDTVSP-SCRATCH\"

if /I NOT "!root:~-1!" == "\" (set "root=!root!\")
if /I NOT "!vs_root:~-1!" == "\" (set "vs_root=!vs_root!\")
set "root_nobackslash=%root:~0,-1%"
set "vs_root_nobackslash=%vs_root:~0,-1%"

set "vs_path_drive=!vs_root:~,2!"
set "vs_scripts_path=!vs_root!vs-scripts\"
set "vs_plugins_path=!vs_root!vs-plugins\"
set "vs_coreplugins_path=!vs_root!vs-coreplugins\"

if /I NOT "!vs_scripts_path:~-1!" == "\" (set "vs_scripts_path=!vs_scripts_path!\")
if /I NOT "!vs_plugins_path:~-1!" == "\" (set "vs_plugins_path=!vs_plugins_path!\")
if /I NOT "!vs_coreplugins_path:~-1!" == "\" (set "vs_coreplugins_path=!vs_coreplugins_path!\")

set "ffmpegexe64=!vs_root!ffmpeg.exe"
set "ffmpegexe64_OpenCL=!vs_root!ffmpeg_OpenCL.exe"
set "ffprobeexe64=!vs_root!ffprobe.exe"
set "mediainfoexe64=!vs_root!MediaInfo.exe"
set "dgindexNVexe64=!vs_root!DGIndex\DGIndexNV.exe"
set "vspipeexe64=!vs_root!VSPipe.exe"
set "py_exe=!vs_root!python.exe"
set "Insomniaexe64=C:\SOFTWARE\Insomnia\64-bit\Insomnia.exe"
REM --------- setup paths and exe filenames ----------------------------

REM -- Header ---------------------------------------------------------------------
REM set header to date and time and computer name
CALL :get_header_String "header"
REM -- Header ---------------------------------------------------------------------

REM -- Prepare the log file ---------------------------------------------------------------------
SET vrdlog=!root!%~n0-vrdlog-!header!.log
REM ECHO !DATE! !TIME! DEL /F "!vrdlog!"
DEL /F "!vrdlog!" >NUL 2>&1
REM -- Prepare the log file ---------------------------------------------------------------------

REM ---------Setup Folders --------- (ensure trailing backslash exists)
set "temp_Folder=!scratch_Folder!"

REM ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
REM ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
REM set "source_mp4_Folder=F:\mp4library\TEST\"
REM set "source_mp4_Folder=F:\mp4library\BigIdeas\"
REM set "source_mp4_Folder=F:\mp4library\BigIdeas\WhatMakesUsHappy\"
REM set "source_mp4_Folder=F:\mp4library\CharlieWalsh\"
REM set "source_mp4_Folder=F:\mp4library\ClassicDocumentaries\"
REM set "source_mp4_Folder=F:\mp4library\ClassicMovies\"
REM set "source_mp4_Folder=F:\mp4library\ClassicMovies\PENDING\"
REM set "source_mp4_Folder=F:\mp4library\Comedy\"
REM set "source_mp4_Folder=F:\mp4library\Documentaries\"
set "source_mp4_Folder=F:\mp4library\Footy\Pending\"
REM set "source_mp4_Folder=F:\mp4library\HomePics\"
REM set "source_mp4_Folder=F:\mp4library\MOVIES\"
REM set "source_mp4_Folder=F:\mp4library\MOVIES\Pending\"
REM set "source_mp4_Folder=F:\mp4library\oldMovies\"
REM set "source_mp4_Folder=F:\mp4library\oldSciFi\"
REM set "source_mp4_Folder=F:\mp4library\SciFi\PENDING\"
REM REM set "source_mp4_Folder=F:\mp4library\Series\"
if /I NOT "!source_mp4_Folder:~-1!" == "\" (set "source_mp4_Folder=!source_mp4_Folder!\")
REM ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
REM ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


set "destination_mp4_Folder=!source_mp4_Folder!converted\"
if /I NOT "!destination_mp4_Folder:~-1!" == "\" (set "destination_mp4_Folder=!destination_mp4_Folder!\")

set "done_avc_aac=!source_mp4_Folder!done_avc_aac\"
if /I NOT "!done_avc_aac:~-1!" == "\" (set "done_avc_aac=!done_avc_aac!\")

set "done_avc_mp3=!source_mp4_Folder!done_avc_mp3\"
if /I NOT "!done_avc_mp3:~-1!" == "\" (set "done_avc_mp3=!done_avc_mp3!\")

set "done_h265_aac=!source_mp4_Folder!done_h265_aac\"
if /I NOT "!done_h265_aac:~-1!" == "\" (set "done_h265_aac=!done_h265_aac!\")

set "done_h265_mp3=!source_mp4_Folder!done_h265_mp3\"
if /I NOT "!done_h265_mp3:~-1!" == "\" (set "done_h265_mp3=!done_h265_mp3!\")

set "done_bad=!source_mp4_Folder!done_bad\"
if /I NOT "!done_bad:~-1!" == "\" (set "done_bad=!done_bad!\")
REM

REM the trailing backslash ensures it detects it as a folder
if not exist "!source_mp4_Folder!" (mkdir "!source_mp4_Folder!")
if not exist "!destination_mp4_Folder!" (mkdir "!destination_mp4_Folder!")
if not exist "!scratch_Folder!" (mkdir "!scratch_Folder!")
if not exist "!temp_Folder!" (mkdir "!temp_Folder!")

if not exist "!done_avc_aac!" (mkdir "!done_avc_aac!")
if not exist "!done_avc_mp3!" (mkdir "!done_avc_mp3!")
if not exist "!done_h265_aac!" (mkdir "!done_h265_aac!")
if not exist "!done_h265_mp3!" (mkdir "!done_h265_mp3!")
if not exist "!done_bad!" (mkdir "!done_bad!")

REM --------- resolve any relative paths into absolute paths --------- 
REM --------- ensure no spaces between brackets and first/last parts of the the SET statement inside the DO --------- 
REM --------- this also puts a trailing "\" on the end ---------
REM ECHO !DATE! !TIME! before capture_TS_folder="%capture_TS_folder%" >> "!vrdlog!" 2>&1
REM ECHO !DATE! !TIME! before source_mp4_Folder="%source_mp4_Folder%" >> "!vrdlog!" 2>&1
FOR /F %%i IN ("!source_mp4_Folder!") DO (set "source_mp4_Folder=%%~fi")
REM ECHO !DATE! !TIME! after source_mp4_Folder="%source_mp4_Folder%" >> "!vrdlog!" 2>&1
REM ECHO !DATE! !TIME! before scratch_Folder="%scratch_Folder%" >> "!vrdlog!" 2>&1
FOR /F %%i IN ("!scratch_Folder!") DO (set "scratch_Folder=%%~fi")
REM ECHO !DATE! !TIME! after scratch_Folder="%scratch_Folder%" >> "!vrdlog!" 2>&1
REM ECHO !DATE! !TIME! before temp_Folder="%temp_Folder%" >> "!vrdlog!" 2>&1
FOR /F %%i IN ("!temp_Folder!") DO (set "temp_Folder=%%~fi")
REM ECHO !DATE! !TIME! after temp_Folder="%temp_Folder%" >> "!vrdlog!" 2>&1
REM ECHO !DATE! !TIME! before destination_mp4_Folder="%destination_mp4_Folder%" >> "!vrdlog!" 2>&1
FOR /F %%i IN ("!destination_mp4_Folder!") DO (set "destination_mp4_Folder=%%~fi")
REM ECHO !DATE! !TIME! after destination_mp4_Folder="%destination_mp4_Folder%" >> "!vrdlog!" 2>&1

REM ECHO !DATE! !TIME! before done_avc_aac="%done_avc_aac%" >> "!vrdlog!" 2>&1
FOR /F %%i IN ("!done_avc_aac!") DO (set "done_avc_aac=%%~fi")
REM ECHO !DATE! !TIME! after done_avc_aac="%done_avc_aac%" >> "!vrdlog!" 2>&1

REM ECHO !DATE! !TIME! before done_avc_mp3="%done_avc_mp3%" >> "!vrdlog!" 2>&1
FOR /F %%i IN ("!done_avc_mp3!") DO (set "done_avc_mp3=%%~fi")
REM ECHO !DATE! !TIME! after done_avc_mp3="%done_avc_mp3%" >> "!vrdlog!" 2>&1

REM ECHO !DATE! !TIME! before done_h265_aac="%done_h265_aac%" >> "!vrdlog!" 2>&1
FOR /F %%i IN ("!done_h265_aac!") DO (set "done_h265_aac=%%~fi")
REM ECHO !DATE! !TIME! after done_h265_aac="%done_h265_aac%" >> "!vrdlog!" 2>&1

REM ECHO !DATE! !TIME! before done_h265_mp3="%done_h265_mp3%" >> "!vrdlog!" 2>&1
FOR /F %%i IN ("!done_h265_mp3!") DO (set "done_h265_mp3=%%~fi")
REM ECHO !DATE! !TIME! after done_h265_mp3="%done_h265_mp3%" >> "!vrdlog!" 2>&1

REM ECHO !DATE! !TIME! before done_h265_mp3="%done_bad%" >> "!vrdlog!" 2>&1
FOR /F %%i IN ("!done_bad!") DO (set "done_bad=%%~fi")
REM ECHO !DATE! !TIME! after done_bad="%done_bad%" >> "!vrdlog!" 2>&1
REM ---------Setup Folders ---------

REM --------- setup LOG file and TEMP filenames ----------------------------
REM base the filenames on the running script filename using %~n0
set PSlog=!source_mp4_Folder!%~n0-!header!-PSlog.log
ECHO !DATE! !TIME! DEL /F "!PSlog!" >> "!vrdlog!" 2>&1
DEL /F "!PSlog!" >> "!vrdlog!" 2>&1

SET tempfile=!scratch_Folder!%~n0-!header!-temp.txt
ECHO !DATE! !TIME! DEL /F "!tempfile!" >> "!vrdlog!" 2>&1
DEL /F "!tempfile!" >> "!vrdlog!" 2>&1

SET tempfile_stderr=!scratch_Folder!%~n0-!header!-temp_stderr.txt
ECHO !DATE! !TIME! DEL /F "!tempfile!" >> "!vrdlog!" 2>&1
DEL /F "!tempfile!" >> "!vrdlog!" 2>&1

set "temp_cmd_file=!temp_Folder!temp_cmd_file.bat"
ECHO !DATE! !TIME! DEL /F "!temp_cmd_file!" >> "!vrdlog!" 2>&1
DEL /F "!temp_cmd_file!" >> "!vrdlog!" 2>&1
REM --------- setup LOG file and TEMP filenames ----------------------------

REM --------- setup .PY fully qualified filenames to pre-created files which rename and re-timestamp filenames etc ---------
set "Path_to_py_VRDTVSP_Calculate_Duration=!root!VRDTVSP_Calculate_Duration.py"
set "Path_to_py_VRDTVSP_Rename_Fix_Filenames_Move_Date_Adjust_Titles=!root!VRDTVSP_Rename_Fix_Filenames_Move_Date_Adjust_Titles.py"
set "Path_to_py_VRDTVSP_Modify_File_Date_Timestamps=!root!VRDTVSP_Modify_File_Date_Timestamps.py"
set "Path_to_py_VRDTVSP_Set_Mediainfo_Variables_for_first_stream_in_section=!root!VRDTVSP_Set_Mediainfo_Variables_for_first_stream_in_section.py"
set "Path_to_py_VRDTVSP_Set_ffprobe_Variables_for_first_stream_in_section=!root!VRDTVSP_Set_ffprobe_Variables_for_first_stream_in_section.py"
REM --------- setup .VBS and .PS1 and .PY fully qualified filenames to pre-created files which rename and re-timestamp filenames etc ---------

CALL :get_date_time_String "TOTAL_start_date_time"

REM --------- Start Initial Summarize ---------
ECHO !DATE! !TIME! ----------------------------------------------------------------------------------------------------------------------- >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! Start summary of Initialised paths etc ... >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! COMPUTERNAME="!COMPUTERNAME!"  header="!header!" >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! root="!root!" >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! root_nobackslash="!root_nobackslash!" >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! vs_root="!vs_root!" >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! vs_root_nobackslash="!vs_root_nobackslash!" >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! vs_path_drive="!vs_path_drive!" >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! vs_scripts_path="!vs_scripts_path!" >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! vs_plugins_path="!vs_plugins_path!" >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! vs_coreplugins_path="!vs_coreplugins_path!" >> "!vrdlog!" 2>&1

ECHO !DATE! !TIME! ffmpegexe64="!ffmpegexe64!" >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! ffmpegexe64_OpenCL="!ffmpegexe64_OpenCL!" >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! ffprobeexe64="!ffprobeexe64!" >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! mediainfoexe64="!mediainfoexe64!" >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! dgindexNVexe64="!dgindexNVexe64!" >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! vspipeexe64="!vspipeexe64!" >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! py_exe="!py_exe!" >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! Insomniaexe64="!Insomniaexe64!" >> "!vrdlog!" 2>&1

ECHO !DATE! !TIME! vrdlog="!vrdlog!" >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! source_mp4_Folder="!source_mp4_Folder!" >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! destination_mp4_Folder="!destination_mp4_Folder!" >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! done_avc_aac="!done_avc_aac!" >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! done_avc_mp3="!done_avc_mp3!" >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! done_h265_aac="!done_h265_aac!" >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! done_h265_mp3="!done_h265_mp3!" >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! done_bad="!done_bad!" >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! PSlog="!PSlog!" >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! tempfile="!tempfile!" >> "!vrdlog!" 2>&1

ECHO !DATE! !TIME! Path_to_py_VRDTVSP_Calculate_Duration="!Path_to_py_VRDTVSP_Calculate_Duration!" >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! Path_to_py_VRDTVSP_Rename_Fix_Filenames_Move_Date_Adjust_Titles="!Path_to_py_VRDTVSP_Rename_Fix_Filenames_Move_Date_Adjust_Titles!" >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! Path_to_py_VRDTVSP_Modify_File_Date_Timestamps="!Path_to_py_VRDTVSP_Modify_File_Date_Timestamps!" >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! Path_to_py_VRDTVSP_Set_Mediainfo_Variables_for_first_stream_in_section="!Path_to_py_VRDTVSP_Set_Mediainfo_Variables_for_first_stream_in_section!" >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! Path_to_py_VRDTVSP_Set_ffprobe_Variables_for_first_stream_in_section="!Path_to_py_VRDTVSP_Set_ffprobe_Variables_for_first_stream_in_section!" >> "!vrdlog!" 2>&1

ECHO !DATE! !TIME! End summary of Initialised paths etc ... >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! ----------------------------------------------------------------------------------------------------------------------- >> "!vrdlog!" 2>&1
REM --------- End Initial Summarize ---------

REM --------- SETUP FFMPEG DEVICE and OpenCL stuff and show helps ---------
ECHO !DATE! !TIME! ----------------------------------------------------------------------------------------------------------------------- >> "!vrdlog!" 2>&1
REM setup the OpenCL device strings 
set ff_ffmpeg_device=0.0
SET ff_OpenCL_device_init=-init_hw_device opencl=ocl:!ff_ffmpeg_device! -filter_hw_device ocl
REM ECHO !DATE! !TIME! ff_ffmpeg_device="!ff_ffmpeg_device!" >> "!vrdlog!" 2>&1
REM ECHO !DATE! !TIME! ff_OpenCL_device_init="!ff_OpenCL_device_init!" >> "!vrdlog!" 2>&1
REM Display ffmpeg features for the current ffmpeg.exe
REM ECHO !DATE! !TIME! 1. "!ffmpegexe64_OpenCL!" -hide_banner -v debug -init_hw_device list >> "!vrdlog!" 2>&1
REM "!ffmpegexe64_OpenCL!" -hide_banner -v debug -init_hw_device list >> "!vrdlog!" 2>&1
REM ECHO !DATE! !TIME! 2. "!ffmpegexe64_OpenCL!" -hide_banner -v debug -init_hw_device opencl >> "!vrdlog!" 2>&1
REM "!ffmpegexe64_OpenCL!" -hide_banner -v debug -init_hw_device opencl >> "!vrdlog!" 2>&1
REM ECHO !DATE! !TIME! 3. "!ffmpegexe64_OpenCL!" -hide_banner -v debug -init_hw_device opencl:!ff_ffmpeg_device!  >> "!vrdlog!" 2>&1
REM "!ffmpegexe64_OpenCL!" -hide_banner -v debug -init_hw_device opencl:!ff_ffmpeg_device!  >> "!vrdlog!" 2>&1
REM ECHO !DATE! !TIME! 4 "!ffmpegexe64!" -hide_banner -h encoder=h264_nvenc  >> "!vrdlog!" 2>&1
REM "!ffmpegexe64!" -hide_banner -h encoder=h264_nvenc  >> "!vrdlog!" 2>&1
REM ECHO !DATE! !TIME! 5 "!ffmpegexe64!" -hide_banner -h encoder=hevc_nvenc >> "!vrdlog!" 2>&1
REM "!ffmpegexe64!" -hide_banner -h encoder=hevc_nvenc >> "!vrdlog!" 2>&1
REM ECHO !DATE! !TIME! 6 "!ffmpegexe64!" -hide_banner -h filter=yadif  >> "!vrdlog!" 2>&1
REM "!ffmpegexe64!" -hide_banner -h filter=yadif  >> "!vrdlog!" 2>&1
REM ECHO !DATE! !TIME! 7 "!ffmpegexe64_OpenCL!" -hide_banner -h filter=unsharp_opencl  >> "!vrdlog!" 2>&1
REM "!ffmpegexe64_OpenCL!" -hide_banner -h filter=unsharp_opencl  >> "!vrdlog!" 2>&1
REM ECHO !DATE! !TIME! -------------------------------------- >> "!vrdlog!" 2>&1
REM ECHO !DATE! !TIME! 8 "!mediainfoexe64!" --help  >> "!vrdlog!" 2>&1
REM "!mediainfoexe64!" --help  >> "!vrdlog!" 2>&1
REM ECHO !DATE! !TIME! ---------------------------------------------------------------------------- >> "!vrdlog!" 2>&1
REM ECHO !DATE! !TIME! "!mediainfoexe64!" --Info-Parameters  >> "!vrdlog!" 2>&1
REM ECHO "!mediainfoexe64!" --Info-Parameters  >> "!vrdlog!" 2>&1
REM "!mediainfoexe64!" --Info-Parameters  >> "!vrdlog!" 2>&1
REM ECHO !DATE! !TIME! ---------------------------------------------------------------------------- >> "!vrdlog!" 2>&1
REM ECHO !DATE! !TIME! ---------------------------------------------------------------------------- >> "!vrdlog!" 2>&1
REM ECHO !DATE! !TIME! "!mediainfoexe64!"  --Legacy --Info-Parameters  >> "!vrdlog!" 2>&1
REM ECHO "!mediainfoexe64!"  --Legacy --Info-Parameters  >> "!vrdlog!" 2>&1
REM "!mediainfoexe64!"  --Legacy --Info-Parameters  >> "!vrdlog!" 2>&1
REM ECHO !DATE! !TIME! ---------------------------------------------------------------------------- >> "!vrdlog!" 2>&1
REM ECHO !DATE! !TIME! ----------------------------------------------------------------------------------------------------------------------- >> "!vrdlog!" 2>&1

REM ********** PREVENT PC FROM GOING TO SLEEP **********
ECHO !DATE! !TIME! ----------------------------------------------------------------------------------------------------------------------- >> "!vrdlog!" 2>&1
set iFile=Insomnia-!header!.exe
ECHO copy "C:\SOFTWARE\Insomnia\32-bit\Insomnia.exe" "!source_mp4_Folder!!iFile!" >> "!vrdlog!" 2>&1
copy "C:\SOFTWARE\Insomnia\32-bit\Insomnia.exe" "!source_mp4_Folder!!iFile!" >> "!vrdlog!" 2>&1
start /min "!iFile!" "!source_mp4_Folder!!iFile!"
ECHO !DATE! !TIME! ----------------------------------------------------------------------------------------------------------------------- >> "!vrdlog!" 2>&1
REM ********** PREVENT PC FROM GOING TO SLEEP **********

REM --------- Swap to source folder and save old folder using PUSHD ---------
ECHO !DATE! !TIME! ----------------------------------------------------------------------------------------------------------------------- >> "!vrdlog!" 2>&1
CD >> "!vrdlog!" 2>&1
ECHO PUSHD "!source_mp4_Folder!" >> "!vrdlog!" 2>&1
PUSHD "!source_mp4_Folder!" >> "!vrdlog!" 2>&1
CD >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! ----------------------------------------------------------------------------------------------------------------------- >> "!vrdlog!" 2>&1
REM --------- Swap to source folder and save old folder using PUSHD ---------

REM --------- Start Run the py to modify the filenames to enforce validity  i.e. no special characters ---------
ECHO !DATE! !TIME! ----------------------------------------------------------------------------------------------------------------------- >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! ********** >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! ********** >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! ********** >> "!vrdlog!" 2>&1
REM GRRR - sometimes left and right parentheses etc are seem in filenames of the media files ... 
REM Check if filenames are a "safe string" without special characters like !~`!@#$%^&*()+=[]{}\|:;'"<>,?/
REM If a filename isn't "safe" then rename it so it really is safe
REM Allowed only characters a-z,A-Z,0-9,-,_,.,space
REM
REM ENFORCE VALID FILENAMES on the source_mp4_Folder
CALL :get_date_time_String "start_date_time"
set "the_folder=!source_mp4_Folder!" 
CALL :make_double_backslashes_into_variable "!source_mp4_Folder!" "the_folder"
REM CALL :remove_trailing_backslash_into_variable "!the_folder!" "the_folder"
ECHO "!py_exe!" "!Path_to_py_VRDTVSP_Rename_Fix_Filenames_Move_Date_Adjust_Titles!" --folder "!the_folder!" --recurse >> "!vrdlog!" 2>&1
"!py_exe!" "!Path_to_py_VRDTVSP_Rename_Fix_Filenames_Move_Date_Adjust_Titles!" --folder "!the_folder!" --recurse >> "!vrdlog!" 2>&1
CALL :get_date_time_String "end_date_time"
ECHO "!py_exe!" "!Path_to_py_VRDTVSP_Calculate_Duration!" --start_datetime "!start_date_time!" --end_datetime "!end_date_time!" --prefix_id "VRDTVSP_Rename_Fix_Filenames_Move_Date_Adjust_Titles !the_folder!" >> "!vrdlog!" 2>&1
"!py_exe!" "!Path_to_py_VRDTVSP_Calculate_Duration!" --start_datetime "!start_date_time!" --end_datetime "!end_date_time!" --prefix_id "VRDTVSP_Rename_Fix_Filenames_Move_Date_Adjust_Titles !the_folder!" >> "!vrdlog!" 2>&1
REM
ECHO !DATE! !TIME! ********** >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! ********** >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! ********** >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! ----------------------------------------------------------------------------------------------------------------------- >> "!vrdlog!" 2>&1
REM --------- End Run the py to modify the filenames to enforce validity  i.e. no special characters ---------

REM ****************************************************************************************************************************************
REM ****************************************************************************************************************************************
:before_main_loop
ECHO !DATE! !TIME! ********** >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! ********** >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! ********** >> "!vrdlog!" 2>&1
CALL :get_date_time_String "loop_start_date_time"
for %%f in ("!source_mp4_Folder!*.mp4") do (
	CALL :get_date_time_String "iloop_start_date_time"
	ECHO !DATE! !TIME! START ------------------ %%f >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! Input file : "%%~f" >> "!vrdlog!" 2>&1
	REM check parmaters in the media file
	CALL :getvariables "%%f"
	REM if the media file passed tests in :getvariables then process the media file
	if exist "%%f" (CALL :convert_to_h264_aac "%%f")
	ECHO !DATE! !TIME! END ------------------ %%f >> "!vrdlog!" 2>&1
	CALL :get_date_time_String "iloop_end_date_time"
	ECHO "!py_exe!" "!Path_to_py_VRDTVSP_Calculate_Duration!" --start_datetime "!iloop_start_date_time!" --end_datetime "!iloop_end_date_time!" --prefix_id ":::::::::: iloop %%f " >> "!vrdlog!" 2>&1
	"!py_exe!" "!Path_to_py_VRDTVSP_Calculate_Duration!" --start_datetime "!iloop_start_date_time!" --end_datetime "!iloop_end_date_time!" --prefix_id ":::::::::: iloop %%f " >> "!vrdlog!" 2>&1
)
CALL :get_date_time_String "loop_end_date_time"
ECHO "!py_exe!" "!Path_to_py_VRDTVSP_Calculate_Duration!" --start_datetime "!loop_start_date_time!" --end_datetime "!loop_end_date_time!" --prefix_id "Loop_Processing_Files" >> "!vrdlog!" 2>&1
"!py_exe!" "!Path_to_py_VRDTVSP_Calculate_Duration!" --start_datetime "!loop_start_date_time!" --end_datetime "!loop_end_date_time!" --prefix_id "Loop_Processing_Files" >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! ********** >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! ********** >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! ********** >> "!vrdlog!" 2>&1
:after_main_loop
REM ****************************************************************************************************************************************
REM ****************************************************************************************************************************************

REM --------- Start Run the py to modify the filenames to enforce validity  i.e. no special characters ---------
ECHO !DATE! !TIME! ----------------------------------------------------------------------------------------------------------------------- >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! ********** >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! ********** >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! ********** >> "!vrdlog!" 2>&1
REM GRRR - sometimes left and right parentheses etc are seem in filenames of the media files ... 
REM Check if filenames are a "safe string" without special characters like !~`!@#$%^&*()+=[]{}\|:;'"<>,?/
REM If a filename isn't "safe" then rename it so it really is safe
REM Allowed only characters a-z,A-Z,0-9,-,_,.,space
REM
REM ENFORCE VALID FILENAMES on the destination_mp4_Folder
CALL :get_date_time_String "start_date_time"
set "the_folder=!destination_mp4_Folder!" 
CALL :make_double_backslashes_into_variable "!destination_mp4_Folder!" "the_folder"
REM CALL :remove_trailing_backslash_into_variable "!the_folder!" "the_folder"
ECHO "!py_exe!" "!Path_to_py_VRDTVSP_Rename_Fix_Filenames_Move_Date_Adjust_Titles!" --folder "!the_folder!" --recurse >> "!vrdlog!" 2>&1
"!py_exe!" "!Path_to_py_VRDTVSP_Rename_Fix_Filenames_Move_Date_Adjust_Titles!" --folder "!the_folder!" --recurse >> "!vrdlog!" 2>&1
CALL :get_date_time_String "end_date_time"
ECHO "!py_exe!" "!Path_to_py_VRDTVSP_Calculate_Duration!" --start_datetime "!start_date_time!" --end_datetime "!end_date_time!" --prefix_id "VRDTVSP_Rename_Fix_Filenames_Move_Date_Adjust_Titles !the_folder!" >> "!vrdlog!" 2>&1
"!py_exe!" "!Path_to_py_VRDTVSP_Calculate_Duration!" --start_datetime "!start_date_time!" --end_datetime "!end_date_time!" --prefix_id "VRDTVSP_Rename_Fix_Filenames_Move_Date_Adjust_Titles !the_folder!" >> "!vrdlog!" 2>&1
REM
CALL :get_date_time_String "loop_start_date_time"
ECHO !DATE! !TIME! ********** >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! ********** >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! ********** >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! ----------------------------------------------------------------------------------------------------------------------- >> "!vrdlog!" 2>&1
REM --------- End Run the py to modify the filenames to enforce validity  i.e. no special characters ---------


REM --------- Start Run the py to modify the filename timestamps filenames based on the date in the filename eg 2020-06-03 ---------
ECHO !DATE! !TIME! ----------------------------------------------------------------------------------------------------------------------- >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! ********** >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! ********** >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! ********** >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! ********** >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! --- START Modify DateCreated and DateModified Timestamps on "!destination_mp4_Folder!" >> "!vrdlog!" 2>&1

REM ECHO DEBUG: BEFORE:  >> "!vrdlog!" 2>&1
REM ECHO dir "!destination_mp4_Folder!" >> "!vrdlog!" 2>&1
REM dir "!destination_mp4_Folder!" >> "!vrdlog!" 2>&1
CALL :get_date_time_String "start_date_time"
set "the_folder=!destination_mp4_Folder!" 
CALL :make_double_backslashes_into_variable "!destination_mp4_Folder!" "the_folder"
REM CALL :remove_trailing_backslash_into_variable "!the_folder!" "the_folder"
ECHO "!py_exe!" "!Path_to_py_VRDTVSP_Modify_File_Date_Timestamps!" --folder "!the_folder!" --recurse >> "!vrdlog!" 2>&1
"!py_exe!" "!Path_to_py_VRDTVSP_Modify_File_Date_Timestamps!" --folder "!the_folder!" --recurse >> "!vrdlog!" 2>&1
REM ECHO DEBUG: AFTER: >> "!vrdlog!" 2>&1
REM ECHO dir "!destination_mp4_Folder!" >> "!vrdlog!" 2>&1
REM dir "!destination_mp4_Folder!" >> "!vrdlog!" 2>&1
CALL :get_date_time_String "end_date_time"
REM ECHO "!py_exe!" "!Path_to_py_VRDTVSP_Calculate_Duration!" --start_datetime "!start_date_time!" --end_datetime "!end_date_time!" --prefix_id "ReTimestamp" >> "!vrdlog!" 2>&1
"!py_exe!" "!Path_to_py_VRDTVSP_Calculate_Duration!" --start_datetime "!start_date_time!" --end_datetime "!end_date_time!" --prefix_id "ReTimestamp" >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! --- END Modify DateCreated and DateModified Timestamps on "!destination_mp4_Folder!" >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! ********** >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! ********** >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! ********** >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! ----------------------------------------------------------------------------------------------------------------------- >> "!vrdlog!" 2>&1
REM --------- End Run the py to modify the filename timestamps filenames based on the date in the filename eg 2020-06-03 ---------

REM ********** ALLOW PC TO GO TO SLEEP AGAIN **********
ECHO !DATE! !TIME! ----------------------------------------------------------------------------------------------------------------------- >> "!vrdlog!" 2>&1
REM "C:\000-PStools\pskill.exe" -t -nobanner "%iFile%" >> "!vrdlog!" 2>&1
ECHO taskkill /t /f /im "%iFile%" >> "!vrdlog!" 2>&1
taskkill /t /f /im "%iFile%" >> "!vrdlog!" 2>&1
DEL /F "!source_mp4_Folder!!iFile!" >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! ----------------------------------------------------------------------------------------------------------------------- >> "!vrdlog!" 2>&1
REM ********** ALLOW PC TO GO TO SLEEP AGAIN **********

REM --------- Swap back to original folder ---------
ECHO !DATE! !TIME! ----------------------------------------------------------------------------------------------------------------------- >> "!vrdlog!" 2>&1
CD >> "!vrdlog!" 2>&1
ECHO POPD >> "!vrdlog!" 2>&1
POPD >> "!vrdlog!" 2>&1
CD >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! ----------------------------------------------------------------------------------------------------------------------- >> "!vrdlog!" 2>&1
REM --------- Swap back to original folder ---------


CALL :get_date_time_String "TOTAL_end_date_time"
ECHO "!py_exe!" "!Path_to_py_VRDTVSP_Calculate_Duration!" --start_datetime "!TOTAL_start_date_time!" --end_datetime "!TOTAL_end_date_time!" --prefix_id "TOTAL" >> "!vrdlog!" 2>&1
"!py_exe!" "!Path_to_py_VRDTVSP_Calculate_Duration!" --start_datetime "!TOTAL_start_date_time!" --end_datetime "!TOTAL_end_date_time!" --prefix_id "TOTAL" >> "!vrdlog!" 2>&1

!xPAUSE!
goto :eof


REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM
:getvariables
REM parameter 1 = input filename (.mp4 file)
REM NOTES:
REM %~1  -  expands %1 removing any surrounding quotes (") 
REM %~f1  -  expands %1 to a fully qualified path name 
REM %~d1  -  expands %1 to a drive letter only 
REM %~p1  -  expands %1 to a path only 
REM %~n1  -  expands %1 to a file name only including the leading "."
REM %~x1  -  expands %1 to a file extension only 
REM %~s1  -  expanded path contains short names only 
REM %~a1  -  expands %1 to file attributes 
REM %~t1  -  expands %1 to date/time of file 
REM %~z1  -  expands %1 to size of file 
REM The modifiers can be combined to get compound results:
REM %~dp1  -  expands %1 to a drive letter and path only 
REM %~nx1  -  expands %1 to a file name and extension only 

set "the_Source_File=%~f1"
set "the_Target_Filename=%~n1"
set "the_Target_Filename=%the_Target_Filename:.aac=%"
set "the_Target_Filename=%the_Target_Filename:.mp3=%"
set "the_Target_Filename=%the_Target_Filename:.h264=%"
set "the_Target_Filename=%the_Target_Filename:.avc=%"
set "the_Target_Filename=%the_Target_Filename:.h265=%"
set "the_Target_Filename=%the_Target_Filename:.mp4=%"
set "the_Target_File=%destination_mp4_Folder%%the_Target_Filename%.mp4"
set "the_file_name_part=%~n1"

set "the_DGI_file=!scratch_Folder!!the_file_name_part!.dgi"
set "the_DGI_autolog=!scratch_Folder!!the_file_name_part!.log"
set "the_VPY_file=!scratch_Folder!!the_file_name_part!.vpy"

REM ECHO in :getvariables ... from :getvariables the_Source_File="!the_Source_File!" >> "!vrdlog!" 2>&1
REM ECHO in :getvariables ... from :getvariables the_file_name_part="!the_file_name_part!" >> "!vrdlog!" 2>&1
REM ECHO in :getvariables ... from :getvariables the_Target_Filename="!the_Target_Filename!" >> "!vrdlog!" 2>&1
REM ECHO in :getvariables ... from :getvariables the_Target_File="!the_Target_File!" >> "!vrdlog!" 2>&1
REM ECHO in :getvariables ... from :getvariables the_DGI_file="!the_DGI_file!" >> "!vrdlog!" 2>&1
REM ECHO in :getvariables ... from :getvariables the_DGI_autolog="!the_DGI_autolog!" >> "!vrdlog!" 2>&1
REM ECHO in :getvariables ... from :getvariables the_VPY_file="!the_VPY_file!" >> "!vrdlog!" 2>&1

REM !xPAUSE!

REM dispose of a LOT of variables, some of whih are large
CALL :clear_variables
REM :gather_variables_from_media_file P2 =	the global prefix to use for this gather, one of "SRC_", "QSF_" "TARGET_"
CALL :gather_variables_from_media_file "%~f1" "SRC_" 

REM display all SRC_ variables
REM ECHO +++++++++ >> "!vrdlog!" 2>&1
REM ECHO display all SRC_ variables >> "!vrdlog!" 2>&1
REM ECHO set SRC_ >> "!vrdlog!" 2>&1
REM set SRC_ >> "!vrdlog!" 2>&1
REM ECHO +++++++++ >> "!vrdlog!" 2>&1

IF /I "!SRC_calc_Video_Interlacement!" == "PROGRESSIVE" (
	ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
) ELSE IF /I "!SRC_calc_Video_Interlacement!" == "INTERLACED" (
	ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
) ELSE (
	set "check_QSF_failed=ERROR: mediainfo/ffmpeg data '!SRC_calc_Video_Interlacement!' yields neither PROGRESSIVE nor INTERLACED for '%~f1'"
	ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! !check_QSF_failed! >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
	REM !xPAUSE!
	REM exit 1
	call :move_to_bad "!the_Source_File!"
	goto :eof
)
REM
IF /I "!SRC_calc_Video_FieldFirst!" == "TFF" (
	ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
) ELSE IF /I "!SRC_calc_Video_FieldFirst!" == "BFF" (
	ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
) ELSE (
	set "check_QSF_failed=ERROR: mediainfo/ffmpeg processing '!SRC_calc_Video_FieldFirst!' yields neither 'TFF' nor 'BFF' field-first for '%~f1'"
	ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! !check_QSF_failed! >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
	REM !xPAUSE!
	REM exit 1
	call :move_to_bad "!the_Source_File!"
	goto :eof
)
REM
IF /I "!SRC_calc_Video_Encoding!" == "AVC" (
	set "qsf_extension=!extension_h264!"
) ELSE IF /I "!SRC_calc_Video_Encoding!" == "HEVC" (
	set "qsf_extension=!extension_hevc!"
) ELSE (
	set "check_QSF_failed=ERROR: mediainfo format !SRC_calc_Video_Encoding! neither 'AVC' nor 'MPEG2' for '%~f1'"
	ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! !check_QSF_failed! >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
	REM !xPAUSE!
	REM exit 1
	call :move_to_bad "!the_Source_File!"
	goto :eof
)

REM
REM Now claculate variables used in the FFMPEG encoding qsf -> destination0mp4
REM

REM
REM Use the max of these actual video bitrates (not the "overall" which includes audio bitrate) 
REM		SRC_MI_V_BitRate
set /a SRC_calc_Video_Max_Bitrate=0
if !SRC_MI_V_BitRate! gtr !SRC_calc_Video_Max_Bitrate! set /a SRC_calc_Video_Max_Bitrate=!SRC_MI_V_BitRate!
REM 	' NOTE:	After testing, it has been found that ffprobe can mis-report bitrates in the QSF'd file by about double.
REM 	'		Although mediainfo and the "QSF log" values are reasonably close, testing shows ffprobe gets it more "right" when encoding.
REM 	'		Although hopefully correct, this can result in a much lower transcoded filesizes than the originals.

IF /I "!SRC_calc_Video_Encoding!" == "AVC" (
	REM CALCULATE H.264 TARGET BITRATES FROM THE INCOMING H.264 BITRATE
	set /a "X_bitrate_05percent=!SRC_calc_Video_Max_Bitrate! / 20"
	set /a "X_bitrate_10percent=!SRC_calc_Video_Max_Bitrate! / 10"
	set /a "X_bitrate_20percent=!SRC_calc_Video_Max_Bitrate! / 5"
	set /a "X_bitrate_25percent=!SRC_calc_Video_Max_Bitrate! / 4"
	set /a "X_bitrate_50percent=!SRC_calc_Video_Max_Bitrate! / 2"
	REM ffmpeg nvenc typically seems to undershoot the target bitrate, so bump it up.
	set /a "FFMPEG_V_Target_BitRate=!SRC_calc_Video_Max_Bitrate! + !X_bitrate_05percent!"
	set /a "extra_bitrate_05percent=!FFMPEG_V_Target_BitRate! / 20"
	set /a "extra_bitrate_10percent=!FFMPEG_V_Target_BitRate! / 10"
	set /a "extra_bitrate_20percent=!FFMPEG_V_Target_BitRate! / 5"
	set /a "extra_bitrate_25percent=!FFMPEG_V_Target_BitRate! / 4"
	set /a "extra_bitrate_50percent=!FFMPEG_V_Target_BitRate! / 2"
	set /a "FFMPEG_V_Target_Minimum_BitRate=!extra_bitrate_20percent!"
	set /a "FFMPEG_V_Target_Maximum_BitRate=!FFMPEG_V_Target_BitRate! * 2"
	set /a "FFMPEG_V_Target_BufSize=!FFMPEG_V_Target_BitRate! * 2"
	ECHO !DATE! !TIME! Bitrates are calculated from the max AVC bitrate seen. >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! "AVC"      SRC_calc_Video_Max_Bitrate=!SRC_calc_Video_Max_Bitrate! >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! "AVC" FFMPEG_V_Target_Minimum_BitRate=!FFMPEG_V_Target_Minimum_BitRate! >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! "AVC"         FFMPEG_V_Target_BitRate=!FFMPEG_V_Target_BitRate! >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! "AVC" FFMPEG_V_Target_Maximum_BitRate=!FFMPEG_V_Target_Maximum_BitRate! >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! "AVC"         FFMPEG_V_Target_BufSize=!FFMPEG_V_Target_BufSize! >> "!vrdlog!" 2>&1
) ELSE IF /I "!SRC_calc_Video_Encoding!" == "HEVC" (
	REM CALCULATE H.264 TARGET BITRATES FROM THE INCOMING H.265 BITRATE
	set /a "X_bitrate_05percent=!SRC_calc_Video_Max_Bitrate! / 20"
	set /a "X_bitrate_10percent=!SRC_calc_Video_Max_Bitrate! / 10"
	set /a "X_bitrate_20percent=!SRC_calc_Video_Max_Bitrate! / 5"
	set /a "X_bitrate_25percent=!SRC_calc_Video_Max_Bitrate! / 4"
	set /a "X_bitrate_50percent=!SRC_calc_Video_Max_Bitrate! / 2"
	REM ffmpeg nvenc typically seems to undershoot the target bitrate, so bump it up.
	set /a "FFMPEG_V_Target_BitRate=!SRC_calc_Video_Max_Bitrate! + !X_bitrate_25percent!"
	set /a "extra_bitrate_05percent=!FFMPEG_V_Target_BitRate! / 20"
	set /a "extra_bitrate_10percent=!FFMPEG_V_Target_BitRate! / 10"
	set /a "extra_bitrate_20percent=!FFMPEG_V_Target_BitRate! / 5"
	set /a "extra_bitrate_25percent=!FFMPEG_V_Target_BitRate! / 4"
	set /a "extra_bitrate_50percent=!FFMPEG_V_Target_BitRate! / 2"
	set /a "FFMPEG_V_Target_Minimum_BitRate=!extra_bitrate_20percent!"
	set /a "FFMPEG_V_Target_Maximum_BitRate=!FFMPEG_V_Target_BitRate! * 2"
	set /a "FFMPEG_V_Target_BufSize=!FFMPEG_V_Target_BitRate! * 2"
	ECHO !DATE! !TIME! Bitrates are calculated from the max HEVC bitrate seen. >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! "AVC"      SRC_calc_Video_Max_Bitrate=!SRC_calc_Video_Max_Bitrate! >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! "AVC" FFMPEG_V_Target_Minimum_BitRate=!FFMPEG_V_Target_Minimum_BitRate! >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! "AVC"         FFMPEG_V_Target_BitRate=!FFMPEG_V_Target_BitRate! >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! "AVC" FFMPEG_V_Target_Maximum_BitRate=!FFMPEG_V_Target_Maximum_BitRate! >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! "AVC"         FFMPEG_V_Target_BufSize=!FFMPEG_V_Target_BufSize! >> "!vrdlog!" 2>&1
) ELSE (
	ECHO !DATE! !TIME! ERROR: UNKNOWN SRC_calc_Video_Encoding="!SRC_calc_Video_Encoding!" to base the transcode calculations on. MUST be AVC or HEVC >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! ERROR: UNKNOWN SRC_calc_Video_Encoding="!SRC_calc_Video_Encoding!" to base the transcode calculations on. MUST be AVC or HEVC >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! ERROR: UNKNOWN SRC_calc_Video_Encoding="!SRC_calc_Video_Encoding!" to base the transcode calculations on. MUST be AVC or HEVC >> "!vrdlog!" 2>&1
	REM !xPAUSE!
	REM exit 1
	call :move_to_bad "!the_Source_File!"
	goto :eof
)

IF /I "!SRC_calc_Video_Interlacement!" == "PROGRESSIVE" (
	REM set for no deinterlace
	set "FFMPEG_V_dg_deinterlace=0"
) ELSE IF /I "!SRC_calc_Video_Interlacement!" == "INTERLACED" (
	REM set for normal single framerate deinterlace
	set "FFMPEG_V_dg_deinterlace=1"
) ELSE (
	set "check_QSF_failed=ERROR: UNKNOWN SRC_calc_Video_Interlacement="!SRC_calc_Video_Interlacement!" to base transcode calculations on, for '%~f1'"
	ECHO !DATE! !TIME! !check_QSF_failed! >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! the_Source_File="!the_Source_File!" >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
	CALL :declare_FAILED "%~f1"
	CALL :get_date_time_String "end_date_time_QSF"
	REM ECHO "!py_exe!" "!Path_to_py_VRDTVSP_Calculate_Duration!" --start_datetime "!start_date_time_QSF!" --end_datetime "!end_date_time_QSF!" --prefix_id "QSF itself" >> "!vrdlog!" 2>&1
	"!py_exe!" "!Path_to_py_VRDTVSP_Calculate_Duration!" --start_datetime "!start_date_time_QSF!" --end_datetime "!end_date_time_QSF!" --prefix_id "QSF itself" >> "!vrdlog!" 2>&1
	REM !xPAUSE!
	REM exit 1
	call :move_to_bad "!the_Source_File!"
	goto :eof
)

IF /I "!SRC_calc_Video_FieldFirst!" == "TFF" (
	set "FFMPEG_V_dg_use_TFF=True"
) ELSE IF /I "!SRC_calc_Video_FieldFirst!" == "BFF" (
	set "FFMPEG_V_dg_use_TFF=False"
) ELSE (
	set "check_QSF_failed=ERROR: UNKNOWN SRC_calc_Video_FieldFirst="!SRC_calc_Video_FieldFirst!" to base transcode calculations on, for '%~f1'"
	ECHO !DATE! !TIME! !check_QSF_failed! >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! the_Source_File="!the_Source_File!" >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
	CALL :declare_FAILED "%~f1"
	CALL :get_date_time_String "end_date_time_QSF"
	REM ECHO "!py_exe!" "!Path_to_py_VRDTVSP_Calculate_Duration!" --start_datetime "!start_date_time_QSF!" --end_datetime "!end_date_time_QSF!" --prefix_id "QSF itself" >> "!vrdlog!" 2>&1
	"!py_exe!" "!Path_to_py_VRDTVSP_Calculate_Duration!" --start_datetime "!start_date_time_QSF!" --end_datetime "!end_date_time_QSF!" --prefix_id "QSF itself" >> "!vrdlog!" 2>&1
	REM !xPAUSE!
	REM exit 1
	call :move_to_bad "!the_Source_File!"
	goto :eof
)

ECHO !DATE! !TIME! "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! NOTE: After testing, it has been found that ffprobe can mis-report bitrates in the QSF'd file by about double. >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME!       Although mediainfo and the "QSF log" values are reasonably close, testing shows ffprobe gets it more "right" when encoding. >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME!       Although hopefully correct, this can result in a much lower transcoded filesizes than the originals. >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME!       For now, accept what we PROPOSE on whether to "Up" the CQ from 0 to 24. >> "!vrdlog!" 2>&1
REM Default CQ options, default to cq0
set "FFMPEG_V_cq0=-cq:v 0"
set "FFMPEG_V_cq24=-cq:v 24 -qmin 16 -qmax 48"
set "FFMPEG_V_PROPOSED_x_cq_options=!FFMPEG_V_cq0!"
set "FFMPEG_V_final_cq_options=!FFMPEG_V_cq0!"
ECHO !DATE! !TIME! "Initial Default FFMPEG_V_final_cq_options=!FFMPEG_V_final_cq_options!" >> "!vrdlog!" 2>&1

REM
REM FOR AVC INPUT FILES ONLY, calculate the CQ to use (default to CQ0)
REM *** NOTE 2024.03.30 WE HAVE CHANGED THIS TO JUST A QUICK RAW TEST FOR LOW TARGET BITRATE ***
REM	From:	There are special cases where Mediainfo detects a lower bitrate than FFPROBE
REM			and MediaInfo is likely right ... however FFPROBE is what we want it to be.
REM			When this happens, if we just leave the bitrate CQ as-is then ffmpeg just undershoots 
REM			even though we specify the higher bitrate of FFPROBE.
REM			If we detect such a case, change to CQ24 instead of CQ0 and leave the 
REM			specified bitrate unchanged ... which "should" fix it up.
REM
IF /I "!SRC_calc_Video_Encoding!" == "AVC" (
	ECHO !DATE! !TIME! "????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????" >> "!vrdlog!" 2>&1
	ECHO Example table of values and actions >> "!vrdlog!" 2>&1
	ECHO	MI		FF		INCOMING	ACTION >> "!vrdlog!" 2>&1
	ECHO	0		0		5Mb			set to CQ 0 >> "!vrdlog!" 2>&1
	ECHO	0		1.5Mb	1.5Mb		set to CQ 24 >> "!vrdlog!" 2>&1
	ECHO	0		4Mb		4Mb			set to CQ 0 >> "!vrdlog!" 2>&1
	ECHO	1.5Mb	0		1.5Mb		set to CQ 24 >> "!vrdlog!" 2>&1
	ECHO	1.5Mb 	1.5Mb	1.5Mb		set to CQ 24 >> "!vrdlog!" 2>&1
	ECHO	1.5Mb	4Mb		4Mb			set to CQ 24 *** this one >> "!vrdlog!" 2>&1
	ECHO	4Mb		0		4Mb			set to CQ 0 >> "!vrdlog!" 2>&1
	ECHO	4Mb		1.5Mb	4Mb			set to CQ 0 >> "!vrdlog!" 2>&1
	ECHO	4Mb		5Mb		5Mb			set to CQ 0 >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! "????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????" >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! "Calculating whether to Bump CQ from 0 to 24 ..." >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! "FFMPEG_V_Target_BitRate=!FFMPEG_V_Target_BitRate!" >> "!vrdlog!" 2>&1
	REM There were nested IF statements which is why the IFs and SETs are done this way
	If !FFMPEG_V_Target_BitRate! LSS 2000000 (
		REM low bitrate, do not touch the bitrate itself, instead bump to CQ24
		set "FFMPEG_V_PROPOSED_x_cq_options=!FFMPEG_V_cq24!"
		ECHO !DATE! !TIME! "yes to Low INCOMING_BITRATE !INCOMING_BITRATE! LSS 2000000" >> "!vrdlog!" 2>&1
		ECHO !DATE! !TIME! "FFMPEG_V_PROPOSED_x_cq_options=!FFMPEG_V_PROPOSED_x_cq_options!" >> "!vrdlog!" 2>&1
	)
	set "FFMPEG_V_final_cq_options=!FFMPEG_V_PROPOSED_x_cq_options!"
)
ECHO !DATE! !TIME! Final FFMPEG_V_final_cq_options='!FFMPEG_V_final_cq_options!' >> "!vrdlog!" 2>&1

IF /I "%COMPUTERNAME%" == "3900X" (
	REM		' -dpb_size 0		means automatic (default)
	REM		' -bf:v 3			means use 3 b-frames (dont use more than 3)
	REM	xx	' -b_ref_mode 0		means B frames will not be used for reference
	REM set "ffmpeg_RTX2060super_extra_flags=-spatial-aq 1 -temporal-aq 1 -refs 3"
	REM 2021.02.28 "-refs 3" is replaced by -dpb_size 0 -bf:v 3 -b_ref_mode:v 0 https://trac.ffmpeg.org/ticket/9130#comment:8 https://trac.ffmpeg.org/ticket/7303#comment:3
	set "FFMPEG_V_RTX2060super_extra_flags=-spatial-aq 1 -temporal-aq 1 -dpb_size 0 -bf:v 3 -b_ref_mode:v 0"
) ELSE (
	set "FFMPEG_V_RTX2060super_extra_flags="
)

REM Now Check for Footy, after the final fiddling with bitrates and CQ.
REM If is footy, deinterlace to 50FPS 50p, doubling the framerate, rather than just 25p
REM so that we maintain the "motion fluidity" of 50i into 50p. It's better than Nothing.

set "Footy_found=False"
IF /I NOT "!the_file_name_part!"=="!the_file_name_part:AFL=_____!" (
	set "Footy_found=True"
	ECHO Footy word 'AFL' found in filename '!the_file_name_part!' >> "!vrdlog!" 2>&1
) ELSE IF /I NOT "!the_file_name_part!"=="!the_file_name_part:SANFL=_____!" (
	set "Footy_found=True"
	ECHO Footy word 'SANFL' found in filename '!the_file_name_part!' >> "!vrdlog!" 2>&1
) ELSE IF /I NOT "!the_file_name_part!"=="!the_file_name_part:Crows=_____!" (
	set "Footy_found=True"
	ECHO Footy word 'Crows' found in filename '!the_file_name_part!' >> "!vrdlog!" 2>&1
) ELSE (
	set "Footy_found=False"
	ECHO NO Footy words found in filename '!the_file_name_part!' >> "!vrdlog!" 2>&1
)
IF /I "!Footy_found!" == "True" (
	IF /I "!SRC_calc_Video_Interlacement!" == "PROGRESSIVE" (
		REM set for no deinterlace
		set "FFMPEG_V_dg_deinterlace=0"
		ECHO Already Progressive video, Footy words found in filename '!the_file_name_part!', FFMPEG_V_dg_deinterlace=!FFMPEG_V_dg_deinterlace! NO Footy variables set >> "!vrdlog!" 2>&1
	) ELSE IF /I "!SRC_calc_Video_Interlacement!" == "INTERLACED" (
		REM set for double framerate deinterlace
		set "FFMPEG_V_dg_deinterlace=2"
		vrdtvsp_final_dg_deinterlace = 2	' set for double framerate deinterlace
		REM use python to calculate rounded values for upped FOOTY double framerate deinterlaced output
		CALL :calc_single_number_result_py "int(round(!FFMPEG_V_Target_BitRate! * 1.75))"       "Footy_FFMPEG_V_Target_BitRate"
		CALL :calc_single_number_result_py "int(round(!Footy_FFMPEG_V_Target_BitRate! * 0.20))" "Footy_FFMPEG_V_Target_Minimum_BitRate"
		CALL :calc_single_number_result_py "int(round(!Footy_FFMPEG_V_Target_BitRate! * 2))"    "Footy_FFMPEG_V_Target_Maximum_BitRate"
		CALL :calc_single_number_result_py "int(round(!Footy_FFMPEG_V_Target_BitRate! * 2))"    "Footy_FFMPEG_V_Target_BufSize"
		ECHO Interlaced video, Footy words found in filename '!the_file_name_part!', FFMPEG_V_dg_deinterlace=!FFMPEG_V_dg_deinterlace!  Footy variables set >> "!vrdlog!" 2>&1
		set /a FFMPEG_V_Target_BitRate=!Footy_FFMPEG_V_Target_BitRate!
		set /a FFMPEG_V_Target_Minimum_BitRate=!Footy_FFMPEG_V_Target_Minimum_BitRate!
		set /a FFMPEG_V_Target_Maximum_BitRate=!Footy_FFMPEG_V_Target_Maximum_BitRate!
		set /a FFMPEG_V_Target_BufSize=!Footy_FFMPEG_V_Target_BufSize!
	) ELSE (
		set "check_QSF_failed=UNKNOWN SRC_calc_Video_Interlacement="!SRC_calc_Video_Interlacement!" to base transcode calculations on, for '%~f1'"
		ECHO !DATE! !TIME! !check_QSF_failed! >> "!vrdlog!" 2>&1
		ECHO !DATE! !TIME! the_Source_File="!the_Source_File!" >> "!vrdlog!" 2>&1
		REM !xPAUSE!
		REM exit 1
		call :move_to_bad "!the_Source_File!"
		goto :eof
	)
) ELSE (
	ECHO NO Footy words found in filename '!the_file_name_part!', FFMPEG_V_dg_deinterlace unchanged=!FFMPEG_V_dg_deinterlace!, NO footy variables set  >> "!vrdlog!" 2>&1
)
ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
ECHO set FFMPEG_ >> "!vrdlog!" 2>&1
set FFMPEG_ >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
ECHO set Footy_ >> "!vrdlog!" 2>&1
set Footy_ >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
REM ECHO set X_ >> "!vrdlog!" 2>&1
REM set X_ >> "!vrdlog!" 2>&1
REM ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
REM ECHO set extra_ >> "!vrdlog!" 2>&1
REM set extra_ >> "!vrdlog!" 2>&1
REM ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1

ECHO !DATE! !TIME! ====================================================================================================================================================== >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! ====================================================================================================================================================== >> "!vrdlog!" 2>&1

ECHO !DATE! !TIME! FFMPEGVARS: Determining FFMPEG_ variables helpful in encoding from "!the_Source_File!"  >> "!vrdlog!" 2>&1
set "FFMPEG_V_G=UNKNOWN"
IF /I "!SRC_calc_Video_Interlacement!" == "PROGRESSIVE" (
	ECHO !DATE! !TIME! FFMPEGVARS: PROGRESSIVE detected SRC_MI_V_FrameRate_Num='!SRC_MI_V_FrameRate_Num!' >> "!vrdlog!" 2>&1
	IF /I "!SRC_calc_Video_Encoding!" == "AVC" (
		REM Progressive AVC
		ECHO !DATE! !TIME! FFMPEGVARS: PROGRESSIVE AVC detected SRC_MI_V_FrameRate_Num='!SRC_MI_V_FrameRate_Num!' >> "!vrdlog!" 2>&1
		set "FFMPEG_V_dg_deinterlace=0"
		set "FFMPEG_V_dg_vpy_denoise="
		set "FFMPEG_V_dg_vpy_dsharpen="
		if /I "!SRC_MI_V_FrameRate_Num!" == "25" (
			set "FFMPEG_V_G=25"
		) else if /I "!SRC_MI_V_FrameRate_Num!" == "50" (
			set "FFMPEG_V_G=50"
		) else (
			set "FFMPEG_V_G=12"
		)
		IF /I "!Footy_found!" == "True" (
			ECHO !DATE! !TIME! FFMPEGVARS: PROGRESSIVE AVC FOOTY detected SRC_MI_V_FrameRate_Num='!SRC_MI_V_FrameRate_Num!' >> "!vrdlog!" 2>&1
			set "FFMPEG_V_dg_deinterlace=0"
			set "FFMPEG_V_dg_vpy_denoise="
			set "FFMPEG_V_dg_vpy_dsharpen="
			if /I "!SRC_MI_V_FrameRate_Num!" == "25" (
				set "FFMPEG_V_G=25"
			) else if /I "!SRC_MI_V_FrameRate_Num!" == "50" (
				set "FFMPEG_V_G=50"
			) else (
				set "FFMPEG_V_G=12"
			)
		)
	) ELSE IF /I "!SRC_calc_Video_Encoding!" == "HEVC" (
		REM Progressive HEVC
		ECHO !DATE! !TIME! FFMPEGVARS: PROGRESSIVE HEVC detected SRC_MI_V_FrameRate_Num='!SRC_MI_V_FrameRate_Num!' >> "!vrdlog!" 2>&1
		set "FFMPEG_V_dg_deinterlace=0"
		set "FFMPEG_V_dg_vpy_denoise=, dn_enable=3, dn_quality="good", dn_strength=0.06, dn_cstrength=0.06, dn_tthresh=75.0, dn_show=0"
		set "FFMPEG_V_dg_vpy_dsharpen=, sh_enable=1, sh_strength=0.3"
		if /I "!SRC_MI_V_FrameRate_Num!" == "25" (
			set "FFMPEG_V_G=25"
		) else if /I "!SRC_MI_V_FrameRate_Num!" == "50" (
			set "FFMPEG_V_G=50"
		) else (
			set "FFMPEG_V_G=12"
		)
		IF /I "!Footy_found!" == "True" (
			ECHO !DATE! !TIME! FFMPEGVARS: PROGRESSIVE HEVC FOOTY detected SRC_MI_V_FrameRate_Num='!SRC_MI_V_FrameRate_Num!' >> "!vrdlog!" 2>&1
			set "FFMPEG_V_dg_deinterlace=0"
			set "FFMPEG_V_dg_vpy_denoise=, dn_enable=3, dn_quality="good", dn_strength=0.04, dn_cstrength=0.04, dn_tthresh=75.0, dn_show=0"
			set "FFMPEG_V_dg_vpy_dsharpen=, sh_enable=1, sh_strength=0.25"
			if /I "!SRC_MI_V_FrameRate_Num!" == "25" (
				set "FFMPEG_V_G=25"
			) else if /I "!SRC_MI_V_FrameRate_Num!" == "50" (
				set "FFMPEG_V_G=50"
			) else (
				set "FFMPEG_V_G=12"
			)
		)
	) ELSE (
		REM UNKNOWN
		ECHO !DATE! !TIME! FFMPEGVARS: UNKNOWN PROGRESSIVE SRC_calc_Video_Encoding '!SRC_calc_Video_Encoding!' detected SRC_MI_V_FrameRate_Num='!SRC_MI_V_FrameRate_Num!' >> "!vrdlog!" 2>&1
		REM !xPAUSE!
		REM exit 1
		call :move_to_bad "!the_Source_File!"
		goto :eof
	)
) ELSE IF /I "!SRC_calc_Video_Interlacement!" == "INTERLACED" (
	ECHO !DATE! !TIME! FFMPEGVARS: INTERLACED detected SRC_MI_V_FrameRate_Num='!SRC_MI_V_FrameRate_Num!' >> "!vrdlog!" 2>&1
	IF /I "!SRC_calc_Video_Encoding!" == "AVC" (
		REM Interlaced AVC
		ECHO !DATE! !TIME! FFMPEGVARS: INTERLACED AVC detected SRC_MI_V_FrameRate_Num='!SRC_MI_V_FrameRate_Num!' >> "!vrdlog!" 2>&1
		set "FFMPEG_V_dg_deinterlace=1"
		set "FFMPEG_V_dg_vpy_denoise=, dn_enable=3, dn_quality="good", dn_strength=0.06, dn_cstrength=0.06, dn_tthresh=75.0, dn_show=0"
		set "FFMPEG_V_dg_vpy_dsharpen=, sh_enable=1, sh_strength=0.3"
		if /I "!SRC_MI_V_FrameRate_Num!" == "25" (
			set "FFMPEG_V_G=25"
		) else if /I "!SRC_MI_V_FrameRate_Num!" == "50" (
			set "FFMPEG_V_G=50"
		) else (
			set "FFMPEG_V_G=12"
		)
		IF /I "!Footy_found!" == "True" (
			ECHO !DATE! !TIME! FFMPEGVARS: INTERLACED AVC FOOTY detected SRC_MI_V_FrameRate_Num='!SRC_MI_V_FrameRate_Num!' >> "!vrdlog!" 2>&1
			set "FFMPEG_V_dg_deinterlace=2"
			set "FFMPEG_V_dg_vpy_denoise=, dn_enable=3, dn_quality="good", dn_strength=0.04, dn_cstrength=0.04, dn_tthresh=75.0, dn_show=0"
			set "FFMPEG_V_dg_vpy_dsharpen=, sh_enable=1, sh_strength=0.25"
			if /I "!SRC_MI_V_FrameRate_Num!" == "25" (
				set "FFMPEG_V_G=50"
			) else (
				set "FFMPEG_V_G=24"
			)
		)
	) ELSE IF /I "!SRC_calc_Video_Encoding!" == "HEVC" (
		ECHO !DATE! !TIME! FFMPEGVARS: INTERLACED HEVC detected SRC_MI_V_FrameRate_Num='!SRC_MI_V_FrameRate_Num!' >> "!vrdlog!" 2>&1
		set "FFMPEG_V_dg_deinterlace=2"
		set "FFMPEG_V_dg_vpy_denoise=, dn_enable=3, dn_quality="good", dn_strength=0.06, dn_cstrength=0.06, dn_tthresh=75.0, dn_show=0"
		set "FFMPEG_V_dg_vpy_dsharpen=, sh_enable=1, sh_strength=0.3"
		if /I "!SRC_MI_V_FrameRate_Num!" == "25" (
			set "FFMPEG_V_G=25"
		) else if /I "!SRC_MI_V_FrameRate_Num!" == "50" (
			set "FFMPEG_V_G=50"
		) else (
			set "FFMPEG_V_G=12"
		)
		IF /I "!Footy_found!" == "True" (
			ECHO !DATE! !TIME! FFMPEGVARS: PROGRESSIVE HEVC FOOTY detected SRC_MI_V_FrameRate_Num='!SRC_MI_V_FrameRate_Num!' >> "!vrdlog!" 2>&1
			set "FFMPEG_V_dg_deinterlace=2"
			set "FFMPEG_V_dg_vpy_denoise=, dn_enable=3, dn_quality="good", dn_strength=0.04, dn_cstrength=0.04, dn_tthresh=75.0, dn_show=0"
			set "FFMPEG_V_dg_vpy_dsharpen=, sh_enable=1, sh_strength=0.25"
			if /I "!SRC_MI_V_FrameRate_Num!" == "25" (
				set "FFMPEG_V_G=50"
			) else (
				set "FFMPEG_V_G=24"
			)
		)
	) ELSE (
		REM UNKNOWN
		ECHO !DATE! !TIME! FFMPEGVARS: UNKNOWN INTERLACED SRC_calc_Video_Encoding '!SRC_calc_Video_Encoding!' detected SRC_MI_V_FrameRate_Num='!SRC_MI_V_FrameRate_Num!' >> "!vrdlog!" 2>&1
		REM !xPAUSE!
		REM exit 1
		call :move_to_bad "!the_Source_File!"
		goto :eof
	)
)
REM display all FFMPEG_ variables
ECHO +++++++++ >> "!vrdlog!" 2>&1
ECHO display all FFMPEG_ variables >> "!vrdlog!" 2>&1
ECHO set FFMPEG_ >> "!vrdlog!" 2>&1
set FFMPEG_ >> "!vrdlog!" 2>&1
ECHO +++++++++ >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! ====================================================================================================================================================== >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! ====================================================================================================================================================== >> "!vrdlog!" 2>&1
goto :eof

REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM
:convert_to_h264_aac
REM parameter 1 = input filename (.mp4 file)
REM NOTES:
REM %~1  -  expands %1 removing any surrounding quotes (") 
REM %~f1  -  expands %1 to a fully qualified path name 
REM %~d1  -  expands %1 to a drive letter only 
REM %~p1  -  expands %1 to a path only 
REM %~n1  -  expands %1 to a file name only including the leading "."
REM %~x1  -  expands %1 to a file extension only 
REM %~s1  -  expanded path contains short names only 
REM %~a1  -  expands %1 to file attributes 
REM %~t1  -  expands %1 to date/time of file 
REM %~z1  -  expands %1 to size of file 
REM The modifiers can be combined to get compound results:
REM %~dp1  -  expands %1 to a drive letter and path only 
REM %~nx1  -  expands %1 to a file name and extension only 

REM ECHO in :convert_to_h264_aac ... from :getvariables the_Source_File="!the_Source_File!" >> "!vrdlog!" 2>&1
REM ECHO in :convert_to_h264_aac ... from :getvariables the_file_name_part="!the_file_name_part!" >> "!vrdlog!" 2>&1
REM ECHO in :convert_to_h264_aac ... from :getvariables the_Target_Filename="!the_Target_Filename!" >> "!vrdlog!" 2>&1
REM ECHO in :convert_to_h264_aac ... from :getvariables the_Target_File="!the_Target_File!" >> "!vrdlog!" 2>&1
REM ECHO in :convert_to_h264_aac ... from :getvariables the_DGI_file="!the_DGI_file!" >> "!vrdlog!" 2>&1
REM ECHO in :convert_to_h264_aac ... from :getvariables the_DGI_autolog="!the_DGI_autolog!" >> "!vrdlog!" 2>&1
REM ECHO in :convert_to_h264_aac ... from :getvariables the_VPY_file="!the_VPY_file!" >> "!vrdlog!" 2>&1
REM !xPAUSE!

REM the_Source_File is already set by :gather_variables_from_media_file


REM display all SRC_ variables
ECHO +++++++++ >> "!vrdlog!" 2>&1
ECHO :convert_to_h264_aac display all SRC_ variables >> "!vrdlog!" 2>&1
ECHO :convert_to_h264_aac set SRC_ >> "!vrdlog!" 2>&1
set SRC_ >> "!vrdlog!" 2>&1
ECHO +++++++++ >> "!vrdlog!" 2>&1

REM display all calculated variables
ECHO +++++++++ >> "!vrdlog!" 2>&1
ECHO :convert_to_h264_aac display all calculated variables >> "!vrdlog!" 2>&1
ECHO :convert_to_h264_aac set SRC_calc_ >> "!vrdlog!" 2>&1
set SRC_calc_ >> "!vrdlog!" 2>&1
ECHO +++++++++ >> "!vrdlog!" 2>&1


REM IGNORE ANYTHING BUT AVC and HEVC
REM the MOVE of the_Source_File into a destination folder depends on video codec and audio codec
REM done_avc_aac
REM done_avc_mp3
REM done_h265_aac
REM done_h265_mp3
REM 
REM use this:
REM		SRC_FF_A_codec_name=aac
REM		SRC_FF_A_codec_name=mp3
REM not this:
REM		SRC_MI_A_Format=AAC
REM		SRC_MI_A_Format=MPEG_Audio
REM
IF /I "!SRC_calc_Video_Interlacement!" == "PROGRESSIVE" (
	IF /I "!SRC_calc_Video_Encoding!" == "AVC" (
		IF /I "!SRC_FF_A_codec_name!" == "aac" (
			ECHO !DATE! !TIME! PROGRESSIVE AVC AAC >> "!vrdlog!" 2>&1
			REM for Progressive AVC just copy video stream and transcode audio stream
			ECHO ======================================================  Start Run FFMPEG copy video stream, copy audio stream for PROGRESSIVE AVC AAC ====================================================== >> "!vrdlog!" 2>&1
			ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
			REM ffmpeg throws an error due to "-c:v copy" and this together: -vf "setdar="!QSF_MI_V_DisplayAspectRatio_String_slash!"
			REM ffmpeg throws an error due to "-c:v copy" and this together: -profile:v high -level 5.2 
			set "FFMPEG_cmd="!ffmpegexe64!""
			set "FFMPEG_cmd=!FFMPEG_cmd! -hide_banner -v info -nostats"
			set "FFMPEG_cmd=!FFMPEG_cmd! -i "!the_Source_File!" -probesize 100M -analyzeduration 100M"
			set "FFMPEG_cmd=!FFMPEG_cmd! -c:v copy -fps_mode passthrough"
			set "FFMPEG_cmd=!FFMPEG_cmd! -strict experimental"
			set "FFMPEG_cmd=!FFMPEG_cmd! -sws_flags lanczos+accurate_rnd+full_chroma_int+full_chroma_inp"
			set "FFMPEG_cmd=!FFMPEG_cmd! -movflags +faststart+write_colr"
			set "FFMPEG_cmd=!FFMPEG_cmd! -c:a copy"
			set "FFMPEG_cmd=!FFMPEG_cmd! -y "!the_Target_File!""
			ECHO !FFMPEG_cmd! >> "!vrdlog!" 2>&1
			REM !FFMPEG_cmd! >> "!vrdlog!" 2>&1
			SET EL=!ERRORLEVEL!
			IF /I "!EL!" NEQ "0" (
				set "check_QSF_failed=********** ERROR: Error Number '!EL!' returned from '!ffmpegexe64!' copy video stream, copy audio stream "
				ECHO !DATE! !TIME! !check_QSF_failed! >> "!vrdlog!" 2>&1
				ECHO !DATE! !TIME! the_Source_File="!the_Source_File!" >> "!vrdlog!" 2>&1
				REM !xPAUSE!
				REM exit !EL!
				call :move_to_bad "!the_Source_File!"
				goto :eof
			)
			ECHO ======================================================  Finish Run FFMPEG copy video stream, copy audio stream for PROGRESSIVE AVC AAC ====================================================== >> "!vrdlog!" 2>&1
			ECHO MOVE /Y "!the_Source_File!" "!done_avc_aac!" >> "!vrdlog!" 2>&1
			MOVE /Y "!the_Source_File!" "!done_avc_aac!" >> "!vrdlog!" 2>&1
		) ELSE IF /I "!SRC_FF_A_codec_name!" == "mp3" (
			ECHO !DATE! !TIME! PROGRESSIVE AVC MP3  >> "!vrdlog!" 2>&1
			REM c:v copy c:a CONVERT TO AAC
			ECHO ======================================================  Start Run FFMPEG copy video stream, transcode audio stream for PROGRESSIVE AVC MP3 ====================================================== >> "!vrdlog!" 2>&1
			ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
			REM ffmpeg throws an error due to "-c:v copy" and this together: -vf "setdar="!QSF_MI_V_DisplayAspectRatio_String_slash!"
			REM ffmpeg throws an error due to "-c:v copy" and this together: -profile:v high -level 5.2 
			set "FFMPEG_cmd="!ffmpegexe64!""
			set "FFMPEG_cmd=!FFMPEG_cmd! -hide_banner -v info -nostats"
			set "FFMPEG_cmd=!FFMPEG_cmd! -i "!the_Source_File!" -probesize 100M -analyzeduration 100M"
			set "FFMPEG_cmd=!FFMPEG_cmd! -c:v copy -fps_mode passthrough"
			set "FFMPEG_cmd=!FFMPEG_cmd! -strict experimental"
			set "FFMPEG_cmd=!FFMPEG_cmd! -sws_flags lanczos+accurate_rnd+full_chroma_int+full_chroma_inp"
			set "FFMPEG_cmd=!FFMPEG_cmd! -movflags +faststart+write_colr"
			set "FFMPEG_cmd=!FFMPEG_cmd! -c:a libfdk_aac -b:a 256k -ar 48000"
			set "FFMPEG_cmd=!FFMPEG_cmd! -y "!the_Target_File!""
			ECHO !FFMPEG_cmd! >> "!vrdlog!" 2>&1
			REM !FFMPEG_cmd! >> "!vrdlog!" 2>&1
			SET EL=!ERRORLEVEL!
			IF /I "!EL!" NEQ "0" (
				set "check_QSF_failed=********** ERROR: Error Number '!EL!' returned from '!ffmpegexe64!' copy video stream, transcode audio stream "
				ECHO !DATE! !TIME! !check_QSF_failed! >> "!vrdlog!" 2>&1
				ECHO !DATE! !TIME! the_Source_File="!the_Source_File!" >> "!vrdlog!" 2>&1
				REM !xPAUSE!
				REM exit !EL!
				call :move_to_bad "!the_Source_File!"
				goto :eof
			)
			ECHO ======================================================  Finish Run FFMPEG copy video stream, transcode audio stream for PROGRESSIVE AVC MP3 ====================================================== >> "!vrdlog!" 2>&1
			ECHO MOVE /Y "!the_Source_File!" "!done_avc_mp3!" >> "!vrdlog!" 2>&1
			MOVE /Y "!the_Source_File!" "!done_avc_mp3!" >> "!vrdlog!" 2>&1
		) ELSE (
			ECHO !DATE! !TIME! PROGRESSIVE AVC SRC_FF_A_codec_name "!SRC_FF_A_codec_name!" NOT IN ['.aac', '.mp3' ] >> "!vrdlog!" 2>&1
			ECHO !DATE! !TIME! the_Source_File="!the_Source_File!" >> "!vrdlog!" 2>&1
			REM !xPAUSE!
			REM EXIT 1
			call :move_to_bad "!the_Source_File!"
			goto :eof
		)
	) ELSE IF /I "!SRC_calc_Video_Encoding!" == "HEVC" (
		IF /I "!SRC_FF_A_codec_name!" == "aac" (
			ECHO !DATE! !TIME! PROGRESSIVE HEVC AAC >> "!vrdlog!" 2>&1
			REM c:v CONVERT TO H264 copy c:a copy
			ECHO ======================================================  Start Run FFMPEG transcode video stream, copy audio stream for PROGRESSIVE HEVC AAC ====================================================== >> "!vrdlog!" 2>&1
			ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
			set "FFMPEG_cmd="!ffmpegexe64!""
			set "FFMPEG_cmd=!FFMPEG_cmd! -hide_banner -v info -nostats"
			REM set "FFMPEG_cmd=!FFMPEG_cmd! -hide_banner -v verbose -nostats"
			set "FFMPEG_cmd=!FFMPEG_cmd! -i "!the_Source_File!" -probesize 100M -analyzeduration 100M"
			set "FFMPEG_cmd=!FFMPEG_cmd! -vf "setdar=!SRC_MI_V_DisplayAspectRatio_String_slash!""
			set "FFMPEG_cmd=!FFMPEG_cmd! -fps_mode passthrough -sws_flags lanczos+accurate_rnd+full_chroma_int+full_chroma_inp -strict experimental"
			set "FFMPEG_cmd=!FFMPEG_cmd! -c:v h264_nvenc -pix_fmt nv12 -preset p7 -multipass fullres -forced-idr 1 -g !FFMPEG_V_G! -coder:v cabac"
			set "FFMPEG_cmd=!FFMPEG_cmd! !FFMPEG_V_RTX2060super_extra_flags!"
			set "FFMPEG_cmd=!FFMPEG_cmd! -rc:v vbr !FFMPEG_V_final_cq_options!"
			set "FFMPEG_cmd=!FFMPEG_cmd! -b:v !FFMPEG_V_Target_BitRate! -minrate:v !FFMPEG_V_Target_Minimum_BitRate! -maxrate:v !FFMPEG_V_Target_Maximum_BitRate! -bufsize !FFMPEG_V_Target_Maximum_BitRate!"
			set "FFMPEG_cmd=!FFMPEG_cmd! -strict experimental"
			REM set "FFMPEG_cmd=!FFMPEG_cmd! -sws_flags lanczos+accurate_rnd+full_chroma_int+full_chroma_inp"
			set "FFMPEG_cmd=!FFMPEG_cmd! -profile:v high -level 5.2 -movflags +faststart+write_colr"
			set "FFMPEG_cmd=!FFMPEG_cmd! -c:a copy"
			set "FFMPEG_cmd=!FFMPEG_cmd! -y "!the_Target_File!""
			ECHO !FFMPEG_cmd! >> "!vrdlog!" 2>&1
			REM !FFMPEG_cmd! >> "!vrdlog!" 2>&1
			SET EL=!ERRORLEVEL!
			IF /I "!EL!" NEQ "0" (
				set "check_QSF_failed=********** ERROR: Error Number '!EL!' returned from '!ffmpegexe64!' transcode video stream, copy audio stream "
				ECHO !DATE! !TIME! !check_QSF_failed! >> "!vrdlog!" 2>&1
				ECHO !DATE! !TIME! the_Source_File="!the_Source_File!" >> "!vrdlog!" 2>&1
				REM !xPAUSE!
				REM exit !EL!
				call :move_to_bad "!the_Source_File!"
				goto :eof
			)
			ECHO ======================================================  Finish Run FFMPEG transcode video stream, copy audio stream for PROGRESSIVE HEVC AAC ====================================================== >> "!vrdlog!" 2>&1
			ECHO MOVE /Y "!the_Source_File!" "!done_h265_aac!" >> "!vrdlog!" 2>&1
			MOVE /Y "!the_Source_File!" "!done_h265_aac!" >> "!vrdlog!" 2>&1
		) ELSE IF /I "!SRC_FF_A_codec_name!" == "mp3" (
			ECHO !DATE! !TIME! PROGRESSIVE HEVC MP3 >> "!vrdlog!" 2>&1
			REM c:v CONVERT TO H264 c:a CONVERT TO AAC
			ECHO ======================================================  Start Run FFMPEG transcode video stream, transcode audio stream for PROGRESSIVE HEVC MP3 ====================================================== >> "!vrdlog!" 2>&1
			ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
			set "FFMPEG_cmd="!ffmpegexe64!""
			set "FFMPEG_cmd=!FFMPEG_cmd! -hide_banner -v info -nostats"
			REM set "FFMPEG_cmd=!FFMPEG_cmd! -hide_banner -v verbose -nostats"
			set "FFMPEG_cmd=!FFMPEG_cmd! -i "!the_Source_File!" -probesize 100M -analyzeduration 100M"
			set "FFMPEG_cmd=!FFMPEG_cmd! -vf "setdar=!SRC_MI_V_DisplayAspectRatio_String_slash!""
			set "FFMPEG_cmd=!FFMPEG_cmd! -fps_mode passthrough -sws_flags lanczos+accurate_rnd+full_chroma_int+full_chroma_inp -strict experimental"
			set "FFMPEG_cmd=!FFMPEG_cmd! -c:v h264_nvenc -pix_fmt nv12 -preset p7 -multipass fullres -forced-idr 1 -g !FFMPEG_V_G! -coder:v cabac"
			set "FFMPEG_cmd=!FFMPEG_cmd! !FFMPEG_V_RTX2060super_extra_flags!"
			set "FFMPEG_cmd=!FFMPEG_cmd! -rc:v vbr !FFMPEG_V_final_cq_options!"
			set "FFMPEG_cmd=!FFMPEG_cmd! -b:v !FFMPEG_V_Target_BitRate! -minrate:v !FFMPEG_V_Target_Minimum_BitRate! -maxrate:v !FFMPEG_V_Target_Maximum_BitRate! -bufsize !FFMPEG_V_Target_Maximum_BitRate!"
			set "FFMPEG_cmd=!FFMPEG_cmd! -strict experimental"
			REM set "FFMPEG_cmd=!FFMPEG_cmd! -sws_flags lanczos+accurate_rnd+full_chroma_int+full_chroma_inp"
			set "FFMPEG_cmd=!FFMPEG_cmd! -profile:v high -level 5.2 -movflags +faststart+write_colr"
			set "FFMPEG_cmd=!FFMPEG_cmd! -c:a libfdk_aac -b:a 256k -ar 48000"
			set "FFMPEG_cmd=!FFMPEG_cmd! -y "!the_Target_File!""
			ECHO !FFMPEG_cmd! >> "!vrdlog!" 2>&1
			REM !FFMPEG_cmd! >> "!vrdlog!" 2>&1
			SET EL=!ERRORLEVEL!
			IF /I "!EL!" NEQ "0" (
				set "check_QSF_failed=********** ERROR: Error Number '!EL!' returned from '!ffmpegexe64!' transcode video stream, transcode audio stream "
				ECHO !DATE! !TIME! !check_QSF_failed! >> "!vrdlog!" 2>&1
				ECHO !DATE! !TIME! the_Source_File="!the_Source_File!" >> "!vrdlog!" 2>&1
				REM !xPAUSE!
				REM exit !EL!
				call :move_to_bad "!the_Source_File!"
				goto :eof
			)
			ECHO ======================================================  Finish Run FFMPEG transcode video stream, transcode audio stream for PROGRESSIVE HEVC MP3 ====================================================== >> "!vrdlog!" 2>&1
			ECHO MOVE /Y "!the_Source_File!" "!done_h265_mp3!" >> "!vrdlog!" 2>&1
			MOVE /Y "!the_Source_File!" "!done_h265_mp3!" >> "!vrdlog!" 2>&1
		) ELSE (
			ECHO !DATE! !TIME! PROGRESSIVE HEVC SRC_FF_A_codec_name "!SRC_FF_A_codec_name!" NOT IN ['.aac', '.mp3' ] >> "!vrdlog!" 2>&1
			ECHO !DATE! !TIME! the_Source_File="!the_Source_File!" >> "!vrdlog!" 2>&1
			REM !xPAUSE!
			REM EXIT 1
			call :move_to_bad "!the_Source_File!"
			goto :eof
		)
	) ELSE (
		ECHO !DATE! !TIME! PROGRESSIVE SRC_calc_Video_Encoding "!SRC_calc_Video_Encoding!" not in [ 'AVC', 'HEVC' ] >> "!vrdlog!" 2>&1
		ECHO !DATE! !TIME! the_Source_File="!the_Source_File!" >> "!vrdlog!" 2>&1
		REM !xPAUSE!
		REM EXIT 1
		call :move_to_bad "!the_Source_File!"
		goto :eof
	)
) ELSE IF /I "!SRC_calc_Video_Interlacement!" == "INTERLACED" (
	REM for INTERLACED we do not care about the source codec, we ALWAYS deinterlace and transcode the video; the audio is transcoded only if not AAC
	REM i.e. for ALL interlaced sources, do vapoursynth/DG
	SET "the_FFMPEG_AUDIO_treatment=-c:a libfdk_aac -b:a 256k -ar 48000"
	ECHO ======================================================  Start the DGIndexNV for INTERLACED SOURCE ====================================================== >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
	ECHO !dgindexNVexe64! -version >> "!vrdlog!" 2>&1
	!dgindexNVexe64! -version  >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
	ECHO !dgindexNVexe64! -i "!the_Source_File!" -e -h -o "!the_DGI_file!" >> "!vrdlog!" 2>&1
	!dgindexNVexe64! -i "!the_Source_File!" -e -h -o "!the_DGI_file!" >> "!vrdlog!" 2>&1
	SET EL=!ERRORLEVEL!
	IF /I "!EL!" NEQ "0" (
		set "check_QSF_failed=********** ERROR: Error Number '!EL!' returned from '!dgindexNVexe64!'"
		ECHO !DATE! !TIME! !check_QSF_failed! >> "!vrdlog!" 2>&1
		ECHO !DATE! !TIME! the_Source_File="!the_Source_File!" >> "!vrdlog!" 2>&1
		ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
		REM !xPAUSE!
		REM EXIT
		call :move_to_bad "!the_Source_File!"
		goto :eof
	)
	ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
	ECHO TYPE "!the_DGI_autolog!" >> "!vrdlog!" 2>&1
	TYPE "!the_DGI_autolog!" >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
	REM ECHO TYPE "!the_DGI_file!" >> "!vrdlog!" 2>&1
	REM TYPE "!the_DGI_file!" >> "!vrdlog!" 2>&1
	REM ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
	ECHO DEL /F "!the_DGI_autolog!" >> "!vrdlog!" 2>&1
	DEL /F "!the_DGI_autolog!" >> "!vrdlog!" 2>&1
	ECHO ======================================================  Finish the DGIndexNV for INTERLACED SOURCE ====================================================== >> "!vrdlog!" 2>&1
	ECHO ======================================================  Start Create a the_VPY_file ====================================================== >> "!vrdlog!" 2>&1
	DEL /F "!the_VPY_file!">NUL 2>&1
	ECHO import vapoursynth as vs		# this allows use of constants eg vs.YUV420P8 >> "!the_VPY_file!" 2>&1
	ECHO from vapoursynth import core	# actual vapoursynth core >> "!the_VPY_file!" 2>&1
	ECHO #import functool >> "!the_VPY_file!" 2>&1
	ECHO #import mvsfunc as mvs			# this relies on the .py residing at the VS folder root level - see run_vsrepo.bat >> "!the_VPY_file!" 2>&1
	ECHO #import havsfunc as haf		# this relies on the .py residing at the VS folder root level - see run_vsrepo.bat >> "!the_VPY_file!" 2>&1
	ECHO core.std.LoadPlugin^(r'!vs_root!\DGIndex\DGDecodeNV.dll'^) # do it like gonca https://forum.doom9.org/showthread.php?p=1877765#post1877765 >> "!the_VPY_file!" 2>&1
	ECHO core.avs.LoadPlugin^(r'!vs_root!\DGIndex\DGDecodeNV.dll'^) # do it like gonca https://forum.doom9.org/showthread.php?p=1877765#post1877765 >> "!the_VPY_file!" 2>&1
	ECHO # NOTE: deinterlace=1, use_top_field=True for "Interlaced"/"TFF" >> "!the_VPY_file!" 2>&1
	ECHO # NOTE: deinterlace=2, use_top_field=True for "Interlaced"/"TFF" >> "!the_VPY_file!" 2>&1
	ECHO # dn_enable=x DENOISE >> "!the_VPY_file!" 2>&1
	ECHO # default 0  0: disabled  1: spatial denoising only  2: temporal denoising only  3: spatial and temporal denoising >> "!the_VPY_file!" 2>&1
	ECHO # dn_quality="x" default "good"    "good" "better" "best" ... "best" halves the speed compared pre-CUDASynth >> "!the_VPY_file!" 2>&1
	ECHO video = core.dgdecodenv.DGSource^( r'!the_DGI_file!', deinterlace=!FFMPEG_V_dg_deinterlace!, use_top_field=!FFMPEG_V_dg_use_TFF!, use_pf=False !FFMPEG_V_dg_vpy_denoise! !FFMPEG_V_dg_vpy_dsharpen! ^) >> "!the_VPY_file!" 2>&1
	ECHO #video = vs.core.text.ClipInfo^(video^) >> "!the_VPY_file!" 2>&1
	ECHO video.set_output^(^) >> "!the_VPY_file!" 2>&1
	ECHO TYPE "!the_VPY_file!" >> "!vrdlog!" 2>&1
	TYPE "!the_VPY_file!" >> "!vrdlog!" 2>&1
	ECHO ======================================================  Finish Create a the_VPY_file ====================================================== >> "!vrdlog!" 2>&1
	REM
	IF /I "!SRC_calc_Video_Encoding!" == "AVC" (
		IF /I "!SRC_FF_A_codec_name!" == "aac" (
			ECHO !DATE! !TIME! INTERLACED AVC AAC >> "!vrdlog!" 2>&1
			REM c:v DEINTERLACE AND convert to H264 c:a copy
			REM --- USE DG and VAPOURSYNTH 
			ECHO ======================================================  Start Run FFMPEG vapoursynth/DG/deinterlace transcode video stream, copy audio stream for INTERLACED AVC AAC ====================================================== >> "!vrdlog!" 2>&1
			SET "the_FFMPEG_AUDIO_treatment=-c:a copy"
			call :run_ffmpeg_vapoursynth_DG_deinterlace_transcode
			ECHO ======================================================  Finish Run FFMPEG vapoursynth/DG/deinterlace transcode video stream, copy audio stream for INTERLACED AVC AAC ====================================================== >> "!vrdlog!" 2>&1
			IF /I "!EL!" NEQ "0" (
				call :move_to_bad "!the_Source_File!"
				goto :eof
			)
			ECHO MOVE /Y "!the_Source_File!" "!done_avc_aac!" >> "!vrdlog!" 2>&1
			MOVE /Y "!the_Source_File!" "!done_avc_aac!" >> "!vrdlog!" 2>&1
		) ELSE IF /I "!SRC_FF_A_codec_name!" == "mp3" (
			ECHO !DATE! !TIME! INTERLACED AVC MP3 >> "!vrdlog!" 2>&1
			REM c:v DEINTERLACE AND convert to H264 c:a CONVERT TO AAC
			REM --- USE DG and VAPOURSYNTH 
			ECHO ======================================================  Start Run FFMPEG vapoursynth/DG/deinterlace transcode video stream, transcode audio stream for INTERLACED AVC MP3 ====================================================== >> "!vrdlog!" 2>&1
			SET "the_FFMPEG_AUDIO_treatment=-c:a libfdk_aac -b:a 256k -ar 48000"
			call :run_ffmpeg_vapoursynth_DG_deinterlace_transcode
			ECHO ======================================================  Finish Run FFMPEG vapoursynth/DG/deinterlace transcode video stream, transcode audio stream for INTERLACED AVC MP3 ====================================================== >> "!vrdlog!" 2>&1
			IF /I "!EL!" NEQ "0" (
				call :move_to_bad "!the_Source_File!"
				goto :eof
			)
			ECHO MOVE /Y "!the_Source_File!" "!done_avc_mp3!" >> "!vrdlog!" 2>&1
			MOVE /Y "!the_Source_File!" "!done_avc_mp3!" >> "!vrdlog!" 2>&1
		) ELSE (
			ECHO !DATE! !TIME! INTERLACED AVC SRC_FF_A_codec_name "!SRC_FF_A_codec_name!" NOT IN ['.aac', '.mp3' ]
			ECHO !DATE! !TIME! the_Source_File="!the_Source_File!" >> "!vrdlog!" 2>&1
			REM !xPAUSE!
			REM EXIT
			call :move_to_bad "!the_Source_File!"
			goto :eof
		)
	) ELSE IF /I "!SRC_calc_Video_Encoding!" == "HEVC" (
		IF /I "!SRC_FF_A_codec_name!" == "aac" (
			ECHO !DATE! !TIME! INTERLACED HEVC AAC >> "!vrdlog!" 2>&1
			REM c:v DEINTERLACE AND convert to H264 c:a copy
			REM --- USE DG and VAPOURSYNTH 
			ECHO ======================================================  Start Run FFMPEG vapoursynth/DG/deinterlace transcode video stream, copy audio stream for INTERLACED HEVC AAC ====================================================== >> "!vrdlog!" 2>&1
			SET "the_FFMPEG_AUDIO_treatment=-c:a copy"
			call :run_ffmpeg_vapoursynth_DG_deinterlace_transcode
			ECHO ======================================================  Finish Run FFMPEG vapoursynth/DG/deinterlace transcode video stream, copy audio stream for INTERLACED HEVC AAC ====================================================== >> "!vrdlog!" 2>&1
			IF /I "!EL!" NEQ "0" (
				call :move_to_bad "!the_Source_File!"
				goto :eof
			)
			ECHO MOVE /Y "!the_Source_File!" "!done_h265_aac!" >> "!vrdlog!" 2>&1
			MOVE /Y "!the_Source_File!" "!done_h265_aac!" >> "!vrdlog!" 2>&1
		) ELSE IF /I "!SRC_FF_A_codec_name!" == "mp3" (
			ECHO !DATE! !TIME! INTERLACED HEVC MP3 >> "!vrdlog!" 2>&1
			REM c:v DEINTERLACE AND convert to H264 c:a CONVERT TO AAC
			REM --- USE DG and VAPOURSYNTH 
			ECHO ======================================================  Start Run FFMPEG vapoursynth/DG/deinterlace transcode video stream, transcode audio stream for INTERLACED HEVC MP3 ====================================================== >> "!vrdlog!" 2>&1
			SET "the_FFMPEG_AUDIO_treatment=-c:a libfdk_aac -b:a 256k -ar 48000"
			call :run_ffmpeg_vapoursynth_DG_deinterlace_transcode
			ECHO ======================================================  Finish Run FFMPEG vapoursynth/DG/deinterlace transcode video stream, transcode audio stream for INTERLACED HEVC MP3 ====================================================== >> "!vrdlog!" 2>&1
			IF /I "!EL!" NEQ "0" (
				call :move_to_bad "!the_Source_File!"
				goto :eof
			)
			ECHO MOVE /Y "!the_Source_File!" "!done_h265_mp3!" >> "!vrdlog!" 2>&1
			MOVE /Y "!the_Source_File!" "!done_h265_mp3!" >> "!vrdlog!" 2>&1
		) ELSE (
			ECHO !DATE! !TIME! INTERLACED HEVC SRC_FF_A_codec_name "!SRC_FF_A_codec_name!" NOT IN ['.aac', '.mp3' ] >> "!vrdlog!" 2>&1
			ECHO !DATE! !TIME! the_Source_File="!the_Source_File!" >> "!vrdlog!" 2>&1
			REM !xPAUSE!
			REM EXIT 1
			call :move_to_bad "!the_Source_File!"
			goto :eof
		)
	) ELSE (
		ECHO !DATE! !TIME! PROGRESSIVE SRC_calc_Video_Encoding "!SRC_calc_Video_Encoding!" not in [ 'AVC', 'HEVC' ] >> "!vrdlog!" 2>&1
		ECHO !DATE! !TIME! the_Source_File="!the_Source_File!" >> "!vrdlog!" 2>&1
		REM !xPAUSE!
		REM EXIT 1
		call :move_to_bad "!the_Source_File!"
		goto :eof
	)
) ELSE (
	ECHO !DATE! !TIME! SRC_calc_Video_Interlacement "!SRC_calc_Video_Interlacement!" NOT IN ['PROGRESSIVE', 'INTERLACED' ] >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! the_Source_File="!the_Source_File!" >> "!vrdlog!" 2>&1
	REM !xPAUSE!
	REM EXIT 1
	call :move_to_bad "!the_Source_File!"
	goto :eof
)
goto :eof


REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM
:run_ffmpeg_vapoursynth_DG_deinterlace_transcode
REM all the variables should have been set up by now
ECHO ======================================================  Start Run FFMPEG vapoursynth/DG/deinterlace transcode ====================================================== >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! ********** SRC_calc_Video_Is_Progessive_AVC=!SRC_calc_Video_Is_Progessive_AVC! ... so NOT Progressive-AVC ... transcode video and transcode audio >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! ********** NOT Progressive-AVC ... use ffmpeg and a .vpy to transcode video and transcode audio >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
REM set "FFMPEG_vspipe_cmd="!vspipeexe64!" --container y4m --filter-time "!the_VPY_file!" -"
set "FFMPEG_vspipe_cmd="!vspipeexe64!" --container y4m "!the_VPY_file!" -"
set "FFMPEG_cmd="!ffmpegexe64!""
set "FFMPEG_cmd=!FFMPEG_cmd! -hide_banner -v info -nostats"
REM set "FFMPEG_cmd=!FFMPEG_cmd! -hide_banner -v verbose -nostats"
set "FFMPEG_cmd=!FFMPEG_cmd! -f yuv4mpegpipe -i pipe: -probesize 100M -analyzeduration 100M"
set "FFMPEG_cmd=!FFMPEG_cmd! -i "!the_Source_File!""
set "FFMPEG_cmd=!FFMPEG_cmd! -map 0:v:0 -map 1:a:0"
set "FFMPEG_cmd=!FFMPEG_cmd! -vf "setdar=!SRC_MI_V_DisplayAspectRatio_String_slash!""
set "FFMPEG_cmd=!FFMPEG_cmd! -fps_mode passthrough -sws_flags lanczos+accurate_rnd+full_chroma_int+full_chroma_inp -strict experimental"
set "FFMPEG_cmd=!FFMPEG_cmd! -c:v h264_nvenc -pix_fmt nv12 -preset p7 -multipass fullres -forced-idr 1 -g !FFMPEG_V_G! -coder:v cabac"
set "FFMPEG_cmd=!FFMPEG_cmd! !FFMPEG_V_RTX2060super_extra_flags!"
set "FFMPEG_cmd=!FFMPEG_cmd! -rc:v vbr !FFMPEG_V_final_cq_options!"
set "FFMPEG_cmd=!FFMPEG_cmd! -b:v !FFMPEG_V_Target_BitRate! -minrate:v !FFMPEG_V_Target_Minimum_BitRate! -maxrate:v !FFMPEG_V_Target_Maximum_BitRate! -bufsize !FFMPEG_V_Target_Maximum_BitRate!"
set "FFMPEG_cmd=!FFMPEG_cmd! -strict experimental"
REM set "FFMPEG_cmd=!FFMPEG_cmd! -sws_flags lanczos+accurate_rnd+full_chroma_int+full_chroma_inp"
set "FFMPEG_cmd=!FFMPEG_cmd! -profile:v high -level 5.2 -movflags +faststart+write_colr"
set "FFMPEG_cmd=!FFMPEG_cmd! !the_FFMPEG_AUDIO_treatment!"
set "FFMPEG_cmd=!FFMPEG_cmd! -y "!the_Target_File!""
REM
REM ECHO "!vspipeexe64!" -h >> "!vrdlog!" 2>&1
REM "!vspipeexe64!" -h >> "!vrdlog!" 2>&1
ECHO "!vspipeexe64!" --version  >> "!vrdlog!" 2>&1
"!vspipeexe64!" --version  >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
ECHO "!vspipeexe64!" --info "!the_VPY_file!" >> "!vrdlog!" 2>&1
"!vspipeexe64!" --info "!the_VPY_file!" >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
REM ECHO "!vspipeexe64!" --filter-time --progress --container y4m "!the_VPY_file!" -- >> "!vrdlog!" 2>&1
REM "!vspipeexe64!" --filter-time --progress --container y4m "!the_VPY_file!" -- >> "!vrdlog!" 2>&1
REM ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
ECHO FFMPEG_vspipe_cmd='!FFMPEG_vspipe_cmd!' >> "!vrdlog!" 2>&1
ECHO FFMPEG_cmd='!FFMPEG_cmd!' >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
DEL /F "!temp_cmd_file!">NUL 2>&1
ECHO @ECHO ON>>"!temp_cmd_file!" 2>&1
ECHO !FFMPEG_vspipe_cmd!^^^|!FFMPEG_cmd!>>"!temp_cmd_file!" 2>&1
ECHO set "EL=^!ERRORLEVEL^!">>"!temp_cmd_file!" 2>&1
ECHO goto :eof>>"!temp_cmd_file!" 2>&1
ECHO TYPE "!temp_cmd_file!" >> "!vrdlog!" 2>&1
TYPE "!temp_cmd_file!" >> "!vrdlog!" 2>&1
ECHO CALL "!temp_cmd_file!" >> "!vrdlog!" 2>&1
REM CALL "!temp_cmd_file!" >> "!vrdlog!" 2>&1
IF /I "!EL!" NEQ "0" (
	set "check_QSF_failed=********** ERROR: Error Number '!EL!' returned from '!ffmpegexe64!' vapoursynth/DG/deinterlace transcode"
	ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! !check_QSF_failed! >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! the_Source_File="!the_Source_File!" >> "!vrdlog!" 2>&1
	REM !xPAUSE!
	REM exit !EL!
	REM call :move_to_bad "!the_Source_File!"
	goto :eof
)
ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
ECHO ======================================================  Finish Run FFMPEG vapoursynth/DG/deinterlace transcode ====================================================== >> "!vrdlog!" 2>&1
goto :eof



REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM
:move_to_bad
REM NOTES:
REM %~1  -  expands %1 removing any surrounding quotes (") 
REM %~f1  -  expands %1 to a fully qualified path name 
REM %~d1  -  expands %1 to a drive letter only 
REM %~p1  -  expands %1 to a path only 
REM %~n1  -  expands %1 to a file name only including the leading "."
REM %~x1  -  expands %1 to a file extension only 
REM %~s1  -  expanded path contains short names only 
REM %~a1  -  expands %1 to file attributes 
REM %~t1  -  expands %1 to date/time of file 
REM %~z1  -  expands %1 to size of file 
REM The modifiers can be combined to get compound results:
REM %~dp1  -  expands %1 to a drive letter and path only 
REM %~nx1  -  expands %1 to a file name and extension only 
ECHO !DATE! !TIME! ==================== START MOVE TO BAD "%~f1" ==================== >> "!vrdlog!" 2>&1
ECHO MOVE /Y "%~f1" "!done_bad!" >> "!vrdlog!" 2>&1
MOVE /Y "%~f1" "!done_bad!" >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! ==================== FINISH MOVE TO BAD "%~f1" ==================== >> "!vrdlog!" 2>&1
goto :eof


REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM
:clear_variables
ECHO FOR /F "tokens=1,* delims==" %%G IN ('SET SRC_') DO (set "%%G=") >> "!vrdlog!" 2>&1
FOR /F "tokens=1,* delims==" %%G IN ('SET SRC_') DO (set "%%G=")>NUL 2>&1

ECHO FOR /F "tokens=1,* delims==" %%G IN ('SET QSF_') DO (set "%%G=") >> "!vrdlog!" 2>&1
FOR /F "tokens=1,* delims==" %%G IN ('SET QSF_') DO (set "%%G=")>NUL 2>&1

ECHO FOR /F "tokens=1,* delims==" %%G IN ('SET TARGET_') DO (set "%%G=") >> "!vrdlog!" 2>&1
FOR /F "tokens=1,* delims==" %%G IN ('SET TARGET_') DO (set "%%G=")>NUL 2>&1

ECHO FOR /F "tokens=1,* delims==" %%G IN ('SET FFMPEG_') DO (set "%%G=") >> "!vrdlog!" 2>&1
FOR /F "tokens=1,* delims==" %%G IN ('SET FFMPEG_') DO (set "%%G=")>NUL 2>&1

ECHO FOR /F "tokens=1,* delims==" %%G IN ('SET Footy_') DO (set "%%G=") >> "!vrdlog!" 2>&1
FOR /F "tokens=1,* delims==" %%G IN ('SET Footy_') DO (set "%%G=")>NUL 2>&1

goto :eof


REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM
:gather_variables_from_media_file
REM Parameters
REM		1	the fully qualified filename of the media file, eg a .TS file etc
REM		2	the global prefix to use for this gather, one of "SRC_", "QSF_" "TARGET_"
REM NOTES:
REM %~1   -  expands %1 removing any surrounding quotes (") 
REM %~f1  -  expands %1 to a fully qualified path name 
REM %~d1  -  expands %1 to a drive letter only 
REM %~p1  -  expands %1 to a path only 
REM %~n1  -  expands %1 to a file name only including the leading "."
REM %~x1  -  expands %1 to a file extension only 
REM %~s1  -  expanded path contains short names only 
REM %~a1  -  expands %1 to file attributes 
REM %~t1  -  expands %1 to date/time of file 
REM %~z1  -  expands %1 to size of file 
REM The modifiers can be combined to get compound results:
REM %~dp1 -  expands %1 to a drive letter and path only 
REM %~nx1 -  expands ro name.extension 
REM DO NOT SET @setlocal ENABLEDELAYEDEXPANSION or this function will fail
REM DO NOT SET @setlocal enableextensions
REM ENSURE no trailing spaces in any of the lines in this routine !!
REM
set "media_filename=%~f1"
set "current_prefix=%~2"

CALL :get_date_time_String "gather_variables_from_media_file_START"

ECHO !DATE! !TIME! ====================================================================================================================================================== >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! Start collecting :gather_variables_from_media_file "!current_prefix!" ffprobe and mediainfo variables ... "!media_filename!" >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! ====================================================================================================================================================== >> "!vrdlog!" 2>&1

IF /I "!current_prefix!" == "SRC_" goto :is_valid_current_prefix
IF /I "!current_prefix!" == "QSF_" goto :is_valid_current_prefix
IF /I "!current_prefix!" == "TARGET_" goto :is_valid_current_prefix
	ECHO !DATE! !TIME! ?????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????? >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! ?????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????? >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! Invalid current_prefix "!current_prefix!" for "!media_filename!" >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! "!current_prefix!" MUST be one of "SRC_", "QSF_" "TARGET_" >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! ABORTING. >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! ?????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????? >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! ?????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????? >> "!vrdlog!" 2>&1
	!xPAUSE!
	exit 1
:is_valid_current_prefix
set "derived_prefix_FF=!current_prefix!FF_"
set "derived_prefix_MI=!current_prefix!MI_"
REM ---
ECHO !DATE! !TIME! ====================================================================================================================================================== >> "!vrdlog!" 2>&1
ECHO DEL /F "!temp_cmd_file!" >> "!vrdlog!" 2>&1
DEL /F "!temp_cmd_file!" >> "!vrdlog!" 2>&1
ECHO FOR /F "tokens=1,* delims==" %%G IN ('SET !derived_prefix_FF!') DO (set "%%G=") >> "!vrdlog!" 2>&1
FOR /F "tokens=1,* delims==" %%G IN ('SET !derived_prefix_FF!') DO (set "%%G=")>NUL 2>&1
ECHO "!py_exe!" "!Path_to_py_VRDTVSP_Set_ffprobe_Variables_for_first_stream_in_section!" --ffprobe_dos_variablename "ffprobeexe64" --mediafile "!media_filename!" --prefix "!derived_prefix_FF!" --output_cmd_file="!temp_cmd_file!" >> "!vrdlog!" 2>&1
"!py_exe!" "!Path_to_py_VRDTVSP_Set_ffprobe_Variables_for_first_stream_in_section!" --ffprobe_dos_variablename "ffprobeexe64" --mediafile "!media_filename!" --prefix "!derived_prefix_FF!" --output_cmd_file="!temp_cmd_file!" >> "!vrdlog!" 2>&1
SET EL=!ERRORLEVEL!
IF /I "!EL!" NEQ "0" (
   ECHO !DATE! !TIME! **********  ffprobe "!derived_prefix_FF!" Error !EL! returned from !Path_to_py_VRDTVSP_Set_Mediainfo_Variables_for_first_stream_in_section! >> "!vrdlog!" 2>&1
   ECHO !DATE! !TIME! **********  ABORTING ... >> "!vrdlog!" 2>&1
   !xPAUSE!
   EXIT !EL!
)
ECHO ### "!derived_prefix_FF!" >> "!vrdlog!" 2>&1
REM ECHO TYPE "!temp_cmd_file!" >> "!vrdlog!" 2>&1
REM TYPE "!temp_cmd_file!" >> "!vrdlog!" 2>&1
ECHO call "!temp_cmd_file!" >> "!vrdlog!" 2>&1
call "!temp_cmd_file!" >> "!vrdlog!" 2>&1
ECHO DEL /F "!temp_cmd_file!" >> "!vrdlog!" 2>&1
DEL /F "!temp_cmd_file!" >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! ====================================================================================================================================================== >> "!vrdlog!" 2>&1
ECHO DEL /F "!temp_cmd_file!" >> "!vrdlog!" 2>&1
DEL /F "!temp_cmd_file!" >> "!vrdlog!" 2>&1
ECHO FOR /F "tokens=1,* delims==" %%G IN ('SET !derived_prefix_MI!') DO (set "%%G=") >> "!vrdlog!" 2>&1
FOR /F "tokens=1,* delims==" %%G IN ('SET !derived_prefix_MI!') DO (set "%%G=")>NUL 2>&1
ECHO "!py_exe!" "!Path_to_py_VRDTVSP_Set_Mediainfo_Variables_for_first_stream_in_section!" --mediainfo_dos_variablename "mediainfoexe64" --mediafile "!media_filename!" --prefix "!derived_prefix_MI!" --output_cmd_file="!temp_cmd_file!" >> "!vrdlog!" 2>&1
"!py_exe!" "!Path_to_py_VRDTVSP_Set_Mediainfo_Variables_for_first_stream_in_section!" --mediainfo_dos_variablename "mediainfoexe64" --mediafile "!media_filename!" --prefix "!derived_prefix_MI!" --output_cmd_file="!temp_cmd_file!" >> "!vrdlog!" 2>&1
SET EL=!ERRORLEVEL!
IF /I "!EL!" NEQ "0" (
   ECHO !DATE! !TIME! **********  mediainfo "!derived_prefix_MI!" Error !EL! returned from !Path_to_py_VRDTVSP_Set_ffprobe_Variables_for_first_stream_in_section! >> "!vrdlog!" 2>&1
   ECHO !DATE! !TIME! **********  ABORTING ... >> "!vrdlog!" 2>&1
   !xPAUSE!
   EXIT !EL!
)
ECHO ### "!derived_prefix_MI!" >> "!vrdlog!" 2>&1
REM ECHO TYPE "!temp_cmd_file!" >> "!vrdlog!" 2>&1
REM TYPE "!temp_cmd_file!" >> "!vrdlog!" 2>&1
ECHO call "!temp_cmd_file!" >> "!vrdlog!" 2>&1
call "!temp_cmd_file!" >> "!vrdlog!" 2>&1
ECHO DEL /F "!temp_cmd_file!" >> "!vrdlog!" 2>&1
DEL /F "!temp_cmd_file!" >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! ====================================================================================================================================================== >> "!vrdlog!" 2>&1
REM list initial variables we created for "!current_prefix!" and "!media_filename!"
REM ECHO !DATE! !TIME! List initial "!current_prefix!" variables for "!media_filename!" >> "!vrdlog!" 2>&1
REM ECHO set !current_prefix! >> "!vrdlog!" 2>&1
REM set !current_prefix! >> "!vrdlog!" 2>&1
REM ECHO !DATE! !TIME! ====================================================================================================================================================== >> "!vrdlog!" 2>&1
REM ECHO !DATE! !TIME! Start of NOTES: >> "!vrdlog!" 2>&1
REM ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
REM ECHO !DATE! !TIME! AVC Interlaced type #1 .TS >> "!vrdlog!" 2>&1
REM ECHO !DATE! !TIME!    !current_prefix!MI_V_CodecID=27 >> "!vrdlog!" 2>&1
REM ECHO !DATE! !TIME!    !current_prefix!MI_G_Format=MPEG-TS >> "!vrdlog!" 2>&1
REM ECHO !DATE! !TIME!    !current_prefix!MI_V_Format=AVC >> "!vrdlog!" 2>&1
REM ECHO !DATE! !TIME!    !current_prefix!FF_V_codec_name=h264 >> "!vrdlog!" 2>&1
REM ECHO !DATE! !TIME!    !current_prefix!FF_V_field_order=tt >> "!vrdlog!" 2>&1
REM ECHO !DATE! !TIME!    !current_prefix!MI_V_ScanOrder=TFF >> "!vrdlog!" 2>&1
REM ECHO !DATE! !TIME!    !current_prefix!MI_V_ScanType=Interlaced >> "!vrdlog!" 2>&1
REM ECHO !DATE! !TIME!    !current_prefix!MI_V_ScanType_StoreMethod=SeparatedFields >> "!vrdlog!" 2>&1
REM ECHO !DATE! !TIME!    !current_prefix!FF_V_display_aspect_ratio=16:9 >> "!vrdlog!" 2>&1
REM ECHO !DATE! !TIME!    !current_prefix!MI_V_DisplayAspectRatio_String=16:9 >> "!vrdlog!" 2>&1
REM ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
REM ECHO !DATE! !TIME! AVC Interlaced type #2 >> "!vrdlog!" 2>&1
REM ECHO !DATE! !TIME!    !current_prefix!MI_V_CodecID=27 >> "!vrdlog!" 2>&1
REM ECHO !DATE! !TIME!    !current_prefix!MI_G_Format=MPEG-TS >> "!vrdlog!" 2>&1
REM ECHO !DATE! !TIME!    !current_prefix!MI_V_Format=AVC >> "!vrdlog!" 2>&1
REM ECHO !DATE! !TIME!    !current_prefix!FF_V_codec_name=h264 >> "!vrdlog!" 2>&1
REM ECHO !DATE! !TIME!    !current_prefix!FF_V_field_order=tt >> "!vrdlog!" 2>&1
REM ECHO !DATE! !TIME!    !current_prefix!MI_V_ScanOrder=TFF >> "!vrdlog!" 2>&1
REM ECHO !DATE! !TIME!    !current_prefix!MI_V_ScanType=MBAFF >> "!vrdlog!" 2>&1
REM ECHO !DATE! !TIME!    !current_prefix!MI_V_ScanType_StoreMethod=InterleavedFields >> "!vrdlog!" 2>&1
REM ECHO !DATE! !TIME!    !current_prefix!FF_V_display_aspect_ratio=16:9 >> "!vrdlog!" 2>&1
REM ECHO !DATE! !TIME!    !current_prefix!MI_V_DisplayAspectRatio_String=16:9 >> "!vrdlog!" 2>&1
REM ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
REM ECHO !DATE! !TIME! AVC Interlaced type #3 .mp4 >> "!vrdlog!" 2>&1
REM ECHO !DATE! !TIME!    !current_prefix!MI_V_CodecID=avc1 >> "!vrdlog!" 2>&1
REM ECHO !DATE! !TIME!    !current_prefix!MI_G_Format=MPEG-4 >> "!vrdlog!" 2>&1
REM ECHO !DATE! !TIME!    !current_prefix!MI_V_Format=AVC >> "!vrdlog!" 2>&1
REM ECHO !DATE! !TIME!    !current_prefix!FF_V_codec_name=h264 >> "!vrdlog!" 2>&1
REM ECHO !DATE! !TIME!    !current_prefix!FF_V_field_order=tt >> "!vrdlog!" 2>&1
REM ECHO !DATE! !TIME!    !current_prefix!MI_V_ScanOrder=TFF >> "!vrdlog!" 2>&1
REM ECHO !DATE! !TIME!    !current_prefix!MI_V_ScanType=MBAFF >> "!vrdlog!" 2>&1
REM ECHO !DATE! !TIME!    !current_prefix!MI_V_ScanType_StoreMethod=InterleavedFields >> "!vrdlog!" 2>&1
REM ECHO !DATE! !TIME!    !current_prefix!FF_V_display_aspect_ratio=16:9 >> "!vrdlog!" 2>&1
REM ECHO !DATE! !TIME!    !current_prefix!MI_V_DisplayAspectRatio_String=16:9 >> "!vrdlog!" 2>&1
REM ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
REM ECHO !DATE! !TIME! AVC Interlaced type #4 .mp4 >> "!vrdlog!" 2>&1
REM ECHO !DATE! !TIME!    !current_prefix!MI_V_CodecID_Info=Advanced_Video_Coding >> "!vrdlog!" 2>&1
REM ECHO !DATE! !TIME!    !current_prefix!MI_G_Format=MPEG-4 >> "!vrdlog!" 2>&1
REM ECHO !DATE! !TIME!    !current_prefix!MI_V_Format=AVC >> "!vrdlog!" 2>&1
REM ECHO !DATE! !TIME!    !current_prefix!FF_V_codec_name=h264 >> "!vrdlog!" 2>&1
REM ECHO !DATE! !TIME!    !current_prefix!FF_V_field_order=tt >> "!vrdlog!" 2>&1
REM ECHO !DATE! !TIME!    !current_prefix!MI_V_ScanOrder=TFF >> "!vrdlog!" 2>&1
REM ECHO !DATE! !TIME!    !current_prefix!MI_V_ScanType=MBAFF >> "!vrdlog!" 2>&1
REM ECHO !DATE! !TIME!    !current_prefix!MI_V_ScanType_StoreMethod=InterleavedFields >> "!vrdlog!" 2>&1
REM ECHO !DATE! !TIME!    !current_prefix!FF_V_display_aspect_ratio=16:9 >> "!vrdlog!" 2>&1
REM ECHO !DATE! !TIME!    !current_prefix!MI_V_DisplayAspectRatio_String=16:9 >> "!vrdlog!" 2>&1
REM ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
REM ECHO !DATE! !TIME! MPEG2 INTERLACED >> "!vrdlog!" 2>&1
REM ECHO !DATE! !TIME!    !current_prefix!MI_V_CodecID=2 >> "!vrdlog!" 2>&1
REM ECHO !DATE! !TIME!    !current_prefix!MI_G_Format=MPEG-TS >> "!vrdlog!" 2>&1
REM ECHO !DATE! !TIME!    !current_prefix!MI_V_Format=MPEG_Video >> "!vrdlog!" 2>&1
REM ECHO !DATE! !TIME!    !current_prefix!FF_V_codec_name=mpeg2video >> "!vrdlog!" 2>&1
REM ECHO !DATE! !TIME!    !current_prefix!FF_V_field_order=tt >> "!vrdlog!" 2>&1
REM ECHO !DATE! !TIME!    !current_prefix!MI_V_ScanOrder=TFF >> "!vrdlog!" 2>&1
REM ECHO !DATE! !TIME!    !current_prefix!MI_V_ScanType=Interlaced >> "!vrdlog!" 2>&1
REM ECHO !DATE! !TIME!    !current_prefix!MI_V_ScanType_StoreMethod= >> "!vrdlog!" 2>&1
REM ECHO !DATE! !TIME!    !current_prefix!FF_V_display_aspect_ratio=16:9 >> "!vrdlog!" 2>&1
REM ECHO !DATE! !TIME!    !current_prefix!MI_V_DisplayAspectRatio_String=16:9 >> "!vrdlog!" 2>&1
REM ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
REM ECHO !DATE! !TIME! MPEG2 PROGRESSIVE >> "!vrdlog!" 2>&1
REM ECHO !DATE! !TIME!    !current_prefix!MI_V_CodecID=2 >> "!vrdlog!" 2>&1
REM ECHO !DATE! !TIME!    !current_prefix!MI_G_Format=MPEG-TS >> "!vrdlog!" 2>&1
REM ECHO !DATE! !TIME!    !current_prefix!MI_V_Format=MPEG_Video >> "!vrdlog!" 2>&1
REM ECHO !DATE! !TIME!    !current_prefix!FF_V_codec_name=mpeg2video >> "!vrdlog!" 2>&1
REM ECHO !DATE! !TIME!    !current_prefix!FF_V_field_order=progressive >> "!vrdlog!" 2>&1
REM ECHO !DATE! !TIME!    !current_prefix!MI_V_ScanOrder= >> "!vrdlog!" 2>&1
REM ECHO !DATE! !TIME!    !current_prefix!MI_V_ScanType= >> "!vrdlog!" 2>&1
REM ECHO !DATE! !TIME!    !current_prefix!MI_V_ScanType_StoreMethod= >> "!vrdlog!" 2>&1
REM ECHO !DATE! !TIME!    !current_prefix!FF_V_display_aspect_ratio=16:9 >> "!vrdlog!" 2>&1
REM ECHO !DATE! !TIME!    !current_prefix!MI_V_DisplayAspectRatio_String=16:9 >> "!vrdlog!" 2>&1
REM ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
REM ECHO !DATE! !TIME! End of NOTES: >> "!vrdlog!" 2>&1
REM ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1

REM
REM Fix up and calculate some variables
REM

REM sometimes mediainfo omits to return the video bit_rate oin .TS files, so fudge it using other detected bitrates
call set tmp_MI_V_BitRate=%%!current_prefix!MI_V_BitRate%%
ECHO Fudge Check #1 !current_prefix!MI_V_BitRate '!tmp_MI_V_BitRate!' for blank ... >> "!vrdlog!" 2>&1
IF /I "!tmp_MI_V_BitRate!" == "" (
	ECHO set !current_prefix!MI_V_BitRate >> "!vrdlog!" 2>&1
	set !current_prefix!MI_V_BitRate >> "!vrdlog!" 2>&1
	ECHO set !current_prefix!MI_G_OverallBitRate >> "!vrdlog!" 2>&1
	set !current_prefix!MI_G_OverallBitRate >> "!vrdlog!" 2>&1
	ECHO set !current_prefix!FF_G_bit_rate >> "!vrdlog!" 2>&1
	set !current_prefix!FF_G_bit_rate >> "!vrdlog!" 2>&1
	ECHO WARNING: !current_prefix!MI_V_BitRate '!tmp_MI_V_BitRate!' was blank, attempting to fudge to !current_prefix!FF_G_bit_rate >> "!vrdlog!" 2>&1
	REM
	call set !current_prefix!MI_V_BitRate=%%!current_prefix!FF_G_bit_rate%%
)
call set tmp_MI_V_BitRate=%%!current_prefix!MI_V_BitRate%%
ECHO Fudge Check #2 !current_prefix!MI_V_BitRate '!tmp_MI_V_BitRate!' for blank ... >> "!vrdlog!" 2>&1
IF /I "!tmp_MI_V_BitRate!" == "" (
	ECHO set !current_prefix!MI_V_BitRate >> "!vrdlog!" 2>&1
	set !current_prefix!MI_V_BitRate >> "!vrdlog!" 2>&1
	ECHO set !current_prefix!MI_G_OverallBitRate >> "!vrdlog!" 2>&1
	set !current_prefix!MI_G_OverallBitRate >> "!vrdlog!" 2>&1
	ECHO set !current_prefix!FF_G_bit_rate >> "!vrdlog!" 2>&1
	set !current_prefix!FF_G_bit_rate >> "!vrdlog!" 2>&1
	ECHO WARNING: !current_prefix!MI_V_BitRate '!tmp_MI_V_BitRate!' was blank, attempting to fudge to !current_prefix!MI_G_OverallBitRate >> "!vrdlog!" 2>&1
	REM
	call set !current_prefix!MI_V_BitRate=%%!current_prefix!MI_G_OverallBitRate%%
)
call set tmp_MI_V_BitRate=%%!current_prefix!MI_V_BitRate%%
ECHO Fudge Check #3 !current_prefix!MI_V_BitRate '!tmp_MI_V_BitRate!' for blank ... >> "!vrdlog!" 2>&1
IF /I "!tmp_MI_V_BitRate!" == "" (
	ECHO set !current_prefix!MI_V_BitRate >> "!vrdlog!" 2>&1
	set !current_prefix!MI_V_BitRate >> "!vrdlog!" 2>&1
	ECHO set !current_prefix!MI_G_OverallBitRate >> "!vrdlog!" 2>&1
	set !current_prefix!MI_G_OverallBitRate >> "!vrdlog!" 2>&1
	ECHO set !current_prefix!FF_G_bit_rate >> "!vrdlog!" 2>&1
	set !current_prefix!FF_G_bit_rate >> "!vrdlog!" 2>&1
	ECHO ERROR: Unable to detect !current_prefix!MI_V_BitRate '!tmp_MI_V_BitRate!', failed to fudge it, Aborting >> "!vrdlog!" 2>&1
	exit 1
)

REM get a slash version of MI_V_DisplayAspectRatio_String
call set !current_prefix!MI_V_DisplayAspectRatio_String_slash=%%!current_prefix!MI_V_DisplayAspectRatio_String%%
call set !current_prefix!MI_V_DisplayAspectRatio_String_slash=%%!current_prefix!MI_V_DisplayAspectRatio_String_slash::=/%%
call set !current_prefix!MI_V_DisplayAspectRatio_String_slash=%%!current_prefix!MI_V_DisplayAspectRatio_String_slash::\=/%%
ECHO +++++++++ >> "!vrdlog!" 2>&1
ECHO set !current_prefix!MI_V_DisplayAspectRatio_String >> "!vrdlog!" 2>&1
set !current_prefix!MI_V_DisplayAspectRatio_String >> "!vrdlog!" 2>&1
ECHO +++++++++ >> "!vrdlog!" 2>&1

REM get a slash version of FF_V_display_aspect_ratio
call set !current_prefix!FF_V_display_aspect_ratio_slash=%%!current_prefix!FF_V_display_aspect_ratio%%
call set !current_prefix!FF_V_display_aspect_ratio_slash=%%!current_prefix!FF_V_display_aspect_ratio_slash::=/%%
call set !current_prefix!FF_V_display_aspect_ratio_slash=%%!current_prefix!FF_V_display_aspect_ratio_slash::\=/%%
ECHO +++++++++ >> "!vrdlog!" 2>&1
ECHO set !current_prefix!FF_V_display_aspect_ratio >> "!vrdlog!" 2>&1
set !current_prefix!FF_V_display_aspect_ratio >> "!vrdlog!" 2>&1
ECHO +++++++++ >> "!vrdlog!" 2>&1

REM calculate MI_A_Audio_Delay from MI_A_Video_Delay
REM MI_A_Video_Delay is reported by mediainfo as decimal seconds, not milliseconds, so up-convert it
call set tmp_MI_A_Video_Delay=%%!current_prefix!MI_A_Video_Delay%%
IF /I "!tmp_MI_A_Video_Delay!" == "" (set "tmp_MI_A_Video_Delay=0")
set "py_eval_string=int(1000.0 * !tmp_MI_A_Video_Delay!)"
CALL :calc_single_number_result_py "!py_eval_string!" "tmp_MI_A_Video_Delay"
set /a tmp_MI_A_Audio_Delay=0 - !tmp_MI_A_Video_Delay!
set "!current_prefix!MI_A_Video_Delay=!tmp_MI_A_Video_Delay!"
set "!current_prefix!MI_A_Audio_Delay=!tmp_MI_A_Audio_Delay!"
ECHO +++++++++ >> "!vrdlog!" 2>&1
ECHO set !current_prefix!MI_A_Video_Delay >> "!vrdlog!" 2>&1
set !current_prefix!MI_A_Video_Delay >> "!vrdlog!" 2>&1
ECHO set !current_prefix!MI_A_Audio_Delay >> "!vrdlog!" 2>&1
set !current_prefix!MI_A_Audio_Delay >> "!vrdlog!" 2>&1
ECHO +++++++++ >> "!vrdlog!" 2>&1

REM Determine which type of encoding, AVC or MPEG2 or HEVC or VP9
call set tmp_MI_V_Format=%%!current_prefix!MI_V_Format%%
call set tmp_FF_V_codec_name=%%!current_prefix!FF_V_codec_name%%
set "!current_prefix!calc_Video_Encoding=VP9"
set "!current_prefix!calc_Video_Encoding_original=VP9"
IF /I "!tmp_MI_V_Format!" == "AVC"            (set "!current_prefix!calc_Video_Encoding=AVC")
IF /I "!tmp_FF_V_codec_name!" == "h264"       (set "!current_prefix!calc_Video_Encoding=AVC")
IF /I "!tmp_MI_V_Format!" == "MPEG_Video"     (set "!current_prefix!calc_Video_Encoding=MPEG2")
IF /I "!tmp_FF_V_codec_name!" == "mpeg2video" (set "!current_prefix!calc_Video_Encoding=MPEG2")
IF /I "!tmp_MI_V_Format!" == "HEVC"           (set "!current_prefix!calc_Video_Encoding=HEVC")
IF /I "!tmp_FF_V_codec_name!" == "hevc"       (set "!current_prefix!calc_Video_Encoding=HEVC")
IF /I "!tmp_MI_V_Format!" == "vp09"           (set "!current_prefix!calc_Video_Encoding=VP9")
IF /I "!tmp_FF_V_codec_name!" == "vp9"        (set "!current_prefix!calc_Video_Encoding=VP9")
call set !current_prefix!calc_Video_Encoding_original=%%!current_prefix!calc_Video_Encoding%%
REM ***** Trick conversion by fooling info unknown input is HEVC which could in the future force re-encoding into h.264 AVC
call set tmp_FF_V_codec_name_original=%%!current_prefix!calc_Video_Encoding_original%%
call set tmp_FF_V_codec_name_original=%%!current_prefix!calc_Video_Encoding_original%%
IF /I NOT "!tmp_FF_V_codec_name_original!" == "AVC" (
	IF /I NOT "!tmp_FF_V_codec_name_original!" == "HEVC" (
		IF /I NOT "!tmp_FF_V_codec_name_original!" == "MPEG2" (
			REM IF /I NOT "!tmp_FF_V_codec_name_original!" == "VP9" (
				set "!current_prefix!calc_Video_Encoding=HEVC"
			REM )
		)
	)
)
REM ECHO +++++++++ >> "!vrdlog!" 2>&1
REM ECHO set tmp_MI_V_Format >> "!vrdlog!" 2>&1
REM set tmp_MI_V_Format >> "!vrdlog!" 2>&1
REM ECHO +++++++++ >> "!vrdlog!" 2>&1
REM ECHO set tmp_FF_V_codec_name >> "!vrdlog!" 2>&1
REM set tmp_FF_V_codec_name >> "!vrdlog!" 2>&1
ECHO +++++++++ >> "!vrdlog!" 2>&1
ECHO set !current_prefix!calc_Video_Encoding_original >> "!vrdlog!" 2>&1
set !current_prefix!calc_Video_Encoding_original >> "!vrdlog!" 2>&1
ECHO set !current_prefix!calc_Video_Encoding >> "!vrdlog!" 2>&1
set !current_prefix!calc_Video_Encoding >> "!vrdlog!" 2>&1
ECHO +++++++++ >> "!vrdlog!" 2>&1

REM Determine whether PROGRESSIVE or INTERLACED
call set tmp_MI_V_ScanType=%%!current_prefix!MI_V_ScanType%%
call set tmp_FF_V_field_order=%%!current_prefix!FF_V_field_order%%
set "!current_prefix!calc_Video_Interlacement=PROGRESSIVE"
IF /I "!tmp_MI_V_ScanType!" == "MBAFF"          (set "!current_prefix!calc_Video_Interlacement=INTERLACED")
IF /I "!tmp_MI_V_ScanType!" == "Interlaced"     (set "!current_prefix!calc_Video_Interlacement=INTERLACED")
IF /I "!tmp_FF_V_field_order!" == "tt"          (set "!current_prefix!calc_Video_Interlacement=INTERLACED")
IF /I "!tmp_MI_V_ScanType!" == ""               (set "!current_prefix!calc_Video_Interlacement=PROGRESSIVE")
IF /I "!tmp_FF_V_field_order!" == "progressive" (set "!current_prefix!calc_Video_Interlacement=PROGRESSIVE")
ECHO +++++++++ >> "!vrdlog!" 2>&1
ECHO set tmp_MI_V_ScanType >> "!vrdlog!" 2>&1
set tmp_MI_V_ScanType >> "!vrdlog!" 2>&1
ECHO +++++++++ >> "!vrdlog!" 2>&1
ECHO set tmp_FF_V_field_order >> "!vrdlog!" 2>&1
set tmp_FF_V_field_order >> "!vrdlog!" 2>&1
ECHO +++++++++ >> "!vrdlog!" 2>&1
ECHO set !current_prefix!calc_Video_Interlacement >> "!vrdlog!" 2>&1
set !current_prefix!calc_Video_Interlacement >> "!vrdlog!" 2>&1
ECHO +++++++++ >> "!vrdlog!" 2>&1

REM Determine FIELD ORDER for interlaced
call set tmp_MI_V_ScanOrder=%%!current_prefix!MI_V_ScanOrder%%
set "!current_prefix!calc_Video_FieldFirst=TFF"
IF /I "!tmp_MI_V_ScanOrder!" == ""    (set "!current_prefix!calc_Video_FieldFirst=TFF")
IF /I "!tmp_MI_V_ScanOrder!" == "TFF" (set "!current_prefix!calc_Video_FieldFirst=TFF")
IF /I "!tmp_MI_V_ScanOrder!" == "BFF" (set "!current_prefix!calc_Video_FieldFirst=BFF")
REM ECHO +++++++++ >> "!vrdlog!" 2>&1
REM ECHO set tmp_MI_V_ScanOrder >> "!vrdlog!" 2>&1
REM set tmp_MI_V_ScanOrder >> "!vrdlog!" 2>&1
REM ECHO +++++++++ >> "!vrdlog!" 2>&1
ECHO set !current_prefix!calc_Video_FieldFirst >> "!vrdlog!" 2>&1
set !current_prefix!calc_Video_FieldFirst >> "!vrdlog!" 2>&1
ECHO +++++++++ >> "!vrdlog!" 2>&1

call set tmp_calc_Video_Interlacement=%%!current_prefix!calc_Video_Interlacement%%
call set tmp_calc_Video_Encoding=%%!current_prefix!calc_Video_Encoding%%
set "!current_prefix!calc_Video_Is_Progessive_AVC=False"
IF /I "!tmp_calc_Video_Interlacement!" == "PROGRESSIVE" ( 
	IF /I "!tmp_calc_Video_Encoding!" == "AVC" (
		set "!current_prefix!calc_Video_Is_Progessive_AVC=True"
	)
)

REM display all calculated variables
ECHO +++++++++ >> "!vrdlog!" 2>&1
ECHO :gather_variables_from_media_file display all calculated variables >> "!vrdlog!" 2>&1
ECHO :gather_variables_from_media_file set !current_prefix!calc >> "!vrdlog!" 2>&1
set !current_prefix!calc >> "!vrdlog!" 2>&1
ECHO +++++++++ >> "!vrdlog!" 2>&1

REM display calculated variables individually
ECHO +++++++++ >> "!vrdlog!" 2>&1
call set tmp_calc_Video_Encoding=%%!current_prefix!calc_Video_Encoding%%
call set tmp_calc_Video_Interlacement=%%!current_prefix!calc_Video_Interlacement%%
call set tmp_calc_Video_FieldFirst=%%!current_prefix!calc_Video_FieldFirst%%
ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! :gather_variables_from_media_file !current_prefix!calc_Video_Encoding=!tmp_calc_Video_Encoding! >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! :gather_variables_from_media_file !current_prefix!calc_Video_Interlacement=!tmp_calc_Video_Interlacement! >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! :gather_variables_from_media_file !current_prefix!calc_Video_FieldFirst=!tmp_calc_Video_FieldFirst! >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
ECHO +++++++++ >> "!vrdlog!" 2>&1

REM ECHO !DATE! !TIME! ====================================================================================================================================================== >> "!vrdlog!" 2>&1
REM ECHO !DATE! !TIME! List all  "!current_prefix!" variables for "!media_filename!" >> "!vrdlog!" 2>&1
REM ECHO set !current_prefix! >> "!vrdlog!" 2>&1
REM set !current_prefix! >> "!vrdlog!" 2>&1
REM ECHO !DATE! !TIME! ====================================================================================================================================================== >> "!vrdlog!" 2>&1

REM ECHO !DATE! !TIME! ====================================================================================================================================================== >> "!vrdlog!" 2>&1
REM ECHO "!mediainfoexe64!" "!media_filename!" --full >> "!vrdlog!" 2>&1
REM "!mediainfoexe64!" "!media_filename!" --full >> "!vrdlog!" 2>&1
REM ECHO !DATE! !TIME! ====================================================================================================================================================== >> "!vrdlog!" 2>&1
REM ECHO "!ffprobeexe64!" -v verbose -select_streams v:0 -show_entries stream -of default "!media_filename!" >> "!vrdlog!" 2>&1
REM "!ffprobeexe64!" -v verbose -select_streams v:0 -show_entries stream -of default "!media_filename!" >> "!vrdlog!" 2>&1
REM ECHO !DATE! !TIME! ====================================================================================================================================================== >> "!vrdlog!" 2>&1
REM ECHO "!ffprobeexe64!" -v verbose -select_streams a:0 -show_entries stream -of default "!media_filename!" >> "!vrdlog!" 2>&1
REM "!ffprobeexe64!" -v verbose -select_streams a:0 -show_entries stream -of default "!media_filename!" >> "!vrdlog!" 2>&1
REM ECHO !DATE! !TIME! ====================================================================================================================================================== >> "!vrdlog!" 2>&1

ECHO !DATE! !TIME! ====================================================================================================================================================== >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! End collecting :gather_variables_from_media_file "!current_prefix!" ffprobe and mediainfo variables ... "!media_filename!" >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! ====================================================================================================================================================== >> "!vrdlog!" 2>&1

CALL :get_date_time_String "gather_variables_from_media_file_END"
REM ECHO "!py_exe!" "!Path_to_py_VRDTVSP_Calculate_Duration!" --start_datetime "!gather_variables_from_media_file_START!" --end_datetime "!gather_variables_from_media_file_END!" --prefix_id "gather !current_prefix!" >> "!vrdlog!" 2>&1
"!py_exe!" "!Path_to_py_VRDTVSP_Calculate_Duration!" --start_datetime "!gather_variables_from_media_file_START!" --end_datetime "!gather_variables_from_media_file_END!" --prefix_id "gather !current_prefix!" >> "!vrdlog!" 2>&1

goto :eof


REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM
:LoCase
REM Subroutine to convert a variable VALUE to all lower case.
REM The argument for this subroutine is the variable NAME.
FOR %%i IN ("A=a" "B=b" "C=c" "D=d" "E=e" "F=f" "G=g" "H=h" "I=i" "J=j" "K=k" "L=l" "M=m" "N=n" "O=o" "P=p" "Q=q" "R=r" "S=s" "T=t" "U=u" "V=v" "W=w" "X=x" "Y=y" "Z=z") DO CALL set "%1=%%%1:%%~i%%"
goto :eof

:UpCase
REM Subroutine to convert a variable VALUE to all UPPER CASE.
REM The argument for this subroutine is the variable NAME.
FOR %%i IN ("a=A" "b=B" "c=C" "d=D" "e=E" "f=F" "g=G" "h=H" "i=I" "j=J" "k=K" "l=L" "m=M" "n=N" "o=O" "p=P" "q=Q" "r=R" "s=S" "t=T" "u=U" "v=V" "w=W" "x=X" "y=Y" "z=Z") DO CALL set "%1=%%%1:%%~i%%"
goto :eof

:TCase
REM Subroutine to convert a variable VALUE to Title Case.
REM The argument for this subroutine is the variable NAME.
FOR %%i IN (" a= A" " b= B" " c= C" " d= D" " e= E" " f= F" " g= G" " h= H" " i= I" " j= J" " k= K" " l= L" " m= M" " n= N" " o= O" " p= P" " q= Q" " r= R" " s= S" " t= T" " u= U" " v= V" " w= W" " x= X" " y= Y" " z= Z") DO CALL set "%1=%%%1:%%~i%%"
goto :eof


REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM
:calc_single_number_result
REM use VBS to evaluate an incoming formula string which has no embedded special characters 
REM and yield a result which has no embedded special characters
REM eg   CALL :calc_single_number_result "Int((1+2+3+4+5+6)/10.0)" "return_variable_name"
set "Datey=%DATE: =0%"
set "Timey=%time: =0%"
set "eval_datetime=!Datey:~10,4!-!Datey:~7,2!-!Datey:~4,2!.!Timey:~0,2!.!Timey:~3,2!.!Timey:~6,2!.!Timey:~9,2!"
set "eval_datetime=!eval_datetime: =0!"
set "eval_formula_vbs_filename=.\VTDTVS_eval_formula-!eval_datetime!.vbs"
set "eval_formula=%~1"
set "eval_variable_name=%~2"
set "eval_single_number_result="
REM ECHO 'cscript //nologo "!eval_formula_vbs_filename!" "!eval_formula!"'
for /f %%A in ('cscript //nologo "!eval_formula_vbs_filename!" "!eval_formula!"') do (
    set "!eval_variable_name!=%%A"
    set "eval_single_number_result=%%A"
)
DEL /F "!eval_formula_vbs_filename!" >NUL 2>&1
REM ECHO "eval_formula_vbs_filename=!eval_formula_vbs_filename!"
REM ECHO "eval_variable_name=!eval_variable_name! eval_formula=!eval_formula! eval_single_number_result=!eval_single_number_result!"
goto :eof


REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM
:calc_single_number_result_py
REM Use Python to evaluate an incoming formula string which has no embedded special characters 
REM and yield a result which has no embedded special characters
REM Example usage: CALL :calc_single_number_result "1+2+3+4+5+6" "return_variable_name"
set "eval_formula=%~1"
set "eval_variable_name=%~2"
set "Datey=%DATE: =0%"
set "Timey=%time: =0%"
set "eval_datetime=!Datey:~10,4!-!Datey:~7,2!-!Datey:~4,2!.!Timey:~0,2!.!Timey:~3,2!.!Timey:~6,2!.!Timey:~9,2!"
set "eval_datetime=!eval_datetime: =0!"
set "eval_result_filename=.\VTDTVS_eval_formula-!eval_datetime!.txt"
REM Evaluate the formula using Python
set "eval_single_number_result="
"!py_exe!" -c "print(str(eval('!eval_formula!'))+'\n')" >"!eval_result_filename!" 2>&1
set /p eval_single_number_result=<"!eval_result_filename!"
set "!eval_variable_name!=!eval_single_number_result!"
set "eval_single_number_result="
DEL /F "!eval_result_filename!" >NUL 2>&1
goto :eof


REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM
:get_date_time_String
REM return a datetime string with spaces replaced by zeroes in format yyyy-mm-dd hh.mm.ss.hh
set "datetimestring_variable_name=%~1"
set "Datey=!DATE: =0!"
set "Timey=!TIME: =0!"
set "eval_datetime=!Datey:~10,4!-!Datey:~7,2!-!Datey:~4,2! !Timey:~0,2!.!Timey:~3,2!.!Timey:~6,2!.!Timey:~9,2!"
set "!datetimestring_variable_name!=!eval_datetime!"
goto :eof


REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM
:get_date_time_String_nospaces
REM return a datetime string with spaces replaced by zeroes and no spaces in format yyyy-mm-dd.hh.mm.ss.hh
set "ns_datetimestring_variable_name=%~1"
set "ns_eval_datetime="
CALL :get_date_time_String "ns_eval_datetime"
set "ns_eval_datetime=!ns_eval_datetime: =.!"
set "!ns_datetimestring_variable_name!=!ns_eval_datetime!"
goto :eof


REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM
:get_header_String
REM Create a Header
set "ghs_header_variable_name=%~1"
CALL :get_date_time_String_nospaces "ghs_date_time_String"
set "!ghs_header_variable_name!=!ghs_date_time_String!-!COMPUTERNAME!"
goto :eof


REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM
:remove_trailing_backslash_into_variable
REM remove trailing backslash from p1 "!source_mp4_Folder!" into p2 "the_folder"
set "rtbiv_path=%~1"
set "rtbiv_variable=%~2"
if /I "!rtbiv_path:~-1!" == "\" (set "rtbiv_path=!rtbiv_path:~,-1!")
if /I "!rtbiv_path:~-1!" == "\" (set "rtbiv_path=!rtbiv_path:~,-1!")
if /I "!rtbiv_path:~-1!" == "\" (set "rtbiv_path=!rtbiv_path:~,-1!")
if /I "!rtbiv_path:~-1!" == "\" (set "rtbiv_path=!rtbiv_path:~,-1!")
if /I "!rtbiv_path:~-1!" == "\" (set "rtbiv_path=!rtbiv_path:~,-1!")
set "!rtbiv_variable!=!rtbiv_path!"
goto :eof


REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM
:make_double_backslashes_into_variable
REM double every backslash in p1 "!source_mp4_Folder!" into p2 "the_folder"
set "rtbiv_path=%~1"
set "rtbiv_variable=%~2"
REM make all double backslashes into single backslashes first; do it multiple times to ensure multiples are caught
set "rtbiv_path=!rtbiv_path:\\=\!"
set "rtbiv_path=!rtbiv_path:\\=\!"
set "rtbiv_path=!rtbiv_path:\\=\!"
set "rtbiv_path=!rtbiv_path:\\=\!"
set "rtbiv_path=!rtbiv_path:\\=\!"
REM now make double backslashes
set "rtbiv_path=!rtbiv_path:\=\\!"
set "!rtbiv_variable!=!rtbiv_path!"
goto :eof





