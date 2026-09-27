# adjust if needed
rootDir <- file.path(Sys.getenv("HPC_SCRATCH"), "ITCD", "IPO")

# set root directory
setwd(rootDir)

# load library
library(magrittr) # for %>%

# import functions
source(file.path("pro", "function.R"))

# set common variables
## image size in pixels
inputSize <- 128
targetShape <- c(inputSize, inputSize)

## batch size
batch_size <- 1

## all bands defined in function
selectedBands <- c("CHM", "113", "ARVI", "NDVI", "GNDVI", "55", "PRI", "11", "B", "G", "R", "NDLI", "EVI", "NIR", "SAVI")