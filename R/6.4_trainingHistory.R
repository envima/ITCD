args <- commandArgs(trailingOnly = TRUE)
modelName <- args[1]

source("R/a2_set up tensorflow.R")
source("R/a0_set up environment.R")

# read training history
i <- file.path("out", "training", "model", modelName)
path <- file.path(i, "trainingHistory.RDS")
trainingHistory <- readRDS(path)

# plot training history
trainingHistory$params$epochs <- 25

newRes <- 300
f <- newRes / 72

library(keras)

jpeg(file.path("out", "analysis", paste0("trainingHistory ", modelName, ".jpeg")), width = 400 * f, height = 400 * f, res = 72 * f, pointsize = 12, family = "Times")
    plot(trainingHistory, method = "ggplot2", theme_bw = TRUE)
dev.off()
