include("../src/dsp.jl")
include("../src/database.jl")
include("../src/fingerprint.jl")
include("./listen.jl")

using SQLite
using FFMPEG
using JSON

using .Dsp
using .Database
using .Fingerprint
using .Listen

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
    db = SQLite.DB("../db/songs.db")
    folder_path = "../data/processed_8s_noise/"

    if !isdir(folder_path)
        println("Directory not found: $folder_path")
        return
    end

    files = readdir(folder_path)
    test_files = [joinpath(folder_path, f) for f in files if endswith(f, ".wav")]

    total_files = length(test_files)
    correct_matches = 0

    println("Running batch validation on $total_files files...")
    println("-" ^ 40)

    for file_path in test_files
        filename = basename(file_path)

        truth_tags = get_wav_tags(file_path)
        truth_title = get(truth_tags, "title", "Unknown Title")

        spec = compute_spectrogram_obj(file_path)
        peaks = find_peaks_adaptive(spec)
        hashes = hash_peaks(peaks)
        found_id = Listen.identify_song(db, hashes)

        match_success = false
        if !isnothing(found_id)
            found_info = Database.get_song(db, found_id)
            # Case-insensitive comparison
            if lowercase(strip(found_info.title)) == lowercase(strip(truth_title))
                match_success = true
            end
        end

        if match_success
            correct_matches += 1
            printstyled("✔ [PASS] $filename\n", color=:green)
        else
            printstyled("✘ [FAIL] $filename (Expected: $truth_title)\n", color=:red)
        end
    end

    println("-" ^ 40)
    percentage = round((correct_matches / total_files) * 100; digits=2)

    printstyled("Total: $total_files\n", bold=true)
    printstyled("Correct: $correct_matches\n", bold=true, color=:green)
    printstyled("Success Rate: $percentage%\n", bold=true, color=:cyan)
end

main()
