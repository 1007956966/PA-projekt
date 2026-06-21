using Gtk4
using GtkObservables
using Cairo

const GUI_WIDTH = 720
const GUI_HEIGHT = 500
const CLICK_TOLERANCE = 20.0
const VERTEX_RADIUS = 25.0

function _positions(g::GameGraph)
    pos = Dict{Int, Tuple{Float64, Float64}}()

    # Optimized layout for the small 4-vertex demonstration graph.
    # This version does not assume that the vertex ids are exactly 1,2,3,4.
    if length(g.vertices) == 4
        middle_vertices = [v for v in g.vertices if v != g.s && v != g.t]

        pos[g.s.id] = (90.0, 250.0)
        pos[g.t.id] = (640.0, 250.0)

        pos[middle_vertices[1].id] = (330.0, 95.0)
        pos[middle_vertices[2].id] = (330.0, 405.0)

        return pos
    end

    # General layout for larger graphs:
    # place vertices from left to right according to their sorted ids.
    # This works well for our random_graph, because it creates a connected
    # base structure from 1 to n.
    sorted_vertices = sort(g.vertices, by = v -> v.id)
    n = length(sorted_vertices)

    left = 90.0
    right = GUI_WIDTH - 90.0
    center_y = GUI_HEIGHT / 2
    amplitude = GUI_HEIGHT * 0.30

    for (i, v) in enumerate(sorted_vertices)
        if v == g.s
            pos[v.id] = (left, center_y)
        elseif v == g.t
            pos[v.id] = (right, center_y)
        else
            x = left + (right - left) * (i - 1) / max(n - 1, 1)

            # Alternate vertices above and below the middle line.
            # This reduces overlaps compared with putting all vertices on one line.
            layer = i - 1
            y = center_y + amplitude * sin(2pi * layer / max(n - 1, 1))

            pos[v.id] = (x, y)
        end
    end

    return pos
end

function _status_string(state::GameState)::String
    if state.winner == :short
        return "Game over: Short wins"
    elseif state.winner == :cut
        return "Game over: Cut wins"
    elseif state.current_player == :short
        return "Current player: Short"
    else
        return "Current player: Cut"
    end
end

function _text_metrics(ctx, text::String)
    ext = text_extents(ctx, text)

    if hasproperty(ext, :width)
        return ext.width, ext.height, ext.x_bearing, ext.y_bearing
    else
        # Usually: [x_bearing, y_bearing, width, height, x_advance, y_advance]
        return ext[3], ext[4], ext[1], ext[2]
    end
end

function _draw_centered_text(ctx, text::String, x, y; size=18.0, bold=true)
    if bold
        select_font_face(ctx, "Sans", Cairo.FONT_SLANT_NORMAL, Cairo.FONT_WEIGHT_BOLD)
    else
        select_font_face(ctx, "Sans", Cairo.FONT_SLANT_NORMAL, Cairo.FONT_WEIGHT_NORMAL)
    end

    set_font_size(ctx, size)

    w, h, xb, yb = _text_metrics(ctx, text)
    move_to(ctx, x - w / 2 - xb, y - h / 2 - yb)
    show_text(ctx, text)
end

function _trimmed_segment(p1, p2; radius=VERTEX_RADIUS + 5.0)
    x1, y1 = p1
    x2, y2 = p2

    dx = x2 - x1
    dy = y2 - y1
    len = hypot(dx, dy)

    if len == 0.0
        return p1, p2
    end

    ux = dx / len
    uy = dy / len

    return (x1 + radius * ux, y1 + radius * uy),
           (x2 - radius * ux, y2 - radius * uy)
end

function _edge_label_offset(e::Edge)
    if e.id == 1
        return (0.0, -17.0)
    elseif e.id == 2
        return (0.0, -17.0)
    elseif e.id == 3
        return (0.0, 18.0)
    elseif e.id == 4
        return (0.0, 18.0)
    elseif e.id == 5
        return (-24.0, 0.0)
    else
        return (0.0, -15.0)
    end
