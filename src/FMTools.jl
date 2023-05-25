module FMTools

using Dates, DelimitedFiles, LinearAlgebra, Printf, SeisTools, Statistics, TOML, SHA

SSAC = SeisTools.SAC
SDP = SeisTools.DataProcess
SSR = SeisTools.Source
SGD = SeisTools.Geodesy

# DEBUG = true

include("macros.jl")
include("sourcetimefunction.jl")
include("types.jl")
include("phasereport.jl")
include("io.jl")
include("calc.jl")

end # module
