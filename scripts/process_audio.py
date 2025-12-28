import os
import random
import subprocess
from pydub import AudioSegment, effects

NOISE_FOLDER = './background_noise'
OUTPUT_FOLDER = './processed_8s_noise'

TARGET_DURATION = 8000

NORMALIZED_DB = -20.0
NOISE_RELATIVE_DB = -3

def normalize_audio(segment, target_dBFS):
    change_in_dBFS = target_dBFS - segment.dBFS
    return segment.apply_gain(change_in_dBFS)

def get_random_noise(noise_folder):
    noise_files = [f for f in os.listdir(noise_folder) if f.lower().endswith('.wav')]
    if not noise_files:
        raise Exception("No .wav files found in noise folder!")
    return os.path.join(noise_folder, random.choice(noise_files))

def copy_metadata_ffmpeg(source_path, processed_temp_path, final_output_path):
    command = [
        "ffmpeg",
        "-y",
        "-hide_banner", "-loglevel", "error",
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
            audio = AudioSegment.from_wav(source_path)

            if audio.channels == 1:
                audio = audio.set_channels(2)

            if len(audio) > TARGET_DURATION:
                audio = audio[:TARGET_DURATION]
            else:
                silence_needed = TARGET_DURATION - len(audio)
                audio = audio + AudioSegment.silent(duration=silence_needed)

            audio = normalize_audio(audio, NORMALIZED_DB)

            noise_path = get_random_noise(NOISE_FOLDER)
            noise = AudioSegment.from_wav(noise_path)

            if noise.channels == 1:
                noise = noise.set_channels(2)

            while len(noise) < TARGET_DURATION:
                noise += noise
            noise = noise[:TARGET_DURATION]

            noise = normalize_audio(noise, NORMALIZED_DB)
            noise = noise + NOISE_RELATIVE_DB

            mixed = audio.overlay(noise, position=0)

            mixed.export(temp_path, format="wav")

            copy_metadata_ffmpeg(source_path, temp_path, final_output_path)

            print(f"Processed: {filename}")

        except Exception as e:
            print(f"Error processing {filename}: {e}")

    try:
        import shutil
        shutil.rmtree(temp_folder)
    except:
        pass

if __name__ == "__main__":
    process_audio()
