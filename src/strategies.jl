"""
Subtypes of `DistributionStrategy` define how work should be distributed among
all available processing devices.
"""
abstract type DistributionStrategy end

const TILESIZE = 32

include("strategies/serial.jl")
include("strategies/threads.jl")
include("strategies/procs.jl")
