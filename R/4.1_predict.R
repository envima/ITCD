args <- commandArgs(trailingOnly = TRUE)
modelName <- args[1]

source("R/a2_set up tensorflow.R")
source("R/a1_set up terra.R")
source("R/a0_set up environment.R")

# overlap
n <- 24
overlapStride <- c(n, n)

# get common file names
commonPredict <- tools::file_path_sans_ext(list.files(file.path("inp", "testing", "RGB")))

# set parameters for myPredict
modelDir <- file.path("out", "training", "model", modelName)
outDir <- file.path("out", "testing", "prediction", paste0(modelName, " overlap", n))
model <- unet(c(targetShape, 8), weighted = FALSE, num_layers = 4)
loss <- "binary_crossentropy"
metrics <- "accuracy"

# get file names without tile numbering
imageDir <- file.path("out", "testing", paste("image", inputSize), paste0("overlap", n))
maskDir <- file.path("out", "testing", paste("mask", inputSize), paste0("overlap", n))
files <- data.frame(
  imagePaths = list.files(imageDir, full.names = TRUE),
  maskPaths = list.files(maskDir, full.names = TRUE)
)
filesWithoutNumbering <- files
filesWithoutNumbering$imagePaths <- gsub("_[0-9]+(?=\\.tif$)", "", basename(files$imagePaths), perl = TRUE)

# generate test and prediction per testing file
for (i in commonPredict) {
  selected <- files[filesWithoutNumbering$imagePaths == paste0(i, ".tif"), ]
  imagePaths <- selected$imagePaths
  maskPaths <- selected$maskPaths
  optimizer <- keras::optimizer_sgd(learning_rate = 0.001, momentum = 0.99)
  myPredict(
    imagePaths, maskPaths, modelDir,
    model, optimizer, loss, metrics,
    batch_size, outDir, overlapStride,
    doEvaluation = FALSE, useBands = selectedBands[1:8]
  )
}
