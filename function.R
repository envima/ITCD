#' Get common filenames
#'
#' @description
#' Get common filenames from four folders.
#'
#' @param annotationsDir Directory of annotation files.
#' @param rgbDir Directory of RGB files.
#' @param hyperspectralDir Directory of hyperspectral files.
#' @param chmDir Directory of CHM files.
#' @returns A vector of common filenames without directory and filename extension.
getCommonFiles <- function(annotationsDir, rgbDir, hyperspectralDir, chmDir) {
  # list file names
  annotations <- list.files(annotationsDir)
  RGB <- list.files(rgbDir)
  Hyperspectral <- list.files(hyperspectralDir)
  CHM <- list.files(chmDir)

  # remove file extensions
  annotations <- tools::file_path_sans_ext(annotations)
  RGB <- tools::file_path_sans_ext(RGB)
  Hyperspectral <- tools::file_path_sans_ext(Hyperspectral)
  CHM <- tools::file_path_sans_ext(CHM)

  # remove _hypersectral and _CHM
  Hyperspectral <- gsub("_hyperspectral", "", Hyperspectral)
  CHM <- gsub("_CHM", "", CHM)

  # find common files
  common <- intersect(annotations, RGB)
  common <- intersect(common, Hyperspectral)
  intersect(common, CHM)
}

#' Get metadata
#'
#' @description
#' Get metadata of raster files.
#'
#' @param inpPath Path to the raster file.
#' @returns A data.frame with filename, dimension, resolution, and crs.
getMetadata <- function(inpPath) {
  # read file
  r <- terra::rast(inpPath)

  # get filename
  filename <- tools::file_path_sans_ext(basename(inpPath))

  # get dimension
  rdim <- dim(r)

  # get resolution
  rres <- terra::res(r)

  # put into data.frame
  out <- data.frame(
    filename = filename,
    x = rdim[1],
    y = rdim[2],
    band = rdim[3],
    xres = rres[1],
    yres = rres[2],
    crs = terra::crs(r, proj = TRUE)
  )
}

#' Tile calculator
#'
#' @description
#' Calculate how many tiles will be generated if cropped and not mixed only?
#'
#' @param inpPath Path to input raster file.
#' @param targetShape A vector with two elements representing output width and height in pixels.
#' @returns Number of tiles.
tileCalculator <- function(inpPath, targetShape) {
  r <- terra::rast(inpPath)
  inputSize <- dim(r)[1:2]

  tileSize <- as.integer(inputSize / targetShape)
  tileSize[1] * tileSize[2]
}

#' Generate mask
#'
#' @description
#' Generate ground truth files.
#'
#' @param xmlPath Path to input annotation file.
#' @param dopPath Path to input RGB file.
#' @param targetShape A vector with two elements representing output width and height in pixels.
#' @param outDir Directory to output mask tiles.
#' @param gpkgDir Directory to output gpkg file.
#' @param croppedDir Directory to output mask file, cropped evenly on all sides.
#' @param mixedOnly Keep only tiles with both foreground and background?
#' @param overlapStride A vector with two elements representing overlapping width and height in pixels.
#' @param oval Instead of a rectangular bounding box, use its inscribed ellipse?
#' @returns NULL, as the function does not return a value.
generateMask <- function(
    xmlPath, dopPath, targetShape, outDir,
    gpkgDir = NULL, croppedDir = NULL, mixedOnly = TRUE, overlapStride = NULL, shape = "rectangular") {
  # create output folder if not exist
  toCheck <- c(outDir, gpkgDir, croppedDir)
  for (i in toCheck) {
    if (!dir.exists(i)) {
      dir.create(i, recursive = TRUE)
    }
  }

  # convert xml to sf
  im <- raster::stack(dopPath)
  dat <- dplyr::bind_rows(parallel::mclapply(xmlPath, NeonTreeEvaluation::xml_parse))
  mask <- NeonTreeEvaluation::boxes_to_spatial_polygons(dat, im)
  #     plotRGB(im)
  #     plot(mask, add = TRUE, col = NA)

  if (shape == "oval") {
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
  }
  #     plot(mask, add = TRUE, col = NA)
  
  # save gpkg file?
  if (!is.null(gpkgDir)) {
    f <- file.path(gpkgDir, paste0(tools::file_path_sans_ext(basename(dopPath)), ".gpkg"))
    sf::st_write(mask[, "crown_id"], f, append = FALSE, delete_dsn = TRUE, quiet = TRUE)
  }

  # convert sf to raster mask
  dop <- terra::rast(dopPath)
  mask <- terra::rasterize(mask, dop)

  # reclassify to 0 and 1s
  mask[is.na(mask[])] <- 0
  mask[mask > 1] <- 1

  if (!is.null(overlapStride)) {
    # fill mask to integer multiple of targetShape
    cropped <- fillAndOverlap(mask, targetShape, overlapStride, fillOnly = TRUE)
  } else {
    # crop evenly to fit target shape
    cropped <- cropEvenly(mask, targetShape)
  }

  # save cropped file?
  if (!is.null(croppedDir)) {
    f <- file.path(croppedDir, basename(dopPath))
    terra::writeRaster(cropped, f, overwrite = TRUE)
  }

  # grid for splitting
  if (!is.null(overlapStride)) {
    maskGrid <- terra::aggregate(cropped, targetShape - overlapStride * 2)
  } else {
    maskGrid <- terra::aggregate(cropped, targetShape)
  }
  terra::values(maskGrid) <- 1:terra::ncell(maskGrid)
  maskGrid <- terra::as.polygons(maskGrid)
  names(maskGrid) <- "cell"

  if (!is.null(overlapStride)) {
    # fill and overlap
    cropped <- fillAndOverlap(mask, targetShape, overlapStride, fillOnly = FALSE)
  }

  # split
  for (i in seq_along(maskGrid)) {
    e1 <- terra::ext(maskGrid[maskGrid$cell == i, ])
    if (!is.null(overlapStride)) {
      toAdd <- c(overlapStride[1], overlapStride[1], overlapStride[2], overlapStride[2]) * terra::res(mask)
      e1 <- e1 + toAdd
    }
    splitted <- terra::crop(cropped, e1)

    # save
    f <- paste0(tools::file_path_sans_ext(basename(dopPath)), "_", i, ".tif")
    f <- file.path(outDir, f)
    if (mixedOnly) {
      if (isMixed(splitted)) {
        terra::writeRaster(splitted, f, overwrite = TRUE)
      }
    } else {
      terra::writeRaster(splitted, f, overwrite = TRUE)
    }
  }
}

