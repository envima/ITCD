# adjust if needed
rootDir <- file.path(Sys.getenv("HPC_SCRATCH"), "ITCD", "IPO")

# set root directory
setwd(rootDir)

# create folders
foldersToCreate <- c(
  "inp", # input
  "pro", # process
  "out", # output
  
  "inp/training",
  "inp/training/annotations",
  "inp/training/RGB",
  "inp/training/Hyperspectral",
  "inp/training/CHM",
  
  "inp/testing",
  "inp/testing/annotations",
  "inp/testing/RGB",
  "inp/testing/Hyperspectral",
  "inp/testing/CHM",
  
  "inp/analysis",
  "inp/submission",
  
  "out/training",
  "out/training/mask",
  "out/training/annotations",
  "out/training/weight",
  "out/training/image",
  "out/training/model",
  "out/training/visualization",
  
  "out/testing",
  "out/testing/mask",
  "out/testing/image",
  "out/testing/prediction",
  "out/testing/segment",
  "out/testing/visualization",
  
  "out/analysis",
  "out/submission"
)
for (i in foldersToCreate) {
  if (!dir.exists(i)) {
    dir.create(i)
  }
}
