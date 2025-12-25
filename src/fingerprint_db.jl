using SQLite
using DataFrames

db = SQLite.DB("../db/shazam_clone.db")

SQLite.execute(db, """
DROP TABLE IF EXISTS Songs;
""")

SQLite.execute(db, """
CREATE TABLE IF NOT EXISTS Songs(
       song_id INTEGER PRIMARY KEY,
       title TEXT,
       artist TEXT
);
""")

SQLite.tables(db)
