# Run like:
#   python "G:\HDTV\VRDTVSP_Set_Mediainfo_Variables_for_first_stream_in_section.py" --mediainfo_dos_variablename "mediainfoexe64" --mediafile "G:\HDTV\file1.ts" --prefix "SRC_MI_" --output_cmd_file="D:\VRDTVSP-SCRATCH\temp_cmd_file.bat" 
#
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
import chardet
from charset_normalizer import from_bytes as cn_from_bytes
import pprint
#from MediaInfoDLL3 import MediaInfo, Stream, Info, InfoOption
from pymediainfo import MediaInfo

#IS_VERBOSE = True
IS_VERBOSE = False

# Windows Error Codes from CLause AI :=
# Windows System Error Codes (from winerror.h)
# https://learn.microsoft.com/en-us/windows/win32/debug/system-error-codes
# Success
ERROR_SUCCESS = 0                       # The operation completed successfully
# Failures
ERROR_INVALID_FUNCTION = 1
# File/Path errors
ERROR_FILE_NOT_FOUND = 2                # The system cannot find the file specified
ERROR_PATH_NOT_FOUND = 3                # The system cannot find the path specified
ERROR_ACCESS_DENIED = 5                 # Access is denied
ERROR_INVALID_DATA = 13
ERROR_INVALID_DRIVE = 15                # The system cannot find the drive specified
ERROR_NOT_READY = 21                    # The device is not ready
ERROR_BAD_LENGTH = 24                   # The program issued a command but the command length is incorrect
ERROR_SHARING_VIOLATION = 32            # The process cannot access the file because it is being used by another process
ERROR_HANDLE_EOF = 38                   # Reached the end of the file
ERROR_NOT_SUPPORTED = 50                # The request is not supported
ERROR_BAD_NETPATH = 53                  # The network path was not found
ERROR_ALREADY_EXISTS = 80               # The file exists
# Parameter/Data errors
ERROR_INVALID_PARAMETER = 87            # The parameter is incorrect
ERROR_INSUFFICIENT_BUFFER = 122         # The data area passed to a system call is too small
ERROR_INVALID_NAME = 123                # The filename, directory name, or volume label syntax is incorrect
ERROR_MOD_NOT_FOUND = 126               # The specified module could not be found
ERROR_PROC_NOT_FOUND = 127              # The specified procedure could not be found
ERROR_INVALID_FLAGS = 1004              # Invalid flags
ERROR_UNRECOGNIZED_MEDIA = 1785         # The disk media is not recognized. It may not be formatted
# Data format errors
ERROR_INVALID_DATA = 13                 # The data is invalid
ERROR_BAD_FORMAT = 11                   # An attempt was made to load a program with an incorrect format
ERROR_CRC = 23                          # Data error (cyclic redundancy check)
ERROR_BAD_FILE_TYPE = 222               # The file type being saved or retrieved has been blocked
# Operation errors  
ERROR_CALL_NOT_IMPLEMENTED = 120        # This function is not supported on this system
ERROR_CANCELLED = 1223                  # The operation was canceled by the user
ERROR_TIMEOUT = 1460                    # This operation returned because the timeout period expired
# Process/Resource errors
ERROR_OUTOFMEMORY = 14                  # Not enough storage is available to complete this operation
ERROR_NOT_ENOUGH_MEMORY = 8             # Not enough memory resources are available to process this command
ERROR_NO_PROC_SLOTS = 89                # The system cannot start another process at this time

