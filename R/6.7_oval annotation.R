source("R/a0_set up environment.R")

commonTrain <- tools::file_path_sans_ext(list.files(file.path("inp", "training", "RGB")))

i <- commonTrain[1]
xmlPath <- file.path("inp", "training", "annotations", paste0(i, ".xml"))
dopPath <- file.path("inp", "training", "RGB", paste0(i, ".tif"))
cropped <- file.path("out", "training", "mask 128 oval", "2018_BART_4_322000_4882000_image_crop_1.tif")

# convert xml to sf
im <- raster::stack(dopPath)
dat <- dplyr::bind_rows(parallel::mclapply(xmlPath, NeonTreeEvaluation::xml_parse))
mask <- NeonTreeEvaluation::boxes_to_spatial_polygons(dat, im)
mask_ori <- mask

# draw oval annotation
for (j in 1:nrow(mask)) {
  bbox <- sf::st_bbox(mask$geometry[j])
  smx <- (bbox$xmax - bbox$xmin) / 2 # semi-minor/major axis on x
  smy <- (bbox$ymax - bbox$ymin) / 2 # semi-minor/major axis on y
  angles <- seq(0, 2 * pi, pi/8)

  ellipse <- c()
  for (angle in angles) {
    ellipse <- rbind(ellipse, c(smx * cos(angle), smy * sin(angle)) + c(bbox$xmin + smx, bbox$ymin + smy))
  }

  mask$geometry[j] <- sf::st_polygon(x = list(ellipse))
}

# plot
filename <- file.path("out", "analysis", "oval annotation.jpeg")
newRes <- 300
f <- newRes / 72
myMar <- c(0, 0, 2, 0)
jpeg(filename, width = 240 * 3 * f, height = 240 * f, res = 72 * f, pointsize = 12, family = "Times")
    par(mfrow = c(1, 3))
    im <- terra::rast(dopPath)
    cropped <- terra::rast(cropped)
    terra::plotRGB(terra::crop(im, cropped), mar = myMar, main = "RGB")
    terra::plotRGB(terra::crop(im, cropped), mar = myMar, main = "Original annotation")
    plot(mask_ori, add = TRUE, col = NA)
    terra::plotRGB(terra::crop(im, cropped), mar = myMar, main = "Adapted annotation")
    plot(mask, add = TRUE, col = NA)
dev.off()
