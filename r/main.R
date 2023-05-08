library(RSQLite)
library(maeplyr)
library(microbenchmark)
library(dplyr)
library(ggplot2)

source("r/dummy_exp_builder.R")
source("r/exp_exporter.R")

# Initialize SummarizedExperiment and export to SQLite

experim <- dummy_se_builder(
  rpois,
  list(lambda = 0.5),
  n_features = 10,
  n_samples = 10,
  seed = 1416)

experim.db <- export_se(experim, drop_empty = TRUE)

# Normalization

normalization_query <- "SELECT LOG(value/size + 1) AS norm_val
    FROM assay
    JOIN (SELECT sampleID, SUM(value) AS size
            FROM assay
            GROUP BY sampleID) AS agg
    ON assay.sampleID = agg.sampleID
    LIMIT 10;"

norm_r <- function(se) {
  mutate(se, dummy_assay = log(dummy_assay/colSums(dummy_assay) + 1))
}

# Remove features with no counts across all samples

trim_query <- "SELECT featureID, sampleID, value
    FROM assay
    WHERE featureID NOT IN (
        SELECT featureID
        FROM assay
        GROUP BY featureID
        HAVING SUM(value) = 0
    )
    LIMIT 10;"

# Subset data by sample attribute

filter_query <- "SELECT featureID, assay.sampleID, value, binary_attribute
    FROM assay
    JOIN colData on assay.sampleID = colData.sampleID
    WHERE binary_attribute = 'B'
    LIMIT 10;"

# Benchmarking

res <- data.frame()
set.seed(1416)

for (i in 10:100) {
  
  experim <- dummy_se_builder(
    rpois,
    list(lambda = 0.5),
    n_features = i,
    n_samples = i)
  
  experim.db <- export_se(experim)
  #loki <- export_se(experim, "loki", key = TRUE)
  
  df_temp <- microbenchmark(
    SQLite = dbGetQuery(experim.db, normalization_query),
    #`SQLite (key)` = dbGetQuery(loki, normalization_query),
    SummExp = norm_r(experim),
    unit = "ms"
  ) %>%
    summary() %>%
    mutate(
      n = i,
      test = "Normalization"
      )

  df_temp <- microbenchmark(
    SQLite = dbGetQuery(experim.db, trim_query),
    #`SQLite (key)` = dbGetQuery(loki, trim_query),
    SummExp = trim_empty_rows(experim),
    unit = "ms"
  ) %>%
    summary() %>%
    mutate(
      n = i,
      test = "Feature filtering"
    ) %>%
    rbind(df_temp, .)

  df_temp <- microbenchmark(
    SQLite = dbGetQuery(experim.db, filter_query),
    #`SQLite (key)` = dbGetQuery(loki, filter_query),
    SummExp = filter_colData(experim, binary_attribute == "B"),
    unit = "ms"
  ) %>%
    summary() %>%
    mutate(
      n = i,
      test = "Sample filtering"
    ) %>%
    rbind(df_temp, .)

  res <- rbind(res, df_temp)
  
  # Clean up
  rm(df_temp, experim)
  dbDisconnect(experim.db)
}

# Plotting

theme_set(theme_bw())

res %>%
   ggplot(aes(x = n, y = median, color = expr)) +
   scale_color_manual(name = "Container", values = c("#009E73", "#CC79A7")) +
   geom_line() +
   facet_wrap(~test) +
   labs(x = "Size (n features, n samples)", y = "Median execution time (ms)")

# For use with primary key testing
# res %>%
#   filter(test == "Sample filtering") %>%
#   ggplot(aes(x = n, y = median, color = expr)) +
#   scale_color_manual(name = "Container", values = c("#009E73", "red", "#CC79A7")) +
#   geom_line() +
#   #facet_wrap(~test) +
#   labs(x = "Size (n features, n samples)", y = "Median execution time (ms)")
