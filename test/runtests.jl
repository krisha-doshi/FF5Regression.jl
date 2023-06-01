using .FF5Regression
using Test
using GLM, DataFrames, CSV, Plots, MLDataUtils, MLBase, HTTP, ZipFile, Dates, DataStructures

FF5Regression.model_results(Base.vect("aapl", "amzn"), "2012-12-12", "2021-12-12", "FF5")

# @testset "FF5Regression.jl" begin
# end
