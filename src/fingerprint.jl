module Fingerprint

export find_peaks_adaptive, hash_peaks

using DSP
using Statistics

function find_peaks_adaptive(spec_obj;
                             dynamic_range_db::Float64 = 40.0,
                             min_dist_freq::Float64 = 150.0, # e.g., 150 Hz gap
                             min_dist_time::Float64 = 0.5)   # e.g., 0.5 Seconds gap

    power_db = pow2db.(spec_obj.power)

    max_volume = maximum(power_db)
    amp_min = max_volume - dynamic_range_db

    hz_step = spec_obj.freq[2] - spec_obj.freq[1]

    time_step = spec_obj.time[2] - spec_obj.time[1]

    r_neighbor = max(1, round(Int, min_dist_freq / hz_step))
    c_neighbor = max(1, round(Int, min_dist_time / time_step))

    rows, cols = size(power_db)
    peaks = Vector{Tuple{Int, Int}}()

    for c in (1 + c_neighbor):(cols - c_neighbor)
        for r in (1 + r_neighbor):(rows - r_neighbor)

            cur_val = power_db[r, c]

            if cur_val < amp_min
                continue
            end

            is_peak = true

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
                push!(peaks, (c, r))
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
