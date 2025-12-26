include("src/dsp.jl")
include("src/database.jl")
include("src/fingerprint.jl")
include("scripts/listen.jl")

using SQLite
using .Dsp
using .Database
using .Fingerprint
using .Listen

const SONG_PATH = "./audio_samples/night_owl.wav"
# const SONG_PATH = "./audio_samples/hallon.wav"
# const SONG_PATH = "./audio_samples/outside_to_play.wav"
# const SONG_PATH = "./data/fma_small_local/013/013191.wav"

function main()
    db = SQLite.DB("./db/songs.db")

    printstyled("\nProcessing audio...\n", color=:cyan)
    spec_matrix = compute_spectrogram_obj(SONG_PATH)
    peaks = find_peaks_adaptive(spec_matrix)
    hashes = hash_peaks(peaks)

    printstyled("Searching database...\n", color=:cyan)
    song_id = Listen.identify_song(db, hashes)

    println("-" ^ 40)

    if isnothing(song_id)
        # Failure: Red
        printstyled("❌ No match found.\n", color=:red, bold=true)
    else
        song_info = Database.get_song(db, song_id)

        printstyled("✅ Match Found!\n\n", color=:green, bold=true)

        printstyled("Title:  ", color=:yellow, bold=true)
        println(song_info.title)

        printstyled("Artist: ", color=:yellow, bold=true)
        println(song_info.artist)

        printstyled("Album:  ", color=:yellow, bold=true)
        println(song_info.album)
    end
    println("-" ^ 40)
end

main()
