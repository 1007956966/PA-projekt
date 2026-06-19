using Test
using ShannonSwitching

println("Running ShannonSwitching tests...")

@testset "Package loads" begin
    @test true
end

@testset "New game and valid moves" begin
    g = sample_graph()
    state = new_game(g)

    @test state.current_player == :short
    @test state.winner === nothing
    @test length(valid_moves(state)) == 5
    @test [e.id for e in valid_moves(state)] == [1, 2, 3, 4, 5]
end

@testset "Short wins" begin
    g = sample_graph()
    state = new_game(g)

    make_move!(state, g.edges[1])  # Short: 1 -- 2
    make_move!(state, g.edges[3])  # Cut:   1 -- 3
    make_move!(state, g.edges[2])  # Short: 2 -- 4

    @test state.winner == :short
end

@testset "Cut wins" begin
    g = sample_graph()
    state = new_game(g)

    make_move!(state, g.edges[1])  # Short: 1 -- 2
    make_move!(state, g.edges[2])  # Cut:   2 -- 4
    make_move!(state, g.edges[3])  # Short: 1 -- 3
    make_move!(state, g.edges[4])  # Cut:   3 -- 4

    @test state.winner == :cut
end

@testset "Illegal repeated move throws error" begin
    g = sample_graph()
    state = new_game(g)

    make_move!(state, g.edges[1])
    @test_throws AssertionError make_move!(state, g.edges[1])
end

@testset "Strategies return neutral edges" begin
    g = sample_graph(weighted=true)
    state = new_game(g)

    @test random_strategy(state).state == :neutral
    @test short_strategy(state).state == :neutral
    @test cut_strategy(state).state == :neutral
    @test weighted_short(state).state == :neutral
    @test weighted_cut(state).state == :neutral
end

println("All ShannonSwitching tests finished.")