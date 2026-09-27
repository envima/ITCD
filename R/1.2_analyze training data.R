source("R/a0_set up environment.R")

# training image metadata
inpDir <- file.path("inp", "training", "RGB")
inpPaths <- list.files(inpDir, full.name = TRUE)
RGBmetadata <- data.frame()
for (inpPath in inpPaths) {
  a <- getMetadata(inpPath)
  RGBmetadata <- rbind(RGBmetadata, a)
}

inpDir <- file.path("inp", "training", "Hyperspectral")
inpPaths <- list.files(inpDir, full.name = TRUE)
HYPmetadata <- data.frame()
for (inpPath in inpPaths) {
  a <- getMetadata(inpPath)
  HYPmetadata <- rbind(HYPmetadata, a)
}

inpDir <- file.path("inp", "training", "CHM")
inpPaths <- list.files(inpDir, full.name = TRUE)
CHMmetadata <- data.frame()
for (inpPath in inpPaths) {
  a <- getMetadata(inpPath)
  CHMmetadata <- rbind(CHMmetadata, a)
}

## All training RGB images have 3 bands and a resolution of 0.1 m with sizes ranging from 888*1153 to 10000*10000 pixels.
summary(RGBmetadata)

## All training RGB images have crs, but not all are the same
unique(RGBmetadata$crs)

## All training hyperspectral images have 426 bands and a resolution of 1 m with sizes ranging from 90*116 to 1000*1000 pixels.
summary(HYPmetadata)

## All training hyperspectral images have crs, but not all are the same
unique(HYPmetadata$crs)

## All training CHM images have 1 band and a resolution of 1 m with sizes ranging from 90*116 to 1000*1000 pixels.
summary(CHMmetadata)

## All training CHM images have crs, but not all are the same
unique(CHMmetadata$crs)

## All hyperspectral and RGB extent approximately match
inpDir <- file.path("inp", "training", "RGB")
RGBPaths <- list.files(inpDir, full.name = TRUE)
inpDir <- file.path("inp", "training", "Hyperspectral")
hypPaths <- list.files(inpDir, full.name = TRUE)
a <- c()
for (i in seq_along(RGBPaths)) {
  RGB <- terra::ext(terra::rast(RGBPaths[i]))
  hyp <- terra::ext(terra::rast(hypPaths[i]))
  a <- c(a, hyp <= RGB + 1)
}
table(unlist(a))

## All hyperspectral and CHM extent match
inpDir <- file.path("inp", "training", "CHM")
CHMPaths <- list.files(inpDir, full.name = TRUE)
inpDir <- file.path("inp", "training", "Hyperspectral")
hypPaths <- list.files(inpDir, full.name = TRUE)
a <- c()
for (i in seq_along(CHMPaths)) {
  CHM <- terra::ext(terra::rast(CHMPaths[i]))
  hyp <- terra::ext(terra::rast(hypPaths[i]))
  a <- c(a, hyp == CHM)
}
table(unlist(a))

## All crs match
table(HYPmetadata$crs == CHMmetadata$crs)
table(HYPmetadata$crs == RGBmetadata$crs)
