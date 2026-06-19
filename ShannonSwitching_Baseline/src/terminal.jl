function _print_state(state::GameState)
    println("\nCurrent player: ", state.current_player)
    println("Edges:")
    for e in state.graph.edges
        println("  ", e.id, ": ", e.u.id, " -- ", e.v.id,
                "   state=", e.state, "   weight=", round(e.weight, digits=2))
    end
    if !isnothing(state.winner)
        println("Winner: ", state.winner)
    end
end

"""
    play_terminal(g=sample_graph())

Start a simple terminal version of the Shannon-Switching game.
Players choose edges by entering their edge id.
"""
function play_terminal(g::GameGraph=sample_graph())
    state = new_game(g)
    while isnothing(state.winner) && !isempty(valid_moves(state))
        _print_state(state)
        print("Choose edge id: ")
        input = readline()
        id = tryparse(Int, strip(input))
        if isnothing(id)
            println("Please enter a number.")
            continue
        end
        matches = [e for e in valid_moves(state) if e.id == id]
        if isempty(matches)
            println("Invalid move. Choose a neutral edge id.")
            continue
        end
        make_move!(state, matches[1])
    end
    _print_state(state)
    return state
end
