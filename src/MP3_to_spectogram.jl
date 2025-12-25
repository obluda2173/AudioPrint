using FFMPEG, DSP, WAV, Plots

function mp3_to_wav(input_path)
    output_path = replace(input_path, ".mp3" => ".wav")
    FFMPEG.ffmpeg_exe(`-y -i $input_path -loglevel error $output_path`)
    println("Saved as: $output_path")
end


# using WAV
# s, fs = wavread("/mnt/c/Dev/AudioPrint/data/fma_small_local/000/000002.wav")
# print(fs)
# plot(0:2/fs:(length(s)-1)/fs, s)
# xlabel("Time [s]")

using SampledSignals, WAV
audio_test_url = "https://upload.wikimedia.org/wikipedia/commons/4/48/Piano-phrase.wav"
 y, fs = wavread("../data/fma_small_local/000/000002.wav")
audio_test = SampleBuf(y,fs)
n = length(audio_test.data)
nw = n÷50
spec = spectrogram(vec(mono(audio_test).data), nw, nw÷10; fs=fs)
plt = heatmap(spec.time, spec.freq, pow2db.(spec.power), xguide="Time [s]", yguide="Frequency [Hz]")
savefig("../media/heatmap.png")
