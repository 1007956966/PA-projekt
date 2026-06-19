module ShannonSwitching

include("types.jl")
include("graph_utils.jl")
include("game.jl")
include("strategies.jl")
include("terminal.jl")
include("gui.jl")

export Vertex, Edge, GameGraph, GameState
export new_game, valid_moves, make_move!, check_winner
export random_graph, sample_graph
export has_st_path, find_st_path, shortest_st_path, path_weight
export random_strategy, short_strategy, cut_strategy
export weighted_short, weighted_cut, TEAM_NAME
export play_terminal, run_game

end # module
