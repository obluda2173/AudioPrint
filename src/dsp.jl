module Dsp

export mp3_to_wav, compute_spectrogram_obj

using DSP
using FFMPEG
using Statistics: mean
using WAV

function mp3_to_wav(input_path::String)
    output_path = replace(input_path, r"\.mp3$"i => ".wav")
    run(`$(FFMPEG.ffmpeg) -y -i $input_path -loglevel error $output_path`)

    return output_path
end

function compute_spectrogram_obj(file_path::String; window_duration::Float64=0.04)
    raw_audio, fs = wavread(file_path)
    signal = size(raw_audio, 2) > 1 ? vec(mean(raw_audio, dims=2)) : vec(raw_audio)

    n_window = round(Int, window_duration * fs)
    n_overlap = n_window ÷ 2

    return spectrogram(signal, n_window, n_overlap; fs=fs)
end

end
