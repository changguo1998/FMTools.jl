abstract type InfoReport end

const _phasereport_REF_EVENT = [(1, 2, 's'), (4, 24, 'd'), (26, 33, 'f'), 
    (34, 42, 'f'), (43, 46, 'f'), (47, 51, 'f'), (52, 56, 'i'), (57, 60, 'i'),
    (62, 63, 's'), (64, 66, 'i'), (67, 0, 's')]
const _phasereport_REF_PHASE = [(1, 2, 's'), (4, 8, 's'), (10, 12, 's'), 
    (14, 14, 'c'), (16, 16, 'c'), (18, 24, 's'), (26, 28, 'f'), (30, 30, 'c'), 
    (33, 43, 't'), (45, 51, 'f'), (53, 58, 'f'), (59, 63, 'f'), (64, 73, 'f'),
    (74, 80, 'f'), (82, 83, 's'), (84, 0, 'f')]
const _phasereport_RERANGE_EVENT = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]
const _phasereport_RERANGE_PHASE = [1, 2, 3, 6, 9, 5, 15, 16, 4, 8, 7, 10, 11,
    12, 13, 14]

struct PhaseReport <: InfoReport
    network::String
    station::String
    channel::String
    type::String
    time::Time
    polarity::Char
    magtype::String
    mag::Float64
    code1::Char
    code2::Char
    value1::Float64
    value2::Float64
    value3::Float64
    value4::Float64
    value5::Float64
    value6::Float64
end

function PhaseReport(network::String, station::String, channel::String, 
    type::String, time::Time;polarity::Char='\0', mtype::String="",
    mag::Float64=NaN, code1::Char='\0', code2::Char='\0', v1::Float64=NaN,
    v2::Float64=NaN, v3::Float64=NaN, v4::Float64=NaN, v5::Float64=NaN,
    v6::Float64=NaN)
    return PhaseReport(network, station, channel, type, time, polarity, mtype,
        mag, code1, code2, v1, v2, v3, v4, v5, v6)
end

function _phasereport_equal_must(x, y)
    return x === y
end

function _phasereport_equal_default(x, y, d)
    return (x === y) || (x === d) || (y === d)
end

function _phasereport_isless(a::PhaseReport, b::PhaseReport)
    if a.network < b.network
        return true
    elseif a.network > b.network
        return false
    else
        if a.station < b.station
            return true
        elseif a.station > b.station
            return false
        else
            if a.channel < b.channel
                return true
            elseif a.channel > b.channel
                return false
            else
                if a.type < b.type
                    return true
                elseif a.type > b.type
                    return false
                else
                    if a.time < b.time
                        return true
                    else
                        return false
                    end
                end
            end
        end
    end
end

function _phasereport_isequal(a::PhaseReport, b::PhaseReport)
    f = true
    for fld in (:network, :station, :channel, :type, :time)
        f &= _phasereport_equal_must(getfield(a, fld), getfield(b, fld))
    end
    for fld in (:code1, :polarity, :code2)
        f &= _phasereport_equal_default(getfield(a, fld), getfield(b, fld), '\0')
    end
    for fld in (:value1, :value2, :value3, :value4, :value5, :value6, :mag)
        f &= _phasereport_equal_default(getfield(a, fld), getfield(b, fld), NaN)
    end
    for fld in (:magtype,)
        f &= _phasereport_equal_default(getfield(a, fld), getfield(b, fld), "")
    end
    return f
end

function _phasereport_select_default(x, y, d)
    if !(x === d)
        return x
    elseif !(y === d)
        return y
    else
        return d
    end
end

