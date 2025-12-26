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
# instructions: have a look on how the above tables Songs and Fingerptints are created
#               check the difference between SQLite's execute() and Stmt() method functions
#               use most appropriate function to insert the given signature arguments to a database
#               do some little research on how to create appopriate song_id
function add_song(db::SQLite.DB,
                  title::String,
                  artist::String,
                  album::String)


end

# bulk insert hashes
# accepts a Vector of Tuples: [(hash1, offset1), (hash2, offset2), ...]
# instructions: get some inspiration from previous instructions
function add_fingerprints(db::SQLite.DB,
                          song_id::Int,
                          hashes::Vector{Tuple{Int, Int}})

end

# searches for matches
# returns a DataFrame
# instructions: good luck
function query_fingerprints(db::SQLite.DB,
                            query_hashes::Vector{Int})

end

end
