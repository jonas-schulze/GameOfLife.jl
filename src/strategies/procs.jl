using Distributed
using DistributedArrays

DA = DistributedArrays

"""
Use all workers available.
"""
struct ProcParallel <: DistributionStrategy end


function step!(new, old, ::ProcParallel)
    m, n = size(old)
    prepare!(old)
    @sync @distributed for c in 2:TILESIZE:n-1
        for r in 2:TILESIZE:m-1
            rows = r:min(r+TILESIZE-1, m-1)
            cols = c:min(c+TILESIZE-1, n-1)
            I = (rows,cols)
            life_rule!(new, old, I, I)
        end
    end
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
