source("R/a2_set up tensorflow.R")
source("R/a1_set up terra.R")
source("R/a0_set up environment.R")

# sets all random seeds needed to make TensorFlow code reproducible
# this also sets the R random seed set.seed()
tensorflow::set_random_seed(42)

# for GPU also running deterministically
tensorflow::tf$config$experimental$enable_op_determinism()

imageDir <- file.path("out", "training", "image 128 oval")
maskDir <- file.path("out", "training", "mask 128 oval")
weightDir <- file.path("out", "training", "weight 128 oval BORD10")
outDir <- file.path("out", "training", "model", "band8_all_oval_BORD10")

model <- unet(c(targetShape, 8), weighted = TRUE, num_layers = 4)
optimizer <- keras::optimizer_sgd(learning_rate = 0.001, momentum = 0.99)
loss <- myLoss_mean()
metrics <- "accuracy"

epochs <- 50
callbacks <- list(
  keras::callback_early_stopping(
    monitor = "val_loss",
    min_delta = 1e-4,
    patience = 5,
    verbose = 1,
    restore_best_weights = TRUE
  ),
  keras::callback_model_checkpoint(
    file.path(outDir, "checkpoint.ckpt"),
    verbose = 1,
    save_weights_only = TRUE,
    save_best_only = TRUE
  )
)

trainingHistory <- myTrain(
  imageDir, maskDir, weightDir, outDir,
  model, optimizer, loss, metrics,
  batch_size, epochs, callbacks,
  class_weight = NULL, augment = TRUE, weighted = TRUE,
  useBands = selectedBands[1:8]
)
