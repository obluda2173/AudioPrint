using FFMPEG, WAV

function convert_to_wav(input_path)
    output_path = replace(input_path, ".mp3" => ".wav")
    FFMPEG.ffmpeg_exe(`-y -i $input_path -loglevel error $output_path`)
    println("Saved as: $output_path")
end

convert_to_wav("./data/fma_small_local/031/031807.mp3")
