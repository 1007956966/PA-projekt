using Test
using ShannonSwitching

@testset "basic game setup" begin
    g = sample_graph()
    state = new_game(g)
    @test state.current_player == :short
    @test isnothing(state.winner)
    @test length(valid_moves(state)) == length(g.edges)
    @test check_winner(state) === nothing
end

@testset "Short win" begin
    g = sample_graph()
    state = new_game(g)
    make_move!(state, g.edges[1]) # Short: 1--2
    make_move!(state, g.edges[3]) # Cut:   1--3
    make_move!(state, g.edges[2]) # Short: 2--4, now s--2--t
    @test state.winner == :short
end

@testset "Cut win" begin
    v = [Vertex(i) for i in 1:3]
    edges = Edge[
        Edge(1, v[1], v[2]),
        Edge(2, v[2], v[3]),
    ]
    g = GameGraph(v, edges, v[1], v[3])
    state = new_game(g)
    make_move!(state, g.edges[1]) # Short claims first edge
    make_move!(state, g.edges[2]) # Cut removes second edge, no s-t path remains
    @test state.winner == :cut
end

@testset "invalid moves" begin
    g = sample_graph()
    state = new_game(g)
    make_move!(state, g.edges[1])
    @test_throws AssertionError make_move!(state, g.edges[1])
end

@testset "strategies return legal moves" begin
    g = sample_graph(weighted=true)
    state = new_game(g)
    @test weighted_short(state).state == :neutral
    @test weighted_cut(state).state == :neutral
    @test short_strategy(state).state == :neutral
    @test cut_strategy(state).state == :neutral
end
