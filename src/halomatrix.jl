import Base: size, IndexStyle, getindex
import DistributedArrays: localindices
using DistributedArrays: DArray

# Since `localpart(A)` defaults to `A`, so should `localindices(A)`.
localindices(A) = axes(A)

"""
`HaloMatrix` provides convenience access to the directly surrounding rows and
columns of a matrix: left `l`, right `c`, top `t`, bottom `b` and the matrix
itself in the center `c`:

    | -t- |
    l  c  r
    | -b- |
"""
mutable struct HaloMatrix{T,V,M} <: AbstractMatrix{T}
    dims::Tuple{Int,Int}
    l::V
    r::V
    t::V
    b::V
    c::M
end

function HaloMatrix(matrix::M) where M
    m, n = size(matrix)

    l = similar(matrix, m+2)
    t = similar(matrix, n)
    r = similar(l)
    b = similar(t)

    T = eltype(matrix)
    V = typeof(l)
    HaloMatrix{T,V,M}((m+2,n+2), l, r, t, b, matrix)
end

Base.size(h::HaloMatrix) = h.dims
Base.IndexStyle(::Type{<:HaloMatrix}) = IndexCartesian()
function Base.getindex(s::HaloMatrix, I::Vararg{Int,2})
    r, c = I
    m, n = size(s)
    1 < r < m && 1 < c < n && return s.c[r-1,c-1]
    c == 1 && return s.l[r]
    c == n && return s.r[r]
    r == 1 && return s.t[c-1]
    return s.b[c-1]
end

interior(x) = @view x[2:end-1,2:end-1]
interior(h::HaloMatrix) = h.c

"""
Bring about the halo of the matrix `M`.

For "local" matrices, it is better to create a bigger matrix:

```julia
halo = BitArray(undef, n+2, n+2)
grid = interior(grid)
glorify!(halo, grid)
# not yet implemented .. :(
```
"""
function glorify(M)
    halo = HaloMatrix(localpart(M))
    glorify!(halo, M)
    halo
end

"""
Regenerate the `halo` according to the matrix `M`.
"""
function glorify!(halo::HaloMatrix, M)
    m, n = size(M)
    rows, cols = localindices(M)

    # Compute indices:
    il = mod(first(cols)-2, n) + 1
    ir = mod( last(cols)  , n) + 1
    it = mod(first(rows)-2, m) + 1
    ib = mod( last(rows)  , m) + 1

    # Copy the halo:
    halo.l[1]   = M[it,il]
    halo.l[end] = M[ib,il]
    halo.r[1]   = M[it,ir]
    halo.r[end] = M[ib,ir]
    @views begin
        halo.l[2:end-1] .= M[rows,  il]
        halo.r[2:end-1] .= M[rows,  ir]
        halo.t[:]       .= M[  it,cols]
        halo.b[:]       .= M[  ib,cols]
    end
    halo.c = localpart(M)
    nothing
end

