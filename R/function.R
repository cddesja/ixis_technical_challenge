# read in data ----
read_data <- function(file){
  read_delim(file, delim = ";")
}

# initial processing ----
initial_process <- function(data){
  data |>
    mutate(
      # job, martial, educ, default, housing, loan recode unknown to NA
      across(c(job, marital, education, default, housing, loan), function(x){
        ifelse(x == "unknown", NA, x)
      }),

      # 999 means client was not previously contacted as NA
      pdays = ifelse(pdays == 999, NA, pdays),

      # create an ID variable
      idvar = row_number(),

      # create an y as continuous for visualization
      y_bin = ifelse(y == "yes", 1, 0),

      # convert all characters to factors
      # not necessary, but helpful
      across(where(is.character), as.factor)
    ) |>

    # pdays missing so much data, for exercise will drop,
    # could consider imputation
    select(-pdays) |>

    # remove missing data
    # something more sophisticated probably should be used like MI
    na.omit()
}

# obtain descriptives statistics ----
obtain_descriptives <- function(data){
  skim(data)
}

# select only the continuous features ----
select_cont_feat <- function(data){
  data |>
    select_if(is.numeric)
}

# convert dataset with continous features to long format ----
cont_wide_to_long <- function(cont_data){
  cont_data |>
    pivot_longer(cols = age:nr.employed)
}


# select only the categorical features ----
select_cat_feat <- function(data){
  data |>
    select_if(function(x) is.character(x) | is.factor(x))
}

# plot a correlation matrix ----
plot_corr_plot <- function(cont_data){
  # visualize the correlation plot
  cont_data |>
    select(-idvar) |>
    cor(use = "pairwise.complete.obs") |>
    ggcorrplot(lab = TRUE,
               type = "lower")
}

# plot histograms for all continuous variables ----
plot_histograms <- function(cont_long_data){
  cont_long_data |>
    ggplot(aes(value)) +
    geom_histogram(fill = "white", col = "black") +
    facet_wrap(~ name, scales = "free") +
    ylab("Frequency")
}

# plot empirical logit plot for all continuous variables ----
plot_logit_plots <- function(cont_long_data){
  cont_long_data |>
    group_by(name, value) |>
    summarize(p = mean(y_bin),
              n = n()) |>
    mutate(logodds = log(p / (1 - p))) |>
    ggplot(aes(y = logodds, x = value)) +
    geom_point(aes(size = n)) +
    ylab("Empirical Logit") +
    facet_wrap(~ name, scales = "free")
}

# plot barcharts ----
plot_barcharts <- function(cat_data){
  cat_data |>
    pivot_longer(cols = c(job:poutcome)) |>
    group_by(name, value) |>
    summarize(p = mean(y == "yes"),
              n = n()) |>
    ggplot(aes(value, p)) +
    geom_bar(stat = "identity") +
    facet_wrap(~ name, scales = "free") +
    ylab("Proportion")
}

# partition the data ----
part_data <- function(data, seed = 62134){

  # drop my numerical y_bin variable
  data <- data |>
    select(-y_bin)

  set.seed(seed)

  split_dat <- initial_split(data,
                             strata = y)
  train_dat <- training(split_dat)
  test_dat <- testing(split_dat)

  # return a list of the various data sets
  list(split = split_dat,
       train = train_dat,
       test = test_dat)
}

# feature preparation and model set up for the lasso ----
feature_prep_lasso <- function(training_data){

  # y is outcome, everything else, except ID, are features
  lasso_recipe <- recipe(y ~ ., data = training_data) |>

    # ID should not be used in the model
    update_role(idvar, new_role = "ID") |>

    # create dummy variables
    step_dummy(all_nominal_predictors()) |>

    # drop features w/o variance
    step_zv(all_predictors()) |>

    # continuous features need to be standardized
    step_normalize(all_numeric())

  # define the lasso logistic regression model
  lasso_mod <-
    logistic_reg(penalty = tune(), mixture = 1) |>
    set_engine("glmnet")

  # create a lasso workflow
  workflow() %>%
    add_model(lasso_mod) |>
    add_recipe(lasso_recipe)
}