#' Is the tile mixed?
#'
#' @description
#' Does the tile have both foreground and background pixels?
#'
#' @param r Input raster.
#' @returns Logical.
isMixed <- function(r) {
  if (1 %in% terra::values(r)) {
    if (0 %in% terra::values(r)) {
      return(TRUE)
    }
  }
  FALSE
}

#' Crop a raster evenly
#'
#' @description
#' Crop a raster evenly on all sides.
#'
#' @param r Input raster.
#' @param targetShape A vector with two elements representing output width and height in pixels.
#' @returns An evenly cropped raster.
cropEvenly <- function(r, targetShape) {
  # define target and input size on x and y direction
  targetSizeX <- targetShape[1]
  targetSizeY <- targetShape[2]
  inputX <- terra::ncol(r)
  inputY <- terra::nrow(r)

  # difference of input and target size
  diffX <- inputX %% targetSizeX
  diffY <- inputY %% targetSizeY

  # determine new dimensions of raster and crop,
  # cutting evenly on all sides if possible
  newXmin <- terra::ext(r)[1] + ceiling(diffX / 2) * terra::res(r)[1]
  newXmax <- terra::ext(r)[2] - floor(diffX / 2) * terra::res(r)[1]
  newYmin <- terra::ext(r)[3] + ceiling(diffY / 2) * terra::res(r)[2]
  newYmax <- terra::ext(r)[4] - floor(diffY / 2) * terra::res(r)[2]
  terra::crop(r, terra::ext(newXmin, newXmax, newYmin, newYmax))
}

#' Generate weight
#'
#' @description
#' Generate weight based on Ronneberger2015.
#'
#' @param maskPath Path to the ground truth file.
#' @param gpkgPath Path to the annotation gpkg file.
#' @param outDir Output directory.
#' @returns Weight raster.
#' @reference https://doi.org/10.1007/978-3-319-24574-4_28
generateWeight <- function(maskPath, gpkgPath, outDir, strategy = "RONN") {
  # create output folder if not exist
  if (!dir.exists(outDir)) {
    dir.create(outDir, recursive = TRUE)
  }

  r <- terra::rast(maskPath)
  
  if (strategy == "BORD10") {
    w <- terra::boundaries(r, classes = TRUE)
    w <- terra::subst(w, 1, 10, others = 1)
  } else if (strategy == "BORD10v2") {
    w <- terra::subst(r, 0, NA)
    w <- terra::boundaries(w, inner = TRUE, directions = 4)
    w <- terra::subst(w, 1, 10, others = 1)
  } else if (strategy == "RONN") {
    # class weight
    rtable <- table(terra::values(r == 0))
    weights <- (1 / rtable) / max(1 / rtable) # is between 0 and 1
    class_weight <- r
    class_weight[class_weight == 1] <- weights["FALSE"]
    class_weight[class_weight == 0] <- weights["TRUE"]

    # take middle point of only background cell
    r[r == 1] <- NA
    p <- terra::as.points(r)

    # crop gpkg (rasterize, then convert back to vector)
    gpkg <- terra::vect(gpkgPath)
    gpkg <- terra::rasterize(gpkg, r, field = "crown_id")
    gpkg <- terra::as.polygons(gpkg)

    # calculate distance (between each polygon and each point)
    d <- terra::distance(gpkg, p)
    #   saveRDS(d, file.path("tem", "d.RDS"))

    # distance to the nearest cell
    d1 <- distanceToNNearestCell(d, 1)
    a <- terra::values(r)
    a <- replace(a, !is.na(a), d1)
    d1 <- terra::rast(r, vals = a)
    #   terra::writeRaster(d1, file.path("tem", "d1.tif"), overwrite = TRUE)

    # distance to the second nearest cell
    d2 <- distanceToNNearestCell(d, 2)
    a <- terra::values(r)
    a <- replace(a, !is.na(a), d2)
    d2 <- terra::rast(r, vals = a)
    #   terra::writeRaster(d2, file.path("tem", "d2.tif"), overwrite = TRUE)

    # calculate weight map
    w <- weightMap(d1, d2, class_weight)
    w <- terra::cover(w, class_weight) # give foreground the class weight
    #   plot(w)
  }
  
  # save
  if (!is.null(outDir)) {
    f <- file.path(outDir, basename(maskPath))
    terra::writeRaster(w, f, overwrite = TRUE)
  }

  w
}

