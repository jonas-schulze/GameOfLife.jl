using Distributed
using DistributedArrays

DA = DistributedArrays

"""
Split the work into `Task`s that are spawned on all workers available.
"""
struct DistributedTasks <: DistributionStrategy end

function step!(new::DArray, old::DArray, ::DistributedTasks)
    m, n = size(old)

    Indices = UnitRange{Int}
    Tile = Tuple{Indices,Indices}
    channels = [RemoteChannel(()->Channel{Tile}(Sys.CPU_THREADS)) for _ in procs(old)]

    indices = old.indices
    @assert size(indices) == size(channels)

    for (chan,indices) in zip(channels,indices)
        @async begin
            t_rows, t_cols = indices
            rend = min(m-1, last(t_rows))
            cend = min(n-1, last(t_cols))
            for c in max(2,first(t_cols)):TILESIZE:cend
                for r in max(2,first(t_rows)):TILESIZE:rend
                    rows = r:min(r+TILESIZE-1, rend)
                    cols = c:min(c+TILESIZE-1, cend)
                    I = (rows,cols)
                    put!(chan, I)
                end
            end
            close(chan)
        end
    end

    prepare!(old)

    @sync for (p,chan) in zip(procs(old),channels)
        # One could even use threads or local tasks on worker p.
        # In this scenario it's not useful though.
        @spawnat p begin
            for I in chan
                oldindices = I
                # Transform tile indices onto local indices:
                rows, cols = I
                offset = map(first,localindices(old))
                newindices = (first(rows)-offset[1]+1:last(rows)-offset[1]+1,
                              first(cols)-offset[2]+1:last(cols)-offset[2]+1)
                life_rule!(localpart(new), old, newindices, oldindices)
            end
        end
    end
end
