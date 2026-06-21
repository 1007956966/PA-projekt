module ShannonSwitching

include("types.jl")
include("graph_utils.jl")
include("game.jl")
include("strategies.jl")
include("terminal.jl")

export Vertex, Edge, GameGraph, GameState
export new_game, valid_moves, make_move!, check_winner
export sample_graph, random_graph
export has_st_path, find_st_path, shortest_st_path, path_weight
export random_strategy, short_strategy, cut_strategy
export weighted_short, weighted_cut, TEAM_NAME
export play_terminal, run_game

"""
    run_game(g::GameGraph=sample_graph(weighted=true))

Start a small Gtk4/Cairo graphical interface for the Shannon-Switching game.
The GUI is loaded lazily so that the core package and tests still work even
when the graphical libraries are not needed.
"""
function run_game(g::GameGraph = sample_graph())
    if !isdefined(@__MODULE__, :_run_game)
        include(joinpath(@__DIR__, "gui.jl"))
    end

    f = getfield(@__MODULE__, :_run_game)
    return Base.invokelatest(f, g)
end

end # module