#' Distance to Nth nearest cell
#'
#' @description
#' Distance to Nth nearest cell in pixels.
#'
#' @param distanceMatrix A distance matrix.
#' @param n N as in Nth nearest.
#' @returns NULL, as the function does not return a value.
distanceToNNearestCell <- function(distanceMatrix, n) {
  out <- parallel::mclapply(seq_len(ncol(distanceMatrix)), function(i) {
    sort(distanceMatrix[, i])[n]
  })

  as.vector(do.call(cbind, out))
}

#' Weight formula
#'
#' @description
#' According to Ronneberger2015.
#'
#' @param d1 Distance to nearest cell in pixel.
#' @param d2 Distance to second nearest cell in pixel.
#' @param wc Class weight.
#' @param w0 A constant.
#' @param sigma A constant.
#' @returns Weight raster.
#' @reference https://doi.org/10.1007/978-3-319-24574-4_28
weightMap <- function(d1, d2, wc, w0 = 10, sigma = 5) {
  wc + w0 * exp(-(d1 + d2)^2 / (2 * sigma^2))
}

#' Generate image tiles
#'
#' @description
#' Generate 15-band image tile. The bands are R, G, B, CHM,
#' hyperspectral bands 11, 55, 113, and
#' vegetation indices NIR, NDVI, EVI, ARVI, PRI, NDLI, SAVI, GNDVI.
#'
#' @param maskPath Path to mask.
#' @param dopPath Path to RGB.
#' @param hyperspectralPath Path to hyperspectral.
#' @param chmPath Path to CHM.
#' @param outDir Output directory.
#' @param overlapStride Overlap size in pixel.
#' @returns A 15-band image tile, normalized to 0 and 1.
generateImage <- function(
    maskPath, dopPath, hyperspectralPath, chmPath, outDir,
    overlapStride = NULL, useBands = NULL) {
  # create output folder if not exist
  if (!dir.exists(outDir)) {
    dir.create(outDir, recursive = TRUE)
  }

  # read files
  mask <- terra::rast(maskPath)
  dop <- terra::rast(dopPath)
  hyp <- terra::rast(hyperspectralPath)
  chm <- terra::rast(chmPath)

  # select only some hyperspectral bands
  selectedBands <- c(11, 55, 113, 96, 54, 18, 31, 38, 260, 275, 84, 58)
  hyp <- hyp[[selectedBands]]
  names(hyp) <- c("11", "55", "113", "NIR", "RED", "BLUE", "531", "570", "1680", "1754", "800", "670")

  # extent in some files don't match exactly
  # assume they should
  if (!is.null(overlapStride)) {
    terra::ext(hyp) <- terra::ext(dop)
    terra::ext(chm) <- terra::ext(dop)
  }

  if (!is.null(overlapStride)) {
    targetShape <- dim(mask)[1:2]
    # fill and overlap
    dop <- fillAndOverlap(dop, targetShape, overlapStride, fillOnly = FALSE)
    hyp <- fillAndOverlap(hyp, targetShape / 10, overlapStride / 10, fillOnly = FALSE)
    chm <- fillAndOverlap(chm, targetShape / 10, overlapStride / 10, fillOnly = FALSE)
  }

  # crop files
  # crop bigger for hyp and chm to prevent NA after resampling
  dop <- terra::crop(dop, mask)
  hyp <- terra::crop(hyp, mask, snap = "out")
  chm <- terra::crop(chm, mask, snap = "out")

  # replace na with mean until no na anymore
  dop <- replaceNA(dop)
  hyp <- replaceNA(hyp)
  chm <- replaceNA(chm)

  # resample due to different resolution
  hyp <- terra::resample(hyp, dop, method = "bilinear", threads = TRUE, overwrite = TRUE)
  chm <- terra::resample(chm, dop, method = "bilinear", threads = TRUE, overwrite = TRUE)

  # calculate indices from hyp, + 1e-7 to avoid divided by zero
  NDVI <- (hyp[["NIR"]] - hyp[["RED"]]) / ((hyp[["NIR"]] + hyp[["RED"]]) + 1e-7)
  EVI <- 2.5 * (hyp[["NIR"]] - hyp[["RED"]]) / ((hyp[["NIR"]] + 6 * hyp[["RED"]] - 7.5 * hyp[["BLUE"]] + 1) + 1e-7)
  ARVI <- (hyp[["NIR"]] - 2 * hyp[["RED"]] + hyp[["BLUE"]]) / (hyp[["NIR"]] + 2 * hyp[["RED"]] - hyp[["BLUE"]] + 1e-7)
  PRI <- (hyp[["531"]] - hyp[["570"]]) / (hyp[["531"]] + hyp[["570"]] + 1e-7)
  NDLI <- (log10(hyp[["1754"]]) - log10(hyp[["1680"]])) / (log10(hyp[["1754"]]) + log10(hyp[["1680"]]) + 1e-7)
  SAVI <- (log10(hyp[["800"]]) - log10(hyp[["670"]])) / ((log10(hyp[["800"]]) + log10(hyp[["670"]]) + 0.5) * 1.5 + 1e-7)
  GNDVI <- (hyp[["NIR"]] - hyp[["531"]]) / ((hyp[["NIR"]] + hyp[["531"]]) + 1e-7)

  hyp <- c(hyp[[c("11", "55", "113", "NIR")]], NDVI, EVI, ARVI, PRI, NDLI, SAVI, GNDVI)

  # combine
  out <- c(dop, chm, hyp)
  names(out) <- c("R", "G", "B", "CHM", "11", "55", "113", "NIR", "NDVI", "EVI", "ARVI", "PRI", "NDLI", "SAVI", "GNDVI")

  # output only selected ones
  if (!is.null(useBands)) {
    out <- out[[useBands]]
  }

  # normalize each layer to zero to one
  out <- zeroToOne(out)

  # save
  if (!is.null(outDir)) {
    f <- file.path(outDir, basename(maskPath))
    terra::writeRaster(out, f, overwrite = TRUE)
  }

  out
}

