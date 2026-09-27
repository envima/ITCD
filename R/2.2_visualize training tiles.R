args <- commandArgs(trailingOnly = TRUE)
maskType <- args[1]
strategy <- args[2]

source("R/a1_set up terra.R")
source("R/a0_set up environment.R")

# get all filenames
maskDir <- file.path("out", "training", paste("mask", inputSize, maskType))
allFiles <- list.files(maskDir)

# set parameters before plotting
mfrow_org <- par("mfrow")
newRes <- 300
f <- newRes / 72
myMar <- c(0, 0, 2, 0)

for (i in allFiles[1]) {
  # read files
  maskPath <- file.path("out", "training", paste("mask", inputSize, maskType), i)
  imagePath <- file.path("out", "training", paste("image", inputSize, maskType), i)
  weightPath <- file.path("out", "training", paste("weight", inputSize, maskType, strategy), i)
  imager <- terra::rast(imagePath)
  maskr <- terra::rast(maskPath)
  weightr <- terra::rast(weightPath)

  # plot
  filename <- file.path("out", "training", "visualization", paste(tools::file_path_sans_ext(i), inputSize, maskType, paste0(strategy, ".jpeg")))
  jpeg(filename, width = 480 * f, height = 360 * f, res = 72 * f, pointsize = 12, family = "Times")
  par(mfrow = c(3, 4))
  for (j in selectedBands[1:8]) {
    terra::plot(imager[[j]], axes = FALSE, legend = FALSE, mar = myMar, main = names(imager[[j]]), col = .default.pal())
  }
  terra::plotRGB(imager[[c("R", "G", "B")]] * 255, mar = myMar, main = "RGB")
  terra::plotRGB(imager[[c("11", "55", "113")]] * 255, mar = myMar, main = "11/55/113")
  terra::plot(maskr, axes = FALSE, legend = FALSE, mar = myMar, main = "target", col = .default.pal())
  terra::plot(weightr, axes = FALSE, legend = FALSE, mar = myMar, main = "weight", col = .default.pal())
  dev.off()
}

# recover plot parameter
par(mfrow = mfrow_org)
