"Create a new game state. All edges are reset to neutral and Short starts."
function new_game(g::GameGraph)::GameState
    for e in g.edges
        e.state = :neutral
    end
    return GameState(g, :short, Tuple{Symbol, Edge}[], nothing)
end

"Return all neutral edges that the current player may choose."
valid_moves(state::GameState)::Vector{Edge} = [e for e in state.graph.edges if e.state == :neutral]

"Return :short, :cut, or nothing according to the current game state."
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

"Execute the current player's move on a neutral edge."
function make_move!(state::GameState, e::Edge)::Nothing
    @assert isnothing(state.winner) "Game is already over"
    @assert e.state == :neutral "Edge $(e.id) is not neutral"
    @assert state.current_player in (:short, :cut) "Unknown player"

    player = state.current_player
    e.state = player == :short ? :short : :cut
    push!(state.history, (player, e))
    state.winner = check_winner(state)
    if isnothing(state.winner)
        state.current_player = player == :short ? :cut : :short
    end
    return nothing
end

"A small example graph with vertices 1=s and 4=t."
function sample_graph(; weighted::Bool=false)::GameGraph
    v = [Vertex(i) for i in 1:4]
    weights = weighted ? [1.0, 1.0, 2.0, 2.0, 3.0] : zeros(5)
    edges = Edge[
        Edge(1, v[1], v[2], weights[1], :neutral),
        Edge(2, v[2], v[4], weights[2], :neutral),
        Edge(3, v[1], v[3], weights[3], :neutral),
        Edge(4, v[3], v[4], weights[4], :neutral),
        Edge(5, v[2], v[3], weights[5], :neutral),
    ]
    return GameGraph(v, edges, v[1], v[4])
end

"Deterministic connected graph generator used as a safe fallback."
function random_graph(n::Int, m::Int; weighted::Bool=false)::GameGraph
    @assert n >= 2 "n must be at least 2"
    maxm = n * (n - 1) ÷ 2
    @assert n - 1 <= m <= maxm "Need n-1 <= m <= n(n-1)/2"
    v = [Vertex(i) for i in 1:n]
    edges = Edge[]
    id = 1
    for i in 1:(n-1)
        push!(edges, Edge(id, v[i], v[i+1], weighted ? Float64(1 + (id % 10)) : 0.0, :neutral))
        id += 1
    end
    for i in 1:n, j in (i+2):n
        length(edges) >= m && break
        push!(edges, Edge(id, v[i], v[j], weighted ? Float64(1 + (id % 10)) : 0.0, :neutral))
        id += 1
    end
    return GameGraph(v, edges, v[1], v[n])
end
