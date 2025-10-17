# ==============================================================================
# Descriptive Statistics Script
# ==============================================================================
# File: 02_descriptive_stats.R
# Project: İnternet Keyfiyyəti - Dünəndən Bu Günə
# Author: ICTA Azerbaijan - Statistics Unit
# Date: October 17, 2025
# Description: Calculate descriptive statistics for internet quality data
# ==============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(knitr)
  library(kableExtra)
})

# Resolve namespace conflicts
filter <- dplyr::filter
lag <- dplyr::lag

cat("\n==============================================================================\n")
cat("DESCRIPTIVE STATISTICS - INTERNET QUALITY ANALYSIS\n")
cat("==============================================================================\n\n")

# ==============================================================================
# 1. LOAD PROCESSED DATA
# ==============================================================================

cat("Step 1: Loading processed data...\n")

fixed_clean <- read_csv("data/processed/fixed_clean.csv", show_col_types = FALSE)
cellular_clean <- read_csv("data/processed/cellular_clean.csv", show_col_types = FALSE)
az_fixed <- read_csv("data/processed/azerbaijan_fixed.csv", show_col_types = FALSE)
az_cellular <- read_csv("data/processed/azerbaijan_cellular.csv", show_col_types = FALSE)

cat("  - All datasets loaded successfully\n\n")

# ==============================================================================
# 2. AZERBAIJAN SUMMARY STATISTICS
# ==============================================================================

cat("Step 2: Computing Azerbaijan summary statistics...\n")

# Fixed Internet Summary (using median values)
az_fixed_summary <- az_fixed %>%
  filter(MetricType == "median") %>%
  summarise(
    Type = "Fixed",
    Observations = n(),
    MeanDownload = mean(DownloadSpeed, na.rm = TRUE),
    MedianDownload = median(DownloadSpeed, na.rm = TRUE),
    SDDownload = sd(DownloadSpeed, na.rm = TRUE),
    MinDownload = min(DownloadSpeed, na.rm = TRUE),
    MaxDownload = max(DownloadSpeed, na.rm = TRUE),
    MeanUpload = mean(UploadSpeed, na.rm = TRUE),
    MedianUpload = median(UploadSpeed, na.rm = TRUE),
    SDUpload = sd(UploadSpeed, na.rm = TRUE),
    MinUpload = min(UploadSpeed, na.rm = TRUE),
    MaxUpload = max(UploadSpeed, na.rm = TRUE)
  )

# Cellular Internet Summary (using median values)
az_cellular_summary <- az_cellular %>%
  filter(MetricType == "median") %>%
  summarise(
    Type = "Cellular",
    Observations = n(),
    MeanDownload = mean(DownloadSpeed, na.rm = TRUE),
    MedianDownload = median(DownloadSpeed, na.rm = TRUE),
    SDDownload = sd(DownloadSpeed, na.rm = TRUE),
    MinDownload = min(DownloadSpeed, na.rm = TRUE),
    MaxDownload = max(DownloadSpeed, na.rm = TRUE),
    MeanUpload = mean(UploadSpeed, na.rm = TRUE),
    MedianUpload = median(UploadSpeed, na.rm = TRUE),
    SDUpload = sd(UploadSpeed, na.rm = TRUE),
    MinUpload = min(UploadSpeed, na.rm = TRUE),
    MaxUpload = max(UploadSpeed, na.rm = TRUE)
  )

# Combine summaries
az_summary <- bind_rows(az_fixed_summary, az_cellular_summary)

cat("\nAzerbaijan Summary Statistics:\n")
print(az_summary)

# ==============================================================================
# 3. CIS COUNTRIES SUMMARY
# ==============================================================================

cat("\n\nStep 3: Computing CIS countries summary statistics...\n")

