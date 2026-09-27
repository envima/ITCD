source("R/a0_set up environment.R")

# How many files are there per site?
CHMDir <- file.path("inp", "testing", "CHM")
a <- list.files(CHMDir)
a1 <- a[1:63]
a2 <- a[64:186]

a1 <- strsplit(a1, "_", fixed = TRUE)
a1 <- do.call(rbind, a1)
a1 <- a1[, c(1:3)]
a1 <- data.frame(a1)
names(a1) <- c("year", "site", "plot")

a2 <- strsplit(a2, "[._]")
a2 <- do.call(rbind, a2)
a2 <- a2[, c(1:3)]
a2 <- data.frame(a2)
names(a2) <- c("site", "plot", "year")

a <- rbind(a1, a2)

dfFiles <- dplyr::count(a, site)
names(dfFiles) <- c("site", "files")
dfFiles

# How many crowns are there per site?
# get common file names of the training data
commonPredict <- tools::file_path_sans_ext(list.files(file.path("inp", "testing", "RGB")))

site <- c()
crowns <- c()
for (i in commonPredict[1:63]) {
  xmlPath <- file.path("inp", "testing", "annotations", paste0(i, ".xml"))
  dopPath <- file.path("inp", "testing", "RGB", paste0(i, ".tif"))

  im <- raster::stack(dopPath)
  dat <- dplyr::bind_rows(parallel::mclapply(xmlPath, NeonTreeEvaluation::xml_parse))
  site <- c(site, strsplit(i, "_", fixed = TRUE)[[1]][2])
  crowns <- c(crowns, length(dat$filename))
}
dfCrowns1 <- data.frame(site, crowns)

site <- c()
crowns <- c()
for (i in commonPredict[64:186]) {
  xmlPath <- file.path("inp", "testing", "annotations", paste0(i, ".xml"))
  dopPath <- file.path("inp", "testing", "RGB", paste0(i, ".tif"))

  im <- raster::stack(dopPath)
  dat <- dplyr::bind_rows(parallel::mclapply(xmlPath, NeonTreeEvaluation::xml_parse))
  site <- c(site, strsplit(i, "_", fixed = TRUE)[[1]][1])
  crowns <- c(crowns, length(dat$filename))
}
dfCrowns2 <- data.frame(site, crowns)

a <- rbind(dfCrowns1, dfCrowns2)
dfCrowns <- aggregate(a$crowns, by = list(a$site), FUN = "sum")
names(dfCrowns) <- c("site", "crowns")
dfCrowns

# combine
dfEval <- merge(dfFiles, dfCrowns)
dfEval
write.csv(dfEval, file.path("out", "analysis", "dfEval.csv"), row.names = FALSE)
