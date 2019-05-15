"""
Split the work into `Task`s that are spawned on the local machine.

!!! warning

    Currently (Julia version 1.1), all tasks are scheduled onto the same thread.
    Check out [the docs](https://github.com/JuliaLang/julia/blame/80516ca20297a67b996caa08c38786332379b6a5/doc/src/manual/parallel-computing.md#L213-L217)
    or the help of `asyncmap` for more information.

    However, I personally hope/expect that in a future version of Julia this
    issue will be resolved. Check out [this PR on GitHub](https://github.com/JuliaLang/julia/pull/22631)
    and the [references therein](https://github.com/JuliaLang/julia/pull/22631#issuecomment-476472243).

"""
struct LocalTasks <: DistributionStrategy end

"""
There are several constructs in Julia to use coroutines. The example example
here uses a data-pipeline-ish style to demonstrate the use of `Channel`s.
For a more implicit/pragmatic implementation, take a look at `step!` using
`DArray`s where each `@async` creates and schedules a new `Task`.
"""
function step!(new, old, ::LocalTasks)
    m, n = size(old)

    Indices = UnitRange{Int}
    Tile = Tuple{Indices,Indices}
    tiles = Channel{Tile}(Sys.CPU_THREADS)

    # Define the work to be done asynchronously:
    @async begin
        for c in 2:TILESIZE:n-1
            for r in 2:TILESIZE:m-1
                rows = r:min(r+TILESIZE-1, m-1)
                cols = c:min(c+TILESIZE-1, n-1)
                I = (rows,cols)
                put!(tiles, I)
            end
        end
        close(tiles)
    end

    prepare!(old)

    # Start working on it right away, but wait until all are finished.
    # This will be ensured by the channel being closed.
    @sync for _ in 1:Sys.CPU_THREADS
        @async for I in tiles
            life_rule!(new, old, I, I)
        end
    end
end
