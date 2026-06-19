function _print_state(state::GameState)
    println("\nCurrent player: ", state.current_player)
    println("Edges:")
    for e in state.graph.edges
        println("  ", e.id, ": ", e.u.id, " -- ", e.v.id, "  weight=", e.weight, "  state=", e.state)
    end
    if !isnothing(state.winner)
        println("Winner: ", state.winner)
    end
end

"Play a complete game in the terminal by entering edge ids."
function play_terminal(g::GameGraph=sample_graph())::Nothing
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
        edge = nothing
        for e in valid_moves(state)
            if e.id == id
                edge = e
                break
            end
        end
        if isnothing(edge)
            println("Invalid move. Choose a neutral edge id.")
            continue
        end
        make_move!(state, edge)
    end
    _print_state(state)
    isnothing(state.winner) && println("No winner: no neutral edges left.")
    return nothing
end
