# FF5Regression

[![Build Status](https://github.com/krisha-doshi/FF5Regression.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/krisha-doshi/FF5Regression.jl/actions/workflows/CI.yml?query=branch%3Amain)


## Introduction
Computes Fama French Five Factor (FF5) loadings and alpha for given stock tickers.

This downloads most recent monthly data from Yahoo Finance on the company's adjusted close and from Fama French 5 Factors documents. 
It then reates a dataframe for any given ticker within its specified timeframe with columns of the 5 Fama French factors, the monthly and excess returns of the company represented by the ticker.
It uses the dataframe to construct a multi linear regression model of excess returns against the 5 Fama French factors and gives estimates of the coefficients of the model (alpha and the Fama French Five Factor loadings).
The equation, coefficients and standard errors are displayed.
The performance of the model created on the test set is then displayed.
The t and f test is conducted on the model.
