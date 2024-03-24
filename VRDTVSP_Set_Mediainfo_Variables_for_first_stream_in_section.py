import os
import re
import argparse
from datetime import datetime
import ctypes
from ctypes import wintypes
from ctypes import *		# for mediainfo ... load via ctypes.CDLL(r'.\MediaInfo.dll')
from typing import Union	# for mediainfo
from pathlib import Path
import json
import xml.etree.ElementTree as ET
import subprocess
import pprint
from MediaInfoDLL3 import MediaInfo, Stream, Info, InfoOption

def add_variable_to_list(key, value, set_cmd_list):
    set_cmd_list.append(f'SET "{key}={value}"')

def escape_special_chars(text):
    # Replace special characters with underscores.
    special_chars = r'<>|&"?*()\' '    # leave : and / alone
    return re.sub(r'[%s]' % re.escape(special_chars), '_', text)

def get_general_info(mediafile, prefix):
    # Create a MediaInfo object
    media_info = MediaInfo()
    # Open the media file
    media_info.Open(mediafile)
    # Get general information
    general_info = media_info.Get(Stream.General, 0)
    # Populate dictionary with key/value pairs for general information
    general_dict = {}
    for info_type in Info:
        info_value = general_info.Get(info_type)
        if info_value:
            general_dict[escape_special_chars(prefix + Info.enum_type(info_type))] = escape_special_chars(info_value)
    # Close the MediaInfo object
    media_info.Close()
    return general_dict

def get_video_info(mediafile, prefix):
    # Create a MediaInfo object
    media_info = MediaInfo()
    # Open the media file
    media_info.Open(mediafile)
    # Get information for the first video stream
    video_info = media_info.Get(Stream.Video, 0)
    # Populate dictionary with key/value pairs for video information
    video_dict = {}
    if video_info:
        for info_type in Info:
            info_value = video_info.Get(info_type)
            if info_value:
                video_dict[escape_special_chars(prefix + Info.enum_type(info_type))] = escape_special_chars(info_value)
    # Close the MediaInfo object
    media_info.Close()
    return video_dict

def get_audio_info(mediafile, prefix):
    # Create a MediaInfo object
    media_info = MediaInfo()
    # Open the media file
    media_info.Open(mediafile)
    # Get information for the first audio stream
    audio_info = media_info.Get(Stream.Audio, 0)
    # Populate dictionary with key/value pairs for audio information
    audio_dict = {}
    if audio_info:
        for info_type in Info:
            info_value = audio_info.Get(info_type)
            if info_value:
                audio_dict[escape_special_chars(prefix + Info.enum_type(info_type))] = escape_special_chars(info_value)
    # Close the MediaInfo object
    media_info.Close()
    return audio_dict

