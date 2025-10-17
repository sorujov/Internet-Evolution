# ==============================================================================
# Comparative Analysis Script
# ==============================================================================
# File: 04_comparative_analysis.R
# Project: İnternet Keyfiyyəti - Dünəndən Bu Günə
# Author: ICTA Azerbaijan - Statistics Unit
# Date: October 17, 2025
# Description: Compare Azerbaijan with other CIS countries
# ==============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
})

# Resolve namespace conflicts
filter <- dplyr::filter
lag <- dplyr::lag

cat("\n==============================================================================\n")
cat("COMPARATIVE ANALYSIS - INTERNET QUALITY ANALYSIS\n")
cat("==============================================================================\n\n")

# ==============================================================================
# 1. LOAD PROCESSED DATA
# ==============================================================================

cat("Step 1: Loading processed data...\n")

fixed_clean <- read_csv("data/processed/fixed_clean.csv", show_col_types = FALSE)
cellular_clean <- read_csv("data/processed/cellular_clean.csv", show_col_types = FALSE)

cat("  - All datasets loaded successfully\n\n")

# ==============================================================================
# 2. LATEST MONTH COMPARISON
# ==============================================================================

cat("Step 2: Computing latest month comparison...\n")

latest_date <- max(fixed_clean$Date, na.rm = TRUE)

# CIS Fixed Internet Comparison (Latest Month)
cis_fixed_latest <- fixed_clean %>%
  filter(MetricType == "median", Date == latest_date) %>%
  select(Country, DownloadSpeed, UploadSpeed) %>%
  arrange(desc(DownloadSpeed)) %>%
  mutate(
    Rank = row_number(),
    Type = "Fixed"
  )

# CIS Cellular Internet Comparison (Latest Month)
cis_cellular_latest <- cellular_clean %>%
  filter(MetricType == "median", Date == latest_date) %>%
  select(Country, DownloadSpeed, UploadSpeed) %>%
  arrange(desc(DownloadSpeed)) %>%
  mutate(
    Rank = row_number(),
    Type = "Cellular"
  )

cat("\nFixed Internet Rankings (", format(latest_date, "%B %Y"), "):\n")
print(cis_fixed_latest)

cat("\nCellular Internet Rankings (", format(latest_date, "%B %Y"), "):\n")
print(cis_cellular_latest)

# ==============================================================================
# 3. OVERALL PERIOD COMPARISON
# ==============================================================================

cat("\n\nStep 3: Computing overall period comparison...\n")

