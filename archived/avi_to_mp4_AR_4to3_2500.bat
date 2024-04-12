@ECHO ON
@setlocal ENABLEDELAYEDEXPANSION
@setlocal enableextensions

"C:\SOFTWARE\Vapoursynth-x64\ffmpeg.exe" -hide_banner -v info -i "%~f1" -probesize 100M -analyzeduration 100M ^
-vf "setdar=4/3" -fps_mode passthrough -sws_flags lanczos+accurate_rnd+full_chroma_int+full_chroma_inp -strict experimental ^
-c:v h264_nvenc -pix_fmt nv12 -preset p7 -multipass fullres -forced-idr 1 -g 25 -coder:v cabac -spatial-aq 1 -temporal-aq 1 -dpb_size 0 -bf:v 3 -b_ref_mode:v 0 -rc:v vbr ^
-cq:v 0 -b:v 2500000 -minrate:v 100000 -maxrate:v 3500000 -bufsize 3500000 ^
-strict experimental -profile:v high -level 5.2 -movflags +faststart+write_colr -c:a libfdk_aac -b:a 256k -ar 48000 -y "%~dpn1.h264.aac.mp4"

pause
exit