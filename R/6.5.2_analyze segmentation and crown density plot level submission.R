source("R/a0_set up environment.R")

submissions <- list.files(file.path("out", "submission"), full.name = TRUE)
path <- file.path("out", "testing", "segment", "band8_all_oval_BORD10 overlap24 segment76", "imageCrowns_submissionCommon.RDS")
submissions <- c(submissions, path)

plots <- list()
for (submission in submissions) {
  f <- tools::file_path_sans_ext(basename(submission))
  results <- readRDS(submission)

  results$plot_level$F1score <- 2 * results$plot_level$precision * results$plot_level$recall / (results$plot_level$precision + results$plot_level$recall + 1e-7)

  # calculate site density
  dfEval <- read.csv(file.path("out", "analysis", "dfCrownsPerPlot.csv"))
  dfEval$density <- dfEval$crowns / (0.4 * 0.4) # crown per km^2

  # merge data
  df <- merge(dfEval, results$plot_level, by.x = "plot", by.y = "plot_name")

  # plot F1 vs tree crown density
  library(ggplot2)

  map_plot <- ggplot() +
    geom_point(data = df, aes(x = density, y = F1score), shape = 1, size = 1.5) + # Points
    ggtitle(gsub("imageCrowns_", "", f)) +
    ylim(0, 1) +
    xlim(0, 600) +
    labs(x = expression("Crowns per km"^2), y = "F1-score") + 
    theme_minimal() + # A clean theme for the map
    theme(
      panel.grid = element_blank(), # remove grid
      panel.border = element_rect(color = "black", fill = NA), # Add black frame
      axis.ticks = element_line(), # add tick
      axis.ticks.length = unit(0.15, "cm"), # outer tick
      axis.text = element_text(size = 11, color = "black"), # axis text
      text = element_text(family = "Times", color = "black"),
      plot.margin = unit(c(0.2, 0.2, 0.2, 0.2), "cm") # remove margin
    )
  plots[[f]] <- map_plot
}

plots[[6]] <- plots[[6]] +
  ggtitle("This_study")

combined <- patchwork::wrap_plots(plots, ncol = 3, nrow = 2)
f <- file.path("out", "analysis", "F1 vs crown density plot submission.jpeg")
ggsave(f, plot = combined, dpi = 300, width = 12, height = 8)
