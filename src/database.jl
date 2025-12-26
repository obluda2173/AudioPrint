module Database

export init_db, add_songs, add_fingerprint, query_fingerprints

using SQLite

function init_db(db_path)
    db = SQLite.DB(db_path)

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

# inserts metadata
# returns song_id
function add_song(db::SQLite.DB,
                  title::String,
                  artist::String,
                  album::String)


end

# bulk insert hashes
# accepts a Vector of Tuples: [(hash1, offset1), (hash2, offset2), ...]
function add_fingerprints(db::SQLite.DB,
                          song_id::Int,
                          hashes::Vector{Tuple{Int, Int}})

end

# searches for matches
# returns a DataFrame
function query_fingerprints(db::SQLite.DB,
                            query_hashes::Vector{Int})

end

end
