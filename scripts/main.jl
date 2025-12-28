using DrWatson
@quickactivate "AudioFingerprint"

include(srcdir("dsp.jl"))
include(srcdir("database.jl"))
include(srcdir("fingerprint.jl"))
include(srcdir("listen.jl"))

using SQLite
using .Dsp
using .Database
using .Fingerprint
using .Listen

const DB_PATH = datadir("db", "songs.db")

function main()
    if length(ARGS) < 1
        printstyled("Error: No audio file provided.\n", color=:red, bold=true)
        println("Usage: julia scripts/identify.jl <path_to_audio_file>")
        return
    end

    target_file = ARGS[1]

    if !isfile(target_file)
        printstyled("Error: File not found: $target_file\n", color=:red)
        return
    end

    if !isfile(DB_PATH)
        printstyled("Error: Database not found at $DB_PATH\n", color=:red)
        println("Please run 'scripts/ingest_library.jl' first to build your database.")
        return
    end

    db = SQLite.DB(DB_PATH)

    printstyled("\n🎧 Processing $target_file...\n", color=:cyan)
    # ... (Keep your existing fingerprint/hash logic here) ...
    spec_matrix = compute_spectrogram_obj(target_file)
    peaks = find_peaks_adaptive(spec_matrix)
    hashes = hash_peaks(peaks)

    printstyled("🔍 Searching database...\n", color=:cyan)
    song_id = Listen.identify_song(db, hashes)

    println("-" ^ 40)

    if isnothing(song_id)
        printstyled("❌ No match found.\n", color=:red, bold=true)
    else
        song_info = Database.get_song(db, song_id)
        printstyled("✅ Match Found!\n", color=:green, bold=true)
        println("Title:  $(song_info.title)")
        println("Artist: $(song_info.artist)")
        println("Album:  $(song_info.album)")
    end
    println("-" ^ 40)
end

main()
