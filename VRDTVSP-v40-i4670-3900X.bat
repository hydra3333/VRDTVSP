@ECHO ON
@setlocal ENABLEDELAYEDEXPANSION
@setlocal enableextensions

REM --------- set whether pause statements take effect ----------------------------
REM SET xPAUSE=REM
set "xPAUSE=PAUSE"

REM --------- set whether pause statements take effect ----------------------------

REM --------- setup paths and exe filenames ----------------------------

set "root=G:\TEST-vrdtvsp-v40\"
set "vs_root=G:\TEST-vrdtvsp-v40\Vapoursynth-x64\"
set "destination_mp4_Folder=G:\TEST-vrdtvsp-v40\VRDTVSP-Converted\"
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
set "capture_TS_folder=!root!"
set "source_TS_Folder=!capture_TS_folder!000-TO-BE-PROCESSED\"
set "done_TS_Folder=!source_TS_Folder!VRDTVSP-done\"
set "failed_conversion_TS_Folder=!source_TS_Folder!VRDTVSP-Failed-Conversion\"
set "temp_Folder=!scratch_Folder!"

if /I NOT "!destination_mp4_Folder:~-1!" == "\" (set "destination_mp4_Folder=!destination_mp4_Folder!\")
if /I NOT "!capture_TS_folder:~-1!" == "\" (set "capture_TS_folder=!capture_TS_folder!\")
if /I NOT "!source_TS_Folder:~-1!" == "\" (set "source_TS_Folder=!source_TS_Folder!\")
if /I NOT "!done_TS_Folder:~-1!" == "\" (set "done_TS_Folder=!done_TS_Folder!\")
if /I NOT "!failed_conversion_TS_Folder:~-1!" == "\" (set "failed_conversion_TS_Folder=!failed_conversion_TS_Folder!\")
if /I NOT "!scratch_Folder:~-1!" == "\" (set "scratch_Folder=!scratch_Folder!\")
if /I NOT "!temp_Folder:~-1!" == "\" (set "temp_Folder=!temp_Folder!\")

REM the trailing backslash ensures it detects it as a folder
if not exist "!capture_TS_folder!" (mkdir "!capture_TS_folder!")
if not exist "!source_TS_Folder!" (mkdir "!source_TS_Folder!")
if not exist "!done_TS_Folder!" (mkdir "!done_TS_Folder!")
if not exist "!failed_conversion_TS_Folder!" (mkdir "!failed_conversion_TS_Folder!")
if not exist "!scratch_Folder!" (mkdir "!scratch_Folder!")
if not exist "!temp_Folder!" (mkdir "!temp_Folder!")
if not exist "!destination_mp4_Folder!" (mkdir "!destination_mp4_Folder!")

REM --------- resolve any relative paths into absolute paths --------- 
REM --------- ensure no spaces between brackets and first/last parts of the the SET statement inside the DO --------- 
REM --------- this also puts a trailing "\" on the end ---------
REM ECHO !DATE! !TIME! before capture_TS_folder="%capture_TS_folder%" >> "%vrdlog%" 2>&1
FOR /F %%i IN ("!capture_TS_folder!") DO (set "capture_TS_folder=%%~fi")
REM ECHO !DATE! !TIME! after capture_TS_folder="%capture_TS_folder%" >> "%vrdlog%" 2>&1
REM ECHO !DATE! !TIME! before source_TS_Folder="%source_TS_Folder%" >> "%vrdlog%" 2>&1
FOR /F %%i IN ("!source_TS_Folder!") DO (set "source_TS_Folder=%%~fi")
REM ECHO !DATE! !TIME! after source_TS_Folder="%source_TS_Folder%" >> "%vrdlog%" 2>&1
REM ECHO !DATE! !TIME! before done_TS_Folder="%done_TS_Folder%" >> "%vrdlog%" 2>&1
FOR /F %%i IN ("!done_TS_Folder!") DO (set "done_TS_Folder=%%~fi")
REM ECHO !DATE! !TIME! after done_TS_Folder="%done_TS_Folder%" >> "%vrdlog%" 2>&1
REM ECHO !DATE! !TIME! before failed_conversion_TS_Folder="%failed_conversion_TS_Folder%" >> "%vrdlog%" 2>&1
FOR /F %%i IN ("!failed_conversion_TS_Folder!") DO (set "failed_conversion_TS_Folder=%%~fi")
REM ECHO !DATE! !TIME! after failed_conversion_TS_Folder="%failed_conversion_TS_Folder%" >> "%vrdlog%" 2>&1
REM ECHO !DATE! !TIME! before scratch_Folder="%scratch_Folder%" >> "%vrdlog%" 2>&1
FOR /F %%i IN ("!scratch_Folder!") DO (set "scratch_Folder=%%~fi")
REM ECHO !DATE! !TIME! after scratch_Folder="%scratch_Folder%" >> "%vrdlog%" 2>&1
REM ECHO !DATE! !TIME! before temp_Folder="%temp_Folder%" >> "%vrdlog%" 2>&1
FOR /F %%i IN ("!temp_Folder!") DO (set "temp_Folder=%%~fi")
REM ECHO !DATE! !TIME! after temp_Folder="%temp_Folder%" >> "%vrdlog%" 2>&1
REM ECHO !DATE! !TIME! before destination_mp4_Folder="%destination_mp4_Folder%" >> "%vrdlog%" 2>&1
FOR /F %%i IN ("!destination_mp4_Folder!") DO (set "destination_mp4_Folder=%%~fi")
REM ECHO !DATE! !TIME! after destination_mp4_Folder="%destination_mp4_Folder%" >> "%vrdlog%" 2>&1
REM ---------Setup Folders ---------

REM --------- setup LOG file and TEMP filenames ----------------------------
REM base the filenames on the running script filename using %~n0
set PSlog=!source_TS_Folder!%~n0-!header!-PSlog.log
ECHO !DATE! !TIME! DEL /F "!PSlog!" >> "%vrdlog%" 2>&1
DEL /F "!PSlog!" >> "%vrdlog%" 2>&1

SET tempfile=!scratch_Folder!%~n0-!header!-temp.txt
ECHO !DATE! !TIME! DEL /F "!tempfile!" >> "%vrdlog%" 2>&1
DEL /F "!tempfile!" >> "%vrdlog%" 2>&1

SET tempfile_stderr=!scratch_Folder!%~n0-!header!-temp_stderr.txt
ECHO !DATE! !TIME! DEL /F "!tempfile!" >> "%vrdlog%" 2>&1
DEL /F "!tempfile!" >> "%vrdlog%" 2>&1

set "temp_cmd_file=!temp_Folder!temp_cmd_file.bat"
ECHO !DATE! !TIME! DEL /F "!temp_cmd_file!" >> "%vrdlog%" 2>&1
DEL /F "!temp_cmd_file!" >> "%vrdlog%" 2>&1

set "vrd5_logfiles=G:\HDTV\VideoReDo-5_*.Log"
ECHO DEL /F "!vrd5_logfiles!" >> "%vrdlog%" 2>&1
DEL /F "!vrd5_logfiles!" >> "%vrdlog%" 2>&1

set "vrd6_logfiles=G:\HDTV\VideoReDo6_*.Log"
ECHO DEL /F "!vrd6_logfiles!" >> "%vrdlog%" 2>&1
DEL /F "!vrd6_logfiles!" >> "%vrdlog%" 2>&1
REM --------- setup LOG file and TEMP filenames ----------------------------

REM --------- setup vrd paths filenames etc ----------------------------
REM set the primary and fallback version of VRD to use for QSF
REM The QSF fallback process uses these next 2 variables to set/reset which version use when, via "CALL :set_vrd_qsf_paths NUMBER"
set "DEFAULT_vrd_version_primary=5"
set "DEFAULT_vrd_version_fallback=6"
set "extension_mpeg2=mpg"
set "extension_h264=mp4"
set "extension_h265=mp4"
set "VRDTVSP_QSF_VBS_SCRIPT=!root!VRDTVSP_qsf_script.vbs"
set "profile_name_for_qsf_mpeg2_vrd6=VRDTVS-for-QSF-MPEG2_VRD6"
set "profile_name_for_qsf_mpeg2_vrd5=VRDTVS-for-QSF-MPEG2_VRD5"
set "profile_name_for_qsf_h264_vrd6=VRDTVS-for-QSF-H264_VRD6"
set "profile_name_for_qsf_h264_vrd5=VRDTVS-for-QSF-H264_VRD5"
set "profile_name_for_qsf_h265_vrd6=VRDTVS-for-QSF-H265_VRD6"
set "profile_name_for_qsf_h265_vrd5=VRDTVS-for-QSF-H265_VRD5"
REM qsf timeout in minutes  (VRD v6 takes 4 hours for a large 10Gb footy file); allow extra 10 secs for cscript timeout for vrd to finish
set "default_qsf_timeout_minutes_VRD6=240"
set /a default_qsf_timeout_seconds_VRD6=(!default_qsf_timeout_minutes_VRD6! * 60) + 10
set "default_qsf_timeout_minutes_VRD5=15"
set /a default_qsf_timeout_seconds_VRD5=(!default_qsf_timeout_minutes_VRD5! * 60) + 10
REM --------- ensure "\" at end of VRD paths
set "Path_to_vrd6=C:\Program Files (x86)\VideoReDoTVSuite6"
if /I NOT "!Path_to_vrd6:~-1!" == "\" (set "Path_to_vrd6=!Path_to_vrd6!\")
FOR /F "delims=" %%i IN ("%Path_to_vrd6%") DO (set "Path_to_vrd6=%%~fi")
FOR /F "delims=" %%i IN ("%Path_to_vrd6%vp.vbs") DO (set "Path_to_vp_vbs_vrd6=%%~fi")
REM --------- ensure "\" at end of VRD paths
set "Path_to_vrd5=C:\Program Files (x86)\VideoReDoTVSuite5"
if /I NOT "!Path_to_vrd5:~-1!" == "\" (set "Path_to_vrd5=!Path_to_vrd5!")
FOR /F "delims=" %%i IN ("%Path_to_vrd5%") DO (SET Path_to_vrd5=%%~fi)
FOR /F "delims=" %%i IN ("%Path_to_vrd5%vp.vbs") DO (set "Path_to_vp_vbs_vrd5=%%~fi")
REM
CALL :set_vrd_qsf_paths "!DEFAULT_vrd_version_primary!"
REM
echo set DEFAULT_vrd_ >> "%vrdlog%" 2>&1
set DEFAULT_vrd_ >> "%vrdlog%" 2>&1
echo set _vrd_ >> "%vrdlog%" 2>&1
set _vrd_ >> "%vrdlog%" 2>&1
REM --------- setup vrd paths filenames etc ----------------------------

REM --------- setup .PY fully qualified filenames to pre-created files which rename and re-timestamp filenames etc ---------
set "Path_to_py_VRDTVSP_Calculate_Duration=!root!VRDTVSP_Calculate_Duration.py"
set "Path_to_py_VRDTVSP_Rename_Fix_Filenames_Move_Date_Adjust_Titles=!root!VRDTVSP_Rename_Fix_Filenames_Move_Date_Adjust_Titles.py"
set "Path_to_py_VRDTVSP_Modify_File_Date_Timestamps=!root!VRDTVSP_Modify_File_Date_Timestamps.py"
set "Path_to_py_VRDTVSP_Set_Mediainfo_Variables_for_first_stream_in_section=!root!VRDTVSP_Set_Mediainfo_Variables_for_first_stream_in_section.py"
set "Path_to_py_VRDTVSP_Set_ffprobe_Variables_for_first_stream_in_section=!root!VRDTVSP_Set_ffprobe_Variables_for_first_stream_in_section.py"
set "Path_to_vbs_VRDTVSP_Run_QSF_with_v5_or_v6=!root!VRDTVSP_Run_QSF_with_v5_or_v6.vbs"
REM --------- setup .VBS and .PS1 and .PY fully qualified filenames to pre-created files which rename and re-timestamp filenames etc ---------

CALL :get_date_time_String "TOTAL_start_date_time"

REM --------- Start Initial Summarize ---------
ECHO !DATE! !TIME! ----------------------------------------------------------------------------------------------------------------------- >> "%vrdlog%" 2>&1
ECHO !DATE! !TIME! Start summary of Initialised paths etc ... >> "%vrdlog%" 2>&1
ECHO !DATE! !TIME! COMPUTERNAME="!COMPUTERNAME!"  header="!header!" >> "%vrdlog%" 2>&1
ECHO !DATE! !TIME! root="!root!" >> "%vrdlog%" 2>&1
ECHO !DATE! !TIME! root_nobackslash="!root_nobackslash!" >> "%vrdlog%" 2>&1
ECHO !DATE! !TIME! vs_root="!vs_root!" >> "%vrdlog%" 2>&1
ECHO !DATE! !TIME! vs_root_nobackslash="!vs_root_nobackslash!" >> "%vrdlog%" 2>&1
ECHO !DATE! !TIME! vs_path_drive="!vs_path_drive!" >> "%vrdlog%" 2>&1
ECHO !DATE! !TIME! vs_scripts_path="!vs_scripts_path!" >> "%vrdlog%" 2>&1
ECHO !DATE! !TIME! vs_plugins_path="!vs_plugins_path!" >> "%vrdlog%" 2>&1
ECHO !DATE! !TIME! vs_coreplugins_path="!vs_coreplugins_path!" >> "%vrdlog%" 2>&1

ECHO !DATE! !TIME! ffmpegexe64="!ffmpegexe64!" >> "%vrdlog%" 2>&1
ECHO !DATE! !TIME! ffmpegexe64_OpenCL="!ffmpegexe64_OpenCL!" >> "%vrdlog%" 2>&1
ECHO !DATE! !TIME! ffprobeexe64="!ffprobeexe64!" >> "%vrdlog%" 2>&1
ECHO !DATE! !TIME! mediainfoexe64="!mediainfoexe64!" >> "%vrdlog%" 2>&1
ECHO !DATE! !TIME! dgindexNVexe64="!dgindexNVexe64!" >> "%vrdlog%" 2>&1
ECHO !DATE! !TIME! vspipeexe64="!vspipeexe64!" >> "%vrdlog%" 2>&1
ECHO !DATE! !TIME! py_exe="!py_exe!" >> "%vrdlog%" 2>&1
ECHO !DATE! !TIME! Insomniaexe64="!Insomniaexe64!" >> "%vrdlog%" 2>&1

ECHO !DATE! !TIME! vrdlog="!vrdlog!" >> "%vrdlog%" 2>&1
ECHO !DATE! !TIME! capture_TS_folder="!capture_TS_folder!" >> "%vrdlog%" 2>&1
ECHO !DATE! !TIME! source_TS_Folder="!source_TS_Folder!" >> "%vrdlog%" 2>&1
ECHO !DATE! !TIME! done_TS_Folder="!done_TS_Folder!" >> "%vrdlog%" 2>&1
ECHO !DATE! !TIME! failed_conversion_TS_Folder="!failed_conversion_TS_Folder!" >> "%vrdlog%" 2>&1
ECHO !DATE! !TIME! scratch_Folder="!scratch_Folder!" >> "%vrdlog%" 2>&1
ECHO !DATE! !TIME! destination_mp4_Folder="!destination_mp4_Folder!" >> "%vrdlog%" 2>&1
ECHO !DATE! !TIME! PSlog="!PSlog!" >> "%vrdlog%" 2>&1
ECHO !DATE! !TIME! tempfile="!tempfile!" >> "%vrdlog%" 2>&1

ECHO !DATE! !TIME! extension_mpeg2="!extension_mpeg2!" >> "%vrdlog%" 2>&1
ECHO !DATE! !TIME! extension_h264="!extension_h264!" >> "%vrdlog%" 2>&1
ECHO !DATE! !TIME! extension_h265="!extension_h265!" >> "%vrdlog%" 2>&1
ECHO !DATE! !TIME! VRDTVSP_QSF_VBS_SCRIPT="!VRDTVSP_QSF_VBS_SCRIPT!" >> "%vrdlog%" 2>&1
ECHO !DATE! !TIME! Path_to_vrd6="!Path_to_vrd6!" >> "%vrdlog%" 2>&1
ECHO !DATE! !TIME! Path_to_vp_vbs_vrd6="!Path_to_vp_vbs_vrd6!" >> "%vrdlog%" 2>&1
ECHO !DATE! !TIME! Path_to_vrd5="!Path_to_vrd5!" >> "%vrdlog%" 2>&1
ECHO !DATE! !TIME! Path_to_vp_vbs_vrd5="!Path_to_vp_vbs_vrd5!" >> "%vrdlog%" 2>&1
ECHO !DATE! !TIME! SET VRD paths for version "!_vrd_version_primary!" >> "%vrdlog%" 2>&1
ECHO !DATE! !TIME! Path_to_vrd="!Path_to_vrd!" >> "%vrdlog%" 2>&1
ECHO !DATE! !TIME! Path_to_vrd_vp_vbs="!Path_to_vrd_vp_vbs!" >> "%vrdlog%" 2>&1
ECHO !DATE! !TIME! profile_name_for_qsf_mpeg2="!profile_name_for_qsf_mpeg2!" >> "%vrdlog%" 2>&1
ECHO !DATE! !TIME! profile_name_for_qsf_h264="!profile_name_for_qsf_h264!" >> "%vrdlog%" 2>&1
ECHO !DATE! !TIME! profile_name_for_qsf_h265="!profile_name_for_qsf_h265!" >> "%vrdlog%" 2>&1

ECHO !DATE! !TIME! Path_to_py_VRDTVSP_Calculate_Duration="!Path_to_py_VRDTVSP_Calculate_Duration!" >> "%vrdlog%" 2>&1
ECHO !DATE! !TIME! Path_to_py_VRDTVSP_Rename_Fix_Filenames_Move_Date_Adjust_Titles="!Path_to_py_VRDTVSP_Rename_Fix_Filenames_Move_Date_Adjust_Titles!" >> "%vrdlog%" 2>&1
ECHO !DATE! !TIME! Path_to_py_VRDTVSP_Modify_File_Date_Timestamps="!Path_to_py_VRDTVSP_Modify_File_Date_Timestamps!" >> "%vrdlog%" 2>&1
ECHO !DATE! !TIME! Path_to_py_VRDTVSP_Set_Mediainfo_Variables_for_first_stream_in_section="!Path_to_py_VRDTVSP_Set_Mediainfo_Variables_for_first_stream_in_section!" >> "%vrdlog%" 2>&1
ECHO !DATE! !TIME! Path_to_py_VRDTVSP_Set_ffprobe_Variables_for_first_stream_in_section="!Path_to_py_VRDTVSP_Set_ffprobe_Variables_for_first_stream_in_section!" >> "%vrdlog%" 2>&1

ECHO !DATE! !TIME! End summary of Initialised paths etc ... >> "%vrdlog%" 2>&1
ECHO !DATE! !TIME! ----------------------------------------------------------------------------------------------------------------------- >> "%vrdlog%" 2>&1
REM --------- End Initial Summarize ---------

