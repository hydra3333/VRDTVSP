import os
import re
import argparse
from datetime import datetime
#
# THIS WILL ONLY WORK if the calling CMD commandline specifies dates in the right format "YYYY-MM-DD HH.MM.SS.hhh"
#
import argparse
from datetime import datetime
if __name__ == "__main__":
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
