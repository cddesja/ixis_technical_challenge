# IXIS Technical Challenge
 Code and Documentation for IXIS Technical Challenge

## How to use this repository?
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

### Purpose
The purpose of this challenge was to help a marketing executive at a large bank (1) understand which characteristics of potential customers are the best predictors of purchasing of one of the bank’s products and (2) to develop a predictive model to score each potential customer’s propensity to purchase. 

### Model Methodology and Justification
Based on these two objectives, a LASSO logistic regression and a decision tree were fit. Logistic regression models were examined as they (a) are highly interpretable, (b) their properties are well understood, (c) potential known to the end user and (d) fast to run. In situation of linear relations between features and the response variable, on the logit scale, they preform well. Given there were 19 candidate features, a couple of approaches to selecting the best logistic regression model were considered: stepwise logistic regression and penalized logistic regression. Either approach would result in a final model with fewer features. In general, penalized logistic regression tends to perform better, in terms of bias/variance tradefoff, than stepwise and thus this approach was selected. Finally, LASSO was performed over ridge or elastic net as it can shrink features' cofficients to 0. 

The other modeling framework considered was a decision tree. Decision trees are helpful when nonlinear relations are expected. They are more flexible than logistic regression, while still being highly interpretable. The decision to consider a decision tree over random forest, e.g., was that if this model fit better than logistic regression it would be possible to communicate modeling findings with tree diagrams rather than just variable importance. 

### Diagram of ML pipeline

The exact pipeline that was used is available in the `_targets.R`, see lines 25 - 65, and is shown in the diagram below.

![Machine Learning Pipeline](ml_pipeline.png)

A greatly simplified version of the major components in this pipeline is shown in the diagram below.

![Simplified Pipeline](simplified_pipeline.png)

Provide written documentation describing:

– A diagram of your ML pipeline(s)
– An explanation of the technical considerations/decisions made at each step of the pipeline
1
– Bonus: Describe how the selected model could be deployed into a production environment (assume
a greenfield architecture) for scoring potential bank customers
