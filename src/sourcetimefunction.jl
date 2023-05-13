abstract type SourceTimeFunction <: Any end

# = = = = = = = = = = =
mutable struct GaussSTF <: SourceTimeFunction
    t0::Float64
    tshift::Float64
end

GaussSTF(t0::Real, tshift::Real) = GaussSTF(Float64(t0), Float64(tshift))

(stf::GaussSTF)(t::Real) = exp(-( (t - stf.tshift) / stf.t0)^2)


# = = = = = = = = = = =
mutable struct SmoothRampSTF <: SourceTimeFunction
    t0::Float64
    tshift::Float64
end

SmoothRampSTF(t0::Real, tshift::Real=-3*t0) = SmoothRampSTF(Float64(t0), Float64(tshift))

(stf::SmoothRampSTF)(t::Real) = (1 + tanh( (t - stf.tshift) / stf.t0)) * 0.5

# = = = = = = = = = = =
mutable struct DSmoothRampSTF <: SourceTimeFunction
    t0::Float64
    tshift::Float64
end

DSmoothRampSTF(t0::Real, tshift::Real=-3*t0) = SmoothRampSTF(Float64(t0), Float64(tshift))

(stf::DSmoothRampSTF)(t::Real) = 1 / cosh((t - stf.tshift) / stf.t0)^2

# = = = = = = = = = = =
mutable struct ExtraSTF <: SourceTimeFunction
    dt::Float64
    sample::Vector{Float64}
    splineCoef::Matrix{Float64}
end

function ExtraSTF(dt::Real, sample::AbstractVector{<:Real})
    N = length(sample)-1
    M = zeros(4*N, 4*N)
    b = zeros(4*N)
    x = (eachindex(sample).-1)./N
    for i = 1:N
        r = i*4-4
        s = mod(i, N)*4
        for j = 1:4
            M[r+1, r+j] = (j > 1) ? x[i]^(j-1) : 1.0
            M[r+2, r+j] = (j > 1) ? x[i+1]^(j-1) : 1.0
            if j > 2
                M[r+3, r+j] =  (j-1)*x[i+1]^(j-2)
                M[r+3, s+j] = -(j-1)*x[i+1]^(j-2)
            elseif j == 2
                M[r+3, r+j] =  1.0
                M[r+3, s+j] = -1.0
            end
            if j > 3
                M[r+4, r+j] =  6*x[i+1]
                M[r+4, s+j] = -6*x[i+1]
            elseif j == 3
                M[r+4, r+j] =  2.0
                M[r+4, s+j] = -2.0
            end
        end
        b[r+1] = sample[i]
        b[r+2] = sample[i+1]
        b[r+3] = 0.0
        b[r+4] = 0.0
    end
    for j = 1:4
        if j > 2
            M[end-1, j] = -(j-1)*x[1]^(j-2)
        elseif j == 2
            M[end-1, j] = -1.0
        end
        if j > 3
            M[end, j] = -6*x[1]
        elseif j == 3
            M[end, j] = -2.0
        end
    end
    a = M\b
    mat = reshape(a, 4, N)
    return ExtraSTF(Float64(dt), Float64.(sample), mat)
end

function (stf::ExtraSTF)(t::Real)
    nf = t/stf.dt
    x = nf / size(stf.splineCoef, 2)
    n = floor(Int, nf) + 1
    if n > size(stf.splineCoef, 2) || n < 1
        return 0.0
    end
    v = stf.splineCoef[4, n]
    for i = 1:3
        v *= x
        v += stf.splineCoef[4-i, n]
    end
    return v
end