#' Replace NA values in a raster
#'
#' @description
#' Replace NA values in a raster repeatedly with mean value of nearby cells.
#'
#' @param r A raster.
#' @returns A raster without NA. If all pixels are NA, return a raster of 0.
replaceNA <- function(r) {
  # return raster of 0 if all na
  if (all(is.na(terra::values(r)))) {
    terra::values(r) <- 0
    return(r)
  }

  # replace na
  while (TRUE) {
    if (any(is.na(terra::values(r)))) {
      r <- terra::focal(r, w = 3, fun = mean, na.policy = "only", na.rm = TRUE)
    } else {
      break
    }
  }
  r
}

#' Normalize a raster
#'
#' @description
#' Normalize each layer in a terra raster to 0-1.
#' + 1e-7 to avoid divided by zero, which could happen in CHM for example
#'
#' @param ras A raster.
#' @returns A normalized raster.
zeroToOne <- function(ras) {
  out <- lapply(names(ras), function(i) {
    layer <- ras[[i]]
    imax <- max(terra::values(layer), na.rm = TRUE)
    imin <- min(terra::values(layer), na.rm = TRUE)
    normalized <- (layer - imin) / ((imax - imin) + 1e-7)
  })
  out <- terra::rast(out)
}

#' My loss function
#'
#' @description
#' My loss function that calculates mean of output. For weighted model.
#'
#' @returns A loss function.
myLoss_mean <- function() {
  function(target, output) {
    tensorflow::tf$math$reduce_mean(output)
  }
}

#' Training function
#'
#' @description
#' Training function.
#'
#' @param imageDir Image directory.
#' @param maskDir Mask directory.
#' @param weightDir Weight directory.
#' @param outDir Output directory.
#' @param model Model object for use in the training.
#' @param optimizer Optimizer.
#' @param loss Loss function.
#' @param metrics List of metrics.
#' @param batch_size Number of samples per gradient update, default 32.
#' @param epochs Number of epochs to train the model.
#' @param callbacks List of callbacks to be called during training.
#' @param class_weight List of callbacks to be called during training.
#' @param sampling A vector of indices to choose sample from all available input files.
#' @param augment Augment training data?
#' @param weighted Is the model weighted?
#' @param useBands A vector of band names. Only these bands from the image will be used.
#' @returns Training history.
myTrain <- function(
    imageDir, maskDir, weightDir, outDir,
    model, optimizer, loss, metrics,
    batch_size, epochs, callbacks,
    class_weight = NULL, sampling = NULL, augment = TRUE, weighted = FALSE,
    useBands = NULL) {
  # create output folder
  if (!dir.exists(outDir)) {
    dir.create(outDir, recursive = TRUE)
  }

  # get a list of files
  files <- list(
    img = list.files(imageDir, full.names = TRUE),
    mask = list.files(maskDir, full.names = TRUE)
  )
  if (weighted) {
    files$weight <- list.files(weightDir, full.names = TRUE)
  }

  # sampling
  if (!is.null(sampling)) {
    files$mask <- sort(files$mask[sampling])
    files$img <- sort(files$img[basename(files$img) %in% basename(files$mask)])

    if (weighted) {
      files$weight <- sort(files$weight[basename(files$weight) %in% basename(files$mask)])
    }
  }

  # get number of bands in the image
  if (!is.null(useBands)) {
    imgBands <- length(useBands)
  } else {
    imgBands <- terra::nlyr(terra::rast(files$img[1]))
  }

  # split files randomly into training and validation
  files <- data.frame(files)
  data <- rsample::initial_split(files, prop = 0.8)

  # get arrays from files
  ## training image
  files <- rsample::training(data)$img
  outShape <- c(targetShape, imgBands)
  x <- filesToArray(files, outShape, useBands)

  ## training mask
  files <- rsample::training(data)$mask
  outShape <- c(targetShape, 1)
  y <- filesToArray(files, outShape)

  ## validation image
  files <- rsample::testing(data)$img
  outShape <- c(targetShape, imgBands)
  vx <- filesToArray(files, outShape, useBands)

  ## validation mask
  files <- rsample::testing(data)$mask
  outShape <- c(targetShape, 1)
  vy <- filesToArray(files, outShape)

  if (weighted) {
    ## training weight
    files <- rsample::training(data)$weight
    shape <- c(targetShape, 1)
    w <- filesToArray(files, shape)

    ## validation weight
    files <- rsample::testing(data)$weight
    shape <- c(targetShape, 1)
    vw <- filesToArray(files, shape)
  }

  # showImage(x, y)

  # augment training data
  if (augment) {
    x <- augmentation(x)
    y <- augmentation(y)

    if (weighted) {
      w <- augmentation(w)
    }
  }

  #   showImage(as.array(x), as.array(y), length(rsample::training(data)$img)+1)

  # compile model
  model %>% keras::compile(
    optimizer = optimizer,
    loss = loss,
    metrics = metrics
  )

  # train model
  if (weighted) {
    trainingHistory <- model %>% keras::fit(
      x = list(x, y, w),
      y = y,
      batch_size = batch_size,
      epochs = epochs,
      callbacks = callbacks,
      validation_data = list(list(vx, vy, vw), vy),
      class_weight = class_weight
    )
  } else {
    trainingHistory <- model %>% keras::fit(
      x = x,
      y = y,
      batch_size = batch_size,
      epochs = epochs,
      callbacks = callbacks,
      validation_data = list(vx, vy),
      class_weight = class_weight
    )
  }

  # save model
  keras::save_model_tf(model, outDir)

  # save training history
  path <- file.path(outDir, "trainingHistory.RDS")
  saveRDS(trainingHistory, file = path)

  # save training history plot
  path <- file.path(outDir, "trainingHistory.png")
  png(path)
  print(plot(trainingHistory))
  dev.off()

  # plot training history
  #   plot(trainingHistory)

  trainingHistory
}

