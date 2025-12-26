import os
import random
import subprocess
from pydub import AudioSegment, effects

# --- CONFIGURATION ---
SOURCE_FOLDER = './test_files'
NOISE_FOLDER = './background_noise'
OUTPUT_FOLDER = './processed_8s_noise'

# Target duration in milliseconds (8 seconds = 8000 ms)
TARGET_DURATION = 8000

# Volume Config
# We normalize everything to this level first to ensure consistency
NORMALIZED_DB = -20.0
# How much louder/quieter the noise should be relative to the music?
# 0 = same volume as music. -5 = slightly quieter. -10 = background ambience.
NOISE_RELATIVE_DB = -3

def normalize_audio(segment, target_dBFS):
    """
    Normalizes audio to a specific dBFS level.
    This ensures the music and noise start at comparable volumes.
    """
    change_in_dBFS = target_dBFS - segment.dBFS
    return segment.apply_gain(change_in_dBFS)

def get_random_noise(noise_folder):
    noise_files = [f for f in os.listdir(noise_folder) if f.lower().endswith('.wav')]
    if not noise_files:
        raise Exception("No .wav files found in noise folder!")
    return os.path.join(noise_folder, random.choice(noise_files))

def copy_metadata_ffmpeg(source_path, processed_temp_path, final_output_path):
    """
    Uses FFmpeg to copy metadata from the source file to the processed file.
    This handles both ID3 and RIFF INFO tags reliably.
    """
    # Command explanation:
    # -i processed: Input 0 (our mixed audio)
    # -i source: Input 1 (original file with tags)
    # -map 0: Use audio from Input 0
    # -map_metadata 1: Use metadata from Input 1
    # -c copy: Copy the stream (do not re-encode)
    # -y: Overwrite output if exists
    command = [
        "ffmpeg",
        "-y",
        "-hide_banner", "-loglevel", "error", # Keep it quiet in the terminal
        "-i", processed_temp_path,
        "-i", source_path,
        "-map", "0",
        "-map_metadata", "1",
        "-c", "copy",
        final_output_path
    ]

    try:
        subprocess.run(command, check=True)
    except subprocess.CalledProcessError as e:
        print(f"Error copying metadata for {final_output_path}: {e}")

def process_audio():
    if not os.path.exists(OUTPUT_FOLDER):
        os.makedirs(OUTPUT_FOLDER)

    # Create a temp folder for intermediate files (files before metadata copy)
    temp_folder = os.path.join(OUTPUT_FOLDER, "temp_processing")
    if not os.path.exists(temp_folder):
        os.makedirs(temp_folder)

    files = [f for f in os.listdir(SOURCE_FOLDER) if f.lower().endswith('.wav')]
    print(f"Found {len(files)} files to process...")

    for filename in files:
        source_path = os.path.join(SOURCE_FOLDER, filename)
        temp_path = os.path.join(temp_folder, filename)
        final_output_path = os.path.join(OUTPUT_FOLDER, filename)

        try:
            # 1. Load Main Audio
            audio = AudioSegment.from_wav(source_path)

            # Convert to stereo to match noise (prevents channel mapping issues)
            if audio.channels == 1:
                audio = audio.set_channels(2)

            # 2. Trim or Pad to 8 Seconds
            if len(audio) > TARGET_DURATION:
                audio = audio[:TARGET_DURATION]
            else:
                silence_needed = TARGET_DURATION - len(audio)
                audio = audio + AudioSegment.silent(duration=silence_needed)

            # 3. Normalize Main Audio (Make it a standard volume)
            audio = normalize_audio(audio, NORMALIZED_DB)

            # 4. Load and Prepare Noise
            noise_path = get_random_noise(NOISE_FOLDER)
            noise = AudioSegment.from_wav(noise_path)

            # Ensure noise is stereo
            if noise.channels == 1:
                noise = noise.set_channels(2)

            # Loop noise if short
            while len(noise) < TARGET_DURATION:
                noise += noise
            noise = noise[:TARGET_DURATION]

            # 5. Normalize Noise and Apply Relative Volume
            # First, make noise exactly as loud as the music
            noise = normalize_audio(noise, NORMALIZED_DB)
            # Then apply the adjustment (e.g., make it -3dB quieter than the music)
            noise = noise + NOISE_RELATIVE_DB

            # 6. Overlay
            mixed = audio.overlay(noise, position=0)

            # 7. Export to TEMP file (stripped metadata)
            mixed.export(temp_path, format="wav")

            # 8. Use FFmpeg to merge metadata from Source + Audio from Temp -> Final
            copy_metadata_ffmpeg(source_path, temp_path, final_output_path)

            print(f"Processed: {filename}")

        except Exception as e:
            print(f"Error processing {filename}: {e}")

    # Cleanup temp folder
    try:
        import shutil
        shutil.rmtree(temp_folder)
    except:
        pass

if __name__ == "__main__":
    process_audio()
