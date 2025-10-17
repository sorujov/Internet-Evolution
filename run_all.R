# ==============================================================================
# Master Script - Run All Analysis
# ==============================================================================
# File: run_all.R
# Project: İnternet Keyfiyyəti - Dünəndən Bu Günə
# Author: ICTA Azerbaijan - Statistics Unit
# Date: October 17, 2025
# ==============================================================================

cat("\n")
cat("================================================================================\n")
cat("                    INTERNET QUALITY ANALYSIS PIPELINE                         \n")
cat("                        ICTA Azerbaijan - 2025                                 \n")
cat("================================================================================\n")
cat("\n")

start_time <- Sys.time()

# Step 1: Data Preparation
cat("STEP 1/4: Data Preparation\n")
cat("--------------------------------------------------------------------------------\n")
source("analysis/01_data_prep.R")

# Step 2: Descriptive Statistics
cat("\nSTEP 2/4: Descriptive Statistics\n")
cat("--------------------------------------------------------------------------------\n")
source("analysis/02_descriptive_stats.R")

# Step 3: Trend Analysis
cat("\nSTEP 3/4: Trend Analysis\n")
cat("--------------------------------------------------------------------------------\n")
source("analysis/03_trend_analysis.R")

# Step 4: Comparative Analysis
cat("\nSTEP 4/4: Comparative Analysis\n")
cat("--------------------------------------------------------------------------------\n")
source("analysis/04_comparative_analysis.R")

# Calculate execution time
end_time <- Sys.time()
execution_time <- difftime(end_time, start_time, units = "secs")

cat("\n")
cat("================================================================================\n")
cat("                    ANALYSIS PIPELINE COMPLETED!                                \n")
cat("================================================================================\n")
cat("\nTotal execution time:", round(execution_time, 2), "seconds\n")
cat("\nAll processed data files are in: data/processed/\n")
cat("\nNext step: Generate report using report/article.Rmd\n")
cat("\nTo generate report, run:\n")
cat("  rmarkdown::render('report/article.Rmd', output_format = 'all')\n")
cat("\n")
cat("================================================================================\n\n")
