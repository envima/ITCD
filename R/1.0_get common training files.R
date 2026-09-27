source("R/a0_set up environment.R")

# adjust if needed
trainingDir <- file.path("..", "NeonTreeEvaluation_train")

# define paths
annotationsDir <- file.path(trainingDir, "annotations", "annotations")
rgbDir <- file.path(trainingDir, "training", "RGB")
hyperspectralDir <- file.path(trainingDir, "training", "Hyperspectral")
chmDir <- file.path(trainingDir, "training", "CHM")

common <- getCommonFiles(annotationsDir, rgbDir, hyperspectralDir, chmDir)

# annotations
files_to_copy <- file.path(annotationsDir, paste0(common, ".xml"))
outDir <- file.path("inp", "training", "annotations")

file.copy(files_to_copy, outDir, overwrite = TRUE)

# RGB
files_to_copy <- file.path(rgbDir, paste0(common, ".tif"))
outDir <- file.path("inp", "training", "RGB")

file.copy(files_to_copy, outDir, overwrite = TRUE)

# hyperspectral
files_to_copy <- file.path(hyperspectralDir, paste0(common, "_hyperspectral.tif"))
outDir <- file.path("inp", "training", "Hyperspectral", paste0(common, ".tif"))

file.copy(files_to_copy, outDir, overwrite = TRUE)

# CHM
files_to_copy <- file.path(chmDir, paste0(common, "_CHM.tif"))
outDir <- file.path("inp", "training", "CHM", paste0(common, ".tif"))

file.copy(files_to_copy, outDir, overwrite = TRUE)
