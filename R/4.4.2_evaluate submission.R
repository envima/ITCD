args <- commandArgs(trailingOnly = TRUE)
modelName <- args[1]
type <- args[2]

source("R/a0_set up environment.R")

# overlap
n <- 24

# combination of segment parameters
j <- 76

# evaluate submission file
segmentDir <- file.path("out", "testing", "segment", paste0(modelName, " overlap", n, " segment", j))
submission <- file.path(segmentDir, paste0("submission", type, ".csv"))
evaluateSubmission(submission, segmentDir)
