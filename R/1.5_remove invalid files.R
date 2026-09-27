source("R/a0_set up environment.R")

toDelete <- c("SJER_062_2018", "TALL_043_2019", "SJER_016_2018")

deleteList <- c()
for (i in toDelete) {
  filePath1 <- file.path("inp", "testing", "annotations", paste0(i, ".xml"))
  filePath2 <- file.path("inp", "testing", "RGB", paste0(i, ".tif"))
  filePath3 <- file.path("inp", "testing", "Hyperspectral", paste0(i, ".tif"))
  filePath4 <- file.path("inp", "testing", "CHM", paste0(i, ".tif"))
  deleteList <- c(deleteList, filePath1, filePath2, filePath3, filePath4)
}

for (i in deleteList) {
  if (file.exists(i)) {
    file.remove(i)
  }
}
