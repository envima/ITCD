args <- commandArgs(trailingOnly = TRUE)
maskType <- args[1]
strategy <- args[2]

source("R/a1_set up terra.R")
source("R/a0_set up environment.R")

# generate training weight
maskDir <- file.path("out", "training", paste("mask", inputSize, maskType))
outDir <- file.path("out", "training", paste("weight", inputSize, maskType, strategy))
files <- list.files(maskDir, full.names = TRUE)
for (maskPath in files) {

  a <- tools::file_path_sans_ext(gsub("_[0-9]+(?=\\.tif$)", "", basename(maskPath), perl = TRUE))
  gpkgPath <- file.path("out", "training", "annotations", paste0(a, ".gpkg"))

  generateWeight(maskPath, gpkgPath, outDir, strategy = strategy)
}
