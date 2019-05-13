using Test, GameOfLife

interior(grid) = @view grid[2:end-1,2:end-1]

function generate(world)
    m, n = size(world)
    grid = BitArray(undef, m+2, n+2)
    interior(grid) .= world
    grid
end

world0 = [0 0 0 0 1 1 1;
          0 1 1 1 0 0 0;
          0 0 0 0 1 0 1]
world1 = [1 0 1 0 1 0 1;
          1 0 1 1 0 0 1;
          1 0 1 0 1 0 1]

m, n = size(world0)

@testset "general simulation tools" begin
    g0 = generate(world0)
    prepare!(g0)
    @test g0 == [1 0 0 0 0 1 0 1 0;
                 1 0 0 0 0 1 1 1 0;
                 0 0 1 1 1 0 0 0 0;
                 1 0 0 0 0 1 0 1 0;
                 1 0 0 0 0 1 1 1 0]
    g1 = similar(g0)
    life_rule!(g1, g0, (2:m+1,2:n+1))
    @test interior(g1) == world1
end

@testset "distribution strategies" begin
    @testset "$S" for S in [Serial]
        old = generate(world0)
        new = similar(old)
        step!(new, old, S())
        @test interior(old) == world0
        @test interior(new) == world1
    end
end
