module Dsp

export mp3_to_wav, spectrogram_cstm

using DSP
using FFMPEG
using Plots
using SampledSignals
using WAV

function mp3_to_wav(input_path)
    output_path = replace(input_path, ".mp3" => ".wav")
    FFMPEG.ffmpeg_exe(`-y -i $input_path -loglevel error $output_path`)
    println("Saved as: $output_path")
end

function spectrogram_cstm(file_path)
    raw_audio, fs = wavread(file_path)

    audio_buf = SampleBuf(raw_audio, fs)
    mono_signal = vec(mono(audio_buf).data)

    n_samples = length(mono_signal)
    window_duration = 0.04
    window_size = round(Int, window_duration * fs)
    overlap = window_size ÷ 2

    spec = spectrogram(mono_signal, window_size, overlap; fs=fs)

    println(typeof(spec))

    power_db = pow2db.(spec.power)

    return power_db

    # heatmap(
    #     spec.time,
    #     spec.freq,
    #     power_db,
    #     xguide = "Time [s]",
    #     yguide = "Frequency [Hz]",
    #     title = "Spectrogram Analysis",
    #     color = :viridis
    # )

    # savefig("../media/heatmap.png")
end

# spectrogram_plot("../data/fma_small_local/000/000002.wav")

end
