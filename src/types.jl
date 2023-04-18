# * global variable
_TimePrecision = Millisecond
_TimeSecondRatio = _TimePrecision(Second(1))/_TimePrecision(1)

function settimeprecision!(T::Type)
    @must T <: TimePeriod
    global _TimePrecision = T
    global _TimeSecondRatio = _TimePrecision(Second(1))/_TimePrecision(1)
    return nothing
end

_LongAgo = DateTime(1800)

# * types

"""
```
struct Direction3D <: Any
    x::Float64
    y::Float64
    z::Float64
end
```

3D direction in N-E-D coordinate system
"""
struct Direction3D <: Any
    x::Float64
    y::Float64
    z::Float64
    function Direction3D(x::Float64, y::Float64, z::Float64)
        @must norm([x,y,z]) > 0.0
        n = norm([x, y, z])
        return new(x/n, y/n, z/n)
    end
end

"""
```
Direction3D(x, y, z)
```
"""
Direction3D(x::Real, y::Real, z::Real) = Direction3D(Float64(x), Float64(y), Float64(z))

"""
```
Direction3D(incline, azimuth)
```

incline is relative to up dirction
"""
function Direction3D(inc::Real, az::Real)
    z = cosd(180.0-inc)
    r = sind(180.0-inc)
    x = r * cosd(az)
    y = r * sind(az)
    return Direction3D(x, y, z)
end

"""
```
Direction3D(directionName::String)
```

using direction name to set `Direction3D`. Available direction names are:
- N north
- E east
- S south
- W west
- U up
- D down
"""
function Direction3D(s::String)
    if s == "N"
        return Direction3D(90, 0)
    elseif s == "E"
        return Direction3D(90, 90)
    elseif s == "S"
        return Direction3D(90, 180)
    elseif s == "W"
        return Direction3D(90, 270)
    elseif s == "U"
        return Direction3D(0, 0)
    elseif s == "D"
        return Direction3D(180, 0)
    else
        error("Direction name not valid")
    end
end

"""
```
incaz(dirc::Direction3D) -> (inc, az)
```

return incline and azimuth of direction
"""
function incaz(dirc::Direction3D)
    inc = 180.0 - acosd(dirc.z)
    az = atand(dirc.y, dirc.x)
    return (inc, az)
end

# = = = = =
# = types of input data
# = = = = =
abstract type PreprocessedData <: Any end

"""
```
mutable struct Phase <: PreprocessedData
    # - phase info
    ptype::String
    at::DateTime
    tt::TimePeriod
    # - cross ref
    idobjects::Vector{Int}
    idchannel::Int
    idstation::Int
end
```
"""
mutable struct Phase <: PreprocessedData
    # - phase info
    ptype::String
    at::DateTime
    tt::TimePeriod
    # - cross ref
    idobjects::Vector{Int}
    idchannel::Int
    idstation::Int
end

"""
```
Phase(ptype, at, tt; idobjects, idchannel, idstation) -> Phase
```

construct Phase type
- ptype AbstractString
- at DateTime
- tt TimePeriod or Real. when tt is Real, it will be treated as second
"""
function Phase(ptype::AbstractString, at::DateTime, tt::Union{TimePeriod,Real}=_TimePrecision(0);
    idobjects::AbstractVector{<:Integer}=Int[], idchannel::Integer=0, idstation::Integer=0)
    if typeof(tt) <: Real
        tt = _Second(tt)
    end
    return Phase(String(ptype), at, tt, Int.(idobjects), Int(idchannel), Int(idstation))
end

"""
```
mutable struct RecordChannel <: PreprocessedData
    # - required field
    dircname::String
    filepath::String
    glibmodel::String
    # - channel info
    direction::Direction3D
    # - record data
    rbt::DateTime
    ret::DateTime
    rdt::TimePeriod
    record::Vector{Float64}
    # - synthetic data
    glibpath::String
    tlibpath::String
    gbt::TimePeriod
    gdt::TimePeriod
    greenfun::Matrix{Float64}
    # - cross ref
    idphase::Vector{Int}
    idstation::Int
end
```
"""
mutable struct RecordChannel <: PreprocessedData
    # - required field
    dircname::String
    filepath::String
    # - channel info
    direction::Direction3D
    # - record data
    rbt::DateTime
    ret::DateTime
    rdt::TimePeriod
    record::Vector{Float64}
    # - synthetic data
    glibmodel::String
    glibpath::String
    tlibpath::String
    gbt::TimePeriod
    gdt::TimePeriod
    greenfun::Matrix{Float64}
    # - cross ref
    idphase::Vector{Int}
    idstation::Int
end

