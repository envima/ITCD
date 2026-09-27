source("R/a0_set up environment.R")

# read submission results
submissions <- list.files(file.path("out", "submission"), full.name = TRUE)
for (submission in submissions) {
  f <- tools::file_path_sans_ext(basename(submission))
  path <- file.path("out", "submission", paste0(f, ".RDS"))
  results <- readRDS(path)
  assign(substr(f, 13, nchar(f)), results)
}

# read my previous results


# read my results
path <- file.path("out", "testing", "segment", "band8_all_oval_BORD10 overlap24 segment76", "imageCrowns_submissionCommon.RDS")
This_study <- readRDS(path)

# overall
overall <- rbind(This_study$overall, Dalponte2016$overall, Li2012$overall, Silva2016$overall, Weinstein_unpublished$overall, Weinstein2019$overall)
submission <- c("This_study", "Dalponte2016", "Li2012", "Silva2016", "Weinstein_unpublished", "Weinstein2019")
overall <- cbind(submission, overall)

overall
#              submission  precision    recall
# 1            This_study 0.62812698 0.6563968
# 2          Dalponte2016 0.31566667 0.5972857
# 3                Li2012 0.07788889 0.2659365
# 4             Silva2016 0.32352381 0.5822222
# 5 Weinstein_unpublished 0.71807937 0.8287778
# 6         Weinstein2019 0.62993651 0.7976508

# plot
library(ggplot2)
library(ggrepel)

map_plot <- ggplot() +
  geom_point(data = overall, aes(x = precision, y = recall), shape = 1, size = 1.5) + # Points
  ylim(0, 1) +
  xlim(0, 1) +
  geom_text_repel(data = overall, vjust = 0.2, aes(x = precision, y = recall, label = submission), size = 3.8, family = "Times") + # Labels
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

f <- file.path("out", "analysis", "compare submissions.jpeg")
ggsave(f, plot = map_plot, dpi = 300, width = 5, height = 5)
