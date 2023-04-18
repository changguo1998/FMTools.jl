function update_stationcoor!(data::PreInverse)
    for s = data.stations
        (dist, az, _) = SGD.distance(data.event.lat, data.event.lon, s.lat, s.lon)
        (_, baz, _) = SGD.distance(s.lat, s.lon, data.event.lat, data.event.lon)
        s.dist = dist
        s.az = az
        s.azx = dist * cosd(az)
        s.azy = dist * sind(az)
        s.baz = baz
        s.bazx = dist * cosd(baz)
        s.bazy = dist * sind(baz)
    end
    return nothing
end