def Attempt_to_detect_mediainfo_output_encoding(raw_bytes):
    """
    We are forced to try various encodings because mediainfo swaps them around willy nilly.
    Try to detect/guess encoding for mediainfo output bytes and return
    (encoding_name, decoded_text).
    Strict decode attempts are used (no silent replacement) so we know
    the decode was valid. If nothing decodes strictly, returns (None, None).
    """
    global IS_VERBOSE

    if IS_VERBOSE:
        print(f"Entered: Attempt_to_detect_mediainfo_output_encoding", flush=True)
    #---
    # Attempt to detect the encoding via charset_normalizer (better for Python3/utf-8-ish data than chardet)
    cn_result = None
    cn_detected_bytes = None
    cn_detected_this_time = None
    cn_detected_confidence = None
    try:
        cn_result = cn_from_bytes(raw_bytes)
        if cn_result:
            cn_detected_bytes = cn_result.best()
            if cn_detected_bytes:
                cn_detected_this_time = cn_detected_bytes.encoding
                # charset_normalizer has 'percent' idea but not a single confidence number; use None or estimated
                cn_detected_confidence = getattr(cn_detected_bytes, "confidence", None)
    except Exception:
        # charset_normalizer not installed or failed
        pass
    if cn_detected_this_time:
        cn_detected_this_time = cn_detected_this_time.strip().lower()
    #---
    # Attempt to detect the encoding via chardet
    chardet_detected_bytes = None
    chardet_detected_this_time = None
    chardet_detected_confidence = None
    try:
        chardet_detected_bytes = chardet.detect(raw_bytes)
        if chardet_detected_bytes:
            chardet_detected_this_time = chardet_detected_bytes.get('encoding')
            chardet_detected_confidence = chardet_detected_bytes.get('confidence')
    except Exception:
        # chardet not installed or failed
        pass
    if chardet_detected_this_time:
        chardet_detected_this_time = chardet_detected_this_time.strip().lower()
    #---
    # Attempt to detect Windows codepage OEM first because your environment is Windows console
    windows_cp = None
    windows_cp_encoding = None
    try:
        windows_cp = ctypes.windll.kernel32.GetOEMCP()  # e.g. 850
        windows_cp_encoding = f'cp{windows_cp}'
    except Exception:
        # failed to get windows codepage
        pass
    if windows_cp_encoding:
        windows_cp_encoding = windows_cp_encoding.strip().lower()
    #---
    # create a list of candidate encodings:
    candidate_encodings = []
    # add candicate encodings in order of likelihood
    if windows_cp_encoding and windows_cp_encoding not in candidate_encodings:
        windows_cp_encoding = windows_cp_encoding.strip().lower()
        candidate_encodings.append(windows_cp_encoding)
    if cn_detected_this_time and cn_detected_this_time not in candidate_encodings:
        cn_detected_this_time = cn_detected_this_time.strip().lower()
        candidate_encodings.append(cn_detected_this_time)
    if chardet_detected_this_time and chardet_detected_this_time not in candidate_encodings:
        chardet_detected_this_time = chardet_detected_this_time.strip().lower()
        candidate_encodings.append(chardet_detected_this_time)
    #
    # finally, always try these common encodings afterwards (utf-8 with/without BOM, utf-16 variations, windows-1252, latin-1)
    for enc in ('utf-8-sig', 'utf-8', 'utf-16', 'utf-16le', 'utf-16be', 'cp850', 'cp1252', 'latin-1'):
        if enc not in candidate_encodings:
            candidate_encodings.append(enc.strip().lower())
    #---
    # Go through the rigmarole of trying fallback encodings in the strict order which I defined
    mediainfo_encoding_this_time = None
    decoded_mediainfo_output = None
    decode_error = None
    for encoding in candidate_encodings:
        if not encoding:    # skip any bum entries
            continue
        try:
            decoded_mediainfo_output = raw_bytes.decode(encoding)
            # success, if it gets to here
            mediainfo_encoding_this_time = encoding # always put this line after the decode attempt
            break
        except UnicodeDecodeError as ude:
            decode_error = ude
            print(f"Candidate mediainfo encoding '{encoding}' rejected: UnicodeDecodeError: {decode_error}", file=sys.stderr)
            # try next candidate
            continue
        except LookupError:
            # unknown encoding name from detection - skip it
            print(f"Candidate mediainfo encoding '{encoding}' rejected: unknown encoding name", file=sys.stderr)
            continue
    #---
    if mediainfo_encoding_this_time is None:
        # None of the decodes succeeded strictly; fail fatally with an error message
        print("Fatal: failed to decode mediainfo output with any tried encoding.", file=sys.stderr)
        if decode_error:
            print(f"Last detected UnicodeDecodeError: {decode_error}", file=sys.stderr)
        sys.exit(ERROR_INVALID_DATA)
    #---
    # By this time we have successfully decoded whatever the mediainfo output is
    print(f"Candidate mediainfo encoding '{mediainfo_encoding_this_time}' accepted.")
    #print(f"DEBUG: returned output string: {decoded_mediainfo_output}")

    if IS_VERBOSE:
        print(f"Exiting: Attempt_to_detect_mediainfo_output_encoding", flush=True)
   
    return mediainfo_encoding_this_time, decoded_mediainfo_output

