include("src/fingerprint.jl")

using .Fingerprint

constellation_map = [
    (10, 50),
    (12, 60),
    (15, 55),
    (500, 120)
]

function main()
    results = hash_peaks(constellation_map)

    for res in results
        println("Hash: $(bitstring(res.hash)) | Anchor Time: $(res.time_offset)")
    end
end

main()
