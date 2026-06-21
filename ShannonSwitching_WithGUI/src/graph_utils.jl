"Return all edges whose state is in allowed_states."
function allowed_edges(g::GameGraph, allowed_states::Vector{Symbol})::Vector{Edge}
    return [e for e in g.edges if e.state in allowed_states]
end

"Return edges incident to vertex v and allowed by state."
function incident_edges(g::GameGraph, v::Vertex, allowed_states::Vector{Symbol})::Vector{Edge}
    return [e for e in g.edges if e.state in allowed_states && (e.u == v || e.v == v)]
end

"Breadth-first search for an s-t path using only allowed edge states."
function find_st_path(g::GameGraph, allowed_states::Vector{Symbol})::Vector{Edge}
    queue = Vertex[g.s]
    seen = Set{Int}([g.s.id])
    parent_edge = Dict{Int, Edge}()
    parent_vertex = Dict{Int, Vertex}()

    while !isempty(queue)
        v = popfirst!(queue)
        v == g.t && break
        for e in incident_edges(g, v, allowed_states)
            w = other(e, v)
            if !(w.id in seen)
                push!(seen, w.id)
                parent_edge[w.id] = e
                parent_vertex[w.id] = v
                push!(queue, w)
            end
        end
    end

    if !(g.t.id in seen)
        return Edge[]
    end

    path = Edge[]
    cur = g.t
    while cur != g.s
        e = parent_edge[cur.id]
        pushfirst!(path, e)
        cur = parent_vertex[cur.id]
    end
    return path
end

"Return true iff there is an s-t path using only allowed edge states."
has_st_path(g::GameGraph, allowed_states::Vector{Symbol})::Bool = !isempty(find_st_path(g, allowed_states)) || g.s == g.t

"Total weight of a path."
path_weight(path::Vector{Edge})::Float64 = sum(e.weight for e in path)

"A simple Dijkstra implementation for positive edge weights."
function shortest_st_path(g::GameGraph, allowed_states::Vector{Symbol})::Vector{Edge}
    dist = Dict(v.id => Inf for v in g.vertices)
    used = Set{Int}()
    parent_edge = Dict{Int, Edge}()
    parent_vertex = Dict{Int, Vertex}()
    dist[g.s.id] = 0.0

    while length(used) < length(g.vertices)
        best_id = nothing
        best_dist = Inf
        for v in g.vertices
            if !(v.id in used) && dist[v.id] < best_dist
                best_id = v.id
                best_dist = dist[v.id]
            end
        end
        best_id === nothing && break
        best_id == g.t.id && break
        push!(used, best_id)
        v = first(x for x in g.vertices if x.id == best_id)
        for e in incident_edges(g, v, allowed_states)
            w = other(e, v)
            w.id in used && continue
            nd = dist[v.id] + e.weight
            if nd < dist[w.id]
                dist[w.id] = nd
                parent_edge[w.id] = e
                parent_vertex[w.id] = v
            end
        end
    end

    if !haskey(parent_edge, g.t.id) && g.s != g.t
        return Edge[]
    end
    path = Edge[]
    cur = g.t
    while cur != g.s
        e = parent_edge[cur.id]
        pushfirst!(path, e)
        cur = parent_vertex[cur.id]
    end
    return path
end
