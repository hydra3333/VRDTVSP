import os
import re
import argparse
from datetime import datetime
#
# THIS WILL ONLY WORK if the calling CMD commandline specifies a folder with DOUBLE backslashes
#

if __name__ == "__main__":
    print(f"STARTED Set file date-time timestamps")
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
    # Handling trailing spaces and backslashes, tremoving trailing ones too
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
    for old_full_filename in file_list:
        filename = os.path.basename(old_full_filename)
        # look for a properly formatted date string in the filename
        match = re.search(date_pattern, filename)
        if match:
            date_string = match.group()
            #date_from_file = datetime.strptime(date_string, "%Y-%m-%d").date()
            date_from_file = datetime.strptime(date_string, "%Y-%m-%d") # Convert to datetime object
            #print(f"Date string detected in filename string, using date {date_from_file} from {old_full_filename}")
            fs = "filename-date"
        else:
            date_from_file = datetime.fromtimestamp(os.path.getctime(old_full_filename)).date()
            #print(f"No date string detected in filename, using creation-date {date_from_file} of file {old_full_filename}")
            fs = "creaton-date"
        # Set both creation and modification date timestamps based on the date in the string
        os.utime(old_full_filename, (date_from_file.timestamp(), date_from_file.timestamp()))
        print(f"Set {fs} '{date_from_file}' into creation and modification dates on '{old_full_filename}'")
    print(f"FINISHED Set file date-time timestamps in every {valid_suffixes} filename by Matching them with a regex match in Python ...")
