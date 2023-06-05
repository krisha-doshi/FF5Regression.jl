using .FF5Regression
using Test
using GLM, DataFrames, CSV, Plots, MLDataUtils, MLBase, HTTP, ZipFile, Dates, DataStructures

dictionary = FF5Regression.model_results_dict(Base.vect("aapl", "amd"), "2012-12-12", "2021-12-12")

# @testset "FF5Regression.jl" begin
# end