#' U-Net
#'
#' @description
#' Create a U-Net model.
#'
#' Compared with original model: use_batch_norm was taken as a parameter;
#' Option for weighted model was added; Output datatype was set to float32
#' for calculation stability.
#'
#' @reference https://github.com/r-tensorflow/unet/blob/c47cf31f13050722b587a5c394d4511d8f5e50b9/R/model.R
#' @reference https://github.com/keras-team/keras/blob/r2.15/keras/backend.py#L5802
#' @reference https://www.tensorflow.org/guide/mixed_precision
#'
#' @param input_shape Input shape.
#' @param num_classes Number of classes.
#' @param dropout Dropout rate.
#' @param filters Number of filters in the first layer.
#' @param num_layers Number of layers.
#' @param output_activation Output activation function.
#' @param weighted Create a weighted model?
#' @param use_batch_norm Use batch normalization?
#' @returns A model.
unet <- function(input_shape, num_classes = 1, dropout = 0.5, filters = 64,
                 num_layers = 4, output_activation = "sigmoid", weighted = FALSE, use_batch_norm = FALSE) {
  input <- keras::layer_input(shape = input_shape)

  x <- input
  down_layers <- list()

  for (i in seq_len(num_layers)) {
    x <- conv2d_block(
      inputs = x,
      filters = filters,
      use_batch_norm = use_batch_norm,
      dropout = 0,
      padding = "same"
    )

    down_layers[[i]] <- x

    x <- keras::layer_max_pooling_2d(x, pool_size = c(2, 2), strides = c(2, 2))

    filters <- filters * 2
  }

  if (dropout > 0) {
    x <- keras::layer_dropout(x, rate = dropout)
  }

  x <- conv2d_block(
    inputs = x,
    filters = filters,
    use_batch_norm = use_batch_norm,
    dropout = 0.0,
    padding = "same"
  )

  for (conv in rev(down_layers)) {
    filters <- filters / 2L

    x <- keras::layer_conv_2d_transpose(
      x,
      filters = filters,
      kernel_size = c(2, 2),
      padding = "same",
      strides = c(2, 2)
    )

    x <- keras::layer_concatenate(list(conv, x))
    x <- conv2d_block(
      inputs = x,
      filters = filters,
      use_batch_norm = use_batch_norm,
      dropout = 0.0,
      padding = "same"
    )
  }

  x <- keras::layer_conv_2d(
    x,
    filters = num_classes,
    kernel_size = c(1, 1)
  )

  # https://www.tensorflow.org/guide/mixed_precision
  output <- keras::layer_activation(
    x,
    activation = output_activation,
    dtype = "float32"
  )

  if (weighted) {
    target <- keras::layer_input(shape = c(input_shape[1:2], num_classes))
    weight <- keras::layer_input(shape = c(input_shape[1:2], num_classes))

    #   https://github.com/keras-team/keras/blob/r2.15/keras/backend.py#L5802
    #   epsilon_ <- tensorflow::tf$convert_to_tensor(keras::k_epsilon(), output$dtype$base_dtype)
    #   output <- tensorflow::tf$clip_by_value(output, epsilon_, 1.0 - epsilon_)

    # Compute cross entropy from probabilities.
    bce <- target * tensorflow::tf$math$log(output + keras::k_epsilon())
    bce <- bce + (1 - target) * tensorflow::tf$math$log(1 - output + keras::k_epsilon())
    bce <- -bce
    wbce <- weight * bce

    model <- keras::keras_model(list(input, target, weight), wbce)
  } else {
    model <- keras::keras_model(input, output)
  }

  model
}

#' 2D convolution layer block
#'
#' @description
#' Create a 2D convolution layer block with two convolution layers.
#'
#' Same as reference
#'
#' @reference https://github.com/r-tensorflow/unet/blob/c47cf31f13050722b587a5c394d4511d8f5e50b9/R/model.R
#'
#' @param inputs Input model for this block to be added on.
#' @param use_batch_norm Use batch normalization?
#' @param dropout Dropout rate.
#' @param filters Number of filters in the convolution layers.
#' @param kernel_size Kernel size.
#' @param activation Activation function to use.
#' @param kernel_initializer Initializer for the kernel weights matrix.
#' @param padding Padding option. One of "valid" or "same".
#' @returns A 2D convolution layer block.
conv2d_block <- function(inputs, use_batch_norm = TRUE, dropout = 0.3,
                         filters = 16, kernel_size = c(3, 3), activation = "relu",
                         kernel_initializer = "he_normal", padding = "same") {
  x <- keras::layer_conv_2d(
    inputs,
    filters = filters,
    kernel_size = kernel_size,
    activation = activation,
    kernel_initializer = kernel_initializer,
    padding = padding
  )

  if (use_batch_norm) {
    x <- keras::layer_batch_normalization(x)
  }

  if (dropout > 0) {
    x <- keras::layer_dropout(x, rate = dropout)
  }

  x <- keras::layer_conv_2d(
    x,
    filters = filters,
    kernel_size = kernel_size,
    activation = activation,
    kernel_initializer = kernel_initializer,
    padding = padding
  )

  if (use_batch_norm) {
    x <- keras::layer_batch_normalization(x)
  }

  x
}

