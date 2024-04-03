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

#
# THIS WILL ONLY WORK if the calling CMD commandline specifies a folder with DOUBLE backslashes
#

if __name__ == "__main__":
    TERMINAL_WIDTH = 250
    objPrettyPrint = pprint.PrettyPrinter(width=TERMINAL_WIDTH, compact=False, sort_dicts=False)	# facilitates formatting 
	#print(f"DEBUG: {objPrettyPrint.pformat(a_list)}")

    print(f"\n\nSTARTED Set file date-time timestamps")
    print(f"This will ONLY work when the calling dos commandline specifies a folder with DOUBLE backslashes like this:")
    print(f"   \"python3.exe\" \"Modify_File_Date_Timestamps.py\" --folder \"t:\\\\HDTV\\\\\" --recurse")
    parser = argparse.ArgumentParser(description="Set file date-time timestamps")
    parser.add_argument("--folder", default="G:\\HDTV\\000-TO-BE-PROCESSED", help="Folder to process")
    parser.add_argument("--recurse", action="store_true", help="Recursively process subdirectories")
    args = parser.parse_args()
    folder = args.folder
    recurse = args.recurse
    file_list = []
    valid_suffixes = ('.ts', '.mp4', '.mpg', '.vob', '.bprj')    #, '.mp3', '.aac', '.mp2')
    # Handling trailing spaces and backslashes, removing trailing ones too
    # The double backslashes below are because python uses backslash as an escaping character
    folder = folder.replace("\\\\", "\\").rstrip("\\").rstrip(" ")
    print(f"Incoming Folder='{folder}'")
    print(f"Recurse: {recurse}")
    print(f"Valid suffixes: {valid_suffixes}")
    if recurse:
        print(f"Gathering filenames with RECURSE for '{folder}'")
        for root, _, files in os.walk(folder):
            for file in files:
                if file.endswith(valid_suffixes):
                    file_list.append(os.path.join(root, file))
    else:
        print(f"Gathering filenames without RECURSE for '{folder}'")
        for file in os.listdir(folder):
            if os.path.isfile(os.path.join(folder, file)) and file.endswith(valid_suffixes):
                file_list.append(os.path.join(folder, file))
    print(f"STARTING Set file date-time timestamps in every {valid_suffixes} filename by Matching them with a regex match in Python ...")
    # Regex for extracting date string from filename
    date_pattern = r'\b\d{4}-\d{2}-\d{2}\b'
    #
    local_tz = pytz.timezone('Australia/Adelaide')  # Set your local timezone
    utc_tz = pytz.utc # Create a timezone object for UTC
    #
    for old_full_filename in file_list:
        filename = os.path.basename(old_full_filename)
        # look for a properly formatted date string in the filename
        match = re.search(date_pattern, filename)
        if match:
            date_string = match.group()
            date_from_file = datetime.strptime(date_string, "%Y-%m-%d") # Convert to datetime object
            date_from_file = local_tz.localize(date_from_file).replace(hour=0, minute=0, second=0, microsecond=0)  # Replace time portion with 00:00:00.00 in local timezone
            fs = "filename-date"
            #print(f"DEBUG: +++ date pattern match found in filename: {date_from_file} {old_full_filename}")
        else:
            creation_time = os.path.getctime(old_full_filename)
            date_from_file = datetime.fromtimestamp(creation_time)
            date_from_file = local_tz.localize(date_from_file).replace(hour=0, minute=0, second=0, microsecond=0)  # Replace time portion with 00:00:00.00 in local timezone
            fs = "creaton-date"
            #print(f"DEBUG: --- date pattern match NOT found in filename, using creation date of the file instead: {date_from_file} {old_full_filename}")
        # Set only modification date timestamp based on the date in the string. 
        # Python cannot set creation time.
        #    Usage: os.utime(filename, access_time, modification_time)
        #os.utime(old_full_filename, (date_from_file.timestamp(), date_from_file.timestamp()))
        #---
        # Set BOTH creation and modification date timestamp based on the date in the string.
        # Convert datetime object to Windows FILETIME format
        #time_windows = int((date_from_file - datetime(1601, 1, 1)).total_seconds() * 10**7)
        datetime_1601 = datetime(1601, 1, 1, tzinfo=utc_tz)
        time_difference = (date_from_file - datetime_1601).total_seconds() # Calculate time difference in seconds
        time_windows = int(time_difference * 10**7) # Convert time difference to FILETIME format
        # Open the file
        handle = ctypes.windll.kernel32.CreateFileW(old_full_filename, ctypes.wintypes.DWORD(256), 0, None, ctypes.wintypes.DWORD(3), 0, None)
        # Change BOTH creation and modification times
        ctypes.windll.kernel32.SetFileTime(handle, ctypes.byref(ctypes.c_ulonglong(time_windows)), None, ctypes.byref(ctypes.c_ulonglong(time_windows)))
        # Close the file handle
        ctypes.windll.kernel32.CloseHandle(handle)
        #---
        print(f"Set {fs} '{date_from_file}' into creation-date and modification-date on '{old_full_filename}'")
    print(f"FINISHED Set file date-time timestamps in every {valid_suffixes} filename by Matching them with a regex match in Python ...\n\n")
