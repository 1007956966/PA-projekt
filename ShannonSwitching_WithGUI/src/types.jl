"A vertex of the game graph."
struct Vertex
    id::Int
end

"An undirected edge with mutable game state."
mutable struct Edge
    id::Int
    u::Vertex
    v::Vertex
    weight::Float64
    state::Symbol  # :neutral, :short, :cut
end

"The fixed game graph with source s and target t."
struct GameGraph
    vertices::Vector{Vertex}
    edges::Vector{Edge}
    s::Vertex
    t::Vertex
end

"Current state of a Shannon-Switching game."
mutable struct GameState
    graph::GameGraph
    current_player::Symbol      # :short or :cut
    history::Vector{Tuple{Symbol, Edge}}
    winner::Union{Symbol, Nothing}
end

Base.:(==)(a::Vertex, b::Vertex) = a.id == b.id
Base.hash(v::Vertex, h::UInt) = hash(v.id, h)
Base.:(==)(a::Edge, b::Edge) = a.id == b.id
Base.hash(e::Edge, h::UInt) = hash(e.id, h)

"Return the other endpoint of edge e when one endpoint is v."
function other(e::Edge, v::Vertex)::Vertex
    e.u == v && return e.v
    e.v == v && return e.u
    error("Vertex $(v.id) is not incident to edge $(e.id)")
end
