# read arguments
args <- commandArgs(trailingOnly = TRUE)
puType <- args[1]
filename <- args[2]

# setting
path <- "~/Downloads/repos/ITCD"
setwd(path)

# read template file
if (puType == "cpu") {
  lines <- readLines("template cpu.sh")
} else if (puType == "gpu") {
  lines <- readLines("template gpu.sh")
}

# replace filename
lines_modified <- gsub("filename", filename, lines)

# replace params and save
if (length(args) < 3) {
  lines_modified <- gsub(" params", "", lines_modified)
  writeLines(lines_modified, file.path("sh", paste0(filename, ".sh")))
} else {
  params <- args[3]
  lines_modified <- gsub("params", params, lines_modified)
  writeLines(lines_modified, file.path("sh", paste0(filename, " ", params, ".sh")))
}