# Fixed Internet - Overall Average
cis_fixed_overall <- fixed_clean %>%
  filter(MetricType == "median") %>%
  group_by(Country) %>%
  summarise(
    AvgDownload = mean(DownloadSpeed, na.rm = TRUE),
    AvgUpload = mean(UploadSpeed, na.rm = TRUE),
    MinDownload = min(DownloadSpeed, na.rm = TRUE),
    MaxDownload = max(DownloadSpeed, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(desc(AvgDownload)) %>%
  mutate(Rank = row_number(), Type = "Fixed")

# Cellular Internet - Overall Average
cis_cellular_overall <- cellular_clean %>%
  filter(MetricType == "median") %>%
  group_by(Country) %>%
  summarise(
    AvgDownload = mean(DownloadSpeed, na.rm = TRUE),
    AvgUpload = mean(UploadSpeed, na.rm = TRUE),
    MinDownload = min(DownloadSpeed, na.rm = TRUE),
    MaxDownload = max(DownloadSpeed, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(desc(AvgDownload)) %>%
  mutate(Rank = row_number(), Type = "Cellular")

cat("\nOverall Period Rankings - Fixed Internet:\n")
print(cis_fixed_overall)

cat("\nOverall Period Rankings - Cellular Internet:\n")
print(cis_cellular_overall)

# ==============================================================================
# 4. GROWTH RATE COMPARISON
# ==============================================================================

cat("\n\nStep 4: Computing growth rate comparison...\n")

# Function to calculate growth by country
calculate_country_growth <- function(data, type) {
  data %>%
    filter(MetricType == "median") %>%
    group_by(Country) %>%
    arrange(Date) %>%
    summarise(
      FirstDownload = first(DownloadSpeed),
      LastDownload = last(DownloadSpeed),
      PercentGrowth = ((last(DownloadSpeed) - first(DownloadSpeed)) / first(DownloadSpeed)) * 100,
      AbsoluteGrowth = last(DownloadSpeed) - first(DownloadSpeed),
      .groups = "drop"
    ) %>%
    mutate(Type = type) %>%
    arrange(desc(PercentGrowth))
}

# Fixed Internet Growth by Country
fixed_growth_comparison <- calculate_country_growth(fixed_clean, "Fixed")

# Cellular Internet Growth by Country
cellular_growth_comparison <- calculate_country_growth(cellular_clean, "Cellular")

cat("\nGrowth Rate Comparison - Fixed Internet:\n")
print(fixed_growth_comparison)

cat("\nGrowth Rate Comparison - Cellular Internet:\n")
print(cellular_growth_comparison)

# ==============================================================================
# 5. AZERBAIJAN VS REGIONAL AVERAGE
# ==============================================================================

cat("\n\nStep 5: Azerbaijan vs Regional Average...\n")

# Fixed Internet - Regional Average
fixed_regional <- fixed_clean %>%
  filter(MetricType == "median") %>%
  group_by(Date) %>%
  summarise(
    RegionalAvgDownload = mean(DownloadSpeed, na.rm = TRUE),
    RegionalAvgUpload = mean(UploadSpeed, na.rm = TRUE),
    .groups = "drop"
  )

# Add Azerbaijan data
az_vs_regional_fixed <- fixed_clean %>%
  filter(MetricType == "median", Country == "Azerbaijan") %>%
  select(Date, AZ_Download = DownloadSpeed, AZ_Upload = UploadSpeed) %>%
  left_join(fixed_regional, by = "Date") %>%
  mutate(
    Type = "Fixed",
    Gap_Download = AZ_Download - RegionalAvgDownload,
    Gap_Upload = AZ_Upload - RegionalAvgUpload,
    PercentOfRegional_Download = (AZ_Download / RegionalAvgDownload) * 100
  )

# Cellular Internet - Regional Average
cellular_regional <- cellular_clean %>%
  filter(MetricType == "median") %>%
  group_by(Date) %>%
  summarise(
    RegionalAvgDownload = mean(DownloadSpeed, na.rm = TRUE),
    RegionalAvgUpload = mean(UploadSpeed, na.rm = TRUE),
    .groups = "drop"
  )

# Add Azerbaijan data
az_vs_regional_cellular <- cellular_clean %>%
  filter(MetricType == "median", Country == "Azerbaijan") %>%
  select(Date, AZ_Download = DownloadSpeed, AZ_Upload = UploadSpeed) %>%
  left_join(cellular_regional, by = "Date") %>%
  mutate(
    Type = "Cellular",
    Gap_Download = AZ_Download - RegionalAvgDownload,
    Gap_Upload = AZ_Upload - RegionalAvgUpload,
    PercentOfRegional_Download = (AZ_Download / RegionalAvgDownload) * 100
  )

cat("  - Regional comparison computed\n")

# ==============================================================================
# 6. SAVE COMPARATIVE ANALYSIS RESULTS
# ==============================================================================

cat("\nStep 6: Saving comparative analysis results...\n")

# Save latest month comparison
write_csv(bind_rows(cis_fixed_latest, cis_cellular_latest), 
          "data/processed/cis_comparison_latest.csv")
cat("  - Saved: data/processed/cis_comparison_latest.csv\n")

# Save overall comparison
write_csv(bind_rows(cis_fixed_overall, cis_cellular_overall), 
          "data/processed/cis_comparison_overall.csv")
cat("  - Saved: data/processed/cis_comparison_overall.csv\n")

# Save growth comparison
write_csv(bind_rows(fixed_growth_comparison, cellular_growth_comparison), 
          "data/processed/cis_growth_comparison.csv")
cat("  - Saved: data/processed/cis_growth_comparison.csv\n")

# Save Azerbaijan vs Regional
write_csv(bind_rows(az_vs_regional_fixed, az_vs_regional_cellular), 
          "data/processed/azerbaijan_vs_regional.csv")
cat("  - Saved: data/processed/azerbaijan_vs_regional.csv\n")

# ==============================================================================
# COMPLETION MESSAGE
# ==============================================================================

cat("\n==============================================================================\n")
cat("COMPARATIVE ANALYSIS COMPLETED SUCCESSFULLY!\n")
cat("==============================================================================\n")
cat("\nComparative analysis files saved to: data/processed/\n")
cat("\nAll analysis scripts completed! Ready for report generation.\n")
cat("==============================================================================\n\n")