#' Files to array
#'
#' @description
#' Transform image files to array.
#'
#' @param files A vector of image file paths.
#' @param outShape Output shape of the array.
#' @param useBands A vector of band names. Only these bands from the image will be extracted.
#' @returns An array representing extracted pixel values.
filesToArray <- function(files, outShape, useBands = NULL) {
  x <- array(, dim = c(length(files), outShape))

  for (i in 1:length(files)) {
    f <- files[i]
    r <- terra::rast(f)

    if (!is.null(useBands)) {
      r <- r[[useBands]]
    }

    a <- terra::as.array(r)

    x[i, , , ] <- a
  }

  x
}

#' Show image
#'
#' @description
#' Show two images from two arrays, RGB on the left, mask on the right.
#'
#' @param x Array for RGB.
#' @param y Array for mask.
#' @param i Which image in the array to show.
#' @param r Band index in the array for R.
#' @param g Band index in the array for G.
#' @param b Band index in the array for B.
#' @param fx Factor to be multiplied with values in x.
#' @param fy Factor to be multiplied with values in y.
#' @returns A plot with RGB on the left and mask on the right.
showImage <- function(x, y, i = 1, r = 1, g = 2, b = 3, fx = 255, fy = 1) {
  par(mfrow = c(1, 2))
  terra::plotRGB(c(terra::rast(x[i, , , r] * fx), terra::rast(x[i, , , g] * fx), terra::rast(x[i, , , b] * fx)))
  terra::plot(terra::rast(y[i, , , 1]) * fy)
}

#' Augmentation
#'
#' @description
#' Augmentation procedure. First randomly flip input horizontally and vertically,
#' and then randomly rotate it between plus/minus 45 degrees.
#'
#' @param x Input array.
#' @returns Concatenation of the original array and augmented array.
#' The output size is two times that of the original array.
augmentation <- function(x) {
  xaug <- x %>%
    keras::layer_random_flip(mode = "horizontal_and_vertical", seed = 42) %>%
    keras::layer_random_rotation(factor = 0.125, seed = 42)
  x <- tensorflow::tf$concat(list(x, xaug), axis = 0L)
}

#' Fill and overlap
#'
#' @description
#' Fill (and overlap) a raster to integer multiple of targetShape by mirroring.
#'
#' @param r Input raster.
#' @param targetShape A vector with two elements representing output width and height in pixels.
#' @param overlapStride A vector with two elements representing overlapping width and height in pixels.
#' @param fillOnly Fill only without overlapping?.
#' @returns Filled (and overlapped) raster.
fillAndOverlap <- function(r, targetShape, overlapStride, fillOnly = FALSE) {
  targetShape <- targetShape - overlapStride * 2

  # distance needed to move on x, y to fill
  rSize <- dim(r)[1:2]
  rNeed <- ceiling(rSize / targetShape) * targetShape - rSize
  rResolution <- terra::res(r)
  rDistance <- ceiling(rNeed / 2) * rResolution

  if (fillOnly) {
    if (sum(rDistance) == 0) {
      return(r)
    } else {
      rFilled <- fourMirrors(r, rDistance)
      return(rFilled)
    }
  } else {
    # distance needed to move on x, y to fill and to overlay
    rDistance <- rDistance + overlapStride * rResolution
    rDistance <- ceiling(rDistance / rResolution) * rResolution

    rFilledAndOverlapped <- fourMirrors(r, rDistance)
  }
}

#' Mirroring
#'
#' @description
#' Mirroring a raster on all sides.
#'
#' @param r5 Input raster to be mirrored.
#' @param d Mirroring distance in pixels.
#' @returns A raster mirrored on all sides.
fourMirrors <- function(r5, d) {
  # imagine the output is a merge of 9 tiles arranged in:
  # 123
  # 456
  # 789

  r5e <- terra::ext(r5)

  e <- terra::ext(r5e[1], r5e[2], r5e[4] - d[2], r5e[4])
  r2 <- terra::crop(r5, e)
  r2 <- terra::flip(r2, direction = "vertical")
  r2 <- terra::shift(r2, dy = d[2])

  e <- terra::ext(r5e[1], r5e[2], r5e[3], r5e[3] + d[2])
  r8 <- terra::crop(r5, e)
  r8 <- terra::flip(r8, direction = "vertical")
  r8 <- terra::shift(r8, dy = -d[2])

  e <- terra::ext(r5e[1], r5e[1] + d[1], r5e[3], r5e[4])
  r4 <- terra::crop(r5, e)
  r4 <- terra::flip(r4, direction = "horizontal")
  r4 <- terra::shift(r4, dx = -d[1])

  e <- terra::ext(r5e[2] - d[1], r5e[2], r5e[3], r5e[4])
  r6 <- terra::crop(r5, e)
  r6 <- terra::flip(r6, direction = "horizontal")
  r6 <- terra::shift(r6, dx = d[1])

  r2e <- terra::ext(r2)

  e <- terra::ext(r2e[1], r2e[1] + d[1], r2e[3], r2e[4])
  r1 <- terra::crop(r2, e)
  r1 <- terra::flip(r1, direction = "horizontal")
  r1 <- terra::shift(r1, dx = -d[1])

  e <- terra::ext(r2e[2] - d[1], r2e[2], r2e[3], r2e[4])
  r3 <- terra::crop(r2, e)
  r3 <- terra::flip(r3, direction = "horizontal")
  r3 <- terra::shift(r3, dx = d[1])

  r8e <- terra::ext(r8)

  e <- terra::ext(r8e[1], r8e[1] + d[2], r8e[3], r8e[4])
  r7 <- terra::crop(r8, e)
  r7 <- terra::flip(r7, direction = "horizontal")
  r7 <- terra::shift(r7, dx = -d[2])

  e <- terra::ext(r8e[2] - d[2], r8e[2], r8e[3], r8e[4])
  r9 <- terra::crop(r8, e)
  r9 <- terra::flip(r9, direction = "horizontal")
  r9 <- terra::shift(r9, dx = d[2])

  terra::merge(r1, r2, r3, r4, r5, r6, r7, r8, r9)
  #   plot(merged)
}

