export Object

abstract type Object <: PreprocessedData end

for f in readlines(joinpath(@__DIR__, "methodlist.txt"))
    include(joinpath(@__DIR__, f*".jl"))
end