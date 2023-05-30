using .FF5Regression
using Test
using GLM, DataFrames, CSV, Plots, Lathe, StatsPlots, MLDataUtils, MLBase, HTTP, ZipFile, Dates

FF5Regression.regression_data("aapl", "1999-12-12", "2022-12-12")

@testset "FF5Regression.jl" begin
    # Write your tests here.
end