# Fixed Internet by Country
cis_fixed_summary <- fixed_clean %>%
  filter(MetricType == "median") %>%
  group_by(Country) %>%
  summarise(
    Observations = n(),
    MeanDownload = mean(DownloadSpeed, na.rm = TRUE),
    MeanUpload = mean(UploadSpeed, na.rm = TRUE),
    MinDownload = min(DownloadSpeed, na.rm = TRUE),
    MaxDownload = max(DownloadSpeed, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(desc(MeanDownload))

cat("\nCIS Fixed Internet Summary (by Country):\n")
print(cis_fixed_summary)

# Cellular Internet by Country
cis_cellular_summary <- cellular_clean %>%
  filter(MetricType == "median") %>%
  group_by(Country) %>%
  summarise(
    Observations = n(),
    MeanDownload = mean(DownloadSpeed, na.rm = TRUE),
    MeanUpload = mean(UploadSpeed, na.rm = TRUE),
    MinDownload = min(DownloadSpeed, na.rm = TRUE),
    MaxDownload = max(DownloadSpeed, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(desc(MeanDownload))

cat("\nCIS Cellular Internet Summary (by Country):\n")
print(cis_cellular_summary)

# ==============================================================================
# 4. YEARLY STATISTICS FOR AZERBAIJAN
# ==============================================================================

cat("\n\nStep 4: Computing yearly statistics for Azerbaijan...\n")

# Fixed Internet by Year
az_fixed_yearly <- az_fixed %>%
  filter(MetricType == "median") %>%
  group_by(Year) %>%
  summarise(
    Type = "Fixed",
    AvgDownload = mean(DownloadSpeed, na.rm = TRUE),
    AvgUpload = mean(UploadSpeed, na.rm = TRUE),
    .groups = "drop"
  )

# Cellular Internet by Year
az_cellular_yearly <- az_cellular %>%
  filter(MetricType == "median") %>%
  group_by(Year) %>%
  summarise(
    Type = "Cellular",
    AvgDownload = mean(DownloadSpeed, na.rm = TRUE),
    AvgUpload = mean(UploadSpeed, na.rm = TRUE),
    .groups = "drop"
  )

az_yearly <- bind_rows(az_fixed_yearly, az_cellular_yearly) %>%
  arrange(Type, Year)

cat("\nAzerbaijan Yearly Statistics:\n")
print(az_yearly)

# ==============================================================================
# 5. QUARTILE ANALYSIS
# ==============================================================================

cat("\n\nStep 5: Computing quartile analysis...\n")

# Fixed Internet Quartiles
az_fixed_quartiles <- az_fixed %>%
  filter(MetricType == "median") %>%
  summarise(
    Type = "Fixed",
    Q1_Download = quantile(DownloadSpeed, 0.25, na.rm = TRUE),
    Q2_Download = quantile(DownloadSpeed, 0.50, na.rm = TRUE),
    Q3_Download = quantile(DownloadSpeed, 0.75, na.rm = TRUE),
    Q1_Upload = quantile(UploadSpeed, 0.25, na.rm = TRUE),
    Q2_Upload = quantile(UploadSpeed, 0.50, na.rm = TRUE),
    Q3_Upload = quantile(UploadSpeed, 0.75, na.rm = TRUE)
  )

# Cellular Internet Quartiles
az_cellular_quartiles <- az_cellular %>%
  filter(MetricType == "median") %>%
  summarise(
    Type = "Cellular",
    Q1_Download = quantile(DownloadSpeed, 0.25, na.rm = TRUE),
    Q2_Download = quantile(DownloadSpeed, 0.50, na.rm = TRUE),
    Q3_Download = quantile(DownloadSpeed, 0.75, na.rm = TRUE),
    Q1_Upload = quantile(UploadSpeed, 0.25, na.rm = TRUE),
    Q2_Upload = quantile(UploadSpeed, 0.50, na.rm = TRUE),
    Q3_Upload = quantile(UploadSpeed, 0.75, na.rm = TRUE)
  )

az_quartiles <- bind_rows(az_fixed_quartiles, az_cellular_quartiles)

cat("\nAzerbaijan Quartile Analysis:\n")
print(az_quartiles)

# ==============================================================================
# 6. SAVE ALL STATISTICS
# ==============================================================================

cat("\n\nStep 6: Saving statistics...\n")

# Save Azerbaijan summary
write_csv(az_summary, "data/processed/azerbaijan_summary_stats.csv")
cat("  - Saved: data/processed/azerbaijan_summary_stats.csv\n")

# Save CIS summaries
write_csv(cis_fixed_summary, "data/processed/cis_fixed_summary.csv")
cat("  - Saved: data/processed/cis_fixed_summary.csv\n")

write_csv(cis_cellular_summary, "data/processed/cis_cellular_summary.csv")
cat("  - Saved: data/processed/cis_cellular_summary.csv\n")

# Save yearly statistics
write_csv(az_yearly, "data/processed/azerbaijan_yearly_stats.csv")
cat("  - Saved: data/processed/azerbaijan_yearly_stats.csv\n")

# Save quartile analysis
write_csv(az_quartiles, "data/processed/azerbaijan_quartiles.csv")
cat("  - Saved: data/processed/azerbaijan_quartiles.csv\n")

# ==============================================================================
# COMPLETION MESSAGE
# ==============================================================================

cat("\n==============================================================================\n")
cat("DESCRIPTIVE STATISTICS COMPLETED SUCCESSFULLY!\n")
cat("==============================================================================\n")
cat("\nStatistics files saved to: data/processed/\n")
cat("\nYou can now proceed to: 03_trend_analysis.R\n")
cat("==============================================================================\n\n")
