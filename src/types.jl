import Base: +, -, *, /, promote_rule

export settimeprecision!, _Second, setlengthprecision!, Direction3D, incaz, 
    Length, Kilometer, Meter, Millimeter, Micrometer, _Kilometer, _Meter
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

_Second(x::Real) = _TimePrecision(round(Int, x * _TimeSecondRatio))

# = = = = = = = = = = = = = = =
# = basic types
# = = = = = = = = = = = = = = =

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

abstract type Length <: Any end

_LENGTH_TYPE_LIST = (:Kilometer, :Meter, :Decimeter, :Centimeter, :Millimeter, :Micrometer, :Nanometer) 

for sym in _LENGTH_TYPE_LIST
    @eval struct $sym <: Length
        value::Int
    end
    @eval begin
        +(a::$sym, b::$sym) = $sym(a.value + b.value)
        -(a::$sym, b::$sym) = $sym(a.value - b.value)
        *(a::$sym, b::Integer) = $sym(a.value * b)
        *(a::Integer, b::$sym) = $sym(b.value * a)
        /(a::$sym, b::$sym) = a.value / b.value
    end
end

_LENGTH_UNIT_POWER = (3, 0, -1, -2, -3, -6, -9)

for i = eachindex(_LENGTH_TYPE_LIST), j = eachindex(_LENGTH_TYPE_LIST)
    if j >= i
        continue
    end
    @eval begin
        promote_rule(::Type{$(_LENGTH_TYPE_LIST[i])}, ::Type{$(_LENGTH_TYPE_LIST[j])}) = $(_LENGTH_TYPE_LIST[i])
        promote_rule(::Type{$(_LENGTH_TYPE_LIST[j])}, ::Type{$(_LENGTH_TYPE_LIST[i])}) = $(_LENGTH_TYPE_LIST[i])
        $(_LENGTH_TYPE_LIST[i])(t::$(_LENGTH_TYPE_LIST[j])) = 
            $(_LENGTH_TYPE_LIST[i])(t.value*10^($(_LENGTH_UNIT_POWER[j]-_LENGTH_UNIT_POWER[i])))
    end
end

_LengthPrecision = Millimeter
_LengthKilometerRatio = _LengthPrecision(Kilometer(1))/_LengthPrecision(1)
_LengthMeterRatio = _LengthPrecision(Meter(1))/_LengthPrecision(1)

function setlengthprecision!(T::Type)
    @must T <: Length
    global _LengthPrecision = T
    global _LengthKilometerRatio = _LengthPrecision(Kilometer(1))/_LengthPrecision(1)
    global _LengthMeterRatio = _LengthPrecision(Meter(1))/_LengthPrecision(1)
    return nothing
end

_Kilometer(x::Real) = _LengthPrecision(round(Int, x * _LengthKilometerRatio))

_Meter(x::Real) = _LengthPrecision(round(Int, x * _LengthMeterRatio))

# = = = = = = = = = = = = = = =
# = Searching Method
# = = = = = = = = = = = = = = =
include("search/searchingMethod.jl")

# = = = = = = = = = = = = = = =
# = types of input data
# = = = = = = = = = = = = = = =
export PreprocessedData, AlgorithmSetting, DataCollection,
    Event, Station, RecordChannel, Phase

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
function Phase(ptype::AbstractString, at::DateTime=_LongAgo, tt::Union{TimePeriod,Real}=_TimePrecision(0);
    idobjects::AbstractVector{<:Integer}=Int[], idchannel::Integer=0)
    if typeof(tt) <: Real
        tt = _Second(tt)
    end
    return Phase(String(ptype), at, tt, Int.(idobjects), Int(idchannel))
end

"""
```
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
    gdt::TimePeriod
    greenfun::Matrix{Float64}
    # - cross ref
    idphase::Vector{Int}
    idstation::Int
end

"""
```
RecordChannel(dircname, filepath; direction, rbt, ret, rdt, record, glibmodel, 
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
    el::Length
    # - auxiliary info
    dist::Length
    az::Float64
    azx::Length
    azy::Length
    baz::Float64
    bazx::Length
    bazy::Length
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
    el::Length
    # - auxiliary info
    dist::Length
    az::Float64
    azx::Length
    azy::Length
    baz::Float64
    bazx::Length
    bazy::Length
    # - cross ref
    idchannel::Vector{Int}
end

"""
```
Station(network, station, lat, lon, el;
    dist, az, azx, azy, baz, bazx, bazy, idchannel) -> Station
