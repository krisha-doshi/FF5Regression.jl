module ModelRegression
using GLM, DataFrames, CSV, Plots, MLDataUtils, MLBase, HTTP, ZipFile, Dates, DataStructures

"""
    generate_ff_monthly_data() 

Generate the latest monthly data from the Fama French 5 Factors documents in the form of a 
dataframe
"""
function generate_ff_monthly_data()
  # URL of the zip file
  url = "https://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/F-F_Research_Data_5_Factors_2x3_CSV.zip"

  # Download the zip file to memory
  response = HTTP.get(url)

  # Wrap the downloaded data in an IOBuffer
  buffer = IOBuffer(response.body)

  # Open the zip file from the buffer
  z = ZipFile.Reader(buffer)

  df = DataFrame()

  # Loop over the files in the zip file
  for f in z.files
    # Display the file name
    println(f.name)
  
    file_data = String(read(f))
    file_data = replace(file_data, "\r\n" => "\n")
    lines = split(file_data, '\n')
  
    # filtered_lines = [line for line in lines if length(split(line, ',')) == 7 && (split(line, ',')[1] != "") && (length(strip(split(line, ',')[1])) == 6)]
    filtered_lines = []
    for line in lines
      elements = split(line, ',')
      if (length(elements) == 7) && (strip(elements[1]) != "") && (length(strip(elements[1])) == 6)
        cleaned_elements = [strip(element) for element in elements]
        cleaned_elements[1] = cleaned_elements[1][1:4] * "-" * cleaned_elements[1][5:6]
        push!(filtered_lines, join(cleaned_elements, ','))
      end
    end
    
    filtered_data = join(filtered_lines, '\n')

    column_names = ["Month", "MKT_RF", "SMB", "HML", "RMW", "CMA", "RF"]
  
    df = CSV.File(IOBuffer(filtered_data), header=column_names) |> DataFrame

    df[!,"MKT_RF"] = df[!,"MKT_RF"]/100
    df[!,"SMB"] = df[!,"SMB"]/100
    df[!,"HML"] = df[!,"HML"]/100
    df[!,"RMW"] = df[!,"RMW"]/100
    df[!,"CMA"] = df[!,"CMA"]/100
    df[!,"RF"] = df[!,"RF"]/100


  end

  # Close the zip file when done
  close(z)

  return df
end

"""
    get_monthly(sym, startd, endd)

Generate a dataframe containing the monthly returns
of a specific company with ticker `sym` in the specified timeframe 
between `startd` and `endd`

params:
    - sym:: String , ticker
    - startd:: DateTime, starting date in the form 'yyyy-mm-dd'
    - endd:: DateTime, ending date in the form 'yyyy-mm-dd'
"""
function get_monthly(sym, startd, endd)
    symbol = uppercase(sym)
    starting = Int(datetime2unix.(DateTime(startd)))
    ending = Int(datetime2unix.(DateTime(Date(endd))))
    url = "https://query1.finance.yahoo.com/v7/finance/download/$symbol?period1=$starting&period2=$ending&interval=1mo&events=history&includeAdjustedClose=true"
    response = HTTP.get(url)
    data = CSV.File(IOBuffer(response.body)) |> DataFrame
   
    # Collecting adjusted closing data
    dates = data[2:end,1]
    adj_close = data[:,6]
   
    # Calculating monthly returns
    # monthly returns = (adj close of this month / adj close of last month) - 1
    month = Vector()
    for i in eachindex(adj_close)
        if i!= 1
            push!(month,(adj_close[i]/adj_close[i-1] -1))
        else
            continue
        end
    end
    monthly_returns = DataFrame(Month = dates, Monthly_Returns = month)
    return monthly_returns
end

"""
    get_main_data(sym, startdate, enddate)

Generate a dataframe containing the excess and monthly returns
of a specific company with ticker `sym` and the Fama French 5 
factors data in the specified timeframe between `startd` and `endd`

params:
    - sym:: String , ticker
    - startd:: DateTime, starting date in the form 'yyyy-mm-dd'
    - endd:: DateTime, ending date in the form 'yyyy-mm-dd'
"""
function get_main_data(sym, startdate, enddate)
    five_factors = generate_ff_monthly_data()
    monthly = get_monthly(sym, startdate, enddate)
    df = innerjoin(five_factors, monthly, on=:Month)
    df[!,:Excess_Returns] = df[:,8] - df[:,7]
    return df 
end 

