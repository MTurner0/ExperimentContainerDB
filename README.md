# Data management for single- and multi-omics

Benchmarking of SQLite (via `RSQLite`) against `SummarizedExperiment` and `MultiAssayExperiment` containers (data wrangling via the [`maeplyr` package](https://github.com/MTurner0/maeplyr)).

## Set up

The Makefile is currently used only to make (and remove, when using `make clean`) the directory in which to store .sqlite files.

- `r/requirements.R` will install all necessary `R` packages.
- `r/dummy_exp_builder.R` defines the functions used to build `SummarizedExperiment` containers of arbitrary size.
- `r/exp_exporter.R` defines the functions used to export `SummarizedExperiment` data to a local SQLite database (run `make` first).

## Benchmarking

- `r/main.R` can be used to:
    - compare SQLite against `SummarizedExperiment`-based data manipulation
    - over a range of data sizes
    - for three omics pre-processing steps.

The sql/ directory contains the SQL statements used to perform these pre-processing steps in SQLite.

- `r/mae.R` can be used to compare SQLite against `MultiAssayExperiment`-based data manipulation over a portion of [a Human Microbiome Project workflow](https://github.com/waldronlab/MicrobiomeWorkshop).
