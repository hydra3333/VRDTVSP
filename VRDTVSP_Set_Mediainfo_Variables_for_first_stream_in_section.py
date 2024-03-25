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
    special_chars = r'<>|&"?*()\' '    # leave : and / alone
    return re.sub(r'[%s]' % re.escape(special_chars), '_', text)

def process_section(section_name_capitalize, section, prefix, set_cmd_list):
    for child in section:
        if not isinstance(value, str):
            value = str(value)
        key = escape_special_chars(prefix + child.tag)
        value = escape_special_chars(child.text.strip())
        os.environ[key] = value
        add_variable_to_list(key, value, set_cmd_list)

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
    TERMINAL_WIDTH = 250
    objPrettyPrint = pprint.PrettyPrinter(width=TERMINAL_WIDTH, compact=False, sort_dicts=False)	# facilitates formatting 
	#print(f"DEBUG: {objPrettyPrint.pformat(a_list)}")

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
        sys.exit(1)

    # Check if media file exists
    if not os.path.exists(mediafile):
        print(f"Error: Media file does not exist at path {mediafile}.")
        sys.exit(1)

    # Run MediaInfo command to generate JSON output
    #mediainfo_json_file = mediafile + ".mediainfo.json"
    #if os.path.exists(mediainfo_json_file):
    #    os.remove(mediainfo_json_file)
    mediainfo_subprocess_command = [mediainfo_path, '--Full', '--Output=JSON', '--BOM', mediafile ]
    #print(f"DEBUG: issuing subprocess command: {mediainfo_subprocess_command}")
    mediainfo_output = subprocess.check_output(mediainfo_subprocess_command).decode('utf-8', 'ignore')
    #print(f"DEBUG: returned output string: {mediainfo_output}")

    json_data = json.loads(mediainfo_output)
    print(f"DEBUG: json_data:\n{objPrettyPrint.pformat(json_data)}")

    # Check if the JSON file exists and load it then delete the file
    #if os.path.exists(mediainfo_json_file):
    #    with open(mediainfo_json_file, 'r') as j:
    #        json_data = json.load(j)
    #else:
    #    print(f"Error: MediaInfo JSON file does not exist at path '{mediainfo_json_file}'")
    #    sys.exit(1)
    #if os.path.exists(mediainfo_json_file):
    #    os.remove(mediainfo_json_file)

    # Find the specified section in the MediaInfo output
    section_name_capitalize = section_name.capitalize()
    section_track_data = None
    # Iterate through the tracks and check if any track has '@type' equal to 'General'
    for track in json_data['media']['track']:
        if track.get('@type') == section_name_capitalize:
            section_track_data = track
            break
    if not section_track_data:
        print(f"Error: Invalid MediaInfo section '{section_name_capitalize}' processing {mediafile}\nPlease specify a valid section (e.g., Video, Audio, General).")
        sys.exit(1)
    else:
        print(f"DEBUG: json_data Section {section_name_capitalize}:\n{objPrettyPrint.pformat(section)}")
        print(f"DEBUG: calling process_section for '{section_name_capitalize}'")
        process_section(section_name_capitalize, section_track_data, prefix, set_cmd_list)
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

