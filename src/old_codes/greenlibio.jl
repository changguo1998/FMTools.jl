_hash(x) = sha256(collect(reinterpret(UInt8, x)))

function _compressBoolarray(x::AbstractArray{Bool})
    nbuf = ceil(Int, length(x)/8)
    buf = zeros(UInt8, nbuf)
    for i = eachindex(x)
        (_j, _k) = divrem(i-1, 8)
        j = _j + 1
        k = _k + 1
        if x[i]
            buf[j] |= 1 << UInt8(8-k)
        else
            buf[j] &= ~(1 << UInt8(8-k))
        end
    end
    return buf
end

function _decompressBoolarray(cx::Array{UInt8})
    nbuf = length(cx)*8
    buf = falses(nbuf)
    for i = eachindex(cx)
        for j = 1:8
            k = (i-1) * 8 + j
            buf[k] = Bool((cx[i] >> (8-j)) & 0x01)
        end
    end
    return buf
end

"""
```
struct Gfun_head
    format::UInt32
    hash::Vector{UInt8}
    nx::Int32
    ny::Int32
    nz::Int32
    nt::Int32
    dx::Float32
    dy::Float32
    dz::Float32
    dt::Float32
    x0::Float32
    y0::Float32
    z0::Float32
    airflag::Array{Bool, 3}
    startpos::Array{Int64, 5}
    discription::String
end
```
"""
struct Gfun_head
    format::UInt32
    hash::Vector{UInt8}
    nx::Int32
    ny::Int32
    nz::Int32
    nt::Int32
    dx::Float32
    dy::Float32
    dz::Float32
    dt::Float32
    x0::Float32
    y0::Float32
    z0::Float32
    airflag::Array{Bool, 3}
    startpos::Array{Int64, 5}
    discription::String
end

"""
```
Gfun_head(format, hash, nx, ny, nz, nt, dx, dy, dz, dt, x0, y0, z0, 
    airflag, startpos, discription::String="")
```
"""
function Gfun_head(format::Integer, hash::AbstractVector{<:Integer},
        nx::Integer, ny::Integer, nz::Integer, nt::Integer,
        dx::AbstractFloat, dy::AbstractFloat, dz::AbstractFloat, dt::AbstractFloat,
        x0::AbstractFloat, y0::AbstractFloat, z0::AbstractFloat, 
        airflag::AbstractArray{Bool, 3}, startpos::AbstractArray{<:Integer, 5}, 
        discription::String="")
    return Gfun_head(Int32(format), UInt8.(hash), 
        Int32(nx), Int32(ny), Int32(nz), Int32(nt),
        Float32(dx), Float32(dy), Float32(dz), Float32(dt),
        Float32(x0), Float32(y0), Float32(z0),
        Bool.(airflag), Int64.(startpos), String(discription))
end

"""
```
Gfun_head(io::IO) -> Gfun_head
```
"""
function Gfun_head(io::IO)
    fmt = read(io, Int32)
    sha = zeros(UInt8, 32); read!(io, sha)
    nx = read(io, Int32)
    ny = read(io, Int32)
    nz = read(io, Int32)
    nt = read(io, Int32)
    dx = read(io, Float32)
    dy = read(io, Float32)
    dz = read(io, Float32)
    dt = read(io, Float32)
    x0 = read(io, Float32)
    y0 = read(io, Float32)
    z0 = read(io, Float32)
    caflag = zeros(UInt8, ceil(Int, nx*ny*nz/8)); read!(io, caflag)
    aflag = reshape(_decompressBoolarray(caflag)[1:nx*ny*nz], (nz, ny, nx))
    stpos = zeros(Int64, nz, ny, nx); read!(io, stpos)
    ndiscrip = read(io, Int32)
    discrip = zeros(Char, ndiscrip); read!(io, discrip)
    return Gfun_head(fmt, sha, nx, ny, nz, nt, dx, dy, dz, dt, x0, y0, z0,
        aflag, stpos, String(discrip))
end

"""
```
Gfun_head(path::AbstractString)
```
"""
Gfun_head(path::AbstractString) = open(Gfun_head, path)

"""
```
struct GreenFunction
    head::Gfun_head
    io::IO
end
```
"""
struct GreenFunction
    head::Gfun_head
    io::IO
end

"""
```
GreenFunction(path::AbstractString) -> GreenFunction
```
"""
function GreenFunction(path::AbstractString)
    _io = open(path)
    hd = Gfun_head(_io)
    return GreenFunction(hd, _io)
end

"""
```
closegf(gf::GreenFunction) -> GreenFunction
```
"""
function closegf(gf::GreenFunction)
    if isopen(gf.io)
        close(gf.io)
    end
    return nothing
end