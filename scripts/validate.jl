using DrWatson
@quickactivate "AudioFingerprint"

include(srcdir("dsp.jl"))
include(srcdir("database.jl"))
include(srcdir("fingerprint.jl"))
include(srcdir("listen.jl"))

using SQLite
using Statistics
using FFMPEG
using JSON
using .Dsp
using .Database
using .Fingerprint
using .Listen

const DB_PATH = projectdir("data/db", "songs.db")
const SAMPLES_PATH = datadir("processed")

function get_wav_tags(file_path::String)
    cmd = `$(FFMPEG.ffprobe()) -v quiet -print_format json -show_format "$file_path"`

    out = IOBuffer()
    try
        run(pipeline(cmd, stdout=out))
    catch
        return Dict()
    end

    seekstart(out)
    data = JSON.parse(out)

    if haskey(data, "format") && haskey(data["format"], "tags")
        raw_tags = data["format"]["tags"]

        clean_tags = Dict{String, Any}()
        for (k, v) in raw_tags
            clean_tags[lowercase(k)] = v
        end
        return clean_tags
    end
    return Dict()
end

function main()
    # Ensure DB exists
    if !isfile(DB_PATH)
        println("Error: Database not found at $DB_PATH")
        return
    end

    db = SQLite.DB(DB_PATH)

    if !isdir(SAMPLES_PATH)
        println("Directory not found: $SAMPLES_PATH")
        return
    end

    files = readdir(SAMPLES_PATH)
    test_files = [joinpath(SAMPLES_PATH, f) for f in files if endswith(f, ".wav")]

    total_files = length(test_files)
    correct_matches = 0
    processing_times = Float64[]

    println("Running batch validation on $total_files files...")
    println("-" ^ 40)

    for file_path in test_files
        filename = basename(file_path)

        truth_tags = get_wav_tags(file_path)
        truth_title = get(truth_tags, "title", "Unknown Title")

        t_elapsed = @elapsed begin
            spec = compute_spectrogram_obj(file_path)
            peaks = find_peaks_adaptive(spec)
            hashes = hash_peaks(peaks)
            found_id = Listen.identify_song(db, hashes)
        end
        push!(processing_times, t_elapsed)
        # --- END TIMER ---

        match_success = false
        if !isnothing(found_id)
            found_info = Database.get_song(db, found_id)
            if lowercase(strip(found_info.title)) == lowercase(strip(truth_title))
                match_success = true
            end
        end

        if match_success
            correct_matches += 1
            printstyled("✔ [PASS] $filename ", color=:green)
        else
            printstyled("✘ [FAIL] $filename (Expected: $truth_title) ", color=:red)
        end
        printstyled("($(round(t_elapsed * 1000; digits=1))ms)\n", color=:light_black)
    end

    println("-" ^ 40)

    accuracy = round((correct_matches / total_files) * 100; digits=2)
    avg_time = round(mean(processing_times) * 1000; digits=2)

    printstyled("Total: $total_files\n", bold=true)
    printstyled("Correct: $correct_matches\n", bold=true, color=:green)
    printstyled("Success Rate: $accuracy%\n", bold=true, color=:cyan)
    printstyled("Avg Time: $(avg_time)ms\n", bold=true, color=:yellow)
end

main()
