# = = = = =
# = time convert
# = = = = =

function _Second(x::Real)
    return _TimePrecision(round(Int, x*_TimeSecondRatio))
end
