source("R/a0_set up environment.R")

path <- file.path("out", "submission", "imageCrowns_Dalponte2016.RDS")
Dalponte2016 <- readRDS(path)
a <- Dalponte2016$plot_level$plot_name
print(length(a))

crowns <- c()
for (i in a) {
  xmlPath <- file.path("inp", "testing", "annotations", paste0(i, ".xml"))
  dopPath <- file.path("inp", "testing", "RGB", paste0(i, ".tif"))

  im <- raster::stack(dopPath)
  dat <- dplyr::bind_rows(parallel::mclapply(xmlPath, NeonTreeEvaluation::xml_parse))
  crowns <- c(crowns, length(dat$filename))
}
out <- data.frame(plot = a, crowns)

write.csv(out, file.path("out", "analysis", "dfCrownsPerPlot.csv"), row.names = FALSE)
