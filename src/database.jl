module Database

export init_db, add_songs, add_fingerprint, query_fingerprints

using SQLite
using DataFrames

function init_db(db_path)
    db = SQLite.DB(db_path)

    SQLite.execute(db, """
    CREATE TABLE IF NOT EXISTS Songs (
           song_id INTEGER PRIMARY KEY,
           title TEXT,
           artist TEXT
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
end

function add_songs()

end

function add_fingerprint()

end

function query_fingerprints()

end

end
