args <- commandArgs(trailingOnly = TRUE)
maskType <- args[1]

source("R/a1_set up terra.R")
source("R/a0_set up environment.R")

# generate training image
maskDir <- file.path("out", "training", paste("mask", inputSize, maskType))
outDir <- file.path("out", "training", paste("image", inputSize, maskType))
files <- list.files(maskDir, full.names = TRUE)
for (maskPath in files) {
  a <- tools::file_path_sans_ext(gsub("_[0-9]+(?=\\.tif$)", "", basename(maskPath), perl = TRUE))
  dopPath <- file.path("inp", "training", "RGB", paste0(a, ".tif"))
  hyperspectralPath <- file.path("inp", "training", "Hyperspectral", paste0(a, ".tif"))
  chmPath <- file.path("inp", "training", "CHM", paste0(a, ".tif"))

  generateImage(maskPath, dopPath, hyperspectralPath, chmPath, outDir, useBands = selectedBands[1:11])
}
