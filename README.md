# IXIS Technical Challenge
 Code and Documentation for IXIS Technical Challenge

## How to use repository?
* Install the following `R` packages:
  - `targets`
  - `tidymodels`
  - `vip`
  - `ggcorrplot`
  - `readr`
  - `skimr`
 
* Clone/download the repository

* Open `ixis.Rproj` in RStudio (though this isn't necessary)

* Open `_targets.R` to see my ML pipeline, Lines 25 - 65.
  - A diagram of this pipeline can be seen by `tar_visnetwork()`
    
* Run `tar_make()` to create all the output which will be saved in `_targets/objects`. These objects be read with `tar_read()` 

* The `function.R` has all the hard work and is well coded.

## Technical Description

The purpose of this challenge was to help a marketing executive at a large bank (1) understand which characteristics of potential customers are the best predictors of purchasing of one of the bank’s products and (2) to develop a predictive model to score each potential customer’s propensity to purchase. Based on these two objectives I decided to fit a LASSO logistic regression and a decision tree. Logistic regression models are highly interpretable, well known, and fast to run. They typically do a good job for most models. Given that I had 19 potential features, I had a couple obvious options for a logistic regression model - stepwise logistic regresion or penalized logistic regression. Both of these approaches would enable me to reduce the number of features in my final model and have a highly intepretable, more parsimonious, and potentially more predictive model. I decided to use LASSO over ridge or elastic net, e.g., because LASSO has the potential to shrink coefficients to 0, while ridge won't.  


Provide written documentation describing:
– The methodology chosen for this project
– A diagram of your ML pipeline(s)
– An explanation of the technical considerations/decisions made at each step of the pipeline
1
– Bonus: Describe how the selected model could be deployed into a production environment (assume
a greenfield architecture) for scoring potential bank customers