train_lasso <- function(training_data, lasso_workflow, seed = 97652){

  # set up plausible values for lambda
  lambda_grid <- grid_regular(penalty(), levels = 50)

  set.seed(seed)

  # use k-folds cross-validation, where k = 10.
  folds_data <- vfold_cv(training_data)

  # train the models and save the validation predictions
  lasso_tune <- lasso_workflow |>
    tune_grid(resamples = folds_data,
              grid = lambda_grid,
              control = control_grid(save_pred = TRUE))

  # create plots of AUC and accuracy to examine later
  plot_auc <- lasso_tune %>%
    collect_metrics() %>%
    ggplot(aes(penalty, mean, color = .metric)) +
    geom_errorbar(aes(ymin = mean - std_err,
                      ymax = mean + std_err),
                  alpha = 0.5) +
    geom_point() +
    geom_line() +
    facet_wrap(~.metric, scales = "free", nrow = 2) +
    scale_x_log10() +
    theme(legend.position = "none")

  # identify and save the best hyperparameter(s)
  best_param <- lasso_tune %>%
    select_best("roc_auc")

  # save AUC curve for comparsion
  lasso_auc <-
    lasso_tune |>
    collect_predictions(parameters = best_param) |>
    roc_curve(y, .pred_no) |>
    mutate(model = "Lasso Logistic Regression")

  # return some output that will be helpful for validation
  list(
    plot_auc = plot_auc,
    best_param = best_param,
    best_auc = lasso_tune |>
      show_best("roc_auc"),
    compare_auc = lasso_auc
   )
}

# feature preparation for the tree ----
feature_prep_tree <- function(training_data){

  # y is outcome, everything else, except ID, are features
  tree_recipe <- recipe(y ~ ., data = training_data) |>

    # ID should not be used in the model
    update_role(idvar, new_role = "ID")

  # define decision tree
  tree_mod <-
    decision_tree(
      cost_complexity = tune(),
      tree_depth = tune()
    ) %>%
    set_engine("rpart") %>%
    set_mode("classification")


  # create a decision tree workflow
  tree_workflow <-
    workflow() |>
    add_model(tree_mod) |>
    add_recipe(tree_recipe)
}

# train the decision tree
train_tree <- function(training_data, tree_workflow, seed = 97652){

  # Try 25 different complexity and depth parameters combinations
  tree_grid <- grid_regular(cost_complexity(),
                            tree_depth(),
                            levels = 5)

  set.seed(seed)

  # use k-folds cross-validation, where k = 10.
  folds_data <- vfold_cv(training_data)

  # train the models and save the validation predictions
  tree_tune <- tree_workflow |>
    tune_grid(resamples = folds_data,
              grid = tree_grid,
              control = control_grid(save_pred = TRUE))


  # create plots of AUC and accuracy to examine later
  plot_auc <-  tree_tune |>
    collect_metrics() |>
    mutate(tree_depth = factor(tree_depth)) |>
    ggplot(aes(x = cost_complexity, y = mean, color = tree_depth)) +
    geom_line() +
    geom_point(size = 2) +
    facet_wrap(~ .metric, scales = "free") +
    theme_bw()

  # identify and save the best hyperparameter(s)
  best_param <- tree_tune |>
    select_best("roc_auc")

  # save AUC for comparison
  tree_auc <-
    tree_tune |>
    collect_predictions(parameters = best_param) |>
    roc_curve(y, .pred_no) |>
    mutate(model = "Decision Tree")

  # return some output that will be helpful for validation
  list(
    plot_auc = plot_auc,
    best_param = best_param,
    best_auc = tree_tune |>
      show_best("roc_auc"),
    compare_auc = tree_auc
  )
}

# compare the candidate models ----
compare_models <- function(model1, model2){
  bind_rows(model1, model2) |>
    ggplot(aes(x = 1 - specificity, y = sensitivity, col = model)) +
    geom_path(lwd = 1.2) +
    scale_color_brewer(palette = "Set1") +
    theme_bw()
}

# fit final lasso model ----
final_lasso_model <- function(split_data, lasso_workflow, best_param){

  ## finalize workflow
  final_lasso <- finalize_workflow(
    lasso_workflow,
    best_param
  )

  lasso_last_fit <-
    final_lasso %>%
    last_fit(split_data)

  fit_measures <- lasso_last_fit  |>
    collect_metrics()

  extract_vi <- lasso_last_fit %>%
    extract_fit_parsnip() %>%
    vi() %>%
    mutate(Variable = forcats::fct_reorder(Variable, Importance)) %>%
    head(n = 5) |>
    mutate(Variable = recode(Variable, emp.var.rate = "Employment Variation Rate",
                             duration = "Last Contact Duration",
                             cons.price.idx = "Consumer Price Index",
                             euribor3m = "Euribor 3 month rate",
                             poutcome_success = "Successful Previous Market Compaign"))

  plot_vi <- extract_vi |>
    ggplot(aes(x = Importance, y = Variable, col = Sign)) +
    geom_point(size = 10) +
    geom_segment(aes(xend = 0, yend = Variable), size = 1.8, alpha = .5) +
    labs(y = NULL) +
    scale_color_brewer("", palette = "Set1") +
    theme_bw() +
    theme(legend.position = "none",
          panel.grid.major = element_blank(),
          panel.grid.minor = element_blank()) +
    ggtitle("Top 5 Most Important Predictors")

  list(
    fit_measures = fit_measures,
    plot_vi = plot_vi
  )
}

