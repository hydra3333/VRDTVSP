@ECHO OFF
@setlocal ENABLEDELAYEDEXPANSION
@setlocal enableextensions

REM --------- set whether pause statements take effect ----------------------------
SET "xPAUSE=REM"
REM set "xPAUSE=PAUSE"
REM --------- set whether pause statements take effect ----------------------------

ECHO !DATE! !TIME! --------- Start setup paths and exe filenames ---------------------------- >> "!vrdlog!" 2>&1
set "root=G:\HDTV\"
set "vs_root=C:\SOFTWARE\Vapoursynth-x64\"
set "destination_mp4_Folder=T:\HDTV\VRDTVSP-Converted\"
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
ECHO !DATE! !TIME! --------- Finish setup paths and exe filenames ---------------------------- >> "!vrdlog!" 2>&1

ECHO !DATE! !TIME! -- Start Header --------------------------------------------------------------------- >> "!vrdlog!" 2>&1
REM set header to date and time and computer name
CALL :get_header_String "header"
ECHO !DATE! !TIME! -- Finish Header --------------------------------------------------------------------- >> "!vrdlog!" 2>&1

ECHO !DATE! !TIME! -- Start Prepare the log file --------------------------------------------------------------------- >> "!vrdlog!" 2>&1
SET vrdlog=!root!%~n0-vrdlog-!header!.log
REM ECHO !DATE! !TIME! DEL /F "!vrdlog!"
DEL /F "!vrdlog!" >NUL 2>&1
ECHO !DATE! !TIME! -- Finish Prepare the log file --------------------------------------------------------------------- >> "!vrdlog!" 2>&1

ECHO !DATE! !TIME! --------- Start Setup Folders --------- ensure trailing backslash exists >> "!vrdlog!" 2>&1
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
ECHO !DATE! !TIME! before capture_TS_folder="%capture_TS_folder%" >> "!vrdlog!" 2>&1
FOR /F %%i IN ("!capture_TS_folder!") DO (set "capture_TS_folder=%%~fi")
ECHO !DATE! !TIME! after capture_TS_folder="%capture_TS_folder%" >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! before source_TS_Folder="%source_TS_Folder%" >> "!vrdlog!" 2>&1
FOR /F %%i IN ("!source_TS_Folder!") DO (set "source_TS_Folder=%%~fi")
ECHO !DATE! !TIME! after source_TS_Folder="%source_TS_Folder%" >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! before done_TS_Folder="%done_TS_Folder%" >> "!vrdlog!" 2>&1
FOR /F %%i IN ("!done_TS_Folder!") DO (set "done_TS_Folder=%%~fi")
ECHO !DATE! !TIME! after done_TS_Folder="%done_TS_Folder%" >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! before failed_conversion_TS_Folder="%failed_conversion_TS_Folder%" >> "!vrdlog!" 2>&1
FOR /F %%i IN ("!failed_conversion_TS_Folder!") DO (set "failed_conversion_TS_Folder=%%~fi")
ECHO !DATE! !TIME! after failed_conversion_TS_Folder="%failed_conversion_TS_Folder%" >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! before scratch_Folder="%scratch_Folder%" >> "!vrdlog!" 2>&1
FOR /F %%i IN ("!scratch_Folder!") DO (set "scratch_Folder=%%~fi")
ECHO !DATE! !TIME! after scratch_Folder="%scratch_Folder%" >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! before temp_Folder="%temp_Folder%" >> "!vrdlog!" 2>&1
FOR /F %%i IN ("!temp_Folder!") DO (set "temp_Folder=%%~fi")
ECHO !DATE! !TIME! after temp_Folder="%temp_Folder%" >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! before destination_mp4_Folder="%destination_mp4_Folder%" >> "!vrdlog!" 2>&1
FOR /F %%i IN ("!destination_mp4_Folder!") DO (set "destination_mp4_Folder=%%~fi")
ECHO !DATE! !TIME! after destination_mp4_Folder="%destination_mp4_Folder%" >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! --------- Finish Setup Folders --------- >> "!vrdlog!" 2>&1

ECHO !DATE! !TIME! --------- Start setup LOG file and TEMP filenames ---------------------------- >> "!vrdlog!" 2>&1
REM base the filenames on the running script filename using %~n0
set PSlog=!source_TS_Folder!%~n0-!header!-PSlog.log
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

set "temp_cmd_file_echo_status=!temp_Folder!temp_cmd_file_echo_status.txt"
ECHO !DATE! !TIME! DEL /F "!temp_cmd_file_echo_status!" >> "!vrdlog!" 2>&1
DEL /F "!temp_cmd_file_echo_status!" >> "!vrdlog!" 2>&1

set "vrd5_logfiles=G:\HDTV\VideoReDo-5_*.Log"
ECHO DEL /F "!vrd5_logfiles!" >> "!vrdlog!" 2>&1
DEL /F "!vrd5_logfiles!" >> "!vrdlog!" 2>&1

set "vrd6_logfiles=G:\HDTV\VideoReDo6_*.Log"
ECHO DEL /F "!vrd6_logfiles!" >> "!vrdlog!" 2>&1
DEL /F "!vrd6_logfiles!" >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! --------- Finish setup LOG file and TEMP filenames ---------------------------- >> "!vrdlog!" 2>&1

ECHO !DATE! !TIME! --------- Start setup vrd paths filenames etc ---------------------------- >> "!vrdlog!" 2>&1
REM set the primary and fallback version of VRD to use for QSF
REM The QSF fallback process uses these next 2 variables to set/reset which version use when, via "CALL :set_vrd_qsf_paths NUMBER"
REM
set "DEFAULT_vrd_version_primary=5"
set "DEFAULT_vrd_version_fallback=6"
REM
set "extension_mpeg2=mpg"
set "extension_h264=mp4"
set "extension_h265=mp4"
set "extension_vp9=mp4"
set "VRDTVSP_QSF_VBS_SCRIPT=!root!VRDTVSP_qsf_script.vbs"
set "profile_name_for_qsf_mpeg2_vrd6=VRDTVS-for-QSF-MPEG2_VRD6"
set "profile_name_for_qsf_mpeg2_vrd5=VRDTVS-for-QSF-MPEG2_VRD5"
set "profile_name_for_qsf_h264_vrd6=VRDTVS-for-QSF-H264_VRD6"
set "profile_name_for_qsf_h264_vrd5=VRDTVS-for-QSF-H264_VRD5"
set "profile_name_for_qsf_h265_vrd6="
set "profile_name_for_qsf_h265_vrd5="
set "profile_name_for_qsf_vp9_vrd6="
set "profile_name_for_qsf_vp9_vrd5="
REM qsf timeout in minutes  (VRD v6 takes 4 hours for a large 10Gb footy file); allow extra 10 secs for cscript timeout for vrd to finish copying .tmp file to .mp4 file
set "default_qsf_timeout_minutes_VRD6=300"
set /a default_qsf_timeout_seconds_VRD6=(!default_qsf_timeout_minutes_VRD6! * 60) + 30
set "default_qsf_timeout_minutes_VRD5=60"
set /a default_qsf_timeout_seconds_VRD5=(!default_qsf_timeout_minutes_VRD5! * 60) + 30
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
REM ECHO set DEFAULT_vrd_ >> "!vrdlog!" 2>&1
REM set DEFAULT_vrd_ >> "!vrdlog!" 2>&1
REM ECHO set _vrd_ >> "!vrdlog!" 2>&1
REM set _vrd_ >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! --------- Finish setup vrd paths filenames etc ---------------------------- >> "!vrdlog!" 2>&1

ECHO !DATE! !TIME! --------- Start setup .PY fully qualified filenames to pre-created files which rename and re-timestamp filenames etc --------- >> "!vrdlog!" 2>&1
set "Path_to_py_VRDTVSP_Calculate_Duration=!root!VRDTVSP_Calculate_Duration.py"
set "Path_to_py_VRDTVSP_Rename_Fix_Filenames_Move_Date_Adjust_Titles=!root!VRDTVSP_Rename_Fix_Filenames_Move_Date_Adjust_Titles.py"
set "Path_to_py_VRDTVSP_Modify_File_Date_Timestamps=!root!VRDTVSP_Modify_File_Date_Timestamps.py"
set "Path_to_py_VRDTVSP_Set_Mediainfo_Variables_for_first_stream_in_section=!root!VRDTVSP_Set_Mediainfo_Variables_for_first_stream_in_section.py"
set "Path_to_py_VRDTVSP_Set_ffprobe_Variables_for_first_stream_in_section=!root!VRDTVSP_Set_ffprobe_Variables_for_first_stream_in_section.py"
set "Path_to_vbs_VRDTVSP_Run_QSF_with_v5_or_v6=!root!VRDTVSP_Run_QSF_with_v5_or_v6.vbs"
ECHO !DATE! !TIME! --------- Finish setup .VBS and .PS1 and .PY fully qualified filenames to pre-created files which rename and re-timestamp filenames etc --------- >> "!vrdlog!" 2>&1

CALL :get_date_time_String "TOTAL_start_date_time"

ECHO !DATE! !TIME! --------- Start Initial Summarize --------- >> "!vrdlog!" 2>&1
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
ECHO !DATE! !TIME! capture_TS_folder="!capture_TS_folder!" >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! source_TS_Folder="!source_TS_Folder!" >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! done_TS_Folder="!done_TS_Folder!" >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! failed_conversion_TS_Folder="!failed_conversion_TS_Folder!" >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! scratch_Folder="!scratch_Folder!" >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! destination_mp4_Folder="!destination_mp4_Folder!" >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! PSlog="!PSlog!" >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! tempfile="!tempfile!" >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! extension_mpeg2="!extension_mpeg2!" >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! extension_h264="!extension_h264!" >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! VRDTVSP_QSF_VBS_SCRIPT="!VRDTVSP_QSF_VBS_SCRIPT!" >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! Path_to_vrd6="!Path_to_vrd6!" >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! Path_to_vp_vbs_vrd6="!Path_to_vp_vbs_vrd6!" >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! Path_to_vrd5="!Path_to_vrd5!" >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! Path_to_vp_vbs_vrd5="!Path_to_vp_vbs_vrd5!" >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! SET VRD paths for version "!_vrd_version_primary!" >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! Path_to_vrd="!Path_to_vrd!" >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! Path_to_vrd_vp_vbs="!Path_to_vrd_vp_vbs!" >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! profile_name_for_qsf_mpeg2="!profile_name_for_qsf_mpeg2!" >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! profile_name_for_qsf_h264="!profile_name_for_qsf_h264!" >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! profile_name_for_qsf_h265="!profile_name_for_qsf_h265!" >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! Path_to_py_VRDTVSP_Calculate_Duration="!Path_to_py_VRDTVSP_Calculate_Duration!" >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! Path_to_py_VRDTVSP_Rename_Fix_Filenames_Move_Date_Adjust_Titles="!Path_to_py_VRDTVSP_Rename_Fix_Filenames_Move_Date_Adjust_Titles!" >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! Path_to_py_VRDTVSP_Modify_File_Date_Timestamps="!Path_to_py_VRDTVSP_Modify_File_Date_Timestamps!" >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! Path_to_py_VRDTVSP_Set_Mediainfo_Variables_for_first_stream_in_section="!Path_to_py_VRDTVSP_Set_Mediainfo_Variables_for_first_stream_in_section!" >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! Path_to_py_VRDTVSP_Set_ffprobe_Variables_for_first_stream_in_section="!Path_to_py_VRDTVSP_Set_ffprobe_Variables_for_first_stream_in_section!" >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! Finish summary of Initialised paths etc ... >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! ----------------------------------------------------------------------------------------------------------------------- >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! --------- Finish Initial Summarize --------- >> "!vrdlog!" 2>&1

ECHO !DATE! !TIME! --------- Start SETUP FFMPEG DEVICE and OpenCL stuff and show helps --------- >> "!vrdlog!" 2>&1
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
ECHO !DATE! !TIME! --------- Finish SETUP FFMPEG DEVICE and OpenCL stuff and show helps --------- >> "!vrdlog!" 2>&1

ECHO !DATE! !TIME! Start ********** Start PREVENT PC FROM GOING TO SLEEP ********** >> "!vrdlog!" 2>&1
set iFile=Insomnia-!header!.exe
ECHO copy "C:\SOFTWARE\Insomnia\32-bit\Insomnia.exe" "!source_TS_Folder!!iFile!" >> "!vrdlog!" 2>&1
copy "C:\SOFTWARE\Insomnia\32-bit\Insomnia.exe" "!source_TS_Folder!!iFile!" >> "!vrdlog!" 2>&1
start /min "!iFile!" "!source_TS_Folder!!iFile!"
ECHO !DATE! !TIME! Finish ********** Finish PREVENT PC FROM GOING TO SLEEP ********** >> "!vrdlog!" 2>&1

ECHO !DATE! !TIME! --------- Start Swap to source folder and save old folder using PUSHD --------- >> "!vrdlog!" 2>&1
CD >> "!vrdlog!" 2>&1
ECHO PUSHD "!source_TS_Folder!" >> "!vrdlog!" 2>&1
PUSHD "!source_TS_Folder!" >> "!vrdlog!" 2>&1
CD >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! --------- Finish Swap to source folder and save old folder using PUSHD --------- >> "!vrdlog!" 2>&1

ECHO !DATE! !TIME! --------- Start move .TS .MP4 .MPG .VOB files from capture folder "!capture_TS_folder!" to "!source_TS_Folder!" --------- >> "!vrdlog!" 2>&1
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
REM ECHO "!py_exe!" "!Path_to_py_VRDTVSP_Calculate_Duration!" --start_datetime "!start_date_time!" --end_datetime "!end_date_time!" --prefix_id "MoveFiles" >> "!vrdlog!" 2>&1
"!py_exe!" "!Path_to_py_VRDTVSP_Calculate_Duration!" --start_datetime "!start_date_time!" --end_datetime "!end_date_time!" --prefix_id "MoveFiles" >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! --------- Finish move .TS .MP4 .MPG .VOB files from capture folder "!capture_TS_folder!" to "!source_TS_Folder!" --------- >> "!vrdlog!" 2>&1

ECHO !DATE! !TIME! --------- Start Run the py to modify the filenames to enforce validity  i.e. no special characters --------- >> "!vrdlog!" 2>&1
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
ECHO "!py_exe!" "!Path_to_py_VRDTVSP_Rename_Fix_Filenames_Move_Date_Adjust_Titles!" --folder "!the_folder!" --recurse >> "!vrdlog!" 2>&1
"!py_exe!" "!Path_to_py_VRDTVSP_Rename_Fix_Filenames_Move_Date_Adjust_Titles!" --folder "!the_folder!" --recurse >> "!vrdlog!" 2>&1
CALL :get_date_time_String "end_date_time"
ECHO "!py_exe!" "!Path_to_py_VRDTVSP_Calculate_Duration!" --start_datetime "!start_date_time!" --end_datetime "!end_date_time!" --prefix_id "VRDTVSP_Rename_Fix_Filenames_Move_Date_Adjust_Titles !the_folder!" >> "!vrdlog!" 2>&1
"!py_exe!" "!Path_to_py_VRDTVSP_Calculate_Duration!" --start_datetime "!start_date_time!" --end_datetime "!end_date_time!" --prefix_id "VRDTVSP_Rename_Fix_Filenames_Move_Date_Adjust_Titles !the_folder!" >> "!vrdlog!" 2>&1
REM
CALL :get_date_time_String "loop_start_date_time"
ECHO !DATE! !TIME! --------- Finish Run the py to modify the filenames to enforce validity  i.e. no special characters --------- >> "!vrdlog!" 2>&1


REM ****************************************************************************************************************************************
REM ****************************************************************************************************************************************
:before_main_loop
ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! ------------------ STARTING MAIN LOOP ------------------ %%f >> "!vrdlog!" 2>&1
CALL :get_date_time_String "loop_start_date_time"
for %%f in ("!source_TS_Folder!*.TS", "!source_TS_Folder!*.MPG", "!source_TS_Folder!*.MP4", "!source_TS_Folder!*.VOB") do (
	CALL :get_date_time_String "iloop_start_date_time"
	ECHO !DATE! !TIME! ------------------ CYCLE IN MAIN LOOP START ------------------ %%f >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! Start Calling :QSFandCONVERT with Input file "%%~f" >> "!vrdlog!" 2>&1
	CALL :QSFandCONVERT "%%f"
	REM no - MOVE "%%f" "!done_TS_Folder!" - INSTEAD do the RENAME/MOVE as a part of the CALL above, depending on whether it's been processed correctly
	ECHO !DATE! !TIME! Finished Calling :QSFandCONVERT with Input file "%%~f" >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! ------------------ CYCLE IN MAIN LOOP FINISH ------------------ %%f >> "!vrdlog!" 2>&1
	CALL :get_date_time_String "iloop_end_date_time"
	ECHO "!py_exe!" "!Path_to_py_VRDTVSP_Calculate_Duration!" --start_datetime "!iloop_start_date_time!" --end_datetime "!iloop_end_date_time!" --prefix_id ":::::::::: iloop %%f " >> "!vrdlog!" 2>&1
	"!py_exe!" "!Path_to_py_VRDTVSP_Calculate_Duration!" --start_datetime "!iloop_start_date_time!" --end_datetime "!iloop_end_date_time!" --prefix_id ":::::::::: iloop %%f " >> "!vrdlog!" 2>&1
)
CALL :get_date_time_String "loop_end_date_time"
ECHO "!py_exe!" "!Path_to_py_VRDTVSP_Calculate_Duration!" --start_datetime "!loop_start_date_time!" --end_datetime "!loop_end_date_time!" --prefix_id "Loop_Processing_Files" >> "!vrdlog!" 2>&1
"!py_exe!" "!Path_to_py_VRDTVSP_Calculate_Duration!" --start_datetime "!loop_start_date_time!" --end_datetime "!loop_end_date_time!" --prefix_id "Loop_Processing_Files" >> "!vrdlog!" 2>&1
:after_main_loop
ECHO !DATE! !TIME! ------------------ FINISHED MAIN LOOP ------------------ %%f >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
REM ****************************************************************************************************************************************
REM ****************************************************************************************************************************************


