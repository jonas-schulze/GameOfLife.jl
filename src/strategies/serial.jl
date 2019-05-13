"""
Do not distribute the work at all.
Perform all computations one after another.
"""
struct Serial <: DistributionStrategy end

function step!(new, old, ::Serial)
    m, n = size(old)
    prepare!(old)
    life_rule!(new, old, (2:m-1, 2:n-1))
end
