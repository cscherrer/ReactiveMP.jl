module NormalMeanPrecisionTest

using Test
using ReactiveMP

@testset "NormalMeanPrecision" begin

    @testset "Constructor" begin
        @test NormalMeanPrecision <: NormalDistributionsFamily
        @test NormalMeanPrecision <: UnivariateNormalDistributionsFamily

        @test NormalMeanPrecision()         == NormalMeanPrecision{Float64}(0.0, 1.0)
        @test NormalMeanPrecision(1.0)      == NormalMeanPrecision{Float64}(1.0, 1.0)
        @test NormalMeanPrecision(1.0, 2.0) == NormalMeanPrecision{Float64}(1.0, 2.0)
        @test NormalMeanPrecision(1)        == NormalMeanPrecision{Float64}(1.0, 1.0)
        @test NormalMeanPrecision(1, 2)     == NormalMeanPrecision{Float64}(1.0, 2.0)
        @test NormalMeanPrecision(1.0, 2)   == NormalMeanPrecision{Float64}(1.0, 2.0)
        @test NormalMeanPrecision(1, 2.0)   == NormalMeanPrecision{Float64}(1.0, 2.0)
        @test NormalMeanPrecision(1f0)      == NormalMeanPrecision{Float32}(1f0, 1f0)
        @test NormalMeanPrecision(1f0, 2f0) == NormalMeanPrecision{Float32}(1f0, 2f0)
        @test NormalMeanPrecision(1f0, 2)   == NormalMeanPrecision{Float32}(1f0, 2f0)
        @test NormalMeanPrecision(1f0, 2.0) == NormalMeanPrecision{Float64}(1.0, 2.0)

        @test eltype(NormalMeanPrecision())         === Float64
        @test eltype(NormalMeanPrecision(0.0))      === Float64
        @test eltype(NormalMeanPrecision(0.0, 1.0)) === Float64
        @test eltype(NormalMeanPrecision(0))        === Float64
        @test eltype(NormalMeanPrecision(0, 1))     === Float64
        @test eltype(NormalMeanPrecision(0.0, 1))   === Float64
        @test eltype(NormalMeanPrecision(0, 1.0))   === Float64
        @test eltype(NormalMeanPrecision(0f0))      === Float32
        @test eltype(NormalMeanPrecision(0f0, 1f0)) === Float32
        @test eltype(NormalMeanPrecision(0f0, 1.0)) === Float64
    end

    @testset "Stats methods" begin

        dist1 = NormalMeanPrecision(0.0, 1.0)
        
        @test mean(dist1)         === 0.0
        @test median(dist1)       === 0.0
        @test mode(dist1)         === 0.0
        @test weightedmean(dist1) === 0.0
        @test var(dist1)          === 1.0
        @test std(dist1)          === 1.0
        @test cov(dist1)          === 1.0
        @test invcov(dist1)       === 1.0
        @test precision(dist1)    === 1.0
        @test entropy(dist1)      ≈ 1.41893853320467
        @test pdf(dist1, 1.0)     ≈ 0.24197072451914337
        @test pdf(dist1, -1.0)    ≈ 0.24197072451914337
        @test pdf(dist1, 0.0)     ≈ 0.3989422804014327
        @test logpdf(dist1, 1.0)  ≈ -1.4189385332046727
        @test logpdf(dist1, -1.0) ≈ -1.4189385332046727
        @test logpdf(dist1, 0.0)  ≈ -0.9189385332046728

        dist2 = NormalMeanPrecision(1.0, 1.0)

        @test mean(dist2)         === 1.0
        @test median(dist2)       === 1.0
        @test mode(dist2)         === 1.0
        @test weightedmean(dist2) === 1.0
        @test var(dist2)          === 1.0
        @test std(dist2)          === 1.0
        @test cov(dist2)          === 1.0
        @test invcov(dist2)       === 1.0
        @test precision(dist2)    === 1.0
        @test entropy(dist2)      ≈ 1.41893853320467
        @test pdf(dist2, 1.0)     ≈ 0.3989422804014327
        @test pdf(dist2, -1.0)    ≈ 0.05399096651318806
        @test pdf(dist2, 0.0)     ≈ 0.24197072451914337
        @test logpdf(dist2, 1.0)  ≈ -0.9189385332046728
        @test logpdf(dist2, -1.0) ≈ -2.9189385332046727
        @test logpdf(dist2, 0.0)  ≈ -1.4189385332046727

        dist3 = NormalMeanPrecision(1.0, 0.5)

        @test mean(dist3)         === 1.0
        @test median(dist3)       === 1.0
        @test mode(dist3)         === 1.0
        @test weightedmean(dist3) === inv(2.0)
        @test var(dist3)          === 2.0
        @test std(dist3)          === sqrt(2.0)
        @test cov(dist3)          === 2.0
        @test invcov(dist3)       === inv(2.0)
        @test precision(dist3)    === inv(2.0)
        @test entropy(dist3)      ≈ 1.7655121234846454
        @test pdf(dist3, 1.0)     ≈ 0.28209479177387814
        @test pdf(dist3, -1.0)    ≈ 0.1037768743551487
        @test pdf(dist3, 0.0)     ≈ 0.21969564473386122
        @test logpdf(dist3, 1.0)  ≈ -1.2655121234846454
        @test logpdf(dist3, -1.0) ≈ -2.2655121234846454
        @test logpdf(dist3, 0.0)  ≈ -1.5155121234846454
        
    end

    @testset "Base methods" begin
        @test convert(NormalMeanPrecision{Float32}, NormalMeanPrecision()) == NormalMeanPrecision{Float32}(0f0, 1f0)
        @test convert(NormalMeanPrecision{Float64}, NormalMeanPrecision(0.0, 10.0)) == NormalMeanPrecision{Float64}(0.0, 10.0)
        @test convert(NormalMeanPrecision{Float64}, NormalMeanPrecision(0.0, 0.1)) == NormalMeanPrecision{Float64}(0.0, 0.1)
        @test convert(NormalMeanPrecision{Float64}, 0, 1) == NormalMeanPrecision{Float64}(0.0, 1.0)
        @test convert(NormalMeanPrecision{Float64}, 0, 10) == NormalMeanPrecision{Float64}(0.0, 10.0)
        @test convert(NormalMeanPrecision{Float64}, 0, 0.1) == NormalMeanPrecision{Float64}(0.0, 0.1)
        @test convert(NormalMeanPrecision, 0, 1) == NormalMeanPrecision{Float64}(0.0, 1.0)
        @test convert(NormalMeanPrecision, 0, 10) == NormalMeanPrecision{Float64}(0.0, 10.0)
        @test convert(NormalMeanPrecision, 0, 0.1) == NormalMeanPrecision{Float64}(0.0, 0.1)
    end

    @testset "vague" begin
        d1 = vague(NormalMeanPrecision)

        @test typeof(d1) <: NormalMeanPrecision
        @test mean(d1)      == 0.0
        @test precision(d1) == ReactiveMP.tiny
    end

    @testset "prod" begin
        
        @test prod(ProdAnalytical(), NormalMeanPrecision(-1, 1/1), NormalMeanPrecision(1, 1/1)) ≈ NormalMeanPrecision(0.0, 2.0)
        @test prod(ProdAnalytical(), NormalMeanPrecision(-1, 1/2), NormalMeanPrecision(1, 1/4)) ≈ NormalMeanPrecision(-1/3, 3/4)
        @test prod(ProdAnalytical(), NormalMeanPrecision(2, 1/2), NormalMeanPrecision(0, 1/10)) ≈ NormalMeanPrecision(5/3, 3/5)

    end

end

end