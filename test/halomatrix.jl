using GameOfLife: glorify, glorify!, HaloMatrix

@testset "HaloMatrix" begin
    a = reshape(1:12, 3, 4) |> collect
    b = [12 3 6 9 12 3;
         10 1 4 7 10 1;
         11 2 5 8 11 2;
         12 3 6 9 12 3;
         10 1 4 7 10 1]
    h = glorify(a)

    @test h isa HaloMatrix
    @test size(h) == (5,6)
    @test h[2:end-1,2:end-1] == a
    @test h == b

    # The inner part must share the data:
    a[1,1] = 13
    @test h[2,2] == 13

    # After a refresh, the inner data is propagated to the halo:
    glorify!(h, a)
    @test h[2,2] == h[end,end] == 13
end

