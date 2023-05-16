module JSM2

using Dates, DelimitedFiles, LinearAlgebra, Printf, SeisTools, Statistics, TOML, SHA, Mmap

SSAC = SeisTools.SAC
SDP = SeisTools.DataProcess
SSR = SeisTools.Source
SGD = SeisTools.Geodesy

# DEBUG = true

include("macros.jl")
include("sourcetimefunction.jl")
include("types.jl")
include("greenlibio.jl")
include("misfit/misfits.jl")
include("phasereport.jl")
include("io.jl")
include("calc.jl")

end # module
