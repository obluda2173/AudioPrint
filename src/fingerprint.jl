module Fingerprint

using Statistics

"""
find_peaks(spectrogram::Matrix{Float64}; amp_min=10.0, neighbor_size=10)

Finds local maxima in a spectrogram.
- `spectrogram`: 2D array (Frequency x Time).
- `amp_min`: Minimum amplitude to be considered a peak (filters silence).
- `neighbor_size`: The radius of the neighborhood to check.
"""
function find_peaks(spectrogram::Matrix{Float64}, amp_min::Float64=10.0, neighbor_size::Int=10)
    rows, cols = size(spectrogram)
    peaks = Vector{Tuple{Int, Int}}()

    for c in (1 + neighbor_size):(cols - neighbor_size)
        for r in (1 + neighbor_size):(rows - neighbor_size)

            cur_val = spectrogram[r][c]

            if cur_val < amp_min
                continue
            end

            is_peak = true

            for c_off in -neighbor_size:neighbor_size
                for r_off in -neighbor_size:neighbor_size

                    if c_off == 0 && r_off == 0
                        continue
                    end

                    if spectrogram[r + r_off, c + c_off] >= current_val
                        is_peak = false
                        break
                    end
                end
                if !is_peak break end
            end

            if is_peak
                push!(peaks, (r, c))
            end
        end
    end

    return peaks
end

function hash_peaks(peaks::Vector{Tuple{Int, Int}})

end

end
