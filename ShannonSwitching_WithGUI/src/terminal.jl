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
function play_terminal(g::GameGraph = sample_graph())
    state = new_game(g)

    while isnothing(state.winner)
        println()
        println("Current player: ", state.current_player)
        println("Edges:")

        for e in state.graph.edges
            println(
                "  ", e.id, ": ",
                e.u.id, " -- ", e.v.id,
                "   weight=", e.weight,
                "   state=", e.state
            )
        end

        print("Choose edge id: ")
        input = readline()

        edge_id = try
            parse(Int, input)
        catch
            println("Invalid input. Please enter an edge id.")
            continue
        end

        candidates = [e for e in valid_moves(state) if e.id == edge_id]

        if isempty(candidates)
            println("Invalid move. Choose a neutral edge id.")
            continue
        end

        make_move!(state, candidates[1])
    end

    println()
    println("Winner: ", state.winner)
    return state
end