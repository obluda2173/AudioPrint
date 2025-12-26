module Database

export init_db, add_song, add_fingerprint

using SQLite
using DBInterface # Good practice to explicitly use this for the interface functions

function init_db(db_path)
    db = SQLite.DB(db_path)


    SQLite.execute(db, """
    DROP TABLE IF EXISTS Songs;
    """)
    SQLite.execute(db, """
    DROP TABLE IF EXISTS Fingerprints;
    """)

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

# searches for matches
# returns a DataFrame
# instructions: good luck
# function query_fingerprints(db::SQLite.DB,
#                             query_hashes::Vector{Int})

# end

end
