source("R/a0_set up environment.R")

# testing image metadata
inpDir <- file.path("inp", "testing", "RGB")
inpPaths <- list.files(inpDir, full.name = TRUE)
RGBmetadata <- data.frame()
for (inpPath in inpPaths) {
  a <- getMetadata(inpPath)
  RGBmetadata <- rbind(RGBmetadata, a)
}

inpDir <- file.path("inp", "testing", "Hyperspectral")
inpPaths <- list.files(inpDir, full.name = TRUE)
HYPmetadata <- data.frame()
for (inpPath in inpPaths) {
  a <- getMetadata(inpPath)
  HYPmetadata <- rbind(HYPmetadata, a)
}

inpDir <- file.path("inp", "testing", "CHM")
inpPaths <- list.files(inpDir, full.name = TRUE)
CHMmetadata <- data.frame()
for (inpPath in inpPaths) {
  a <- getMetadata(inpPath)
  CHMmetadata <- rbind(CHMmetadata, a)
}

## All testing RGB images have 3 bands and a resolution of ca. 0.1 m (difference < 1 %) with sizes 400*400 pixels, but there are 2 exceptions: 400*370 (SJER_062_2018) and 400*392 (TALL_043_2019).
summary(RGBmetadata)
RGBmetadata[RGBmetadata$y != 400, c("filename", "y")]

## All testing RGB images have crs, but not all are the same
unique(RGBmetadata$crs)

## All testing hyperspectral images have 426 bands and a resolution of 1 m with sizes of 40*40 pixels, but there are 2 exceptions: 40*37 (SJER_062_2018) and 40*39 (TALL_043_2019).
summary(HYPmetadata)
HYPmetadata[HYPmetadata$y != 40, c("filename", "y")]

## All testing hyperspectral images have no crs
unique(HYPmetadata$crs)

## All testing CHM images have 1 band and a resolution of 1 m with sizes of 40*40 pixels, but there are 2 exceptions of 40*3 (SJER_062_2018) and 40*1 (TALL_043_2019).
summary(CHMmetadata)
CHMmetadata[CHMmetadata$y != 40, c("filename", "y")]

## All testing CHM images have crs, but not all the same
unique(CHMmetadata$crs)

## All hyperspectral and CHM extent approximately match, except SJER_062_2018 and TALL_043_2019
inpDir <- file.path("inp", "testing", "CHM")
CHMPaths <- list.files(inpDir, full.name = TRUE)
inpDir <- file.path("inp", "testing", "Hyperspectral")
hypPaths <- list.files(inpDir, full.name = TRUE)
a <- c()
for (i in seq_along(CHMPaths)) {
  CHM <- terra::ext(terra::rast(CHMPaths[i]))
  hyp <- terra::ext(terra::rast(hypPaths[i]))
  a <- c(a, hyp <= CHM + 1)
}
table(unlist(a))
a <- unlist(a)
CHMPaths[a == FALSE]

## All hyperspectral and RGB extent approximately match
inpDir <- file.path("inp", "testing", "RGB")
RGBPaths <- list.files(inpDir, full.name = TRUE)
inpDir <- file.path("inp", "testing", "Hyperspectral")
hypPaths <- list.files(inpDir, full.name = TRUE)
a <- c()
for (i in seq_along(RGBPaths)) {
  RGB <- terra::ext(terra::rast(RGBPaths[i]))
  hyp <- terra::ext(terra::rast(hypPaths[i]))
  a <- c(a, hyp <= RGB + 1)
}
table(unlist(a))

## All crs match
table(CHMmetadata$crs == RGBmetadata$crs)

# SJER_062_2018 and TALL_043_2019 will be taken out in 1.5_remove invalid files.R
