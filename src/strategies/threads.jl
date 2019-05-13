using .Threads: @threads

"""
Use all threads available to the current process.
"""
struct ThreadParallel <: DistributionStrategy end

function step!(new, old, ::ThreadParallel)
    m, n = size(old)
    prepare!(old)
    @threads for c in 2:TILESIZE:n-1
        for r in 2:TILESIZE:m-1
            rows = r:min(r+TILESIZE-1, m-1)
            cols = c:min(c+TILESIZE-1, n-1)
            life_rule!(new, old, (rows, cols))
        end
    end
end
