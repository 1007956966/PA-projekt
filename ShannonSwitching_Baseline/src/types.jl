import Base: ==, hash, show

"""
    Vertex(id::Int)

A vertex of the game graph. The field `id` is the unique vertex identifier.
"""
struct Vertex
    id::Int
end

==(a::Vertex, b::Vertex) = a.id == b.id
hash(v::Vertex, h::UInt) = hash(v.id, h)
show(io::IO, v::Vertex) = print(io, "v", v.id)

"""
    Edge(id, u, v, weight, state)

An undirected edge between vertices `u` and `v`.

The field `state` is one of `:neutral`, `:short`, or `:cut`.
For the unweighted game use `weight = 0.0`.
"""
mutable struct Edge
    id::Int
    u::Vertex
    v::Vertex
    weight::Float64
    state::Symbol
end

Edge(id::Int, u::Vertex, v::Vertex; weight::Real=0.0, state::Symbol=:neutral) =
    Edge(id, u, v, Float64(weight), state)

==(a::Edge, b::Edge) = a.id == b.id
hash(e::Edge, h::UInt) = hash(e.id, h)
show(io::IO, e::Edge) = print(io, "e", e.id, "(", e.u.id, "--", e.v.id, ", ", e.state, ", w=", e.weight, ")")

"""
    GameGraph(vertices, edges, s, t)

The graph used for the Shannon-Switching game.
`s` is the source and `t` is the target.
"""
struct GameGraph
    vertices::Vector{Vertex}
    edges::Vector{Edge}
    s::Vertex
    t::Vertex
end

"""
    GameState(graph, current_player, history, winner)

Mutable state of a running Shannon-Switching game.

`current_player` is `:short` or `:cut`.
`history` stores pairs `(player, edge)`.
`winner` is `:short`, `:cut`, or `nothing`.
"""
mutable struct GameState
    graph::GameGraph
    current_player::Symbol
    history::Vector{Tuple{Symbol, Edge}}
    winner::Union{Symbol, Nothing}
end
