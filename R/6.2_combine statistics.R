source("R/a0_set up environment.R")

# adjust if needed
neonPath <- file.path("inp", "analysis", "NEON_Field_Site_Metadata_20240914.csv")

# read files
dfTrain <- read.csv(file.path("out", "analysis", "dfTrain.csv"))
dfEval <- read.csv(file.path("out", "analysis", "dfEval.csv"))
dfNeon <- read.csv(neonPath)
dfCompare <- read.csv(file.path("out", "analysis", "dfCompare.csv"))

# get only what we want from Neon
names(dfNeon)
a <- c("field_site_id", "field_dominant_nlcd_classes", "field_site_name")
dfNeon <- dfNeon[, a]
names(dfNeon) <- c("site", "NLCD", "siteName")

# merge them
df <- merge(dfTrain, dfEval, by = "site", all = TRUE, suffixes = c(".Train", ".Eval"))
df <- merge(df, dfNeon, all.x = TRUE)
df <- merge(df, dfCompare, all.x = TRUE)

# remove degree
# df$T <- gsub("°C", "", df$T)

# analyze temperature and precipitation
# plot(df$T, df$P, type = "n")
# text(df$T, df$P, df$site)

# remove unwanted text
df$siteName <- gsub(" NEON", "", df$siteName)

# add sum row
a <- c("sum", sum(df$tiles, na.rm = TRUE), sum(df$crowns.Train, na.rm = TRUE), sum(df$files, na.rm = TRUE), sum(df$crowns.Eval, na.rm = TRUE), "", "", sum(df$files.compare, na.rm = TRUE))
df <- rbind(df, a)

# replalce NA
df[is.na(df)] <- "-"

# get needed in order
df <- df[, c("site", "crowns.Train", "tiles", "crowns.Eval", "files", "files.compare", "NLCD", "siteName")]
df

# replace separation symbol
df$NLCD <- gsub("|", ", ", df$NLCD, fixed = TRUE)

# export for latex
write.table(df[, -8], file.path("out", "analysis", "siteStatistics.txt"), row.names = FALSE, sep = "&", eol = "\\\\\n", quote = FALSE)
write.table(df[-22, c(1, 8)], file.path("out", "analysis", "siteNames.txt"), row.names = FALSE, sep = "&", eol = "\\\\\n", quote = FALSE)