ECHO !DATE! !TIME! --------- Start Run the py to modify the filenames to enforce validity  i.e. no special characters --------- >> "!vrdlog!" 2>&1
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
ECHO !DATE! !TIME! --------- Finish Run the py to modify the filenames to enforce validity  i.e. no special characters --------- >> "!vrdlog!" 2>&1

ECHO !DATE! !TIME! --------- Start Run the py to modify the filename timestamps filenames based on the date in the filename eg 2020-06-03 --------- >> "!vrdlog!" 2>&1
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
ECHO !DATE! !TIME! --- FINISH Modify DateCreated and DateModified Timestamps on "!destination_mp4_Folder!" >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! --------- Finish Run the py to modify the filename timestamps filenames based on the date in the filename eg 2020-06-03 --------- >> "!vrdlog!" 2>&1

ECHO !DATE! !TIME! ********** Start ALLOW PC TO GO TO SLEEP AGAIN ********** >> "!vrdlog!" 2>&1
REM "C:\000-PStools\pskill.exe" -t -nobanner "%iFile%" >> "!vrdlog!" 2>&1
ECHO taskkill /t /f /im "%iFile%" >> "!vrdlog!" 2>&1
taskkill /t /f /im "%iFile%" >> "!vrdlog!" 2>&1
DEL /F "!source_TS_Folder!!iFile!" >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! ********** Finish ALLOW PC TO GO TO SLEEP AGAIN ********** >> "!vrdlog!" 2>&1

ECHO !DATE! !TIME! --------- Start Swap back to original folder using POPD --------- >> "!vrdlog!" 2>&1
CD >> "!vrdlog!" 2>&1
ECHO POPD >> "!vrdlog!" 2>&1
POPD >> "!vrdlog!" 2>&1
CD >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! --------- Finish Swap back to original folder using POPD --------- >> "!vrdlog!" 2>&1

CALL :get_date_time_String "TOTAL_end_date_time"
ECHO "!py_exe!" "!Path_to_py_VRDTVSP_Calculate_Duration!" --start_datetime "!TOTAL_start_date_time!" --end_datetime "!TOTAL_end_date_time!" --prefix_id "TOTAL" >> "!vrdlog!" 2>&1
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
set "check_QSF_failed="

REM dispose of a LOT of variables, some of whih are large
CALL :clear_variables

REM :gather_variables_from_media_file P2 =	the global prefix to use for this gather, one of "SRC_", "QSF_" "TARGET_"
CALL :gather_variables_from_media_file "%~f1" "SRC_" 

REM "SRC_calc_Video_Encoding=AVC"
REM "SRC_calc_Video_Encoding=MPEG2"
REM "SRC_calc_Video_Encoding=HEVC"
REM "SRC_calc_Video_Encoding=VP9"
REM "SRC_calc_Video_Encoding_original=AVC"
REM "SRC_calc_Video_Encoding_original=MPEG2"
REM "SRC_calc_Video_Encoding_original=HEVC"
REM "SRC_calc_Video_Encoding=VP9"

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
REM "extension_vp9=mp4"
REM 
REM Providing subroutine :set_vrd_qsf_paths has been called, then these have been preset:
REM    profile_name_for_qsf_mpeg2
REM    profile_name_for_qsf_h264
REM    extension_mpeg2=mpg
REM    extension_h264=mp4
REM    extension_h265=mp4
REM    extension_vp9=vp9

REM Check if SRC_ interlacing variable is valid
IF /I "!SRC_calc_Video_Interlacement!" == "PROGRESSIVE" (
	ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
) ELSE IF /I "!SRC_calc_Video_Interlacement!" == "INTERLACED" (
	ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
) ELSE (
	set "check_QSF_failed=ERROR: mediainfo/ffmpeg data '!SRC_calc_Video_Interlacement!' yields neither PROGRESSIVE nor INTERLACED for '%~f1'"
	ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! !check_QSF_failed! >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
	CALL :declare_FAILED "%~f1"
	CALL :get_date_time_String "end_date_time_QSF"
	REM ECHO "!py_exe!" "!Path_to_py_VRDTVSP_Calculate_Duration!" --start_datetime "!start_date_time_QSF!" --end_datetime "!end_date_time_QSF!" --prefix_id "QSF itself" >> "!vrdlog!" 2>&1
	"!py_exe!" "!Path_to_py_VRDTVSP_Calculate_Duration!" --start_datetime "!start_date_time_QSF!" --end_datetime "!end_date_time_QSF!" --prefix_id "QSF itself" >> "!vrdlog!" 2>&1
	goto :eof
)
REM Check if SRC_ interlacement field variable is valid
IF /I "!SRC_calc_Video_FieldFirst!" == "TFF" (
	ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
) ELSE IF /I "!SRC_calc_Video_FieldFirst!" == "BFF" (
	ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
) ELSE (
	set "check_QSF_failed=ERROR: mediainfo/ffmpeg processing '!SRC_calc_Video_FieldFirst!' yields neither 'TFF' nor 'BFF' field-first ,default='TFF', for '%~f1'"
	ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! !check_QSF_failed! >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
	CALL :declare_FAILED "%~f1"
	CALL :get_date_time_String "end_date_time_QSF"
	REM ECHO "!py_exe!" "!Path_to_py_VRDTVSP_Calculate_Duration!" --start_datetime "!start_date_time_QSF!" --end_datetime "!end_date_time_QSF!" --prefix_id "QSF itself" >> "!vrdlog!" 2>&1
	"!py_exe!" "!Path_to_py_VRDTVSP_Calculate_Duration!" --start_datetime "!start_date_time_QSF!" --end_datetime "!end_date_time_QSF!" --prefix_id "QSF itself" >> "!vrdlog!" 2>&1
	goto :eof
)
REM Check if SRC_ encoding variable is valid
IF /I "!SRC_calc_Video_Encoding!" == "AVC" (
	set "qsf_extension=!extension_h264!"
) ELSE IF /I "!SRC_calc_Video_Encoding!" == "MPEG2" (
	set "qsf_extension=!extension_mpeg2!"
) ELSE IF /I "!SRC_calc_Video_Encoding!" == "HEVC" (
	set "qsf_extension=!extension_h265!"
) ELSE IF /I "!SRC_calc_Video_Encoding!" == "VP9" (
	set "qsf_extension=!extension_vp9!"
) ELSE (
	set "check_QSF_failed=ERROR: mediainfo format !SRC_calc_Video_Encoding! neither 'AVC' nor 'MPEG2' nor 'HEVC' nor 'VP9' for '%~f1'"
	ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! !check_QSF_failed! >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
	CALL :declare_FAILED "%~f1"
	CALL :get_date_time_String "end_date_time_QSF"
	REM ECHO "!py_exe!" "!Path_to_py_VRDTVSP_Calculate_Duration!" --start_datetime "!start_date_time_QSF!" --end_datetime "!end_date_time_QSF!" --prefix_id "QSF itself" >> "!vrdlog!" 2>&1
	"!py_exe!" "!Path_to_py_VRDTVSP_Calculate_Duration!" --start_datetime "!start_date_time_QSF!" --end_datetime "!end_date_time_QSF!" --prefix_id "QSF itself" >> "!vrdlog!" 2>&1
	goto :eof
)

set "qsf_xml_prefix=QSFinfo_"
set "SOURCE_File=!~f1!"
set "QSF_File=!scratch_Folder!%~n1.qsf.!qsf_extension!"
set "DGI_file=!scratch_Folder!%~n1.qsf.dgi"
set "DGI_autolog=!scratch_Folder!%~n1.qsf.log"
set "VPY_file=!scratch_Folder!%~n1.qsf.vpy"
set "Target_File=!destination_mp4_Folder!%~n1.MP4"

set "can_do_qsf=False"
IF /I "!SRC_calc_Video_Encoding!" == "AVC" (
	set "can_do_qsf=True"
) ELSE IF /I "!SRC_calc_Video_Encoding!" == "MPEG2" (
	set "can_do_qsf=True"
) ELSE IF /I "!SRC_calc_Video_Encoding!" == "HEVC" (
	set "can_do_qsf=False"
) ELSE IF /I "!SRC_calc_Video_Encoding!" == "VP9" (
	set "can_do_qsf=False"
) ELSE (
	set "can_do_qsf=False"
)
IF /I "!can_do_qsf!" == "True" (
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
	ECHO CALL :run_cscript_qsf_with_timeout "!DEFAULT_vrd_version_primary!" "%~f1" "!QSF_File!" "!qsf_xml_prefix!" >> "!vrdlog!" 2>&1
	CALL :run_cscript_qsf_with_timeout "!DEFAULT_vrd_version_primary!" "%~f1" "!QSF_File!" "!qsf_xml_prefix!"
	REM check result returned from :run_cscript_qsf_with_timeout
	IF /I NOT "!check_QSF_failed!" == "" (
		REM It failed, try doing the fallback QSF
		set "check_QSF_failed="
		ECHO call run_cscript_qsf_with_timeout "!DEFAULT_vrd_version_fallback!" "%~f1" "!QSF_File!" "!qsf_xml_prefix!" >> "!vrdlog!" 2>&1
		CALL :run_cscript_qsf_with_timeout "!DEFAULT_vrd_version_fallback!" "%~f1" "!QSF_File!" "!qsf_xml_prefix!"
		REM check result returned from :run_cscript_qsf_with_timeout
		IF /I NOT "!check_QSF_failed!" == "" (
			ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
			ECHO !DATE! !TIME! !check_QSF_failed! >> "!vrdlog!" 2>&1
			ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
			CALL :declare_FAILED "%~f1"
			CALL :get_date_time_String "end_date_time_QSF"
			REM ECHO "!py_exe!" "!Path_to_py_VRDTVSP_Calculate_Duration!" --start_datetime "!start_date_time_QSF!" --end_datetime "!end_date_time_QSF!" --prefix_id "QSF itself" >> "!vrdlog!" 2>&1
			"!py_exe!" "!Path_to_py_VRDTVSP_Calculate_Duration!" --start_datetime "!start_date_time_QSF!" --end_datetime "!end_date_time_QSF!" --prefix_id "QSF itself" >> "!vrdlog!" 2>&1
			goto :eof
		)
	)
) ELSE (
	ECHO CALL :run_ffmpeg_stream_copy_instead_of_qsf "%~f1" "!QSF_File!" "!qsf_xml_prefix!" >> "!vrdlog!" 2>&1
	CALL :run_ffmpeg_stream_copy_instead_of_qsf "%~f1" "!QSF_File!" "!qsf_xml_prefix!"
	REM check result returned from :run_ffmpeg_stream_copy_instead_of_qsf
	IF /I NOT "!check_QSF_failed!" == "" (
		ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
		ECHO !DATE! !TIME! !check_QSF_failed! >> "!vrdlog!" 2>&1
		ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
		CALL :declare_FAILED "%~f1"
		CALL :get_date_time_String "end_date_time_QSF"
		REM ECHO "!py_exe!" "!Path_to_py_VRDTVSP_Calculate_Duration!" --start_datetime "!start_date_time_QSF!" --end_datetime "!end_date_time_QSF!" --prefix_id "QSF itself" >> "!vrdlog!" 2>&1
		"!py_exe!" "!Path_to_py_VRDTVSP_Calculate_Duration!" --start_datetime "!start_date_time_QSF!" --end_datetime "!end_date_time_QSF!" --prefix_id "QSF itself" >> "!vrdlog!" 2>&1
		goto :eof
	)
)

REM Use the max of these actual video bitrates (not the "overall" which includes audio bitrate) 
REM		SRC_MI_V_BitRate
REM		QSF_MI_V_BitRate
REM		QSFinfo_ActualVideoBitrate
set /a SRC_calc_Video_Max_Bitrate=0
if !SRC_MI_V_BitRate! gtr !SRC_calc_Video_Max_Bitrate! (set /a SRC_calc_Video_Max_Bitrate=!SRC_MI_V_BitRate!)

REM deal with cases of no QSF done
IF /I "!QSF_calc_Video_Encoding!" == "HEVC" (
	set "QSFinfo_ActualVideoBitrate=!QSF_MI_V_BitRate!"
) ELSE IF /I "!QSF_calc_Video_Encoding!" == "VP9" (
	set "QSFinfo_ActualVideoBitrate=!QSF_MI_V_BitRate!"
)

REM 	' NOTE:	After testing, it has been found that ffprobe can mis-report bitrates in the QSF'd file by about double.
REM 	'		Although mediainfo and the "QSF log" values are reasonably close, testing shows ffprobe gets it more "right" when encoding.
REM 	'		Although hopefully correct, this can result in a much lower transcoded filesizes than the originals.
if !QSF_MI_V_BitRate! gtr !SRC_calc_Video_Max_Bitrate! (set /a SRC_calc_Video_Max_Bitrate=!QSF_MI_V_BitRate!)
if !QSFinfo_ActualVideoBitrate! gtr !SRC_calc_Video_Max_Bitrate! (set /a SRC_calc_Video_Max_Bitrate=!QSFinfo_ActualVideoBitrate!)
ECHO SRC_calc_Video_Max_Bitrate=!SRC_calc_Video_Max_Bitrate! from !SRC_MI_V_BitRate!, !QSF_MI_V_BitRate!, !QSFinfo_ActualVideoBitrate! >> "!vrdlog!" 2>&1
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
	set "check_QSF_failed=ERROR: incoming SRC_calc_Video_Encoding '!SRC_calc_Video_Encoding!' NOT EQUAL QSF_calc_Video_Encoding '!QSF_calc_Video_Encoding!' for '%~f1'"
	ECHO !DATE! !TIME! !check_QSF_failed! >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! SRC file="%~f1" >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! QSF_file="!QSF_File!" >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
	CALL :declare_FAILED "%~f1"
	CALL :get_date_time_String "end_date_time_QSF"
	REM ECHO "!py_exe!" "!Path_to_py_VRDTVSP_Calculate_Duration!" --start_datetime "!start_date_time_QSF!" --end_datetime "!end_date_time_QSF!" --prefix_id "QSF itself" >> "!vrdlog!" 2>&1
	"!py_exe!" "!Path_to_py_VRDTVSP_Calculate_Duration!" --start_datetime "!start_date_time_QSF!" --end_datetime "!end_date_time_QSF!" --prefix_id "QSF itself" >> "!vrdlog!" 2>&1
	goto :eof
)
IF /I NOT "!SRC_FF_V_codec_name!" == "!QSF_FF_V_codec_name!" (
	set "check_QSF_failed=ERROR: incoming SRC_FF_V_codec_name '!SRC_FF_V_codec_name!' NOT EQUAL QSF_FF_V_codec_name '!QSF_FF_V_codec_name!' for '%~f1'"
	ECHO !DATE! !TIME! !check_QSF_failed! >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! SRC file="%~f1" >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! QSF_file="!QSF_File!" >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
	CALL :declare_FAILED "%~f1"
	CALL :get_date_time_String "end_date_time_QSF"
	REM ECHO "!py_exe!" "!Path_to_py_VRDTVSP_Calculate_Duration!" --start_datetime "!start_date_time_QSF!" --end_datetime "!end_date_time_QSF!" --prefix_id "QSF itself" >> "!vrdlog!" 2>&1
	"!py_exe!" "!Path_to_py_VRDTVSP_Calculate_Duration!" --start_datetime "!start_date_time_QSF!" --end_datetime "!end_date_time_QSF!" --prefix_id "QSF itself" >> "!vrdlog!" 2>&1
	goto :eof
)
IF /I NOT "!SRC_calc_Video_Interlacement!" == "!QSF_calc_Video_Interlacement!" (
	set "check_QSF_failed=ERROR: incoming SRC_calc_Video_Interlacement '!SRC_calc_Video_Interlacement!' NOT EQUAL QSF_calc_Video_Interlacement '!QSF_calc_Video_Interlacement!' for '%~f1'"
	ECHO !DATE! !TIME! !check_QSF_failed! >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! SRC file="%~f1" >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! QSF_file="!QSF_File!" >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
	CALL :declare_FAILED "%~f1"
	CALL :get_date_time_String "end_date_time_QSF"
	REM ECHO "!py_exe!" "!Path_to_py_VRDTVSP_Calculate_Duration!" --start_datetime "!start_date_time_QSF!" --end_datetime "!end_date_time_QSF!" --prefix_id "QSF itself" >> "!vrdlog!" 2>&1
	"!py_exe!" "!Path_to_py_VRDTVSP_Calculate_Duration!" --start_datetime "!start_date_time_QSF!" --end_datetime "!end_date_time_QSF!" --prefix_id "QSF itself" >> "!vrdlog!" 2>&1
	goto :eof
)
IF /I NOT "!SRC_calc_Video_FieldFirst!" == "!QSF_calc_Video_FieldFirst!" (
	set "check_QSF_failed=ERROR: incoming SRC_calc_Video_FieldFirst '!SRC_calc_Video_FieldFirst!' NOT EQUAL QSF_calc_Video_FieldFirst '!QSF_calc_Video_FieldFirst!' for '%~f1'"
	ECHO !DATE! !TIME! !check_QSF_failed! >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! SRC file="%~f1" >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! QSF_file="!QSF_File!" >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
	CALL :declare_FAILED "%~f1"
	CALL :get_date_time_String "end_date_time_QSF"
	REM ECHO "!py_exe!" "!Path_to_py_VRDTVSP_Calculate_Duration!" --start_datetime "!start_date_time_QSF!" --end_datetime "!end_date_time_QSF!" --prefix_id "QSF itself" >> "!vrdlog!" 2>&1
	"!py_exe!" "!Path_to_py_VRDTVSP_Calculate_Duration!" --start_datetime "!start_date_time_QSF!" --end_datetime "!end_date_time_QSF!" --prefix_id "QSF itself" >> "!vrdlog!" 2>&1
	goto :eof
)
ECHO !DATE! !TIME! ====================================================================================================================================================== >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! QSF file details: "!QSF_File!" >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME!   QSF: Video Codec: '!QSF_FF_V_codec_name!' ScanType: '!QSF_calc_Video_Interlacement!' ScanOrder: '!QSF_calc_Video_FieldFirst!' WxH: !QSF_MI_V_Width!x!QSF_MI_V_HEIGHT! dar:'!QSF_FF_V_display_aspect_ratio_slash!' and '!QSF_MI_V_DisplayAspectRatio_String_slash!' >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME!        Audio Codec: '!QSF_FF_A_codec_name!' Audio_Delay_ms: '!QSF_MI_A_Audio_Delay!' Video_Delay_ms: '!QSF_MI_A_Video_Delay!' QSF_Bitrate: !QSF_MI_V_BitRate! SRC_Bitrate: !SRC_MI_V_BitRate!  SRC_calc_Video_Max_Bitrate=!SRC_calc_Video_Max_Bitrate! >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! _vrd_version_primary='!_vrd_version_primary!' _vrd_version_fallback=!_vrd_version_fallback!' qsf_profile=!qsf_profile!' qsf_extension='!qsf_extension!' >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! ====================================================================================================================================================== >> "!vrdlog!" 2>&1