REM --------- SETUP FFMPEG DEVICE and OpenCL stuff and show helps ---------
ECHO !DATE! !TIME! ----------------------------------------------------------------------------------------------------------------------- >> "%vrdlog%" 2>&1
REM setup the OpenCL device strings 
set ff_ffmpeg_device=0.0
SET ff_OpenCL_device_init=-init_hw_device opencl=ocl:!ff_ffmpeg_device! -filter_hw_device ocl
REM ECHO !DATE! !TIME! ff_ffmpeg_device="!ff_ffmpeg_device!" >> "%vrdlog%" 2>&1
REM ECHO !DATE! !TIME! ff_OpenCL_device_init="!ff_OpenCL_device_init!" >> "%vrdlog%" 2>&1
REM Display ffmpeg features for the current ffmpeg.exe
REM ECHO !DATE! !TIME! 1. "!ffmpegexe64_OpenCL!" -hide_banner -v debug -init_hw_device list >> "%vrdlog%" 2>&1
REM "!ffmpegexe64_OpenCL!" -hide_banner -v debug -init_hw_device list >> "%vrdlog%" 2>&1
REM ECHO !DATE! !TIME! 2. "!ffmpegexe64_OpenCL!" -hide_banner -v debug -init_hw_device opencl >> "%vrdlog%" 2>&1
REM "!ffmpegexe64_OpenCL!" -hide_banner -v debug -init_hw_device opencl >> "%vrdlog%" 2>&1
REM ECHO !DATE! !TIME! 3. "!ffmpegexe64_OpenCL!" -hide_banner -v debug -init_hw_device opencl:!ff_ffmpeg_device!  >> "%vrdlog%" 2>&1
REM "!ffmpegexe64_OpenCL!" -hide_banner -v debug -init_hw_device opencl:!ff_ffmpeg_device!  >> "%vrdlog%" 2>&1
REM ECHO !DATE! !TIME! 4 "!ffmpegexe64!" -hide_banner -h encoder=h264_nvenc  >> "%vrdlog%" 2>&1
REM "!ffmpegexe64!" -hide_banner -h encoder=h264_nvenc  >> "%vrdlog%" 2>&1
REM ECHO !DATE! !TIME! 5 "!ffmpegexe64!" -hide_banner -h encoder=hevc_nvenc >> "!vrdlog!" 2>&1
REM "!ffmpegexe64!" -hide_banner -h encoder=hevc_nvenc >> "!vrdlog!" 2>&1
REM ECHO !DATE! !TIME! 6 "!ffmpegexe64!" -hide_banner -h filter=yadif  >> "%vrdlog%" 2>&1
REM "!ffmpegexe64!" -hide_banner -h filter=yadif  >> "%vrdlog%" 2>&1
REM ECHO !DATE! !TIME! 7 "!ffmpegexe64_OpenCL!" -hide_banner -h filter=unsharp_opencl  >> "%vrdlog%" 2>&1
REM "!ffmpegexe64_OpenCL!" -hide_banner -h filter=unsharp_opencl  >> "%vrdlog%" 2>&1
REM ECHO !DATE! !TIME! -------------------------------------- >> "%vrdlog%" 2>&1
REM ECHO !DATE! !TIME! 8 "!mediainfoexe64!" --help  >> "%vrdlog%" 2>&1
REM "!mediainfoexe64!" --help  >> "%vrdlog%" 2>&1
REM ECHO !DATE! !TIME! ---------------------------------------------------------------------------- >> "%vrdlog%" 2>&1
REM ECHO !DATE! !TIME! "!mediainfoexe64!" --Info-Parameters  >> "%vrdlog%" 2>&1
REM ECHO "!mediainfoexe64!" --Info-Parameters  >> "%vrdlog%" 2>&1
REM "!mediainfoexe64!" --Info-Parameters  >> "%vrdlog%" 2>&1
REM ECHO !DATE! !TIME! ---------------------------------------------------------------------------- >> "%vrdlog%" 2>&1
REM ECHO !DATE! !TIME! ---------------------------------------------------------------------------- >> "%vrdlog%" 2>&1
REM ECHO !DATE! !TIME! "!mediainfoexe64!"  --Legacy --Info-Parameters  >> "%vrdlog%" 2>&1
REM ECHO "!mediainfoexe64!"  --Legacy --Info-Parameters  >> "%vrdlog%" 2>&1
REM "!mediainfoexe64!"  --Legacy --Info-Parameters  >> "%vrdlog%" 2>&1
REM ECHO !DATE! !TIME! ---------------------------------------------------------------------------- >> "%vrdlog%" 2>&1
REM ECHO !DATE! !TIME! ----------------------------------------------------------------------------------------------------------------------- >> "%vrdlog%" 2>&1

REM ***** PREVENT PC FROM GOING TO SLEEP *****
ECHO !DATE! !TIME! ----------------------------------------------------------------------------------------------------------------------- >> "%vrdlog%" 2>&1
set iFile=Insomnia-!header!.exe
ECHO copy "C:\SOFTWARE\Insomnia\32-bit\Insomnia.exe" "!source_TS_Folder!!iFile!" >> "!vrdlog!" 2>&1
copy "C:\SOFTWARE\Insomnia\32-bit\Insomnia.exe" "!source_TS_Folder!!iFile!" >> "!vrdlog!" 2>&1
start /min "!iFile!" "!source_TS_Folder!!iFile!"
ECHO !DATE! !TIME! ----------------------------------------------------------------------------------------------------------------------- >> "%vrdlog%" 2>&1
REM ***** PREVENT PC FROM GOING TO SLEEP *****

REM --------- Swap to source folder and save old folder using PUSHD ---------
ECHO !DATE! !TIME! ----------------------------------------------------------------------------------------------------------------------- >> "%vrdlog%" 2>&1
CD >> "!vrdlog!" 2>&1
echo PUSHD "!source_TS_Folder!" >> "!vrdlog!" 2>&1
PUSHD "!source_TS_Folder!" >> "!vrdlog!" 2>&1
CD >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! ----------------------------------------------------------------------------------------------------------------------- >> "%vrdlog%" 2>&1
REM --------- Swap to source folder and save old folder using PUSHD ---------

REM --------- Start move .TS .MP4 .MPG .VOB files from capture folder to source folder
ECHO !DATE! !TIME! ----------------------------------------------------------------------------------------------------------------------- >> "%vrdlog%" 2>&1
ECHO !DATE! !TIME! ***** >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! ***** >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! ***** >> "!vrdlog!" 2>&1
ECHO --------- Start move .TS .MP4 .MPG .VOB files from capture folder "!capture_TS_folder!" to "!source_TS_Folder!" --------- >> "!vrdlog!" 2>&1
CALL :get_date_time_String "start_date_time"
ECHO MOVE /Y "!capture_TS_folder!*.TS" "!source_TS_Folder!" >> "!vrdlog!" 2>&1
MOVE /Y "!capture_TS_folder!*.TS" "!source_TS_Folder!" >> "!vrdlog!" 2>&1
ECHO MOVE /Y "!capture_TS_folder!*.MP4" "!source_TS_Folder!" >> "!vrdlog!" 2>&1
MOVE /Y "!capture_TS_folder!*.MP4" "!source_TS_Folder!" >> "!vrdlog!" 2>&1
ECHO MOVE /Y "!capture_TS_folder!*.MPG" "!source_TS_Folder!" >> "!vrdlog!" 2>&1
MOVE /Y "!capture_TS_folder!*.MPG" "!source_TS_Folder!" >> "!vrdlog!" 2>&1
ECHO MOVE /Y "!capture_TS_folder!*.VOB" "!source_TS_Folder!" >> "!vrdlog!" 2>&1
MOVE /Y "!capture_TS_folder!*.VOB" "!source_TS_Folder!" >> "!vrdlog!" 2>&1
CALL :get_date_time_String "end_date_time"
REM echo "!py_exe!" "!Path_to_py_VRDTVSP_Calculate_Duration!" --start_datetime "!start_date_time!" --end_datetime "!end_date_time!" --prefix_id "MoveFiles" >> "!vrdlog!" 2>&1
"!py_exe!" "!Path_to_py_VRDTVSP_Calculate_Duration!" --start_datetime "!start_date_time!" --end_datetime "!end_date_time!" --prefix_id "MoveFiles" >> "!vrdlog!" 2>&1
ECHO --------- End   move .TS .MP4 .MPG .VOB files from capture folder "!capture_TS_folder!" to "!source_TS_Folder!" --------- >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! ***** >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! ***** >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! ***** >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! ----------------------------------------------------------------------------------------------------------------------- >> "%vrdlog%" 2>&1
REM --------- End move .TS .MP4 .MPG .VOB files from capture folder to source folder

