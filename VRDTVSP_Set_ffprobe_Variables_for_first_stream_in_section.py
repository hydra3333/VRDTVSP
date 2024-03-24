import os
import re
import argparse
from datetime import datetime
import ctypes
from ctypes import wintypes
from pathlib import Path
import json
import xml.etree.ElementTree as ET
import subprocess

def get_env_variable(key):
    # Function to get environment variable
    # Because os.environ() ONLY set/get environment variables within the life of the PYTHON process
    # Depends Windows stuff being setup globally in __main__
    buffer_size = 32767  # Maximum size of environment variable value
    buffer = ctypes.create_unicode_buffer(buffer_size)
    result = GetEnvironmentVariableW(key, buffer, buffer_size)
    if result == 0:
        error_code = ctypes.get_last_error()
        if error_code == 203:  # ERROR_ENVVAR_NOT_FOUND
            print(f"Environment variable '{key}' not found.")
        else:
            print(f"Failed to get environment variable '{key}': Error code {error_code}")
        return None
    else:
        return buffer.value

def set_env_variable(key, value):
    # Function to set environment variable
    # Because os.environ() ONLY set/get environment variables within the life of the PYTHON process
    # Depends Windows stuff being setup globally in __main__
    result = SetEnvironmentVariableW(key, value)
    if not result:
        error_code = ctypes.get_last_error()
        print(f"Failed to set environment variable '{key}' to '{value}': Error code {error_code}")
        exit(1)

def escape_special_chars(text):
    # Replace special characters with underscores.
    special_chars = r'<>|&"?*()\' '    # leave : and / alone
    return re.sub(r'[%s]' % re.escape(special_chars), '_', text)

def process_stream(stream, prefix):
    # Create or overwrite environment variables with key/value pairs
    for key, value in stream.items():
        if not isinstance(value, str):
            value = str(value)
        key = escape_special_chars(prefix + key)
        value = escape_special_chars(value)
        print(f"DEBUG: do set_env_variable '{key}'] = '{value}'")
        #os.environ[key] = value    # Because os.environ() ONLY set/get environment variables within the life of the PYTHON process
        set_env_variable(key, value)
        debug_value = get_env_variable(key)
        print(f"DEBUG: after set_env_variable '{key}'] = '{debug_value}'")

def process_general_section(general_info, prefix):
    # Process general section
    #print("Processing General section...")
    process_stream(general_info, prefix)

def process_section(section_name, streams, prefix):
    # Process elements within the section based on the section name
    # sort the streams based on their index within the specified codec type 
    # and then select the stream with the lowest index as the first stream for that codec type.
    if section_name.lower() == "general":
        #print("Processing General section...")
        process_stream(section, prefix)
    else:    
        codec_streams = sorted(streams, key=lambda x: x['index'])  # Sort streams based on index
        if len(codec_streams) > 0:
            #print(f"Processing first {section_name} stream...")
            process_stream(codec_streams[0], prefix)  # Choose the first stream with the lowest index
        else:
            print(f"No {section_name} stream found for {mediafile}")
            pass

