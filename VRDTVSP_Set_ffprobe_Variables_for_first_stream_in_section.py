import os
import sys
import re
import argparse
from datetime import datetime
import pytz 
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

#DEBUG_MODE = True
DEBUG_MODE = False

def add_variable_to_list(key, value, set_cmd_list):
    set_cmd_list.append(f'SET "{key}={value}"')

def escape_special_chars(text):
    global DEBUG_MODE
    # Replace special characters with underscores.
    special_chars = r'<>|&"?*()\' @'    # leave : and / alone
    return re.sub(r'[%s]' % re.escape(special_chars), '_', text.strip()).replace('__', '_').replace('__', '_')

def process_stream(stream, prefix, set_cmd_list):
    # Create or overwrite environment variables with key/value pairs
    # Because os.environ() ONLY set/get environment variables within the life of the PYTHON process, add to a list
    global DEBUG_MODE
    if DEBUG_MODE:
        print("DEBUG: Processing Stream...", flush=True)
    for key, value in stream.items():
        if not isinstance(value, str):
            value = str(value)
        key = escape_special_chars(prefix + key)
        value = escape_special_chars(value.strip())
        if DEBUG_MODE:
            print(f"DEBUG: do set_env_variable '{key}'] = '{value}'", flush=True)
        os.environ[key] = value    # Because os.environ() ONLY set/get environment variables within the life of the PYTHON process
        debug_value = os.environ[key]
        if DEBUG_MODE:
            print(f"DEBUG: after set_env_variable '{key}' = '{debug_value}'", flush=True)
        add_variable_to_list(key, value, set_cmd_list)
    if DEBUG_MODE:
        print("DEBUG: Processing Stream finished.", flush=True)

def process_general_section(general_info, prefix, set_cmd_list):
    # Process general section
    global DEBUG_MODE
    if DEBUG_MODE:
        print("DEBUG: Processing General section...", flush=True)
    process_stream(general_info, prefix, set_cmd_list)
    if DEBUG_MODE:
        print("DEBUG: Processing General section finished.", flush=True)

def process_section(section_name, streams, prefix, set_cmd_list):
    # Process elements within the section based on the section name
    # sort the streams based on their index within the specified codec type 
    # and then select the stream with the lowest index as the first stream for that codec type.
    global DEBUG_MODE
    if DEBUG_MODE:
        print("DEBUG: Processing Section...", flush=True)
    if section_name.lower() == "general":
        if DEBUG_MODE:
            print("DEBUG: Processing General section...", flush=True)
        process_stream(section, prefix, set_cmd_list)
    else:    
        codec_streams = sorted(streams, key=lambda x: x['index'])  # Sort streams based on index
        if len(codec_streams) > 0:
            if DEBUG_MODE:
                print(f"DEBUG: Processing first {section_name} stream ...", flush=True)
            process_stream(codec_streams[0], prefix, set_cmd_list)  # Choose the first stream with the lowest index
        else:
            print(f"No ffprobe {section_name} stream found for {mediafile}", flush=True)
    if DEBUG_MODE:
        print("DEBUG: Processing Section finished.", flush=True)

