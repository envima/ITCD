source("R/a0_set up environment.R")

# adjust if needed
testingDir <- file.path("..", "NeonTreeEvaluation")
trainingDir <- file.path("..", "NeonTreeEvaluation_train")
submissionDir <- file.path("..", "NeonTreeEvaluation_analysis")

# set timeout
# huge data, check timeout
orgTimeout <- getOption("timeout")
# ?download.file: It is unrealistic to require download times of less than 1s/MB.
options(timeout = max(4.5 * 1024, getOption("timeout")))

# 1. download testing data
# 3692.9 MB
download.file("https://zenodo.org/records/4770593/files/weecology/NeonTreeEvaluation-1.8.0.zip?download=1", paste0(testingDir, ".zip"))
# alternative URL: https://github.com/weecology/NeonTreeEvaluation/archive/refs/tags/1.8.0.zip

# extract testing data
unzip(paste0(testingDir, ".zip"), exdir = "..")
file.rename(from = "../weecology-NeonTreeEvaluation-d0b90bc", to = testingDir)

# for git user
# It's a huge repo, clone just what here needs
# git clone --depth 1 --branch "1.8.0" https://github.com/weecology/NeonTreeEvaluation.git "../NeonTreeEvaluation"

# or clone the whole repo
# git clone https://github.com/weecology/NeonTreeEvaluation.git "../NeonTreeEvaluation"
# cd ../NeonTreeEvaluation
# git checkout "1.8.0"

# 2. download training data
dir.create(trainingDir)
# 547 KB
download.file("https://zenodo.org/records/5914554/files/annotations.zip?download=1", file.path(trainingDir, "annotations.zip"))
# 4288.3 MB
download.file("https://zenodo.org/records/5914554/files/training.zip?download=1", file.path(trainingDir, "training.zip"))

# extract training data
unzip(file.path(trainingDir, "annotations.zip"), exdir = file.path(trainingDir, "annotations"))
unzip(file.path(trainingDir, "training.zip"), exdir = file.path(trainingDir, "training"))

# 3. download submission data
# 1.9 MB
download.file("https://github.com/weecology/NeonTreeEvaluation_analysis/archive/a426a1a6a621b67f11dc4e6cc46eb9df9d0fc677.zip", paste0(submissionDir, ".zip"))

# extract submission data
unzip(paste0(submissionDir, ".zip"), exdir = "..")
file.rename(from = "../NeonTreeEvaluation_analysis-a426a1a6a621b67f11dc4e6cc46eb9df9d0fc677", to = submissionDir)

# git clone --depth 1 --branch "a426a1a6a621b67f11dc4e6cc46eb9df9d0fc677" https://github.com/weecology/NeonTreeEvaluation_analysis.git "../NeonTreeEvaluation_analysis"

# 4. download a newer version of NEON_Field_Site_Metadata.csv if wished
# manually from https://www.neonscience.org/field-sites/explore-field-sites
# save under inp/analysis/

# 5. download map file
# manually from https://www.naturalearthdata.com/downloads/110m-cultural-vectors/
# Admin 1 – States, Provinces >  Download states and provinces (47.97 KB) version 5.1.1
# save under the same folder as IPO
unzip(file.path("..", "ne_110m_admin_1_states_provinces.zip"), exdir = file.path("inp", "analysis", "ne_110m_admin_1_states_provinces"))

# recover original timeout setting
options(timeout = orgTimeout)
