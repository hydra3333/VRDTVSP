# VRDTVSP

## built primarily with vbscript   

### ONLY works on a Win10x64 PC with specific licensed software an free software   
### and preset folder/file locations   
### and TV Scheduler Pro recordings   

Tries to convert time-shifted (thus free in AU) OTA files to non-interlaced formats
playable by Chromecasts and thus are suitable for casting.

Tries to deal with random-ish bitrates and aspect-ratios and audio-delays and recording glitches.

Tries to deinterlace as required.

Tries to slightly denoise and sharpen with settings that depend on resolution and specific content.

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

Input: .TS container with mpeg2/h.264 interlaced or progressive video and mpeg2/ac3/aac audio.   
Output: .mp4 container with deinterlaced h.264 video and aac audio.   
