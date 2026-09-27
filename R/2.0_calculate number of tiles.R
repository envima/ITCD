source("R/a0_set up environment.R")

# how many tiles will be generated if cropped and not mixed only?
# (for checking your storage space, for example)
inpPath <- list.files(file.path("inp", "training", "RGB"), full.name = TRUE)
a <- parallel::mclapply(inpPath, function(i) {
  tileCalculator(i, targetShape)
})
sum(unlist(a)) # 34531
