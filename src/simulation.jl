"""
    step!(new, old, ::DistributionStrategy)

Perform one iteration of Conway's Game of Life.
"""
step!

"""
    prepare!(grid)

Prepare the grid to be used as the old/current world stage for `step!`.
Assuming that only inner cells, `grid[2:end-1,2:end-1]`, contain actual
world information, mirror the edges of that grid.
"""
function prepare!(grid)
    m, n = size(grid)
    @views begin
        grid[1,2:n-1] .= grid[m-1,2:n-1]
        grid[m,2:n-1] .= grid[2,2:n-1]
        # Now we are good to include the corners as well:
        grid[1:m,1] .= grid[1:m,n-1]
        grid[1:m,n] .= grid[1:m,2]
    end
    nothing
end

function prepare!(grid::DArray)
    m, n = size(grid)
    P = procs(grid)
    # Note: To simplify the code, we'll set the corners of the matrix twice.
    @sync begin
        for p in P[1,:]
            @async remotecall_fetch(p) do
                _, cols = localindices(grid)
                lgrid = localpart(grid)
                view(lgrid, 1, :) .= grid[m-1,cols]
                nothing
            end
        end
        for p in P[end,:]
            @async remotecall_fetch(p) do
                _, cols = localindices(grid)
                lgrid = localpart(grid)
                lm, ln = size(lgrid)
                view(lgrid, lm, :) .= grid[2,cols]
                nothing
            end
        end
    end
    # Now we are good to include the corners as well:
    @sync begin
        for p in P[:,1]
            @async remotecall_fetch(p) do
                rows, _ = localindices(grid)
                lgrid = localpart(grid)
                view(lgrid, :, 1) .= grid[rows,n-1]
                nothing
            end
        end
        for p in P[:,end]
            @async remotecall_fetch(p) do
                rows, _ = localindices(grid)
                lgrid = localpart(grid)
                lm, ln = size(lgrid)
                view(lgrid, :, ln) .= grid[rows,2]
                nothing
            end
        end
    end
    nothing
end

function life_rule!(new, old, newindices, oldindices)
    neighbours = [CartesianIndex(x,y) for x in -1:1, y in -1:1 if x!=0 || y!=0]
    for (i,j) in zip(CartesianIndices(oldindices), CartesianIndices(newindices))
        nc = sum(old[i+n] for n in neighbours)
        if old[i]
            new[j] = 2 <= nc <= 3
        else
            new[j] = nc == 3
        end
    end
    nothing
end

interior(r::OrdinalRange) = r[2:end-1]
interior(t::Tuple) = map(interior, t)
interior(m::AbstractMatrix) = @view m[interior(axes(m))...]
