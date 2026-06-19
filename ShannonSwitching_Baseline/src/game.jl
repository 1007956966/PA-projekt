using Random

"""
    new_game(g::GameGraph)::GameState

Create a fresh game state. All edges are reset to `:neutral`, Short starts,
and there is no winner yet.
"""
function new_game(g::GameGraph)::GameState
    for e in g.edges
        e.state = :neutral
    end
    return GameState(g, :short, Tuple{Symbol, Edge}[], nothing)
end

"""
    valid_moves(state::GameState)::Vector{Edge}

Return all neutral edges that the current player may choose.
"""
function valid_moves(state::GameState)::Vector{Edge}
    return [e for e in state.graph.edges if e.state == :neutral]
end

"""
    check_winner(state::GameState)::Union{Symbol, Nothing}

Return `:short` if Short's claimed edges contain an `s`-`t` path.
Return `:cut` if the remaining graph, consisting of neutral and Short edges,
contains no `s`-`t` path. Otherwise return `nothing`.
"""
function check_winner(state::GameState)::Union{Symbol, Nothing}
    g = state.graph
    if has_st_path(g, [:short])
        return :short
    elseif !has_st_path(g, [:neutral, :short])
        return :cut
    else
        return nothing
    end
end

function _edge_from_state(state::GameState, e::Edge)::Edge
    for edge in state.graph.edges
        edge.id == e.id && return edge
    end
    error("Edge $(e.id) does not belong to this game graph")
end

"""
    make_move!(state::GameState, e::Edge)::Nothing

Execute the move of the current player on the neutral edge `e`.
Short claims the edge, Cut removes it. The function updates the move history,
checks the winner, and switches the current player if the game is not over.
"""
function make_move!(state::GameState, e::Edge)::Nothing
    @assert isnothing(state.winner) "Spiel ist bereits beendet"
    edge = _edge_from_state(state, e)
    @assert edge.state == :neutral "Kante $(edge.id) ist nicht neutral"

    player = state.current_player
    if player == :short
        edge.state = :short
    elseif player == :cut
        edge.state = :cut
    else
        error("Unknown player: $player")
    end

    push!(state.history, (player, edge))
    state.winner = check_winner(state)

    if isnothing(state.winner)
        state.current_player = player == :short ? :cut : :short
    end
    return nothing
end

"""
    sample_graph(; weighted=false)::GameGraph

Return a small connected test graph with vertices 1=s, 2=a, 3=b, 4=t.
This graph is useful for GUI and manual tests.
"""
function sample_graph(; weighted::Bool=false)::GameGraph
    v = [Vertex(i) for i in 1:4]
    weights = weighted ? [1.0, 1.0, 3.0, 3.0, 2.0] : zeros(5)
    edges = Edge[
        Edge(1, v[1], v[2], weight=weights[1]),
        Edge(2, v[2], v[4], weight=weights[2]),
        Edge(3, v[1], v[3], weight=weights[3]),
        Edge(4, v[3], v[4], weight=weights[4]),
        Edge(5, v[2], v[3], weight=weights[5]),
    ]
    return GameGraph(v, edges, v[1], v[4])
end

"""
    random_graph(n, m; weighted=false)::GameGraph

Generate a random connected simple graph with `n` vertices and `m` edges.
Vertex 1 is the source and vertex `n` is the target. In weighted mode edge
weights are sampled uniformly from `[1, 10]`; otherwise they are `0.0`.
"""
function random_graph(n::Int, m::Int; weighted::Bool=false)::GameGraph
    @assert n >= 2 "Need at least two vertices"
    max_edges = div(n * (n - 1), 2)
    @assert n - 1 <= m <= max_edges "Need n-1 <= m <= n(n-1)/2"

    vertices = [Vertex(i) for i in 1:n]
    pairs = Set{Tuple{Int, Int}}()
    edges = Edge[]
    next_id = 1

    function add_edge!(i, j)
        a, b = minmax(i, j)
        (a, b) in pairs && return false
        push!(pairs, (a, b))
        w = weighted ? 1.0 + 9.0 * rand() : 0.0
        push!(edges, Edge(next_id, vertices[a], vertices[b], weight=w))
        next_id += 1
        return true
    end

    # First add a random-ish chain, ensuring connectedness.
    for i in 1:(n - 1)
        add_edge!(i, i + 1)
    end

    while length(edges) < m
        i, j = rand(1:n), rand(1:n)
        i == j && continue
        add_edge!(i, j)
    end

    return GameGraph(vertices, edges, vertices[1], vertices[n])
end