CALL :get_date_time_String "end_date_time_QSF"
ECHO "!py_exe!" "!Path_to_py_VRDTVSP_Calculate_Duration!" --start_datetime "!start_date_time_QSF!" --end_datetime "!end_date_time_QSF!" --prefix_id "QSF itself" >> "!vrdlog!" 2>&1
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

IF /I "!QSF_calc_Video_Encoding!" == "AVC" (
	REM CALCULATE H.264 TARGET BITRATES FROM THE INCOMING BITRATE
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
	REM ECHO !DATE! !TIME! Bitrates are calculated from the max AVC bitrate seen. >> "!vrdlog!" 2>&1
	REM ECHO !DATE! !TIME! "AVC"      SRC_calc_Video_Max_Bitrate=!SRC_calc_Video_Max_Bitrate! >> "!vrdlog!" 2>&1
	REM ECHO !DATE! !TIME! "AVC" FFMPEG_V_Target_Minimum_BitRate=!FFMPEG_V_Target_Minimum_BitRate! >> "!vrdlog!" 2>&1
	REM ECHO !DATE! !TIME! "AVC"         FFMPEG_V_Target_BitRate=!FFMPEG_V_Target_BitRate! >> "!vrdlog!" 2>&1
	REM ECHO !DATE! !TIME! "AVC" FFMPEG_V_Target_Maximum_BitRate=!FFMPEG_V_Target_Maximum_BitRate! >> "!vrdlog!" 2>&1
	REM ECHO !DATE! !TIME! "AVC"         FFMPEG_V_Target_BufSize=!FFMPEG_V_Target_BufSize! >> "!vrdlog!" 2>&1
) ELSE IF /I "!QSF_calc_Video_Encoding!" == "MPEG2" (
	IF /I "%~x1" == ".MPG" (
		set /a "FFMPEG_V_Target_BitRate=2500000"
		set /a "FFMPEG_V_Target_Minimum_BitRate=100000"
		set /a "FFMPEG_V_Target_Maximum_BitRate=!FFMPEG_V_Target_BitRate! * 2"
		set /a "FFMPEG_V_Target_BufSize=!FFMPEG_V_Target_BitRate! * 2"
	) ELSE IF /I "%~x1" == ".VOB" (
		set /a "FFMPEG_V_Target_BitRate=4000000"
		set /a "FFMPEG_V_Target_Minimum_BitRate=100000"
		set /a "FFMPEG_V_Target_Maximum_BitRate=!FFMPEG_V_Target_BitRate! * 2"
		set /a "FFMPEG_V_Target_BufSize=!FFMPEG_V_Target_BitRate! * 2"
	) ELSE (
		set /a "FFMPEG_V_Target_BitRate=2500000"
		set /a "FFMPEG_V_Target_Minimum_BitRate=100000"
		set /a "FFMPEG_V_Target_Maximum_BitRate=!FFMPEG_V_Target_BitRate! * 2"
		set /a "FFMPEG_V_Target_BufSize=!FFMPEG_V_Target_BitRate! * 2"
	)
	REM ECHO !DATE! !TIME! Bitrates are fixed and NOT calculated, for mpeg2 transcode >> "!vrdlog!" 2>&1
	REM ECHO !DATE! !TIME! Bitrates are assumed based on the MPEG2 extension ""%~x1"" being [.mpg/.vob] or [anything else] >> "!vrdlog!" 2>&1
	REM ECHO !DATE! !TIME! "MPEG2" FFMPEG_V_Target_Minimum_BitRate=!FFMPEG_V_Target_Minimum_BitRate! >> "!vrdlog!" 2>&1
	REM ECHO !DATE! !TIME! "MPEG2"         FFMPEG_V_Target_BitRate=!FFMPEG_V_Target_BitRate! >> "!vrdlog!" 2>&1
	REM ECHO !DATE! !TIME! "MPEG2" FFMPEG_V_Target_Maximum_BitRate=!FFMPEG_V_Target_Maximum_BitRate! >> "!vrdlog!" 2>&1
	REM ECHO !DATE! !TIME! "MPEG2"         FFMPEG_V_Target_BufSize=!FFMPEG_V_Target_BufSize! >> "!vrdlog!" 2>&1
) ELSE IF /I "!QSF_calc_Video_Encoding!" == "HEVC" (
	REM CALCULATE H.264 TARGET BITRATES FROM THE INCOMING BITRATE
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
	REM ECHO !DATE! !TIME! Bitrates are calculated from the max HEVC bitrate seen. >> "!vrdlog!" 2>&1
	REM ECHO !DATE! !TIME! "HEVC"      SRC_calc_Video_Max_Bitrate=!SRC_calc_Video_Max_Bitrate! >> "!vrdlog!" 2>&1
	REM ECHO !DATE! !TIME! "HEVC" FFMPEG_V_Target_Minimum_BitRate=!FFMPEG_V_Target_Minimum_BitRate! >> "!vrdlog!" 2>&1
	REM ECHO !DATE! !TIME! "HEVC"         FFMPEG_V_Target_BitRate=!FFMPEG_V_Target_BitRate! >> "!vrdlog!" 2>&1
	REM ECHO !DATE! !TIME! "HEVC" FFMPEG_V_Target_Maximum_BitRate=!FFMPEG_V_Target_Maximum_BitRate! >> "!vrdlog!" 2>&1
	REM ECHO !DATE! !TIME! "HEVC"         FFMPEG_V_Target_BufSize=!FFMPEG_V_Target_BufSize! >> "!vrdlog!" 2>&1
) ELSE IF /I "!QSF_calc_Video_Encoding!" == "VP9" (
	REM CALCULATE H.264 TARGET BITRATES FROM THE INCOMING BITRATE
	set /a "X_bitrate_05percent=!SRC_calc_Video_Max_Bitrate! / 20"
	set /a "X_bitrate_10percent=!SRC_calc_Video_Max_Bitrate! / 10"
	set /a "X_bitrate_20percent=!SRC_calc_Video_Max_Bitrate! / 5"
	set /a "X_bitrate_25percent=!SRC_calc_Video_Max_Bitrate! / 4"
	set /a "X_bitrate_50percent=!SRC_calc_Video_Max_Bitrate! / 2"
	REM ffmpeg nvenc typically seems to undershoot the target bitrate, so bump it up.
	set /a "FFMPEG_V_Target_BitRate=!SRC_calc_Video_Max_Bitrate! + !X_bitrate_20percent!"
	set /a "extra_bitrate_05percent=!FFMPEG_V_Target_BitRate! / 20"
	set /a "extra_bitrate_10percent=!FFMPEG_V_Target_BitRate! / 10"
	set /a "extra_bitrate_20percent=!FFMPEG_V_Target_BitRate! / 5"
	set /a "extra_bitrate_25percent=!FFMPEG_V_Target_BitRate! / 4"
	set /a "extra_bitrate_50percent=!FFMPEG_V_Target_BitRate! / 2"
	set /a "FFMPEG_V_Target_Minimum_BitRate=!extra_bitrate_20percent!"
	set /a "FFMPEG_V_Target_Maximum_BitRate=!FFMPEG_V_Target_BitRate! * 2"
	set /a "FFMPEG_V_Target_BufSize=!FFMPEG_V_Target_BitRate! * 2"
	REM ECHO !DATE! !TIME! Bitrates are calculated from the max HEVC bitrate seen. >> "!vrdlog!" 2>&1
	REM ECHO !DATE! !TIME! "VP9"      SRC_calc_Video_Max_Bitrate=!SRC_calc_Video_Max_Bitrate! >> "!vrdlog!" 2>&1
	REM ECHO !DATE! !TIME! "VP9" FFMPEG_V_Target_Minimum_BitRate=!FFMPEG_V_Target_Minimum_BitRate! >> "!vrdlog!" 2>&1
	REM ECHO !DATE! !TIME! "VP9"         FFMPEG_V_Target_BitRate=!FFMPEG_V_Target_BitRate! >> "!vrdlog!" 2>&1
	REM ECHO !DATE! !TIME! "VP9" FFMPEG_V_Target_Maximum_BitRate=!FFMPEG_V_Target_Maximum_BitRate! >> "!vrdlog!" 2>&1
	REM ECHO !DATE! !TIME! "VP9"         FFMPEG_V_Target_BufSize=!FFMPEG_V_Target_BufSize! >> "!vrdlog!" 2>&1
) ELSE (
	ECHO !DATE! !TIME! ERROR: UNKNOWN QSF_calc_Video_Encoding="!QSF_calc_Video_Encoding!" to base the transcode calculations on. MUST be AVC or MPEG2 or HEVC or VP9 >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! ERROR: UNKNOWN QSF_calc_Video_Encoding="!QSF_calc_Video_Encoding!" to base the transcode calculations on. MUST be AVC or MPEG2 or HEVC or VP9 >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! ERROR: UNKNOWN QSF_calc_Video_Encoding="!QSF_calc_Video_Encoding!" to base the transcode calculations on. MUST be AVC or MPEG2 or HEVC or VP9 >> "!vrdlog!" 2>&1
	exit 1
)

IF /I "!QSF_calc_Video_Interlacement!" == "PROGRESSIVE" (
	REM set for no deinterlace
	set "FFMPEG_V_dg_deinterlace=0"
	set "FFMPEG_V_vp9_deinterlace_mode="
) ELSE IF /I "!QSF_calc_Video_Interlacement!" == "INTERLACED" (
	REM set for normal single framerate deinterlace
	set "FFMPEG_V_dg_deinterlace=1"
	set "FFMPEG_V_vp9_deinterlace_mode=0"
) ELSE (
	set "check_QSF_failed=ERROR: UNKNOWN QSF_calc_Video_Interlacement="!QSF_calc_Video_Interlacement!" to base transcode calculations on, for '%~f1'"
	ECHO !DATE! !TIME! !check_QSF_failed! >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! SRC file="%~f1" >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! QSF_file="!QSF_File!" >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
	CALL :declare_FAILED "%~f1"
	CALL :get_date_time_String "end_date_time_QSF"
	REM ECHO "!py_exe!" "!Path_to_py_VRDTVSP_Calculate_Duration!" --start_datetime "!start_date_time_QSF!" --end_datetime "!end_date_time_QSF!" --prefix_id "QSF itself" >> "!vrdlog!" 2>&1
	"!py_exe!" "!Path_to_py_VRDTVSP_Calculate_Duration!" --start_datetime "!start_date_time_QSF!" --end_datetime "!end_date_time_QSF!" --prefix_id "QSF itself" >> "!vrdlog!" 2>&1
	goto :eof
)

IF /I "!QSF_calc_Video_FieldFirst!" == "TFF" (
	set "FFMPEG_V_dg_use_TFF=True"
	set "FFMPEG_V_vp9_deinterlace_parity=1"
) ELSE IF /I "!QSF_calc_Video_FieldFirst!" == "BFF" (
	set "FFMPEG_V_dg_use_TFF=False"
	set "FFMPEG_V_vp9_deinterlace_parity=0"
) ELSE (
	set "check_QSF_failed=ERROR: UNKNOWN QSF_calc_Video_FieldFirst="!QSF_calc_Video_FieldFirst!" to base transcode calculations on, for '%~f1'"
	ECHO !DATE! !TIME! !check_QSF_failed! >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! SRC file="%~f1" >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! QSF_file="!QSF_File!" >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
	CALL :declare_FAILED "%~f1"
	CALL :get_date_time_String "end_date_time_QSF"
	REM ECHO "!py_exe!" "!Path_to_py_VRDTVSP_Calculate_Duration!" --start_datetime "!start_date_time_QSF!" --end_datetime "!end_date_time_QSF!" --prefix_id "QSF itself" >> "!vrdlog!" 2>&1
	"!py_exe!" "!Path_to_py_VRDTVSP_Calculate_Duration!" --start_datetime "!start_date_time_QSF!" --end_datetime "!end_date_time_QSF!" --prefix_id "QSF itself" >> "!vrdlog!" 2>&1
	goto :eof
)

REM ECHO !DATE! !TIME! "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" >> "!vrdlog!" 2>&1
REM ECHO !DATE! !TIME! NOTE: After testing, it has been found that ffprobe can mis-report bitrates in the QSF'd file by about double. >> "!vrdlog!" 2>&1
REM ECHO !DATE! !TIME!       Although mediainfo and the "QSF log" values are reasonably close, testing shows ffprobe gets it more "right" when encoding. >> "!vrdlog!" 2>&1
REM ECHO !DATE! !TIME!       Although hopefully correct, this can result in a much lower transcoded filesizes than the originals. >> "!vrdlog!" 2>&1
REM ECHO !DATE! !TIME!       For now, accept what we PROPOSE on whether to "Up" the CQ from 0 to 24. >> "!vrdlog!" 2>&1
REM Default CQ options, default to cq0
set "FFMPEG_V_cq0=-cq:v 0"
set "FFMPEG_V_cq24=-cq:v 24 -qmin 16 -qmax 48"
set "FFMPEG_V_PROPOSED_x_cq_options=!FFMPEG_V_cq0!"
set "FFMPEG_V_final_cq_options=!FFMPEG_V_cq0!"
ECHO !DATE! !TIME! Initial Default FFMPEG_V_final_cq_options="!FFMPEG_V_final_cq_options!" >> "!vrdlog!" 2>&1

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
	REM ECHO !DATE! !TIME! "????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????" >> "!vrdlog!" 2>&1
	REM ECHO Example table of values and actions >> "!vrdlog!" 2>&1
	REM ECHO	MI		FF		INCOMING	ACTION >> "!vrdlog!" 2>&1
	REM ECHO	0		0		5Mb			set to CQ 0 >> "!vrdlog!" 2>&1
	REM ECHO	0		1.5Mb	1.5Mb		set to CQ 24 >> "!vrdlog!" 2>&1
	REM ECHO	0		4Mb		4Mb			set to CQ 0 >> "!vrdlog!" 2>&1
	REM ECHO	1.5Mb	0		1.5Mb		set to CQ 24 >> "!vrdlog!" 2>&1
	REM ECHO	1.5Mb 	1.5Mb	1.5Mb		set to CQ 24 >> "!vrdlog!" 2>&1
	REM ECHO	1.5Mb	4Mb		4Mb			set to CQ 24 *** this one >> "!vrdlog!" 2>&1
	REM ECHO	4Mb		0		4Mb			set to CQ 0 >> "!vrdlog!" 2>&1
	REM ECHO	4Mb		1.5Mb	4Mb			set to CQ 0 >> "!vrdlog!" 2>&1
	REM ECHO	4Mb		5Mb		5Mb			set to CQ 0 >> "!vrdlog!" 2>&1
	REM ECHO !DATE! !TIME! "????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????" >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! Start Calculating whether to Bump CQ from 0 to 24 ... >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! "FFMPEG_V_Target_BitRate=!FFMPEG_V_Target_BitRate!" >> "!vrdlog!" 2>&1
	REM There were nested IF statements which is why the IFs and SETs are done this way
	If !FFMPEG_V_Target_BitRate! LSS 2000000 (
		REM low bitrate, do not touch the bitrate itself, instead bump to CQ24
		set "FFMPEG_V_PROPOSED_x_cq_options=!FFMPEG_V_cq24!"
		ECHO !DATE! !TIME! "yes to Low INCOMING_BITRATE !INCOMING_BITRATE! LSS 2000000" >> "!vrdlog!" 2>&1
		ECHO !DATE! !TIME! "FFMPEG_V_PROPOSED_x_cq_options=!FFMPEG_V_PROPOSED_x_cq_options!" >> "!vrdlog!" 2>&1
	)
	set "FFMPEG_V_final_cq_options=!FFMPEG_V_PROPOSED_x_cq_options!"
	ECHO !DATE! !TIME! Finish Calculating whether to Bump CQ from 0 to 24 ... >> "!vrdlog!" 2>&1
)
REM ECHO !DATE! !TIME! Final FFMPEG_V_final_cq_options='!FFMPEG_V_final_cq_options!' >> "!vrdlog!" 2>&1

