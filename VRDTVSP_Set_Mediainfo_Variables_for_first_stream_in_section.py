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

def process_track2(track, prefix, set_cmd_list):
    # Create or overwrite environment variables with key/value pairs
    # Because os.environ() ONLY set/get environment variables within the life of the PYTHON process, add to a list
    for key, value in track.items():
        if not isinstance(value, str):
            value = str(value)
        key = escape_special_chars(prefix + key)
        value = escape_special_chars(value.strip())
        #print(f"DEBUG: do set_env_variable '{key}'] = '{value}'")
        os.environ[key] = value    # Because os.environ() ONLY set/get environment variables within the life of the PYTHON process
        #debug_value = os.environ[key]
        #print(f"DEBUG: after set_env_variable '{key}' = '{debug_value}'")
        add_variable_to_list(key, value, set_cmd_list)

def process_section2(section_name, tracks, prefix, set_cmd_list):
    # Process elements within the section based on the section name
    # sort the tracks based on their index within the specified codec type 
    # and then select the stream with the lowest index as the first stream for that codec type.
    sorted_tracks = sorted(tracks, key=lambda x: x['StreamKindID'])  # Sort tracks based on StreamKindID
    if len(sorted_tracks) > 0:
        #print(f"Processing first {section_name} track ...")
        process_track2(sorted_tracks[0], prefix, set_cmd_list)  # Choose the first stream with the lowest index
    else:
        print(f"No mediainfo {section_name} track found for {mediafile}")

def process_section(section_name_capitalize, section, prefix, set_cmd_list):
    #print(f"DEBUG: json_data Section {section_name_capitalize}:\nSection Data: {section}\n{objPrettyPrint.pformat(section)}")
    #for key, value in section.items():
    #    print(f"DEBUG: Section {section_name_capitalize} key='{key}' value='{value}'")
    for key, value in section.items():
        if not isinstance(value, str):
            value = str(value)
        key = escape_special_chars(prefix.strip() + key.strip())
        value = escape_special_chars(value.strip())
        os.environ[key] = value
        add_variable_to_list(key, value, set_cmd_list)

if __name__ == "__main__":
    # REM prefix is usually "SRC_", "QSF_", "TARGET"
    # python.exe --mediainfo_dos_variablename "mediainfo_dos_variablename" --mediafile "!source_mediafile!" --prefix "!prefix!"
    # set !prefix!

    TERMINAL_WIDTH = 250
    objPrettyPrint = pprint.PrettyPrinter(width=TERMINAL_WIDTH, compact=False, sort_dicts=False)    # facilitates formatting 
    #print(f"DEBUG: {objPrettyPrint.pformat(a_list)}")

    parser = argparse.ArgumentParser(description="Parse media file with MediaInfo and create DOS variables.")
    parser.add_argument("--mediainfo_dos_variablename", help="Name of DOS variable for fully qualified MediaInfo path", required=True)
    parser.add_argument("--mediafile", help="Path to the media file", required=True)
    parser.add_argument("--prefix", help="Prefix for DOS variable keys", required=True)
    parser.add_argument("--output_cmd_file", help="Path to the cmd file containing the DOS SET statements", required=True)
    args = parser.parse_args()

    # Retrieve the name of the DOS variable for MediaInfo path from command-line arguments
    mediainfo_dos_variablename = args.mediainfo_dos_variablename
    mediafile = args.mediafile
    prefix = args.prefix

    # Retrieve the path of MediaInfo from the environment variable and Check if MediaInfo file path exists
    mediainfo_path = os.environ.get(mediainfo_dos_variablename)
    if not mediainfo_path or not os.path.exists(mediainfo_path):
        print(f"Error: MediaInfo path not specified or does not exist for variable {mediainfo_dos_variablename}.")
        sys.exit(1)

    # Check if media file exists
    if not os.path.exists(mediafile):
        print(f"Error: Media file does not exist at path {mediafile}.")
        sys.exit(1)

    set_cmd_list = [ 'REM ---' ]
    set_cmd_list.append(f'DEL /F ".\\tmp_echo_status.log">NUL 2>&1"')
    set_cmd_list.append(f'@ECHO>".\\tmp_echo_status.log" 2>&1')
    #set_cmd_list.append(f'TYPE ".\\tmp_echo_status.log"')
    set_cmd_list.append(f'set /p initial_echo_status=<".\\tmp_echo_status.log"')
    set_cmd_list.append(f'DEL /F ".\\tmp_echo_status.log">NUL 2>&1')
    #set_cmd_list.append(f'echo DEBUG: 1 initial_echo_status=!initial_echo_status!')
    set_cmd_list.append(f'set "initial_echo_status=!initial_echo_status:ECHO is =!"')
    #set_cmd_list.append(f'echo DEBUG: 2 initial_echo_status=!initial_echo_status!')
    set_cmd_list.append(f'set "initial_echo_status=!initial_echo_status:.=!"')
    #set_cmd_list.append(f'echo DEBUG: 3 initial_echo_status=!initial_echo_status!')
    set_cmd_list.append(f'REM ---')
    set_cmd_list.append(f'@ECHO OFF')
    set_cmd_list.append(f'echo prefix = "{prefix}"   Initial echo status=!initial_echo_status!')
    set_cmd_list.append(f'REM List of DOS SET commands to define DOS variables')
    set_cmd_list.append(f'REM First, clear the variables with the chosen prefix')
    set_cmd_list.append(f'FOR /F "tokens=1,* delims==" %%G IN (\'SET {prefix}\') DO (SET "%%G=") >NUL 2>&1')

    # Run MediaInfo command to generate JSON output
    mediainfo_subprocess_command = [mediainfo_path, '--Full', '--Output=JSON', '--BOM', mediafile ]
    #print(f"DEBUG: issuing subprocess command: {mediainfo_subprocess_command}")
    mediainfo_output = subprocess.check_output(mediainfo_subprocess_command).decode('utf-8', 'ignore')
    #print(f"DEBUG: returned output string: {mediainfo_output}")

    # Parse JSON output
    json_data = json.loads(mediainfo_output)
    if json_data is None:
        print(f"Error: No mediainfo JSON data returned from: {mediafile}")
        sys.exit(1)
    if "track" in json_data['media']:
        for sn in [ "General", "Video", "Audio" ]:
            section_name = sn.capitalize()
            prefix_X =  prefix + section_name[0].upper() + "_"
            tracks = [t for t in json_data['media']['track'] if "@type" in t and t["@type"].lower() == section_name.lower()]
            process_section2(section_name.capitalize(), tracks, prefix_X, set_cmd_list)
    else:
        print(f"Error: No mediainfo tracks detected processing {mediafile}\n")
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

