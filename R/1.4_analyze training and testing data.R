source("R/a0_set up environment.R")

# do training and testing overlap?
inpDir <- file.path("inp", "training", "CHM")
trainPaths <- list.files(inpDir, full.name = TRUE)

inpDir <- file.path("inp", "testing", "CHM")
evalPaths <- list.files(inpDir, full.name = TRUE)

length(trainPaths) * length(evalPaths)

out <- c()
for (i in trainPaths) {
  r <- terra::rast(i)
  r1 <- terra::ext(r) + 5
  for (j in evalPaths) {
    r <- terra::rast(j)
    r2 <- terra::ext(r) + 5

    result <- terra::intersect(r1, r2)
    if (is.null(result)) {
      out <- c(out, FALSE)
    } else {
      out <- c(out, TRUE)
      print(paste(i, "and", j, "overlaps"))
    }
  }
}
table(out)

# visualize
i <- file.path("inp", "training", "CHM", "2018_SJER_3_258000_4106000_image.tif")
j <- file.path("inp", "testing", "CHM", "SJER_016_2018.tif")
r <- terra::rast(i)
r1 <- terra::ext(r)
r <- terra::rast(j)
r2 <- terra::ext(r)

newRes <- 300
f <- newRes / 72

png(file.path("out", "analysis", "SJER overlap.png"), width = 480 * f, height = 480 * f, res = 72 * f, pointsize = 12)
terra::plot(r1)
terra::plot(r2, add = T)
dev.off()

# SJER_016_2018 will be taken out in 1.5_remove invalid files.R