ECHO !DATE! !TIME! ----- Start Calculating whether to use 3900X RTX2060super_extra_flags ... >> "!vrdlog!" 2>&1
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
ECHO !DATE! !TIME! ----- Finish Calculating whether to use 3900X RTX2060super_extra_flags ... >> "!vrdlog!" 2>&1

ECHO !DATE! !TIME! ----- Start Checking for and Calculating Footy variables ... >> "!vrdlog!" 2>&1
REM Now Check for Footy, after the final fiddling with bitrates and CQ.
REM If is footy, deinterlace to 50FPS 50p, doubling the framerate, rather than just 25p
REM so that we maintain the "motion fluidity" of 50i into 50p. It's better than Nothing.
set "Footy_found=False"
IF /I NOT "!file_name_part!"=="!file_name_part:AFL=_____!" (
	set "Footy_found=True"
	ECHO Footy word 'AFL' found in filename '!file_name_part!' >> "!vrdlog!" 2>&1
) ELSE IF /I NOT "!file_name_part!"=="!file_name_part:SANFL=_____!" (
	set "Footy_found=True"
	ECHO Footy word 'SANFL' found in filename '!file_name_part!' >> "!vrdlog!" 2>&1
) ELSE IF /I NOT "!file_name_part!"=="!file_name_part:Crows=_____!" (
	set "Footy_found=True"
	ECHO Footy word 'Crows' found in filename '!file_name_part!' >> "!vrdlog!" 2>&1
) ELSE (
	set "Footy_found=False"
	ECHO NO Footy words found in filename '!file_name_part!' >> "!vrdlog!" 2>&1
)
IF /I "!Footy_found!" == "True" (
	IF /I "!QSF_calc_Video_Interlacement!" == "PROGRESSIVE" (
		REM set for no deinterlace
		set "FFMPEG_V_dg_deinterlace=0"
		set "FFMPEG_V_vp9_deinterlace_mode="
		ECHO Already Progressive video, Footy words found in filename '!file_name_part!', FFMPEG_V_dg_deinterlace=!FFMPEG_V_dg_deinterlace! FFMPEG_V_vp9_deinterlace_mode='!FFMPEG_V_vp9_deinterlace_mode!' NO Footy variables set >> "!vrdlog!" 2>&1
	) ELSE IF /I "!QSF_calc_Video_Interlacement!" == "INTERLACED" (
		REM set for double framerate deinterlace
		set "FFMPEG_V_dg_deinterlace=2"
		set "FFMPEG_V_vp9_deinterlace_mode=1"
		REM use python to calculate rounded values for upped FOOTY double framerate deinterlaced output
		CALL :calc_single_number_result_py "int(round(!FFMPEG_V_Target_BitRate! * 1.75))"       "Footy_FFMPEG_V_Target_BitRate"
		CALL :calc_single_number_result_py "int(round(!Footy_FFMPEG_V_Target_BitRate! * 0.20))" "Footy_FFMPEG_V_Target_Minimum_BitRate"
		CALL :calc_single_number_result_py "int(round(!Footy_FFMPEG_V_Target_BitRate! * 2))"    "Footy_FFMPEG_V_Target_Maximum_BitRate"
		CALL :calc_single_number_result_py "int(round(!Footy_FFMPEG_V_Target_BitRate! * 2))"    "Footy_FFMPEG_V_Target_BufSize"
		ECHO Interlaced video, Footy words found in filename '!file_name_part!', FFMPEG_V_dg_deinterlace=!FFMPEG_V_dg_deinterlace! FFMPEG_V_vp9_deinterlace_mode='!FFMPEG_V_vp9_deinterlace_mode!' Footy variables set >> "!vrdlog!" 2>&1
		set /a FFMPEG_V_Target_BitRate=!Footy_FFMPEG_V_Target_BitRate!
		set /a FFMPEG_V_Target_Minimum_BitRate=!Footy_FFMPEG_V_Target_Minimum_BitRate!
		set /a FFMPEG_V_Target_Maximum_BitRate=!Footy_FFMPEG_V_Target_Maximum_BitRate!
		set /a FFMPEG_V_Target_BufSize=!Footy_FFMPEG_V_Target_BufSize!
	) ELSE (
		set "check_QSF_failed=UNKNOWN QSF_calc_Video_Interlacement="!QSF_calc_Video_Interlacement!" to base transcode calculations on, for '%~f1'"
		ECHO !DATE! !TIME! !check_QSF_failed! >> "!vrdlog!" 2>&1
		ECHO !DATE! !TIME! SRC file="%~f1" >> "!vrdlog!" 2>&1
		ECHO !DATE! !TIME! QSF_file="!QSF_File!" >> "!vrdlog!" 2>&1
		ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
		CALL :declare_FAILED "%~f1"
		CALL :get_date_time_String "end_date_time_QSF"
		REM ECHO "!py_exe!" "!Path_to_py_VRDTVSP_Calculate_Duration!" --start_datetime "!start_date_time_QSF!" --end_datetime "!end_date_time_QSF!" --prefix_id "QSF itself" >> "!vrdlog!" 2>&1
		"!py_exe!" "!Path_to_py_VRDTVSP_Calculate_Duration!" --start_datetime "!start_date_time_QSF!" --end_datetime "!end_date_time_QSF!" --prefix_id "QSF itself" >> "!vrdlog!" 2>&1
		goto :eof
	)
) ELSE (
	ECHO NO Footy words found in filename '!file_name_part!', FFMPEG_V_dg_deinterlace unchanged=!FFMPEG_V_dg_deinterlace!, NO footy variables set  >> "!vrdlog!" 2>&1
)
ECHO !DATE! !TIME! ----- Finish  Checking for and Calculating Footy variables ... >> "!vrdlog!" 2>&1

ECHO !DATE! !TIME! ----- Start Using These variables ... >> "!vrdlog!" 2>&1
ECHO QSF_calc_Video_Encoding="!QSF_calc_Video_Encoding!" >> "!vrdlog!" 2>&1
ECHO QSF_calc_Video_Interlacement="!QSF_calc_Video_Interlacement!" >> "!vrdlog!" 2>&1
ECHO set FFMPEG_ >> "!vrdlog!" 2>&1
set FFMPEG_ >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
ECHO set Footy_ >> "!vrdlog!" 2>&1
set Footy_ >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
ECHO set X_ >> "!vrdlog!" 2>&1
set X_ >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
ECHO set extra_ >> "!vrdlog!" 2>&1
set extra_ >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! ----- Finish Using These variables ... >> "!vrdlog!" 2>&1

ECHO !DATE! !TIME! ====================================================================================================================================================== >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! ====================================================================================================================================================== >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! Start FFMPEG Transcode of "!QSF_File!" into "!Target_File!" >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! ====================================================================================================================================================== >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! ====================================================================================================================================================== >> "!vrdlog!" 2>&1

