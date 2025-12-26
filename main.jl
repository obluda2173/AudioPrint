include("src/fingerprint.jl")
include("src/dsp.jl")
include("src/database.jl")

using SQLite

using .Fingerprint
using .Dsp
using .Database

# const SONG_PATH = "./samples/night_owl.wav"
# const SONG_PATH = "./samples/hallon.wav"
# const SONG_PATH = "./samples/outside_to_play.wav"
const SONG_PATH = "./data/fma_small_local/013/013191.wav"

function get_song(db::SQLite.DB, song_id::Int)
    stmt = SQLite.Stmt(db, "SELECT * FROM Songs WHERE song_id = ?")

    results = DBInterface.execute(stmt, [song_id])

    for row in results
        println("Found: '$(row.title)' by $(row.artist) (Album: $(row.album))")
        return row
    end

    println("No song found with ID: $song_id")
    return nothing
end

function main()
    db = SQLite.DB("./db/songs.db")

    spec_matrix = compute_spectrogram_obj(SONG_PATH)
    peaks = find_peaks_adaptive(spec_matrix)
    results = hash_peaks(peaks)

    song_ids = query_fingerprints(db, results)

    # println(song_id)

    get_song(db, song_ids[1])
    # get_song(db, song_ids[2])
end

main()