def add_variable_to_list(key, value, set_cmd_list):
    global IS_VERBOSE
    if IS_VERBOSE:
        print(f"Entered: add_variable_to_list", flush=True)
    set_cmd_list.append(f'SET "{key}={value}"')
    if IS_VERBOSE:
        print(f"Exiting: add_variable_to_list", flush=True)

def escape_special_chars(text):
    # Replace special characters with underscores.
    global IS_VERBOSE
    if IS_VERBOSE:
        print(f"Entered: escape_special_chars", flush=True)
    special_chars = r'<>|&"?*()\' @'    # leave : and / alone
    if IS_VERBOSE:
        print(f"Exiting: escape_special_chars", flush=True)
    return re.sub(r'[%s]' % re.escape(special_chars), '_', text.strip()).replace('__', '_').replace('__', '_')

def process_track2(track, prefix, set_cmd_list):
    # Create or overwrite environment variables with key/value pairs
    # Because os.environ() ONLY set/get environment variables within the life of the PYTHON process, add to a list
    global IS_VERBOSE
    if IS_VERBOSE:
        print(f"Entered: process_track2", flush=True)
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
    if IS_VERBOSE:
        print(f"Exiting: process_track2", flush=True)

def process_section2(section_name, tracks, prefix, set_cmd_list):
    # Process elements within the section based on the section name
    # sort the tracks based on their index within the specified codec type 
    # and then select the stream with the lowest index as the first stream for that codec type.
    global IS_VERBOSE
    if IS_VERBOSE:
        print(f"Entered: process_section2", flush=True)
    sorted_tracks = sorted(tracks, key=lambda x: x['StreamKindID'])  # Sort tracks based on StreamKindID
    if len(sorted_tracks) > 0:
        #print(f"Processing first {section_name} track ...")
        process_track2(sorted_tracks[0], prefix, set_cmd_list)  # Choose the first stream with the lowest index
    else:
        print(f"No mediainfo {section_name} track found for {mediafile}")
    if IS_VERBOSE:
        print(f"Exiting: process_section2", flush=True)

def process_section(section_name_capitalize, section, prefix, set_cmd_list):
    #print(f"DEBUG: json_data Section {section_name_capitalize}:\nSection Data: {section}\n{objPrettyPrint.pformat(section)}")
    #for key, value in section.items():
    #    print(f"DEBUG: Section {section_name_capitalize} key='{key}' value='{value}'")
    global IS_VERBOSE
    if IS_VERBOSE:
        print(f"Entered: process_section", flush=True)
    for key, value in section.items():
        if not isinstance(value, str):
            value = str(value)
        key = escape_special_chars(prefix.strip() + key.strip())
        value = escape_special_chars(value.strip())
        os.environ[key] = value
        add_variable_to_list(key, value, set_cmd_list)
    if IS_VERBOSE:
        print(f"Exiting: process_section", flush=True)

def quote_if_needed(arg):
    global IS_VERBOSE
    if ' ' in arg or '"' in arg or '\t' in arg:
        return f'"{arg}"'
    return arg

