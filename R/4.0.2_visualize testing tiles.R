source("R/a1_set up terra.R")
source("R/a0_set up environment.R")

# overlap pixel
n <- 24

# set parameters before plotting
mfrow_org <- par("mfrow")

newRes <- 300
f <- newRes / 72
myMar <- c(0, 0, 2, 0)

imageDir <- file.path("out", "testing", paste("image", inputSize), paste0("overlap", n))
allFiles <- list.files(imageDir)

# get common file names of the testing data
commonPredict <- tools::file_path_sans_ext(list.files(file.path("inp", "testing", "RGB")))

for (k in commonPredict[1]) {
  toPlot <- allFiles[grepl(k, allFiles, fixed = TRUE)]
  
  for (i in toPlot) {
    outDir <- file.path("out", "testing", paste("visualization", inputSize), paste0("overlap", n))
    if (!dir.exists(outDir)) {
      dir.create(outDir, recursive = TRUE)
    }

    # read file
    imagePath <- file.path(imageDir, i)
    imager <- terra::rast(imagePath)

    # plot every band
    png(file.path(outDir, paste0(tools::file_path_sans_ext(i), ".png")), width = 480 * f, height = 375 * f, res = 72 * f, pointsize = 12)
    par(mfrow = c(3, 4))
    for (j in seq_len(terra::nlyr(imager))) {
      terra::plot(imager[[j]], axes = FALSE, legend = FALSE, mar = myMar, main = names(imager[[j]]), col = .default.pal())
    }
    dev.off()
  }
}

# recover plot parameter
par(mfrow = mfrow_org)
