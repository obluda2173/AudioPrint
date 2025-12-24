#!/bin/bash

# Define the target directory based on your tree output
TARGET_DIR="data"

# Check if ffmpeg is installed
if ! command -v ffmpeg &> /dev/null; then
    echo "Error: ffmpeg is not installed."
    echo "Please install it using: sudo apt install ffmpeg (or brew install ffmpeg)"
    exit 1
fi

echo "Scanning '$TARGET_DIR' for .mp3 files..."

# Find all .mp3 files recursively
find "$TARGET_DIR" -type f -name "*.mp3" | while read -r mp3_file; do
    
    # Create the new .wav filename string
    wav_file="${mp3_file%.mp3}.wav"

    # Convert using ffmpeg
    # -i: input file
    # -vn: skip video (good practice for audio files)
    # -acodec pcm_s16le: standard CD-quality WAV encoding
    # -loglevel error: suppresses verbose output (only shows errors)
    # -y: overwrites output if it already exists
    # < /dev/null: prevents ffmpeg from swallowing stdin inside the loop
    ffmpeg -i "$mp3_file" -vn -acodec pcm_s16le -loglevel error -y "$wav_file" < /dev/null

    # Check if the conversion command was successful
    if [ $? -eq 0 ]; then
        echo "Converted: $wav_file"
        # Remove the original mp3 file
        rm "$mp3_file"
    else
        echo "FAILED to convert: $mp3_file"
    fi

done

echo "All tasks finished."
