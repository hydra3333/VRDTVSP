import os
import sys
import re
import argparse
from datetime import datetime
import ctypes
from ctypes import wintypes
from ctypes import *        # for mediainfo ... load via ctypes.CDLL(r'.\MediaInfo.dll')
from typing import Union    # for mediainfo
from pathlib import Path
import json
import xml.etree.ElementTree as ET
import subprocess
import pprint
#from MediaInfoDLL3 import MediaInfo, Stream, Info, InfoOption
from pymediainfo import MediaInfo


def add_variable_to_list(key, value, set_cmd_list):
    set_cmd_list.append(f'SET "{key}={value}"')

def escape_special_chars(text):
    # Replace special characters with underscores.
    special_chars = r'<>|&"?*()\' @'    # leave : and / alone
    return re.sub(r'[%s]' % re.escape(special_chars), '_', text.strip()).replace('__', '_').replace('__', '_')

def process_stream(stream, prefix, set_cmd_list):
    # Create or overwrite environment variables with key/value pairs
    # Because os.environ() ONLY set/get environment variables within the life of the PYTHON process, add to a list
    for key, value in stream.items():
        if not isinstance(value, str):
            value = str(value)
        key = escape_special_chars(prefix + key)
        value = escape_special_chars(value.strip())
        #print(f"DEBUG: do set_env_variable '{key}'] = '{value}'")
        os.environ[key] = value    # Because os.environ() ONLY set/get environment variables within the life of the PYTHON process
        #debug_value = os.environ[key]
        #print(f"DEBUG: after set_env_variable '{key}' = '{debug_value}'")
        add_variable_to_list(key, value, set_cmd_list)

def process_general_section(general_info, prefix, set_cmd_list):
    # Process general section
    #print("Processing General section...")
    process_stream(general_info, prefix, set_cmd_list)

def process_section(section_name, streams, prefix, set_cmd_list):
    # Process elements within the section based on the section name
    # sort the streams based on their index within the specified codec type 
    # and then select the stream with the lowest index as the first stream for that codec type.
    if section_name.lower() == "general":
        #print("Processing General section...")
        process_stream(section, prefix, set_cmd_list)
    else:    
        codec_streams = sorted(streams, key=lambda x: x['index'])  # Sort streams based on index
        if len(codec_streams) > 0:
            #print(f"Processing first {section_name} stream ...")
            process_stream(codec_streams[0], prefix, set_cmd_list)  # Choose the first stream with the lowest index
        else:
            print(f"No ffprobe {section_name} stream found for {mediafile}")

if __name__ == "__main__":
    # REM prefix is usually "SRC_", "QSF_", "TARGET"
    # python.exe --ffprobe_dos_variablename "ffprobe_dos_variablename" --mediafile "!source_mediafile!" --prefix "!prefix!"
    # set !prefix!

    TERMINAL_WIDTH = 250
    objPrettyPrint = pprint.PrettyPrinter(width=TERMINAL_WIDTH, compact=False, sort_dicts=False)    # facilitates formatting 
    #print(f"DEBUG: {objPrettyPrint.pformat(a_list)}")

    parser = argparse.ArgumentParser(description="Parse media file with ffprobe and create environment variables.")
    parser.add_argument("--ffprobe_dos_variablename", help="Name of DOS variable for fully qualified ffprobe path", required=True)
    parser.add_argument("--mediafile", help="Path to the media file", required=True)
    parser.add_argument("--prefix", help="Prefix for environment variable keys", required=True)
    parser.add_argument("--output_cmd_file", help="Path to the cmd file containing the DOS SET statements", required=True)
    args = parser.parse_args()

    # Retrieve the name of the DOS variable for MediaInfo path from command-line arguments
    ffprobe_dos_variablename = args.ffprobe_dos_variablename
    mediafile = args.mediafile
    prefix = args.prefix

    # Retrieve the path of MediaInfo from the environment variable and Check if MediaInfo file path exists
    ffprobe_path = os.environ.get(ffprobe_dos_variablename)
    if not ffprobe_path or not os.path.exists(ffprobe_path):
        print(f"Error: ffprobe path not specified or does not exist for variable {ffprobe_dos_variablename}.")
        sys.exit(1)

    # Check if media file exists
    if not os.path.exists(mediafile):
        print(f"Error: Media file does not exist: {mediafile}")
        sys.exit(1)

    set_cmd_list = [ 'REM ---' ]
    set_cmd_list.append(f'DEL /F ".\tmp_echo_status.log">NUL 2>&1"')
    set_cmd_list.append(f'@ECHO>".\tmp_echo_status.log" 2>&1')
    set_cmd_list.append(f'set /p initial_echo_status=<".\tmp_echo_status.log"')
    set_cmd_list.append(f'DEL /F ".\tmp_echo_status.log">NUL 2>&1')
    set_cmd_list.append(f'set "initial_echo_status=!initial_echo_status:ECHO is =!"')
    set_cmd_list.append(f'set "initial_echo_status=!initial_echo_status:.=!"')
    set_cmd_list.append(f'REM ---')
    set_cmd_list.append(f'@ECHO OFF')
    set_cmd_list.append(f'echo prefix = "{prefix}"')
    set_cmd_list.append(f'REM List of DOS SET commands to define DOS variables')
    set_cmd_list.append(f'REM First, clear the variables with the chosen prefix')
    set_cmd_list.append(f'FOR /F "tokens=1,* delims==" %%G IN (\'SET {prefix}\') DO (SET "%%G=")')

    # Run ffprobe command to get JSON output
    ffprobe_subprocess_command = [ffprobe_path, "-v", "quiet", "-print_format", "json", "-show_format", "-show_streams", mediafile]
    #print(f"DEBUG: issuing subprocess command: {ffprobe_subprocess_command}")
    ffprobe_output = subprocess.check_output(ffprobe_subprocess_command).decode()
    #print(f"DEBUG: returned output string: {ffprobe_output}")

    # Parse JSON output
    ffprobe_data = json.loads(ffprobe_output)
    if ffprobe_data is None:
        print(f"Error: No ffprobe JSON data returned from: {mediafile}")
        sys.exit(1)
    if "streams" in ffprobe_data:
        section_name = "General".lower()
        prefix_X =  prefix + "G_"
        process_general_section(ffprobe_data["format"], prefix_X, set_cmd_list)
        for sn in [ "Video", "Audio" ]:
            section_name = sn.lower()
            prefix_X =  prefix + section_name[0].upper() + "_"
            streams = [s for s in ffprobe_data["streams"] if "codec_type" in s and s["codec_type"].lower() == section_name.lower()]
            process_section(section_name.lower(), streams, prefix_X, set_cmd_list)
    else:
        print(f"Error: No ffprobe streams detected processing {mediafile}\n")
        #sys.exit(1)
        pass

    set_cmd_list.append(f'@ECHO !initial_echo_status!')
    set_cmd_list.append(f'set "initial_echo_status="')
    set_cmd_list.append(f'goto :eof')
    #print(f"DEBUG: set_cmd_list=\n{objPrettyPrint.pformat(set_cmd_list)}")

    # Open the cmd file for writing in overwrite mode
    output_cmd_file = args.output_cmd_file
    if os.path.exists(output_cmd_file):
        os.remove(output_cmd_file)
    with open(output_cmd_file, 'w') as cmd_file:
        # Write each item in the list to the file followed by a newline character
        for cmd_item in set_cmd_list:
            cmd_file.write(cmd_item + '\n')