"""
    model_results_df(sym, startd, endd, model) 

Calculate and return the coefficients for a model
(CAPM, FF3 or FF5) as a dataframe.

params:
    - sym:: String or Vector, ticker
    - startd:: DateTime, starting date in the form 'yyyy-mm-dd'
    - endd:: DateTime, ending date in the form 'yyyy-mm-dd'
    - model:: String, model used for regression (CAPM, FF3 or FF5)
"""
function model_results_df(sym, startdate, enddate, model)
    if typeof(sym) == String
        companies = Base.vect(sym)
    elseif typeof(sym) == Array{String, 1} 
        companies = sym
    end

    # model formula
    if model == "CAPM"
        fm = @formula(Excess_Returns ~ MKT_RF)
    elseif model ==  "FF3"
        fm = @formula(Excess_Returns ~ MKT_RF + SMB + HML)
    elseif model == "FF5"
        fm = @formula(Excess_Returns ~ MKT_RF + SMB + HML + RMW + CMA)
    else
        return("Incorrect model entered")
    end

    output_df = DataFrame()
    # output_dict = DefaultDict{String, Dict{String, String}}(()->Dict{String,String}())
    for company in companies
        df = get_main_data(company, startdate, enddate)
        linearRegressor = lm(fm, df)
        ttestresults = @time linearRegressor

        # coefficients and std errors of model 
        coefficients = coef(linearRegressor)
        standard_errors = stderror(linearRegressor)
        companyname = Dict([("Company", company), ("Intercept", coefficients[1]), ("MKT_RF", coefficients[2]), ("R_Square_Value", r2(linearRegressor))])
    
        if model != "CAPM"
            companyname["SMB"] = coefficients[3]
            companyname["HML"] = coefficients[4]
            
            if model == "FF5"
                companyname["RMW"] = coefficients[5]
                companyname["CMA"] = coefficients[6]
                data = DataFrame(companyname)
                append!(output_df, data)
                select!(output_df, :Company, :Intercept, :MKT_RF, :SMB, :HML, :RMW, :CMA, :R_Square_Value)
            else
                data = DataFrame(companyname)
                append!(output_df, data)
                select!(output_df, :Company, :Intercept, :MKT_RF, :SMB, :HML, :R_Square_Value)
            end
        else
            data = DataFrame(companyname)
            append!(output_df, data)
            select!(output_df, :Company, :Intercept, :MKT_RF, :R_Square_Value)
        end
    end
    
    return output_df

end   

mutable struct Estimate
    coefficient :: Float64
    std_err :: Float64
end

"""
    model_results_dict(sym, startd, endd) 

Calculate and return the coefficients and standard errors for models 
(CAPM, FF3 and FF5) as a nested dictionary.

params:
    - sym:: String or Vector, ticker
    - startd:: DateTime, starting date in the form 'yyyy-mm-dd'
    - endd:: DateTime, ending date in the form 'yyyy-mm-dd'
"""
function model_results_dict(sym, startdate, enddate)
    if typeof(sym) == String
        companies = Base.vect(sym)
    elseif typeof(sym) == Array{String, 1} 
        companies = sym
    end

    output_dict = DefaultDict{String, Dict{String, Dict{String, Any}}}(()->Dict{String,Dict{String, Any}}())
    
    for company in companies
        df = get_main_data(company, startdate, enddate)

        output_dict[company] = Dict()

        fmCAPM = @formula(Excess_Returns ~ MKT_RF) 
        linearRegressorCAPM = lm(fmCAPM, df)
        coefficientsCAPM = coef(linearRegressorCAPM)
        standard_errorsCAPM = stderror(linearRegressorCAPM)
        output_dict[company]["CAPM"] = Dict([("Intercept", Estimate(coefficientsCAPM[1], standard_errorsCAPM[1])), ("MKT_RF", Estimate(coefficientsCAPM[2], standard_errorsCAPM[2])), ("R_Square_Value", r2(linearRegressorCAPM))])


        fmFF3 = @formula(Excess_Returns ~ MKT_RF + SMB + HML) 
        linearRegressorFF3 = lm(fmFF3, df)
        coefficientsFF3 = coef(linearRegressorFF3)
        standard_errorsFF3 = stderror(linearRegressorFF3)
        output_dict[company]["FF3"] = Dict([("Intercept", Estimate(coefficientsFF3[1], standard_errorsFF3[1])), ("MKT_RF", Estimate(coefficientsFF3[2], standard_errorsFF3[2])), ("SMB", Estimate(coefficientsFF3[3], standard_errorsFF3[3])), ("HML", Estimate(coefficientsFF3[4], standard_errorsFF3[4])), ("R_Square_Value", r2(linearRegressorFF3))])

        fmFF5 = @formula(Excess_Returns ~ MKT_RF + SMB + HML + RMW + CMA)
        linearRegressorFF5 = lm(fmFF5, df)
        coefficientsFF5 = coef(linearRegressorFF5)
        standard_errorsFF5 = stderror(linearRegressorFF5)
        output_dict[company]["FF5"] = Dict([("Intercept", Estimate(coefficientsFF5[1], standard_errorsFF5[1])), ("MKT_RF", Estimate(coefficientsFF5[2], standard_errorsFF5[2])), ("SMB", Estimate(coefficientsFF5[3], standard_errorsFF5[3])), ("HML", Estimate(coefficientsFF5[4], standard_errorsFF5[4])), ("RMW", Estimate(coefficientsFF5[5], standard_errorsFF5[5])), ("CMA", Estimate(coefficientsFF5[6], standard_errorsFF5[6])), ("R_Square_Value", r2(linearRegressorFF5))])

    end
    
    return output_dict

end   

end