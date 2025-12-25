include("src/fingerprint.jl")
include("src/dsp.jl")

using .Fingerprint
using .Dsp

const SONG_PATH = "./data/fma_small_local/000/000002.wav"

function main()
    spec = spectrogram_cstm(SONG_PATH)
    println("Spectrogram created: ", length(spec))
    peaks = find_peaks(spec)
    println("Peaks found: ", length(peaks))
    results = hash_peaks(peaks)
    println("Hashes generated: ", length(results))

    open("hash.txt", "w") do io
        for res in results
            write(io, "Hash: $(bitstring(res.hash)) | Anchor Time: $(res.time_offset)\n")
        end
    end
end

main()