end

function _draw_edge_label(ctx, label::String, x, y)
    radius = 12.5

    set_source_rgb(ctx, 1.0, 1.0, 1.0)
    arc(ctx, x, y, radius, 0.0, 2pi)
    fill_preserve(ctx)

    set_source_rgb(ctx, 0.25, 0.25, 0.25)
    set_line_width(ctx, 1.2)
    stroke(ctx)

    set_source_rgb(ctx, 0.05, 0.05, 0.05)
    _draw_centered_text(ctx, label, x, y; size=12.5, bold=true)
end

function _draw_cut_marker(ctx, x, y)
    set_source_rgb(ctx, 0.86, 0.05, 0.05)
    set_line_width(ctx, 5.0)

    d = 13.0
    move_to(ctx, x - d, y - d)
    line_to(ctx, x + d, y + d)
    stroke(ctx)

    move_to(ctx, x + d, y - d)
    line_to(ctx, x - d, y + d)
    stroke(ctx)
end

function _draw_edge(ctx, e::Edge, p1, p2)
    q1, q2 = _trimmed_segment(p1, p2)
    x1, y1 = q1
    x2, y2 = q2

    dx = x2 - x1
    dy = y2 - y1
    len = hypot(dx, dy)

    mx = (x1 + x2) / 2
    my = (y1 + y2) / 2

    # Base neutral edge
    set_dash(ctx, Float64[], 0.0)
    set_source_rgb(ctx, 0.70, 0.70, 0.70)
    set_line_width(ctx, 3.5)
    move_to(ctx, x1, y1)
    line_to(ctx, x2, y2)
    stroke(ctx)

    if e.state == :short
        # Blue highlight with clean stroke
        set_source_rgb(ctx, 0.05, 0.22, 0.95)
        set_line_width(ctx, 7.0)
        move_to(ctx, x1, y1)
        line_to(ctx, x2, y2)
        stroke(ctx)
    elseif e.state == :cut
        # Do not draw full red dashed line. Instead: grey edge + red X marker.
        _draw_cut_marker(ctx, mx, my)
    end

    ox, oy = _edge_label_offset(e)
    _draw_edge_label(ctx, string(e.id), mx + ox, my + oy)
end

function _draw_vertex(ctx, v::Vertex, p, g::GameGraph)
    x, y = p

    # shadow
    set_source_rgba(ctx, 0.0, 0.0, 0.0, 0.10)
    arc(ctx, x + 2.5, y + 2.5, VERTEX_RADIUS, 0.0, 2pi)
    fill(ctx)

    # fill
    set_source_rgb(ctx, 0.98, 0.98, 0.95)
    arc(ctx, x, y, VERTEX_RADIUS, 0.0, 2pi)
    fill_preserve(ctx)

    # border
    if v == g.s
        set_source_rgb(ctx, 0.0, 0.55, 0.0)
    elseif v == g.t
        set_source_rgb(ctx, 0.45, 0.0, 0.65)
    else
        set_source_rgb(ctx, 0.12, 0.12, 0.12)
    end

    set_line_width(ctx, 3.8)
    stroke(ctx)

    label = v == g.s ? "s" : (v == g.t ? "t" : string(v.id))
    set_source_rgb(ctx, 0.05, 0.05, 0.05)
    _draw_centered_text(ctx, label, x, y; size=18.0, bold=true)
end