if __name__ == "__main__":
    # eg clear, set with python3, then show
    # set "prefix=SRC_FF_V_"
    # REM set !prefix!
    # FOR /F "tokens=1,* delims==" %%G IN ('SET !prefix!') DO (SET "%%G=")
    # python.exe --ffprobe_dos_variablename "ffprobe_dos_variablename" --mediafile "!source_mediafile!" --prefix "!prefix!" --section "Video"
    # set !prefix!
    # set "prefix=SRC_FF_A_"
    # REM set !prefix!
    # FOR /F "tokens=1,* delims==" %%G IN ('SET !prefix!') DO (SET "%%G=")
    # python.exe --ffprobe_dos_variablename "ffprobe_dos_variablename" --mediafile "!source_mediafile!" --prefix "!prefix!" --section "Audio"
    # set !prefix!
    # set "prefix=SRC_FF_G_"
    # REM set !prefix!
    # FOR /F "tokens=1,* delims==" %%G IN ('SET !prefix!') DO (SET "%%G=")
    # python.exe --ffprobe_dos_variablename "ffprobe_dos_variablename" --mediafile "!source_mediafile!" --prefix "!prefix!" --section "General"
    # set !prefix!

    parser = argparse.ArgumentParser(description="Parse media file with ffprobe and create environment variables.")
    parser.add_argument("--ffprobe_dos_variablename", help="Name of DOS variable for fully qualified ffprobe path", required=True)
    parser.add_argument("--mediafile", help="Path to the media file", required=True)
    parser.add_argument("--prefix", help="Prefix for environment variable keys", required=True)
    parser.add_argument("--section", help="ffprobe section to process (e.g., Video, Audio, General)", required=True)
    args = parser.parse_args()

    #***************************************************************************************************
    # Setup Windows stuff to read/write environment variables
    # Because os.environ() ONLY set/get environment variables within the life of the PYTHON process
    # Define necessary constants and types
    LPWSTR = ctypes.POINTER(wintypes.WCHAR)
    kernel32 = ctypes.WinDLL('kernel32', use_last_error=True)
    user32 = ctypes.WinDLL('user32', use_last_error=True)
    # Define the SetEnvironmentVariable function from kernel32.dll
    SetEnvironmentVariableW = kernel32.SetEnvironmentVariableW
    SetEnvironmentVariableW.argtypes = (LPWSTR, LPWSTR)
    SetEnvironmentVariableW.restype = wintypes.BOOL
    # Define the GetEnvironmentVariable function from kernel32.dll
    GetEnvironmentVariableW = kernel32.GetEnvironmentVariableW
    GetEnvironmentVariableW.argtypes = (LPWSTR, LPWSTR, wintypes.DWORD)
    GetEnvironmentVariableW.restype = wintypes.DWORD
    # Define the SendMessageTimeoutW function from user32.dll
    SendMessageTimeoutW = user32.SendMessageTimeoutW
    SendMessageTimeoutW.argtypes = (wintypes.HWND, wintypes.UINT, wintypes.LPARAM, LPWSTR, wintypes.UINT, wintypes.UINT, wintypes.DWORD)
    SendMessageTimeoutW.restype = wintypes.LPARAM
    #***************************************************************************************************

    # Retrieve the name of the DOS variable for MediaInfo path from command-line arguments
    ffprobe_dos_variablename = args.ffprobe_dos_variablename
    mediafile = args.mediafile
    prefix = args.prefix
    section_name = args.section.lower()  # Convert section name to lowercase for case-insensitive comparison

    # Retrieve the path of MediaInfo from the environment variable and Check if MediaInfo file path exists
    ffprobe_path = os.environ.get(ffprobe_dos_variablename)
    if not ffprobe_path or not os.path.exists(ffprobe_path):
        print(f"Error: ffprobe path not specified or does not exist for variable {ffprobe_dos_variablename}.")
        exit(1)

    # Check if media file exists
    if not os.path.exists(mediafile):
        print(f"Error: Media file does not exist: {mediafile}")
        exit(1)

    # Run ffprobe command to get JSON output
    ffprobe_subprocess_command = [ffprobe_path, "-v", "quiet", "-print_format", "json", "-show_format", "-show_streams", mediafile]
    print(f"DEBUG: issuing subprocess command: {ffprobe_subprocess_command}")
    ffprobe_output = subprocess.check_output(ffprobe_subprocess_command).decode()
    #print(f"DEBUG: returned output string: {ffprobe_output}")

    # Parse JSON output
    ffprobe_data = json.loads(ffprobe_output)
    if section_name.lower() == "general":
        process_general_section(ffprobe_data["format"], prefix)
    elif "streams" in ffprobe_data:
        streams = [s for s in ffprobe_data["streams"] if "codec_type" in s and s["codec_type"] == section_name]    # eg "video", "audio"
        process_section(section_name, streams, prefix)
    else:
        print(f"Error: Invalid ffprobe section '{section_name}' processing {mediafile}\nPlease specify a valid section (e.g., Video, Audio, General).")
        exit(1)
