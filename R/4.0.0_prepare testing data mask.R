source("R/a1_set up terra.R")
source("R/a0_set up environment.R")

# overlap pixel
n <- 24
overlapStride <- c(n, n)

# get common file names of the testing data
commonPredict <- tools::file_path_sans_ext(list.files(file.path("inp", "testing", "RGB")))

# generate testing mask
outDir <- file.path("out", "testing", paste("mask", inputSize), paste0("overlap", n))
for (i in commonPredict) {
  xmlPath <- file.path("inp", "testing", "annotations", paste0(i, ".xml"))
  dopPath <- file.path("inp", "testing", "RGB", paste0(i, ".tif"))
  generateMask(
    xmlPath, dopPath, targetShape, outDir,
    mixedOnly = FALSE, overlapStride = overlapStride
  )
}
