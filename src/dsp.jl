module Dsp

using DSP
using FFMPEG
using WAV
using Statistics: mean

export mp3_to_wav, compute_log_spectrogram

"""
Converts an MP3 file to WAV format using FFMPEG.
Returns the path to the new WAV file.
"""
function mp3_to_wav(input_path::String)
    output_path = replace(input_path, r"\.mp3$"i => ".wav")
    run(`$(FFMPEG.ffmpeg) -y -i $input_path -loglevel error $output_path`)

    return output_path
end

"""
Loads a WAV file, converts to mono, computes the spectrogram,
and returns the Power Spectral Density in Decibels (dB).
"""
function compute_log_spectrogram(file_path::String; window_duration::Float64=0.04)
    # 1. Load Audio (raw_audio is a Matrix: samples x channels)
    raw_audio, fs = wavread(file_path)

    # 2. Convert to Mono (Efficiently)
    # If stereo (2 columns), average them. If already mono, just flatten to vector.
    signal = size(raw_audio, 2) > 1 ? vec(mean(raw_audio, dims=2)) : vec(raw_audio)

    # 3. Configure Windows (Time -> Samples)
    n_window = round(Int, window_duration * fs)
    n_overlap = n_window ÷ 2

    # 4. Compute Spectrogram (DSP.jl)
    spec = spectrogram(signal, n_window, n_overlap; fs=fs)

    # 5. Convert Power to dB (Log Scale) and return
    return pow2db.(spec.power)
end

end
