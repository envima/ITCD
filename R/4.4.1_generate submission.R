args <- commandArgs(trailingOnly = TRUE)
modelName <- args[1]
type <- args[2]

source("R/a0_set up environment.R")

# overlap
n <- 24

# combination of segment parameters
j <- 76

# get common file names of the testing data
commonPredict <- tools::file_path_sans_ext(list.files(file.path("inp", "testing", "RGB")))
if (type == "Common") {
  Dalponte2016 <- readRDS(file.path("out", "submission", "imageCrowns_Dalponte2016.RDS"))
  commonPredict <- commonPredict[commonPredict %in% Dalponte2016$plot_level$plot_name]
}

# generate submission file
segmentDir <- file.path("out", "testing", "segment", paste0(modelName, " overlap", n, " segment", j))
inpPaths <- list.files(segmentDir, pattern = ".gpkg", full.names = TRUE)
if (type == "Common") {
  inpPaths <- inpPaths[tools::file_path_sans_ext(basename(inpPaths)) %in% commonPredict]
}
generateSubmission(inpPaths, segmentDir, shouldHave = commonPredict, outName = paste0("submission", type))
