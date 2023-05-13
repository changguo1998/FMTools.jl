abstract type SearchingMethod <: Any end

for f in readlines(joinpath(@__DIR__, "methodlist.txt"))
    include(f*".jl")
end
