# VRDTVSP

### NOTHING WORKS FOR THE TIME BEING
#### REDEVEOPMENT IN PROGRESS .vbs -> .bat/.py/.ps1




### built primarily with vbscript in 1970's coding style   

#### ONLY works on a Win10x64 PC with    
#### - specific licensed software    
#### - and free software   
#### - and preset folder/file locations   
#### - and TV Scheduler Pro recordings   

## Is suited to tailored personal needs rather than being a general tool

Tries to convert time-shifted (thus free in AU) OTA interlaced and progressive recordings
to non-interlaced formats which are playable by Chromecasts and thus are suitable for casting.   

Input: .ts container files with mpeg2/h.264 interlaced or progressive video and mpeg2/ac3/aac audio.   
Output: .mp4 container files with deinterlaced h.264 video codec and aac audio codec.   

Tries to deal with seemingly random-ish bitrates and aspect-ratios and audio-delays and recording glitches.

Tries to deinterlace if required.

Tries to slightly denoise and sharpen with settings that depend on source codec and specific content.

Dependencies:   
1. *.ts OTA capture files created by TV Scheduler Pro   
2. VideoReDo version 6 (version 5 can be used)   
3. Vapoursynth x64 Portable   
4. Python x64 Portable (a version compatible withthe version of Vapoursynth used) in the Vapoursynth portable folder   
5. ffmpeg x64 in the Vapoursynth portable folder, built with these:    
5.1 Nvidia NVEnc x64 capability   
5.2 Vapoursynth x64 capability   
5.3 fdk-aac x64 capability   
6. ffprobe x64 (builds with ffmpeg) in the Vapoursynth portable folder   
7. Donald Graft's Nvdia accelerated (NV) tools and DLL (non-free), in a folder under the Vapoursynth portable folder   
8. mediainfo x64   
9. a reasonable Nvidia card and latest Drivers, eg a 1050Ti upward eg an RTX2060Super   
