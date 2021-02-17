@ECHO on
@setlocal ENABLEDELAYEDEXPANSION
@setlocal enableextensions
DEL .\0-TEST-RUN-VRDTSV_001-BATCH.log

cscript //nologo "E:\GIT-REPOSITORIES\VRDTVSP\VRDTVS_001.vbs" ^
/DEBUG:True ^
/DEV:False ^
/capture_Folder:"G:\HDTV\000-TO-BE-PROCESSED\zzz-TEST\CAPTURE\" ^
/source_Folder:"G:\HDTV\000-TO-BE-PROCESSED\zzz-TEST\VRDTVS-Source\" ^
/done_Folder:"G:\HDTV\000-TO-BE-PROCESSED\zzz-TEST\VRDTVS-Done\" ^
/destination_Folder:"G:\HDTV\000-TO-BE-PROCESSED\zzz-TEST\VRDTVS-Converted\" ^
/failed_Folder:"G:\HDTV\000-TO-BE-PROCESSED\zzz-TEST\VRDTVS-Failed-Conversion\" ^
/temp_path:"D:\VRDTVS-SCRATCH\" ^
/vrd_version_for_qsf:6 ^
/vrd_version_for_adscan:5 ^
/do_adscan:True >> .\0-TEST-RUN-VRDTSV_001-BATCH.log 2>&1


SET EL=%ERRORLEVEL%
exit %EL%
