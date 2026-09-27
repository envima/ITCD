args <- commandArgs(trailingOnly = TRUE)
maskType <- args[1]

source("R/a1_set up terra.R")
source("R/a0_set up environment.R")

# get common file names of the training data
commonTrain <- tools::file_path_sans_ext(list.files(file.path("inp", "training", "RGB")))

# generate training mask
outDir <- file.path("out", "training", paste("mask", inputSize, maskType))
gpkgDir <- file.path("out", "training", "annotations")
for (i in commonTrain) {
  xmlPath <- file.path("inp", "training", "annotations", paste0(i, ".xml"))
  dopPath <- file.path("inp", "training", "RGB", paste0(i, ".tif"))
  generateMask(
    xmlPath, dopPath, targetShape, outDir,
    gpkgDir = gpkgDir, shape = maskType
  )
}

length(list.files(outDir))
