using Test, GameOfLife
using SharedArrays
using DistributedArrays: distribute

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

function generate(world, ::DistributedTasks)
    grid = generate(world, Serial())
    distribute(grid)
end

world0 = [0 0 0 0 1 1 1;
          0 1 1 1 0 0 0;
          0 0 0 0 1 0 1]
world1 = [1 0 1 0 1 0 1;
          1 0 1 1 0 0 1;
          1 0 1 0 1 0 1]

@testset "general simulation tools" begin
    m, n = size(world0)
    g0 = generate(world0)
    prepare!(g0)
    @test g0 == [1 0 0 0 0 1 0 1 0;
                 1 0 0 0 0 1 1 1 0;
                 0 0 1 1 1 0 0 0 0;
                 1 0 0 0 0 1 0 1 0;
                 1 0 0 0 0 1 1 1 0]
    g1 = similar(g0)
    I = (2:m+1,2:n+1)
    life_rule!(g1, g0, I, I)
    @test interior(g1) == world1
end

const Strategies = [Serial, ThreadParallel, ProcParallel, LocalTasks, DistributedTasks]

@testset "distribution strategies" begin
    @testset "$S" for S in Strategies
        s = S()
        old = generate(world0, s)
        new = similar(old)
        step!(new, old, s)
        @test interior(old) == world0
        @test interior(new) == world1
    end
end

function randomize!(x)
    for i in eachindex(x)
        x[i] = rand(eltype(x))
    end
end

# Props to ffevotte: https://discourse.julialang.org/t/print-debug-info-for-failed-test/22311
onfail(body, x) = error("I might have overlooked something: $x")
onfail(body, _::Test.Pass) = nothing
onfail(body, _::Tuple{Test.Fail,T}) where {T} = body()

gettuples(x) = map(Tuple, x |> interior |> findall)

E_new = Dict()

# If this suite fails, run the script via including the file and plot the grid:
#
# using Plots
# scatter(gettuples(E_ref .!= E_new[S]), markersize=1)
@testset "slightly bigger dataset" begin
    n = 2*GameOfLife.TILESIZE + GameOfLife.TILESIZE÷2
    g = BitArray(undef, n, n)
    randomize!(g)
    ref = similar(g)
    step!(ref, g, Serial())

    @testset "$S" for S in Strategies[2:end]
        s = S()
        old = generate(interior(g), s)
        new = similar(old)
        step!(new, old, s)
        onfail(@test interior(new) == interior(ref)) do
            global E_old = g
            global E_ref = ref
            global E_new[S] = new
        end
    end
end
