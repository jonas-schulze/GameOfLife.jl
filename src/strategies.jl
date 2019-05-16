"""
Subtypes of `DistributionStrategy` define how work should be distributed among
all available processing devices.
"""
abstract type DistributionStrategy end

const TILESIZE = 32

include("strategies/serial.jl")
include("strategies/threads.jl")
include("strategies/tasks_local.jl")
include("strategies/tasks_distributed.jl")
include("strategies/procs_local.jl")
include("strategies/procs_distributed.jl")
