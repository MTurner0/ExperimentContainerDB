# Makes a dummy SummarizedExperiment object of specified size.
# Make this a class? Go to Kris to ask how?
dummy_se_builder <- function(
    data_generating_process,
    params,
    n_features = 10,
    n_samples = 10,
    seed
    ) {

  if (!missing(seed)) {
    set.seed(seed)
  }

  params["n"] <- n_features * n_samples
  data <- do.call(data_generating_process, params)
  assay <- matrix(data, n_features, n_samples)

  coldat <- data.frame(sampleID = keygen(
    n_samples, ceiling(log(n_samples, base = 62))
    ))
  colnames(assay) <- coldat$sampleID

  rowdat <- data.frame(featureID = keygen(
    n_features, ceiling(log(n_features, base = 62))
    ))
  rownames(assay) <- rowdat$featureID

  SummarizedExperiment::SummarizedExperiment(
    assays = list("dummy_assay" = assay),
    rowData = rowdat,
    colData = coldat
  )
}

# Used to make unique keys for features and samples
keygen <- function(n_keys, keylength = 10) {
  keys <- character(length = 0L)
  while (length(keys) < n_keys) {
    key <- paste(
      sample(c(letters, LETTERS, 0:9), size = keylength, replace = TRUE),
      collapse = ""
      )
    keys <- c(keys, key)
    keys <- unique(keys) # Remove duplicates
  }
  return(keys)
}
