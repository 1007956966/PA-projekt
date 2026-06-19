"""
    other_endpoint(e, v)

Return the other endpoint of edge `e` with respect to vertex `v`.
"""
function other_endpoint(e::Edge, v::Vertex)::Vertex
    if e.u == v
        return e.v
    elseif e.v == v
        return e.u
    else
        error("Vertex $(v.id) is not incident to edge $(e.id)")
    end
end

"""
    incident_edges(g, v, allowed_states)

Return all edges incident to `v` whose state belongs to `allowed_states`.
"""
function incident_edges(g::GameGraph, v::Vertex, allowed_states)::Vector{Edge}
    states = Set(Symbol.(allowed_states))
    return [e for e in g.edges if e.state in states && (e.u == v || e.v == v)]
end

"""
    find_st_path(g, allowed_states)::Vector{Edge}

Find one path from `g.s` to `g.t` using only edges whose state belongs to
`allowed_states`. Returns an empty vector if no such path exists.
"""
function find_st_path(g::GameGraph, allowed_states)::Vector{Edge}
    g.s == g.t && return Edge[]

    visited = Set{Int}([g.s.id])
    queue = Vertex[g.s]
    parent_edge = Dict{Int, Edge}()
    parent_vertex = Dict{Int, Int}()

    while !isempty(queue)
        v = popfirst!(queue)
        if v == g.t
            break
        end
        for e in incident_edges(g, v, allowed_states)
            w = other_endpoint(e, v)
            if !(w.id in visited)
                push!(visited, w.id)
                parent_edge[w.id] = e
                parent_vertex[w.id] = v.id
                push!(queue, w)
            end
        end
    end

    if !(g.t.id in visited)
        return Edge[]
    end

    path = Edge[]
    cur = g.t.id
    while cur != g.s.id
        e = parent_edge[cur]
        pushfirst!(path, e)
        cur = parent_vertex[cur]
    end
    return path
end

"""
    has_st_path(g, allowed_states)::Bool

Return true iff there is an `s`-`t` path using only edges whose state belongs
to `allowed_states`.
"""
has_st_path(g::GameGraph, allowed_states)::Bool = !isempty(find_st_path(g, allowed_states)) || g.s == g.t

"""
    shortest_st_path(g, allowed_states)::Vector{Edge}

Compute a minimum-weight `s`-`t` path using only edges whose state belongs to
`allowed_states`. The implementation is a simple Dijkstra variant without an
external priority queue. It is sufficient for small and medium project graphs.
"""
function shortest_st_path(g::GameGraph, allowed_states)::Vector{Edge}
    states = Set(Symbol.(allowed_states))
    ids = [v.id for v in g.vertices]
    vertices_by_id = Dict(v.id => v for v in g.vertices)
    dist = Dict(id => Inf for id in ids)
    used = Set{Int}()
    prev_edge = Dict{Int, Edge}()
    prev_vertex = Dict{Int, Int}()

    dist[g.s.id] = 0.0

    while length(used) < length(ids)
        candidates = [id for id in ids if !(id in used)]
        isempty(candidates) && break
        u_id = candidates[argmin([dist[id] for id in candidates])]
        isinf(dist[u_id]) && break
        push!(used, u_id)
        u = vertices_by_id[u_id]
        u == g.t && break

        for e in incident_edges(g, u, states)
            v = other_endpoint(e, u)
            v.id in used && continue
            # In unweighted graphs all weights are 0.0; use a tiny positive
            # value so Dijkstra still behaves sensibly.
            cost = e.weight > 0 ? e.weight : 1.0
            nd = dist[u_id] + cost
            if nd < dist[v.id]
                dist[v.id] = nd
                prev_edge[v.id] = e
                prev_vertex[v.id] = u_id
            end
        end
    end

    if g.s != g.t && !haskey(prev_edge, g.t.id)
        return Edge[]
    end

    path = Edge[]
    cur = g.t.id
    while cur != g.s.id
        e = prev_edge[cur]
        pushfirst!(path, e)
        cur = prev_vertex[cur]
    end
    return path
end

"""
    path_weight(path)::Float64

Return the sum of edge weights along a path.
"""
path_weight(path::Vector{Edge})::Float64 = sum(e.weight for e in path)