function _draw_legend(ctx)
    x = 28.0
    y = 30.0

    set_source_rgb(ctx, 0.05, 0.05, 0.05)
    _draw_centered_text(ctx, "Legend", x + 52, y - 12; size=13.0, bold=true)

    y += 15

    set_source_rgb(ctx, 0.70, 0.70, 0.70)
    set_line_width(ctx, 3.5)
    move_to(ctx, x, y)
    line_to(ctx, x + 42, y)
    stroke(ctx)
    set_source_rgb(ctx, 0.05, 0.05, 0.05)
    move_to(ctx, x + 55, y + 4)
    show_text(ctx, "neutral")

    y += 28

    set_source_rgb(ctx, 0.05, 0.22, 0.95)
    set_line_width(ctx, 7.0)
    move_to(ctx, x, y)
    line_to(ctx, x + 42, y)
    stroke(ctx)
    set_source_rgb(ctx, 0.05, 0.05, 0.05)
    move_to(ctx, x + 55, y + 4)
    show_text(ctx, "Short")

    y += 28

    set_source_rgb(ctx, 0.70, 0.70, 0.70)
    set_line_width(ctx, 3.5)
    move_to(ctx, x, y)
    line_to(ctx, x + 42, y)
    stroke(ctx)
    _draw_cut_marker(ctx, x + 21, y)
    set_source_rgb(ctx, 0.05, 0.05, 0.05)
    move_to(ctx, x + 55, y + 4)
    show_text(ctx, "Cut")
end

function _draw_graph(ctx, state::GameState, pos)
    # background
    set_source_rgb(ctx, 0.98, 0.98, 0.95)
    paint(ctx)

    _draw_legend(ctx)

    # edges below vertices
    for e in state.graph.edges
        _draw_edge(ctx, e, pos[e.u.id], pos[e.v.id])
    end

    # vertices on top
    for v in state.graph.vertices
        _draw_vertex(ctx, v, pos[v.id], state.graph)
    end
end

function _point_segment_distance(px, py, x1, y1, x2, y2)::Float64
    dx = x2 - x1
    dy = y2 - y1
    denom = dx * dx + dy * dy

    if denom == 0.0
        return hypot(px - x1, py - y1)
    end

    t = ((px - x1) * dx + (py - y1) * dy) / denom
    t = max(0.0, min(1.0, t))

    qx = x1 + t * dx
    qy = y1 + t * dy

    return hypot(px - qx, py - qy)
end

function _clicked_edge(state::GameState, pos, x, y)::Union{Edge, Nothing}
    best = nothing
    best_dist = Inf

    for e in valid_moves(state)
        p1, p2 = _trimmed_segment(pos[e.u.id], pos[e.v.id])
        x1, y1 = p1
        x2, y2 = p2

        d = _point_segment_distance(x, y, x1, y1, x2, y2)

        if d < best_dist
            best_dist = d
            best = e
        end
    end

    return best_dist <= CLICK_TOLERANCE ? best : nothing
end

function _run_game(g::GameGraph = sample_graph())
    state_obs = Observable(new_game(g))
    pos = _positions(g)

    win = GtkWindow("Shannon Switching", GUI_WIDTH, GUI_HEIGHT + 100)

    vbox = GtkBox(:v)
    label = GtkLabel(_status_string(state_obs[]))
    canvas = GtkCanvas(GUI_WIDTH, GUI_HEIGHT)
    hbox = GtkBox(:h)
    btn = GtkButton("New Game")

    push!(win, vbox)
    push!(vbox, label)
    push!(vbox, canvas)
    push!(vbox, hbox)
    push!(hbox, btn)

    @guarded draw(canvas) do widget
        ctx = getgc(widget)
        _draw_graph(ctx, state_obs[], pos)
    end

    on(state_obs) do state
        Gtk4.G_.set_label(label, _status_string(state))
        draw(canvas)
    end

    click = GtkGestureClick()
    push!(canvas, click)

    signal_connect(click, "pressed") do _ctrl, _n_press, x, y
        state = state_obs[]
        !isnothing(state.winner) && return

        e = _clicked_edge(state, pos, x, y)
        isnothing(e) && return

        make_move!(state, e)
        notify(state_obs)
    end

    signal_connect(btn, "clicked") do _button
        state_obs[] = new_game(g)
    end

    show(win)
    draw(canvas)
    Gtk4.start_main_loop()

    return nothing
end