import os
import subprocess
import json
import argparse

def escape_special_chars(text):
    # Replace special characters with underscores.
    special_chars = r'<>|&"?*()\' '    # leave : and / alone
    return re.sub(r'[%s]' % re.escape(special_chars), '_', text)

def process_stream(stream, prefix):
    # Create or overwrite environment variables with key/value pairs
    for key, value in stream.items():
        key = escape_special_chars(prefix + key)
        value = escape_special_chars(value)
        os.environ[key] = value

def process_general_section(general_info, prefix):
    # Process general section
    print("Processing General section...")
    process_stream(general_info, prefix)

def old_process_section(section_name, section, prefix):
    # Process elements within the section based on the section name
    if section_name.lower() == "general".lower():
        print("Processing General section...")
        process_stream(section, prefix)
    else:    #elif section_name in ["video", "audio"]:
        print(f"Processing first {section_name} stream...")
        if len(section) > 0:
            process_stream(section[0], prefix)
        else:
            print(f"No {section_name} stream found.")

def process_section(section_name, streams, prefix):
    # Process elements within the section based on the section name
    # sort the streams based on their index within the specified codec type 
    # and then select the stream with the lowest index as the first stream for that codec type.
    if section_name.lower() == "general":
        print("Processing General section...")
        process_stream(section, prefix)
    else:    
        codec_streams = sorted(streams, key=lambda x: x['index'])  # Sort streams based on index
        if len(codec_streams) > 0:
            print(f"Processing first {section_name} stream...")
            process_stream(codec_streams[0], prefix)  # Choose the first stream with the lowest index
        else:
            print(f"No {section_name} stream found.")

if __name__ == "__main__":
    # eg clear, set with python3, then show
    # set "prefix=SRC_FF_V_"
    # REM set !prefix!
    # FOR /F "tokens=1,* delims==" %%G IN ('SET !prefix!') DO (SET "%%G=")
    # python.exe --ffprobe_dos_variablename "ffprobe_dos_variablename" --mediafile "!source_mediafile!" --prefix "!prefix!" --section "Video"
    # set !prefix!
    # set "prefix=SRC_FF_A_"
    # REM set !prefix!
    # FOR /F "tokens=1,* delims==" %%G IN ('SET !prefix!') DO (SET "%%G=")
    # python.exe --ffprobe_dos_variablename "ffprobe_dos_variablename" --mediafile "!source_mediafile!" --prefix "!prefix!" --section "Audio"
    # set !prefix!
    # set "prefix=SRC_FF_G_"
    # REM set !prefix!
    # FOR /F "tokens=1,* delims==" %%G IN ('SET !prefix!') DO (SET "%%G=")
    # python.exe --ffprobe_dos_variablename "ffprobe_dos_variablename" --mediafile "!source_mediafile!" --prefix "!prefix!" --section "General"
    # set !prefix!

    parser = argparse.ArgumentParser(description="Parse media file with ffprobe and create environment variables.")
    parser.add_argument("--ffprobe_dos_variablename", help="Name of DOS variable for fully qualified ffprobe path", required=True)
    parser.add_argument("--mediafile", help="Path to the media file", required=True)
    parser.add_argument("--prefix", help="Prefix for environment variable keys", required=True)
    parser.add_argument("--section", help="ffprobe section to process (e.g., Video, Audio, General)", required=True)
    args = parser.parse_args()

    # Retrieve the name of the DOS variable for MediaInfo path from command-line arguments
    ffprobe_dos_variablename = args.ffprobe_dos_variablename
    mediafile = args.mediafile
    prefix = args.prefix
    section_name = args.section.lower()  # Convert section name to lowercase for case-insensitive comparison

    # Retrieve the path of MediaInfo from the environment variable and Check if MediaInfo file path exists
    ffprobe_path = os.environ.get(ffprobe_dos_variablename)
    if not ffprobe_path or not os.path.exists(ffprobe_path):
        print(f"Error: ffprobe path not specified or does not exist for variable {ffprobe_dos_variablename}.")
        exit(1)

    # Check if media file exists
    if not os.path.exists(mediafile):
        print(f"Error: Media file does not exist: {mediafile}")
        exit(1)

    # Run ffprobe command to get JSON output
    ffprobe_output = subprocess.check_output([ffprobe_path, "-v", "quiet", "-print_format", "json", "-show_format", "-show_streams", mediafile]).decode()

    # Parse JSON output
    ffprobe_data = json.loads(ffprobe_output)
    if section_name.lower() == "general":
        process_general_section(ffprobe_data["format"], prefix)
    elif "streams" in ffprobe_data:
        streams = [s for s in ffprobe_data["streams"] if s["codec_type"] == section_name]    # eg "video", "audio"
        process_section(section_name, streams, prefix)
    else:
        print(f"Error: Invalid ffprobe section '{section_name}'. Please specify a valid section (e.g., Video, Audio, General).")
        exit(1)
