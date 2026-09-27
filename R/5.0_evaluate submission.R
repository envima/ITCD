source("R/a0_set up environment.R")

submissions <- list.files(file.path("inp", "submission"), full.name = TRUE)
outDir <- file.path("out", "submission")

for (submission in submissions[1:3]) {
  evaluateSubmission(submission, outDir)
}

# project for Weinstein submissions
for (submission in submissions[4:5]) {
  evaluateSubmission(submission, outDir, project = TRUE)
}
