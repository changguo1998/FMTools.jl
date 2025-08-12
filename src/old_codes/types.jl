import Base: +, -, *, /, promote_rule

export settimeprecision!, _Second, LongAgo, Direction3D, incaz,
    setlengthprecision!, Length, Kilometer, Meter, Millimeter,
    Micrometer, _Kilometer, _Meter
# * global variable
_TimePrecision = Millisecond
_TimeSecondRatio = _TimePrecision(Second(1))/_TimePrecision(1)

function settimeprecision!(T::Type)
    @must T <: TimePeriod
    global _TimePrecision = T
    global _TimeSecondRatio = _TimePrecision(Second(1))/_TimePrecision(1)
    return nothing
end

LongAgo = DateTime(1800)

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

# = = = = = = = = = = = = = = =
# = Searching Method
# = = = = = = = = = = = = = = =
include("search/searchingMethod.jl")

# = = = = = = = = = = = = = = =
# = types of input data
# = = = = = = = = = = = = = = =
export PreprocessedData, AlgorithmSetting, DataCollection,
    Event, Station, RecordChannel, Phase, Object

abstract type PreprocessedData <: Any end

abstract type Object <: PreprocessedData end

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
    idobject::Vector{Int}
    idchannel::Int
end

"""
```
Phase(ptype, at, tt; idobject, idchannel, idstation) -> Phase
```

construct Phase type
- ptype AbstractString
- at DateTime
- tt TimePeriod or Real. when tt is Real, it will be treated as second
"""
function Phase(ptype::AbstractString, at::DateTime=LongAgo, tt::Union{TimePeriod,Real}=_TimePrecision(0);
    idobject::AbstractVector{<:Integer}=Int[], idchannel::Integer=0)
    if typeof(tt) <: Real
        tt = _Second(tt)
    end
    return Phase(String(ptype), at, tt, Int.(idobject), Int(idchannel))
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
    glibpath, tlibpath, gdt, greenfun, idphase, idstation) -> RecordChannel
```
"""
function RecordChannel(dircname::Union{AbstractString,AbstractChar},
    filepath::AbstractString;
    direction::Union{Direction3D,Nothing}=nothing,
    rbt::DateTime=LongAgo, ret::DateTime=LongAgo,
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
    if typeof(gdt) <: Real
        gdt = _Second(gdt)
    end
    return RecordChannel(String(dircname), String(filepath), direction,
        rbt, ret, rdt, Float64.(record), String(glibmodel),
        String(glibpath), String(tlibpath), gdt, Float64.(greenfun),
        Int.(idphase), Int(idstation))
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
    objects::Vector{Object}
end

struct AlgorithmSetting <: PreprocessedData
    greenbuffer::Bool
end

function AlgorithmSetting(; greenbuffer::Bool=true)
    return AlgorithmSetting(greenbuffer)
end

include("misfit/misfits.jl")


# = = = = = = = = = = = = =
# = = = = = = = = = = = = =
# = = = = = = = = = = = = =
# = = = = = = = = = = = = =

export pushphase!, selectdatacollection

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

_typelist = (:Station, :RecordChannel, :Phase, :Object)
_fldnames = (:idstation, :idchannel, :idphase, :idobject)
for _i = eachindex(_typelist)
    if _i == 1
        continue
    end
    @eval function _downward_relation!(f2::AbstractVector{Bool},
        dat::Vector{$(_typelist[_i-1])}, f1::AbstractVector{Bool})
        for i = eachindex(dat)
            if f1[i]
                for j = getfield(dat[i], _fldnames[$(_i)])
                    f2[j] = true
                end
            end
        end
        return nothing
    end
end

for _i = eachindex(_typelist)
    if _i == 1
        continue
    end
    @eval function _upward_relation!(f2::AbstractVector{Bool},
        dat::Vector{$(_typelist[_i])}, f1::AbstractVector{Bool})
        for i = eachindex(dat)
            if f1[i]
                j = getfield(dat[i], _fldnames[$(_i-1)])
                f2[j] = true
            end
        end
        return nothing
    end
end

function _new_id(fv::AbstractVector{Bool})
    id = zeros(Int, length(fv))
    n = 1
    for i = eachindex(fv)
        if fv[i]
            id[i] = n
            n += 1
        end
    end
    return id
end

function selectdatacollection(stations::Vector{Station}, fsta::AbstractVector{Bool},
    channels::Vector{RecordChannel}, fcha::AbstractVector{Bool},
    phases::Vector{Phase}, fpha::AbstractVector{Bool},
    objects::Vector{Object}, fobj::AbstractVector{Bool})
    new_staid = _new_id(fsta)
    new_chaid = _new_id(fcha)
    new_phaid = _new_id(fpha)
    new_objid = _new_id(fobj)
    new_stations = Vector{Station}(undef, count(>(0), fsta))
    new_channels = Vector{RecordChannel}(undef, count(>(0), fcha))
    new_phases = Vector{Phase}(undef, count(>(0), fpha))
    new_objects = Vector{Object}(undef, count(>(0), fobj))
    for i = eachindex(fsta)
        if fsta[i]
            tsta = deepcopy(stations[i])
            tsta.idchannel = Int[]
            for j = stations[i].idchannel
                if new_chaid[j] > 0
                    push!(tsta.idchannel, new_chaid[j])
                end
            end
            new_stations[new_staid[i]] = tsta
        end
    end
    for i = eachindex(fcha)
        if fcha[i]
            tcha = deepcopy(channels[i])
            tcha.idstation = new_staid[channels[i].idstation]
            tcha.idphase = Int[]
            for j = channels[i].idphase
                if new_phaid[j] > 0
                    push!(tcha.idphase, new_phaid[j])
                end
            end
            new_channels[new_chaid[i]] = tcha
        end
    end
    for i = eachindex(fpha)
        if fpha[i]
            tpha = deepcopy(phases[i])
            tpha.idchannel = new_chaid[phases[i].idchannel]
            tpha.idobject = Int[]
            for j = phases[i].idobject
                if new_objid[j] > 0
                    push!(tcha.idphase, new_objid[j])
                end
            end
            new_phases[new_phaid[i]] = tpha
        end
    end
    for i = eachindex(fobj)
        if fobj[i]
            tobj = deepcopy(objects[i])
            tobj.idphase = new_phaid[objects[i].idphase]
            new_objects[new_objid[i]] = tobj
        end
    end
    return (new_stations, new_channels, new_phases, new_objects)
end
