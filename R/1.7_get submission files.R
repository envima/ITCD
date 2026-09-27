source("R/a0_set up environment.R")

# see if different versions in the repo are the same
## compare Dalponte2016
analysisDir <- file.path("..", "NeonTreeEvaluation_analysis")
Dalponte2016 <- file.path(analysisDir, "Dalponte2016", "Dalponte2016.csv")
Dalponte2016s <- file.path(analysisDir, "Submissions", "Dalponte2016.csv")
Dalponte2016 <- read.csv(Dalponte2016)
Dalponte2016s <- read.csv(Dalponte2016s)
table(Dalponte2016 == Dalponte2016s)
#  TRUE
# 73180

## compare Li2012
analysisDir <- file.path("..", "NeonTreeEvaluation_analysis")
Li2012 <- file.path(analysisDir, "Li2012", "Li2012.csv")
Li2012s <- file.path(analysisDir, "Submissions", "Li2012.csv")
Li2012 <- read.csv(Li2012)
Li2012s <- read.csv(Li2012s)
table(Li2012 == Li2012s)
#   TRUE
# 120040

## compare Silva2016
analysisDir <- file.path("..", "NeonTreeEvaluation_analysis")
Silva2016 <- file.path(analysisDir, "Silva2016", "Silva2016.csv")
Silva2016s <- file.path(analysisDir, "Submissions", "Silva2016.csv")
Silva2016 <- read.csv(Silva2016)
Silva2016s <- read.csv(Silva2016s)
table(Silva2016 == Silva2016s)
#  TRUE
# 65325

# copy to IPO
files_to_copy <- list.files(file.path(analysisDir, "Submissions"), full.name = TRUE)
outDir <- file.path("inp", "submission")
file.copy(files_to_copy, outDir, overwrite = TRUE)
