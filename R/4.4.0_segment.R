args <- commandArgs(trailingOnly = TRUE)
modelName <- args[1]

source("R/a1_set up terra.R")
source("R/a0_set up environment.R")

# overlap
n <- 24

# combination of segment parameters
j <- 76

# get common file names of the testing data
commonPredict <- tools::file_path_sans_ext(list.files(file.path("inp", "testing", "RGB")))

# segment
params <- expand.grid(ws = c(5, 10, 15), hmin = c(0.4, 0.5, 0.6), max_cr = c(30, 50, 70), minCrownsArea = c(0, 1.5, 3, 4.5))

for (i in commonPredict) {
  inpPath <- file.path("out", "testing", "prediction", paste0(modelName, " overlap", n), paste0(i, ".tif"))
  referencePath <- file.path("inp", "testing", "RGB", paste0(i, ".tif"))

  outPath <- file.path("out", "testing", "segment", paste0(modelName, " overlap", n, " segment", j), paste0(i, ".gpkg"))
  segment(
    inpPath, outPath,
    referencePath = referencePath,
    ws = params$ws[j], hmin = params$hmin[j], th_tree = params$hmin[j], max_cr = params$max_cr[j], minCrownsArea = params$minCrownsArea[j]
  )
}
