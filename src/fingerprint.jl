module Fingerprint

export find_peaks, hash_peaks

using Statistics

function find_peaks(spectrogram::Matrix{Float64},
                    amp_min::Float64 = -50.0,
                    neighbor_size::Int=10)

    rows, cols = size(spectrogram)
    peaks = Vector{Tuple{Int, Int}}()

    for c in (1 + neighbor_size):(cols - neighbor_size)
        for r in (1 + neighbor_size):(rows - neighbor_size)

            cur_val = spectrogram[r, c]

            if cur_val < amp_min
                continue
            end

            is_peak = true

            for c_off in -neighbor_size:neighbor_size
                for r_off in -neighbor_size:neighbor_size

                    if c_off == 0 && r_off == 0
                        continue
                    end

                    # FIX 2: Correct variable name (cur_val) and indexing
                    if spectrogram[r + r_off, c + c_off] >= cur_val
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

function hash_peaks(peaks::Vector{Tuple{Int, Int}},   # basically peaks
                    fan_out::Int = 10,                # max points to pair per anchor
                    delta_t_min::Int = 0,             # min distance between points
                    delta_t_max::Int = 200)           # max distance (target zone size))

    sorted_peaks = sort(peaks, by = x -> x[1])

    n_peaks = length(sorted_peaks)
    hashes = Vector{NamedTuple{(:hash, :time_offset), Tuple{UInt32, Int}}}()

    sizehint!(hashes, n_peaks * fan_out)

    for i in 1:n_peaks
        anchor = sorted_peaks[i]
        t1, f1 = anchor

        start_idx = i + 1
        end_idx = min(i + fan_out, n_peaks)

        for j in start_idx:end_idx
            target = sorted_peaks[j]
            t2, f2 = target

            delta_t = abs(t2 - t1)

            if delta_t < delta_t_min || delta_t > delta_t_max
                continue
            end

            # [f1 (9 bits)] | [f2 (9 bits)] | [delta_t (14 bits)]
            f1_bits = UInt32(f1 & 0x1FF)       # 9 bits (0-511)
            f2_bits = UInt32(f2 & 0x1FF)       # 9 bits (0-511)
            dt_bits = UInt32(delta_t & 0x3FFF) # 14 bits (0-16383)

            hash_val = (f1_bits << 23) | (f2_bits << 14) | dt_bits

            push!(hashes, (hash = hash_val, time_offset = t1))
        end
    end

    return hashes
end

end
