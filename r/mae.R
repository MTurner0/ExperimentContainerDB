library(maeplyr)

# Load 16S rRNA data
data("momspi16S_mtx")
data("momspi16S_samp")
data("momspi16S_tax")

# Load cytokines data
data("momspiCyto_mtx")
data("momspiCyto_samp")

mae_db <- DBI::dbConnect(
  RSQLite::SQLite(),
  paste0("data/", db_name, ".sqlite", collapse = "")
)

rbind(
  momspi16S_samp,
  momspiCyto_samp
) %>%
  

unpivot_assay <- function(assay) {
  assay <- as.data.frame(assay)
  assay$featureID <- rownames(assay)
  
  tidyr::pivot_longer(assay,
                      !featureID,
                      names_to = "sampleID",
                      values_to = "value")
}

momspi16S_tax <- as.data.frame(momspi16S_tax)
momspi16S_tax$ID <- rownames(momspi16S_tax)

write.csv(unpivot_assay(momspi16S_mtx), "../data/momspi/momspi_phy16S.csv", row.names = FALSE)
write.csv(momspi16S_tax, "../data/momspi/momspi_16Stax.csv", row.names = FALSE)