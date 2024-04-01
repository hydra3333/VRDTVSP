# VRDTVSP

### NOTHING WORKS FOR THE TIME BEING
#### REDEVEOPMENT IN PROGRESS .vbs -> .bat/.py/.ps1


### built primarily with DOS-batch/python3/vbscript in 1970's coding styles   


#### ONLY works on a Win10X64/Win11x64 PC with    
#### - specific licensed software (VideoReDo, although that is no longer sold)    
#### - and free software   
#### - and preset folder/file locations   
#### - and TV Scheduler Pro recordings   


#### If anyone knows of a tool (to replace VideoReDo) which can be run from a
#### commandline-interface (cli) which can parse a .TS and an .MP4 (eg from
#### over-the-air TV captures) checking for glitches and "fix" them so that
#### DGtools/Valpursynth/ffmpeg will not crashwhen trying to transcode them
#### ... please leave a comment !

## Is suited only to tailored personal needs rather than being a general tool

Tries to convert time-shifted (thus free in AU) OTA interlaced and progressive recordings
to non-interlaced (progressive) formats which thus are playable by Chromecasts and thus are suitable for casting.   

Input: .ts container files with mpeg2/h.264 interlaced or progressive video and mp2/ac3/aac audio.   
Output: .mp4 container files with deinterlaced h.264 video codec and aac audio codec.   

Tries to deal with seemingly random-ish bitrate detections and aspect-ratios and audio-delays and yucky recording glitches.    
Relies heavily on the now-defunct VideoReDo product (the author died and the business ceased to operate in 2023)
to "QuickStreamFix" video source files into intermediate files by identifing and fixing video capture anolamies beofre
transcoding using vapoursynth/DGtools/python3/vbscript/FFMPEG.

Tries to deinterlace if required.

Tries to slightly denoise and sharpen with settings that depend on source codec and specific content.

Dependencies:   
1. *.ts OTA capture files created by TV Scheduler Pro   
2. VideoReDo version 6 and version 5   
3. Vapoursynth x64 Portable   
4. Python3 x64 Portable (a version compatible with the version of Vapoursynth used) in the Vapoursynth portable folder   
5. ffmpeg x64 in the Vapoursynth portable folder, compiled with these:    
5.1 Nvidia NVEnc x64 capability   
5.2 Vapoursynth x64 capability   
5.3 fdk-aac x64 capability   
6. ffprobe x64 (builds with ffmpeg) in the Vapoursynth portable folder   
8. mediainfo x64   
7. Donald Graft's Nvdia CUDA accelerated (NV) tools and DLL, in a folder under the Vapoursynth portable folder   
9. a reasonable-ish Nvidia card and latest Drivers, eg a 1050Ti (at minimum) upward eg an RTX-2060-Super   
