using .FF5Regression
using Test
using GLM, DataFrames, CSV, Plots, Lathe, StatsPlots, MLDataUtils, MLBase, HTTP, ZipFile, Dates


@testset "FF5Regression.jl" begin
    FF5Regression.regression_data("aapl", "1999-12-12", "2022-12-12")
    # Write your tests here.
end
