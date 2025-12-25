include("src/fingerprint.jl")
include("src/dsp.jl")

using .Fingerprint
using .Dsp

const SONG_PATH = "./data/fma_small_local/000/000002.wav"

function main()
    spec_matrix = compute_log_spectrogram(SONG_PATH)
    peaks = find_peaks(spec_matrix)
    results = hash_peaks(peaks)

    open("hash.txt", "w") do io
        for res in results
            write(io, "Hash: $(bitstring(res.hash)) | Anchor Time: $(res.time_offset)\n")
        end
    end
end

main()
