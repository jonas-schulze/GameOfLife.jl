using Distributed
using DistributedArrays

DA = DistributedArrays

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

function step!(new::DArray, old::DArray, ::ProcParallel)
    prepare!(old)
    @sync for p in DA.procs(old)
        @async remotecall_fetch(p) do
            @assert localindices(new) == localindices(old)
            m, n = size(old)
            rows, cols = localindices(old)

            # start and length of the window to compute in:
            r = c = 1
            h = length(rows)
            w = length(cols)

            # check whether to cut of mirrored edges of the grid:
            if rows[1] == 1
                h -= 1
                r = 2
            end
            if rows[end] == m
                h -= 1
            end
            if cols[1] == 1
                w -= 1
                c = 2
            end
            if cols[end] == n
                w -= 1
            end

            newindices = (r:r+h-1, c:c+w-1)
            oldindices = (rows[newindices[1]], cols[newindices[2]])

            life_rule!(localpart(new), old, newindices, oldindices)
            nothing
        end
    end
end
