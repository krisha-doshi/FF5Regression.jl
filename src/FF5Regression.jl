module FF5Regression
using GLM, DataFrames, CSV, Plots, MLDataUtils, MLBase, HTTP, ZipFile, Dates

"""
generate_ff_monthly_data: Generates the latest monthly data from the Fama French 5 Factors documents in the form of a 
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
  end

  # Close the zip file when done
  close(z)

  return df
end

"""
get_historical: Generates a dataframe containing the monthly returns
of a specific company with ticker `sym` in the specified timeframe 
between `startd` and `endd`

params:
    - sym:: String , ticker
    - startd:: DateTime, starting date in the form 'yyyy-mm-dd'
    - endd:: DateTime, ending date in the form 'yyyy-mm-dd'
"""
function get_historical(sym, startd, endd)
    symbol = uppercase(sym)
    starting = Int(datetime2unix.(DateTime(startd)))
    ending = Int(datetime2unix.(DateTime(endd)))
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
get_main_data: Generates a dataframe containing the excess and monthly
returns of a specific company with ticker `sym` and the Fama French 5 
factors data in the specified timeframe between `startd` and `endd`

params:
    - sym:: String , ticker
    - startd:: DateTime, starting date in the form 'yyyy-mm-dd'
    - endd:: DateTime, ending date in the form 'yyyy-mm-dd'
"""
function get_main_data(sym, startdate, enddate)
    five_factors = generate_ff_monthly_data()
    monthly = get_historical(sym, startdate, enddate)
    df = innerjoin(five_factors, monthly, on=:Month)
    df[!,:Excess_Returns] = df[:,8] - df[:,7]
    return df 
end 

"""
model_results: Calculates the equation of the multiple regression line 
of excess returns against the Fama French 5 factors and the model 
performance.
"""
function model_results(sym, startdate, enddate, model)
    if typeof(sym) == String
        companies = Base.vect(sym)
    elseif typeof(sym) == Array{String, 1} 
        companies = sym
    else
        return("Incorrect data type entered as ticker - enter either a single ticker as a string or a vector containing multiple tickers")
    end

    for company in companies
        df = get_main_data(company, startdate, enddate)

        # model formula
        if model == "CAPM"
            fm = @formula(Excess_Returns ~ MKT_RF)
        elseif model ==  "FF3"
            fm = @formula(Excess_Returns ~ MKT_RF + SMB + HML)
        elseif model == "FF5"
            fm = @formula(Excess_Returns ~ MKT_RF + SMB + HML + RMW + CMA)
        end
        train, test = splitobs(shuffleobs(df), at = 0.75)
        linearRegressor = lm(fm, train)
        ttestresults = @time linearRegressor

        # coefficients and std errors of model 
        coefficients = coef(linearRegressor)
        standard_errors = stderror(linearRegressor)
        if model == "CAPM"
            println("The modelled equation using test data is : Excess Returns = $(coefficients[1]) + $(coefficients[2]) MKT_RF ")
            println("")
            println("The standard errors of the coefficients are:")
            println("Constant: $(standard_errors[1])")
            println("MKT_RF: $(standard_errors[2])")
        elseif model ==  "FF3"
            println("The modelled equation using test data is : Excess Returns = $(coefficients[1]) + $(coefficients[2]) MKT_RF + $(coefficients[3]) SMB + $(coefficients[4]) HML ")
            println("")
            println("The standard errors of the coefficients are:")
            println("Constant: $(standard_errors[1])")
            println("MKT_RF: $(standard_errors[2])")
            println("SMB: $(standard_errors[3])")
            println("HML: $(standard_errors[4])")
        elseif model ==  "FF5"
            println("The modelled equation using test data is : Excess Returns = $(coefficients[1]) + $(coefficients[2]) MKT_RF + $(coefficients[3]) SMB + $(coefficients[4]) HML + $(coefficients[5]) RMW + $(coefficients[6]) CMA ")
            println("")
            println("The standard errors of the coefficients are:")
            println("Constant: $(standard_errors[1])")
            println("MKT_RF: $(standard_errors[2])")
            println("SMB: $(standard_errors[3])")
            println("HML: $(standard_errors[4])")
            println("RMW: $(standard_errors[5])")
            println("CMA: $(standard_errors[6])")
        end

        # R Square value of the model
        println("R Square value: ", r2(linearRegressor))

        # Prediction
        ypredicted_test = predict(linearRegressor, test)

        # Test Performance 
        performance_testdf = DataFrame(y_actual = test[!,:Excess_Returns], y_predicted = ypredicted_test)
        performance_testdf.error = performance_testdf[!,:y_actual] - performance_testdf[!,:y_predicted]
        performance_testdf.error_sq = performance_testdf.error.*performance_testdf.error
        
        
        # Test Error
        println("Mean Absolute test error: ",mean(abs.(performance_testdf.error)), "\n")
        println("Mean square test error: ",mean(performance_testdf.error_sq), "\n")
        
        # Scatter plot of actual vs predicted values on test dataset
        test_plot = scatter(performance_testdf[!,:y_actual],performance_testdf[!,:y_predicted], title = "Predicted value vs Actual value on Test Data", ylabel = "Predicted value", xlabel = "Actual value", legend = false)
        
        # Result of t test
        println("T test results:")
        println(ttestresults)
        println("\n")
        
        # Result of f test
        println("F test results: ")
        println(ftest(linearRegressor.model))
    end
end   

end
