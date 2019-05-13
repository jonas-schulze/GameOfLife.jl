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

function life_rule!(new, old, I)
    neighbours = [CartesianIndex(x,y) for x in -1:1, y in -1:1 if x!=0 || y!=0]
    for i in CartesianIndices(I)
        nc = sum(old[i+n] for n in neighbours)
        if old[i]
            new[i] = 2 <= nc <= 3
        else
            new[i] = nc == 3
        end
    end
    nothing
end