ECHO !DATE! !TIME! FFMPEGVARS: Determining FFMPEG_ variables helpful in encoding from "!QSF_File!"  >> "!vrdlog!" 2>&1
IF /I "!QSF_calc_Video_Interlacement!" == "PROGRESSIVE" (
	ECHO !DATE! !TIME! FFMPEGVARS: PROGRESSIVE detected >> "!vrdlog!" 2>&1
	IF /I "!QSF_calc_Video_Encoding!" == "AVC" (
		REM Progressive AVC
		ECHO !DATE! !TIME! FFMPEGVARS: PROGRESSIVE AVC detected >> "!vrdlog!" 2>&1
		set "FFMPEG_V_dg_deinterlace=0"
		set "FFMPEG_V_dg_vpy_denoise="
		set "FFMPEG_V_dg_vpy_dsharpen="
		set "FFMPEG_V_G=25"
		IF /I "!Footy_found!" == "True" (
			ECHO !DATE! !TIME! FFMPEGVARS: PROGRESSIVE AVC FOOTY detected >> "!vrdlog!" 2>&1
			set "FFMPEG_V_dg_deinterlace=0"
			set "FFMPEG_V_dg_vpy_denoise="
			set "FFMPEG_V_dg_vpy_dsharpen="
			set "FFMPEG_V_G=25"
		)
	) ELSE IF /I "!QSF_calc_Video_Encoding!" == "MPEG2" (
		REM Progressive MPEG2
		ECHO !DATE! !TIME! FFMPEGVARS: PROGRESSIVE MPEG2 detected >> "!vrdlog!" 2>&1
		set "FFMPEG_V_dg_deinterlace=0"
		set "FFMPEG_V_dg_vpy_denoise=, dn_enable=3, dn_quality="good", dn_strength=0.06, dn_cstrength=0.06, dn_tthresh=75.0, dn_show=0"
		set "FFMPEG_V_dg_vpy_dsharpen=, sh_enable=1, sh_strength=0.3"
		set "FFMPEG_V_G=25"
		IF /I "!Footy_found!" == "True" (
			ECHO !DATE! !TIME! FFMPEGVARS: PROGRESSIVE MPEG2 FOOTY detected >> "!vrdlog!" 2>&1
			set "FFMPEG_V_dg_deinterlace=0"
			set "FFMPEG_V_dg_vpy_denoise=, dn_enable=3, dn_quality="good", dn_strength=0.04, dn_cstrength=0.04, dn_tthresh=75.0, dn_show=0"
			set "FFMPEG_V_dg_vpy_dsharpen=, sh_enable=1, sh_strength=0.3"
			set "FFMPEG_V_G=25"
		)
	) ELSE IF /I "!QSF_calc_Video_Encoding!" == "HEVC" (
		REM Progressive HEVC
		ECHO !DATE! !TIME! FFMPEGVARS: PROGRESSIVE HEVC detected >> "!vrdlog!" 2>&1
		set "FFMPEG_V_dg_deinterlace=0"
		set "FFMPEG_V_dg_vpy_denoise=, dn_enable=3, dn_quality="good", dn_strength=0.06, dn_cstrength=0.06, dn_tthresh=75.0, dn_show=0"
		set "FFMPEG_V_dg_vpy_dsharpen=, sh_enable=1, sh_strength=0.3"
		set "FFMPEG_V_G=25"
		IF /I "!Footy_found!" == "True" (
			ECHO !DATE! !TIME! FFMPEGVARS: PROGRESSIVE HEVC FOOTY detected >> "!vrdlog!" 2>&1
			set "FFMPEG_V_dg_deinterlace=0"
			set "FFMPEG_V_dg_vpy_denoise=, dn_enable=3, dn_quality="good", dn_strength=0.04, dn_cstrength=0.04, dn_tthresh=75.0, dn_show=0"
			set "FFMPEG_V_dg_vpy_dsharpen=, sh_enable=1, sh_strength=0.25"
			set "FFMPEG_V_G=25"
		)
	) ELSE IF /I "!QSF_calc_Video_Encoding!" == "VP9" (
		REM Progressive VP9
		ECHO !DATE! !TIME! FFMPEGVARS: PROGRESSIVE VP9 detected >> "!vrdlog!" 2>&1
		set "FFMPEG_V_vp9_deinterlace_mode="
		set "FFMPEG_V_G=25"
		IF /I "!Footy_found!" == "True" (
			ECHO !DATE! !TIME! FFMPEGVARS: PROGRESSIVE VP9 FOOTY detected >> "!vrdlog!" 2>&1
			set "FFMPEG_V_vp9_deinterlace_mode="
			set "FFMPEG_V_G=25"
		)
	) ELSE (
		REM UNKNOWN, assume Progressive MPEG2
		ECHO !DATE! !TIME! FFMPEGVARS: PROGRESSIVE UNKNOWN codec detected >> "!vrdlog!" 2>&1
		set "FFMPEG_V_dg_deinterlace=0"
		set "FFMPEG_V_dg_vpy_denoise=, dn_enable=3, dn_quality="good", dn_strength=0.06, dn_cstrength=0.06, dn_tthresh=75.0, dn_show=0"
		set "FFMPEG_V_dg_vpy_dsharpen=, sh_enable=1, sh_strength=0.3"
		set "FFMPEG_V_G=25"
		IF /I "!Footy_found!" == "True" (
			ECHO !DATE! !TIME! FFMPEGVARS: PROGRESSIVE UNKNOWN codec FOOTY detected >> "!vrdlog!" 2>&1
			set "FFMPEG_V_dg_deinterlace=0"
			set "FFMPEG_V_dg_vpy_denoise=, dn_enable=3, dn_quality="good", dn_strength=0.04, dn_cstrength=0.04, dn_tthresh=75.0, dn_show=0"
			set "FFMPEG_V_dg_vpy_dsharpen=, sh_enable=1, sh_strength=0.3"
			set "FFMPEG_V_G=25"
		)
	)
) ELSE IF /I "!QSF_calc_Video_Interlacement!" == "INTERLACED" (
	ECHO !DATE! !TIME! FFMPEGVARS: INTERLACED detected >> "!vrdlog!" 2>&1
	IF /I "!QSF_calc_Video_Encoding!" == "AVC" (
		REM Interlaced AVC
		ECHO !DATE! !TIME! FFMPEGVARS: INTERLACED AVC detected >> "!vrdlog!" 2>&1
		set "FFMPEG_V_dg_deinterlace=1"
		set "FFMPEG_V_dg_vpy_denoise=, dn_enable=3, dn_quality="good", dn_strength=0.06, dn_cstrength=0.06, dn_tthresh=75.0, dn_show=0"
		set "FFMPEG_V_dg_vpy_dsharpen=, sh_enable=1, sh_strength=0.3"
		set "FFMPEG_V_G=25"
		IF /I "!Footy_found!" == "True" (
			ECHO !DATE! !TIME! FFMPEGVARS: INTERLACED AVC FOOTY detected >> "!vrdlog!" 2>&1
			set "FFMPEG_V_dg_deinterlace=2"
			set "FFMPEG_V_dg_vpy_denoise=, dn_enable=3, dn_quality="good", dn_strength=0.04, dn_cstrength=0.04, dn_tthresh=75.0, dn_show=0"
			set "FFMPEG_V_dg_vpy_dsharpen=, sh_enable=1, sh_strength=0.25"
			set "FFMPEG_V_G=50"
		)
	) ELSE IF /I "!QSF_calc_Video_Encoding!" == "MPEG2" (
		REM Interlaced MPEG2
		ECHO !DATE! !TIME! FFMPEGVARS: INTERLACED MPEG2 detected >> "!vrdlog!" 2>&1
		set "FFMPEG_V_dg_deinterlace=1"
		set "FFMPEG_V_dg_vpy_denoise=, dn_enable=3, dn_quality="good", dn_strength=0.06, dn_cstrength=0.06, dn_tthresh=75.0, dn_show=0"
		set "FFMPEG_V_dg_vpy_dsharpen=, sh_enable=1, sh_strength=0.3"
		set "FFMPEG_V_G=25"
		IF /I "!Footy_found!" == "True" (
			ECHO !DATE! !TIME! FFMPEGVARS: INTERLACED MPEG2 FOOTY detected >> "!vrdlog!" 2>&1
			set "FFMPEG_V_dg_deinterlace=2"
			set "FFMPEG_V_dg_vpy_denoise=, dn_enable=3, dn_quality="good", dn_strength=0.04, dn_cstrength=0.04, dn_tthresh=75.0, dn_show=0"
			set "FFMPEG_V_dg_vpy_dsharpen=, sh_enable=1, sh_strength=0.3"
			set "FFMPEG_V_G=50"
		)
	) ELSE IF /I "!QSF_calc_Video_Encoding!" == "HEVC" (
		REM Interlaced HEVC
		ECHO !DATE! !TIME! FFMPEGVARS: INTERLACED HEVC detected >> "!vrdlog!" 2>&1
		set "FFMPEG_V_dg_deinterlace=1"
		set "FFMPEG_V_dg_vpy_denoise=, dn_enable=3, dn_quality="good", dn_strength=0.06, dn_cstrength=0.06, dn_tthresh=75.0, dn_show=0"
		set "FFMPEG_V_dg_vpy_dsharpen=, sh_enable=1, sh_strength=0.3"
		set "FFMPEG_V_G=25"
		IF /I "!Footy_found!" == "True" (
			ECHO !DATE! !TIME! FFMPEGVARS: INTERLACED HEVC FOOTY detected >> "!vrdlog!" 2>&1
			set "FFMPEG_V_dg_deinterlace=2"
			set "FFMPEG_V_dg_vpy_denoise=, dn_enable=3, dn_quality="good", dn_strength=0.04, dn_cstrength=0.04, dn_tthresh=75.0, dn_show=0"
			set "FFMPEG_V_dg_vpy_dsharpen=, sh_enable=1, sh_strength=0.25"
			set "FFMPEG_V_G=50"
		)
	) ELSE IF /I "!QSF_calc_Video_Encoding!" == "VP9" (
		REM Interlaced VP9
		ECHO !DATE! !TIME! FFMPEGVARS: INTERLACED VP9 detected >> "!vrdlog!" 2>&1
		set "FFMPEG_V_vp9_deinterlace_mode=0"
		set "FFMPEG_V_G=25"
		IF /I "!Footy_found!" == "True" (
			ECHO !DATE! !TIME! FFMPEGVARS: INTERLACED VP9 FOOTY detected >> "!vrdlog!" 2>&1
			set "FFMPEG_V_vp9_deinterlace_mode=1"
			set "FFMPEG_V_G=50"
		)
	) ELSE (
		REM UNKNOWN, assume Interlaced AVC
		ECHO !DATE! !TIME! FFMPEGVARS: INTERLACED UNKNOWN codec detected >> "!vrdlog!" 2>&1
		set "FFMPEG_V_dg_deinterlace=1"
		set "FFMPEG_V_dg_vpy_denoise=, dn_enable=3, dn_quality="good", dn_strength=0.06, dn_cstrength=0.06, dn_tthresh=75.0, dn_show=0"
		set "FFMPEG_V_dg_vpy_dsharpen=, sh_enable=1, sh_strength=0.3"
		set "FFMPEG_V_G=25"
		IF /I "!Footy_found!" == "True" (
			ECHO !DATE! !TIME! FFMPEGVARS: INTERLACED UNKNOWN codec FOOTY detected >> "!vrdlog!" 2>&1
			set "FFMPEG_V_dg_deinterlace=2"
			set "FFMPEG_V_dg_vpy_denoise=, dn_enable=3, dn_quality="good", dn_strength=0.04, dn_cstrength=0.04, dn_tthresh=75.0, dn_show=0"
			set "FFMPEG_V_dg_vpy_dsharpen=, sh_enable=1, sh_strength=0.25"
			set "FFMPEG_V_G=50"
		)
	)
)
REM ======================================================  Do the DGIndexNV ======================================================
REM re-use error checking variable check_QSF_failed even though we are not doing a QSF
IF QSF_calc_Video_Is_Progessive_AVC == "True" (
	ECHO !DATE! !TIME! QSF_calc_Video_Is_Progessive_AVC=!QSF_calc_Video_Is_Progessive_AVC! >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! DGIndexNV is NOT performed for Progressive-AVC where we just copy streams >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
) ELSE IF /I "!QSF_calc_Video_Encoding!" == "VP9" (
	REM vp9 not supported by DG tools, so do plain ffmpeg instead
	ECHO !DATE! !TIME! QSF_calc_Video_Is_Progessive_AVC=!QSF_calc_Video_Is_Progessive_AVC! >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! DGIndexNV is NOT supported by DG so is NOT performed for VP9 where we instead use ffmpeg transcode ... with deinterlace if required >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
) ELSE (
	ECHO !DATE! !TIME! QSF_calc_Video_Is_Progessive_AVC=!QSF_calc_Video_Is_Progessive_AVC! >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! DGIndexNV WILL be performed for [AVC INTERLACED] [MPEG2 PROGRESSIVE] [MPEG2 INTERLACED] [HEVC PROGRESSIVE] [HEVC INTERLACED] and a .VPY will be created >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
	ECHO ======================================================  Start the DGIndexNV ====================================================== >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
	ECHO !dgindexNVexe64! -version >> "!vrdlog!" 2>&1
	!dgindexNVexe64! -version  >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
	ECHO !dgindexNVexe64! -i "!QSF_File!" -e -h -o "!DGI_file!" >> "!vrdlog!" 2>&1
	!dgindexNVexe64! -i "!QSF_File!" -e -h -o "!DGI_file!" >> "!vrdlog!" 2>&1
	SET EL=!ERRORLEVEL!
	IF /I "!EL!" NEQ "0" (
		set "check_QSF_failed=********** ERROR: Error Number '!EL!' returned from '!dgindexNVexe64!'"
		ECHO !DATE! !TIME! !check_QSF_failed! >> "!vrdlog!" 2>&1
		ECHO !DATE! !TIME! SRC file="%~f1" >> "!vrdlog!" 2>&1
		ECHO !DATE! !TIME! QSF_file="!QSF_File!" >> "!vrdlog!" 2>&1
		ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
		ECHO !DATE! !TIME! **********  Declaring FAILED:  "%~f1" >> "!vrdlog!" 2>&1
		ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
		CALL :declare_FAILED "%~f1"
		goto :eof
	)
	ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
	ECHO TYPE "!DGI_autolog!" >> "!vrdlog!" 2>&1
	TYPE "!DGI_autolog!" >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
	ECHO TYPE "!DGI_file!" >> "!vrdlog!" 2>&1
	REM TYPE "!DGI_file!" >> "!vrdlog!" 2>&1
	REM ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
	ECHO DEL /F "!DGI_autolog!" >> "!vrdlog!" 2>&1
	DEL /F "!DGI_autolog!" >> "!vrdlog!" 2>&1
	ECHO ======================================================  Finish the DGIndexNV ====================================================== >> "!vrdlog!" 2>&1
	ECHO ======================================================  Start Create a VPY_file ====================================================== >> "!vrdlog!" 2>&1
	DEL /F "!VPY_file!">NUL 2>&1
	ECHO import vapoursynth as vs		# this allows use of constants eg vs.YUV420P8 >> "!VPY_file!" 2>&1
	ECHO from vapoursynth import core	# actual vapoursynth core >> "!VPY_file!" 2>&1
	ECHO #import functool >> "!VPY_file!" 2>&1
	ECHO #import mvsfunc as mvs			# this relies on the .py residing at the VS folder root level - see run_vsrepo.bat >> "!VPY_file!" 2>&1
	ECHO #import havsfunc as haf		# this relies on the .py residing at the VS folder root level - see run_vsrepo.bat >> "!VPY_file!" 2>&1
	ECHO core.std.LoadPlugin^(r'!vs_root!\DGIndex\DGDecodeNV.dll'^) # do it like gonca https://forum.doom9.org/showthread.php?p=1877765#post1877765 >> "!VPY_file!" 2>&1
	ECHO core.avs.LoadPlugin^(r'!vs_root!\DGIndex\DGDecodeNV.dll'^) # do it like gonca https://forum.doom9.org/showthread.php?p=1877765#post1877765 >> "!VPY_file!" 2>&1
	ECHO # NOTE: deinterlace=1, use_top_field=True for "Interlaced"/"TFF" >> "!VPY_file!" 2>&1
	ECHO # NOTE: deinterlace=2, use_top_field=True for "Interlaced"/"TFF" >> "!VPY_file!" 2>&1
	ECHO # dn_enable=x DENOISE >> "!VPY_file!" 2>&1
	ECHO # default 0  0: disabled  1: spatial denoising only  2: temporal denoising only  3: spatial and temporal denoising >> "!VPY_file!" 2>&1
	ECHO # dn_quality="x" default "good"    "good" "better" "best" ... "best" halves the speed compared pre-CUDASynth >> "!VPY_file!" 2>&1
	ECHO video = core.dgdecodenv.DGSource^( r'!DGI_file!', deinterlace=!FFMPEG_V_dg_deinterlace!, use_top_field=!FFMPEG_V_dg_use_TFF!, use_pf=False !FFMPEG_V_dg_vpy_denoise! !FFMPEG_V_dg_vpy_dsharpen! ^) >> "!VPY_file!" 2>&1
	ECHO #video = vs.core.text.ClipInfo^(video^) >> "!VPY_file!" 2>&1
	ECHO video.set_output^(^) >> "!VPY_file!" 2>&1
	ECHO TYPE "!VPY_file!" >> "!vrdlog!" 2>&1
	TYPE "!VPY_file!" >> "!vrdlog!" 2>&1
	ECHO ======================================================  Finish Create a VPY_file ====================================================== >> "!vrdlog!" 2>&1
)
IF QSF_calc_Video_Is_Progessive_AVC == "True" (
	REM for Progressive AVC just copy video stream and transcode audio stream
	ECHO ======================================================  Start Run FFMPEG copy video stream ====================================================== >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! ********** QSF_calc_Video_Is_Progessive_AVC=!QSF_calc_Video_Is_Progessive_AVC! ... so IS Progressive-AVC ... just copy video stream and transcode audio >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! ********** IS Progressive-AVC ... use ffmpeg to just copy video stream and transcode audio >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
	REM ffmpeg throws an error due to "-c:v copy" and this together: -vf "setdar="!QSF_MI_V_DisplayAspectRatio_String_slash!"
	REM ffmpeg throws an error due to "-c:v copy" and this together: -profile:v high -level 5.2 
	set "FFMPEG_cmd="!ffmpegexe64!""
	set "FFMPEG_cmd=!FFMPEG_cmd! -hide_banner -v info -nostats"
	set "FFMPEG_cmd=!FFMPEG_cmd! -i "!QSF_File!" -probesize 100M -analyzeduration 100M"
	set "FFMPEG_cmd=!FFMPEG_cmd! -c:v copy -fps_mode passthrough"
	set "FFMPEG_cmd=!FFMPEG_cmd! -strict experimental"
	set "FFMPEG_cmd=!FFMPEG_cmd! -sws_flags lanczos+accurate_rnd+full_chroma_int+full_chroma_inp"
	set "FFMPEG_cmd=!FFMPEG_cmd! -movflags +faststart+write_colr"
	set "FFMPEG_cmd=!FFMPEG_cmd! -c:a libfdk_aac -b:a 256k -ar 48000"
	set "FFMPEG_cmd=!FFMPEG_cmd! -y "!Target_File!""
	ECHO !FFMPEG_cmd! >> "!vrdlog!" 2>&1
 	!FFMPEG_cmd! >> "!vrdlog!" 2>&1
 	SET EL=!ERRORLEVEL!
	IF /I "!EL!" NEQ "0" (
		set "check_QSF_failed=********** ERROR: Error Number '!EL!' returned from '!ffmpegexe64!' copy video stream "
		ECHO !DATE! !TIME! !check_QSF_failed! >> "!vrdlog!" 2>&1
		ECHO !DATE! !TIME! SRC file="%~f1" >> "!vrdlog!" 2>&1
		ECHO !DATE! !TIME! QSF_file="!QSF_File!" >> "!vrdlog!" 2>&1
		ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
		CALL :declare_FAILED "%~f1"
		goto :eof
	)
	ECHO ======================================================  Finish Run FFMPEG copy video stream ====================================================== >> "!vrdlog!" 2>&1
) ELSE IF /I "!QSF_calc_Video_Encoding!" == "VP9" (
	REM [VP9 PROGRESSIVE] [VP9 INTERLACED] transcode video and transcode audio stream
	REM
	REM vp9 without bwdif or yadif deinterlacers
	REM -filter_complex "[0:v]unsharp=lx=3:ly=3:la=0.5:cx=3:cy=3:ca=0.5,format=pix_fmts=yuv420p,setdar='!SRC_MI_V_DisplayAspectRatio_String_slash!'"
	REM
	REM vp9 with bwdif
	REM -filter_complex "[0:v]bwdif=mode=0:parity=0:deint=0,unsharp=lx=3:ly=3:la=0.5:cx=3:cy=3:ca=0.5,format=pix_fmts=yuv420p,setdar='!SRC_MI_V_DisplayAspectRatio_String_slash!'"
	REM		mode	The interlacing mode to adopt. It accepts one of the following values:
	REM			0, send_frame	Output one frame for each frame. Single framerate.
	REM			1, send_field	Output one frame for each field. Double framerate.
	REM			The default value is send_field.
	REM		parity	The picture field parity assumed for the input interlaced video. It accepts one of the following values:
	REM			0, tff	Assume the top field is first.
	REM			1, bff	Assume the bottom field is first.
	REM			-1, auto	Enable automatic detection of field parity.
	REM			The default value is auto. If the interlacing is unknown or the decoder does not export this information, top field first will be assumed.
	REM		deint	Specify which frames to deinterlace. Accepts one of the following values:
	REM			0, all	Deinterlace all frames.
	REM			1, interlaced	Only deinterlace frames marked as interlaced.
	REM			The default value is all.
	REM
	REM vp9 with yadif
	REM -filter_complex "[0:v]yadif=mode=0:parity=0:deint=0,unsharp=lx=3:ly=3:la=0.5:cx=3:cy=3:ca=0.5,format=pix_fmts=yuv420p,setdar='!SRC_MI_V_DisplayAspectRatio_String_slash!'"
	REM Deinterlace the input video ("yadif" means "yet another deinterlacing filter").
	REM It accepts the following parameters:
	REM mode	The interlacing mode to adopt. It accepts one of the following values:
	REM 	0, send_frame	Output one frame for each frame.
	REM 	1, send_field	Output one frame for each field.
	REM 	2, send_frame_nospatial	Like send_frame, but it skips the spatial interlacing check.
	REM 	3, send_field_nospatial	Like send_field, but it skips the spatial interlacing check.
	REM 	The default value is send_frame.
	REM parity	The picture field parity assumed for the input interlaced video. It accepts one of the following values:
	REM 	0, tff	Assume the top field is first.
	REM 	1, bff	Assume the bottom field is first.
	REM 	-1, auto	Enable automatic detection of field parity.
	REM 	The default value is auto. If the interlacing is unknown or the decoder does not export this information, top field first will be assumed.
	REM deint	Specify which frames to deinterlace. Accepts one of the following values:
	REM 	0, all	Deinterlace all frames.
	REM 	1, interlaced	Only deinterlace frames marked as interlaced.
	REM 	The default value is all.
	REM
	set "FFMPEG_V_vp9_deinterlacer=bwdif"
	REM set "FFMPEG_V_vp9_deinterlacer=yadif"
	IF /I "!FFMPEG_V_vp9_deinterlace_mode!" == "" (
		set "FFMPEG_V_vp9_fc=-filter_complex "[0:v]unsharp=lx=3:ly=3:la=0.5:cx=3:cy=3:ca=0.5,format=pix_fmts=yuv420p,setdar='!SRC_MI_V_DisplayAspectRatio_String_slash!'""
	) ELSE (
		set "FFMPEG_V_vp9_fc=-filter_complex "[0:v]!FFMPEG_V_vp9_deinterlacer!=mode=!FFMPEG_V_vp9_deinterlace_mode!:parity=!FFMPEG_V_vp9_deinterlace_parity!:deint=0,unsharp=lx=3:ly=3:la=0.5:cx=3:cy=3:ca=0.5,format=pix_fmts=yuv420p,setdar='!SRC_MI_V_DisplayAspectRatio_String_slash!'""
	)
	ECHO ======================================================  Start Run FFMPEG VP9 transcode ====================================================== >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! ********** QSF_calc_Video_Is_Progessive_AVC=!QSF_calc_Video_Is_Progessive_AVC! ... so NOT Progressive-AVC ... transcode VP9 video and transcode audio >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! ********** NOT Progressive-AVC ... use ffmpeg and a .vpy to transcode video and transcode audio >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
	set "FFMPEG_cmd="!ffmpegexe64!""
	set "FFMPEG_cmd=!FFMPEG_cmd! -hide_banner -v info -nostats"
	REM set "FFMPEG_cmd=!FFMPEG_cmd! -hide_banner -v verbose -nostats"
	REM set "FFMPEG_cmd=!FFMPEG_cmd! -hide_banner -v debug -nostats"
	set "FFMPEG_cmd=!FFMPEG_cmd! -i "!QSF_File!" -probesize 100M -analyzeduration 100M"
	set "FFMPEG_cmd=!FFMPEG_cmd! !FFMPEG_V_vp9_fc!"
	set "FFMPEG_cmd=!FFMPEG_cmd! -fps_mode passthrough -sws_flags lanczos+accurate_rnd+full_chroma_int+full_chroma_inp -strict experimental"
	set "FFMPEG_cmd=!FFMPEG_cmd! -c:v h264_nvenc -pix_fmt nv12 -preset p7 -multipass fullres -forced-idr 1 -g !FFMPEG_V_G! -coder:v cabac"
	set "FFMPEG_cmd=!FFMPEG_cmd! !FFMPEG_V_RTX2060super_extra_flags!"
	set "FFMPEG_cmd=!FFMPEG_cmd! -rc:v vbr !FFMPEG_V_final_cq_options!"
	set "FFMPEG_cmd=!FFMPEG_cmd! -b:v !FFMPEG_V_Target_BitRate! -minrate:v !FFMPEG_V_Target_Minimum_BitRate! -maxrate:v !FFMPEG_V_Target_Maximum_BitRate! -bufsize !FFMPEG_V_Target_Maximum_BitRate!"
	set "FFMPEG_cmd=!FFMPEG_cmd! -strict experimental"
	REM set "FFMPEG_cmd=!FFMPEG_cmd! -sws_flags lanczos+accurate_rnd+full_chroma_int+full_chroma_inp"
	set "FFMPEG_cmd=!FFMPEG_cmd! -profile:v high -level 5.2 -movflags +faststart+write_colr"
	set "FFMPEG_cmd=!FFMPEG_cmd! -c:a libfdk_aac -b:a 256k -ar 48000"
	set "FFMPEG_cmd=!FFMPEG_cmd! -y "!Target_File!""
	ECHO !FFMPEG_cmd! >> "!vrdlog!" 2>&1
 	!FFMPEG_cmd! >> "!vrdlog!" 2>&1
 	SET EL=!ERRORLEVEL!
	IF /I "!EL!" NEQ "0" (
		set "check_QSF_failed=********** ERROR: Error Number '!EL!' returned from '!ffmpegexe64!' transcode VP9 video and transcode audio"
		ECHO !DATE! !TIME! !check_QSF_failed! >> "!vrdlog!" 2>&1
		ECHO !DATE! !TIME! SRC file="%~f1" >> "!vrdlog!" 2>&1
		ECHO !DATE! !TIME! QSF_file="!QSF_File!" >> "!vrdlog!" 2>&1
		ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
		CALL :declare_FAILED "%~f1"
		goto :eof
	)
	ECHO ======================================================  Finish Run FFMPEG VP9 transcode ====================================================== >> "!vrdlog!" 2>&1
) ELSE (
	REM for the rest:
	REM [AVC INTERLACED] [MPEG2 PROGRESSIVE] [MPEG2 INTERLACED] [HEVC PROGRESSIVE] [HEVC INTERLACED] transcode video and transcode audio stream
	ECHO ======================================================  Start Run FFMPEG transcode ====================================================== >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! ********** QSF_calc_Video_Is_Progessive_AVC=!QSF_calc_Video_Is_Progessive_AVC! ... so NOT Progressive-AVC ... transcode video and transcode audio >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! ********** NOT Progressive-AVC ... use ffmpeg and a .vpy to transcode video and transcode audio >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
	REM set "FFMPEG_vspipe_cmd="!vspipeexe64!" --container y4m --filter-time "!VPY_file!" -"
	set "FFMPEG_vspipe_cmd="!vspipeexe64!" --container y4m "!VPY_file!" -"
	set "FFMPEG_cmd="!ffmpegexe64!""
	set "FFMPEG_cmd=!FFMPEG_cmd! -hide_banner -v info -nostats"
	REM set "FFMPEG_cmd=!FFMPEG_cmd! -hide_banner -v verbose -nostats"
	set "FFMPEG_cmd=!FFMPEG_cmd! -f yuv4mpegpipe -i pipe: -probesize 100M -analyzeduration 100M"
	set "FFMPEG_cmd=!FFMPEG_cmd! -i "!QSF_File!""
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
	set "FFMPEG_cmd=!FFMPEG_cmd! -c:a libfdk_aac -b:a 256k -ar 48000"
	set "FFMPEG_cmd=!FFMPEG_cmd! -y "!Target_File!""
	REM
	REM ECHO "!vspipeexe64!" -h >> "!vrdlog!" 2>&1
	REM "!vspipeexe64!" -h >> "!vrdlog!" 2>&1
	ECHO "!vspipeexe64!" --version  >> "!vrdlog!" 2>&1
	"!vspipeexe64!" --version  >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
	ECHO "!vspipeexe64!" --info "!VPY_file!" >> "!vrdlog!" 2>&1
	"!vspipeexe64!" --info "!VPY_file!" >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
	REM ECHO "!vspipeexe64!" --filter-time --progress --container y4m "!VPY_file!" -- >> "!vrdlog!" 2>&1
	REM "!vspipeexe64!" --filter-time --progress --container y4m "!VPY_file!" -- >> "!vrdlog!" 2>&1
	REM ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
	ECHO FFMPEG_vspipe_cmd='!FFMPEG_vspipe_cmd!' >> "!vrdlog!" 2>&1
	ECHO FFMPEG_cmd='!FFMPEG_cmd!' >> "!vrdlog!" 2>&1
	REM
	ECHO DEL /F "!temp_cmd_file!">NUL 2>&1
	ECHO REM Echo status will be in: "!temp_cmd_file_echo_status!">>"!temp_cmd_file!" 2>&1
    ECHO @ECHO^>"!temp_cmd_file_echo_status!">>"!temp_cmd_file!" 2>&1
    ECHO TYPE "!temp_cmd_file_echo_status!">>"!temp_cmd_file!" 2>&1
    ECHO SET /p initial_echo_status=^<"!temp_cmd_file_echo_status!">>"!temp_cmd_file!" 2>&1
	ECHO @ECHO ON>>"!temp_cmd_file!" 2>&1
	ECHO !FFMPEG_vspipe_cmd!^^^|!FFMPEG_cmd!>>"!temp_cmd_file!" 2>&1
	ECHO set "EL=^!ERRORLEVEL^!">>"!temp_cmd_file!" 2>&1
    ECHO @ECHO %%initial_echo_status%%>>"!temp_cmd_file!" 2>&1
    ECHO SET "initial_echo_status=">>"!temp_cmd_file!" 2>&1
	ECHO goto :eof>>"!temp_cmd_file!" 2>&1
	REM
	ECHO !DATE! !TIME! ****************************** >> "!vrdlog!" 2>&1
	ECHO DEL /F "!temp_cmd_file_echo_status!">NUL 2>&1
	ECHO TYPE "!temp_cmd_file!" >> "!vrdlog!" 2>&1
	TYPE "!temp_cmd_file!" >> "!vrdlog!" 2>&1
	ECHO CALL "!temp_cmd_file!" >> "!vrdlog!" 2>&1
	CALL "!temp_cmd_file!" >> "!vrdlog!" 2>&1
	ECHO DEL /F "!temp_cmd_file_echo_status!">NUL 2>&1
	ECHO !DATE! !TIME! ****************************** >> "!vrdlog!" 2>&1
	IF /I "!EL!" NEQ "0" (
		set "check_QSF_failed=********** ERROR: Error Number '!EL!' returned from '!ffmpegexe64!' transcode"
		ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
		ECHO !DATE! !TIME! !check_QSF_failed! >> "!vrdlog!" 2>&1
		ECHO !DATE! !TIME! SRC file="%~f1" >> "!vrdlog!" 2>&1
		dir /s /b "%~f1" >> "!vrdlog!" 2>&1
		ECHO !DATE! !TIME! QSF_file="!QSF_File!" >> "!vrdlog!" 2>&1
		dir /s /b "!QSF_File!" >> "!vrdlog!" 2>&1
		ECHO !DATE! !TIME! DGI_file="!DGI_file!" >> "!vrdlog!" 2>&1
		dir /s /b "!DGI_file!" >> "!vrdlog!" 2>&1
		ECHO !DATE! !TIME! VPY_file="!VPY_file!" >> "!vrdlog!" 2>&1
		dir /s /b "!VPY_file!" >> "!vrdlog!" 2>&1
		ECHO !DATE! !TIME! temp_cmd_file="!temp_cmd_file!" >> "!vrdlog!" 2>&1
		dir /s /b "!temp_cmd_file!" >> "!vrdlog!" 2>&1
		ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
		CALL :declare_FAILED "%~f1"
		goto :eof
	)
	ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
	ECHO ======================================================  Finish Run FFMPEG transcode ====================================================== >> "!vrdlog!" 2>&1
)

