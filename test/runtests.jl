using .ModelRegression
using Test
using GLM, DataFrames, CSV, Plots, MLDataUtils, MLBase, HTTP, ZipFile, Dates, DataStructures

@testset "ModelRegression.jl" begin
    # Testing generate_ff_monthly_data
    df1 = ModelRegression.generate_ff_monthly_data()
    @test ncol(df1) == 7
    @test df1[1,1] == Date(1963,07,01)
    @test df1[10,4] == -0.0067
    @test df1[18,6] == -0.0150

    # Testing get_monthly
    df2 = ModelRegression.get_monthly("amd","1963-07-01", now())
    @test ncol(df2) == 2
    @test df2[1,1] == Date(1985,2,1)
    @test round(df2[6,2],digits=6) == 0.144231

    # Testing get_main_data
    df3 = ModelRegression.get_main_data("amd","1963-07-01", now())
    @test ncol(df3) == 9
    @test df3[1,1] == df2[1,1]
    @test df2[12,2] == df3[12, 8]
    @test df3[100,9] + df3[100,7] == df3[100,8]

    # Testing model_results_df
    df4 = ModelRegression.model_results_df(Base.vect("aapl", "amd"), "1963-07-01", now(), "FF3")
    @test ncol(df4) == 6
    @test ModelRegression.model_results_df(Base.vect("aapl", "amd"), "1963-07-01", now(), "FF4") == "Incorrect model entered"

    # Testing model_results_dict
    dict1 = ModelRegression.model_results_dict(Base.vect("aapl", "amd"), "1963-07-01", now())
    @test length(dict1) == 2
    @test length(dict1["aapl"]) == 3
    @test length(dict1["aapl"]["FF5"]) == 7

end