"""
```
RecordChannel(dircname, filepath, glibmodel; direction=nothing, rbt, ret, rdt, record,
    glibpath, tlibpath, gbt, gdt, greenfun, idphase, idstation) -> RecordChannel
```
"""
function RecordChannel(dircname::Union{AbstractString,AbstractChar}, 
    filepath::AbstractString;
    direction::Union{Direction3D,Nothing}=nothing, 
    rbt::DateTime=_LongAgo, ret::DateTime=_LongAgo,
    rdt::Union{TimePeriod,Real}=_TimePrecision(0), 
    record::AbstractVector{<:Real}=Float64[], 
    glibmodel::AbstractString="", glibpath::AbstractString="", 
    tlibpath::AbstractString="", 
    gbt::Union{TimePeriod,Real}=_TimePrecision(0),
    gdt::Union{TimePeriod,Real}=_TimePrecision(0),
    greenfun::AbstractMatrix{<:Real}=zeros(Float64,0,6), 
    idphase::AbstractVector{<:Integer}=Int[],
    idstation::Integer=0)
    if typeof(dircname) <: AbstractChar
        dircname = String([dircname])
    end
    if isnothing(direction)
        println("use default derection")
        direction = Direction3D(String(dircname))
    end
    if typeof(rdt) <: Real
        rdt = _Second(rdt)
    end
    if typeof(gbt) <: Real
        gbt = _Second(gbt)
    end
    if typeof(gdt) <: Real
        gdt = _Second(gdt)
    end
    return RecordChannel(String(dircname), String(filepath),
        direction, rbt, ret, rdt, Float64.(record), String(glibmodel), 
        String(glibpath), String(tlibpath),
        gbt, gdt, Float64.(greenfun), Int.(idphase), Int(idstation))
end

"""
```
mutable struct Station <: PreprocessedData
    # - station info
    network::String
    station::String
    lat::Float64
    lon::Float64
    el::Float64
    # - auxiliary info
    dist::Float64
    az::Float64
    azx::Float64
    azy::Float64
    baz::Float64
    bazx::Float64
    bazy::Float64
    # - cross ref
    idchannel::Vector{Int}
end
```
"""
mutable struct Station <: PreprocessedData
    # - station info
    network::String
    station::String
    lat::Float64
    lon::Float64
    el::Float64
    # - auxiliary info
    dist::Float64
    az::Float64
    azx::Float64
    azy::Float64
    baz::Float64
    bazx::Float64
    bazy::Float64
    # - cross ref
    idchannel::Vector{Int}
end

"""
```
Station(network, station, lat, lon, el;
    dist, az, azx, azy, baz, bazx, bazy,idchannel) -> Station
```
"""
function Station(network::AbstractString, station::AbstractString, lat::Real,
    lon::Real, el::Real; dist::Real=0.0,
    az::Real=361.0, azx::Real=0.0, azy::Real=0.0,
    baz::Real=0.0, bazx::Real=0.0, bazy::Real=0.0,
    idchannel::AbstractVector{<:Integer}=Int[])
    return Station(String(network), String(station), Float64(lat), Float64(lon),
        Float64(el), Float64(dist), Float64(az), Float64(azx), Float64(azy),
        Float64(baz), Float64(bazx), Float64(bazy), Int.(idchannel))
end

"""
```
mutable struct Event <: PreprocessedData
    # - event info
    origintime::DateTime
    lat::Float64
    lon::Float64
    depth::Float64
    mag::Float64
    t0::TimePeriod
end
```
"""
mutable struct Event <: PreprocessedData
    # - event info
    origintime::DateTime
    lat::Float64
    lon::Float64
    depth::Float64
    mag::Float64
    t0::TimePeriod
    tag::String
end

"""
```
Event(orgintime::DateTime, lat, lon, depth, mag, t0) -> Event
```
"""
function Event(origintime::DateTime, lat::Real, lon::Real, depth::Real, mag::Real,
    t0::Union{TimePeriod,Real}; tag::AbstractString="")
    if typeof(t0) <: Real
        t0 = _Second(t0)
    end
    if isempty(tag)
        tag = @sprintf("%04d%02d%02d%02d%02d", (origintime .|> [year, month, day, hour, minute])...)
    end
    return Event(origintime, Float64(lat), Float64(lon), Float64(depth), Float64(mag), t0, String(tag))
end

"""
```
mutable struct InverseSetting <: Any
    event::Event
    stations::Vector{Station}
    channels::Vector{RecordChannel}
    phases::Vector{Phase}
end
```
"""
mutable struct InverseSetting <: Any
    event::Event
    stations::Vector{Station}
    channels::Vector{RecordChannel}
    phases::Vector{Phase}
    objects::Vector{PreprocessedData}
end
