const TEAM_NAME::String = "CHANGE_ME_BASELINE"

"""
    random_strategy(state)::Edge

Return a uniformly random legal move.
"""
function random_strategy(state::GameState)::Edge
    moves = valid_moves(state)
    @assert !isempty(moves) "No valid moves available"
    return rand(moves)
end

function _first_neutral_on_path(path::Vector{Edge})::Union{Edge, Nothing}
    for e in path
        e.state == :neutral && return e
    end
    return nothing
end

"""
    weighted_short(state)::Edge

Baseline heuristic for weighted Short.
It computes a shortest `s`-`t` path in the graph consisting of neutral and
Short edges and claims a cheap neutral edge on that path.
"""
function weighted_short(state::GameState)::Edge
    moves = valid_moves(state)
    isempty(moves) && error("No valid moves available")

    path = shortest_st_path(state.graph, [:neutral, :short])
    neutral_edges = [e for e in path if e.state == :neutral]
    if isempty(neutral_edges)
        return random_strategy(state)
    end
    return neutral_edges[argmin([e.weight for e in neutral_edges])]
end

"""
    weighted_cut(state)::Edge

Baseline heuristic for weighted Cut.
It looks at the current shortest `s`-`t` path and removes the neutral edge whose
removal increases the shortest path length the most.
"""
function weighted_cut(state::GameState)::Edge
    moves = valid_moves(state)
    isempty(moves) && error("No valid moves available")

    path = shortest_st_path(state.graph, [:neutral, :short])
    candidates = [e for e in path if e.state == :neutral]
    isempty(candidates) && return random_strategy(state)

    best_edge = candidates[1]
    best_score = -Inf

    for e in candidates
        old_state = e.state
        e.state = :cut
        new_path = shortest_st_path(state.graph, [:neutral, :short])
        score = isempty(new_path) ? Inf : path_weight(new_path)
        e.state = old_state

        if score > best_score
            best_score = score
            best_edge = e
        end
    end
    return best_edge
end

"""
    short_strategy(state)::Edge

Fallback strategy for the unweighted game. This is not the full
Kishi-Kajitani optimal strategy, but it always returns a legal move when one
exists. Use it as a safe baseline and replace it later by the optimal version.
"""
function short_strategy(state::GameState)::Edge
    return weighted_short(state)
end

"""
    cut_strategy(state)::Edge

Fallback strategy for the unweighted game. This is not the full optimal Cut
strategy, but it always returns a legal move when one exists.
"""
function cut_strategy(state::GameState)::Edge
    return weighted_cut(state)
end