if __name__ == "__main__":
    # REM prefix is usually "SRC_", "QSF_", "TARGET"
    # python.exe --mediainfo_dos_variablename "mediainfo_dos_variablename" --mediafile "!source_mediafile!" --prefix "!prefix!"
    # set !prefix!

    TERMINAL_WIDTH = 250
    objPrettyPrint = pprint.PrettyPrinter(width=TERMINAL_WIDTH, compact=False, sort_dicts=False)    # facilitates formatting 
    #print(f"DEBUG: {objPrettyPrint.pformat(a_list)}")

    if IS_VERBOSE:
        print(f"Entered: {' '.join(quote_if_needed(arg) for arg in sys.argv)}", flush=True)

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
        print(f"Error: MediaInfo path not specified or does not exist for variable {mediainfo_dos_variablename}.", flush=True)
        sys.exit(ERROR_PATH_NOT_FOUND)

    # Check if media file exists
    if not os.path.exists(mediafile):
        print(f"Error: Media file does not exist at path {mediafile}.", flush=True)
        sys.exit(ERROR_FILE_NOT_FOUND)

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
    set_cmd_list.append(f'ECHO Initialize: Clear variables with the prefix \'{prefix}\' ')
    set_cmd_list.append(f'ECHO Ignore any message like \'Environment variable {prefix} not defined\'')
    set_cmd_list.append(f'FOR /F "tokens=1,* delims==" %%G IN (\'SET {prefix}\') DO (SET "%%G=") >NUL 2>&1')

    # Run MediaInfo command to generate JSON output
    mediainfo_subprocess_command = [mediainfo_path, '--Full', '--Output=JSON', '--BOM', mediafile ]
    #print(f"DEBUG: issuing subprocess command: {mediainfo_subprocess_command}")
    #
    #OLD:
    #mediainfo_output = subprocess.check_output(mediainfo_subprocess_command).decode('utf-8', 'ignore')
    #mediainfo_output = subprocess.check_output(mediainfo_subprocess_command).decode('utf-8-sig')
    #mediainfo_output = subprocess.check_output(mediainfo_subprocess_command)
    #
    # NEW:
    # run and capture raw bytes (not text)
    if IS_VERBOSE:
        print(f"subprocess.run calling: {objPrettyPrint.pformat(mediainfo_subprocess_command)}", flush=True)
    result = subprocess.run(mediainfo_subprocess_command, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if IS_VERBOSE:
        print(f"subprocess.run returned from: {objPrettyPrint.pformat(mediainfo_subprocess_command)}", flush=True)

    # Do this before checking stderr and abort if an error occurred
    if result.returncode != 0:
        print(f"Mediainfo exited with code {result.returncode}", file=sys.stderr, flush=True)
        if result.stderr:
            stderr_encoding_this_time, stderr_output = Attempt_to_detect_mediainfo_output_encoding(result.stderr)
            print(f"Mediainfo stderr: {stderr_output}", file=sys.stderr, flush=True)
        sys.exit(ERROR_INVALID_FUNCTION)

    # If mediainfo wrote anything to stderr, log it and abort
    if result.stderr:
        # Attempt to detect the stderr encoding, if it returns we're good to go.
        stderr_bytes = result.stderr
        stderr_encoding_this_time, stderr_output = Attempt_to_detect_mediainfo_output_encoding(stderr_bytes)
        if stderr_output.strip():
            print(f"Mediainfo error, stderr: {stderr_output}", file=sys.stderr, flush=True)
        sys.exit(ERROR_INVALID_FUNCTION)

    # When we get to here, no errors so far ...
    # Attempt to detect the real output encoding, if it returns we're good to go.
    raw_bytes = result.stdout
    mediainfo_encoding_this_time, mediainfo_output = Attempt_to_detect_mediainfo_output_encoding(raw_bytes)

    # Parse JSON output
    if IS_VERBOSE:
        print(f"Start Parsing JSON result of mediainfo", flush=True)
    json_data = json.loads(mediainfo_output)
    if json_data is None:
        print(f"Error: No mediainfo JSON data returned from: {mediafile}", flush=True)
        sys.exit(ERROR_INVALID_DATA)
    if "track" in json_data['media']:
        for sn in [ "General", "Video", "Audio" ]:
            section_name = sn.capitalize()
            prefix_X =  prefix + section_name[0].upper() + "_"
            tracks = [t for t in json_data['media']['track'] if "@type" in t and t["@type"].lower() == section_name.lower()]
            process_section2(section_name.capitalize(), tracks, prefix_X, set_cmd_list)
    else:
        print(f"Error: No mediainfo tracks detected processing {mediafile}\n", flush=True)
        #sys.exit(ERROR_INVALID_DATA)
        pass
    if IS_VERBOSE:
        print(f"End Parsing JSON result of mediainfo", flush=True)

    set_cmd_list.append(f'@ECHO !initial_echo_status!')
    set_cmd_list.append(f'set "initial_echo_status="')
    set_cmd_list.append(f'goto :eof')
    #print(f"DEBUG: set_cmd_list=\n{objPrettyPrint.pformat(set_cmd_list)}", flush=True)

    # Open the cmd file for writing in overwrite mode
    output_cmd_file = args.output_cmd_file
    if os.path.exists(output_cmd_file):
        os.remove(output_cmd_file)
    # We need a BOM for some Windows consumers, use encoding='utf-8-sig'.
    with open(output_cmd_file, 'w', encoding='utf-8-sig', newline='\r\n') as cmd_file:
        for cmd_item in set_cmd_list:
            cmd_file.write(cmd_item + '\n') # use \n to force the newline as specified in 'newline='
            if IS_VERBOSE:
                print(f"Wrote line to .bat file: {cmd_item}", flush=True)

    if IS_VERBOSE:
        print(f"Exiting: {' '.join(quote_if_needed(arg) for arg in sys.argv)}", flush=True)
