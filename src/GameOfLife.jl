"""
Toy program to demonstrate/practice parallel programming techniques.
"""
module GameOfLife

include("halomatrix.jl")
include("strategies.jl")
include("simulation.jl")

export step!, prepare!, life_rule!
export Serial, ThreadParallel, ProcParallel

end