function phasereport_mergephase(a::PhaseReport, b::PhaseReport)
    if !_phasereport_isequal(a, b)
        error("phase a and phase b not equal")
    end
    network = a.network
    station = a.station
    channel = a.channel
    type = a.type
    time = a.time
    polarity = _phasereport_select_default(a.polarity, b.polarity, '\0')
    mtype = _phasereport_select_default(a.magtype, b.magtype, "")
    mag = _phasereport_select_default(a.mag, b.mag, NaN)
    code1 = _phasereport_select_default(a.code1, b.code1, '\0')
    code2 = _phasereport_select_default(a.code2, b.code2, '\0')
    v1 = _phasereport_select_default(a.value1, b.value1, NaN)
    v2 = _phasereport_select_default(a.value2, b.value2, NaN)
    v3 = _phasereport_select_default(a.value3, b.value3, NaN)
    v4 = _phasereport_select_default(a.value4, b.value4, NaN)
    v5 = _phasereport_select_default(a.value5, b.value5, NaN)
    v6 = _phasereport_select_default(a.value6, b.value6, NaN)
    return PhaseReport(network, station, channel, type, time, polarity, mtype, 
        mag, code1, code2, v1, v2, v3, v4, v5, v6)
end

struct EventReport <: InfoReport
    region::Tuple{String,String}
    time::DateTime
    lat::Float64
    lon::Float64
    dep::Float64
    mag::Float64
    phase::Vector{PhaseReport}
end

function EventReport(region::Tuple{<:AbstractString,<:AbstractString},
    time::DateTime, lat::Real, lon::Real, dep::Real, mag::Real,
    phase::AbstractVector{PhaseReport})
    return EventReport(String.(region), time, Float64(lat), Float64(lon), 
        Float64(dep), Float64(mag), phase)
end

function _phasereport_split_parse(l::AbstractString,
    ref::Vector{Tuple{Int,Int,Char}}, rr::Vector{Int})
    v = Vector{Any}(undef, length(ref))
    for ir in eachindex(ref)
        r = ref[ir]
        if iszero(r[2])
            b = strip(l[r[1]:end])
        else
            b = strip(l[r[1]:r[2]])
        end
        if (r[3] != 'd') && contains(b, ' ')
            error("error while parsing:\n$(l)\nsegment: $(b)")
        end
        if r[3] == 'i'
            v[ir] = isempty(b) ? NaN : parse(Int, b)
        elseif r[3] == 'f'
            v[ir] = isempty(b) ? NaN : parse(Float64, b)
        elseif r[3] == 'd'
            v[ir] = DateTime(b, dateformat"Y/m/d H:M:S.s")
        elseif r[3] == 't'
            v[ir] = Time(b, dateformat"H:M:S.s")
        elseif r[3] == 'c'
            v[ir] = isempty(b) ? '\0' : b[1]
        elseif r[3] == 's'
            v[ir] = String(b)
        end
    end
    return v[rr]
end

function EventReport(l::AbstractVector{<:AbstractString})
    (evtregionCode, evtdate, evtlat, evtlon, evtdep, evtmag, _, _, _, _, 
    evtregionName) = _phasereport_split_parse(l[1], _phasereport_REF_EVENT, 
        _phasereport_RERANGE_EVENT)

    curNetwork = ""
    curStation = ""
    phases = PhaseReport[]
    for il in eachindex(l)
        if il == 1
            continue
        end
        v = _phasereport_split_parse(l[il], _phasereport_REF_PHASE, 
            _phasereport_RERANGE_PHASE)
        if !isempty(v[1])
            curNetwork = v[1]
        end
        if !isempty(v[2])
            curStation = v[2]
        end
        v[1] = curNetwork
        v[2] = curStation
        push!(phases, PhaseReport(v...))
    end

    return EventReport((evtregionCode, evtregionName), evtdate, evtlat, evtlon,
        evtdep, evtmag, phases)
end

function phasereport_parsefile(fname::AbstractString)
    lines = readlines(fname)
    filter!(!isempty, lines)
    starts = findall(contains("eq"), lines)
    ends = [starts[2:end] .- 1; length(lines)]
    evts = Vector{EventReport}(undef, length(starts))
    for il in eachindex(starts)
        evts[il] = EventReport(lines[starts[il]:ends[il]])
    end
    return evts
