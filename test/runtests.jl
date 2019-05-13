using Test, GameOfLife
using SharedArrays

interior(grid) = @view grid[2:end-1,2:end-1]

function generate(world, s=Serial())
    m, n = size(world)
    grid = BitArray(undef, m+2, n+2)
    interior(grid) .= world
    grid
end

function generate(world, ::ProcParallel)
    m, n = size(world)
    grid = SharedArray{Bool,2}(m+2, n+2)
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
    @testset "$S" for S in [Serial, ThreadParallel, ProcParallel]
        s = S()
        old = generate(world0, s)
        new = similar(old)
        step!(new, old, s)
        @test interior(old) == world0
        @test interior(new) == world1
    end
end
