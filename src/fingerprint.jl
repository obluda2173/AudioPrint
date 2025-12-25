module Fingerprint

export find_peaks_adaptive, hash_peaks

using DSP
using Statistics

"""
Identifies peaks using adaptive, human-readable constraints.
- `dynamic_range_db`: How far down from the loudness peak to look (e.g. 30dB).
- `min_dist_freq`: Minimum distance between peaks in Hz.
- `min_dist_time`: Minimum distance between peaks in Seconds.
"""
function find_peaks_adaptive(spec_obj;
                             dynamic_range_db::Float64 = 40.0,
                             min_dist_freq::Float64 = 150.0, # e.g., 150 Hz gap
                             min_dist_time::Float64 = 0.5)   # e.g., 0.5 Seconds gap

    # 1. Convert Power to dB
    # We do this here so we can find the relative Max
    power_db = pow2db.(spec_obj.power)

    # 2. Calculate Adaptive Amplitude Threshold
    # Instead of hardcoded -50, we look X dB below the song's loudest point.
    # This works for both whisper-quiet recordings and loud rock songs.
    max_volume = maximum(power_db)
    amp_min = max_volume - dynamic_range_db

    # 3. Calculate Adaptive Neighborhood (Physical Units -> Matrix Bins)
    # We figure out how "wide" one pixel is in Hz and Seconds.

    # Hz per bin = (Total Freq Range) / (Total Freq Bins)
    # Check the difference between the first two frequency steps
    hz_step = spec_obj.freq[2] - spec_obj.freq[1]

    # Seconds per bin
    time_step = spec_obj.time[2] - spec_obj.time[1]

    # Convert user's physical constraints into matrix integers
    # e.g. "I want 150Hz gap" / "43Hz per bin" = 3 bins
    r_neighbor = max(1, round(Int, min_dist_freq / hz_step))
    c_neighbor = max(1, round(Int, min_dist_time / time_step))

    println("Adaptive Config: Threshold: $(amp_min)dB | Neighbors: $(r_neighbor)x$(c_neighbor) bins")

    # 4. Standard Peak Finding Loop (using calculated integers)
    rows, cols = size(power_db)
    peaks = Vector{Tuple{Int, Int}}()

    # Loop with safety margins for the window
    for c in (1 + c_neighbor):(cols - c_neighbor)
        for r in (1 + r_neighbor):(rows - r_neighbor)

            cur_val = power_db[r, c]

            if cur_val < amp_min
                continue
            end

            is_peak = true

            # Check neighbors
            for c_off in -c_neighbor:c_neighbor
                for r_off in -r_neighbor:r_neighbor
                    if c_off == 0 && r_off == 0 continue end

                    if power_db[r + r_off, c + c_off] >= cur_val
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