#' Predict
#'
#' @description
#' Predict procedure.
#'
#' @param imagePaths Paths to images.
#' @param maskPaths Paths to masks.
#' @param modelDir Model directory.
#' @param model Model object for use in the prediction.
#' @param optimizer Optimizer.
#' @param loss Loss function.
#' @param metrics List of metrics.
#' @param batch_size Number of samples per gradient update, default 32.
#' @param outDir Output directory.
#' @param overlapStride Overlap size in pixel.
#' @param doEvaluation Evaulate test data?.
#' @param useBands A vector of band names. Only these bands from the image will be used.
#' @returns NULL, as the function does not return a value.
myPredict <- function(
    imagePaths, maskPaths, modelDir,
    model, optimizer, loss, metrics,
    batch_size, outDir, overlapStride = NULL, doEvaluation = FALSE,
    useBands = NULL) {
  # create output folder
  if (!dir.exists(outDir)) {
    dir.create(path = outDir, recursive = TRUE)
  }

  # number of bands
  if (!is.null(useBands)) {
    imgBands <- length(useBands)
  } else {
    imgBands <- terra::nlyr(terra::rast(imagePaths[1]))
  }

  # convert files to array
  files <- imagePaths
  shape <- c(targetShape, imgBands)
  x <- filesToArray(files, shape, useBands)

  model %>% keras::compile(
    optimizer = optimizer,
    loss = loss,
    metrics = metrics
  )

  # load trained weights
  keras::load_model_weights_tf(model, file.path(modelDir, "checkpoint.ckpt"))

  # predict
  result <- predict(model, x, batch_size = batch_size)

  # build result
  out <- c()
  for (i in seq_along(maskPaths)) {
    ref <- terra::rast(maskPaths[i])
    maskRes <- terra::res(ref)
    r <- terra::rast(result[i, , , ], extent = terra::ext(ref), crs = terra::crs(ref))
    if (!is.null(overlapStride)) {
      r <- terra::crop(r, terra::ext(r) - overlapStride * maskRes)
    }
    out <- c(out, r)
  }

  out <- terra::merge(terra::sprc(out))
  names(out) <- "result"

  # The following is ok when done per hand, but returns all NULL when done through the function
  #     out <- lapply(seq_along(maskPaths), function(i) {
  #       ref <- terra::rast(maskPaths[i])
  #       maskRes <- terra::res(ref)
  #       r <- terra::rast(result[i,,,], extent = terra::ext(ref), crs = terra::crs(ref))
  #       if (!is.null(overlapStride)) {
  #         terra::crop(r, terra::ext(r) - overlapStride * maskRes)
  #       }
  #     })
  #     return(out)

  # save result
  f <- gsub("_[0-9]+(?=\\.tif$)", "", basename(imagePaths[1]), perl = TRUE)
  terra::writeRaster(out, file.path(outDir, f), overwrite = TRUE)

  # show result
  #   plot(out)
  
  # evaluate
  if (doEvaluation) {
    files <- maskPaths
    shape <- c(targetShape, 1)
    y <- filesToArray(files, shape)

    ev <- keras::evaluate(model, x, y, batch_size = batch_size)
    f <- tools::file_path_sans_ext(gsub("_[0-9]+(?=\\.tif$)", "", basename(imagePaths[1]), perl = TRUE))
    saveRDS(ev, file.path(outDir, paste0(f, ".RDS")))
    # print(ev)
  }
}

