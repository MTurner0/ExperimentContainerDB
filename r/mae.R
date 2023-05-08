library(maeplyr)
library(RSQLite)
library(microbenchmark)
library(ggplot2)
theme_set(theme_bw())

source("r/exp_exporter.R")

# Load 16S rRNA data
data("momspi16S_mtx")
data("momspi16S_samp")
data("momspi16S_tax")

# Load cytokines data
data("momspiCyto_mtx")
data("momspiCyto_samp")

# Add to SQLite DB
mae_db <- dbConnect(SQLite(), "data/momspi.sqlite")

rbind(
  momspi16S_samp,
  momspiCyto_samp
) %>%
  dbWriteTable(mae_db, "colData", .,overwrite = TRUE)

momspi16S_tax <- as.data.frame(momspi16S_tax)
momspi16S_tax$ID <- rownames(momspi16S_tax)
dbWriteTable(mae_db, "rowData_phy16S", momspi16S_tax, overwrite = TRUE)
dbWriteTable(mae_db, "rowData_cyto", data.frame(cytokine = rownames(momspiCyto_mtx)), overwrite = TRUE)

dbWriteTable(mae_db, "phy16S", unpivot_assay(momspi16S_mtx), overwrite = TRUE)
dbWriteTable(mae_db, "cyto", unpivot_assay(momspiCyto_mtx), overwrite = TRUE)

# Construct cytokines SummarizedExperiment
momspiCyto <- SummarizedExperiment(
  assays = list(cyto_conc = momspiCyto_mtx),
  colData = momspiCyto_samp,
  rowData = data.frame(cytokine = rownames(momspiCyto_mtx))
)
# Construct 16S SummarizedExperiment
momspi16S <- SummarizedExperiment(
  assays = list(counts = momspi16S_mtx),
  colData = momspi16S_samp,
  rowData = momspi16S_tax
)
# Construct MultiAssayExperiment
momspi_data <- MultiAssayExperiment(
  experiments = list(phy16S = momspi16S, cyto = momspiCyto)
)

# Clean up
rm(momspi16S, momspiCyto, momspi16S_samp, momspi16S_tax, momspiCyto_samp,
   momspi16S_mtx, momspiCyto_mtx)

# Use metadata to select data collected at
# (1) the same visit (across the two experiments)
# and (2) the first visit.
# Count the number of samples.

momspi_preprocessing <- "SELECT
    MAX(CASE WHEN file_name LIKE '%MVAX' THEN file_name ELSE '' END) AS cytoID,
    MAX(case when file_name like '%D' then file_name else '' end) as phyID 
    FROM colData
    GROUP BY subject_id, sample_body_site, project_name, study_full_name, subject_gender, subject_race, visit_number
    HAVING COUNT(*) = 2 AND visit_number = 1;"

dbGetQuery(mae_db, momspi_preprocessing)

momspi_data %>%
  # Use metadata to select data collected at
  # (1) the same visit (across the two experiments)
  intersect_colData(by = c("subject_id", "sample_body_site",
                           "project_name", "study_full_name", "subject_gender",
                           "subject_race", "visit_number")) %>%
  # and (2) the first visit
  filter_colData(visit_number == 1)

res <- microbenchmark(
  SQLite = dbGetQuery(mae_db, momspi_preprocessing),
  MAE = {momspi_data %>%
      intersect_colData(by = c("subject_id", "sample_body_site",
                               "project_name", "study_full_name", "subject_gender",
                               "subject_race", "visit_number")) %>%
      filter_colData(visit_number == 1)},
  unit = "ms"
  ) %>%
  as.data.frame()

res %>%
  ggplot(aes(y = expr, x = time)) +
  geom_boxplot() +
  labs(x = "Evaluation time (ns)", y = "")