if __name__ == "__main__":
    # eg clear, set with python3, then show
    # set "prefix=SRC_MI_V_"
    # REM set !prefix!
    # FOR /F "tokens=1,* delims==" %%G IN ('SET !prefix!') DO (SET "%%G=")
    # python.exe --mediainfo_dos_variablename "mediainfo_dos_variablename" --mediafile "!source_mediafile!" --prefix "!prefix!" --section "Video"
    # set !prefix!
    # set "prefix=SRC_MI_A_"
    # REM set !prefix!
    # FOR /F "tokens=1,* delims==" %%G IN ('SET !prefix!') DO (SET "%%G=")
    # python.exe --mediainfo_dos_variablename "mediainfo_dos_variablename" --mediafile "!source_mediafile!" --prefix "!prefix!" --section "Audio"
    # set !prefix!
    # set "prefix=SRC_MI_G_"
    # REM set !prefix!
    # FOR /F "tokens=1,* delims==" %%G IN ('SET !prefix!') DO (SET "%%G=")
    # python.exe --mediainfo_dos_variablename "mediainfo_dos_variablename" --mediafile "!source_mediafile!" --prefix "!prefix!" --section "General"
    # set !prefix!

    #CDLL(r'MediaInfo.dll')
    #from MediaInfoDLL3 import MediaInfo, Stream, Info, InfoOption
    #from MediaInfoDLL3 import *

    parser = argparse.ArgumentParser(description="Parse media file with MediaInfo and create DOS variables.")
    parser.add_argument("--mediainfo_dos_variablename", help="Name of DOS variable for fully qualified MediaInfo path", required=True)
    parser.add_argument("--mediafile", help="Path to the media file", required=True)
    parser.add_argument("--prefix", help="Prefix for DOS variable keys", required=True)
    parser.add_argument("--section", help="MediaInfo section to process (e.g., Video, Audio, General)", required=True)
    parser.add_argument("--output_cmd_file", help="Path to the cmd file containing the DOS SET statements", required=True)
    args = parser.parse_args()

    # Retrieve the name of the DOS variable for MediaInfo path from command-line arguments
    mediainfo_dos_variablename = args.mediainfo_dos_variablename
    mediafile = args.mediafile
    prefix = args.prefix
    section_name = args.section.lower()  # Convert section name to lowercase for case-insensitive comparison

    # Retrieve the path of MediaInfo from the environment variable and Check if MediaInfo file path exists
    mediainfo_path = os.environ.get(mediainfo_dos_variablename)
    if not mediainfo_path or not os.path.exists(mediainfo_path):
        print(f"Error: MediaInfo path not specified or does not exist for variable {mediainfo_dos_variablename}.")
        exit(1)

    # Check if media file exists
    if not os.path.exists(mediafile):
        print(f"Error: Media file does not exist at path {mediafile}.")
        exit(1)

    set_cmd_list = [ f'echo prefix = "{prefix}"' ]
    set_cmd_list.append(f'REM List of DOS SET commands to define DOS variables')
    set_cmd_list.append(f'REM First, clear the variables with the chosen prefix')
    set_cmd_list.append(f'FOR /F "tokens=1,* delims==" %%G IN (\'SET !prefix!\') DO (SET "%%G=")')
    if section_name.lower() == "General".lower():
        general_info_dict = get_general_info(mediafile, prefix)
        print("DEBUG: General Information:")
        for key, value in general_info_dict.items():
            print(f"DEBUG: {key}: {value}")
            os.environ[key] = value    # Because os.environ() ONLY set/get environment variables within the life of the PYTHON process
            #debug_value = os.environ[key]
            #print(f"DEBUG: after set_env_variable '{key}' = '{debug_value}'")
            set_cmd_list.append(f'SET "{key}={value}"')
    elif section_name.lower() == "Video".lower():
        video_info_dict = get_video_info(mediafile, prefix)
        print("DEBUG: Video Information:")
        for key, value in video_info_dict.items():
            print(f"DEBUG: {key}: {value}")
            os.environ[key] = value    # Because os.environ() ONLY set/get environment variables within the life of the PYTHON process
            #debug_value = os.environ[key]
            #print(f"DEBUG: after set_env_variable '{key}' = '{debug_value}'")
            set_cmd_list.append(f'SET "{key}={value}"')
    elif section_name.lower() == "Audio".lower():
        audio_info_dict = get_audio_info(mediafile, prefix)
        print("DEBUG: Audio Information:")
        for key, value in audio_info_dict.items():
            print(f"DEBUG: {key}: {value}")
            os.environ[key] = value    # Because os.environ() ONLY set/get environment variables within the life of the PYTHON process
            #debug_value = os.environ[key]
            #print(f"DEBUG: after set_env_variable '{key}' = '{debug_value}'")
            set_cmd_list.append(f'SET "{key}={value}"')
    else:
        print(f"Error: Invalid MediaInfo section '{section_name}' processing {mediafile}\nPlease specify a valid section (e.g., Video, Audio, General).")
        exit(1)

    set_cmd_list.append(f'goto :eof')
    #print(f"DEBUG: set_cmd_list=\n{objPrettyPrint.pformat(set_cmd_list)}")

    # Open the cmd file for writing in overwrite mode
    output_cmd_file = args.output_cmd_file
    if os.path.exists(output_cmd_file):
        os.remove(output_cmd_file)
    # Open the cmd file for writing in overwrite mode
    with open(output_cmd_file, 'w') as cmd_file:
        # Write each item in the list to the file followed by a newline character
        for cmd_item in set_cmd_list:
            cmd_file.write(cmd_item + '\n')
