module JSM2

using Dates, DelimitedFiles, LinearAlgebra, Printf, SeisTools, Statistics, TOML

SSAC = SeisTools.SAC
SDP = SeisTools.DataProcess
SSR = SeisTools.Source
SGD = SeisTools.Geodesy

include("macros.jl")
include("types.jl")
include("basicfunction.jl")
include("phasereport.jl")
include("io.jl")
include("calc.jl")

end # module
