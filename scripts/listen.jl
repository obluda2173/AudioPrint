module Listen

export identify_song

include("../src/database.jl")

using .Database

function identify_song(db, query_hashes::Vector{NamedTuple{(:hash, :time_offset), Tuple{UInt32, Int}}})
    query_map = Dict{UInt32, Vector{Int}}()
    for (h, t) in query_hashes
        if !haskey(query_map, h)
            query_map[h] = Int[]
        end
        push!(query_map[h], t)
    end

    unique_hashes = collect(keys(query_map))

    db_results = Database.fetch_hash_matches(db, unique_hashes)

    matches = Dict{Tuple{Int, Int}, Int}()

    for row in db_results
        db_hash = row[:hash]
        db_offset = row[:offset]
        song_id = row[:song_id]

        if haskey(query_map, db_hash)
            for query_offset in query_map[db_hash]
                diff = db_offset - query_offset
                key = (song_id, diff)
                matches[key] = get(matches, key, 0) + 1
            end
        end
    end

    song_scores = Dict{Int, Int}()
    for ((sid, diff), count) in matches
        current_max = get(song_scores, sid, 0)
        if count > current_max
            song_scores[sid] = count
        end
    end

    ranked = sort(collect(song_scores), by=x->x[2], rev=true)

    if isempty(ranked)
        return nothing
    end

    return ranked[1][1]
end

end
