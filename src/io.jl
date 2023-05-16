# = = = = = = = = = =
# = Record
# = = = = = = = = = =

export readStationChannelInfo, readChannelRecords!

"""
```
Event(filepath) -> Event
```

read *TOML* format event info. Available fields are:

- time/origintime
- lon/longitude
- lat/latitude
- dep/depth(in kilometer)
- mag/magnitude
- t0/risetime(in second)
- tag String identifier
"""
function Event(filepath::AbstractString)
    t = TOML.parsefile(filepath)
    e = Event(_LongAgo, 0.0, 0.0, _LengthPrecision(0))
    ks = keys(t)
    klist = ("time", "origintime", "lat", "latitude", "lon", "longitude", 
        "dep", "depth", "mag", "magnitude", "t0", "risetime", "tag")
    flist = (:time, :time, :lat, :lat, :lon, :lon, :dep, :dep, :mag, :mag, 
        :stf, :stf, :tag)
    funcl = (identity, identity, identity, identity, identity, identity, 
        _Kilometer,  _Kilometer, identity, identity, 
        _t->DSmoothRampSTF(_t, 3*_t), _t->DSmoothRampSTF(_t, 3*_t), 
        identity)
    for i = eachindex(klist)
        if klist[i] in ks
            setfield!(e, flist[i], funcl[i](t[klist[i]]))
        end
    end
    if !("tag" in ks)
        e.tag = @sprintf("%04d%02d%02d%02d%02d", (e.time .|>
            [year, month, day, hour, minute])...)
    end
    return e
end

_findfirst_station(stag::String, lst::Vector{String}) = findfirst(==(stag), lst)

"""
```
readStationChannelInfo(datadir) -> (stations, channels)
```

read files' header of data file ends with `SAC` in `datadir`, return info vector
"""
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

"""
```
readChannelRecords!(::Vector{RecordChannel})
```

read data from file according to the info in `RecordChannel`
"""
readChannelRecords!(channels::Vector{RecordChannel}) =
    foreach(_read_channel_record!, channels)


# = = = = = = = = = =
# = Green's function
# = = = = = = = = = =
