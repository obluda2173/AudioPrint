module Database

export init_db, add_song, add_fingerprint, query_fingerprints

using DataFrames
using SQLite
using DBInterface # Good practice to explicitly use this for the interface functions

function init_db(db_path)
    db = SQLite.DB(db_path)

    # Table creation looks good
    SQLite.execute(db, """
    CREATE TABLE IF NOT EXISTS Songs (
        song_id INTEGER PRIMARY KEY,
        title TEXT NOT NULL,
        artist TEXT NOT NULL,
        album TEXT NOT NULL
    );
    """)

    SQLite.execute(db, """
    CREATE TABLE IF NOT EXISTS Fingerprints (
        hash INTEGER NOT NULL,
        song_id INTEGER NOT NULL,
        offset INTEGER NOT NULL,
        FOREIGN KEY(song_id) REFERENCES Songs(song_id)
    )
    """)

    SQLite.execute(db, "CREATE INDEX IF NOT EXISTS idx_hash ON Fingerprints (hash)")

    return db
end

function add_song(db::SQLite.DB,
                  title::String,
                  artist::String,
                  album::String)

    stmt = SQLite.Stmt(db, """
    INSERT INTO Songs (title, artist, album)
    VALUES (?, ?, ?);
    """)

    DBInterface.execute(stmt, [title, artist, album])

    id = SQLite.last_insert_rowid(db)
    return id
end

function add_fingerprint(db::SQLite.DB,
                         song_id::Int,
                         hashes::Vector{NamedTuple{(:hash, :time_offset), Tuple{UInt32, Int}}})

    stmt = SQLite.Stmt(db, """
    INSERT INTO Fingerprints (song_id, hash, offset)
    VALUES (?, ?, ?);
    """)

    DBInterface.transaction(db) do
        for (hash_val, offset_val) in hashes
            params = [song_id, hash_val, offset_val]
            DBInterface.execute(stmt, params)
        end
    end
end

function query_fingerprints(db::SQLite.DB, query_hashes::Vector{NamedTuple{(:hash, :time_offset), Tuple{UInt32, Int}}})
    query_map = Dict{UInt32, Vector{Int}}()
    for (h, t) in query_hashes
        if !haskey(query_map, h)
            query_map[h] = Int[]
        end
        push!(query_map[h], t)
    end

    unique_hashes = collect(keys(query_map))

    if isempty(unique_hashes)
        return nothing
    end

    hash_list_str = join(unique_hashes, ",")

    query_sql = "SELECT song_id, hash, offset FROM Fingerprints WHERE hash IN ($hash_list_str)"
    results = DBInterface.execute(db, query_sql)

    matches = Dict{Tuple{Int, Int}, Int}()

    for row in results
        db_hash = row[:hash]
        db_offset = row[:offset]
        song_id = row[:song_id]

        for query_offset in query_map[db_hash]
            diff = db_offset - query_offset
            key = (song_id, diff)
            matches[key] = get(matches, key, 0) + 1
        end
    end

    song_scores = Dict{Int, Int}()

    for ((sid, diff), count) in matches
        current_max = get(song_scores, sid, 0)
        if count > current_max
            song_scores[sid] = count
        end
    end

    ranked_results = sort(collect(song_scores), by=x->x[2], rev=true)

    if isempty(ranked_results)
        return nothing
    end

    return ranked_results[1][1]
end

end
