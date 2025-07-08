### DRAFT ONLY
### guess on reasonable "chop" points - chops .25 seconds each side of a glitch  (25/4 = 6 frames either side)
### ffmpeg re-encode parameters missing, eg for aac and for nvenc
### deinterlacing to 50 fps progressive is done
### sharpening not yet done

import subprocess
import re
import sys
import os
import tempfile
from datetime import datetime, timedelta

def run_ffmpeg_command(cmd):
    result = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    return result.returncode, result.stdout, result.stderr

def detect_glitches(input_path, timeout=300):
    cmd = [
        "ffmpeg",
        "-fflags", "+discardcorrupt",
        "-v", "error",
        "-i", input_path,
        "-f", "null",
        "-"
    ]
    try:
        result = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                                text=True, timeout=timeout)
    except subprocess.TimeoutExpired:
        print("FFmpeg decoding timed out.")
        return []

    error_lines = result.stderr.splitlines()
    time_pattern = re.compile(r"time=(\d{2}:\d{2}:\d{2}\.\d{2,3})")
    error_pattern = re.compile(r"error|corrupt|invalid|failed", re.IGNORECASE)

    timestamps = []
    for line in error_lines:
        if error_pattern.search(line):
            m = time_pattern.search(line)
            if m:
                timestamps.append(m.group(1))

    def to_seconds(t):
        h, m, s = t.split(":")
        return int(h)*3600 + int(m)*60 + float(s)

    if not timestamps:
        return []

    ranges = []
    start = timestamps[0]
    prev = timestamps[0]

    for t in timestamps[1:]:
        if to_seconds(t) - to_seconds(prev) > 2.0:
            ranges.append((start, prev))
            start = t
        prev = t
    ranges.append((start, prev))

    def pad_time(t, seconds):
        dt = datetime.strptime(t, "%H:%M:%S.%f")
        dt += timedelta(seconds=seconds)
        if dt < datetime.strptime("00:00:00.000", "%H:%M:%S.%f"):
            dt = datetime.strptime("00:00:00.000", "%H:%M:%S.%f")
        return dt.strftime("%H:%M:%S.%f")[:-3]

    padded_ranges = [(pad_time(s, -0.25), pad_time(e, 0.25)) for s, e in ranges]
    return padded_ranges

def cut_segment(input_path, start, end, output_path, reencode=False):
    cmd = ["ffmpeg", "-hide_banner", "-loglevel", "error", "-i", input_path]

    # Map only first video and first audio streams
    cmd += ["-map", "0:v:0", "-map", "0:a:0"]

    cmd += ["-ss", start]
    if end:
        cmd += ["-to", end]

    if reencode:
        cmd += [
            "-vf", "bwdif=mode=1:deint=all",
            "-af", "aresample=async=1",
            "-c:v", "libx264",
            "-crf", "18",
            "-preset", "slow",
            "-c:a", "aac",
            "-b:a", "192k"
        ]
    else:
        cmd += ["-c:v", "copy", "-c:a", "copy"]

    cmd.append(output_path)
    returncode, _, _ = run_ffmpeg_command(cmd)
    return returncode == 0

def concat_segments(segment_files, output_path):
    with tempfile.NamedTemporaryFile(mode="w", delete=False, suffix=".txt") as list_file:
        for f in segment_files:
            list_file.write(f"file '{os.path.abspath(f)}'\n")
        list_filename = list_file.name

    cmd = [
        "ffmpeg", "-hide_banner", "-loglevel", "error",
        "-f", "concat", "-safe", "0",
        "-i", list_filename,
        "-c", "copy",
        output_path
    ]
    returncode, _, _ = run_ffmpeg_command(cmd)
    os.remove(list_filename)
    return returncode == 0

def main(input_path, output_path):
    glitches = detect_glitches(input_path)
    if not glitches:
        print("No glitches detected; copying file as-is.")
        cut_segment(input_path, "00:00:00.000", None, output_path, reencode=False)
        return

    print(f"Detected glitch segments: {glitches}")

    segment_files = []
    prev_end = "00:00:00.000"
    temp_dir = tempfile.mkdtemp(prefix="repair_ts_")

    for idx, (start, end) in enumerate(glitches, 1):
        if prev_end != start:
            clean_file = os.path.join(temp_dir, f"clean_{idx:03d}.ts")
            print(f"Copying clean segment {prev_end} to {start} -> {clean_file}")
            success = cut_segment(input_path, prev_end, start, clean_file, reencode=False)
            if not success:
                print(f"Error copying clean segment {prev_end}-{start}")
                sys.exit(1)
            segment_files.append(clean_file)

        glitch_file = os.path.join(temp_dir, f"glitch_{idx:03d}.ts")
        print(f"Re-encoding glitch segment {start} to {end} -> {glitch_file}")
        success = cut_segment(input_path, start, end, glitch_file, reencode=True)
        if not success:
            print(f"Error re-encoding glitch segment {start}-{end}")
            sys.exit(1)
        segment_files.append(glitch_file)

        prev_end = end

    tail_file = os.path.join(temp_dir, f"clean_tail.ts")
    print(f"Copying tail segment {prev_end} to EOF -> {tail_file}")
    success = cut_segment(input_path, prev_end, None, tail_file, reencode=False)
    if not success:
        print(f"Error copying tail segment {prev_end}-EOF")
        sys.exit(1)
    segment_files.append(tail_file)

    print(f"Concatenating {len(segment_files)} segments into {output_path}")
    success = concat_segments(segment_files, output_path)
    if not success:
        print("Error concatenating segments.")
        sys.exit(1)

    print("Repair complete.")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python repair_ts.py input.ts output.ts")
        sys.exit(1)

    main(sys.argv[1], sys.argv[2])