end

function _phasereport_fillinfo!(b::Vector{Char}, i::Int, j::Int, info::String)
    k = min(j, i+length(info)-1)
    q = collect(info)
    for p = i:k
        b[p] = Char(q[p-i+1])
    end
    return nothing
end

function phasereport_printfile(fname::AbstractString, pr::Vector{EventReport})
    buffer = Char.(collect(" "^90))
    open(fname, "w") do io
        for e in pr
            buffer .= ' '
            _phasereport_fillinfo!(buffer, 1, 2, e.region[1])
            et = e.time
            _phasereport_fillinfo!(buffer, 4, 24, 
                @sprintf("%04d/%02d/%02d %02d:%02d:%02d.%01d", year(et),
                month(et), day(et), hour(et), minute(et), second(et), 
                round(Int, millisecond(et)/100)))
            if !isnan(e.lat)
                _phasereport_fillinfo!(buffer, 26, 32, @sprintf("%7.3f", e.lat))
            end
            if !isnan(e.lon)
                _phasereport_fillinfo!(buffer, 34, 41, @sprintf("%8.3f", e.lon))
            end
            if !isnan(e.dep)
                _phasereport_fillinfo!(buffer, 43, 45, @sprintf("%3d", round(Int, e.dep)))
            end
            if !isnan(e.mag)
                _phasereport_fillinfo!(buffer, 47, 50, @sprintf("%4.1f", e.mag))
            end
            _phasereport_fillinfo!(buffer, 62, 63, "eq")
            _phasereport_fillinfo!(buffer, 68, 89, e.region[2])
            buffer[90] = '\n'
            print(io, String(buffer))
            cp = [""]
            for p in sort(e.phase, lt=_phasereport_isless)
                buffer .= ' '
                tag = p.network*"."*p.station
                if tag != cp[1]
                    cp[1] = tag
                    _phasereport_fillinfo!(buffer, 1, 2, p.network)
                    _phasereport_fillinfo!(buffer, 4, 8, p.station)
                end
                _phasereport_fillinfo!(buffer, 10, 12, p.channel)
                if p.code1 != '\0'
                    buffer[14] = p.code1
                end
                if p.polarity != '\0'
                    buffer[16] = p.polarity
                end
                _phasereport_fillinfo!(buffer, 18, 24, p.type)
                _phasereport_fillinfo!(buffer, 26, 28, @sprintf("%3.1f", p.value1))
                if p.code2 != '\0'
                    buffer[30] = p.code2
                end
                _phasereport_fillinfo!(buffer, 33, 43, @sprintf("%02d:%02d:%02d.%02d", 
                    hour(p.time), minute(p.time), second(p.time),
                    round(Int, millisecond(p.time)/10)))
                if !isnan(p.value2)
                    _phasereport_fillinfo!(buffer, 45, 50, @sprintf("%6.2f", p.value2))
                end
                if !isnan(p.value3)
                    _phasereport_fillinfo!(buffer, 52, 57, @sprintf("%6.1f", p.value3))
                end
                if !isnan(p.value4)
                    _phasereport_fillinfo!(buffer, 59, 63, @sprintf("%5.1f", p.value4))
                end
                if !isnan(p.value5)
                    _phasereport_fillinfo!(buffer, 65, 73, @sprintf("%9.1f", p.value5))
                end
                if !isnan(p.value6)
                    _phasereport_fillinfo!(buffer, 75, 80, @sprintf("%6.2f", p.value6))
                end
                if !isempty(p.magtype)
                    _phasereport_fillinfo!(buffer, 82, 83, p.magtype)
                end
                if !isnan(p.mag)
                    _phasereport_fillinfo!(buffer, 85, 89, @sprintf("%5.1f", p.mag))
                end
                buffer[90] = '\n'
                print(io, String(buffer))
            end
        end
    end
end
