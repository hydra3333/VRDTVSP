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
# THIS WILL ONLY WORK if the calling CMD commandline specifies dates in the right format "YYYY-MM-DD HH.MM.SS.hhh"
#
import argparse
from datetime import datetime
if __name__ == "__main__":
    TERMINAL_WIDTH = 250
    objPrettyPrint = pprint.PrettyPrinter(width=TERMINAL_WIDTH, compact=False, sort_dicts=False)	# facilitates formatting 
	#print(f"DEBUG: {objPrettyPrint.pformat(a_list)}")

    parser = argparse.ArgumentParser(description='Calculate duration between two date time strings.')
    parser.add_argument("--start_datetime", type=str, help='Start date and time string (YYYY-MM-DD HH.MM.SS.hhh)')
    parser.add_argument("--end_datetime", type=str, help='End date and time string (YYYY-MM-DD HH.MM.SS.hhh)')
    parser.add_argument("--prefix_id", type=str, help='Prefix ID for the duration output')
    args = parser.parse_args()
    # Parse start and end datetime strings and display the difference
    dt_start_date_time = datetime.strptime(args.start_datetime, "%Y-%m-%d %H.%M.%S.%f")
    dt_end_date_time = datetime.strptime(args.end_datetime, "%Y-%m-%d %H.%M.%S.%f")
    duration = dt_end_date_time - dt_start_date_time
    days = duration.days
    hours, remainder = divmod(duration.seconds, 3600)
    minutes, seconds = divmod(remainder, 60)
    microseconds = duration.microseconds
    print(f"\n\n===== {args.prefix_id} DURATION: {days} days {hours} hours {minutes} minutes {seconds}.{microseconds:0{6}} seconds\n\n")
