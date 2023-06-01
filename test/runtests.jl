using .FF5Regression
using Test
using GLM, DataFrames, CSV, Plots, Lathe, StatsPlots, MLDataUtils, MLBase, HTTP, ZipFile, Dates

FF5Regression.model_results(Base.vect("aapl", "amzn"), "2012-12-12", "2021-12-12", "CAPM")

@testset "FF5Regression.jl" begin
end