```
"""
function Station(network::AbstractString, station::AbstractString, lat::Real,
    lon::Real, el::Real; dist::Real=0.0,
    az::Real=361.0, azx::Real=0.0, azy::Real=0.0,
    baz::Real=0.0, bazx::Real=0.0, bazy::Real=0.0,
    idchannel::AbstractVector{<:Integer}=Int[])
    return Station(String(network), String(station), Float64(lat), Float64(lon),
        _Meter(el), _Kilometer(dist), Float64(az), _Kilometer(azx), _Kilometer(azy),
        Float64(baz), _Kilometer(bazx), _Kilometer(bazy), Int.(idchannel))
end

"""
```
mutable struct Event <: PreprocessedData
    # - event info
    time::DateTime
    lat::Float64
    lon::Float64
    dep::Length
    mag::Float64
    stf::SourceTimeFunction
    tag::String
end
```
"""
mutable struct Event <: PreprocessedData
    # - event info
    time::DateTime
    lat::Float64
    lon::Float64
    dep::Length
    mag::Float64
    stf::SourceTimeFunction
    tag::String
end

"""
```
Event(time::DateTime, lat, lon, dep, mag, stf, tag) -> Event
```
"""
function Event(time::DateTime, lat::Real, lon::Real, dep::Union{Real,Length}; mag::Real=0.0,
    stf::Union{SourceTimeFunction,Real}=0.0, tag::AbstractString="")
    if typeof(stf) <: Real
        stf = DSmoothRampSTF(stf, 3*stf)
    end
    if typeof(dep) <: Real
        dep = _Kilometer(dep)
    end
    if isempty(tag)
        tag = @sprintf("%04d%02d%02d%02d%02d", (time .|> [year, month, day, hour, minute])...)
    end
    return Event(time, Float64(lat), Float64(lon), dep, Float64(mag), stf, String(tag))
end

mutable struct DataCollection <: PreprocessedData
    event::Event
    stations::Vector{Station}
    channels::Vector{RecordChannel}
    phases::Vector{Phase}
    objects::Vector{PreprocessedData}
end

struct AlgorithmSetting <: PreprocessedData
    greenbuffer::Bool
end

function AlgorithmSetting(; greenbuffer::Bool=true)
    return AlgorithmSetting(greenbuffer)
end


# = = = = = = = = = = = = =
# = = = = = = = = = = = = =
# = = = = = = = = = = = = =
# = = = = = = = = = = = = =

"""
```
pushphase!(channels, ichannel, phases, ptype)
```
"""
function pushphase!(channels::Vector{RecordChannel}, ichannel::Integer,
    phases::Vector{Phase}, ptype::AbstractString)
    iphase = length(phases) + 1
    c = channels[ichannel]
    push!(c.idphase, iphase)
    push!(phases, Phase(ptype; idchannel=ichannel))
    return nothing
end


"""
```
selectphase!(channels, phases, selectflag::Vector{Bool}) -> newphases
```

select `phases` and update id in `channels` according to `selectflag`
"""
function selectphase!(channels::Vector{RecordChannel}, phases::Vector{Phase},
    selectflag::Vector{Bool})
    @must length(phases) == length(selectflag)
    newphases = phases[selectflag]
    idtable_old2new = zeros(Int, length(phases))
    for i = eachindex(phases), j = eachindex(newphases)
        if phases[i] == newphases[j]
            idtable_old2new[i] = j
        end
    end
    for c = channels
        c.idphase = idtable_old2new[c.idphase]
        deleteat!(c.idphase, iszero.(c.idphase))
    end
    return newphases
end

"""
```
selectphase!(f, channels, phases) -> newphases
```

select `phases` and update id in `channels` according to function `f`,
function `f` take `Phase` as input and return `Bool` type
"""
function selectphase!(f::Function, channels::Vector{RecordChannel},
    phases::Vector{Phase})
    flag = map(f, phases)
    return selectphase!(channels, phases, flag)
end
