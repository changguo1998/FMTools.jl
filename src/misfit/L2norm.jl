export L2norm_misfit

mutable struct L2norm_misfit <: Object
    idphase::Int
    dt::_TimePrecision
    maxlag::_TimePrecision
    bpfilter::Vector{Float64}
    rbt::DateTime
    ret::DateTime
    # = = = = = =
    rec::Vector{Float64}
    greenAmp::Matrix{Float64}
    gxcorr::Matrix{Float64}
end

function L2norm_misfit(idphase::Integer,
    dt::Union{Real,TimePeriod}=_TimePrecision(0),
    maxlag::Union{Real,TimePeriod}=_TimePrecision(0),
    filter::Vector{<:Real}=zeros(2),
    rbt::DateTime=_LongAgo, ret::DateTime=_LongAgo,
    rec::Vector{<:Real}=zeros(0),
    greenAmp::Matrix{<:Real}=zeros(0,0),
    gxcorr::Matrix{<:Real}=zeros(0,0))
    if typeof(dt) <: Real
        _dt = _Second(dt)
    else
        _dt = _TimePrecision(dt)
    end
    if typeof(maxlag) <: Real
        _maxlag = _Second(maxlag)
    else
        _maxlag = _TimePrecision(dt)
    end
    return L2norm_misfit(Int(idphase), _dt, _maxlag, Float64.(filter),
        rbt, ret, Float64.(rec), Float64.(greenAmp), Float64.(gxcorr))
end

function preprocess!(o::L2norm_misfit, event::Event,
    stations::Vector{Station},
    channels::Vector{RecordChannel},
    phases::Vector{Phase})
    # * get ids
    ip = o.idphase
    p = phases[ip]
    ic = p.idchannel
    c = channels[ic]
    is = c.idstation
    s = stations[is]
    # * cut record
    wr1 = deepcopy(c.record)
    SDP.detrend!(wr1)
    SDP.taper!(wr1)
    wr2 = SDP.bandpass(wr1, o.bpfilter[1], o.bpfilter[2], _TimeSecondRatio/c.rdt.value)
    wr3 = zeros(round(Int, length(wr2) * (c.rdt / o.dt)))
    SDP.resample!(wr3, wr2)
    (_, wr4, _) = SDP.cut(wr3, c.rbt, o.rbt, o.ret, o.dt)
    # * cut green
    wg1 = deepcopy(c.greenfun)
    SDP.detrend!(wg1)
    SDP.taper!(wg1)
    wg2 = SDP.bandpass(wg1, o.bpfilter[1], o.bpfilter[2], _TimeSecondRatio/c.gdt.value)
    wg3 = zeros(round(Int, size(wg2, 1) * (c.gdt / o.dt)))
    SDP.resample!(wg3, wg2)
    (_, wg4, _) = SDP.cut(wg2, c.rbt, o.rbt, o.ret, o.dt)
end
