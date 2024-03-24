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
import pprint

def add_variable_to_list(key, value, set_cmd_list):
    set_cmd_list.append(f'SET "{key}={value}"')

def escape_special_chars(text):
    # Replace special characters with underscores.
    special_chars = r'<>|&"?*()\' '    # leave : and / alone
    return re.sub(r'[%s]' % re.escape(special_chars), '_', text)

def process_stream(stream, prefix, set_cmd_list):
    # Create or overwrite DOS environment variables with key/value pairs
    for child in stream:
        if not isinstance(value, str):
            value = str(value)
        key = escape_special_chars(prefix + child.tag)
        value = escape_special_chars(child.text.strip())
        #print(f"DEBUG: do set_env_variable '{key}'] = '{value}'")
        os.environ[key] = value    # Because os.environ() ONLY set/get environment variables within the life of the PYTHON process
        #debug_value = os.environ[key]
        #print(f"DEBUG: after set_env_variable '{key}' = '{debug_value}'")
        add_variable_to_list(key, value, set_cmd_list)

def process_section(section_name_capitalize, section, prefix, set_cmd_list):
    # Process elements within the section based on the section name
    if section.tag.lower() == "general":
        print(f"Processing General section...")
        for element in section:
            if not isinstance(value, str):
                value = str(value)
            key = escape_special_chars(prefix + element.tag)
            value = escape_special_chars(element.text.strip())
            os.environ[key] = value    # Because os.environ() ONLY set/get environment variables within the life of the PYTHON process
            #debug_value = os.environ[key]
            #print(f"DEBUG: after set_env_variable '{key}' = '{debug_value}'")
            add_variable_to_list(key, value, set_cmd_list)
    else:    # eg if section.tag.lower() == "video":
        print(f"Processing first track in section {section_name_capitalize} ...")
        first_track = section.find("./track")
        if first_track:
            process_stream(first_track, prefix, set_cmd_list)
        else:
            print(f"No track found in section: {section_name_capitalize} ... tag={section.tag} for {mediafile}")
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

    # Run MediaInfo command to generate XML output into a string
    mediainfo_subprocess_command = [mediainfo_path, "--Output=XML", mediafile]
    #print(f"DEBUG: issuing subprocess command: {mediainfo_subprocess_command}")
    mediainfo_output = subprocess.check_output(mediainfo_subprocess_command).decode()
    #print(f"DEBUG: returned output string: {mediainfo_output}")

    # Parse MediaInfo XML output in the string
    set_cmd_list = [ f'echo prefix = "{prefix}"' ]
    set_cmd_list.append(f'REM List of DOS SET commands to define DOS variables')
    set_cmd_list.append(f'REM First, clear the variables with the chosen prefix')
    set_cmd_list.append(f'FOR /F "tokens=1,* delims==" %%G IN (\'SET !prefix!\') DO (SET "%%G=")')
    root = ET.fromstring(mediainfo_output)

    # Find the specified section in the MediaInfo output
    section_name_capitalize = section_name.capitalize()
    section = root.find(f"./{section_name_capitalize}")  # Find section in correct case
    if section:
        process_section(section_name_capitalize, section, prefix, set_cmd_list)
    else:
        print(f"Error: Invalid MediaInfo section '{section_name_capitalize}' processing {mediafile}\nPlease specify a valid section (e.g., Video, Audio, General).")
        exit(1)
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


