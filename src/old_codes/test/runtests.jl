using FMTools, Test, SeisTools

@testset "Source Time Function" begin
    s = GaussSTF(1.0, 0.0)
    @test s.([0.0, 1.0, 2.0]) == exp.(-[0.0, 1.0, 2.0].^2)
    s = SmoothRampSTF(1.0, 0.0)
    @test s.([0.0, 1.0, 2.0]) == (1 .+ tanh.([0.0, 1.0, 2.0])) .* 0.5
    s = DSmoothRampSTF(1.0, 0.0)
    @test s.([0.0, 1.0, 2.0]) == @. 1 / cosh([0.0, 1.0, 2.0])^2
    w = sind.((0.0:0.1:2.0).*360.0)
    s = ExtraSTF(0.1, w)
    @test s.([0.0, 0.5, 1.0, 2.0]) == @. sind([0.0, 0.5, 1.0, 2.0]*360.0)
end