ECHO !DATE! !TIME! ********** Start Moving "%~f1" to "!done_TS_Folder!" >> "!vrdlog!" 2>&1
ECHO MOVE /Y "%~f1" "!done_TS_Folder!" >> "!vrdlog!" 2>&1
MOVE /Y "%~f1" "!done_TS_Folder!" >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! ********** Finish Moving "%~f1" to "!done_TS_Folder!" >> "!vrdlog!" 2>&1

ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
ECHO DEL /F !scratch_Folder!*.tmp >> "!vrdlog!" 2>&1
DEL /F !scratch_Folder!*.tmp >> "!vrdlog!" 2>&1
ECHO DEL /F "!QSF_file!" >> "!vrdlog!" 2>&1
DEL /F "!QSF_file!" >> "!vrdlog!" 2>&1
ECHO DEL /F "!VPY_file!" >> "!vrdlog!" 2>&1
DEL /F "!VPY_file!" >> "!vrdlog!" 2>&1
ECHO DEL /F "!DGI_file!" >> "!vrdlog!" 2>&1
DEL /F "!DGI_file!" >> "!vrdlog!" 2>&1
ECHO DEL /F "!DGI_autolog!" >> "!vrdlog!" 2>&1
DEL /F "!DGI_autolog!" >> "!vrdlog!" 2>&1
ECHO DEL /F "!temp_cmd_file!" >> "!vrdlog!" 2>&1
DEL /F "!temp_cmd_file!" >> "!vrdlog!" 2>&1

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
REM ECHO IN set_vrd_qsf_paths default_qsf_timeout_minutes_VRD5=!default_qsf_timeout_minutes_VRD5!   default_qsf_timeout_seconds_VRD5=!default_qsf_timeout_seconds_VRD5! >> "!vrdlog!" 2>&1
REM ECHO IN set_vrd_qsf_paths default_qsf_timeout_minutes_VRD6=!default_qsf_timeout_minutes_VRD6!   default_qsf_timeout_seconds_VRD6=!default_qsf_timeout_seconds_VRD6! >> "!vrdlog!" 2>&1
set "Path_to_vrd="
set "Path_to_vrd_vp_vbs="
set "profile_name_for_qsf_mpeg2="
set "profile_name_for_qsf_h264="
set "profile_name_for_qsf_h265="
set "profile_name_for_qsf_vp9="
IF /I "!requested_vrd_version!" == "6" (
   set "Path_to_vrd=!Path_to_vrd6!"
   set "Path_to_vrd_vp_vbs=!Path_to_vp_vbs_vrd6!"
   set "profile_name_for_qsf_mpeg2=!profile_name_for_qsf_mpeg2_vrd6!"
   set "profile_name_for_qsf_h264=!profile_name_for_qsf_h264_vrd6!"
   set "profile_name_for_qsf_h265="
   set "profile_name_for_qsf_vp9="
   set "_vrd_version_primary=6"
   set "_vrd_version_fallback=5"
   set "_vrd_qsf_timeout_minutes=!default_qsf_timeout_minutes_VRD6!"
   set "_vrd_qsf_timeout_seconds=!default_qsf_timeout_seconds_VRD6!"
) ELSE IF /I "!requested_vrd_version!" == "5" (
   set "Path_to_vrd=!Path_to_vrd5!"
   set "Path_to_vrd_vp_vbs=!Path_to_vp_vbs_vrd5!"
   set "profile_name_for_qsf_mpeg2=!profile_name_for_qsf_mpeg2_vrd5!"
   set "profile_name_for_qsf_h264=!profile_name_for_qsf_h264_vrd5!"
   set "profile_name_for_qsf_h265="
   set "profile_name_for_qsf_vp9="
   set "_vrd_version_primary=5"
   set "_vrd_version_fallback=6"
   set "_vrd_qsf_timeout_minutes=!default_qsf_timeout_minutes_VRD5!"
   set "_vrd_qsf_timeout_seconds=!default_qsf_timeout_seconds_VRD5!"
) ELSE (
   ECHO "VRD Version must be set to 5 or 6 not '!requested_vrd_version!' (_vrd_version_primary=!_vrd_version_primary! _vrd_version_fallback=!_vrd_version_fallback!)... EXITING" >> "!vrdlog!" 2>&1
   !xPAUSE!
   exit
)
REM ECHO EXITING set_vrd_qsf_paths _vrd_qsf_timeout_minutes=!_vrd_qsf_timeout_minutes!   _vrd_qsf_timeout_seconds=!_vrd_qsf_timeout_seconds! >> "!vrdlog!" 2>&1
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

REM ECHO IN run_cscript_qsf_with_timeout  >> "!vrdlog!" 2>&1
REM ECHO 1 "%~1"	VideoReDo version number to use >> "!vrdlog!" 2>&1
REM ECHO 2 "%~2"	fully qualified filename of the SRC input usually a .TS file >> "!vrdlog!" 2>&1
REM ECHO 3 "%~3"	fully qualified filename of name of QSF file to create >> "!vrdlog!" 2>&1
REM ECHO 4 "%~4"	qsf prefix for variables output from the VideoReDo QSF  >> "!vrdlog!" 2>&1

CALL :get_date_time_String "start_date_time_QSF_with_timeout"

set "requested_vrd_version=%~1"
set "source_filename=%~f2"
set "qsf_filename=%~f3"
set "requested_qsf_xml_prefix=%~4"

REM Preset the error flag to nothing
set "check_QSF_failed="

REM Reset VRD QSF defaults to the requested version. Note _vrd_version_primary and _vrd_version_fallback.
ECHO CALL :set_vrd_qsf_paths "!requested_vrd_version!" >> "!vrdlog!" 2>&1
CALL :set_vrd_qsf_paths "!requested_vrd_version!"

REM ECHO ???????????????????????????????????????????????????????????????? >> "!vrdlog!" 2>&1
REM ECHO QSF cscript timeout _vrd_qsf_timeout_seconds is !_vrd_qsf_timeout_seconds! seconds ..." >> "!vrdlog!" 2>&1
REM ECHO QSF VBS     timeout _vrd_qsf_timeout_minutes is !_vrd_qsf_timeout_minutes! minutes ..." >> "!vrdlog!" 2>&1
REM ECHO "_vrd_version_primary=!_vrd_version_primary!" >> "!vrdlog!" 2>&1
REM ECHO "_vrd_version_fallback=!_vrd_version_fallback!" >> "!vrdlog!" 2>&1
REM ECHO ???????????????????????????????????????????????????????????????? >> "!vrdlog!" 2>&1

REM Immediately choose the filename extension base on SRC_ variables and variables set by :set_vrd_qsf_paths
IF /I "!SRC_calc_Video_Encoding!" == "AVC" (
	set "qsf_profile=!profile_name_for_qsf_h264!"
	set "qsf_extension=!extension_h264!"
) ELSE IF /I "!SRC_calc_Video_Encoding!" == "MPEG2" (
	set "qsf_profile=!profile_name_for_qsf_mpeg2!"
	set "qsf_extension=!extension_mpeg2!"
) ELSE IF /I "!SRC_calc_Video_Encoding!" == "HEVC" (
	set "qsf_profile=!profile_name_for_qsf_h265!"
	set "qsf_extension=!extension_h265!"
) ELSE IF /I "!SRC_calc_Video_Encoding!" == "vp9" (
	set "qsf_profile=!profile_name_for_qsf_vp9!"
	set "qsf_extension=!extension_vp9!"
) ELSE (
	set "check_QSF_failed=********** ERROR: run_cscript_qsf_with_timeout mediainfo format !SRC_calc_Video_Encoding! neither 'AVC' nor 'MPEG2' for !source_filename!"
	ECHO !DATE! !TIME! !check_QSF_failed! >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! **********  Declaring as FAILED: "%~f2" >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
	goto :eof
)
REM ECHO "SRC_calc_Video_Encoding=!SRC_calc_Video_Encoding!" >> "!vrdlog!" 2>&1
REM ECHO "SRC_calc_Video_Interlacement=!SRC_calc_Video_Interlacement!" >> "!vrdlog!" 2>&1
REM ECHO "SRC_calc_Video_FieldFirst=!SRC_calc_Video_FieldFirst!" >> "!vrdlog!" 2>&1
REM ECHO "requested_vrd_version=!requested_vrd_version!" >> "!vrdlog!" 2>&1
REM ECHO "_vrd_version_primary=!_vrd_version_primary!" >> "!vrdlog!" 2>&1
REM ECHO "_vrd_version_fallback=!_vrd_version_fallback!" >> "!vrdlog!" 2>&1
REM ECHO "_vrd_qsf_timeout_minutes=!_vrd_qsf_timeout_minutes!" >> "!vrdlog!" 2>&1
REM ECHO "_vrd_qsf_timeout_seconds=!_vrd_qsf_timeout_minutes!" >> "!vrdlog!" 2>&1
REM ECHO "qsf_profile=!qsf_profile!" >> "!vrdlog!" 2>&1
REM ECHO "qsf_extension=!qsf_extension!" >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! ====================================================================================================================================================== >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! Start QSF of file: "!source_filename!" >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! Input: Video Codec: '!SRC_FF_V_codec_name!' ScanType: '!SRC_calc_Video_Interlacement!' ScanOrder: '!SRC_calc_Video_FieldFirst!' WxH: !SRC_MI_V_Width!x!SRC_MI_V_HEIGHT! dar:'!SRC_FF_V_display_aspect_ratio_slash!' and '!SRC_MI_V_DisplayAspectRatio_String_slash!' >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME!        Audio Codec: '!SRC_FF_A_codec_name!' Audio_Delay_ms: '!SRC_MI_A_Audio_Delay!' Video_Delay_ms: '!SRC_MI_A_Video_Delay!' Bitrate: !SRC_MI_V_BitRate! >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! _vrd_version_primary='!_vrd_version_primary!' _vrd_version_fallback=!_vrd_version_fallback!' qsf_profile=!qsf_profile!' qsf_extension='!qsf_extension!' >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! ====================================================================================================================================================== >> "!vrdlog!" 2>&1

