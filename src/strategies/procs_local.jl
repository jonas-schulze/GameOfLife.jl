using Distributed

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
