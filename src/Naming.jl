module Naming

using Dates, SHA

# station name

export string2ns, string2nsc

function _segment_string_tag(s::String, delim::Union{Char,String}, seg_name::Vector{Symbol})
    bufi = split(s, delim; keepempty=true)
    bufo = repeat([""], length(seg_name))
    for i = 1:min(length(bufi), length(bufo))
        bufo[i] = String(bufi[i])
    end
    return NamedTuple{Tuple(seg_name)}(Tuple(bufo))
end

"""
```
string2ns(str) -> (network="", station="")
```
"""
function string2ns(s::AbstractString, delim::Union{Char, String} = ".")
    return _segment_string_tag(s, delim, [:network, :station])
end

"""
```
string2nsc(str) -> (network="", station="", component="")
```
"""
function string2nsc(s::AbstractString, delim::Union{Char, String} = ".")
    return _segment_string_tag(s, delim, [:network, :station, :component])
end

# time

const _DATE_TIME_FORMAT_LIST = ("yyyymmdd",
                                "yyyymmddHH",
                                "yyyymmddHHMM",
                                "yyyymmddHHMMSS",
                                "yyyymmddHHMMSSs",
                                "yyyymmddHHMMSSss",
                                "yyyymmddHHMMSSsss")

const _DATE_TIME_FORMAT_LIST_LEN = length.(_DATE_TIME_FORMAT_LIST)

function detect_time_format_all_digits(s::AbstractString)
    slen = length(s)
    i = findfirst(slen .== _DATE_TIME_FORMAT_LIST_LEN)
    if isnothing(i)
        error("No matching datetime format")
    else
        return _DATE_TIME_FORMAT_LIST[i]
    end
end

function string2datetime_all_digits(s::AbstractString)
    return DateTime(s, detect_time_format_all_digits(s))
end

function string2datetime_date_and_time(s::AbstractString; dd::String="-", td::String=":", ddt="T")
    t1 = split(s, [dd, td, ddt])
    y = parse(Int, t1[1])
    m = parse(Int, t1[2])
    d  = parse(Int, t1[3])
    h = parse(Int, t1[4])
    M = parse(Int, t1[5])
    if length(t1[6]) > 2
        s = Macrosecond(round(Int, parse(Float64, t[6])*1.0e6))
    else
        s = Second(parse(Int, t1[6]))
    end
    return DateTime(y, m, d, h, M) + s
end

export string2datetime

"""
```
string2datetime(str) -> DateTime
```

Auto detect date time format and convert to `DateTime` type
"""
function string2datetime(s::AbstractString)
    if all(isdigit, s)
        return string2datetime_all_digits(s)
    end
    possible_delimers = filter(!isdigit, collect(s))
    t1 = split(s, possible_delimers)
    t2 = map(t1) do seg
        if length(seg) < 2
            return "0"*seg
        else
            return seg
        end
    end
    return string2datetime_all_digits(join(t2))
end

end # Module Naming
