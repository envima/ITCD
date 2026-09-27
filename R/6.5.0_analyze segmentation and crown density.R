args <- commandArgs(trailingOnly = TRUE)
modelName <- args[1]

source("R/a0_set up environment.R")

# calculate F1-score
path <- file.path("out", "testing", "segment", paste0(modelName, " overlap24 segment76"), "imageCrowns_submissionAll.RDS")
results <- readRDS(path)

results$by_site$F1score <- 2 * results$by_site$precision * results$by_site$recall / (results$by_site$precision + results$by_site$recall)

# calculate site density
dfEval <- read.csv(file.path("out", "analysis", "dfEval.csv"))
dfEval$density <- dfEval$crowns / dfEval$files / (0.4 * 0.4) # crown per km^2

# merge data
df <- merge(dfEval, results$by_site, by.x = "site", by.y = "Site")

# plot F1 vs tree crown density
library(ggplot2)
library(ggrepel)

map_plot <- ggplot() +
  geom_point(data = df, aes(x = density, y = F1score), shape = 1, size = 1.5) + # Points
  ylim(0, 0.75) +
  xlim(0, 1000) +
  geom_text_repel(data = df, vjust = 0.2, aes(x = density, y = F1score, label = site), size = 3.8, family = "Times") + # Labels
  labs(title = NULL, x = expression("Crowns per km"^2), y = "F1-score") + 
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

f <- file.path("out", "analysis", paste0("F1 vs crown density ", modelName, ".jpeg"))
ggsave(f, plot = map_plot, dpi = 300, width = 5, height = 5)
