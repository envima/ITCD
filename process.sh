# shell script creation
modelName="band8_all_oval_BORD10"

Rscript "sh creator.R" cpu "2.1.0_prepare training data mask" "oval"
Rscript "sh creator.R" cpu "2.1.1_prepare training data weight" "oval BORD10"
Rscript "sh creator.R" cpu "2.1.2_prepare training data image" "oval"
Rscript "sh creator.R" gpu "2.3_train ${modelName}"
Rscript "sh creator.R" cpu "4.0.0_prepare testing data mask"
Rscript "sh creator.R" cpu "4.0.1_prepare testing data image"
Rscript "sh creator.R" gpu "4.1_predict" ${modelName}
Rscript "sh creator.R" cpu "4.4.0_segment" ${modelName}
Rscript "sh creator.R" cpu "4.4.1_generate submission" "${modelName} All"
Rscript "sh creator.R" cpu "4.4.2_evaluate submission" "${modelName} All"
Rscript "sh creator.R" cpu "4.4.1_generate submission" "${modelName} Common"
Rscript "sh creator.R" cpu "4.4.2_evaluate submission" "${modelName} Common"
Rscript "sh creator.R" cpu "5.0_evaluate submission"

# Set up
Rscript "R/0.0_set up folder.R"
# put function.R under [your_rootDir]/pro
Rscript "R/0.1_download files.R"

# Data selection
Rscript "R/1.0_get common training files.R"
Rscript "R/1.1_get common testing files.R"
Rscript "R/1.2_analyze training data.R"
Rscript "R/1.3_analyze testing data.R"
Rscript "R/1.4_analyze training and testing data.R"
Rscript "R/1.5_remove invalid files.R"
Rscript "R/1.6_put data in extdata.R"
Rscript "R/1.7_get submission files.R"
Rscript "R/2.0_calculate number of tiles.R"

# Data pre-processing - Training tiles
sbatch "sh/2.1.0_prepare training data mask oval.sh"
sbatch "sh/2.1.1_prepare training data weight oval BORD10.sh"
sbatch "sh/2.1.2_prepare training data image oval.sh"
Rscript "R/2.2_visualize training tiles.R" "oval" "BORD10" # Fig. 3
Rscript "R/6.7_oval annotation.R" # Fig. 2

# Training
sbatch "sh/2.3_train ${modelName}.sh"
Rscript "R/6.4_trainingHistory.R" ${modelName} # after 2.3; Fig. A.2

# Data pre-processing - Testing tiles
sbatch "sh/4.0.0_prepare testing data mask.sh"
sbatch "sh/4.0.1_prepare testing data image.sh"
Rscript "R/4.0.2_visualize testing tiles.R"

# Predict
sbatch "sh/4.1_predict ${modelName}.sh"

# Post-processing
sbatch "sh/4.4.0_segment ${modelName}.sh"
Rscript "R/6.6_visualize segmentation selected.R" ${modelName} # Fig. 6

# Delineation results
sbatch "sh/4.4.1_generate submission ${modelName} All.sh"
sbatch "sh/4.4.2_evaluate submission ${modelName} All.sh"
Rscript "R/4.6_analyze segmentation.R" $modelName # Fig. 4

# Comparison with other results
sbatch "sh/5.0_evaluate submission.sh"
Rscript "R/5.1_find common submission.R"
sbatch "sh/4.4.1_generate submission ${modelName} Common.sh"
sbatch "sh/4.4.2_evaluate submission ${modelName} Common.sh"
Rscript "R/5.2_compare submission results.R" # Fig. 7

# Analyses
Rscript "R/6.0_get training statistics.R" # after 2.1.0
Rscript "R/6.1_get testing statistics.R" # after 1.5
Rscript "R/6.2_combine statistics.R" # after 5.1; Table A.1, Table A.2
Rscript "R/6.3_location.R" # after 6.2; Fig. 1
Rscript "R/6.5.0_analyze segmentation and crown density.R" $modelName # Fig. 5
Rscript "R/6.5.1_tree density of common testing plots.R" $modelName
Rscript "R/6.5.2_analyze segmentation and crown density plot level submission.R" $modelName # Fig. A.3
