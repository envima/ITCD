source("R/a0_set up environment.R")

# read site statistics calculated
dfSites <- read.table(file.path("out", "analysis", "siteStatistics.txt"), sep = "&", header = TRUE)
dfSites <- dfSites[dfSites$site != "sum", ]
dfSites

# read NEON data
dfNeon <- read.csv(file.path("inp", "analysis", "NEON_Field_Site_Metadata_20240914.csv"))
names(dfNeon)
a <- c("field_site_id", "field_latitude", "field_longitude")
dfNeon <- dfNeon[, a]
names(dfNeon) <- c("site", "lat", "lon")
dfNeon <- dfNeon[dfNeon$site %in% dfSites$site, ]
dfNeon

# read map file
shp_file <- sf::st_read(file.path("inp", "analysis", "ne_110m_admin_1_states_provinces", "ne_110m_admin_1_states_provinces.shp"))

# plot map
library(ggplot2)
library(ggrepel)

fontface <- rep("plain", 21)
fontface[dfSites$tiles != "-"] <- "bold"

map_plot <- ggplot() +
  geom_sf(data = shp_file, fill = NA, color = "grey") + # Map layer
  geom_point(data = dfNeon, aes(x = lon, y = lat), shape = 1, size = 1) + # Points layer
  geom_text_repel(data = dfNeon, aes(x = lon, y = lat, label = site), color = "black", size = 4, fontface = fontface, vjust = 0.1, family = "Times") + # Labels
  labs(title = NULL, x = NULL, y = NULL) + # Remove labs
  theme_minimal() + # A clean theme for the map
  theme(
    panel.grid = element_blank(), # remove grid
    panel.border = element_rect(color = "black", fill = NA), # Add black frame
    axis.ticks = element_line(), # add tick
    axis.ticks.length = unit(-0.15, "cm"), # inner tick
    axis.text = element_text(family = "Times", size = 10, color = "black"), # tick label
    plot.margin = unit(c(0, 0, 0, 0), "cm") # remove margin
  )

# save map
f <- file.path("out", "analysis", "sites.jpeg")
ggsave(f, plot = map_plot, dpi = 300, width = 6, height = 4)
