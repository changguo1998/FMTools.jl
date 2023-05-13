function update_stationcoor!(stations::Vector{Station}, event::Event)
    for s = stations
        (dist, az, _) = SGD.distance(event.lat, event.lon, s.lat, s.lon)
        (_, baz, _) = SGD.distance(s.lat, s.lon, event.lat, event.lon)
        s.dist = _Kilometer(dist)
        s.az = az
        s.azx = _Kilometer(dist * cosd(az))
        s.azy = _Kilometer(dist * sind(az))
        s.baz = baz
        s.bazx = _Kilometer(dist * cosd(baz))
        s.bazy = _Kilometer(dist * sind(baz))
    end
    return nothing
end

update_stationcoor!(data::InverseSetting) = 
    update_stationcoor!(data.stations, data.event)
