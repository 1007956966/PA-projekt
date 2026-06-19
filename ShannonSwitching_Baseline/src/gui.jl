# GUI code is intentionally isolated from the game logic. The game and strategy
# files do not depend on Gtk4, Cairo, or GtkObservables.
const HAS_GUI = Ref(false)

try
    @eval using Gtk4
    @eval using GtkObservables
    @eval using Cairo
    HAS_GUI[] = true
catch err
    @warn "GUI dependencies could not be loaded. Terminal mode still works." exception=(err, catch_backtrace())
end

const CANVAS_W = 700
const CANVAS_H = 500
const NODE_R = 18.0
const EDGE_CLICK_TOL = 12.0

function _circle_layout(g::GameGraph)
    n = length(g.vertices)
    cx, cy = CANVAS_W / 2, CANVAS_H / 2
    r = min(CANVAS_W, CANVAS_H) * 0.35
    pos = Dict{Int, Tuple{Float64, Float64}}()
    for (k, v) in enumerate(g.vertices)
        theta = 2pi * (k - 1) / n
        pos[v.id] = (cx + r * cos(theta), cy + r * sin(theta))
    end
    # Make sample graph easier to read.
    if sort([v.id for v in g.vertices]) == [1, 2, 3, 4]
        pos[1] = (100.0, 250.0)
        pos[2] = (320.0, 130.0)
        pos[3] = (320.0, 370.0)
        pos[4] = (580.0, 250.0)
    end
    return pos
end

function _status_string(state::GameState)::String
    if state.winner == :short
        return "Short wins!"
    elseif state.winner == :cut
        return "Cut wins!"
    else
        return "Current player: $(state.current_player)"
    end
end

function _dist_point_segment(px, py, x1, y1, x2, y2)
    dx, dy = x2 - x1, y2 - y1
    if dx == 0 && dy == 0
        return hypot(px - x1, py - y1)
    end
    t = ((px - x1) * dx + (py - y1) * dy) / (dx^2 + dy^2)
    t = max(0.0, min(1.0, t))
    qx, qy = x1 + t * dx, y1 + t * dy
    return hypot(px - qx, py - qy)
end

function _edge_at_position(g::GameGraph, pos, x, y)::Union{Edge, Nothing}
    best = nothing
    best_d = Inf
    for e in g.edges
        x1, y1 = pos[e.u.id]
        x2, y2 = pos[e.v.id]
        d = _dist_point_segment(x, y, x1, y1, x2, y2)
        if d < best_d
            best_d = d
            best = e
        end
    end
    return best_d <= EDGE_CLICK_TOL ? best : nothing
end

function _draw_graph(ctx, state::GameState, pos)
    # Background
    set_source_rgb(ctx, 0.96, 0.96, 0.92)
    paint(ctx)

    # Edges
    for e in state.graph.edges
        x1, y1 = pos[e.u.id]
        x2, y2 = pos[e.v.id]

        if e.state == :neutral
            set_source_rgb(ctx, 0.45, 0.45, 0.45)
            set_dash(ctx, Float64[])
            set_line_width(ctx, 3.0)
        elseif e.state == :short
            set_source_rgb(ctx, 0.10, 0.25, 0.90)
            set_dash(ctx, Float64[])
            set_line_width(ctx, 5.0)
        else # :cut
            set_source_rgb(ctx, 0.85, 0.10, 0.10)
            set_dash(ctx, [8.0, 6.0])
            set_line_width(ctx, 4.0)
        end

        move_to(ctx, x1, y1)
        line_to(ctx, x2, y2)
        stroke(ctx)
        set_dash(ctx, Float64[])

        # Edge id / weight label
        mx, my = (x1 + x2) / 2, (y1 + y2) / 2
        set_source_rgb(ctx, 0.05, 0.05, 0.05)
        move_to(ctx, mx + 5, my - 5)
        show_text(ctx, string(e.id))
    end

    # Vertices
    for v in state.graph.vertices
        x, y = pos[v.id]
        if v == state.graph.s
            set_source_rgb(ctx, 0.10, 0.70, 0.20)
        elseif v == state.graph.t
            set_source_rgb(ctx, 0.70, 0.10, 0.70)
        else
            set_source_rgb(ctx, 0.15, 0.15, 0.15)
        end
        arc(ctx, x, y, NODE_R, 0.0, 2pi)
        fill(ctx)
        set_source_rgb(ctx, 1.0, 1.0, 1.0)
        move_to(ctx, x - 5, y + 5)
        label = v == state.graph.s ? "s" : (v == state.graph.t ? "t" : string(v.id))
        show_text(ctx, label)
    end
end

if HAS_GUI[]
    @eval begin
        """
            run_game(g=sample_graph())

        Open a simple Gtk4/Cairo GUI for the Shannon-Switching game.
        Click a neutral edge to make a move. Optional checkboxes let the baseline AI
        play for Short and/or Cut.
        """
        function run_game(g::GameGraph=sample_graph())
            state_obs = Observable(new_game(g))
            pos = _circle_layout(g)

            win = GtkWindow("Shannon-Switching", CANVAS_W, CANVAS_H + 100)
            vbox = GtkBox(:v)
            label = GtkLabel(_status_string(state_obs[]))
            canvas = GtkCanvas(CANVAS_W, CANVAS_H)
            hbox = GtkBox(:h)
            ai_short = GtkCheckButton("Computer Short")
            ai_cut = GtkCheckButton("Computer Cut")
            btn = GtkButton("New Game")

            push!(win, vbox)
            push!(vbox, label)
            push!(vbox, canvas)
            push!(vbox, hbox)
            push!(hbox, ai_short)
            push!(hbox, ai_cut)
            push!(hbox, btn)

            @guarded draw(canvas) do widget
                ctx = getgc(widget)
                _draw_graph(ctx, state_obs[], pos)
            end

            function maybe_ai_move()
                s = state_obs[]
                !isnothing(s.winner) && return
                isempty(valid_moves(s)) && return
                ai_on = s.current_player == :short ? Gtk4.G_.get_active(ai_short) : Gtk4.G_.get_active(ai_cut)
                ai_on || return

                @idle_add begin
                    s2 = state_obs[]
                    if isnothing(s2.winner) && !isempty(valid_moves(s2))
                        e = s2.current_player == :short ? weighted_short(s2) : weighted_cut(s2)
                        make_move!(s2, e)
                        notify(state_obs)
                        maybe_ai_move()
                    end
                    return false
                end
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
                edge = _edge_at_position(state.graph, pos, x, y)
                isnothing(edge) && return
                edge.state == :neutral || return
                make_move!(state, edge)
                notify(state_obs)
                maybe_ai_move()
            end

            signal_connect(btn, "clicked") do _
                state_obs[] = new_game(g)
                maybe_ai_move()
            end

            show(win)
            draw(canvas)
            maybe_ai_move()
            Gtk4.start_main_loop()
            return nothing
        end
    end
else
    """
        run_game(g=sample_graph())

    Open the GUI version of the game. If GUI dependencies are unavailable, use
    `play_terminal()` instead.
    """
    function run_game(g::GameGraph=sample_graph())
        error("GUI dependencies are not available. Use play_terminal() instead.")
    end
end
