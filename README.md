# ModelRegression

[![Build Status](https://github.com/krisha-doshi/FF5Regression.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/krisha-doshi/FF5Regression.jl/actions/workflows/CI.yml?query=branch%3Amain)


## Introduction
Package ModelRegression provides utility functions to run a regression on various models, namely Capital Asset Pricing Model (CAPM), Fama French 3 Factor (FF3) and Fama French Five Factor (FF5). 

## Usage

````julia
using ModelRegression
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
    ModelRegression.model_results_df(Base.vect("aapl", "amd"), "1963-07-01", now(), "FF3")
    
    """
    model_results_dict(sym, startd, endd) 

    Calculate and return the coefficients and standard errors for models 
    (CAPM, FF3 and FF5) as a nested dictionary.

    params:
        - sym:: String or Vector, ticker
        - startd:: DateTime, starting date in the form 'yyyy-mm-dd'
        - endd:: DateTime, ending date in the form 'yyyy-mm-dd'
    """
    ModelRegression.model_results_dict(Base.vect("aapl", "amd"), "1963-07-01", now())
    # This would produce a nested dictionary with the coefficients and standard errors of alpha and the loadings of the various models

