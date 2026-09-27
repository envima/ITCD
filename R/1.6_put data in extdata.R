source("R/a0_set up environment.R")

# edit if needed
extdataDir <- "~/micromamba/envs/ITCD/lib/R/library/NeonTreeEvaluation/extdata"

# define paths
annotationsDir <- file.path("inp", "testing", "annotations")
rgbDir <- file.path("inp", "testing", "RGB")

# create folder structure in extdata of the package
foldersToCreate <- c(
  "NeonTreeEvaluation",
  "NeonTreeEvaluation/annotations",
  "NeonTreeEvaluation/evaluation",
  "NeonTreeEvaluation/evaluation/RGB"
)

for (i in foldersToCreate) {
  f <- file.path(extdataDir, i)
  if (!dir.exists(f)) {
    dir.create(f)
  }
}

# annotations
files_to_copy <- list.files(annotationsDir, full.name = TRUE)
outDir <- file.path(extdataDir, "NeonTreeEvaluation", "annotations")

file.copy(files_to_copy, outDir, overwrite = TRUE)

# RGB
files_to_copy <- list.files(rgbDir, full.name = TRUE)
outDir <- file.path(extdataDir, "NeonTreeEvaluation", "evaluation", "RGB")

file.copy(files_to_copy, outDir, overwrite = TRUE)