#' Segment
#'
#' @description
#' Segment procedure with region growing
#'
#' @param inpPath Input path of probability raster.
#' @param outPath Output path of delineated vectors.
#' @param referencePath Reference raster path for cropping when overlap strategy was applied.
#' @param ws Diameter of the moving window used to detect the local maxima in the units of the input data.
#' @param hmin Minimum probability to be considered as a tree crown pixel. For lidR::lmf
#' @param th_tree Minimum probability to be considered as a tree crown pixel. For lidR::dalponte2016.
#' @param max_cr Maximum tree crown radius in pixels.
#' @param minCrownsArea Minimum tree crown area in squared unit of the input data.
#' @returns NULL, as the function does not return a value.
segment <- function(inpPath, outPath, referencePath = NULL, ws = 10, hmin = 0.5, th_tree = 0.5, max_cr = 50, minCrownsArea = 3, polygonArea = TRUE) {
  # create output folder
  outDir <- dirname(outPath)
  if (!dir.exists(outDir)) {
    dir.create(path = outDir, recursive = TRUE)
  }

  r <- terra::rast(inpPath)

  # crop if reference is provided. For overlap strategy
  if (!is.null(referencePath)) {
    ref <- terra::rast(referencePath)
    r <- terra::crop(r, ref)
  }

  # normalize to 0 - 1
  r <- zeroToOne(r)
  #   terra::plot(r)

  # get tree points
  algorithm <- lidR::lmf(ws = ws, hmin = hmin)
  treetops <- lidR::locate_trees(r, algorithm)
  #   plot(treetops[, "treeID"], add = TRUE, col = "black")

  # get tree crowns
  # max_cr: Maximum value of the crown diameter (should be radius) of a detected tree (in pixels).
  # *1 To read in memory a SpatRaster, see https://github.com/r-lidar/lidR/issues/597
  algo <- lidR::dalponte2016(r * 1, treetops, th_tree = th_tree, max_cr = max_cr)
  crowns <- algo()

  crowns <- terra::as.polygons(crowns)
  #   terra::plot(crowns, add = TRUE)
  #   text(crowns, 1)
  
  # calculate area
  if (polygonArea) {
    crownsArea <- terra::expanse(crowns, transform = FALSE)
  } else {
    # convert to bounding box
    s <- sf::st_as_sf(crowns)
    bbox <- lapply(s$geom, sf::st_bbox)
  
    crownsArea <- unlist(lapply(bbox, function(i){(i$xmax - i$xmin) * (i$ymax - i$ymin)}))
  }
  
  # exclude bounding box area smaller than
  toExclude <- which(crownsArea < minCrownsArea)
  if (length(toExclude) != 0) {
    crowns <- crowns[-which(crownsArea < minCrownsArea)]
  }

  terra::writeVector(crowns, outPath, overwrite = TRUE, options = "")
}

#' Generate submission file
#'
#' @description
#' For submission to the benchmark dataset Weinstein2021.
#'
#' @param inpPaths Input paths of delineated vectors.
#' @param outDir Output directory.
#' @param shouldHave A vector of files that should have delineated results. If prediction missed some of them, they will be given a tree crown of no size. This ensures the empty results will also be evaluated later.
#' @param outName Output filename without extension.
#' @returns NULL, as the function does not return a value.
generateSubmission <- function(inpPaths, outDir, shouldHave = NULL, outName = "submission") {
  # create output folder
  if (!dir.exists(outDir)) {
    dir.create(path = outDir, recursive = TRUE)
  }
  
  out <- data.frame()
  for (inpPath in inpPaths) {
    # prepare table for evaluation submission
    s <- sf::st_read(inpPath, quiet = TRUE)
    bbox <- lapply(s$geom, sf::st_bbox)
    df <- as.data.frame(do.call(rbind, bbox))
    df$plot_name <- tools::file_path_sans_ext(basename(inpPath))

    #     df2 <- as.data.frame(s$geom)
    #     df <- cbind(df, df2)

    out <- rbind(out, df)
  }

  if (!is.null(shouldHave)) {
    # for [writeVector] nothing to write
    have <- tools::file_path_sans_ext(basename(inpPaths))
    missed <- setdiff(shouldHave, have)
  }

  for (i in missed) {
    a <- list(
      plot_name = i,
      xmin = 0,
      ymin = 0,
      xmax = 0,
      ymax = 0
    )
    out <- rbind(out, a)
  }

  #   f <- file.path(outDir, "submission.RDS")
  #   saveRDS(out, f)

  f <- file.path(outDir, paste0(outName, ".csv"))
  write.csv(out, f)
}

#' Evaluate submission
#'
#' @description
#' Evaluate submission based on the NeonEvaluation package for image tree crowns.
#'
#' @param submission Path to submission.
#' @param outDir Output directory.
#' @param project Should the submission results be projected to UTM?.
#' @returns NULL, as the function does not return a value.
evaluateSubmission <- function(submission, outDir, project = FALSE) {
  # create output folder
  if (!dir.exists(outDir)) {
    dir.create(path = outDir, recursive = TRUE)
  }
  
  f <- tools::file_path_sans_ext(basename(submission))
  predictions <- read.csv(submission)
  
  library(sf) # for missing package::function in NeonTreeEvaluation
  tryCatch(
    {
      out <- NeonTreeEvaluation::evaluate_image_crowns(predictions = predictions, show = FALSE, project = project)
      f <- file.path(outDir, paste0("imageCrowns_", f, ".RDS"))
      saveRDS(out, f)
    },
    error = function(e) {
      print(e$message)
    }
  )

  #   tryCatch({
  #     out <- NeonTreeEvaluation::evaluate_field_crowns(predictions = predictions, show = FALSE)
  #     f <- file.path(outDir, paste0("fieldCrowns_", f, ".RDS"))
  #     saveRDS(out, f)
  #   }, error = function(e) {
  #     print(e$message)
  #   })

  #   tryCatch({
  #     out <- NeonTreeEvaluation::evaluate_field_stems(predictions = predictions, show = FALSE)
  #     f <- file.path(outDir, paste0("fieldStems_", f, ".RDS"))
  #     saveRDS(out, f)
  #   }, error = function(e) {
  #     print(e$message)
  #   })
}

# happened on pc, but not on my laptop. For colors in plots and terra maps.
# Error in .default.pal() : could not find function ".default.pal"
# https://github.com/rspatial/terra/blob/master/R/plot_raster.R
.default.pal <- function() {
  rev(terra::map.pal("grey"))
}
