pythonDir <- "~/micromamba/envs/ITCD/bin/python"

# deal with interface between python and r
assignInNamespace("is_conda_python", function(x) {
  return(FALSE)
}, ns = "reticulate")
reticulate::use_python(pythonDir)

## check if gpu is available for tensorflow
tensorflow::tf$test$is_gpu_available()

## use mixed precision to save memory if possible
keras::keras$mixed_precision$set_global_policy("mixed_float16")
