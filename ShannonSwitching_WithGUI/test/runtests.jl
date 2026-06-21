using Test
using ShannonSwitching

@testset "basic game logic" begin
    g = sample_graph()
    state = new_game(g)
    @test length(valid_moves(state)) == 5
    @test check_winner(state) === nothing
    @test state.current_player == :short

    make_move!(state, g.edges[1])  # short: 1--2
    @test state.current_player == :cut
    @test g.edges[1].state == :short

    make_move!(state, g.edges[3])  # cut: 1--3
    @test state.current_player == :short
    @test g.edges[3].state == :cut

    make_move!(state, g.edges[2])  # short: 2--4, wins
    @test state.winner == :short
end

@testset "cut win" begin
    g = sample_graph()
    state = new_game(g)
    g.edges[1].state = :cut
    g.edges[3].state = :cut
    @test check_winner(state) == :cut
end

@testset "strategies return legal moves" begin
    g = sample_graph(weighted=true)
    state = new_game(g)
    @test random_strategy(state).state == :neutral
    @test weighted_short(state).state == :neutral
    @test weighted_cut(state).state == :neutral
    @test short_strategy(state).state == :neutral
    @test cut_strategy(state).state == :neutral
end

@testset "Random graph support" begin
    g = random_graph(8, 12; weighted=true)
    state = new_game(g)

    @test length(g.vertices) == 8
    @test length(g.edges) == 12
    @test length(valid_moves(state)) == 12
    @test state.current_player == :short
    @test state.winner === nothing

    # Strategies should return legal neutral edges.
    @test weighted_short(state).state == :neutral
    @test weighted_cut(state).state == :neutral
end