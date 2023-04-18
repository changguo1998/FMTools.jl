# = = = = = = = = = =
# = Record IO
# = = = = = = = = = =

function Event(filepath::AbstractString)
    t = TOML.parsefile(filepath)
    if "tag" in keys(t)
        return Event(t["origintime"], t["lat"], t["lon"], t["depth"], t["mag"], t["t0"]; tag=t["tag"])
    else
        return Event(t["origintime"], t["lat"], t["lon"], t["depth"], t["mag"], t["t0"])
    end
end

_findfirst_station(stag::String, lst::Vector{String}) = findfirst(==(stag), lst)

function readStationChannelInfo(datadir::AbstractString)
    fs = filter(endswith("SAC"), readdir(datadir))
    stationtags = String[]
    stations = Station[]
    channels = RecordChannel[]
    current_station = 0
    current_channel = 0
    for f in fs
        fp = joinpath(datadir, f)
        shdr = open(SSAC.readhead, fp)
        stag = shdr["knetwk"] * "." * shdr["kstnm"]
        sid = _findfirst_station(stag, stationtags)
        if isnothing(sid)
            push!(stationtags, stag)
            push!(stations, Station(shdr["knetwk"], shdr["kstnm"], 
                shdr["stla"], shdr["stlo"], shdr["stel"]))
            current_station += 1
            sid = current_station
        end
        push!(channels, RecordChannel(shdr["kcmpnm"][end], fp; idstation=sid,
            direction=Direction3D(shdr["cmpinc"], shdr["cmpaz"])))
        current_channel += 1
        push!(stations[sid].idchannel, current_channel)
    end
    return (stations, channels)
end

function _read_channel_record!(c::RecordChannel)
    sf = SSAC.read(c.filepath)
    rt = SSAC.DateTime(sf.hdr)
    bt = rt + _Second(sf.hdr["b"])
    if c.rbt == _LongAgo
        c.rbt = bt
    end
    if c.ret == _LongAgo
        c.ret = bt + _Second(sf.hdr["delta"]*sf.hdr["npts"])
    end
    c.rdt = _Second(sf.hdr["delta"])
    (_, w, _) = SDP.cut(sf.data, bt, c.rbt, c.ret, c.rdt)
    c.record = deepcopy(w)
    return nothing
end

readChannelRecords!(channels::Vector{RecordChannel}) =
    foreach(_read_channel_record!, channels)


# = = = = = = = = = =
# = Green IO
# = = = = = = = = = =
