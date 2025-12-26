include("../src/dsp.jl")
include("../src/database.jl")
include("../src/fingerprint.jl")

using FFMPEG
using JSON

using .Dsp
using .Database
using .Fingerprint

const DB_PATH = "../db/songs.db"
const MUSIC_FOLDER = "../data/fma_small_local/000/"

function get_wav_tags(file_path::String)
    cmd = `$(FFMPEG.ffprobe()) -v quiet -print_format json -show_format "$file_path"`

    out = IOBuffer()
    try
        run(pipeline(cmd, stdout=out))
    catch
        return nothing
    end

    seekstart(out)
    data = JSON.parse(out)

    if haskey(data, "format") && haskey(data["format"], "tags")
        return data["format"]["tags"]
    end
    return Dict()
end

function main()
    file_list = readdir(MUSIC_FOLDER)

    db = init_db(DB_PATH)

    for file in file_list
        if !endswith(file, ".wav")
            continue
        end

        file_path = joinpath(MUSIC_FOLDER, file)

        # 1. ingest metadata
        tags = get_wav_tags(file_path)
        song_id = add_song(db,
                  get(tags, "title", "unknown"),
                  get(tags, "artist", "unknown"),
                  get(tags, "album", "unknown"))

        # 2. ingest fingerprint
        spec_matrix = compute_spectrogram_obj(file_path)
        peaks = find_peaks_adaptive(spec_matrix)
        hashes = hash_peaks(peaks)
        add_fingerprint(db,
                        song_id,
                        hashes)
    end
end

main()