if __name__ == "__main__":
    # REM prefix is usually "SRC_", "QSF_", "TARGET"
    # python.exe --ffprobe_dos_variablename "ffprobe_dos_variablename" --mediafile "!source_mediafile!" --prefix "!prefix!"
    # set !prefix!

    if DEBUG_MODE:
        print(f"DEBUG: Started program ...", flush=True)

    TERMINAL_WIDTH = 250
    objPrettyPrint = pprint.PrettyPrinter(width=TERMINAL_WIDTH, compact=False, sort_dicts=False)    # facilitates formatting 
    # example: print(f"DEBUG: {objPrettyPrint.pformat(a_list)}", flush=True)

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
        print(f"Error: ffprobe path not specified or does not exist for variable {ffprobe_dos_variablename}.", flush=True)
        sys.exit(1)

    # Check if media file exists
    if not os.path.exists(mediafile):
        print(f"Error: Media file does not exist: {mediafile}", flush=True)
        sys.exit(1)

    set_cmd_list = [ 'REM ---' ]
    set_cmd_list.append(f'DEL /F ".\\tmp_echo_status.log">NUL 2>&1"')
    set_cmd_list.append(f'@ECHO>".\\tmp_echo_status.log" 2>&1')
    # DEBUG:
    set_cmd_list.append(f'TYPE ".\\tmp_echo_status.log"')
    #
    set_cmd_list.append(f'set /p initial_echo_status=<".\\tmp_echo_status.log"')
    set_cmd_list.append(f'DEL /F ".\\tmp_echo_status.log">NUL 2>&1')
    if DEBUG_MODE:
        set_cmd_list.append(f'echo DEBUG: 1 initial_echo_status=!initial_echo_status!')
    set_cmd_list.append(f'set "initial_echo_status=!initial_echo_status:ECHO is =!"')
    if DEBUG_MODE:
        set_cmd_list.append(f'echo DEBUG: 2 initial_echo_status=!initial_echo_status!')
    set_cmd_list.append(f'set "initial_echo_status=!initial_echo_status:.=!"')
    if DEBUG_MODE:
        set_cmd_list.append(f'echo DEBUG: 3 initial_echo_status=!initial_echo_status!')
    set_cmd_list.append(f'REM ---')
    set_cmd_list.append(f'@ECHO OFF')
    set_cmd_list.append(f'echo prefix = "{prefix}"   Initial echo status=!initial_echo_status!')
    set_cmd_list.append(f'REM List of DOS SET commands to define DOS variables')
    set_cmd_list.append(f'ECHO Initialize: Clear variables with the prefix \'{prefix}\' ')
    set_cmd_list.append(f'ECHO Ignore any message like \'Environment variable {prefix} not defined\'')
    set_cmd_list.append(f'FOR /F "tokens=1,* delims==" %%G IN (\'SET {prefix}\') DO (SET "%%G=") >NUL 2>&1')

    # Run ffprobe command to get JSON output
    ffprobe_subprocess_command = [ffprobe_path, "-probesize", "100M", "-v", "quiet", "-print_format", "json", "-show_format", "-show_streams", mediafile]
    print(f"DEBUG: issuing subprocess command: {ffprobe_subprocess_command}", flush=True)
    ffprobe_output = subprocess.check_output(ffprobe_subprocess_command).decode()
    print(f"DEBUG: returned output string: {ffprobe_output}", flush=True)

    # Parse JSON output
    ffprobe_data = json.loads(ffprobe_output)
    if ffprobe_data is None:
        print(f"Error: No ffprobe JSON data returned from: {mediafile}", flush=True)
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
        print(f"Error: No ffprobe streams detected processing {mediafile}\n", flush=True)
        #sys.exit(1)
        pass

    set_cmd_list.append(f'@ECHO !initial_echo_status!')
    set_cmd_list.append(f'set "initial_echo_status="')
    set_cmd_list.append(f'goto :eof')
    if DEBUG_MODE:
        print(f"DEBUG: set_cmd_list=\n{objPrettyPrint.pformat(set_cmd_list)}", flush=True)

    # Open the cmd file for writing in overwrite mode
    output_cmd_file = args.output_cmd_file
    if os.path.exists(output_cmd_file):
        os.remove(output_cmd_file)
    with open(output_cmd_file, 'w', encoding='utf-8-sig', newline='\r\n') as cmd_file:
        # Write each item in the list to the file followed by a newline character
        if DEBUG_MODE:
            print(f"DEBUG: start writing commands to '{output_cmd_file}' ...", flush=True)
        for cmd_item in set_cmd_list:
            cmd_file.write(cmd_item + '\n')
            if DEBUG_MODE:
                print(f"DEBUG: writing: '{cmd_item}'", flush=True)
        if DEBUG_MODE:
            print(f"DEBUG: end writing commands to '{output_cmd_file}' ...", flush=True)
    if DEBUG_MODE:
        print(f"DEBUG: Finished program ...", flush=True)

