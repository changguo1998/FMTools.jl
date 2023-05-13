mutable struct L2norm_misfit <: PreprocessedData
    dt::_TimePrecision
    maxlag::_TimePrecision
    rec::Vector{Float64}
    bpfilter::Tuple{Float64,Float64}
    greenAmp::Matrix{Float64}
    gxcorr::Matrix{Float64}

end