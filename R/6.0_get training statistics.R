source("R/a0_set up environment.R")

# How many tiles are there per site?
maskDir <- file.path("out", "training", "mask 128 oval")
a <- list.files(maskDir)
a <- strsplit(a, "_", fixed = TRUE)
a <- do.call(rbind, a)
a <- a[, c(1:3)]
a <- data.frame(a)
names(a) <- c("year", "site", "plot")
dfTiles <- dplyr::count(a, site)
names(dfTiles) <- c("site", "tiles")
dfTiles

# How many crowns are there per site?
# get common file names of the training data
commonTrain <- tools::file_path_sans_ext(list.files(file.path("inp", "training", "RGB")))

site <- c()
crowns <- c()
for (i in commonTrain) {
  xmlPath <- file.path("inp", "training", "annotations", paste0(i, ".xml"))
  dopPath <- file.path("inp", "training", "RGB", paste0(i, ".tif"))

  im <- raster::stack(dopPath)
  dat <- dplyr::bind_rows(parallel::mclapply(xmlPath, NeonTreeEvaluation::xml_parse))
  site <- c(site, strsplit(i, "_", fixed = TRUE)[[1]][2])
  crowns <- c(crowns, length(dat$filename))
}

a <- data.frame(site, crowns)
dfCrowns <- aggregate(a$crowns, by = list(a$site), FUN = "sum")
names(dfCrowns) <- c("site", "crowns")
dfCrowns

# combine
dfTrain <- merge(dfTiles, dfCrowns)
dfTrain
write.csv(dfTrain, file.path("out", "analysis", "dfTrain.csv"), row.names = FALSE)
