args <- commandArgs(trailingOnly = TRUE)
modelName <- args[1]

source("R/a0_set up environment.R")

# show evaluation result
path <- file.path("out", "testing", "segment", paste0(modelName, " overlap24 segment76"), "imageCrowns_submissionAll.RDS")
results <- readRDS(path)
results

precision <- results$overall$precision
precision

recall <- results$overall$recall
recall

F1score <- 2 * precision * recall / (precision + recall)
F1score

# plot precision vs recall 
library(ggplot2)
library(ggrepel)

map_plot <- ggplot() +
  geom_point(data = results$by_site, aes(x = precision, y = recall), shape = 1, size = 1.5) + # Points
  ylim(0, 0.75) +
  xlim(0, 0.75) +
  geom_text_repel(data = results$by_site, vjust = 0.2, aes(x = precision, y = recall, label = Site), size = 3.8, family = "Times") + # Labels
  labs(title = NULL, x = "Precision", y = "Recall") + 
  theme_minimal() + # A clean theme for the map
  theme(
    panel.grid = element_blank(), # remove grid
    panel.border = element_rect(color = "black", fill = NA), # Add black frame
    axis.ticks = element_line(), # add tick
    axis.ticks.length = unit(0.15, "cm"), # outer tick
    axis.text = element_text(size = 11, color = "black"), # axis text
    text = element_text(family = "Times", color = "black"),
    plot.margin = unit(c(0, 0, 0, 0), "cm") # remove margin
  )

f <- file.path("out", "analysis", paste0("evaluation per site ", modelName, ".jpeg"))
ggsave(f, plot = map_plot, dpi = 300, width = 5, height = 5)