REM --------- Start Run the py to modify the filenames to enforce validity  i.e. no special characters ---------
ECHO !DATE! !TIME! ----------------------------------------------------------------------------------------------------------------------- >> "%vrdlog%" 2>&1
ECHO !DATE! !TIME! ***** >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! ***** >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! ***** >> "!vrdlog!" 2>&1
REM GRRR - sometimes left and right parentheses etc are seem in filenames of the media files ... 
REM Check if filenames are a "safe string" without special characters like !~`!@#$%^&*()+=[]{}\|:;'"<>,?/
REM If a filename isn't "safe" then rename it so it really is safe
REM Allowed only characters a-z,A-Z,0-9,-,_,.,space
REM
REM ENFORCE VALID FILENAMES on the source_TS_Folder
CALL :get_date_time_String "start_date_time"
set "the_folder=!source_TS_Folder!" 
CALL :make_double_backslashes_into_variable "!source_TS_Folder!" "the_folder"
REM CALL :remove_trailing_backslash_into_variable "!the_folder!" "the_folder"
echo "!py_exe!" "!Path_to_py_VRDTVSP_Rename_Fix_Filenames_Move_Date_Adjust_Titles!" --folder "!the_folder!" --recurse >> "!vrdlog!" 2>&1
"!py_exe!" "!Path_to_py_VRDTVSP_Rename_Fix_Filenames_Move_Date_Adjust_Titles!" --folder "!the_folder!" --recurse >> "!vrdlog!" 2>&1
CALL :get_date_time_String "end_date_time"
echo "!py_exe!" "!Path_to_py_VRDTVSP_Calculate_Duration!" --start_datetime "!start_date_time!" --end_datetime "!end_date_time!" --prefix_id "VRDTVSP_Rename_Fix_Filenames_Move_Date_Adjust_Titles !the_folder!" >> "!vrdlog!" 2>&1
"!py_exe!" "!Path_to_py_VRDTVSP_Calculate_Duration!" --start_datetime "!start_date_time!" --end_datetime "!end_date_time!" --prefix_id "VRDTVSP_Rename_Fix_Filenames_Move_Date_Adjust_Titles !the_folder!" >> "!vrdlog!" 2>&1
REM
CALL :get_date_time_String "loop_start_date_time"
ECHO !DATE! !TIME! ***** >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! ***** >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! ***** >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! ----------------------------------------------------------------------------------------------------------------------- >> "%vrdlog%" 2>&1
REM --------- End Run the py to modify the filenames to enforce validity  i.e. no special characters ---------

:before_main_loop
REM --------- Start Loop through the SOURCE files ---------
ECHO !DATE! !TIME! ***** >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! ***** >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! ***** >> "!vrdlog!" 2>&1
CALL :get_date_time_String "loop_start_date_time"
for %%f in ("!source_TS_Folder!*.TS", "!source_TS_Folder!*.MPG", "!source_TS_Folder!*.MP4", "!source_TS_Folder!*.VOB") do (
	CALL :get_date_time_String "iloop_start_date_time"
	ECHO !DATE! !TIME! START ------------------ %%f >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! Input file : "%%~f" >> "!vrdlog!" 2>&1
	CALL :QSFandCONVERT "%%f"
	REM no - MOVE "%%f" "!done_TS_Folder!" - INSTEAD do the RENAME/MOVE as a part of the CALL above, depending on whether it's been propcessed correctly
	ECHO !DATE! !TIME! END ------------------ %%f >> "!vrdlog!" 2>&1
	CALL :get_date_time_String "iloop_end_date_time"
	echo "!py_exe!" "!Path_to_py_VRDTVSP_Calculate_Duration!" --start_datetime "!iloop_start_date_time!" --end_datetime "!iloop_end_date_time!" --prefix_id ":::::::::: iloop %%f " >> "!vrdlog!" 2>&1
	"!py_exe!" "!Path_to_py_VRDTVSP_Calculate_Duration!" --start_datetime "!iloop_start_date_time!" --end_datetime "!iloop_end_date_time!" --prefix_id ":::::::::: iloop %%f " >> "!vrdlog!" 2>&1
)
CALL :get_date_time_String "loop_end_date_time"
echo "!py_exe!" "!Path_to_py_VRDTVSP_Calculate_Duration!" --start_datetime "!loop_start_date_time!" --end_datetime "!loop_end_date_time!" --prefix_id "Loop_Processing_Files" >> "!vrdlog!" 2>&1
"!py_exe!" "!Path_to_py_VRDTVSP_Calculate_Duration!" --start_datetime "!loop_start_date_time!" --end_datetime "!loop_end_date_time!" --prefix_id "Loop_Processing_Files" >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! ***** >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! ***** >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! ***** >> "!vrdlog!" 2>&1
REM --------- End Loop through the SOURCE files ---------
:after_main_loop

REM --------- Start Run the py to modify the filenames to enforce validity  i.e. no special characters ---------
ECHO !DATE! !TIME! ----------------------------------------------------------------------------------------------------------------------- >> "%vrdlog%" 2>&1
ECHO !DATE! !TIME! ***** >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! ***** >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! ***** >> "!vrdlog!" 2>&1
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
echo "!py_exe!" "!Path_to_py_VRDTVSP_Rename_Fix_Filenames_Move_Date_Adjust_Titles!" --folder "!the_folder!" --recurse >> "!vrdlog!" 2>&1
"!py_exe!" "!Path_to_py_VRDTVSP_Rename_Fix_Filenames_Move_Date_Adjust_Titles!" --folder "!the_folder!" --recurse >> "!vrdlog!" 2>&1
CALL :get_date_time_String "end_date_time"
echo "!py_exe!" "!Path_to_py_VRDTVSP_Calculate_Duration!" --start_datetime "!start_date_time!" --end_datetime "!end_date_time!" --prefix_id "VRDTVSP_Rename_Fix_Filenames_Move_Date_Adjust_Titles !the_folder!" >> "!vrdlog!" 2>&1
"!py_exe!" "!Path_to_py_VRDTVSP_Calculate_Duration!" --start_datetime "!start_date_time!" --end_datetime "!end_date_time!" --prefix_id "VRDTVSP_Rename_Fix_Filenames_Move_Date_Adjust_Titles !the_folder!" >> "!vrdlog!" 2>&1
REM
CALL :get_date_time_String "loop_start_date_time"
ECHO !DATE! !TIME! ***** >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! ***** >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! ***** >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! ----------------------------------------------------------------------------------------------------------------------- >> "%vrdlog%" 2>&1
REM --------- End Run the py to modify the filenames to enforce validity  i.e. no special characters ---------


REM --------- Start Run the py to modify the filename timestamps filenames based on the date in the filename eg 2020-06-03 ---------
ECHO !DATE! !TIME! ----------------------------------------------------------------------------------------------------------------------- >> "%vrdlog%" 2>&1
ECHO !DATE! !TIME! ***** >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! ***** >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! ***** >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! ***** >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! --- START Modify DateCreated and DateModified Timestamps on "!destination_mp4_Folder!" >> "!vrdlog!" 2>&1

echo DEBUG: BEFORE:  >> "!vrdlog!" 2>&1
echo dir "!destination_mp4_Folder!" >> "!vrdlog!" 2>&1
dir "!destination_mp4_Folder!" >> "!vrdlog!" 2>&1

CALL :get_date_time_String "start_date_time"
set "the_folder=!destination_mp4_Folder!" 
CALL :make_double_backslashes_into_variable "!destination_mp4_Folder!" "the_folder"
REM CALL :remove_trailing_backslash_into_variable "!the_folder!" "the_folder"
echo "!py_exe!" "!Path_to_py_VRDTVSP_Modify_File_Date_Timestamps!" --folder "!the_folder!" --recurse >> "!vrdlog!" 2>&1
"!py_exe!" "!Path_to_py_VRDTVSP_Modify_File_Date_Timestamps!" --folder "!the_folder!" --recurse >> "!vrdlog!" 2>&1

echo DEBUG: AFTER: >> "!vrdlog!" 2>&1
echo dir "!destination_mp4_Folder!" >> "!vrdlog!" 2>&1
dir "!destination_mp4_Folder!" >> "!vrdlog!" 2>&1

CALL :get_date_time_String "end_date_time"
REM echo "!py_exe!" "!Path_to_py_VRDTVSP_Calculate_Duration!" --start_datetime "!start_date_time!" --end_datetime "!end_date_time!" --prefix_id "ReTimestamp" >> "!vrdlog!" 2>&1
"!py_exe!" "!Path_to_py_VRDTVSP_Calculate_Duration!" --start_datetime "!start_date_time!" --end_datetime "!end_date_time!" --prefix_id "ReTimestamp" >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! --- END Modify DateCreated and DateModified Timestamps on "!destination_mp4_Folder!" >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! ***** >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! ***** >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! ***** >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! ----------------------------------------------------------------------------------------------------------------------- >> "%vrdlog%" 2>&1
REM --------- End Run the py to modify the filename timestamps filenames based on the date in the filename eg 2020-06-03 ---------

REM ***** ALLOW PC TO GO TO SLEEP AGAIN *****
ECHO !DATE! !TIME! ----------------------------------------------------------------------------------------------------------------------- >> "%vrdlog%" 2>&1
REM "C:\000-PStools\pskill.exe" -t -nobanner "%iFile%" >> "!vrdlog!" 2>&1
echo taskkill /t /f /im "%iFile%" >> "!vrdlog!" 2>&1
taskkill /t /f /im "%iFile%" >> "!vrdlog!" 2>&1
DEL /F "!source_TS_Folder!!iFile!" >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! ----------------------------------------------------------------------------------------------------------------------- >> "%vrdlog%" 2>&1
REM ***** ALLOW PC TO GO TO SLEEP AGAIN *****

REM --------- Swap back to original folder ---------
ECHO !DATE! !TIME! ----------------------------------------------------------------------------------------------------------------------- >> "%vrdlog%" 2>&1
CD >> "!vrdlog!" 2>&1
echo POPD >> "!vrdlog!" 2>&1
POPD >> "!vrdlog!" 2>&1
CD >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! ----------------------------------------------------------------------------------------------------------------------- >> "%vrdlog%" 2>&1
REM --------- Swap back to original folder ---------


CALL :get_date_time_String "TOTAL_end_date_time"
echo "!py_exe!" "!Path_to_py_VRDTVSP_Calculate_Duration!" --start_datetime "!TOTAL_start_date_time!" --end_datetime "!TOTAL_end_date_time!" --prefix_id "TOTAL" >> "!vrdlog!" 2>&1
"!py_exe!" "!Path_to_py_VRDTVSP_Calculate_Duration!" --start_datetime "!TOTAL_start_date_time!" --end_datetime "!TOTAL_end_date_time!" --prefix_id "TOTAL" >> "!vrdlog!" 2>&1

!xPAUSE!
exit

REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM
:QSFandCONVERT
@setlocal ENABLEDELAYEDEXPANSION
@setlocal enableextensions
REM parameter 1 = input filename (.TS file)
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

CALL :get_date_time_String "start_date_time_QSF"

set "file_name_part=%~n1"

REM dispose of a LOT of variables, some of whih are large
CALL :clear_variables

REM :gather_variables_from_media_file P2 =	the global prefix to use for this gather, one of "SRC_", "QSF_" "TARGET_"
CALL :gather_variables_from_media_file "%~f1" "SRC_" 

REM "SRC_calc_Video_Encoding=AVC"
REM "SRC_calc_Video_Encoding=MPEG2"
REM 
REM "SRC_calc_Video_Interlacement=PROGRESSIVE"
REM "SRC_calc_Video_Interlacement=INTERLACED"
REM 
REM "SRC_calc_Video_FieldFirst=TFF"
REM "SRC_calc_Video_FieldFirst=BFF"
REM 
REM "_vrd_version_primary=5"
REM "_vrd_version_fallback=6"
REM 
REM "extension_mpeg2=mpg"
REM "extension_h264=mp4"
REM "extension_h265=mp4"
REM 
REM Providing subroutine :set_vrd_qsf_paths has been called, then these have been preset:
REM    profile_name_for_qsf_mpeg2
REM    profile_name_for_qsf_h264
REM    profile_name_for_qsf_h265
REM    extension_mpeg2=mpg
REM    extension_h264=mp4
REM    extension_h265=mp4
REM 
IF /I "!SRC_calc_Video_Interlacement!" == "PROGRESSIVE" (
	echo !DATE! !TIME! >> "!vrdlog!" 2>&1
) ELSE IF /I "!SRC_calc_Video_Interlacement!" == "INTERLACED" (
	echo !DATE! !TIME! >> "!vrdlog!" 2>&1
) ELSE (
	echo !DATE! !TIME! ERROR: mediainfo/ffmpeg data !SRC_calc_Video_Interlacement! yields neither PROGRESSIVE nor INTERLACED for "%~f1" >> "!vrdlog!" 2>&1
	echo !DATE! !TIME! Hard Aborting ... >> "!vrdlog!" 2>&1
	!xPAUSE!
	EXIT
)
REM
IF /I "!SRC_calc_Video_FieldFirst!" == "TFF" (
	echo !DATE! !TIME! >> "!vrdlog!" 2>&1
) ELSE IF /I "!SRC_calc_Video_FieldFirst!" == "BFF" (
	echo !DATE! !TIME! >> "!vrdlog!" 2>&1
) ELSE (
	echo !DATE! !TIME! ERROR: mediainfo/ffmpeg processing !SRC_calc_Video_FieldFirst! yields neither 'TFF' nor 'BFF' field-first ,default='TFF', for "%~f1" >> "!vrdlog!" 2>&1
	echo !DATE! !TIME! Hard Aborting ... >> "!vrdlog!" 2>&1
	!xPAUSE!
	EXIT
)

REM =======================================================================================================================================================================================
IF /I "!SRC_calc_Video_Encoding!" == "AVC" (
	set "qsf_extension=!extension_h264!"
) ELSE IF /I "!SRC_calc_Video_Encoding!" == "MPEG2" (
	set "qsf_extension=!extension_mpeg2!"
) ELSE (
	set "check_QSF_failed********* ERROR: mediainfo format !SRC_calc_Video_Encoding! neither 'AVC' nor 'MPEG2' for !source_filename!"
	echo !DATE! !TIME! !check_QSF_failed! >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! *********  Declaring as FAILED: "%~f1" >> "%vrdlog%" 2>&1
	ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
	exit 1
)
set "qsf_xml_prefix=QSFinfo_"
set "QSF_File=!scratch_Folder!%~n1.qsf.!qsf_extension!"
REM Input Parameters to :run_cscript_qsf_with_timeout
REM 	1	VideoReDo version number to use
REM		2 	fully qualified filename of the SRC input (usually a .TS file)
REM 	3	fully qualified filename of name of QSF file to create
REM		4	qsf prefix for variables output from the VideoReDo QSF 
REM RETURN Parameters 
REM		QSF_ parameters from  :gather_variables_from_media_file
REM		!check_QSF_failed! is non-blank if we abort
REM Expected preset variables
REM		SRC_ variables
REM		calculated variables SRC_calc_
REM 	Fudged "!SRC_MI_V_BitRate!"
REM 	temp_cmd_file
set "check_QSF_failed="
echo CALL :run_cscript_qsf_with_timeout "!DEFAULT_vrd_version_primary!" "%~f1" "!QSF_File!" "!qsf_xml_prefix!" >> "%vrdlog%" 2>&1
CALL :run_cscript_qsf_with_timeout "!DEFAULT_vrd_version_primary!" "%~f1" "!QSF_File!" "!qsf_xml_prefix!"
IF /I NOT "!check_QSF_failed!" == "" (
	REM It failed, try doing the fallback QSF
	set "check_QSF_failed="
	echo call run_cscript_qsf_with_timeout "!DEFAULT_vrd_version_fallback!" "%~f1" "!QSF_File!" "!qsf_xml_prefix!" >> "%vrdlog%" 2>&1
	CALL :run_cscript_qsf_with_timeout "!DEFAULT_vrd_version_fallback!" "%~f1" "!QSF_File!" "!qsf_xml_prefix!"
	IF /I NOT "!check_QSF_failed!" == "" (
		ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
		ECHO !DATE! !TIME! *********  Declaring FAILED:  "%~f1" >> "%vrdlog%" 2>&1
		ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
		CALL :declare_FAILED "%~f1"
		CALL :get_date_time_String "end_date_time_QSF"
		REM echo "!py_exe!" "!Path_to_py_VRDTVSP_Calculate_Duration!" --start_datetime "!start_date_time_QSF!" --end_datetime "!end_date_time_QSF!" --prefix_id "QSF itself" >> "!vrdlog!" 2>&1
		"!py_exe!" "!Path_to_py_VRDTVSP_Calculate_Duration!" --start_datetime "!start_date_time_QSF!" --end_datetime "!end_date_time_QSF!" --prefix_id "QSF itself" >> "!vrdlog!" 2>&1
		goto :eof
	)
)

REM Use the max of these actual video bitrates (not the "overall" which includes audio bitrate) 
REM		SRC_MI_V_BitRate
REM		QSF_MI_V_BitRate
REM		QSFinfo_ActualVideoBitrate
set /a SRC_calc_Video_Max_Bitrate=0
if !SRC_MI_V_BitRate! gtr !SRC_calc_Video_Max_Bitrate! set /a SRC_calc_Video_Max_Bitrate=!SRC_MI_V_BitRate!
REM 	' NOTE:	After testing, it has been found that ffprobe can mis-report bitrates in the QSF'd file by about double.
REM 	'		Although mediainfo and the "QSF log" values are reasonably close, testing shows ffprobe gets it more "right" when encoding.
REM 	'		Although hopefully correct, this can result in a much lower transcoded filesizes than the originals.
if !QSF_MI_V_BitRate! gtr !SRC_calc_Video_Max_Bitrate! set /a SRC_calc_Video_Max_Bitrate=!QSF_MI_V_BitRate!
if !QSFinfo_ActualVideoBitrate! gtr !SRC_calc_Video_Max_Bitrate! set /a SRC_calc_Video_Max_Bitrate=!QSFinfo_ActualVideoBitrate!
echo SRC_calc_Video_Max_Bitrate=!SRC_calc_Video_Max_Bitrate! from !SRC_MI_V_BitRate!, !QSF_MI_V_BitRate!, !QSFinfo_ActualVideoBitrate! >> "!vrdlog!" 2>&1
REM Now, SRC_calc_Video_Max_Bitrate contains the max video bitrate observed
REM And handy variables include
REM		!SRC_calc_Video_Encoding!
REM		!SRC_calc_Video_Interlacement!"
REM		!SRC_calc_Video_FieldFirst!"
REM		!SRC_calc_Video_Max_Bitrate!"

ECHO !DATE! !TIME! ====================================================================================================================================================== >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! End QSF of file: "%~f1" >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! Input: Video Codec: '!SRC_FF_V_codec_name!' ScanType: '!SRC_calc_Video_Interlacement!' ScanOrder: '!SRC_calc_Video_FieldFirst!' WxH: !SRC_MI_V_Width!x!SRC_MI_V_HEIGHT! dar:'!SRC_FF_V_display_aspect_ratio_slash!' and '!SRC_MI_V_DisplayAspectRatio_String_slash!' >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME!        Audio Codec: '!SRC_FF_A_codec_name!' Audio_Delay_ms: '!SRC_MI_A_Audio_Delay!' Video_Delay_ms: '!SRC_MI_A_Video_Delay!' Bitrate: !QSF_MI_V_BitRate! >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! _vrd_version_primary='!_vrd_version_primary!' _vrd_version_fallback=!_vrd_version_fallback!' qsf_profile=!qsf_profile!' qsf_extension='!qsf_extension!' >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! ====================================================================================================================================================== >> "!vrdlog!" 2>&1

IF /I NOT "!SRC_calc_Video_Encoding!" == "!QSF_calc_Video_Encoding!" (
	ECHO "ERROR - incoming SRC_calc_Video_Encoding '!SRC_calc_Video_Encoding!' NOT EQUAL QSF_calc_Video_Encoding '!QSF_calc_Video_Encoding!'" >> "!vrdlog!" 2>&1
	ECHO SRC file="%~f1" >> "!vrdlog!" 2>&1
	ECHO QSF_file="!QSF_File!" >> "!vrdlog!" 2>&1
	!xPAUSE!
	exit 1
)
IF /I NOT "!SRC_FF_V_codec_name!" == "!QSF_FF_V_codec_name!" (
	ECHO "ERROR - incoming SRC_FF_V_codec_name '!SRC_FF_V_codec_name!' NOT EQUAL QSF_FF_V_codec_name '!QSF_FF_V_codec_name!'" >> "!vrdlog!" 2>&1
	ECHO SRC file="%~f1" >> "!vrdlog!" 2>&1
	ECHO QSF_file="!QSF_File!" >> "!vrdlog!" 2>&1
	!xPAUSE!
	exit 1
)
IF /I NOT "!SRC_calc_Video_Interlacement!" == "!QSF_calc_Video_Interlacement!" (
	ECHO "ERROR - incoming SRC_calc_Video_Interlacement '!SRC_calc_Video_Interlacement!' NOT EQUAL QSF_calc_Video_Interlacement '!QSF_calc_Video_Interlacement!'" >> "!vrdlog!" 2>&1
	ECHO SRC file="%~f1" >> "!vrdlog!" 2>&1
	ECHO QSF_file="!QSF_File!" >> "!vrdlog!" 2>&1
	!xPAUSE!
	exit 1
)
IF /I NOT "!SRC_calc_Video_FieldFirst!" == "!QSF_calc_Video_FieldFirst!" (
	ECHO "ERROR - incoming SRC_calc_Video_FieldFirst '!SRC_calc_Video_FieldFirst!' NOT EQUAL QSF_calc_Video_FieldFirst '!QSF_calc_Video_FieldFirst!'" >> "!vrdlog!" 2>&1
	ECHO SRC file="%~f1" >> "!vrdlog!" 2>&1
	ECHO QSF_file="!QSF_File!" >> "!vrdlog!" 2>&1
	!xPAUSE!
	exit 1
)
ECHO !DATE! !TIME! ====================================================================================================================================================== >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! QSF file details: "!QSF_File!" >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME!   QSF: Video Codec: '!QSF_FF_V_codec_name!' ScanType: '!QSF_calc_Video_Interlacement!' ScanOrder: '!QSF_calc_Video_FieldFirst!' WxH: !QSF_MI_V_Width!x!QSF_MI_V_HEIGHT! dar:'!QSF_FF_V_display_aspect_ratio_slash!' and '!QSF_MI_V_DisplayAspectRatio_String_slash!' >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME!        Audio Codec: '!QSF_FF_A_codec_name!' Audio_Delay_ms: '!QSF_MI_A_Audio_Delay!' Video_Delay_ms: '!QSF_MI_A_Video_Delay!' QSF_Bitrate: !QSF_MI_V_BitRate! SRC_Bitrate: !SRC_MI_V_BitRate!  SRC_calc_Video_Max_Bitrate=!SRC_calc_Video_Max_Bitrate! >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! _vrd_version_primary='!_vrd_version_primary!' _vrd_version_fallback=!_vrd_version_fallback!' qsf_profile=!qsf_profile!' qsf_extension='!qsf_extension!' >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! ====================================================================================================================================================== >> "!vrdlog!" 2>&1

CALL :get_date_time_String "end_date_time_QSF"
echo "!py_exe!" "!Path_to_py_VRDTVSP_Calculate_Duration!" --start_datetime "!start_date_time_QSF!" --end_datetime "!end_date_time_QSF!" --prefix_id "QSF itself" >> "!vrdlog!" 2>&1
"!py_exe!" "!Path_to_py_VRDTVSP_Calculate_Duration!" --start_datetime "!start_date_time_QSF!" --end_datetime "!end_date_time_QSF!" --prefix_id "QSF itself" >> "!vrdlog!" 2>&1
REM =======================================================================================================================================================================================


REM $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
REM OK, by now QSF is completed and we have 
REM		variables for SRC_			including bitrate and whatnot
REM		variables for QSF_
REM		variables for QSFinfo_
REM		a QSF file "!QSF_File!"
REM handy variables include
REM		!SRC_calc_Video_Encoding!
REM		!SRC_calc_Video_Interlacement!"
REM		!SRC_calc_Video_FieldFirst!"
REM		!qsf_extension!"
REM		!SRC_FF_V_codec_name!
REM		!SRC_MI_V_Width!
REM		!SRC_MI_V_HEIGHT!
REM		!SRC_FF_V_display_aspect_ratio_slash!
REM		!SRC_MI_V_DisplayAspectRatio_String_slash!
REM		!SRC_FF_A_codec_name!
REM		!SRC_MI_A_Audio_Delay!'
REM		!SRC_MI_A_Video_Delay!'
REM		!QSF_MI_A_Audio_Delay!'		<- use this one
REM		!QSF_MI_A_Video_Delay!'		<- use this one
REM		!SRC_MI_V_BitRate!
REM		!QSF_MI_V_BitRate!
REM Example variable values:
REM		SRC_MI_V_BitRate=4585677
REM		SRC_MI_G_OverallBitRate=5300172
REM		SRC_FF_G_bit_rate=5071587
REM		QSF_MI_V_BitRate=4585677
REM		QSF_MI_G_OverallBitRate=5300172
REM		QSF_FF_G_bit_rate=5071587
REM		QSFinfo_ActualVideoBitrate=3951544"
REM		QSFinfo_outputFile=D:\VRDTVSP-SCRATCH\AFL-Live-Sport-Talk_Show-AFL-The_Sunday_Footy_Show.2024-03-24.qsf.mp4"
REM		QSFinfo_OutputType=MP4"
REM		QSFinfo_OutputDurationSecs=20"
REM		QSFinfo_OutputDuration=00:00:20"
REM		QSFinfo_OutputSizeMB=10"
REM		QSFinfo_OutputSceneCount=1"
REM		QSFinfo_VideoOutputFrameCount=519"
REM		QSFinfo_AudioOutputFrameCount=617"
REM		QSFinfo_ActualVideoBitrate=3951544"
REM $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

REM
REM Now claculate variables used in the FFMPEG encoding qsf -> destination0mp4
REM

set "Target_File=!destination_mp4_Folder!%~n1.!qsf_extension!"

IF /I "!QSF_calc_Video_Encoding!" == "AVC" (
	REM CALCULATE H.264 TARGET BITRATES FROM THE INCOMING BITRATE
	set /a "X_bitrate_05percent=!SRC_calc_Video_Max_Bitrate! / 20"
	set /a "X_bitrate_10percent=!SRC_calc_Video_Max_Bitrate! / 10"
	set /a "X_bitrate_20percent=!SRC_calc_Video_Max_Bitrate! / 5"
	set /a "X_bitrate_50percent=!SRC_calc_Video_Max_Bitrate! / 2"
	REM ffmpeg nvenc typically seems to undershoot the target bitrate, so bump it up.
	set /a "FFMPEG_V_Target_BitRate=!SRC_calc_Video_Max_Bitrate! + !X_bitrate_05percent!"
	set /a "extra_bitrate_05percent=!FFMPEG_V_Target_BitRate! / 20"
	set /a "extra_bitrate_10percent=!FFMPEG_V_Target_BitRate! / 10"
	set /a "extra_bitrate_20percent=!FFMPEG_V_Target_BitRate! / 5"
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
) ELSE IF /I "!QSF_calc_Video_Encoding!" == "MPEG2" (
	IF /I "%~x1" == ".MPG" (
		set /a "FFMPEG_V_Target_BitRate=4000000"
		set /a "FFMPEG_V_Target_Minimum_BitRate=100000"
		set /a "FFMPEG_V_Target_Maximum_BitRate=!FFMPEG_V_Target_BitRate! * 2"
		set /a "FFMPEG_V_Target_BufSize=!FFMPEG_V_Target_BitRate! * 2"
	) ELSE IF /I "%~x1" == ".VOB" (
		set /a "FFMPEG_V_Target_BitRate=4000000"
		set /a "FFMPEG_V_Target_Minimum_BitRate=100000"
		set /a "FFMPEG_V_Target_Maximum_BitRate=!FFMPEG_V_Target_BitRate! * 2"
		set /a "FFMPEG_V_Target_BufSize=!FFMPEG_V_Target_BitRate! * 2"
	) ELSE (
		set /a "FFMPEG_V_Target_BitRate=2000000"
		set /a "FFMPEG_V_Target_Minimum_BitRate=100000"
		set /a "FFMPEG_V_Target_Maximum_BitRate=!FFMPEG_V_Target_BitRate! * 2"
		set /a "FFMPEG_V_Target_BufSize=!FFMPEG_V_Target_BitRate! * 2"
	)
	ECHO !DATE! !TIME! Bitrates are fixed and NOT calculated, for mpeg2 transcode >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! Bitrates are assumed based on the MPEG2 extension ""%~x1"" being [.mpg/.vob] or [anything else] >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! "AVC" FFMPEG_V_Target_Minimum_BitRate=!FFMPEG_V_Target_Minimum_BitRate! >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! "AVC"         FFMPEG_V_Target_BitRate=!FFMPEG_V_Target_BitRate! >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! "AVC" FFMPEG_V_Target_Maximum_BitRate=!FFMPEG_V_Target_Maximum_BitRate! >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! "AVC"         FFMPEG_V_Target_BufSize=!FFMPEG_V_Target_BufSize! >> "!vrdlog!" 2>&1
) ELSE (
	ECHO !DATE! !TIME! ERROR: UNKNOWN QSF_calc_Video_Encoding="!QSF_calc_Video_Encoding!" to base the transcode calculations on. NUST be AVC or MPEG2 >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! ERROR: UNKNOWN QSF_calc_Video_Encoding="!QSF_calc_Video_Encoding!" to base the transcode calculations on. NUST be AVC or MPEG2 >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! ERROR: UNKNOWN QSF_calc_Video_Encoding="!QSF_calc_Video_Encoding!" to base the transcode calculations on. NUST be AVC or MPEG2 >> "!vrdlog!" 2>&1
	exit 1
)

IF /I "!QSF_calc_Video_Interlacement!" == "PROGRESSIVE" (
	REM set for no deinterlace
	set "FFMPEG_V_dg_deinterlace=0"
) ELSE IF /I "!QSF_calc_Video_Interlacement!" == "INTERLACED" (
	REM set for normal single framerate deinterlace
	set "FFMPEG_V_dg_deinterlace=1"
	set /a "FFMPEG_V_Target_BitRate=4000000"
	set /a "FFMPEG_V_Target_Minimum_BitRate=100000"
	set /a "FFMPEG_V_Target_Maximum_BitRate=!FFMPEG_V_Target_BitRate! * 2"
	set /a "FFMPEG_V_Target_BufSize=!FFMPEG_V_Target_BitRate! * 2"
) ELSE (
	ECHO !DATE! !TIME! ERROR: UNKNOWN QSF_calc_Video_Interlacement="!QSF_calc_Video_Interlacement!" to base transcode calculations on. >> "!vrdlog!" 2>&1
	exit 1
)

IF /I "!QSF_calc_Video_FieldFirst!" == "TFF" (
	set "FFMPEG_V_dg_use_TFF=True"
) ELSE IF /I "!QSF_calc_Video_FieldFirst!" == "BFF" (
	set "FFMPEG_V_dg_use_TFF=False"
) ELSE (
	ECHO !DATE! !TIME! ERROR: UNKNOWN QSF_calc_Video_FieldFirst="!QSF_calc_Video_FieldFirst!" to base transcode calculations on. >> "!vrdlog!" 2>&1
	exit 1
)

REM Default CQ options:
set "FFMPEG_V_cq0=-cq:v 0"
set "FFMPEG_V_cq24=-cq:v 24 -qmin 16 -qmax 48"
set "FFMPEG_V_PROPOSED_x_cq_options=!FFMPEG_V_cq0!"
set "FFMPEG_V_final_cq_options=!FFMPEG_V_cq0!"

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
IF /I NOT "!file_name_part!"=="!file_name_part:AFL=_____!" (
	set "Footy_found=True"
	echo Footy word 'AFL' found in filename '!file_name_part!' >> "!vrdlog!" 2>&1
) ELSE IF /I NOT "!file_name_part!"=="!file_name_part:SANFL=_____!" (
	set "Footy_found=True"
	echo Footy word 'SANFL' found in filename '!file_name_part!' >> "!vrdlog!" 2>&1
) ELSE IF /I NOT "!file_name_part!"=="!file_name_part:Crows=_____!" (
	set "Footy_found=True"
	echo Footy word 'Crows' found in filename '!file_name_part!' >> "!vrdlog!" 2>&1
) ELSE (
	set "Footy_found=False"
	echo NO Footy words found in filename '!file_name_part!' >> "!vrdlog!" 2>&1
)

IF /I "!Footy_found!" == "True" (
	IF /I "!QSF_calc_Video_Interlacement!" == "PROGRESSIVE" (
		REM set for no deinterlace
		set "FFMPEG_V_dg_deinterlace=0"
		ECHO Already Progressive video, Footy words found in filename '!file_name_part!', FFMPEG_V_dg_deinterlace=!FFMPEG_V_dg_deinterlace! NO Footy variables set >> "!vrdlog!" 2>&1
	) ELSE IF /I "!QSF_calc_Video_Interlacement!" == "INTERLACED" (
		REM set for double framerate deinterlace
		set "FFMPEG_V_dg_deinterlace=2"
		vrdtvsp_final_dg_deinterlace = 2	' set for double framerate deinterlace
		REM use python to calculate rounded values for upped FOOTY double framerate deinterlaced output
		CALL :calc_single_number_result_py "int(round(!FFMPEG_V_Target_BitRate! * 1.75))"       "Footy_FFMPEG_V_Target_BitRate"
		CALL :calc_single_number_result_py "int(round(!Footy_FFMPEG_V_Target_BitRate! * 0.20))" "Footy_FFMPEG_V_Target_Minimum_BitRate"
		CALL :calc_single_number_result_py "int(round(!Footy_FFMPEG_V_Target_BitRate! * 2))"    "Footy_FFMPEG_V_Target_Maximum_BitRate"
		CALL :calc_single_number_result_py "int(round(!Footy_FFMPEG_V_Target_BitRate! * 2))"    "Footy_FFMPEG_V_Target_BufSize"
		ECHO Interlaced video, Footy words found in filename '!file_name_part!', FFMPEG_V_dg_deinterlace=!FFMPEG_V_dg_deinterlace!  Footy variables set >> "!vrdlog!" 2>&1
	) ELSE (
		ECHO !DATE! !TIME! ERROR: UNKNOWN QSF_calc_Video_Interlacement="!QSF_calc_Video_Interlacement!" to base transcode calculations on. >> "!vrdlog!" 2>&1
		exit 1
	)
) ELSE (
	echo NO Footy words found in filename '!file_name_part!', FFMPEG_V_dg_deinterlace unchanged=!FFMPEG_V_dg_deinterlace!, NO footy variables set  >> "!vrdlog!" 2>&1
)

ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
echo set FFMPEG_ >> "!vrdlog!" 2>&1
set FFMPEG_ >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
echo set Footy_ >> "!vrdlog!" 2>&1
set Footy_ >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
echo set X_ >> "!vrdlog!" 2>&1
set X_ >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
echo set extra_ >> "!vrdlog!" 2>&1
set extra_ >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1


goto :eof


BAD BAD BAD FROM HERE DOWN




























ECHO !DATE! !TIME! ====================================================================================================================================================== >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! Start Conversion of "!scratch_file_qsf!" into destination >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! input QSF file: Q_Video Codec: "!Q_V_Codec_legacy!" Q_ScanType: "!Q_V_ScanType!" Q_ScanOrder: "!Q_V_ScanOrder!" !Q_V_Width!x!Q_V_Height! dar=!Q_V_DisplayAspectRatio_String! sar=!Q_V_PixelAspectRatio! Q_Audio Codec: "!Q_A_Codec_legacy!" Q_Audio_Delay_ms: !Q_A_Audio_Delay_ms! Q_Audio_Delay_ms_legacy: !Q_A_Video_Delay_ms_legacy! >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! ====================================================================================================================================================== >> "!vrdlog!" 2>&1
REM
REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM
REM Lets do the Conversion ...
REM
set destination_file=!destination_mp4_Folder!%~n1.mp4
ECHO DEL /F "!destination_file!" >> "!vrdlog!" 2>&1
DEL /F "!destination_file!" >> "!vrdlog!" 2>&1
REM
REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
:do_ffmpeg_conversion
REM
REM do it via ffmpeg
REM
REM +++++++++++++++++++++++++
REM Calculate the target minimum_bitrate, target_bitrate, maximum_bitrate, buffer size : all from the QSF file settings.
REM Note that the only reliable variable obtained from he QSF file is Q_V_BitRate
REM
IF /I "!Q_V_Codec_legacy!" == "AVC" (
	REM CALCULATE H.264 TARGET BITRATES FROM THE INCOMING BITRATE
	set /a "X_bitrate_05percent=!INCOMING_BITRATE! / 20"
	set /a "X_bitrate_10percent=!INCOMING_BITRATE! / 10"
	set /a "X_bitrate_20percent=!INCOMING_BITRATE! / 5"
	set /a "X_bitrate_50percent=!INCOMING_BITRATE! / 2"
	REM ffmpeg nvenc typically seems to undershoot the target bitrate, so bump it up.
	REM set /a "FF_V_Target_BitRate=!INCOMING_BITRATE! + !X_bitrate_20percent! + !X_bitrate_10percent!"
	REM set /a "FF_V_Target_BitRate=!INCOMING_BITRATE! + !X_bitrate_10percent!"
	set /a "FF_V_Target_BitRate=!INCOMING_BITRATE! + !X_bitrate_05percent!"
	set /a "XT_bitrate_05percent=!FF_V_Target_BitRate! / 20"
	set /a "XT_bitrate_10percent=!FF_V_Target_BitRate! / 10"
	set /a "XT_bitrate_20percent=!FF_V_Target_BitRate! / 5"
	set /a "XT_bitrate_50percent=!FF_V_Target_BitRate! / 2"
	set /a "FF_V_Target_Minimum_BitRate=!XT_bitrate_20percent!"
	set /a "FF_V_Target_Maximum_BitRate=!FF_V_Target_BitRate! * 2"
	set /a "FF_V_Target_BufSize=!FF_V_Target_BitRate! * 2"
	ECHO !DATE! !TIME! Bitrates are calculated from Compared incoming AVC bitrate. "Q_V_BitRate=!Q_V_BitRate!" vs "Q_V_BitRate_FF=!Q_V_BitRate_FF!" vs "Q_ACTUAL_QSF_LOG_BITRATE=!Q_ACTUAL_QSF_LOG_BITRATE!" >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! Compared INCOMING_BITRATE=!INCOMING_BITRATE! = incoming AVC bitrate >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! X_bitrate_05percent=!X_bitrate_05percent! >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! X_bitrate_10percent=!X_bitrate_10percent! >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! X_bitrate_20percent=!X_bitrate_20percent! >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! X_bitrate_50percent=!X_bitrate_50percent! >> "!vrdlog!" 2>&1
) ELSE (
	REM is MPEG2 input, so GUESS at reasonable H.264 TARGET BITRATE
	set /a "FF_V_Target_BitRate=2000000"
	set /a "FF_V_Target_Minimum_BitRate=100000"
	set /a "FF_V_Target_Maximum_BitRate=!FF_V_Target_BitRate! * 2"
	set /a "FF_V_Target_BufSize=!FF_V_Target_BitRate! * 2"
	ECHO !DATE! !TIME! Bitrates are fixed non-calculated as OK for mpeg2 transcode >> "!vrdlog!" 2>&1
)
ECHO !DATE! !TIME! FF_V_Target_BitRate=!FF_V_Target_BitRate! >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! FF_V_Target_Minimum_BitRate=!FF_V_Target_Minimum_BitRate! >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! FF_V_Target_Maximum_BitRate=!FF_V_Target_Maximum_BitRate! >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! FF_V_Target_BufSize=!FF_V_Target_BufSize! >> "!vrdlog!" 2>&1
REM +++++++++++++++++++++++++
:do_loudnorm_detection
ECHO !DATE! !TIME! ***************************** start Find Audio Loudness ***************************** >> "%vrdlog%" 2>&1
REM
set "loudnorm_filter="
set "AUDIO_process="
REM +++++++++++++++++++++++++
ECHO !DATE! !TIME! >> "%vrdlog%" 2>&1
ECHO !DATE! !TIME! FOR NOW - DO NO AUDIO FILTERING, on the basis that ads are now VERY loud and their presence interferes with the audio levelling detection. >> "%vrdlog%" 2>&1
ECHO !DATE! !TIME! >> "%vrdlog%" 2>&1
goto :after_loudnorm_detection
REM +++++++++++++++++++++++++
REM
set jsonfile=!scratch_Folder!%~n1.loudnorm_scan.json
SET loudnorm_I=-16
SET loudnorm_TP=0.0
SET loudnorm_LRA=11
ECHO !DATE! !TIME! "!ffmpegexe64!"  -nostats -nostdin -y -hide_banner -i "!scratch_file_qsf!" -threads 0 -vn -af loudnorm=I=%loudnorm_I%:TP=%loudnorm_TP%:LRA=%loudnorm_LRA%:print_format=json -f null - >> "%vrdlog%" 2>&1
"!ffmpegexe64!"  -nostats -nostdin -y -hide_banner -i "!scratch_file_qsf!" -threads 0 -vn -af loudnorm=I=%loudnorm_I%:TP=%loudnorm_TP%:LRA=%loudnorm_LRA%:print_format=json -f null - 2> "%jsonFile%"  
SET EL=!ERRORLEVEL!
IF /I "!EL!" NEQ "0" (
   ECHO !DATE! !TIME! *********  loudnorm scan Error !EL! was found >> "%vrdlog%" 2>&1
   ECHO !DATE! !TIME! *********  ABORTING ... >> "%vrdlog%" 2>&1
   !xPAUSE!
   EXIT !EL!
)
ECHO TYPE "%jsonFile%" >> "%vrdlog%" 2>&1
TYPE "%jsonFile%" >> "%vrdlog%" 2>&1
REM all the trickery below is simply to remove quotes and tabs and spaces from the json single-level response
set "loudnorm_input_i="
set "loudnorm_input_tp="
set "loudnorm_input_lra="
set "loudnorm_input_thresh="
set "loudnorm_target_offset="
for /f "tokens=1,2 delims=:, " %%a in (' find ":" ^< "%jsonFile%" ') do (
   set "var="
   for %%c in (%%~a) do (set "var=!var!,%%~c")
   set "var=!var:~1!"
   set "val="
   for %%d in (%%~b) do (set "val=!val!,%%~d")
   set "val=!val:~1!"
   ECHO !DATE! !TIME! .!var!.=.!val!. >> "%vrdlog%" 2>&1
   IF /I "!var!" == "input_i"         set "!var!=!val!"
   IF /I "!var!" == "input_tp"        set "!var!=!val!"
   IF /I "!var!" == "input_lra"       set "!var!=!val!"
   IF /I "!var!" == "input_thresh"    set "!var!=!val!"
   IF /I "!var!" == "target_offset"   set "!var!=!val!"
)
set "loudnorm_input_i=%input_i%" >> "%vrdlog%" 2>&1
set "loudnorm_input_tp=%input_tp%" >> "%vrdlog%" 2>&1
set "loudnorm_input_lra=%input_lra%" >> "%vrdlog%" 2>&1
set "loudnorm_input_thresh=%input_thresh%" >> "%vrdlog%" 2>&1
set "loudnorm_target_offset=%target_offset%" >> "%vrdlog%" 2>&1
REM check for bad loudnorm values ... if baddies found, use dynaudnorm instead
set AUDIO_process=loudnorm
IF /I "%loudnorm_input_i%" == "inf" set AUDIO_process=dynaudnorm
IF /I "%loudnorm_input_i%" == "-inf" set AUDIO_process=dynaudnorm
IF /I "%loudnorm_input_tp%" == "inf" set AUDIO_process=dynaudnorm
IF /I "%loudnorm_input_tp%" == "-inf" set AUDIO_process=dynaudnorm
IF /I "%loudnorm_input_lra%" == "inf" set AUDIO_process=dynaudnorm
IF /I "%loudnorm_input_lra%" == "-inf" set AUDIO_process=dynaudnorm
IF /I "%loudnorm_input_thresh%" == "inf" set AUDIO_process=dynaudnorm
IF /I "%loudnorm_input_thresh%" == "-inf" set AUDIO_process=dynaudnorm
IF /I "%loudnorm_target_offset%" == "inf" set AUDIO_process=dynaudnorm
IF /I "%loudnorm_target_offset%" == "-inf" set AUDIO_process=dynaudnorm
REM
REM later, in a second encoding pass we MUST down-convert from 192k (loadnorm upsamples it to 192k which is way way too high ... use  -ar 48k or -ar 48000
REM
set AUDIO_process
set AUDIO_process >> "%vrdlog%" 2>&1
IF /I "%AUDIO_process%" == "loudnorm" (
   ECHO !DATE! !TIME! "Proceeding with normal LOUDNORM audio normalisation ..."  >> "%vrdlog%" 2>&1
   set loudnorm_filter=-af "loudnorm=I=%loudnorm_I%:TP=%loudnorm_TP%:LRA=%loudnorm_LRA%:measured_I=%loudnorm_input_i%:measured_LRA=%loudnorm_input_lra%:measured_TP=%loudnorm_input_tp%:measured_thresh=%loudnorm_input_thresh%:offset=%loudnorm_target_offset%:linear=true:print_format=summary"
   ECHO !DATE! !TIME! "loudnorm_filter=%loudnorm_filter%" >> "%vrdlog%" 2>&1
) ELSE (
   ECHO !DATE! !TIME! "********* ERROR VALUES DETECTED FROM LOUDNORM - Doing UNUSUAL dynaudnorm audio normalisation instead ..." >> "%vrdlog%" 2>&1
   set loudnorm_filter=-af "dynaudnorm"
   ECHO !DATE! !TIME! "loudnorm_filter=%loudnorm_filter% (Should be dynaudnorm because loudnorm scan returned bad values)" >> "%vrdlog%" 2>&1
)
ECHO !DATE! !TIME! >> "%vrdlog%" 2>&1
set loudnorm_ >> "%vrdlog%" 2>&1
REM
:after_loudnorm_detection
REM
REM +++++++++++++++++++++++++
set "V_cut_start="
set "V_cut_duration="
REM set V_cut_start=-ss "00:35:00"
REM set V_cut_duration=-t "00:15:00"
REM +++++++++++++++++++++++++
IF /I "%COMPUTERNAME%" == "3900X" (
	set "ffmpeg_RTX2060super_extra_flags=-spatial-aq 1 -temporal-aq 1 -refs 3"
) ELSE (
	set "ffmpeg_RTX2060super_extra_flags="
)
REM +++++++++++++++++++++++++
set AO_=!loudnorm_filter! -c:a libfdk_aac -cutoff 20000 -ab 256k -ar 48000
REM ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
ECHO !DATE! !TIME! "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" >> "%vrdlog%" 2>&1
ECHO !DATE! !TIME! NOTE: After testing, it has been found that ffprobe can mis-report bitrates in the QSF'd file by about double. >> "%vrdlog%" 2>&1
ECHO !DATE! !TIME!       Although mediainfo and the "QSF log" values are reasonably close, testing shows ffprobe gets it more "right" when encoding. >> "%vrdlog%" 2>&1
ECHO !DATE! !TIME!       Although hopefully correct, this can result in a much lower transcoded filesizes than the originals. >> "%vrdlog%" 2>&1
ECHO !DATE! !TIME!       For now, accept what we PROPOSE on whether to "Up" the CQ from 0 to 24. >> "%vrdlog%" 2>&1
set "x_cq0=-cq:v 0"
set "x_cq24=-cq:v 24 -qmin 16 -qmax 48"
set "x_cq_options=!x_cq0!"
set "PROPOSED_x_cq_options=!x_cq_options!"
ECHO !DATE! !TIME! "Initial Default x_cq_options=!x_cq_options!" >> "%vrdlog%" 2>&1
REM
REM FOR AVC INPUT FILES ONLY, calculate the CQ to use (default to CQ0)
REM
REM There are special cases where Mediainfo detects a lower bitrate than FFPROBE
REM and MediaInfo is likely right ... however FFPROBE is what we want it to be.
REM When this happens, if we just leave the bitrate CQ as-is then ffmpeg just undershoots 
REM even though we specify the higher bitrate of FFPROBE.
REM So ...
REM If we detect such a case, change to CQ24 instead of CQ0 and leave the 
REM specified bitrate unchanged ... which "should" fix it up.
REM
IF /I "!Q_V_Codec_legacy!" == "AVC" (
	ECHO !DATE! !TIME! "????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????" >> "%vrdlog%" 2>&1
	ECHO Example table of values and actions >> "%vrdlog%" 2>&1
	ECHO	MI		FF		INCOMING	ACTION >> "%vrdlog%" 2>&1
	ECHO	0		0		5Mb			set to CQ 0 >> "%vrdlog%" 2>&1
	ECHO	0		1.5Mb	1.5Mb		set to CQ 24 >> "%vrdlog%" 2>&1
	ECHO	0		4Mb		4Mb			set to CQ 0 >> "%vrdlog%" 2>&1
	ECHO	1.5Mb	0		1.5Mb		set to CQ 24 >> "%vrdlog%" 2>&1
	ECHO	1.5Mb 	1.5Mb	1.5Mb		set to CQ 24 >> "%vrdlog%" 2>&1
	ECHO	1.5Mb	4Mb		4Mb			set to CQ 24 *** this one >> "%vrdlog%" 2>&1
	ECHO	4Mb		0		4Mb			set to CQ 0 >> "%vrdlog%" 2>&1
	ECHO	4Mb		1.5Mb	4Mb			set to CQ 0 >> "%vrdlog%" 2>&1
	ECHO	4Mb		5Mb		5Mb			set to CQ 0 >> "%vrdlog%" 2>&1
	ECHO !DATE! !TIME! "????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????" >> "%vrdlog%" 2>&1
	ECHO !DATE! !TIME! "Calculating whether to Bump CQ from 0 to 24 ..." >> "%vrdlog%" 2>&1
	ECHO !DATE! !TIME! "INCOMING_BITRATE_MEDIAINFO=!INCOMING_BITRATE_MEDIAINFO!" >> "%vrdlog%" 2>&1
	ECHO !DATE! !TIME! "INCOMING_BITRATE_FFPROBE=!INCOMING_BITRATE_FFPROBE!" >> "%vrdlog%" 2>&1
	ECHO !DATE! !TIME! "INCOMING_BITRATE_QSF_LOG=!INCOMING_BITRATE_QSF_LOG!" >> "%vrdlog%" 2>&1
	ECHO !DATE! !TIME! "so (the max of them) INCOMING_BITRATE=!INCOMING_BITRATE!" >> "%vrdlog%" 2>&1
	REM Nested IF statements means ANDing them
	If !INCOMING_BITRATE! LSS 2200000 (
		REM low bitrate, do not touch the bitrate itself, instead bump to CQ24
		ECHO !DATE! !TIME! "yes to Low INCOMING_BITRATE !INCOMING_BITRATE! LSS 2200000" >> "%vrdlog%" 2>&1
		set "PROPOSED_x_cq_options=!x_cq24!"
		ECHO !DATE! !TIME! "PROPOSED_x_cq_options=!PROPOSED_x_cq_options!" >> "%vrdlog%" 2>&1
	)
	If !INCOMING_BITRATE_MEDIAINFO! GTR 0 (
		ECHO !DATE! !TIME! "yes to INCOMING_BITRATE_MEDIAINFO !INCOMING_BITRATE_MEDIAINFO! GTR 0" >> "%vrdlog%" 2>&1
		IF !INCOMING_BITRATE_MEDIAINFO! LSS 2200000 (
			ECHO !DATE! !TIME! "yes to AND INCOMING_BITRATE_MEDIAINFO !INCOMING_BITRATE_MEDIAINFO! LSS 2200000" >> "%vrdlog%" 2>&1
			IF !INCOMING_BITRATE_FFPROBE! LSS 3400000 (
				ECHO !DATE! !TIME! "yes to AND INCOMING_BITRATE_FFPROBE !INCOMING_BITRATE_FFPROBE! LSS 3400000" >> "%vrdlog%" 2>&1
				set "PROPOSED_x_cq_options=!x_cq24!"
				ECHO !DATE! !TIME! "PROPOSED_x_cq_options=!PROPOSED_x_cq_options!" >> "%vrdlog%" 2>&1
			)
		)
	)
	set "x_cq_options=!PROPOSED_x_cq_options!"
)
:after_CQ_checking
ECHO !DATE! !TIME! "????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????" >> "%vrdlog%" 2>&1
ECHO !DATE! !TIME! >> "%vrdlog%" 2>&1
ECHO !DATE! !TIME! "For file !scratch_file_qsf!" >> "%vrdlog%" 2>&1
ECHO !DATE! !TIME! "Final x_cq_options=!x_cq_options!  for incoming !Q_V_Width!x!Q_V_Height! !Q_V_Codec_legacy!" >> "%vrdlog%" 2>&1
ECHO !DATE! !TIME! >> "%vrdlog%" 2>&1
ECHO !DATE! !TIME! "????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????" >> "%vrdlog%" 2>&1
ECHO !DATE! !TIME! "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" >> "%vrdlog%" 2>&1
REM ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
REM ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
REM Check for Footy, after any final fiddling with bitrates and CQ.
REM If is footy, deinterlace to 50FPS 50p, doubling the framerate, rather than just 25p
REM so that we maintain the "motion fluidity" of 50i into 50p. It's better than nothing.
REM SET the yadif MODE deinterlacing parameter if we are processing FOTTY them go to 50p
REM which plays on Chromecast Ultra and on our two Samsung 4K TVs
REM		yadif:mode:parity:deint
REM		yadif parity 0=TFF 1=BFF 0=AUTO
REM		yadif:0:0:0 = Output one frame for each frame, incoming is TFF, Deinterlace all frames
REM		yadif:1:0:0 = Output one frame for each field, incoming is TFF, Deinterlace all frames (doubles framerate)
set "yadif_mode=0"
REM default to TFF
set "yadif_tff_bff=0"
set "dg_tff=True"
IF /I "!V_ScanOrder!" == "BFF" (
	REM must be flagged as explicitly BFF
	set "yadif_tff_bff=1"
	set "dg_tff=False"
)
set "Footy_yadif_mode=0"
REM deprecated: do not fiddle with x_cq_options in footy checks processing
set "PROPOSED_x_cq_options=!x_cq_options!"
set "Footy_found=FALSE"
IF /I NOT "!V_ScanType!" == "Progressive" (
	set "Footy_found=FALSE"
	echo !DATE! !TIME! Checking for a footy file, by looking at the filename '%~n1' >> "!vrdlog!" 2>&1
	echo '%~n1'|findstr /i /c:"AFL" >> "!vrdlog!" 2>&1
	IF !errorlevel! EQU 0 (
		ECHO !DATE! !TIME! Footy File: string 'AFL' found in filename '%~n1' >> "!vrdlog!" 2>&1
		set "Footy_found=TRUE"
	)
	echo '%~n1'|findstr /i /c:"SANFL" >> "!vrdlog!" 2>&1
	IF !errorlevel! EQU 0 (
		ECHO !DATE! !TIME! Footy File: string 'SANFL' found in filename '%~n1' >> "!vrdlog!" 2>&1
		set "Footy_found=TRUE"
	)
	echo '%~n1'|findstr /i /c:"Adelaide Crows" >> "!vrdlog!" 2>&1
	IF !errorlevel! EQU 0 (
		ECHO !DATE! !TIME! Footy File: string 'Adelaide Crows' found in filename '%~n1' >> "!vrdlog!" 2>&1
		set "Footy_found=TRUE"
	)
	IF /I "!Footy_found!" == "TRUE" (
		ECHO !DATE! !TIME! Footy File: FOOTY FOUND in "%~n1", deinterlace to 50 fps and up the target bitrates by 75 percent >> "!vrdlog!" 2>&1
		ECHO !DATE! !TIME! Footy File: set Footy_yadif_mode parameter= 1 = one frame per FIELD = deinterlace and double the framerate from 25i to 50p >> "!vrdlog!" 2>&1
		set "Footy_yadif_mode=1"
		set /a "Footy_bitrate_05percent=!FF_V_Target_BitRate! / 20"
		set /a "Footy_bitrate_10percent=!FF_V_Target_BitRate! / 10"
		set /a "Footy_bitrate_20percent=!FF_V_Target_BitRate! / 5"
		set /a "Footy_bitrate_50percent=!FF_V_Target_BitRate! / 2"
		ECHO !DATE! !TIME! "Incoming FF_V_Target_BitRate=!FF_V_Target_BitRate!" >> "!vrdlog!" 2>&1
		ECHO !DATE! !TIME! "Footy_bitrate_05percent=!Footy_bitrate_05percent!" >> "!vrdlog!" 2>&1
		ECHO !DATE! !TIME! "Footy_bitrate_10percent=!Footy_bitrate_10percent!" >> "!vrdlog!" 2>&1
		ECHO !DATE! !TIME! "Footy_bitrate_20percent=!Footy_bitrate_20percent!" >> "!vrdlog!" 2>&1
		ECHO !DATE! !TIME! "Footy_bitrate_50percent=!Footy_bitrate_50percent!" >> "!vrdlog!" 2>&1
		ECHO !DATE! !TIME! "Summing FF_V_Target_BitRate=!FF_V_Target_BitRate! + !Footy_bitrate_50percent! + !Footy_bitrate_20percent! + !Footy_bitrate_10percent!" >> "!vrdlog!" 2>&1
		set /a "Footy_FF_V_Target_BitRate=!FF_V_Target_BitRate! + !Footy_bitrate_50percent! + !Footy_bitrate_20percent! + !Footy_bitrate_05percent!"
		set /a "Footy_FF_V_Target_Minimum_BitRate=!Footy_bitrate_20percent!"
		set /a "Footy_FF_V_Target_Maximum_BitRate=!FF_V_Target_BitRate! * 2"
		set /a "Footy_FF_V_Target_BufSize=!FF_V_Target_BitRate! * 2"
		ECHO !DATE! !TIME! Footy File: Upped Footy_FF_V_Target_BitRate=!Footy_FF_V_Target_BitRate! >> "!vrdlog!" 2>&1
		ECHO !DATE! !TIME! Footy File: Footy_FF_V_Target_Minimum_BitRate=!Footy_FF_V_Target_Minimum_BitRate! >> "!vrdlog!" 2>&1
		ECHO !DATE! !TIME! Footy File: Footy_FF_V_Target_Maximum_BitRate=!Footy_FF_V_Target_Maximum_BitRate! >> "!vrdlog!" 2>&1
		ECHO !DATE! !TIME! Footy File: Footy_FF_V_Target_BufSize=!Footy_FF_V_Target_BufSize! >> "!vrdlog!" 2>&1
		REM set "PROPOSED_x_cq_options=!x_cq24!"
		REM ECHO !DATE! !TIME! Footy File: PROPOSED_x_cq_options=!PROPOSED_x_cq_options! >> "!vrdlog!" 2>&1
	) ELSE (
		ECHO !DATE! !TIME! Not Footy File: footy NOT found in "%~f1", >> "!vrdlog!" 2>&1
		ECHO !DATE! !TIME! Not Footy File: set Footy_yadif_mode parameter = 0 = one frame per FRAME - deinterlace and maintain the framerate 25i at 25p >> "!vrdlog!" 2>&1
		set "Footy_yadif_mode=0"
		set /a "Footy_FF_V_Target_BitRate=!FF_V_Target_BitRate!"
		set /a "Footy_FF_V_Target_Minimum_BitRate=!FF_V_Target_Minimum_BitRate!"
		set /a "Footy_FF_V_Target_Maximum_BitRate=!FF_V_Target_Maximum_BitRate!"
		set /a "Footy_FF_V_Target_BufSize=!FF_V_Target_BufSize!"
		REM set "PROPOSED_x_cq_options=!x_cq_options!"
		REM ECHO !DATE! !TIME! Footy File: not a Foory file: PROPOSED_x_cq_options=!PROPOSED_x_cq_options! >> "!vrdlog!" 2>&1
	)
	REM set "x_cq_options=!PROPOSED_x_cq_options!"
)
REM ECHO !DATE! !TIME! >> "%vrdlog%" 2>&1
REM ECHO !DATE! !TIME! After Footy processing, x_cq_options=!x_cq_options! >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! >> "%vrdlog%" 2>&1
ECHO !DATE! !TIME! "????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????" >> "%vrdlog%" 2>&1
REM +++++++++++++++++++++++++
REM
REM set destination_file_FF=!destination_mp4_Folder!%~n1.mp4.vrdtvsp.z-from_qsf_via_ffmpeg_copy.mp4
REM set destination_file_FF=!destination_mp4_Folder!%~n1.mp4.cq_!x_cq!.mp4
REM
set _VPY_file=!scratch_Folder!%~n1.VPY
set _DGI_file=!scratch_Folder!%~n1.DGI
set _DGI_autolog=!scratch_Folder!%~n1.log
IF /I "!Footy_found!" == "TRUE" (
	REM set for double framerate deinterlace
	set dg_deinterlace=2
) ELSE (
	REM set for normal single framerate deinterlace
	set dg_deinterlace=1
)
IF /I "!V_ScanType!" == "Progressive" (
	REM Progressive video, no deinterlacing necessary
	set dg_deinterlace=0
	IF /I "!Q_V_Codec_legacy!" == "AVC" (
		REM is progressive h.264 - no deinterlace, no sharpen, copy video stream only
		ECHO "***FF*** " >> "%vrdlog%" 2>&1
		ECHO "***FF*** Progressive AVC input - setting ff_cmd accordingly ... copy video stream, convert audio stream " >> "%vrdlog%" 2>&1
		ECHO "***FF*** " >> "%vrdlog%" 2>&1
		REM no -cq:v options or bitrates apply to -c:v copy
		REM Handle an ffmpeg.exe with a removed Opencl
		REM set "VO_sharpen=" >> "%vrdlog%" 2>&1
		REM set ff_cmd="!ffmpegexe64_OpenCL!" -hide_banner -v verbose -nostats !ff_OpenCL_device_init! !V_cut_start! -i "!scratch_file_qsf!" -vf "setdar=!V_DisplayAspectRatio_String_slash!" !V_cut_duration! -c:v copy !AO_! -y "!destination_file!" >> "%vrdlog%" 2>&1
		set ff_cmd="!ffmpegexe64!" -hide_banner -v verbose -nostats !V_cut_start! -i "!scratch_file_qsf!" -vf "setdar=!V_DisplayAspectRatio_String_slash!" !V_cut_duration! -c:v copy !AO_! -y "!destination_file!" >> "%vrdlog%" 2>&1
	) ELSE (
		REM is progressive mpeg2 - no deinterlace, yes denoise, sharpen (more for mpeg2 source),  moderate quality
		ECHO "***FF*** " >> "%vrdlog%" 2>&1
		ECHO "***FF*** Progressive MPEG2 input - setting ff_cmd accordingly ... denoise/sharpen video stream via vapoursynth, convert audio stream " >> "%vrdlog%" 2>&1
		ECHO "***FF*** " >> "%vrdlog%" 2>&1
		REM run DGIndex
		ECHO DEL /F "!_DGI_file!" >> "%vrdlog%" 2>&1
		DEL /F "!_DGI_file!" >> "%vrdlog%" 2>&1
		ECHO "%VSdgindexNVexe64%" -i "!scratch_file_qsf!" -h -o "!_DGI_file!" -e >> "%vrdlog%" 2>&1
		set "start_date_time=!date! !time!"
		"%VSdgindexNVexe64%" -i "!scratch_file_qsf!" -h -o "!_DGI_file!" -e >> "%vrdlog%" 2>&1
		set "end_date_time=!date! !time!"
		powershell -NoLogo -ExecutionPolicy Unrestricted -Sta -NonInteractive -WindowStyle Minimized -File "!Path_to_py_VRDTVSP_Calculate_Duration!" -start_date_time "!start_date_time!" -end_date_time "!end_date_time!" -prefix_id "VSdgindexNVexe64" >> "!vrdlog!" 2>&1		
		REM ECHO TYPE "!_DGI_file!" >> "%vrdlog%" 2>&1
		REM TYPE "!_DGI_file!" >> "%vrdlog%" 2>&1
		REM ECHO DIR !scratch_Folder! >> "%vrdlog%" 2>&1
		REM DIR !scratch_Folder! >> "%vrdlog%" 2>&1
		ECHO TYPE "!_DGI_autolog!" >> "%vrdlog%" 2>&1
		TYPE "!_DGI_autolog!" >> "%vrdlog%" 2>&1
		ECHO DEL /F "!_DGI_autolog!" >> "%vrdlog%" 2>&1
		DEL /F "!_DGI_autolog!" >> "%vrdlog%" 2>&1
		REM Create the .vpy file with the .DGI as input
		ECHO DEL /F "!_VPY_file!" >> "%vrdlog%" 2>&1
		DEL /F "!_VPY_file!" >> "%vrdlog%" 2>&1
		ECHO import vapoursynth as vs		# this allows use of constants eg vs.YUV420P8 >> "!_VPY_file!" 2>&1
		ECHO from vapoursynth import core	# actual vapoursynth core >> "!_VPY_file!" 2>&1
		ECHO #import functools >> "!_VPY_file!" 2>&1
		ECHO #import mvsfunc as mvs			# this relies on the .py residing at the VS folder root level - see run_vsrepo.bat >> "!_VPY_file!" 2>&1
		ECHO #import havsfunc as haf		# this relies on the .py residing at the VS folder root level - see run_vsrepo.bat >> "!_VPY_file!" 2>&1
		ECHO core.std.LoadPlugin^(r'!vs_root!DGIndex\DGDecodeNV.dll'^) # do it like gonca https://forum.doom9.org/showthread.php?p=1877765#post1877765 >> "!_VPY_file!" 2>&1
		ECHO core.avs.LoadPlugin^(r'!vs_root!DGIndex\DGDecodeNV.dll'^) # do it like gonca https://forum.doom9.org/showthread.php?p=1877765#post1877765 >> "!_VPY_file!" 2>&1
		ECHO video = core.dgdecodenv.DGSource^(r'!_DGI_file!', deinterlace=!dg_deinterlace!, use_top_field=!dg_tff!, use_pf=False^) >> "!_VPY_file!" 2>&1
		ECHO # DGDecNV changes - >> "!_VPY_file!" 2>&1
		ECHO # 2020.10.21 Added new parameters cstrength and cblend to independently control the chroma denoising. >> "!_VPY_file!" 2>&1
		ECHO # 2020.11.07 Revised DGDenoise parameters. The 'chroma' option is removed. >> "!_VPY_file!" 2>&1
		ECHO #            Now, if 'strength' is set to 0.0 then luma denoising is disabled, >> "!_VPY_file!" 2>&1
		ECHO #            and if cstrength is set to 0.0 then chroma denoising is disabled. >> "!_VPY_file!" 2>&1
		ECHO #            'cstrength' is now defaulted to 0.0, and 'searchw' is defaulted to 9. >> "!_VPY_file!" 2>&1
		ECHO #video = core.avs.DGDenoise^(video, strength=0.15, cstrength=0.15^) # replaced chroma=True >> "!_VPY_file!" 2>&1
		ECHO video = core.avs.DGDenoise^(video, strength=0.06, cstrength=0.06^) # replaced chroma=True >> "!_VPY_file!" 2>&1
		ECHO video = core.avs.DGSharpen^(video, strength=0.3^) >> "!_VPY_file!" 2>&1
		ECHO #video = core.avs.DGSharpen^(video, strength=0.1^) >> "!_VPY_file!" 2>&1
		ECHO #video = core.avs.DGSharpen^(video, strength=0.2^) >> "!_VPY_file!" 2>&1
		ECHO #video = vs.core.text.ClipInfo^(video^) >> "!_VPY_file!" 2>&1
		ECHO video.set_output^(^) >> "!_VPY_file!" 2>&1
		ECHO ---------------------------- >> "%vrdlog%" 2>&1
		ECHO TYPE "!_VPY_file!" >> "%vrdlog%" 2>&1
		TYPE "!_VPY_file!" >> "%vrdlog%" 2>&1
		ECHO ---------------------------- >> "%vrdlog%" 2>&1
		REM from mpeg2, always -cq:v 0
		set VO_HQ=-vsync 0 -sws_flags lanczos+accurate_rnd+full_chroma_int+full_chroma_inp -strict experimental -c:v h264_nvenc -pix_fmt nv12 -preset p7 -multipass fullres !ffmpeg_RTX2060super_extra_flags! -rc:v vbr -cq:v 0 -b:v !FF_V_Target_BitRate! -minrate:v !FF_V_Target_Minimum_BitRate! -maxrate:v !FF_V_Target_Maximum_BitRate! -bufsize !FF_V_Target_BufSize! -profile:v high -level 5.2 -movflags +faststart+write_colr >> "%vrdlog%" 2>&1
		REM Handle an ffmpeg.exe with a removed Opencl
		REM set VO_sharpen=-filter_complex "hwupload,unsharp_opencl=lx=3:ly=3:la=1.5:cx=3:cy=3:ca=1.5,hwdownload,format=pix_fmts=yuv420p" >> "%vrdlog%" 2>&1
		REM set ff_cmd="!ffmpegexe64_OpenCL!" -hide_banner -v verbose -nostats !ff_OpenCL_device_init! !V_cut_start! -i "!scratch_file_qsf!" -vf "setdar=!V_DisplayAspectRatio_String_slash!" !V_cut_duration! !VO_sharpen! !VO_HQ! !AO_! -y "!destination_file!" >> "%vrdlog%" 2>&1
		set ff_cmd="!ffmpegexe64!" -hide_banner -v verbose -nostats !V_cut_start! -f vapoursynth -i "!_VPY_file!" -i "!scratch_file_qsf!" -map 0:v:0 -map 1:a:0 -vf "setdar=!V_DisplayAspectRatio_String_slash!" !V_cut_duration! !VO_HQ! !AO_! -y "!destination_file!" >> "%vrdlog%" 2>&1
	)
) ELSE (
	REM Interlaced video, deinterlacing required to play the result on chromecast devices
	REM run DGIndex
	ECHO DEL /F "!_DGI_file!" >> "%vrdlog%" 2>&1
	DEL /F "!_DGI_file!" >> "%vrdlog%" 2>&1
	ECHO "%VSdgindexNVexe64%" -i "!scratch_file_qsf!" -h -o "!_DGI_file!" -e >> "%vrdlog%" 2>&1
	set "start_date_time=!date! !time!"
	"%VSdgindexNVexe64%" -i "!scratch_file_qsf!" -h -o "!_DGI_file!" -e >> "%vrdlog%" 2>&1
	set "end_date_time=!date! !time!"
	powershell -NoLogo -ExecutionPolicy Unrestricted -Sta -NonInteractive -WindowStyle Minimized -File "!Path_to_py_VRDTVSP_Calculate_Duration!" -start_date_time "!start_date_time!" -end_date_time "!end_date_time!" -prefix_id "VSdgindexNVexe64" >> "!vrdlog!" 2>&1		
	REM ECHO TYPE "!_DGI_file!" >> "%vrdlog%" 2>&1
	REM TYPE "!_DGI_file!" >> "%vrdlog%" 2>&1
	REM ECHO DIR !scratch_Folder! >> "%vrdlog%" 2>&1
	REM DIR !scratch_Folder! >> "%vrdlog%" 2>&1
	ECHO TYPE "!_DGI_autolog!" >> "%vrdlog%" 2>&1
	TYPE "!_DGI_autolog!" >> "%vrdlog%" 2>&1
	ECHO DEL /F "!_DGI_autolog!" >> "%vrdlog%" 2>&1
	DEL /F "!_DGI_autolog!" >> "%vrdlog%" 2>&1
	IF /I "!Q_V_Codec_legacy!" == "AVC" (
		REM is interlaced h.264 - yes deinterlace, yes sharpen (more for mpeg2 source), higher quality
		ECHO "***FF*** " >> "%vrdlog%" 2>&1
		ECHO "***FF*** Interlaced AVC input - setting ff_cmd accordingly ... denoise/sharpen video stream via vapoursynth, convert audio stream " >> "%vrdlog%" 2>&1
		ECHO "***FF*** " >> "%vrdlog%" 2>&1
		REM Create the .vpy file with the .DGI as input
		ECHO DEL /F "!_VPY_file!" >> "%vrdlog%" 2>&1
		DEL /F "!_VPY_file!" >> "%vrdlog%" 2>&1
		ECHO import vapoursynth as vs		# this allows use of constants eg vs.YUV420P8 >> "!_VPY_file!" 2>&1
		ECHO from vapoursynth import core	# actual vapoursynth core >> "!_VPY_file!" 2>&1
		ECHO #import functools >> "!_VPY_file!" 2>&1
		ECHO #import mvsfunc as mvs			# this relies on the .py residing at the VS folder root level - see run_vsrepo.bat >> "!_VPY_file!" 2>&1
		ECHO #import havsfunc as haf		# this relies on the .py residing at the VS folder root level - see run_vsrepo.bat >> "!_VPY_file!" 2>&1
		ECHO core.std.LoadPlugin^(r'!vs_root!DGIndex\DGDecodeNV.dll'^) # do it like gonca https://forum.doom9.org/showthread.php?p=1877765#post1877765 >> "!_VPY_file!" 2>&1
		ECHO core.avs.LoadPlugin^(r'!vs_root!DGIndex\DGDecodeNV.dll'^) # do it like gonca https://forum.doom9.org/showthread.php?p=1877765#post1877765 >> "!_VPY_file!" 2>&1
		ECHO video = core.dgdecodenv.DGSource^(r'!_DGI_file!', deinterlace=!dg_deinterlace!, use_top_field=!dg_tff!, use_pf=False^) >> "!_VPY_file!" 2>&1
		ECHO # DGDecNV changes - >> "!_VPY_file!" 2>&1
		ECHO # 2020.10.21 Added new parameters cstrength and cblend to independently control the chroma denoising. >> "!_VPY_file!" 2>&1
		ECHO # 2020.11.07 Revised DGDenoise parameters. The 'chroma' option is removed. >> "!_VPY_file!" 2>&1
		ECHO #            Now, if 'strength' is set to 0.0 then luma denoising is disabled, >> "!_VPY_file!" 2>&1
		ECHO #            and if cstrength is set to 0.0 then chroma denoising is disabled. >> "!_VPY_file!" 2>&1
		ECHO #            'cstrength' is now defaulted to 0.0, and 'searchw' is defaulted to 9. >> "!_VPY_file!" 2>&1
		ECHO #video = core.avs.DGDenoise^(video, strength=0.15, cstrength=0.15^) # replaced chroma=True >> "!_VPY_file!" 2>&1
		ECHO #video = core.avs.DGDenoise^(video, strength=0.06, cstrength=0.06^) # replaced chroma=True >> "!_VPY_file!" 2>&1
		ECHO #video = core.avs.DGSharpen^(video, strength=0.3^) >> "!_VPY_file!" 2>&1
		ECHO #video = core.avs.DGSharpen^(video, strength=0.1^) >> "!_VPY_file!" 2>&1
		ECHO video = core.avs.DGSharpen^(video, strength=0.2^) >> "!_VPY_file!" 2>&1
		ECHO #video = vs.core.text.ClipInfo^(video^) >> "!_VPY_file!" 2>&1
		ECHO video.set_output^(^) >> "!_VPY_file!" 2>&1
		ECHO ---------------------------- >> "%vrdlog%" 2>&1
		ECHO TYPE "!_VPY_file!" >> "%vrdlog%" 2>&1
		TYPE "!_VPY_file!" >> "%vrdlog%" 2>&1
		ECHO ---------------------------- >> "%vrdlog%" 2>&1
		REM perhaps -cq:v 24 -qmin 18 -qmax 40
		REM set VO_deint_sharpen=-filter_complex "[0:v]yadif=!yadif_mode!:!yadif_tff_bff!:0,hwupload,unsharp_opencl=lx=3:ly=3:la=0.5:cx=3:cy=3:ca=0.5,hwdownload,format=pix_fmts=yuv420p" >> "%vrdlog%" 2>&1
		REM set VO_HQ=-vsync 0 -sws_flags lanczos+accurate_rnd+full_chroma_int+full_chroma_inp !VO_deint_sharpen! -strict experimental -c:v h264_nvenc -pix_fmt nv12 -preset p7 -multipass fullres !ffmpeg_RTX2060super_extra_flags! -rc:v vbr !x_cq_options! -b:v !FF_V_Target_BitRate! -minrate:v !FF_V_Target_Minimum_BitRate! -maxrate:v !FF_V_Target_Maximum_BitRate! -bufsize !FF_V_Target_BufSize! -profile:v high -level 5.2 -movflags +faststart+write_colr >> "%vrdlog%" 2>&1
		REM Handle an ffmpeg.exe with a removed Opencl
		REM set ff_cmd="!ffmpegexe64!" -hide_banner -v verbose -nostats !ff_OpenCL_device_init! !V_cut_start! -i "!scratch_file_qsf!" -vf "setdar=!V_DisplayAspectRatio_String_slash!" !V_cut_duration! !VO_HQ! !AO_! -y "!destination_file!" >> "%vrdlog%" 2>&1
		REM
		set VO_HQ_DG=-vsync 0 -sws_flags lanczos+accurate_rnd+full_chroma_int+full_chroma_inp -strict experimental -c:v h264_nvenc -pix_fmt nv12 -preset p7 -multipass fullres !ffmpeg_RTX2060super_extra_flags! -rc:v vbr !x_cq_options! -b:v !FF_V_Target_BitRate! -minrate:v !FF_V_Target_Minimum_BitRate! -maxrate:v !FF_V_Target_Maximum_BitRate! -bufsize !FF_V_Target_BufSize! -profile:v high -level 5.2 -movflags +faststart+write_colr >> "%vrdlog%" 2>&1
		REM Handle an ffmpeg.exe with a removed Opencl
		REM set ff_cmd_DG="!VSffmpegexe64_OpenCL!" -hide_banner -v verbose -nostats !ff_OpenCL_device_init! !V_cut_start! -f vapoursynth -i "!_VPY_file!" -i "!scratch_file_qsf!" -map 0:v:0 -map 1:a:0 -vf "setdar=!V_DisplayAspectRatio_String_slash!" !V_cut_duration! !VO_HQ_DG! !AO_! -y "!destination_file!" >> "%vrdlog%" 2>&1
		set ff_cmd_DG="!VSffmpegexe64!" -hide_banner -v verbose -nostats !V_cut_start! -f vapoursynth -i "!_VPY_file!" -i "!scratch_file_qsf!" -map 0:v:0 -map 1:a:0 -vf "setdar=!V_DisplayAspectRatio_String_slash!" !V_cut_duration! !VO_HQ_DG! !AO_! -y "!destination_file!" >> "%vrdlog%" 2>&1
		REM we use DG for deinterlacing
		set ff_cmd=!ff_cmd_DG!
		REM #####################################################################################################################
		REM Also setup a FOOTY ffmpeg commandline:
		REM Well, after all the mucking around for setting up for footy, it turns out it makes VERY LITTLE perceptual difference
		REM especially when the source is blocky (lime some footy games are only broadcast at 3.5Mbps which is pitiful.
		REM So, the code remains as an example, but never used.
		REM set Footy_VO_deint_sharpen=-filter_complex "[0:v]yadif=!Footy_yadif_mode!:!yadif_tff_bff!:0,hwupload,unsharp_opencl=lx=3:ly=3:la=0.5:cx=3:cy=3:ca=0.5,hwdownload,format=pix_fmts=yuv420p" >> "%vrdlog%" 2>&1
		REM set Footy_VO_HQ=-vsync 0 -sws_flags lanczos+accurate_rnd+full_chroma_int+full_chroma_inp !Footy_VO_deint_sharpen! -strict experimental -c:v h264_nvenc -pix_fmt nv12 -preset p7 -multipass fullres !ffmpeg_RTX2060super_extra_flags! -rc:v vbr !x_cq_options! -b:v !Footy_FF_V_Target_BitRate! -minrate:v !Footy_FF_V_Target_Minimum_BitRate! -maxrate:v !Footy_FF_V_Target_Maximum_BitRate! -bufsize !Footy_FF_V_Target_BufSize! -profile:v high -level 5.2 -movflags +faststart+write_colr >> "%vrdlog%" 2>&1
		REM set Footy_ff_cmd="!ffmpegexe64!" -hide_banner -v verbose -nostats !ff_OpenCL_device_init! !V_cut_start! -i "!scratch_file_qsf!" -vf "setdar=!V_DisplayAspectRatio_String_slash!" !V_cut_duration! !Footy_VO_HQ! !AO_! -y "!destination_file!" >> "%vrdlog%" 2>&1
		REM
		IF /I "!Footy_found!" == "TRUE" ( 
			ECHO "***FF*** " >> "%vrdlog%" 2>&1
			ECHO "***FF*** Interlaced FOOTY AVC input detected - resetting ff_cmd accordingly ... denoise/sharpen video stream via vapoursynth, with HQ settings, convert audio stream " >> "%vrdlog%" 2>&1
			ECHO "***FF*** " >> "%vrdlog%" 2>&1
			set Footy_VO_HQ_DG=-vsync 0 -sws_flags lanczos+accurate_rnd+full_chroma_int+full_chroma_inp -strict experimental -c:v h264_nvenc -pix_fmt nv12 -preset p7 -multipass fullres !ffmpeg_RTX2060super_extra_flags! -rc:v vbr !x_cq_options! -b:v !Footy_FF_V_Target_BitRate! -minrate:v !Footy_FF_V_Target_Minimum_BitRate! -maxrate:v !Footy_FF_V_Target_Maximum_BitRate! -bufsize !Footy_FF_V_Target_BufSize! -profile:v high -level 5.2 -movflags +faststart+write_colr >> "%vrdlog%" 2>&1
			REM Handle an ffmpeg.exe with a removed Opencl
			REM set Footy_ff_cmd_DG="!VSffmpegexe64_OpenCL!" -hide_banner -v verbose -nostats !ff_OpenCL_device_init! !V_cut_start! -f vapoursynth -i "!_VPY_file!" -i "!scratch_file_qsf!" -map 0:v:0 -map 1:a:0 -vf "setdar=!V_DisplayAspectRatio_String_slash!" !V_cut_duration! !Footy_VO_HQ_DG! !AO_! -y "!destination_file!" >> "%vrdlog%" 2>&1
			set Footy_ff_cmd_DG="!VSffmpegexe64!" -hide_banner -v verbose -nostats !V_cut_start! -f vapoursynth -i "!_VPY_file!" -i "!scratch_file_qsf!" -map 0:v:0 -map 1:a:0 -vf "setdar=!V_DisplayAspectRatio_String_slash!" !V_cut_duration! !Footy_VO_HQ_DG! !AO_! -y "!destination_file!" >> "%vrdlog%" 2>&1
			set ff_cmd=!Footy_ff_cmd_DG!
		)
		REM #####################################################################################################################
	) ELSE (
		REM is interlaced mpeg2 - yes deinterlace, yes denoise, sharpen (more for mpeg2 source), moderate quality
		ECHO "***FF*** " >> "%vrdlog%" 2>&1
		ECHO "***FF*** Interlaced MPEG2 input - setting ff_cmd accordingly ... denoise/more-sharpen video stream via vapoursynth, convert audio stream " >> "%vrdlog%" 2>&1
		ECHO "***FF*** " >> "%vrdlog%" 2>&1
		REM Create the .vpy file with the .DGI as input
		ECHO DEL /F "!_VPY_file!" >> "%vrdlog%" 2>&1
		DEL /F "!_VPY_file!" >> "%vrdlog%" 2>&1
		ECHO import vapoursynth as vs		# this allows use of constants eg vs.YUV420P8 >> "!_VPY_file!" 2>&1
		ECHO from vapoursynth import core	# actual vapoursynth core >> "!_VPY_file!" 2>&1
		ECHO #import functools >> "!_VPY_file!" 2>&1
		ECHO #import mvsfunc as mvs			# this relies on the .py residing at the VS folder root level - see run_vsrepo.bat >> "!_VPY_file!" 2>&1
		ECHO #import havsfunc as haf		# this relies on the .py residing at the VS folder root level - see run_vsrepo.bat >> "!_VPY_file!" 2>&1
		ECHO core.std.LoadPlugin^(r'!vs_root!DGIndex\DGDecodeNV.dll'^) # do it like gonca https://forum.doom9.org/showthread.php?p=1877765#post1877765 >> "!_VPY_file!" 2>&1
		ECHO core.avs.LoadPlugin^(r'!vs_root!DGIndex\DGDecodeNV.dll'^) # do it like gonca https://forum.doom9.org/showthread.php?p=1877765#post1877765 >> "!_VPY_file!" 2>&1
		ECHO video = core.dgdecodenv.DGSource^(r'!_DGI_file!', deinterlace=!dg_deinterlace!, use_top_field=!dg_tff!, use_pf=False^) >> "!_VPY_file!" 2>&1
		ECHO # DGDecNV changes - >> "!_VPY_file!" 2>&1
		ECHO # 2020.10.21 Added new parameters cstrength and cblend to independently control the chroma denoising. >> "!_VPY_file!" 2>&1
		ECHO # 2020.11.07 Revised DGDenoise parameters. The 'chroma' option is removed. >> "!_VPY_file!" 2>&1
		ECHO #            Now, if 'strength' is set to 0.0 then luma denoising is disabled, >> "!_VPY_file!" 2>&1
		ECHO #            and if cstrength is set to 0.0 then chroma denoising is disabled. >> "!_VPY_file!" 2>&1
		ECHO #            'cstrength' is now defaulted to 0.0, and 'searchw' is defaulted to 9. >> "!_VPY_file!" 2>&1
		ECHO #video = core.avs.DGDenoise^(video, strength=0.15, cstrength=0.15^) # replaced chroma=True >> "!_VPY_file!" 2>&1
		ECHO video = core.avs.DGDenoise^(video, strength=0.06, cstrength=0.06^) # replaced chroma=True >> "!_VPY_file!" 2>&1
		ECHO video = core.avs.DGSharpen^(video, strength=0.3^) >> "!_VPY_file!" 2>&1
		ECHO #video = core.avs.DGSharpen^(video, strength=0.1^) >> "!_VPY_file!" 2>&1
		ECHO #video = core.avs.DGSharpen^(video, strength=0.2^) >> "!_VPY_file!" 2>&1
		ECHO #video = vs.core.text.ClipInfo^(video^) >> "!_VPY_file!" 2>&1
		ECHO video.set_output^(^) >> "!_VPY_file!" 2>&1
		ECHO ---------------------------- >> "%vrdlog%" 2>&1
		ECHO TYPE "!_VPY_file!" >> "%vrdlog%" 2>&1
		TYPE "!_VPY_file!" >> "%vrdlog%" 2>&1
		ECHO ---------------------------- >> "%vrdlog%" 2>&1
		REM from mpeg2, always -cq:v 0
		REM set VO_deint_sharpen=-filter_complex "[0:v]yadif=!yadif_mode!:!yadif_tff_bff!:0,hwupload,unsharp_opencl=lx=3:ly=3:la=1.5:cx=3:cy=3:ca=1.5,hwdownload,format=pix_fmts=yuv420p" >> "%vrdlog%" 2>&1
		REM set VO_HQ=-vsync 0 -sws_flags lanczos+accurate_rnd+full_chroma_int+full_chroma_inp !VO_deint_sharpen! -strict experimental -c:v h264_nvenc -pix_fmt nv12 -preset p7 -multipass fullres !ffmpeg_RTX2060super_extra_flags! -rc:v vbr -cq:v 0 -b:v !FF_V_Target_BitRate! -minrate:v !FF_V_Target_Minimum_BitRate! -maxrate:v !FF_V_Target_Maximum_BitRate! -bufsize !FF_V_Target_BufSize! -profile:v high -level 5.2 -movflags +faststart+write_colr >> "%vrdlog%" 2>&1
		REM set ff_cmd="!ffmpegexe64!" -hide_banner -v verbose -nostats !ff_OpenCL_device_init! !V_cut_start! -i "!scratch_file_qsf!" -vf "setdar=!V_DisplayAspectRatio_String_slash!" !V_cut_duration! !VO_HQ! !AO_! -y "!destination_file!" >> "%vrdlog%" 2>&1
		REM
		set VO_HQ_DG=-vsync 0 -sws_flags lanczos+accurate_rnd+full_chroma_int+full_chroma_inp -strict experimental -c:v h264_nvenc -pix_fmt nv12 -preset p7 -multipass fullres !ffmpeg_RTX2060super_extra_flags! -rc:v vbr !x_cq_options! -b:v !FF_V_Target_BitRate! -minrate:v !FF_V_Target_Minimum_BitRate! -maxrate:v !FF_V_Target_Maximum_BitRate! -bufsize !FF_V_Target_BufSize! -profile:v high -level 5.2 -movflags +faststart+write_colr >> "%vrdlog%" 2>&1
		REM Handle an ffmpeg.exe with a removed Opencl
		REM set ff_cmd_DG="!VSffmpegexe64_OpenCL!" -hide_banner -v verbose -nostats !ff_OpenCL_device_init! !V_cut_start! -f vapoursynth -i "!_VPY_file!" -i "!scratch_file_qsf!" -map 0:v:0 -map 1:a:0 -vf "setdar=!V_DisplayAspectRatio_String_slash!" !V_cut_duration! !VO_HQ_DG! !AO_! -y "!destination_file!" >> "%vrdlog%" 2>&1
		set ff_cmd_DG="!VSffmpegexe64!" -hide_banner -v verbose -nostats  !V_cut_start! -f vapoursynth -i "!_VPY_file!" -i "!scratch_file_qsf!" -map 0:v:0 -map 1:a:0 -vf "setdar=!V_DisplayAspectRatio_String_slash!" !V_cut_duration! !VO_HQ_DG! !AO_! -y "!destination_file!" >> "%vrdlog%" 2>&1
		REM we use DG for deinterlacing
		set ff_cmd=!ff_cmd_DG!
	)
)
ECHO !DATE! !TIME! >> "%vrdlog%" 2>&1
REM ECHO !DATE! !TIME! ffmpeg_RTX2060super_extra_flags="!ffmpeg_RTX2060super_extra_flags!">> "!vrdlog!" 2>&1
REM ECHO !DATE! !TIME! Video, Audio, FF options follow: >> "%vrdlog%" 2>&1
REM set VO_ >> "%vrdlog%" 2>&1
REM set AO_ >> "%vrdlog%" 2>&1
REM set ff_ >> "%vrdlog%" 2>&1
ECHO !DATE! !TIME! >> "%vrdlog%" 2>&1
REM +++++++++++++++++++++++++
ECHO !DATE! !TIME! +++++++++++++++++++++++++ >> "%vrdlog%" 2>&1
ECHO !DATE! !TIME! +++++++++++++++++++++++++ >> "%vrdlog%" 2>&1
ECHO !DATE! !TIME! +++++++++++++++++++++++++ >> "%vrdlog%" 2>&1
ECHO !DATE! !TIME! +++++++++++++++++++++++++ >> "%vrdlog%" 2>&1
ECHO !DATE! !TIME! !ff_cmd! >> "%vrdlog%" 2>&1
set "ff_start_date_time=!date! !time!"
!ff_cmd! >> "%vrdlog%" 2>&1
SET EL=!ERRORLEVEL!
set "ff_end_date_time=!date! !time!"
powershell -NoLogo -ExecutionPolicy Unrestricted -Sta -NonInteractive -WindowStyle Minimized -File "!Path_to_py_VRDTVSP_Calculate_Duration!" -start_date_time "!ff_start_date_time!" -end_date_time "!ff_end_date_time!" -prefix_id ":::::::::: ff" >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! +++++++++++++++++++++++++ >> "%vrdlog%" 2>&1
ECHO !DATE! !TIME! +++++++++++++++++++++++++ >> "%vrdlog%" 2>&1
ECHO !DATE! !TIME! +++++++++++++++++++++++++ >> "%vrdlog%" 2>&1
ECHO !DATE! !TIME! +++++++++++++++++++++++++ >> "%vrdlog%" 2>&1
REM
REM if NOT exist "!destination_file!" ( 
IF /I "!EL!" NEQ "0" (
	ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! File failed to Convert by FFMPEG" %~f1" >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! Moving "%~f1" to "!failed_conversion_TS_Folder!" >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
	ECHO MOVE /Y "%~f1" "!failed_conversion_TS_Folder!" >> "%vrdlog%" 2>&1
	MOVE /Y "%~f1" "!failed_conversion_TS_Folder!" >> "%vrdlog%" 2>&1
	ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
	goto :eof
)
ECHO !DATE! !TIME! >> "%vrdlog%" 2>&1
ECHO DEL /F "!scratch_file_qsf!" >> "!vrdlog!" 2>&1
DEL /F "!scratch_file_qsf!" >> "!vrdlog!" 2>&1
ECHO DEL /F "!_DGI_file!" >> "%vrdlog%" 2>&1
DEL /F "!_DGI_file!" >> "%vrdlog%" 2>&1
ECHO DEL /F "!_VPY_file!" >> "%vrdlog%" 2>&1
DEL /F "!_VPY_file!" >> "%vrdlog%" 2>&1
ECHO !DATE! !TIME! >> "%vrdlog%" 2>&1
REM
goto :do_finalization
:after_do_ffmpeg_conversion
REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM
:do_VRD_conversion
REM
REM do it via VRD (doesn't work, CRF is broken with nvenc encoding)
REM note no "/QSF" in the conversion
REM The VRD profiles use SAS (same as source) resolution
REM Default to deinterlace if not explicitly marked as progressive
REM Default to higher CRF quality if AVC input (otherwise is likely to be old mpeg2)
REM Create 4 new specific profiles for Conversion:
REM		VRDTVS-to-h264-CRF20-aac
REM		VRDTVS-to-h264-CRF22-aac
REM		VRDTVS-to-h264-CRF24-aac
REM		VRDTVS-to-h264-SmartDeint-CRF20-aac
REM		VRDTVS-to-h264-SmartDeint-CRF22-aac
REM		VRDTVS-to-h264-SmartDeint-CRF24-aac
REM
REM +++++++++++++++++++++++++
set AO_=-c:a libfdk_aac -cutoff 20000 -ab 256k -ar 48000
REM +++++++++++++++++++++++++
IF /I "!V_ScanType!" == "Progressive" (
	IF /I "!Q_V_Codec_legacy!" == "AVC" (
		REM no deinterlace
		set "VRDTVSP_conversion_profile=VRDTVS-to-h264-CRF24-aac"
		REM set ff_cmd_vrd="!ffmpegexe64!" -v verbose -nostats -i "!scratch_file_qsf!" -c:v copy !AO_! -y "!destination_file!"
		REM Perhaps - instead, copy video stream using ffmpeg even though this is VRD ??
		REM ECHO !ff_cmd_vrd!  >> "%vrdlog%" 2>&1
		REM !ff_cmd_vrd!  >> "%vrdlog%" 2>&1
	) ELSE (
		REM no deinterlace, moderate quality
		set "VRDTVSP_conversion_profile=VRDTVS-to-h264-CRF28-aac"
	)
) ELSE (
	IF /I "!Q_V_Codec_legacy!" == "AVC" (
		REM yes deinterlace, higher quality
		set "VRDTVSP_conversion_profile=VRDTVS-to-h264-SmartDeint-CRF24-aac"
	) ELSE (
		REM yes deinterlace, moderate quality
		set "VRDTVSP_conversion_profile=VRDTVS-to-h264-SmartDeint-CRF28-aac"
	)
)
ECHO !DATE! !TIME! >> "%vrdlog%" 2>&1
set VRDTVSP_conversion_profile >> "%vrdlog%" 2>&1
ECHO !DATE! !TIME! >> "%vrdlog%" 2>&1
ECHO cscript //Nologo "!Path_to_vrd_vp_vbs!" "!scratch_file_qsf!" "!destination_file!" /p %VRDTVSP_conversion_profile% /q /na >> "%vrdlog%" 2>&1
REM  cscript //Nologo "!Path_to_vrd_vp_vbs!" "!scratch_file_qsf!" "!destination_file!" /p %VRDTVSP_conversion_profile% /q /na >> "%vrdlog%" 2>&1
if NOT exist "!destination_file!" ( 
	ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! File failed to Convert by VRD "%~f1" >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! Moving "%~f1" to "!failed_conversion_TS_Folder!" >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
	ECHO MOVE /Y "%~f1" "!failed_conversion_TS_Folder!" >> "%vrdlog%" 2>&1
	MOVE /Y "%~f1" "!failed_conversion_TS_Folder!" >> "%vrdlog%" 2>&1
	ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
	goto :eof
)
ECHO !DATE! !TIME! >> "%vrdlog%" 2>&1
REM
goto :do_finalization
:after_do_VRD_conversion
REM
REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM
:do_finalization
REM
REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM If it gets to here then the conversion has been successful.
REM
ECHO DEL /F "!scratch_file_qsf!"  >> "!vrdlog!" 2>&1
DEL /F "!scratch_file_qsf!"  >> "!vrdlog!" 2>&1
CALL :get_mediainfo_parameter_legacy "Video" "Codec" "D_V_Codec_legacy" "!destination_file!"
CALL :get_mediainfo_parameter "Video" "ScanType" "D_V_ScanType" "!destination_file!" 
IF /I "!D_V_ScanType!" == "" (
	ECHO !DATE! !TIME! "D_V_ScanType blank, setting D_V_ScanType=Progressive" >> "!vrdlog!" 2>&1
	set "D_V_ScanType=Progressive"
)
CALL :get_mediainfo_parameter "Video" "ScanOrder" "D_V_ScanOrder" "!destination_file!" 
IF /I "!Q_V_ScanOrder!" == "" (
	ECHO !DATE! !TIME! "D_V_ScanOrder blank, setting D_V_ScanOrder=TFF" >> "!vrdlog!" 2>&1
	set "Q_V_ScanOrder=TFF"
)
CALL :get_mediainfo_parameter "Video" "BitRate" "D_V_BitRate" "!destination_file!" 
CALL :get_mediainfo_parameter "Video" "BitRate/String" "D_V_BitRate_String" "!destination_file!"  
CALL :get_mediainfo_parameter "Video" "BitRate_Minimum" "D_V_BitRate_Minimum" "!destination_file!"  
CALL :get_mediainfo_parameter "Video" "BitRate_Minimum/String" "D_V_BitRate_Minimum_String" "!destination_file!"  
CALL :get_mediainfo_parameter "Video" "BitRate_Maximum" "D_V_BitRate_Maximum" "!destination_file!" 
CALL :get_mediainfo_parameter "Video" "BitRate_Maximum/String" "D_V_BitRate_Maximum_String" "!destination_file!"  
CALL :get_mediainfo_parameter "Video" "BufferSize" "D_V_BufferSize" "!destination_file!" 
CALL :get_mediainfo_parameter "Video" "Width" "D_V_Width" "!destination_file!" 
CALL :get_mediainfo_parameter "Video" "Height" "D_V_Height" "!destination_file!" 
CALL :get_mediainfo_parameter "Video" "DisplayAspectRatio" "D_V_DisplayAspectRatio" "!destination_file!"
set "D_V_DisplayAspectRatio_String_slash=!D_V_DisplayAspectRatio_String::=/!"
set "D_V_DisplayAspectRatio_String_slash=!D_V_DisplayAspectRatio_String_slash:\=/!"
CALL :get_mediainfo_parameter "Video" "DisplayAspectRatio/String" "D_V_DisplayAspectRatio_String" "!destination_file!"
CALL :get_mediainfo_parameter "Video" "PixelAspectRatio" "D_V_PixelAspectRatio" "!destination_file!"
CALL :get_mediainfo_parameter "Video" "PixelAspectRatio/String" "D_V_PixelAspectRatio_String" "!destination_file!"
CALL :get_mediainfo_parameter "Audio" "Video_Delay" "D_A_Video_Delay_ms" "!destination_file!" 
IF /I "!D_A_Video_Delay_ms!" == "" (
	set /a D_A_Audio_Delay_ms=0
) ELSE (
	set /a D_A_Audio_Delay_ms=0 - !D_A_Video_Delay_ms!
)
ECHO !DATE! !TIME! "D_A_Video_Delay_ms=!D_A_Video_Delay_ms!" >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! "D_A_Audio_Delay_ms=!D_A_Audio_Delay_ms!" Calculated >> "!vrdlog!" 2>&1
REM
CALL :get_ffprobe_video_stream_parameter "codec_name" "D_V_CodecID_FF" "!destination_file!" 
CALL :get_ffprobe_video_stream_parameter "codec_tag_String" "D_V_CodecID_String_FF" "!destination_file!" 
CALL :get_ffprobe_video_stream_parameter "width" "D_V_Width_FF" "!destination_file!" 
CALL :get_ffprobe_video_stream_parameter "height" "D_V_Height_FF" "!destination_file!" 
CALL :get_ffprobe_video_stream_parameter "duration" "D_V_Duration_s_FF" "!destination_file!" 
CALL :get_ffprobe_video_stream_parameter "bit_rate" "D_V_BitRate_FF" "!destination_file!" 
CALL :get_ffprobe_video_stream_parameter "max_bit_rate" "D_V_BitRate_Maximum_FF" "!destination_file!" 
CALL :get_mediainfo_parameter_legacy "Audio" "Codec" "D_A_Codec_legacy" "!destination_file!" 
CALL :get_mediainfo_parameter_legacy "Audio" "Video_Delay" "D_A_Video_Delay_ms_legacy" "!destination_file!" 
IF /I "!D_A_Video_Delay_ms_legacy!" == "" (
	set /a "D_A_Audio_Delay_ms_legacy=0"
) ELSE (
	set /a "D_A_Audio_Delay_ms_legacy=0 - !D_A_Video_Delay_ms_legacy!"
)
ECHO !DATE! !TIME! "D_A_Video_Delay_ms_legacy=!D_A_Video_Delay_ms_legacy!" >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! "D_A_Audio_Delay_ms_legacy=!D_A_Audio_Delay_ms_legacy!" Calculated >> "!vrdlog!" 2>&1
REM
DIR /4 "!destination_file!" 
ECHO DIR /4 "!destination_file!" >> "!vrdlog!" 2>&1
DIR /4 "!destination_file!" >> "!vrdlog!" 2>&1
REM ECHO "!mediainfoexe64!" --Full "!destination_file!" to "%~f1.CONVERTED.mediainfo.txt" >> "!vrdlog!" 2>&1
REM ECHO !DATE! !TIME! "!mediainfoexe64!" --Full "!destination_file!" >> "!vrdlog!" 2>&1
REM "!mediainfoexe64!" --Full "!destination_file!" >> "%vrdlog%" 2>&1
ECHO !DATE! !TIME! ====================================================================================================================================================== >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! output converted file: D_Video Codec: "!D_V_Codec_legacy!" D_ScanType: "!D_V_ScanType!" D_ScanOrder: "!D_V_ScanOrder!" !D_V_Width!x!D_V_Height! dar=!D_V_DisplayAspectRatio_String! sar=!D_V_PixelAspectRatio! D_Audio Codec: "!D_A_Codec_legacy!" D_Audio_Delay_ms: !D_A_Audio_Delay_ms! D_Audio_Delay_ms_legacy: !D_A_Video_Delay_ms_legacy! >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! End Conversion of "%~f1" / "!scratch_file_qsf!" >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! ====================================================================================================================================================== >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! Successfully Converted "%~f1" to "!destination_file!" >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! Moving "%~f1" to "!done_TS_Folder!" >> "!vrdlog!" 2>&1
ECHO MOVE /Y "%~f1" "!done_TS_Folder!" >> "%vrdlog%" 2>&1
MOVE /Y "%~f1" "!done_TS_Folder!" >> "%vrdlog%" 2>&1
ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
REM
goto :eof






REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM
:set_vrd_qsf_paths
REM setup VRD paths based in parameter p1 = 5 or 6 only
set "requested_vrd_version=%~1"
REM echo IN set_vrd_qsf_paths default_qsf_timeout_minutes_VRD5=!default_qsf_timeout_minutes_VRD5!   default_qsf_timeout_seconds_VRD5=!default_qsf_timeout_seconds_VRD5! >> "!vrdlog!" 2>&1
REM echo IN set_vrd_qsf_paths default_qsf_timeout_minutes_VRD6=!default_qsf_timeout_minutes_VRD6!   default_qsf_timeout_seconds_VRD6=!default_qsf_timeout_seconds_VRD6! >> "!vrdlog!" 2>&1
set "Path_to_vrd="
set "Path_to_vrd_vp_vbs="
set "profile_name_for_qsf_mpeg2="
set "profile_name_for_qsf_h264="
set "profile_name_for_qsf_h265="
IF /I "!requested_vrd_version!" == "6" (
   set "Path_to_vrd=!Path_to_vrd6!"
   set "Path_to_vrd_vp_vbs=!Path_to_vp_vbs_vrd6!"
   set "profile_name_for_qsf_mpeg2=!profile_name_for_qsf_mpeg2_vrd6!"
   set "profile_name_for_qsf_h264=!profile_name_for_qsf_h264_vrd6!"
   set "profile_name_for_qsf_h265=!profile_name_for_qsf_h265_vrd6!"
   set "_vrd_version_primary=6"
   set "_vrd_version_fallback=5"
   set "_vrd_qsf_timeout_minutes=!default_qsf_timeout_minutes_VRD6!"
   set "_vrd_qsf_timeout_seconds=!default_qsf_timeout_seconds_VRD6!"
) ELSE IF /I "!requested_vrd_version!" == "5" (
   set "Path_to_vrd=!Path_to_vrd5!"
   set "Path_to_vrd_vp_vbs=!Path_to_vp_vbs_vrd5!"
   set "profile_name_for_qsf_mpeg2=!profile_name_for_qsf_mpeg2_vrd5!"
   set "profile_name_for_qsf_h264=!profile_name_for_qsf_h264_vrd5!"
   set "profile_name_for_qsf_h265=!profile_name_for_qsf_h265_vrd5!"
   set "_vrd_version_primary=5"
   set "_vrd_version_fallback=6"
   set "_vrd_qsf_timeout_minutes=!default_qsf_timeout_minutes_VRD5!"
   set "_vrd_qsf_timeout_seconds=!default_qsf_timeout_seconds_VRD5!"
) ELSE (
   ECHO "VRD Version must be set to 5 or 6 not '!requested_vrd_version!' (_vrd_version_primary=!_vrd_version_primary! _vrd_version_fallback=!_vrd_version_fallback!)... EXITING" >> "!vrdlog!" 2>&1
   !xPAUSE!
   exit
)
REM echo EXITING set_vrd_qsf_paths _vrd_qsf_timeout_minutes=!_vrd_qsf_timeout_minutes!   _vrd_qsf_timeout_seconds=!_vrd_qsf_timeout_seconds! >> "!vrdlog!" 2>&1
goto :eof


REM ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM
:run_cscript_qsf_with_timeout 
REM Input Parameters 
REM 	1	VideoReDo version number to use
REM		2 	fully qualified filename of the SRC input (usually a .TS file)
REM 	3	fully qualified filename of name of QSF file to create
REM		4	qsf prefix for variables output from the VideoReDo QSF 
REM RETURN Parameters 
REM		QSF_ parameters from  :gather_variables_from_media_file
REM		!check_QSF_failed! is non-blank if we abort
REM Expected preset variables
REM		SRC_ variables
REM		calculated variables SRC_calc_
REM 	Fudged "!SRC_MI_V_BitRate!"
REM 	temp_cmd_file
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

REM echo IN run_cscript_qsf_with_timeout  >> "!vrdlog!" 2>&1
REM echo 1 "%~1"	VideoReDo version number to use >> "!vrdlog!" 2>&1
REM echo 2 "%~2"	fully qualified filename of the SRC input usually a .TS file >> "!vrdlog!" 2>&1
REM echo 3 "%~3"	fully qualified filename of name of QSF file to create >> "!vrdlog!" 2>&1
REM echo 4 "%~4"	qsf prefix for variables output from the VideoReDo QSF  >> "!vrdlog!" 2>&1

CALL :get_date_time_String "start_date_time_QSF_with_timeout"

set "requested_vrd_version=%~1"
set "source_filename=%~f2"
set "qsf_filename=%~f3"
set "requested_qsf_xml_prefix=%~4"

REM Preset the error flag to nothing
set "check_QSF_failed="

REM Reset VRD QSF defaults to the requested version. Note _vrd_version_primary and _vrd_version_fallback.
echo CALL :set_vrd_qsf_paths "!requested_vrd_version!" >> "!vrdlog!" 2>&1
CALL :set_vrd_qsf_paths "!requested_vrd_version!"

REM echo ???????????????????????????????????????????????????????????????? >> "!vrdlog!" 2>&1
REM echo QSF cscript timeout _vrd_qsf_timeout_seconds is !_vrd_qsf_timeout_seconds! seconds ..." >> "!vrdlog!" 2>&1
REM echo QSF VBS     timeout _vrd_qsf_timeout_minutes is !_vrd_qsf_timeout_minutes! minutes ..." >> "!vrdlog!" 2>&1
REM echo "_vrd_version_primary=!_vrd_version_primary!" >> "!vrdlog!" 2>&1
REM echo "_vrd_version_fallback=!_vrd_version_fallback!" >> "!vrdlog!" 2>&1
REM echo ???????????????????????????????????????????????????????????????? >> "!vrdlog!" 2>&1

REM Immediately choose the filename extension base on SRC_ variables and variables set by :set_vrd_qsf_paths
IF /I "!SRC_calc_Video_Encoding!" == "AVC" (
	set "qsf_profile=!profile_name_for_qsf_h264!"
	set "qsf_extension=!extension_h264!"
) ELSE IF /I "!SRC_calc_Video_Encoding!" == "MPEG2" (
	set "qsf_profile=!profile_name_for_qsf_mpeg2!"
	set "qsf_extension=!extension_mpeg2!"
) ELSE (
	set "check_QSF_failed********* ERROR: mediainfo format !SRC_calc_Video_Encoding! neither 'AVC' nor 'MPEG2' for !source_filename!"
	echo !DATE! !TIME! !check_QSF_failed! >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! *********  Declaring as FAILED: "%~f2" >> "%vrdlog%" 2>&1
	ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
	goto :eof
)
REM echo "SRC_calc_Video_Encoding=!SRC_calc_Video_Encoding!" >> "!vrdlog!" 2>&1
REM echo "SRC_calc_Video_Interlacement=!SRC_calc_Video_Interlacement!" >> "!vrdlog!" 2>&1
REM echo "SRC_calc_Video_FieldFirst=!SRC_calc_Video_FieldFirst!" >> "!vrdlog!" 2>&1
REM echo "requested_vrd_version=!requested_vrd_version!" >> "!vrdlog!" 2>&1
REM echo "_vrd_version_primary=!_vrd_version_primary!" >> "!vrdlog!" 2>&1
REM echo "_vrd_version_fallback=!_vrd_version_fallback!" >> "!vrdlog!" 2>&1
REM echo "_vrd_qsf_timeout_minutes=!_vrd_qsf_timeout_minutes!" >> "!vrdlog!" 2>&1
REM echo "_vrd_qsf_timeout_seconds=!_vrd_qsf_timeout_minutes!" >> "!vrdlog!" 2>&1
REM echo "qsf_profile=!qsf_profile!" >> "!vrdlog!" 2>&1
REM echo "qsf_extension=!qsf_extension!" >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! ====================================================================================================================================================== >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! Start QSF of file: "!source_filename!" >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! Input: Video Codec: '!SRC_FF_V_codec_name!' ScanType: '!SRC_calc_Video_Interlacement!' ScanOrder: '!SRC_calc_Video_FieldFirst!' WxH: !SRC_MI_V_Width!x!SRC_MI_V_HEIGHT! dar:'!SRC_FF_V_display_aspect_ratio_slash!' and '!SRC_MI_V_DisplayAspectRatio_String_slash!' >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME!        Audio Codec: '!SRC_FF_A_codec_name!' Audio_Delay_ms: '!SRC_MI_A_Audio_Delay!' Video_Delay_ms: '!SRC_MI_A_Video_Delay!' Bitrate: !SRC_MI_V_BitRate! >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! _vrd_version_primary='!_vrd_version_primary!' _vrd_version_fallback=!_vrd_version_fallback!' qsf_profile=!qsf_profile!' qsf_extension='!qsf_extension!' >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! ====================================================================================================================================================== >> "!vrdlog!" 2>&1

REM Delete the QSF target and relevant log files before doing the QSF
ECHO DEL /F "!qsf_filename!"  >> "%vrdlog%" 2>&1
DEL /F "!qsf_filename!"  >> "%vrdlog%" 2>&1
ECHO DEL /F "!vrd5_logfiles!" >> "%vrdlog%" 2>&1
DEL /F "!vrd5_logfiles!" >> "%vrdlog%" 2>&1
ECHO DEL /F "!vrd6_logfiles!" >> "%vrdlog%" 2>&1
DEL /F "!vrd6_logfiles!" >> "%vrdlog%" 2>&1
ECHO DEL /F "!temp_cmd_file!" >> "!vrdlog!" 2>&1
DEL /F "!temp_cmd_file!" >> "!vrdlog!" 2>&1

REM CSCRIPT uses '_vrd_qsf_timeout_seconds' and VBS uses '_vrd_qsf_timeout_minutes' created by ':set_vrd_qsf_paths' 		also see https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/cscript
echo cscript //nologo /t:!_vrd_qsf_timeout_seconds! "!Path_to_vbs_VRDTVSP_Run_QSF_with_v5_or_v6!" "!_vrd_version_primary!" "!source_filename!" "!qsf_filename!" "!qsf_profile!" "!temp_cmd_file!" "!requested_qsf_xml_prefix!" "!SRC_MI_V_BitRate!" "!_vrd_qsf_timeout_minutes!" >> "!vrdlog!" 2>&1
cscript //nologo /t:!_vrd_qsf_timeout_seconds! "!Path_to_vbs_VRDTVSP_Run_QSF_with_v5_or_v6!" "!_vrd_version_primary!" "!source_filename!" "!qsf_filename!" "!qsf_profile!" "!temp_cmd_file!" "!requested_qsf_xml_prefix!" "!SRC_MI_V_BitRate!" "!_vrd_qsf_timeout_minutes!" >> "!vrdlog!" 2>&1
SET EL=!ERRORLEVEL!
IF /I "!EL!" NEQ "0" (
	set "check_QSF_failed=********* ERROR: QSF Error '!EL!' returned from cscript QSF"
	ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! !check_QSF_failed! >> "%vrdlog%" 2>&1
	ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
) ELSE if NOT exist "!qsf_filename!" ( 
	set "check_QSF_failed=********* ERROR: QSF Error QSF file not created: '!qsf_filename!'"
	ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! !check_QSF_failed! >> "%vrdlog%" 2>&1
	ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
) ELSE if NOT exist "!temp_cmd_file!" ( 
	set "check_QSF_failed=********* ERROR: QSF Error Temp cmd file not created: '!temp_cmd_file!'"
	ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! !check_QSF_failed! >> "%vrdlog%" 2>&1
	ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
)
IF /I NOT "!check_QSF_failed!" == "" (
	ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! Ensuring VideoReDo tasks are killed: >> "!vrdlog!" 2>&1
	ECHO tasklist /fo list /fi "IMAGENAME eq VideoReDo*" >> "!vrdlog!" 2>&1
	tasklist /fo list /fi "IMAGENAME eq VideoReDo*" >> "!vrdlog!" 2>&1
	ECHO taskkill /f /t /fi "IMAGENAME eq VideoReDo*" /im * >> "!vrdlog!" 2>&1
	taskkill /f /t /fi "IMAGENAME eq VideoReDo*" /im * >> "!vrdlog!" 2>&1
	ECHO tasklist /fo list /fi "IMAGENAME eq VideoReDo*" >> "!vrdlog!" 2>&1
	tasklist /fo list /fi "IMAGENAME eq VideoReDo*" >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! ********* FAILED:  "%~f1" >> "%vrdlog%" 2>&1
	ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
	goto :eof
)

REM If it got to here then the QSF worked. Run the .cmd file it created so we see the !requested_qsf_xml_prefix! variables created by the QSF
REM echo TYPE "!temp_cmd_file!" >> "!vrdlog!" 2>&1
REM TYPE "!temp_cmd_file!" >> "!vrdlog!" 2>&1
echo call "!temp_cmd_file!" >> "!vrdlog!" 2>&1
call "!temp_cmd_file!" >> "!vrdlog!" 2>&1
ECHO DEL /F "!temp_cmd_file!" >> "!vrdlog!" 2>&1
DEL /F "!temp_cmd_file!" >> "!vrdlog!" 2>&1
echo +++++++++ >> "!vrdlog!" 2>&1
echo set !requested_qsf_xml_prefix! >> "!vrdlog!" 2>&1
set !requested_qsf_xml_prefix! >> "!vrdlog!" 2>&1
echo +++++++++ >> "!vrdlog!" 2>&1

REM :gather_variables_from_media_file P2 =	the global prefix to use for this gather, one of "SRC_", "QSF_" "TARGET_"
CALL :gather_variables_from_media_file "!qsf_filename!" "QSF_" 

REM Reset VRD QSF defaults back to the original DEFAULT version. Note _vrd_version_primary and _vrd_version_fallback.
CALL :set_vrd_qsf_paths "!DEFAULT_vrd_version_primary!"

CALL :get_date_time_String "end_date_time_QSF_with_timeout"
REM echo "!py_exe!" "!Path_to_py_VRDTVSP_Calculate_Duration!" --start_datetime "!start_date_time_QSF_with_timeout!" --end_datetime "!end_date_time_QSF_with_timeout!" --prefix_id "run_cscript_qsf_with_timeout" >> "!vrdlog!" 2>&1
"!py_exe!" "!Path_to_py_VRDTVSP_Calculate_Duration!" --start_datetime "!start_date_time_QSF_with_timeout!" --end_datetime "!end_date_time_QSF_with_timeout!" --prefix_id "run_cscript_qsf_with_timeout" >> "!vrdlog!" 2>&1

goto :eof


REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM
:declare_FAILED
REM Input Parameters 
REM		1 	fully qualified filename of the SRC input which failed and must be moved to the FAILED folder
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
ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! ****** Moving "%~f1" to "!failed_conversion_TS_Folder!" >> "!vrdlog!" 2>&1
ECHO MOVE /Y "%~f1" "!failed_conversion_TS_Folder!" >> "%vrdlog%" 2>&1
MOVE /Y "%~f1" "!failed_conversion_TS_Folder!" >> "%vrdlog%" 2>&1
ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
REM remvove junk files leftover from QSF if it timed out or something
ECHO DEL /F !scratch_Folder!*.tmp >> "!vrdlog!" 2>&1
DEL /F !scratch_Folder!*.tmp >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
goto :eof


REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM
:LoCase
:: Subroutine to convert a variable VALUE to all lower case.
:: The argument for this subroutine is the variable NAME.
FOR %%i IN ("A=a" "B=b" "C=c" "D=d" "E=e" "F=f" "G=g" "H=h" "I=i" "J=j" "K=k" "L=l" "M=m" "N=n" "O=o" "P=p" "Q=q" "R=r" "S=s" "T=t" "U=u" "V=v" "W=w" "X=x" "Y=y" "Z=z") DO CALL set "%1=%%%1:%%~i%%"
goto :eof

:UpCase
:: Subroutine to convert a variable VALUE to all UPPER CASE.
:: The argument for this subroutine is the variable NAME.
FOR %%i IN ("a=A" "b=B" "c=C" "d=D" "e=E" "f=F" "g=G" "h=H" "i=I" "j=J" "k=K" "l=L" "m=M" "n=N" "o=O" "p=P" "q=Q" "r=R" "s=S" "t=T" "u=U" "v=V" "w=W" "x=X" "y=Y" "z=Z") DO CALL set "%1=%%%1:%%~i%%"
goto :eof

:TCase
:: Subroutine to convert a variable VALUE to Title Case.
:: The argument for this subroutine is the variable NAME.
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
REM echo 'cscript //nologo "!eval_formula_vbs_filename!" "!eval_formula!"'
for /f %%A in ('cscript //nologo "!eval_formula_vbs_filename!" "!eval_formula!"') do (
    set "!eval_variable_name!=%%A"
    set "eval_single_number_result=%%A"
)
DEL /F "!eval_formula_vbs_filename!" >NUL 2>&1
REM echo "eval_formula_vbs_filename=!eval_formula_vbs_filename!"
REM echo "eval_variable_name=!eval_variable_name! eval_formula=!eval_formula! eval_single_number_result=!eval_single_number_result!"
goto :eof

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
:remove_trailing_backslash_into_variable
REM remove trailing backslash from p1 "!source_TS_Folder!" into p2 "the_folder"
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

:make_double_backslashes_into_variable
REM double every backslash in p1 "!source_TS_Folder!" into p2 "the_folder"
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

REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
:clear_variables
echo FOR /F "tokens=1,* delims==" %%G IN ('SET SRC_') DO (set "%%G=") >> "!vrdlog!" 2>&1
FOR /F "tokens=1,* delims==" %%G IN ('SET SRC_') DO (set "%%G=")>NUL 2>&1

echo FOR /F "tokens=1,* delims==" %%G IN ('SET QSF_') DO (set "%%G=") >> "!vrdlog!" 2>&1
FOR /F "tokens=1,* delims==" %%G IN ('SET QSF_') DO (set "%%G=")>NUL 2>&1

echo FOR /F "tokens=1,* delims==" %%G IN ('SET TARGET') DO (set "%%G=") >> "!vrdlog!" 2>&1
FOR /F "tokens=1,* delims==" %%G IN ('SET TARGET_') DO (set "%%G=")>NUL 2>&1

echo FOR /F "tokens=1,* delims==" %%G IN ('SET FFMPEG_') DO (set "%%G=") >> "!vrdlog!" 2>&1
FOR /F "tokens=1,* delims==" %%G IN ('SET FFMPEG_') DO (set "%%G=")>NUL 2>&1

echo FOR /F "tokens=1,* delims==" %%G IN ('SET Footy_') DO (set "%%G=") >> "!vrdlog!" 2>&1
FOR /F "tokens=1,* delims==" %%G IN ('SET Footy_') DO (set "%%G=")>NUL 2>&1

goto :eof


REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM ---------------------------------------------------------------------------------------------------------------------------------------------------------

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
echo FOR /F "tokens=1,* delims==" %%G IN ('SET !derived_prefix_FF!') DO (set "%%G=") >> "!vrdlog!" 2>&1
FOR /F "tokens=1,* delims==" %%G IN ('SET !derived_prefix_FF!') DO (set "%%G=")>NUL 2>&1
echo "!py_exe!" "!Path_to_py_VRDTVSP_Set_ffprobe_Variables_for_first_stream_in_section!" --ffprobe_dos_variablename "ffprobeexe64" --mediafile "!media_filename!" --prefix "!derived_prefix_FF!" --output_cmd_file="!temp_cmd_file!" >> "!vrdlog!" 2>&1
"!py_exe!" "!Path_to_py_VRDTVSP_Set_ffprobe_Variables_for_first_stream_in_section!" --ffprobe_dos_variablename "ffprobeexe64" --mediafile "!media_filename!" --prefix "!derived_prefix_FF!" --output_cmd_file="!temp_cmd_file!" >> "!vrdlog!" 2>&1
SET EL=!ERRORLEVEL!
IF /I "!EL!" NEQ "0" (
   ECHO !DATE! !TIME! *********  ffprobe "!derived_prefix_FF!" Error !EL! returned from !Path_to_py_VRDTVSP_Set_Mediainfo_Variables_for_first_stream_in_section! >> "%vrdlog%" 2>&1
   ECHO !DATE! !TIME! *********  ABORTING ... >> "%vrdlog%" 2>&1
   !xPAUSE!
   EXIT !EL!
)
echo ### "!derived_prefix_FF!" >> "!vrdlog!" 2>&1
REM echo TYPE "!temp_cmd_file!" >> "!vrdlog!" 2>&1
REM TYPE "!temp_cmd_file!" >> "!vrdlog!" 2>&1
echo call "!temp_cmd_file!" >> "!vrdlog!" 2>&1
call "!temp_cmd_file!" >> "!vrdlog!" 2>&1
ECHO DEL /F "!temp_cmd_file!" >> "!vrdlog!" 2>&1
DEL /F "!temp_cmd_file!" >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! ====================================================================================================================================================== >> "!vrdlog!" 2>&1
ECHO DEL /F "!temp_cmd_file!" >> "!vrdlog!" 2>&1
DEL /F "!temp_cmd_file!" >> "!vrdlog!" 2>&1
echo FOR /F "tokens=1,* delims==" %%G IN ('SET !derived_prefix_MI!') DO (set "%%G=") >> "!vrdlog!" 2>&1
FOR /F "tokens=1,* delims==" %%G IN ('SET !derived_prefix_MI!') DO (set "%%G=")>NUL 2>&1
echo "!py_exe!" "!Path_to_py_VRDTVSP_Set_Mediainfo_Variables_for_first_stream_in_section!" --mediainfo_dos_variablename "mediainfoexe64" --mediafile "!media_filename!" --prefix "!derived_prefix_MI!" --output_cmd_file="!temp_cmd_file!" >> "!vrdlog!" 2>&1
"!py_exe!" "!Path_to_py_VRDTVSP_Set_Mediainfo_Variables_for_first_stream_in_section!" --mediainfo_dos_variablename "mediainfoexe64" --mediafile "!media_filename!" --prefix "!derived_prefix_MI!" --output_cmd_file="!temp_cmd_file!" >> "!vrdlog!" 2>&1
SET EL=!ERRORLEVEL!
IF /I "!EL!" NEQ "0" (
   ECHO !DATE! !TIME! *********  mediainfo "!derived_prefix_MI!" Error !EL! returned from !Path_to_py_VRDTVSP_Set_ffprobe_Variables_for_first_stream_in_section! >> "%vrdlog%" 2>&1
   ECHO !DATE! !TIME! *********  ABORTING ... >> "%vrdlog%" 2>&1
   !xPAUSE!
   EXIT !EL!
)
echo ### "!derived_prefix_MI!" >> "!vrdlog!" 2>&1
REM echo TYPE "!temp_cmd_file!" >> "!vrdlog!" 2>&1
REM TYPE "!temp_cmd_file!" >> "!vrdlog!" 2>&1
echo call "!temp_cmd_file!" >> "!vrdlog!" 2>&1
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
echo Fudge Check #1 !current_prefix!MI_V_BitRate '!tmp_MI_V_BitRate!' for blank ... >> "!vrdlog!" 2>&1
IF /I "!tmp_MI_V_BitRate!" == "" (
	echo set !current_prefix!MI_V_BitRate >> "!vrdlog!" 2>&1
	set !current_prefix!MI_V_BitRate >> "!vrdlog!" 2>&1
	echo set !current_prefix!MI_G_OverallBitRate >> "!vrdlog!" 2>&1
	set !current_prefix!MI_G_OverallBitRate >> "!vrdlog!" 2>&1
	echo set !current_prefix!FF_G_bit_rate >> "!vrdlog!" 2>&1
	set !current_prefix!FF_G_bit_rate >> "!vrdlog!" 2>&1
	echo WARNING: !current_prefix!MI_V_BitRate '!tmp_MI_V_BitRate!' was blank, attempting to fudge to !current_prefix!FF_G_bit_rate >> "!vrdlog!" 2>&1
	REM
	call set !current_prefix!MI_V_BitRate=%%!current_prefix!FF_G_bit_rate%%
)
call set tmp_MI_V_BitRate=%%!current_prefix!MI_V_BitRate%%
echo Fudge Check #2 !current_prefix!MI_V_BitRate '!tmp_MI_V_BitRate!' for blank ... >> "!vrdlog!" 2>&1
IF /I "!tmp_MI_V_BitRate!" == "" (
	echo set !current_prefix!MI_V_BitRate >> "!vrdlog!" 2>&1
	set !current_prefix!MI_V_BitRate >> "!vrdlog!" 2>&1
	echo set !current_prefix!MI_G_OverallBitRate >> "!vrdlog!" 2>&1
	set !current_prefix!MI_G_OverallBitRate >> "!vrdlog!" 2>&1
	echo set !current_prefix!FF_G_bit_rate >> "!vrdlog!" 2>&1
	set !current_prefix!FF_G_bit_rate >> "!vrdlog!" 2>&1
	echo WARNING: !current_prefix!MI_V_BitRate '!tmp_MI_V_BitRate!' was blank, attempting to fudge to !current_prefix!MI_G_OverallBitRate >> "!vrdlog!" 2>&1
	REM
	call set !current_prefix!MI_V_BitRate=%%!current_prefix!MI_G_OverallBitRate%%
)
call set tmp_MI_V_BitRate=%%!current_prefix!MI_V_BitRate%%
echo Fudge Check #3 !current_prefix!MI_V_BitRate '!tmp_MI_V_BitRate!' for blank ... >> "!vrdlog!" 2>&1
IF /I "!tmp_MI_V_BitRate!" == "" (
	echo set !current_prefix!MI_V_BitRate >> "!vrdlog!" 2>&1
	set !current_prefix!MI_V_BitRate >> "!vrdlog!" 2>&1
	echo set !current_prefix!MI_G_OverallBitRate >> "!vrdlog!" 2>&1
	set !current_prefix!MI_G_OverallBitRate >> "!vrdlog!" 2>&1
	echo set !current_prefix!FF_G_bit_rate >> "!vrdlog!" 2>&1
	set !current_prefix!FF_G_bit_rate >> "!vrdlog!" 2>&1
	echo ERROR: Unable to detect !current_prefix!MI_V_BitRate '!tmp_MI_V_BitRate!', failed to fudge it, Aborting >> "!vrdlog!" 2>&1
	exit 1
)

REM get a slash version of MI_V_DisplayAspectRatio_String
call set !current_prefix!MI_V_DisplayAspectRatio_String_slash=%%!current_prefix!MI_V_DisplayAspectRatio_String%%
call set !current_prefix!MI_V_DisplayAspectRatio_String_slash=%%!current_prefix!MI_V_DisplayAspectRatio_String_slash::=/%%
call set !current_prefix!MI_V_DisplayAspectRatio_String_slash=%%!current_prefix!MI_V_DisplayAspectRatio_String_slash::\=/%%
echo +++++++++ >> "!vrdlog!" 2>&1
echo set !current_prefix!MI_V_DisplayAspectRatio_String >> "!vrdlog!" 2>&1
set !current_prefix!MI_V_DisplayAspectRatio_String >> "!vrdlog!" 2>&1
echo +++++++++ >> "!vrdlog!" 2>&1

REM get a slash version of FF_V_display_aspect_ratio
call set !current_prefix!FF_V_display_aspect_ratio_slash=%%!current_prefix!FF_V_display_aspect_ratio%%
call set !current_prefix!FF_V_display_aspect_ratio_slash=%%!current_prefix!FF_V_display_aspect_ratio_slash::=/%%
call set !current_prefix!FF_V_display_aspect_ratio_slash=%%!current_prefix!FF_V_display_aspect_ratio_slash::\=/%%
echo +++++++++ >> "!vrdlog!" 2>&1
echo set !current_prefix!FF_V_display_aspect_ratio >> "!vrdlog!" 2>&1
set !current_prefix!FF_V_display_aspect_ratio >> "!vrdlog!" 2>&1
echo +++++++++ >> "!vrdlog!" 2>&1

REM calculate MI_A_Audio_Delay from MI_A_Video_Delay
REM MI_A_Video_Delay is reported by mediainfo as decimal seconds, not milliseconds, so up-convert it
call set tmp_MI_A_Video_Delay=%%!current_prefix!MI_A_Video_Delay%%
IF /I "!tmp_MI_A_Video_Delay!" == "" (set "tmp_MI_A_Video_Delay=0")
set "py_eval_string=int(1000.0 * !tmp_MI_A_Video_Delay!)"
CALL :calc_single_number_result_py "!py_eval_string!" "tmp_MI_A_Video_Delay"
set /a tmp_MI_A_Audio_Delay=0 - !tmp_MI_A_Video_Delay!
set "!current_prefix!MI_A_Video_Delay=!tmp_MI_A_Video_Delay!"
set "!current_prefix!MI_A_Audio_Delay=!tmp_MI_A_Audio_Delay!"
echo +++++++++ >> "!vrdlog!" 2>&1
echo set !current_prefix!MI_A_Video_Delay >> "!vrdlog!" 2>&1
set !current_prefix!MI_A_Video_Delay >> "!vrdlog!" 2>&1
echo set !current_prefix!MI_A_Audio_Delay >> "!vrdlog!" 2>&1
set !current_prefix!MI_A_Audio_Delay >> "!vrdlog!" 2>&1
echo +++++++++ >> "!vrdlog!" 2>&1

REM Determine which type of encoding, AVC or MPEG2
call set tmp_MI_V_Format=%%!current_prefix!MI_V_Format%%
call set tmp_FF_V_codec_name=%%!current_prefix!FF_V_codec_name%%
set "!current_prefix!calc_Video_Encoding=AVC"
IF /I "!tmp_MI_V_Format!" == "AVC"            (set "!current_prefix!calc_Video_Encoding=AVC")
IF /I "!tmp_FF_V_codec_name!" == "h264"       (set "!current_prefix!calc_Video_Encoding=AVC")
IF /I "!tmp_MI_V_Format!" == "MPEG_Video"     (set "!current_prefix!calc_Video_Encoding=MPEG2")
IF /I "!tmp_FF_V_codec_name!" == "mpeg2video" (set "!current_prefix!calc_Video_Encoding=MPEG2")
REM echo +++++++++ >> "!vrdlog!" 2>&1
REM echo set tmp_MI_V_Format >> "!vrdlog!" 2>&1
REM set tmp_MI_V_Format >> "!vrdlog!" 2>&1
REM echo +++++++++ >> "!vrdlog!" 2>&1
REM echo set tmp_FF_V_codec_name >> "!vrdlog!" 2>&1
REM set tmp_FF_V_codec_name >> "!vrdlog!" 2>&1
echo +++++++++ >> "!vrdlog!" 2>&1
echo set !current_prefix!calc_Video_Encoding >> "!vrdlog!" 2>&1
set !current_prefix!calc_Video_Encoding >> "!vrdlog!" 2>&1
echo +++++++++ >> "!vrdlog!" 2>&1

REM Determine whether PROGRESSIVE or INTERLACED
call set tmp_MI_V_ScanType=%%!current_prefix!MI_V_ScanType%%
call set tmp_FF_V_field_order=%%!current_prefix!FF_V_field_order%%
set "!current_prefix!calc_Video_Interlacement=PROGRESSIVE"
IF /I "!tmp_MI_V_ScanType!" == "MBAFF"          (set "!current_prefix!calc_Video_Interlacement=INTERLACED")
IF /I "!tmp_MI_V_ScanType!" == "Interlaced"     (set "!current_prefix!calc_Video_Interlacement=INTERLACED")
IF /I "!tmp_FF_V_field_order!" == "tt"          (set "!current_prefix!calc_Video_Interlacement=INTERLACED")
IF /I "!tmp_MI_V_ScanType!" == ""               (set "!current_prefix!calc_Video_Interlacement=PROGRESSIVE")
IF /I "!tmp_FF_V_field_order!" == "progressive" (set "!current_prefix!calc_Video_Interlacement=PROGRESSIVE")
REM echo +++++++++ >> "!vrdlog!" 2>&1
REM echo set tmp_MI_V_ScanType >> "!vrdlog!" 2>&1
REM set tmp_MI_V_ScanType >> "!vrdlog!" 2>&1
REM echo +++++++++ >> "!vrdlog!" 2>&1
REM echo set tmp_FF_V_field_order >> "!vrdlog!" 2>&1
REM set tmp_FF_V_field_order >> "!vrdlog!" 2>&1
echo +++++++++ >> "!vrdlog!" 2>&1
echo set !current_prefix!calc_Video_Interlacement >> "!vrdlog!" 2>&1
set !current_prefix!calc_Video_Interlacement >> "!vrdlog!" 2>&1
echo +++++++++ >> "!vrdlog!" 2>&1

REM Determine FIELD ORDER for interlaced
call set tmp_MI_V_ScanOrder=%%!current_prefix!MI_V_ScanOrder%%
set "!current_prefix!calc_Video_FieldFirst=TFF"
IF /I "!tmp_MI_V_ScanOrder!" == ""    (set "!current_prefix!calc_Video_FieldFirst=TFF")
IF /I "!tmp_MI_V_ScanOrder!" == "TFF" (set "!current_prefix!calc_Video_FieldFirst=TFF")
IF /I "!tmp_MI_V_ScanOrder!" == "BFF" (set "!current_prefix!calc_Video_FieldFirst=BFF")
REM echo +++++++++ >> "!vrdlog!" 2>&1
REM echo set tmp_MI_V_ScanOrder >> "!vrdlog!" 2>&1
REM set tmp_MI_V_ScanOrder >> "!vrdlog!" 2>&1
REM echo +++++++++ >> "!vrdlog!" 2>&1
echo set !current_prefix!calc_Video_FieldFirst >> "!vrdlog!" 2>&1
set !current_prefix!calc_Video_FieldFirst >> "!vrdlog!" 2>&1
echo +++++++++ >> "!vrdlog!" 2>&1

REM display all calculated variables
echo +++++++++ >> "!vrdlog!" 2>&1
echo display all calculated variables >> "!vrdlog!" 2>&1
echo set !current_prefix!calc >> "!vrdlog!" 2>&1
set !current_prefix!calc >> "!vrdlog!" 2>&1
echo +++++++++ >> "!vrdlog!" 2>&1

REM display calculated variables individually
echo +++++++++ >> "!vrdlog!" 2>&1
call set tmp_calc_Video_Encoding=%%!current_prefix!calc_Video_Encoding%%
call set tmp_calc_Video_Interlacement=%%!current_prefix!calc_Video_Interlacement%%
call set tmp_calc_Video_FieldFirst=%%!current_prefix!calc_Video_FieldFirst%%
ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! !current_prefix!calc_Video_Encoding=!tmp_calc_Video_Encoding! >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! !current_prefix!calc_Video_Interlacement=!tmp_calc_Video_Interlacement! >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! !current_prefix!calc_Video_FieldFirst=!tmp_calc_Video_FieldFirst! >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
echo +++++++++ >> "!vrdlog!" 2>&1

REM ECHO !DATE! !TIME! ====================================================================================================================================================== >> "!vrdlog!" 2>&1
REM ECHO !DATE! !TIME! List all  "!current_prefix!" variables for "!media_filename!" >> "!vrdlog!" 2>&1
REM ECHO set !current_prefix! >> "!vrdlog!" 2>&1
REM set !current_prefix! >> "!vrdlog!" 2>&1
REM ECHO !DATE! !TIME! ====================================================================================================================================================== >> "!vrdlog!" 2>&1

REM ECHO !DATE! !TIME! ====================================================================================================================================================== >> "!vrdlog!" 2>&1
REM echo "!mediainfoexe64!" "!media_filename!" --full >> "%vrdlog%" 2>&1
REM "!mediainfoexe64!" "!media_filename!" --full >> "%vrdlog%" 2>&1
REM ECHO !DATE! !TIME! ====================================================================================================================================================== >> "!vrdlog!" 2>&1
REM echo "!ffprobeexe64!" -v verbose -select_streams v:0 -show_entries stream -of default "!media_filename!" >> "%vrdlog%" 2>&1
REM "!ffprobeexe64!" -v verbose -select_streams v:0 -show_entries stream -of default "!media_filename!" >> "%vrdlog%" 2>&1
REM ECHO !DATE! !TIME! ====================================================================================================================================================== >> "!vrdlog!" 2>&1
REM echo "!ffprobeexe64!" -v verbose -select_streams a:0 -show_entries stream -of default "!media_filename!" >> "%vrdlog%" 2>&1
REM "!ffprobeexe64!" -v verbose -select_streams a:0 -show_entries stream -of default "!media_filename!" >> "%vrdlog%" 2>&1
REM ECHO !DATE! !TIME! ====================================================================================================================================================== >> "!vrdlog!" 2>&1

ECHO !DATE! !TIME! ====================================================================================================================================================== >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! End collecting :gather_variables_from_media_file "!current_prefix!" ffprobe and mediainfo variables ... "!media_filename!" >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! ====================================================================================================================================================== >> "!vrdlog!" 2>&1

CALL :get_date_time_String "gather_variables_from_media_file_END"
REM echo "!py_exe!" "!Path_to_py_VRDTVSP_Calculate_Duration!" --start_datetime "!gather_variables_from_media_file_START!" --end_datetime "!gather_variables_from_media_file_END!" --prefix_id "gather !current_prefix!" >> "!vrdlog!" 2>&1
"!py_exe!" "!Path_to_py_VRDTVSP_Calculate_Duration!" --start_datetime "!gather_variables_from_media_file_START!" --end_datetime "!gather_variables_from_media_file_END!" --prefix_id "gather !current_prefix!" >> "!vrdlog!" 2>&1

goto :eof
