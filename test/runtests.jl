using JSM2, Test, SeisTools

@testset "Source Time Function" begin
    s = JSM2.GaussSTF(1.0, 0.0)
    @test s.([0.0, 1.0, 2.0]) == exp.(-[0.0, 1.0, 2.0].^2)
    s = JSM2.SmoothRampSTF(1.0, 0.0)
    @test s.([0.0, 1.0, 2.0]) == (1 .+ tanh.([0.0, 1.0, 2.0])) .* 0.5
    s = JSM2.DSmoothRampSTF(1.0, 0.0)
    @test s.([0.0, 1.0, 2.0]) == @. 1 / cosh([0.0, 1.0, 2.0])^2
    w = sind.((0.0:0.1:2.0).*360.0)
    s = JSM2.ExtraSTF(0.1, w)
    @test s.([0.0, 0.5, 1.0, 2.0]) == @. sind([0.0, 0.5, 1.0, 2.0]*360.0)
end