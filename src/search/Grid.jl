
function _m_range(start::Real, step::Real, stop::Real)
    n = ceil(Int, abs((stop-start)/step)) + 1
    v = zeros(n)
    for i = 1:n-1
        v[i] = start + (i-1)*step
    end
    v[n] = stop
    return v
end

struct Gridsearch <: SearchingMethod
    strikestart::Float64
    strikestep::Float64
    strikestop::Float64
    dipstart::Float64
    dipstep::Float64
    dipstop::Float64
    rakestart::Float64
    rakestep::Float64
    rakestop::Float64
end

"""
```
Gridsearch(strikestart=0, strikestep=5,strikestop=355,
    dipstart=0, dipstep=5, dipstop=90,
    rakestart=-90, rakestep=5, rakestop=90) -> Gridsearch
```
"""
function Gridsearch(strikestart::Real=0, strikestep::Real=5,
    strikestop::Real=355,
    dipstart::Real=0, dipstep::Real=5, dipstop::Real=90,
    rakestart::Real=-90, rakestep::Real=5, rakestop::Real=90)
    return Gridsearch(Float64(strikestart), Float64(strikestep),
        Float64(strikestop),
        Float64(dipstart), Float64(dipstep), Float64(dipstop),
        Float64(rakestart), Float64(rakestep), Float64(rakestop))
end

"""
```
(s::Gridsearch)() -> (sdr::Matrix(3, n), isend::Bool)
```

return sampling point of searching grid
"""
function (s::Gridsearch)()
    vstrike = _m_range(s.strikestart, s.strikestep, s.strikestop)
    vdip = _m_range(s.dipstart, s.dipstep, s.dipstop)
    vrake = _m_range(s.rakestart, s.rakestep, s.rakestop)
    vstrike = unique(mod.(vstrike, 360.0))
    sdr = zeros(3, length(vstrike)*length(vdip)*length(vrake))
    idx = LinearIndices((length(vstrike), length(vdip), length(vrake)))
    for is = eachindex(vstrike), id = eachindex(vdip), ir = eachindex(vrake)
        sdr[1, idx[is, id, ir]] = vstrike[is]
        sdr[2, idx[is, id, ir]] = vstrike[id]
        sdr[3, idx[is, id, ir]] = vstrike[ir]
    end
    return (sdr, true)
end

mutable struct VSGrid <: SearchingMethod
    overlapratio::Vector{Float64}
    steps::Matrix{Float64}
    ilevel::Int
end

function VSGrid(nlevel::Int, overlapratio::AbstractVector{<:Real}, finalstep::AbstractVector{<:Real})
    @must length(finalstep) == 3
    @must nlevel > 0
    nsample = ceil.([360.0, 90.0, 180.0]./finalstep).+1
    q = (nsample ./ 2 ./ overlapratio).^(1/nlevel)
    
    m = zeros(nlevel, 3)
    for i = 1:nlevel, j = 1:3
        m[i, j] = round(Int, q[j]^(nlevel-i))*finalstep[j]
    end
    return VSGrid(overlapratio, m, 1)
end

VSGrid(nlevel::Int, oratio::Real, finalstep::AbstractVector{<:Real}=ones(3)) = 
    VSGrid(nlevel, ones(3).*oratio, finalstep)

function reset_level!(g::VSGrid)
    g.ilevel = 1
    return nothing
end

function (g::VSGrid)(strike::Real=0, dip::Real=0, rake::Real=0)
    if g.ilevel == 1
        _g = Gridsearch(0.0, g.steps[1, 1], 360.0, 0.0, g.steps[1, 2], 90.0,
            -90.0, g.steps[1, 3], 90.0)
    elseif g.ilevel > size(g.steps, 1)
        return zeros(3, 0)
    else
        _g = Gridsearch(strike - g.steps[g.ilevel-1, 1] * g.overlapratio[1],
            g.steps[g.ilevel, 1],
            strike + g.steps[g.ilevel-1, 1] * g.overlapratio[1],
            dip - g.steps[g.ilevel-1, 2] * g.overlapratio[2],
            g.steps[g.ilevel, 2],
            dip + g.steps[g.ilevel-1, 2] * g.overlapratio[2],
            rake - g.steps[g.ilevel-1, 3] * g.overlapratio[3],
            g.steps[g.ilevel, 3],
            rake + g.steps[g.ilevel-1, 3] * g.overlapratio[3])
    end
    g.ilevel += 1
    return (_g()[1], g.ilevel-1 == size(g.steps, 1))
end