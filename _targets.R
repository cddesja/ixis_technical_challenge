# IXIS Data Challenge Pipeline
#
# Chris Desjardins
# 14 July 2022
#

# Load packages required to define the pipeline:
library(targets)

# Set target options:
tar_option_set(
  # packages for targets (i.e. used in analysis)
  packages = c("tidymodels", "vip", "ggcorrplot", "readr", "skimr"),
  format = "rds" # default storage format
)

# tar_make_clustermq() configuration (okay to leave alone):
options(clustermq.scheduler = "multicore")

# Load the function.R script
# This function contains the code written for this challenge
lapply(list.files("R", full.names = TRUE, recursive = TRUE), source)

# Replace the target list below with your own:
list(
  # read in data
  tar_target(file, "bank.csv", format = "file"),
  tar_target(data, read_data(file)),

  # preprocessing and data manipulation
  tar_target(preprocessed_data, initial_process(data)),
  tar_target(continuous_variables, select_cont_feat(preprocessed_data)),
  tar_target(categorical_variables, select_cat_feat(preprocessed_data)),
  tar_target(continuous_long, cont_wide_to_long(continuous_variables)),

  # obtain descriptive statistics
  tar_target(descriptive_statistics, obtain_descriptives(preprocessed_data)),

  # visualizations
  tar_target(correlogram, plot_corr_plot(continuous_variables)),
  tar_target(histograms, plot_histograms(continuous_long)),
  tar_target(empirical_logits, plot_logit_plots(continuous_long)),
  tar_target(barcharts, plot_barcharts(categorical_variables)),

  # partitioning data
  tar_target(partition_data, part_data(preprocessed_data)),

  # set up and run LASSO
  tar_target(lasso_workflow, feature_prep_lasso(partition_data$train)),
  tar_target(tuned_lasso, train_lasso(partition_data$train, lasso_workflow)),

  # set up and run decision tree
  tar_target(tree_workflow, feature_prep_tree(partition_data$train)),
  tar_target(tuned_tree, train_tree(partition_data$train, tree_workflow)),

  # compare the two models
  tar_target(comparative_plot, compare_models(tuned_lasso$compare_auc, tuned_tree$compare_auc)),

  # run the final model
  tar_target(model, final_lasso_model(partition_data$split, lasso_workflow, tuned_lasso$best_param)),

  # extract the most important variables and show model fit
  tar_target(importance_plot, model$plot_vi),
  tar_target(fit_measures, model$fit_measures)
)
