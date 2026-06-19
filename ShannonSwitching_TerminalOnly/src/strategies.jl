const TEAM_NAME::String = "CHANGE_ME_BASELINE"

"Deterministic legal move fallback."
function random_strategy(state::GameState)::Edge
    moves = valid_moves(state)
    @assert !isempty(moves) "No valid moves available"
    return first(moves)
end

function _first_neutral_on_path(path::Vector{Edge})::Union{Edge, Nothing}
    for e in path
        e.state == :neutral && return e
    end
    return nothing
end

"Baseline heuristic for weighted Short."
function weighted_short(state::GameState)::Edge
    moves = valid_moves(state)
    isempty(moves) && error("No valid moves available")
    path = shortest_st_path(state.graph, [:neutral, :short])
    candidates = [e for e in path if e.state == :neutral]
    isempty(candidates) && return random_strategy(state)
    return first(sort(candidates, by = e -> e.weight))
end

"Baseline heuristic for weighted Cut."
function weighted_cut(state::GameState)::Edge
    moves = valid_moves(state)
    isempty(moves) && error("No valid moves available")
    path = shortest_st_path(state.graph, [:neutral, :short])
    candidates = [e for e in path if e.state == :neutral]
    isempty(candidates) && return random_strategy(state)

    best = first(candidates)
    best_score = -Inf
    for e in candidates
        old = e.state
        e.state = :cut
        new_path = shortest_st_path(state.graph, [:neutral, :short])
        score = isempty(new_path) ? Inf : path_weight(new_path)
        e.state = old
        if score > best_score
            best_score = score
            best = e
        end
    end
    return best
end

"Fallback unweighted Short strategy."
function short_strategy(state::GameState)::Edge
    path = find_st_path(state.graph, [:neutral, :short])
    e = _first_neutral_on_path(path)
    return isnothing(e) ? random_strategy(state) : e
end

"Fallback unweighted Cut strategy."
function cut_strategy(state::GameState)::Edge
    path = find_st_path(state.graph, [:neutral, :short])
    candidates = [e for e in path if e.state == :neutral]
    return isempty(candidates) ? random_strategy(state) : first(candidates)
end
