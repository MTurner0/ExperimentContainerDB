source("r/dummy_exp_builder.R")
source("r/exp_exporter.R")

small <- dummy_se_builder(
  rpois,
  list(lambda = 0.5),
  n_features = 10,
  n_samples = 10,
  seed = 1416)

small.db <- export_se(small, "small_exp")
