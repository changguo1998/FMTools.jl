# = = = = =
# = time convert
# = = = = =

_Second(x::Real) = _TimePrecision(round(Int, x * _TimeSecondRatio))

_Kilometer(x::Real) = _LengthPrecision(round(Int, x * _LengthKilometerRatio))

_Meter(x::Real) = _LengthPrecision(round(Int, x * _LengthMeterRatio))
