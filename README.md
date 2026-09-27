# How to reproduce
## 1. [install micromamba](https://mamba.readthedocs.io/en/latest/installation/micromamba-installation.html)
For Linux, macOS, or Git Bash on Windows, install with:
"${SHELL}" <(curl -L micro.mamba.pm/install.sh)

Default settings during the installation was fine for me.

## 2. create environment
micromamba create -n ITCD

if you use HPC, start an interactive session:
srun --ntasks=1 --cpus-per-task=1 --mem-per-cpu=2000MB --gpus=1 --partition=short --pty bash -i

micromamba install -n ITCD -c conda-forge r-keras r-terra r-rsample tensorflow-gpu=2.15 "keras<3" cuda=12.2 cudnn=8.9 r-devtools r-sf r-lidr r-ggrepel r-raster=3.6_26 r-patchwork

## 3. install NeonTreeEvaluation in R
micromamba activate ITCD

R

devtools::install_github("Weecology/NeonTreeEvaluation_package", ref="c4d9953")

3 # do not update any package

quit()

n

micromamba deactivate

## 4. run the scripts in the created environment
follow instructions in process.sh

## 5 remove an environemnt if not needed anymore
micromamba remove --name ITCD --all

# Licence
This repository is licensed under the GNU General Public License, Version 3, or any later version.

In function.R, the function `unet` contained modification and the function `conv2d_block` contained copy from [r-tensorflow/unet]( https://github.com/r-tensorflow/unet/blob/c47cf31f13050722b587a5c394d4511d8f5e50b9/R/model.R) under the MIT License.

In function.R, the function `unet` contained modification from [keras-team/keras]( https://github.com/keras-team/keras/blob/r2.15/keras/backend.py#L5802) under the Apache License, Version 2.0.
