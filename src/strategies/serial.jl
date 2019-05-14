"""
Do not distribute the work at all.
Perform all computations one after another.
"""
struct Serial <: DistributionStrategy end

function step!(new, old, ::Serial)
    m, n = size(old)
    I = (2:m-1,2:n-1)
    prepare!(old)
    life_rule!(new, old, I, I)
end
