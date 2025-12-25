using SQLite
using DataFrames

db = SQLite.DB("../db/songs.db")

# SQLite.execute(db, """
# DROP TABLE IF EXISTS Songs;
# DROP TABLE IF EXISTS Fingerprints;
# """)

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