REM Delete the QSF target and relevant log files before doing the QSF
ECHO DEL /F "!qsf_filename!"  >> "!vrdlog!" 2>&1
DEL /F "!qsf_filename!"  >> "!vrdlog!" 2>&1
ECHO DEL /F "!vrd5_logfiles!" >> "!vrdlog!" 2>&1
DEL /F "!vrd5_logfiles!" >> "!vrdlog!" 2>&1
ECHO DEL /F "!vrd6_logfiles!" >> "!vrdlog!" 2>&1
DEL /F "!vrd6_logfiles!" >> "!vrdlog!" 2>&1
ECHO DEL /F "!temp_cmd_file!" >> "!vrdlog!" 2>&1
DEL /F "!temp_cmd_file!" >> "!vrdlog!" 2>&1

REM CSCRIPT uses '_vrd_qsf_timeout_seconds' and VBS uses '_vrd_qsf_timeout_minutes' created by ':set_vrd_qsf_paths' 		also see https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/cscript
ECHO cscript //nologo /t:!_vrd_qsf_timeout_seconds! "!Path_to_vbs_VRDTVSP_Run_QSF_with_v5_or_v6!" "!_vrd_version_primary!" "!source_filename!" "!qsf_filename!" "!qsf_profile!" "!temp_cmd_file!" "!requested_qsf_xml_prefix!" "!SRC_MI_V_BitRate!" "!_vrd_qsf_timeout_minutes!" >> "!vrdlog!" 2>&1
cscript //nologo /t:!_vrd_qsf_timeout_seconds! "!Path_to_vbs_VRDTVSP_Run_QSF_with_v5_or_v6!" "!_vrd_version_primary!" "!source_filename!" "!qsf_filename!" "!qsf_profile!" "!temp_cmd_file!" "!requested_qsf_xml_prefix!" "!SRC_MI_V_BitRate!" "!_vrd_qsf_timeout_minutes!" >> "!vrdlog!" 2>&1
SET EL=!ERRORLEVEL!
IF /I "!EL!" NEQ "0" (
	set "check_QSF_failed=********** ERROR: run_cscript_qsf_with_timeout QSF Error '!EL!' returned from cscript QSF"
	ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! !check_QSF_failed! >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
) ELSE if NOT exist "!qsf_filename!" ( 
	set "check_QSF_failed=********** ERROR: run_cscript_qsf_with_timeout QSF Error QSF file not created: '!qsf_filename!'"
	ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! !check_QSF_failed! >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
) ELSE if NOT exist "!temp_cmd_file!" ( 
	set "check_QSF_failed=********** ERROR: run_cscript_qsf_with_timeout QSF Error Temp cmd file not created: '!temp_cmd_file!'"
	ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! !check_QSF_failed! >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
)
IF /I NOT "!check_QSF_failed!" == "" (
	ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! ********** FAILED: run_cscript_qsf_with_timeout "%~f1" >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
	goto :eof
)

REM If it got to here then the QSF worked. Run the .cmd file it created so we see the !requested_qsf_xml_prefix! variables created by the QSF
ECHO !DATE! !TIME! ****************************** >> "!vrdlog!" 2>&1
ECHO TYPE "!temp_cmd_file!" >> "!vrdlog!" 2>&1
TYPE "!temp_cmd_file!" >> "!vrdlog!" 2>&1
ECHO call "!temp_cmd_file!" >> "!vrdlog!" 2>&1
call "!temp_cmd_file!" >> "!vrdlog!" 2>&1
ECHO DEL /F "!temp_cmd_file!" >> "!vrdlog!" 2>&1
DEL /F "!temp_cmd_file!" >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! ****************************** >> "!vrdlog!" 2>&1

REM ECHO +++++++++ >> "!vrdlog!" 2>&1
REM ECHO set !requested_qsf_xml_prefix! >> "!vrdlog!" 2>&1
REM set !requested_qsf_xml_prefix! >> "!vrdlog!" 2>&1
REM ECHO +++++++++ >> "!vrdlog!" 2>&1

REM :gather_variables_from_media_file P =	the global prefix to use for this gather, one of "SRC_", "QSF_" "TARGET_"
CALL :gather_variables_from_media_file "!qsf_filename!" "QSF_" 

REM Reset VRD QSF defaults back to the original DEFAULT version. Note _vrd_version_primary and _vrd_version_fallback.
CALL :set_vrd_qsf_paths "!DEFAULT_vrd_version_primary!"

CALL :get_date_time_String "end_date_time_QSF_with_timeout"
REM ECHO "!py_exe!" "!Path_to_py_VRDTVSP_Calculate_Duration!" --start_datetime "!start_date_time_QSF_with_timeout!" --end_datetime "!end_date_time_QSF_with_timeout!" --prefix_id "run_cscript_qsf_with_timeout" >> "!vrdlog!" 2>&1
"!py_exe!" "!Path_to_py_VRDTVSP_Calculate_Duration!" --start_datetime "!start_date_time_QSF_with_timeout!" --end_datetime "!end_date_time_QSF_with_timeout!" --prefix_id "run_cscript_qsf_with_timeout" >> "!vrdlog!" 2>&1

goto :eof


REM ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM
:run_ffmpeg_stream_copy_instead_of_qsf
REM Input Parameters 
REM		1 	fully qualified filename of the SRC input (usually a .TS file)
REM 	2	fully qualified filename of name of QSF file to create
REM		3	qsf prefix for variables output from the VideoReDo QSF 
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

REM ECHO IN run_cscript_qsf_with_timeout  >> "!vrdlog!" 2>&1
REM ECHO 1 "%~1"	fully qualified filename of the SRC input usually a .TS file >> "!vrdlog!" 2>&1
REM ECHO 2 "%~2"	fully qualified filename of name of QSF file to create >> "!vrdlog!" 2>&1
REM ECHO 3 "%~3"	qsf prefix for variables output from the VideoReDo QSF  >> "!vrdlog!" 2>&1

CALL :get_date_time_String "start_date_time_ffmpeg_stream_copy_instead_of_qsf"

set "source_filename=%~f1"
set "qsf_filename=%~f2"
set "requested_qsf_xml_prefix=%~3"

REM Preset the error flag to nothing
set "check_QSF_failed="

REM Immediately choose the filename extension base on SRC_ variables and variables set by :set_vrd_qsf_paths
IF /I "!SRC_calc_Video_Encoding!" == "AVC" (
	set "qsf_profile=!profile_name_for_qsf_h264!"
	set "qsf_extension=!extension_h264!"
) ELSE IF /I "!SRC_calc_Video_Encoding!" == "MPEG2" (
	set "qsf_profile=!profile_name_for_qsf_mpeg2!"
	set "qsf_extension=!extension_mpeg2!"
) ELSE IF /I "!SRC_calc_Video_Encoding!" == "HEVC" (
	set "qsf_profile=!profile_name_for_qsf_h265!"
	set "qsf_extension=!extension_h265!"
) ELSE IF /I "!SRC_calc_Video_Encoding!" == "VP9" (
	set "qsf_profile=!profile_name_for_qsf_vp9!"
	set "qsf_extension=!extension_vp9!"
) ELSE (
	set "check_QSF_failed=********** ERROR: run_ffmpeg_stream_copy_instead_of_qsf mediainfo format !SRC_calc_Video_Encoding! neither 'AVC' nor 'MPEG2' nor "HEVC" nor "VP9" for !source_filename!"
	ECHO !DATE! !TIME! !check_QSF_failed! >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! **********  Declaring as FAILED: "%~f2" >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
	goto :eof
)
REM ECHO "SRC_calc_Video_Encoding=!SRC_calc_Video_Encoding!" >> "!vrdlog!" 2>&1
REM ECHO "SRC_calc_Video_Interlacement=!SRC_calc_Video_Interlacement!" >> "!vrdlog!" 2>&1
REM ECHO "SRC_calc_Video_FieldFirst=!SRC_calc_Video_FieldFirst!" >> "!vrdlog!" 2>&1
REM ECHO "qsf_profile=!qsf_profile!" >> "!vrdlog!" 2>&1
REM ECHO "qsf_extension=!qsf_extension!" >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! ====================================================================================================================================================== >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! Start non-QSF FFMPEG STREAM COPY of file: "!source_filename!" >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! Input: Video Codec: '!SRC_FF_V_codec_name!' ScanType: '!SRC_calc_Video_Interlacement!' ScanOrder: '!SRC_calc_Video_FieldFirst!' WxH: !SRC_MI_V_Width!x!SRC_MI_V_HEIGHT! dar:'!SRC_FF_V_display_aspect_ratio_slash!' and '!SRC_MI_V_DisplayAspectRatio_String_slash!' >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME!        Audio Codec: '!SRC_FF_A_codec_name!' Audio_Delay_ms: '!SRC_MI_A_Audio_Delay!' Video_Delay_ms: '!SRC_MI_A_Video_Delay!' Bitrate: !SRC_MI_V_BitRate! >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! _vrd_version_primary='!_vrd_version_primary!' _vrd_version_fallback=!_vrd_version_fallback!' qsf_profile=!qsf_profile!' qsf_extension='!qsf_extension!' >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! ====================================================================================================================================================== >> "!vrdlog!" 2>&1

REM Delete the QSF target and relevant log files before doing the non-QSF
ECHO DEL /F "!qsf_filename!"  >> "!vrdlog!" 2>&1
DEL /F "!qsf_filename!"  >> "!vrdlog!" 2>&1
ECHO DEL /F "!vrd5_logfiles!" >> "!vrdlog!" 2>&1
DEL /F "!vrd5_logfiles!" >> "!vrdlog!" 2>&1
ECHO DEL /F "!vrd6_logfiles!" >> "!vrdlog!" 2>&1
DEL /F "!vrd6_logfiles!" >> "!vrdlog!" 2>&1
ECHO DEL /F "!temp_cmd_file!" >> "!vrdlog!" 2>&1
DEL /F "!temp_cmd_file!" >> "!vrdlog!" 2>&1

ECHO ======================================================  Start Run non-QSF FFMPEG copy video and audio streams ====================================================== >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! ********** QSF_calc_Video_Is_Progessive_AVC=!QSF_calc_Video_Is_Progessive_AVC! ... so IS Progressive-AVC ... just copy video stream and transcode audio >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! ********** IS Progressive-AVC ... use ffmpeg to just copy video stream and transcode audio >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
REM ffmpeg throws an error due to "-c:v copy" and this together: -vf "setdar="!QSF_MI_V_DisplayAspectRatio_String_slash!"
REM ffmpeg throws an error due to "-c:v copy" and this together: -profile:v high -level 5.2 
set "FFMPEG_cmd="!ffmpegexe64!""
set "FFMPEG_cmd=!FFMPEG_cmd! -hide_banner -v info -nostats"
set "FFMPEG_cmd=!FFMPEG_cmd! -i "!source_filename!" -probesize 100M -analyzeduration 100M"
set "FFMPEG_cmd=!FFMPEG_cmd! -c:v copy -fps_mode passthrough"
set "FFMPEG_cmd=!FFMPEG_cmd! -strict experimental"
set "FFMPEG_cmd=!FFMPEG_cmd! -sws_flags lanczos+accurate_rnd+full_chroma_int+full_chroma_inp"
set "FFMPEG_cmd=!FFMPEG_cmd! -movflags +faststart+write_colr"
set "FFMPEG_cmd=!FFMPEG_cmd! -c:a copy"
set "FFMPEG_cmd=!FFMPEG_cmd! -y "!qsf_filename!""
ECHO !FFMPEG_cmd! >> "!vrdlog!" 2>&1
!FFMPEG_cmd! >> "!vrdlog!" 2>&1
SET EL=!ERRORLEVEL!
IF /I "!EL!" NEQ "0" (
	set "check_QSF_failed=********** ERROR: run_ffmpeg_stream_copy_instead_of_qsf  Error '!EL!' returned from ffmpeg"
	ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! !check_QSF_failed! >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
) ELSE if NOT exist "!qsf_filename!" ( 
	set "check_QSF_failed=********** ERROR: run_ffmpeg_stream_copy_instead_of_qsf  Error QSF file not created: '!qsf_filename!'"
	ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! !check_QSF_failed! >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
)
IF /I NOT "!check_QSF_failed!" == "" (
	ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! ********** FAILED: run_ffmpeg_stream_copy_instead_of_qsf "%~f1" >> "!vrdlog!" 2>&1
	ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
	goto :eof
)
REM There is NOT a  .cmd file  created to see the !requested_qsf_xml_prefix! variables created by the QSF ...
REM So create those variables here now ...
REM Example Returned xml string: from VideoReDo.OutputGetCompletedInfo()
REM VideoReDo.OutputGetCompletedInfo() MUST be called immediately AFTER a QSF FileSaveAs and BEFORE the .Close of the source file for the QSF
REM This is a well-formed single-item XML string, which make it really easy to find things.
REM <VRDOutputInfo outputFile="G:\HDTV\000-TO-BE-PROCESSED\zzz-TEST\VRDTVSP-Source\News-National_Nine_News_Afternoon_Edition.2021-02-05.ts.QSF">
REM  <OutputType desc="Output format:" hidden="1">MP4</OutputType>
REM  <OutputDurationSecs desc="Video length:" val_type="int" hidden="1">65</OutputDurationSecs>
REM  <OutputDuration desc="Video length:">00:01:05</OutputDuration>
REM  <OutputSizeMB desc="Video size:" val_type="int" val_format="%dMB">27</OutputSizeMB>
REM  <OutputSceneCount desc="Output scenes:" val_type="int">1</OutputSceneCount>
REM  <VideoOutputFrameCount desc="Video output frames:" val_type="int">1625</VideoOutputFrameCount>
REM  <AudioOutputFrameCount desc="Audio output frames:" val_type="int">2033</AudioOutputFrameCount>
REM  <ProcessingTimeSecs desc="Processing time (secs):" val_type="int">1</ProcessingTimeSecs>
REM  <ProcessedFramePerSec desc="Processed frames/sec:" val_type="float" val_format="%.2f">1625.000000</ProcessedFramePerSec>
REM  <ActualVideoBitrate desc="Actual Video Bitrate:" val_type="int">2552071</ActualVideoBitrate>
REM  <lkfs_values hidden="1"/>
REM  <audio_level_changes hidden="1"/>
REM </VRDOutputInfo>
REM
set "default_ActualBitrate_bps=!SRC_MI_V_BitRate!"
set "!requested_qsf_xml_prefix!outputFile=!qsf_filename!"
set "!requested_qsf_xml_prefix!OutputType=!qsf_extension!"
set "!requested_qsf_xml_prefix!OutputDurationSecs=0"
set "!requested_qsf_xml_prefix!OutputDuration=00:00:00"
set "!requested_qsf_xml_prefix!OutputSizeMB=0"
set "!requested_qsf_xml_prefix!OutputSceneCount=1"
set "!requested_qsf_xml_prefix!VideoOutputFrameCount=0"
set "!requested_qsf_xml_prefix!AudioOutputFrameCount=0"
set "!requested_qsf_xml_prefix!ProcessingTimeSecs0"
set "!requested_qsf_xml_prefix!ProcessedFramePerSec=0"
set "!requested_qsf_xml_prefix!ActualVideoBitrate=!default_ActualBitrate_bps!"
ECHO ======================================================  Finish Run non-QSF FFMPEG copy video and audio streams ====================================================== >> "!vrdlog!" 2>&1

REM :gather_variables_from_media_file P2 =	the global prefix to use for this gather, one of "SRC_", "QSF_" "TARGET_"
CALL :gather_variables_from_media_file "!qsf_filename!" "QSF_" 

CALL :get_date_time_String "end_date_time_ffmpeg_stream_copy_instead_of_qsf"
REM ECHO "!py_exe!" "!Path_to_py_VRDTVSP_Calculate_Duration!" --start_datetime "!start_date_time_ffmpeg_stream_copy_instead_of_qsf!" --end_datetime "!end_date_time_ffmpeg_stream_copy_instead_of_qsf!" --prefix_id "run_ffmpeg_stream_copy_instead_of_qsf" >> "!vrdlog!" 2>&1
"!py_exe!" "!Path_to_py_VRDTVSP_Calculate_Duration!" --start_datetime "!start_date_time_ffmpeg_stream_copy_instead_of_qsf!" --end_datetime "!end_date_time_ffmpeg_stream_copy_instead_of_qsf!" --prefix_id "run_ffmpeg_stream_copy_instead_of_qsf" >> "!vrdlog!" 2>&1

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
ECHO !DATE! !TIME! **********  Declaring FAILED:  "%~f1" >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! ********** Moving "%~f1" to "!failed_conversion_TS_Folder!" >> "!vrdlog!" 2>&1
ECHO MOVE /Y "%~f1" "!failed_conversion_TS_Folder!" >> "!vrdlog!" 2>&1
MOVE /Y "%~f1" "!failed_conversion_TS_Folder!" >> "!vrdlog!" 2>&1
REM remove junk files leftover from QSF if it timed out or something
ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
ECHO DEL /F !scratch_Folder!*.tmp >> "!vrdlog!" 2>&1
DEL /F !scratch_Folder!*.tmp >> "!vrdlog!" 2>&1

ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
ECHO set SRC_ >> "!vrdlog!" 2>&1
set SRC_ >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
ECHO set QSF_ >> "!vrdlog!" 2>&1
set QSF_ >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
ECHO set FFMPEG_ >> "!vrdlog!" 2>&1
set FFMPEG_ >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
goto :eof


REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM ---------------------------------------------------------------------------------------------------------------------------------------------------------
REM
:clear_variables
REM ECHO FOR /F "tokens=1,* delims==" %%G IN ('SET SRC_') DO (set "%%G=") >> "!vrdlog!" 2>&1
FOR /F "tokens=1,* delims==" %%G IN ('SET SRC_') DO (set "%%G=")>NUL 2>&1
REM ECHO FOR /F "tokens=1,* delims==" %%G IN ('SET QSF_') DO (set "%%G=") >> "!vrdlog!" 2>&1
FOR /F "tokens=1,* delims==" %%G IN ('SET QSF_') DO (set "%%G=")>NUL 2>&1
REM ECHO FOR /F "tokens=1,* delims==" %%G IN ('SET TARGET') DO (set "%%G=") >> "!vrdlog!" 2>&1
FOR /F "tokens=1,* delims==" %%G IN ('SET TARGET_') DO (set "%%G=")>NUL 2>&1
REM ECHO FOR /F "tokens=1,* delims==" %%G IN ('SET FFMPEG_') DO (set "%%G=") >> "!vrdlog!" 2>&1
FOR /F "tokens=1,* delims==" %%G IN ('SET FFMPEG_') DO (set "%%G=")>NUL 2>&1
REM ECHO FOR /F "tokens=1,* delims==" %%G IN ('SET Footy_') DO (set "%%G=") >> "!vrdlog!" 2>&1
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
REM ECHO FOR /F "tokens=1,* delims==" %%G IN ('SET !derived_prefix_FF!') DO (set "%%G=") >> "!vrdlog!" 2>&1
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
REM ECHO ### "!derived_prefix_FF!" >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! ****************************** >> "!vrdlog!" 2>&1
REM ECHO TYPE "!temp_cmd_file!" >> "!vrdlog!" 2>&1
REM TYPE "!temp_cmd_file!" >> "!vrdlog!" 2>&1
ECHO call "!temp_cmd_file!" >> "!vrdlog!" 2>&1
call "!temp_cmd_file!" >> "!vrdlog!" 2>&1
ECHO DEL /F "!temp_cmd_file!" >> "!vrdlog!" 2>&1
DEL /F "!temp_cmd_file!" >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! ****************************** >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! ====================================================================================================================================================== >> "!vrdlog!" 2>&1
ECHO DEL /F "!temp_cmd_file!" >> "!vrdlog!" 2>&1
DEL /F "!temp_cmd_file!" >> "!vrdlog!" 2>&1
REM ECHO FOR /F "tokens=1,* delims==" %%G IN ('SET !derived_prefix_MI!') DO (set "%%G=") >> "!vrdlog!" 2>&1
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
REM ECHO ### "!derived_prefix_MI!" >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! ****************************** >> "!vrdlog!" 2>&1
REM ECHO TYPE "!temp_cmd_file!" >> "!vrdlog!" 2>&1
REM TYPE "!temp_cmd_file!" >> "!vrdlog!" 2>&1
ECHO call "!temp_cmd_file!" >> "!vrdlog!" 2>&1
call "!temp_cmd_file!" >> "!vrdlog!" 2>&1
ECHO DEL /F "!temp_cmd_file!" >> "!vrdlog!" 2>&1
DEL /F "!temp_cmd_file!" >> "!vrdlog!" 2>&1
ECHO !DATE! !TIME! ****************************** >> "!vrdlog!" 2>&1
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
ECHO !DATE! !TIME! ########## Start Fudge Checks on !current_prefix!MI_V_BitRate ... >> "!vrdlog!" 2>&1
ECHO set !current_prefix!MI_V_BitRate >> "!vrdlog!" 2>&1
set !current_prefix!MI_V_BitRate >> "!vrdlog!" 2>&1
ECHO set !current_prefix!MI_G_OverallBitRate >> "!vrdlog!" 2>&1
set !current_prefix!MI_G_OverallBitRate >> "!vrdlog!" 2>&1
ECHO set !current_prefix!FF_G_bit_rate >> "!vrdlog!" 2>&1
set !current_prefix!FF_G_bit_rate >> "!vrdlog!" 2>&1
call set tmp_MI_V_BitRate=%%!current_prefix!MI_V_BitRate%%
ECHO Fudge Check #1 !current_prefix!MI_V_BitRate '!tmp_MI_V_BitRate!' for blank ... >> "!vrdlog!" 2>&1
IF /I "!tmp_MI_V_BitRate!" == "" (
	ECHO WARNING: !current_prefix!MI_V_BitRate '!tmp_MI_V_BitRate!' was blank, attempting to fudge to !current_prefix!FF_G_bit_rate >> "!vrdlog!" 2>&1
	call set !current_prefix!MI_V_BitRate=%%!current_prefix!FF_G_bit_rate%%
)
call set tmp_MI_V_BitRate=%%!current_prefix!MI_V_BitRate%%
ECHO Fudge Check #2 !current_prefix!MI_V_BitRate '!tmp_MI_V_BitRate!' for blank ... >> "!vrdlog!" 2>&1
IF /I "!tmp_MI_V_BitRate!" == "" (
	ECHO WARNING: !current_prefix!MI_V_BitRate '!tmp_MI_V_BitRate!' was blank, attempting to fudge to !current_prefix!MI_G_OverallBitRate >> "!vrdlog!" 2>&1
	call set !current_prefix!MI_V_BitRate=%%!current_prefix!MI_G_OverallBitRate%%
)
call set tmp_MI_V_BitRate=%%!current_prefix!MI_V_BitRate%%
ECHO Fudge Check #3 FINAL CHECK !current_prefix!MI_V_BitRate '!tmp_MI_V_BitRate!' for blank ... >> "!vrdlog!" 2>&1
IF /I "!tmp_MI_V_BitRate!" == "" (
	ECHO ERROR: Unable to detect !current_prefix!MI_V_BitRate '!tmp_MI_V_BitRate!', failed to fudge it, Aborting >> "!vrdlog!" 2>&1
	ECHO SET >> "!vrdlog!" 2>&1
	SET >> "!vrdlog!" 2>&1
	exit 1
)
ECHO !DATE! !TIME! ########## Finish Fudge Checks on !current_prefix!MI_V_BitRate ... >> "!vrdlog!" 2>&1

REM get a slash version of MI_V_DisplayAspectRatio_String
call set !current_prefix!MI_V_DisplayAspectRatio_String_slash=%%!current_prefix!MI_V_DisplayAspectRatio_String%%
call set !current_prefix!MI_V_DisplayAspectRatio_String_slash=%%!current_prefix!MI_V_DisplayAspectRatio_String_slash::=/%%
call set !current_prefix!MI_V_DisplayAspectRatio_String_slash=%%!current_prefix!MI_V_DisplayAspectRatio_String_slash::\=/%%
REM ECHO +++++++++ >> "!vrdlog!" 2>&1
REM ECHO set !current_prefix!MI_V_DisplayAspectRatio_String >> "!vrdlog!" 2>&1
REM set !current_prefix!MI_V_DisplayAspectRatio_String >> "!vrdlog!" 2>&1
REM ECHO +++++++++ >> "!vrdlog!" 2>&1

REM get a slash version of FF_V_display_aspect_ratio
call set !current_prefix!FF_V_display_aspect_ratio_slash=%%!current_prefix!FF_V_display_aspect_ratio%%
call set !current_prefix!FF_V_display_aspect_ratio_slash=%%!current_prefix!FF_V_display_aspect_ratio_slash::=/%%
call set !current_prefix!FF_V_display_aspect_ratio_slash=%%!current_prefix!FF_V_display_aspect_ratio_slash::\=/%%
REM ECHO +++++++++ >> "!vrdlog!" 2>&1
REM ECHO set !current_prefix!FF_V_display_aspect_ratio >> "!vrdlog!" 2>&1
REM set !current_prefix!FF_V_display_aspect_ratio >> "!vrdlog!" 2>&1
REM ECHO +++++++++ >> "!vrdlog!" 2>&1

REM calculate MI_A_Audio_Delay from MI_A_Video_Delay
REM MI_A_Video_Delay is reported by mediainfo as decimal seconds, not milliseconds, so up-convert it
call set tmp_MI_A_Video_Delay=%%!current_prefix!MI_A_Video_Delay%%
IF /I "!tmp_MI_A_Video_Delay!" == "" (set "tmp_MI_A_Video_Delay=0")
set "py_eval_string=int(1000.0 * !tmp_MI_A_Video_Delay!)"
CALL :calc_single_number_result_py "!py_eval_string!" "tmp_MI_A_Video_Delay"
set /a tmp_MI_A_Audio_Delay=0 - !tmp_MI_A_Video_Delay!
set "!current_prefix!MI_A_Video_Delay=!tmp_MI_A_Video_Delay!"
set "!current_prefix!MI_A_Audio_Delay=!tmp_MI_A_Audio_Delay!"
REM ECHO +++++++++ >> "!vrdlog!" 2>&1
REM ECHO set !current_prefix!MI_A_Video_Delay >> "!vrdlog!" 2>&1
REM set !current_prefix!MI_A_Video_Delay >> "!vrdlog!" 2>&1
REM ECHO set !current_prefix!MI_A_Audio_Delay >> "!vrdlog!" 2>&1
REM set !current_prefix!MI_A_Audio_Delay >> "!vrdlog!" 2>&1
REM ECHO +++++++++ >> "!vrdlog!" 2>&1

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
IF /I NOT "!tmp_FF_V_codec_name_original!" == "AVC" (
	IF /I NOT "!tmp_FF_V_codec_name_original!" == "HEVC" (
		IF /I NOT "!tmp_FF_V_codec_name_original!" == "MPEG2" (
			IF /I NOT "!tmp_FF_V_codec_name_original!" == "VP9" (
				set "!current_prefix!calc_Video_Encoding=HEVC"
			)
		)
	)
)
REM ECHO +++++++++ >> "!vrdlog!" 2>&1
REM ECHO set tmp_MI_V_Format >> "!vrdlog!" 2>&1
REM set tmp_MI_V_Format >> "!vrdlog!" 2>&1
REM ECHO +++++++++ >> "!vrdlog!" 2>&1
REM ECHO set tmp_FF_V_codec_name >> "!vrdlog!" 2>&1
REM set tmp_FF_V_codec_name >> "!vrdlog!" 2>&1
REM ECHO +++++++++ >> "!vrdlog!" 2>&1
REM ECHO set !current_prefix!calc_Video_Encoding_original >> "!vrdlog!" 2>&1
REM set !current_prefix!calc_Video_Encoding_original >> "!vrdlog!" 2>&1
REM ECHO set !current_prefix!calc_Video_Encoding >> "!vrdlog!" 2>&1
REM set !current_prefix!calc_Video_Encoding >> "!vrdlog!" 2>&1
REM ECHO +++++++++ >> "!vrdlog!" 2>&1

REM Determine whether PROGRESSIVE or INTERLACED
call set tmp_MI_V_ScanType=%%!current_prefix!MI_V_ScanType%%
call set tmp_FF_V_field_order=%%!current_prefix!FF_V_field_order%%
set "!current_prefix!calc_Video_Interlacement=PROGRESSIVE"
IF /I "!tmp_MI_V_ScanType!" == "MBAFF"          (set "!current_prefix!calc_Video_Interlacement=INTERLACED")
IF /I "!tmp_MI_V_ScanType!" == "Interlaced"     (set "!current_prefix!calc_Video_Interlacement=INTERLACED")
IF /I "!tmp_FF_V_field_order!" == "tt"          (set "!current_prefix!calc_Video_Interlacement=INTERLACED")
IF /I "!tmp_MI_V_ScanType!" == ""               (set "!current_prefix!calc_Video_Interlacement=PROGRESSIVE")
IF /I "!tmp_FF_V_field_order!" == "progressive" (set "!current_prefix!calc_Video_Interlacement=PROGRESSIVE")
REM ECHO +++++++++ >> "!vrdlog!" 2>&1
REM ECHO set tmp_MI_V_ScanType >> "!vrdlog!" 2>&1
REM set tmp_MI_V_ScanType >> "!vrdlog!" 2>&1
REM ECHO +++++++++ >> "!vrdlog!" 2>&1
REM ECHO set tmp_FF_V_field_order >> "!vrdlog!" 2>&1
REM set tmp_FF_V_field_order >> "!vrdlog!" 2>&1
REM ECHO +++++++++ >> "!vrdlog!" 2>&1
REM ECHO set !current_prefix!calc_Video_Interlacement >> "!vrdlog!" 2>&1
REM set !current_prefix!calc_Video_Interlacement >> "!vrdlog!" 2>&1
REM ECHO +++++++++ >> "!vrdlog!" 2>&1

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
REM ECHO set !current_prefix!calc_Video_FieldFirst >> "!vrdlog!" 2>&1
REM set !current_prefix!calc_Video_FieldFirst >> "!vrdlog!" 2>&1
REM ECHO +++++++++ >> "!vrdlog!" 2>&1

call set tmp_calc_Video_Interlacement=%%!current_prefix!calc_Video_Interlacement%%
call set tmp_calc_Video_Encoding=%%!current_prefix!calc_Video_Encoding%%
set "!current_prefix!calc_Video_Is_Progessive_AVC=False"
IF /I "!tmp_calc_Video_Interlacement!" == "PROGRESSIVE" ( 
	IF /I "!tmp_calc_Video_Encoding!" == "AVC" (
		set "!current_prefix!calc_Video_Is_Progessive_AVC=True"
	)
)

REM display all calculated variables
REM ECHO +++++++++ >> "!vrdlog!" 2>&1
REM ECHO display all calculated variables >> "!vrdlog!" 2>&1
REM ECHO set !current_prefix!calc >> "!vrdlog!" 2>&1
REM set !current_prefix!calc >> "!vrdlog!" 2>&1
REM ECHO +++++++++ >> "!vrdlog!" 2>&1

call set tmp_calc_Video_Encoding=%%!current_prefix!calc_Video_Encoding%%
call set tmp_calc_Video_Interlacement=%%!current_prefix!calc_Video_Interlacement%%
call set tmp_calc_Video_FieldFirst=%%!current_prefix!calc_Video_FieldFirst%%
REM display calculated variables individually
REM ECHO +++++++++ >> "!vrdlog!" 2>&1
REM ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
REM ECHO !DATE! !TIME! !current_prefix!calc_Video_Encoding=!tmp_calc_Video_Encoding! >> "!vrdlog!" 2>&1
REM ECHO !DATE! !TIME! !current_prefix!calc_Video_Interlacement=!tmp_calc_Video_Interlacement! >> "!vrdlog!" 2>&1
REM ECHO !DATE! !TIME! !current_prefix!calc_Video_FieldFirst=!tmp_calc_Video_FieldFirst! >> "!vrdlog!" 2>&1
REM ECHO !DATE! !TIME! >> "!vrdlog!" 2>&1
REM ECHO +++++++++ >> "!vrdlog!" 2>&1

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
ECHO !DATE! !TIME! Finish collecting :gather_variables_from_media_file "!current_prefix!" ffprobe and mediainfo variables ... "!media_filename!" >> "!vrdlog!" 2>&1
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

:TCase2
REM Subroutine to convert a variable VALUE to Title Case.
REM The argument for this subroutine is the variable NAME.
call :LoCase %1
FOR %%i IN (" a= A" " b= B" " c= C" " d= D" " e= E" " f= F" " g= G" " h= H" " i= I" " j= J" " k= K" " l= L" " m= M" " n= N" " o= O" " p= P" " q= Q" " r= R" " s= S" " t= T" " u= U" " v= V" " w= W" " x= X" " y= Y" " z= Z" ^
           ".a=.A" ".b=.B" ".c=.C" ".d=.D" ".e=.E" ".f=.F" ".g=.G" ".h=.H" ".i=.I" ".j=.J" ".k=.K" ".l=.L" ".m=.M" ".n=.N" ".o=.O" ".p=.P" ".q=.Q" ".r=.R" ".s=.S" ".t=.T" ".u=.U" ".v=.V" ".w=.W" ".x=.X" ".y=.Y" ".z=.Z" ^
           "_a=_A" "_b=_B" "_c=_C" "_d=_D" "_e=_E" "_f=_F" "_g=_G" "_h=_H" "_i=_I" "_j=_J" "_k=_K" "_l=_L" "_m=_M" "_n=_N" "_o=_O" "_p=_P" "_q=_Q" "_r=_R" "_s=_S" "_t=_T" "_u=_U" "_v=_V" "_w=_W" "_x=_X" "_y=_Y" "_z=_Z" ^
           "-a=-A" "-b=-B" "-c=-C" "-d=-D" "-e=-E" "-f=-F" "-g=-G" "-h=-H" "-i=-I" "-j=-J" "-k=-K" "-l=-L" "-m=-M" "-n=-N" "-o=-O" "-p=-P" "-q=-Q" "-r=-R" "-s=-S" "-t=-T" "-u=-U" "-v=-V" "-w=-W" "-x=-X" "-y=-Y" "-z=-Z") DO (
				CALL set "%1=%%%1:%%~i%%"
			)
call set "first_letter=!%1:~0,1!"
call set "rest_of_string=!%1:~1!"
call :UpCase first_letter
Call CALL set "%1=!first_letter!!rest_of_string!"
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
REM
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
