# ==============================================================================
# Trend Analysis Script
# ==============================================================================
# File: 03_trend_analysis.R
# Project: İnternet Keyfiyyəti - Dünəndən Bu Günə
# Author: ICTA Azerbaijan - Statistics Unit
# Date: October 17, 2025
# Description: Perform trend analysis and growth rate calculations
# ==============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(lubridate)
  library(broom)
})

# Resolve namespace conflicts
filter <- dplyr::filter
lag <- dplyr::lag

cat("\n==============================================================================\n")
cat("TREND ANALYSIS - INTERNET QUALITY ANALYSIS\n")
cat("==============================================================================\n\n")

# ==============================================================================
# 1. LOAD PROCESSED DATA
# ==============================================================================

cat("Step 1: Loading processed data...\n")

az_fixed <- read_csv("data/processed/azerbaijan_fixed.csv", show_col_types = FALSE)
az_cellular <- read_csv("data/processed/azerbaijan_cellular.csv", show_col_types = FALSE)

cat("  - Azerbaijan datasets loaded successfully\n\n")

# ==============================================================================
# 2. PREPARE TREND DATA
# ==============================================================================

cat("Step 2: Preparing data for trend analysis...\n")

# Fixed Internet - median values only
fixed_trend <- az_fixed %>%
  filter(MetricType == "median") %>%
  arrange(Date) %>%
  mutate(
    TimeIndex = row_number(),
    MonthsSinceStart = as.numeric(difftime(Date, min(Date), units = "days")) / 30.44
  )

# Cellular Internet - median values only
cellular_trend <- az_cellular %>%
  filter(MetricType == "median") %>%
  arrange(Date) %>%
  mutate(
    TimeIndex = row_number(),
    MonthsSinceStart = as.numeric(difftime(Date, min(Date), units = "days")) / 30.44
  )

cat("  - Trend data prepared\n")
cat("  - Fixed Internet: ", nrow(fixed_trend), " observations\n")
cat("  - Cellular Internet: ", nrow(cellular_trend), " observations\n\n")

# ==============================================================================
# 3. LINEAR REGRESSION MODELS
# ==============================================================================

cat("Step 3: Fitting linear regression models...\n")

# Fixed Internet Models
fixed_download_model <- lm(DownloadSpeed ~ TimeIndex, data = fixed_trend)
fixed_upload_model <- lm(UploadSpeed ~ TimeIndex, data = fixed_trend)

# Cellular Internet Models
cellular_download_model <- lm(DownloadSpeed ~ TimeIndex, data = cellular_trend)
cellular_upload_model <- lm(UploadSpeed ~ TimeIndex, data = cellular_trend)

cat("  - All regression models fitted\n\n")

# ==============================================================================
# 4. EXTRACT MODEL STATISTICS
# ==============================================================================

cat("Step 4: Extracting model statistics...\n")

# Fixed Internet Results
fixed_results <- tibble(
  Type = "Fixed",
  Metric = c("Download", "Upload"),
  Slope = c(
    coef(fixed_download_model)[2],
    coef(fixed_upload_model)[2]
  ),
  Intercept = c(
    coef(fixed_download_model)[1],
    coef(fixed_upload_model)[1]
  ),
  RSquared = c(
    summary(fixed_download_model)$r.squared,
    summary(fixed_upload_model)$r.squared
  ),
  PValue = c(
    summary(fixed_download_model)$coefficients[2, 4],
    summary(fixed_upload_model)$coefficients[2, 4]
  ),
  MonthlyIncrease = c(
    coef(fixed_download_model)[2],
    coef(fixed_upload_model)[2]
  )
)

# Cellular Internet Results
cellular_results <- tibble(
  Type = "Cellular",
  Metric = c("Download", "Upload"),
  Slope = c(
    coef(cellular_download_model)[2],
    coef(cellular_upload_model)[2]
  ),
  Intercept = c(
    coef(cellular_download_model)[1],
    coef(cellular_upload_model)[1]
  ),
  RSquared = c(
    summary(cellular_download_model)$r.squared,
    summary(cellular_upload_model)$r.squared
  ),
  PValue = c(
    summary(cellular_download_model)$coefficients[2, 4],
    summary(cellular_upload_model)$coefficients[2, 4]
  ),
  MonthlyIncrease = c(
    coef(cellular_download_model)[2],
    coef(cellular_upload_model)[2]
  )
)

# Combine results
trend_results <- bind_rows(fixed_results, cellular_results)

cat("\nTrend Analysis Results:\n")
print(trend_results)

# ==============================================================================
# 5. GROWTH RATE ANALYSIS
# ==============================================================================

cat("\n\nStep 5: Computing growth rates...\n")

# Function to calculate growth rate
calculate_growth <- function(data) {
  first_value <- first(data$DownloadSpeed)
  last_value <- last(data$DownloadSpeed)
  first_upload <- first(data$UploadSpeed)
  last_upload <- last(data$UploadSpeed)

  n_years <- as.numeric(difftime(last(data$Date), first(data$Date), units = "days")) / 365.25

  tibble(
    FirstDownload = first_value,
    LastDownload = last_value,
    FirstUpload = first_upload,
    LastUpload = last_upload,
    AbsoluteGrowthDownload = last_value - first_value,
    AbsoluteGrowthUpload = last_upload - first_upload,
    PercentGrowthDownload = ((last_value - first_value) / first_value) * 100,
    PercentGrowthUpload = ((last_upload - first_upload) / first_upload) * 100,
    Years = n_years,
    CAGRDownload = ((last_value / first_value)^(1/n_years) - 1) * 100,
    CAGRUpload = ((last_upload / first_upload)^(1/n_years) - 1) * 100
  )
}

# Fixed Internet Growth
fixed_growth <- fixed_trend %>%
  calculate_growth() %>%
  mutate(Type = "Fixed", .before = 1)

# Cellular Internet Growth
cellular_growth <- cellular_trend %>%
  calculate_growth() %>%
  mutate(Type = "Cellular", .before = 1)

# Combine growth analysis
growth_analysis <- bind_rows(fixed_growth, cellular_growth)

cat("\nGrowth Rate Analysis:\n")
print(growth_analysis)

# ==============================================================================
# 6. YEAR-OVER-YEAR GROWTH
# ==============================================================================

cat("\n\nStep 6: Computing Year-over-Year growth rates...\n")

# Fixed Internet YoY
fixed_yoy <- fixed_trend %>%
  group_by(Year) %>%
  summarise(
    AvgDownload = mean(DownloadSpeed, na.rm = TRUE),
    AvgUpload = mean(UploadSpeed, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    Type = "Fixed",
    YoY_Download = (AvgDownload - dplyr::lag(AvgDownload)) / dplyr::lag(AvgDownload) * 100,
    YoY_Upload = (AvgUpload - dplyr::lag(AvgUpload)) / dplyr::lag(AvgUpload) * 100
  )

# Cellular Internet YoY
cellular_yoy <- cellular_trend %>%
  group_by(Year) %>%
  summarise(
    AvgDownload = mean(DownloadSpeed, na.rm = TRUE),
    AvgUpload = mean(UploadSpeed, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    Type = "Cellular",
    YoY_Download = (AvgDownload - dplyr::lag(AvgDownload)) / dplyr::lag(AvgDownload) * 100,
    YoY_Upload = (AvgUpload - dplyr::lag(AvgUpload)) / dplyr::lag(AvgUpload) * 100
  )

# Combine YoY
yoy_growth <- bind_rows(fixed_yoy, cellular_yoy) %>%
  arrange(Type, Year)

cat("\nYear-over-Year Growth Rates:\n")
print(yoy_growth)

# ==============================================================================
# 7. QUARTERLY TRENDS
# ==============================================================================

cat("\n\nStep 7: Computing quarterly trends...\n")

# Fixed Internet Quarterly
fixed_quarterly <- fixed_trend %>%
  group_by(Year, Quarter) %>%
  summarise(
    Type = "Fixed",
    AvgDownload = mean(DownloadSpeed, na.rm = TRUE),
    AvgUpload = mean(UploadSpeed, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(YearQuarter = paste0(Year, "-Q", Quarter))

# Cellular Internet Quarterly
cellular_quarterly <- cellular_trend %>%
  group_by(Year, Quarter) %>%
  summarise(
    Type = "Cellular",
    AvgDownload = mean(DownloadSpeed, na.rm = TRUE),
    AvgUpload = mean(UploadSpeed, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(YearQuarter = paste0(Year, "-Q", Quarter))

# Combine quarterly
quarterly_trends <- bind_rows(fixed_quarterly, cellular_quarterly) %>%
  arrange(Type, Year, Quarter)

cat("  - Quarterly trends computed\n")

# ==============================================================================
# 8. SAVE TREND ANALYSIS RESULTS
# ==============================================================================

cat("\nStep 8: Saving trend analysis results...\n")

# Save trend model results
write_csv(trend_results, "data/processed/trend_analysis_results.csv")
cat("  - Saved: data/processed/trend_analysis_results.csv\n")

# Save growth analysis
write_csv(growth_analysis, "data/processed/growth_analysis.csv")
cat("  - Saved: data/processed/growth_analysis.csv\n")

# Save YoY growth
write_csv(yoy_growth, "data/processed/yoy_growth.csv")
cat("  - Saved: data/processed/yoy_growth.csv\n")

# Save quarterly trends
write_csv(quarterly_trends, "data/processed/quarterly_trends.csv")
cat("  - Saved: data/processed/quarterly_trends.csv\n")

# ==============================================================================
# COMPLETION MESSAGE
# ==============================================================================

cat("\n==============================================================================\n")
cat("TREND ANALYSIS COMPLETED SUCCESSFULLY!\n")
cat("==============================================================================\n")
cat("\nTrend analysis files saved to: data/processed/\n")
cat("\nYou can now proceed to: 04_comparative_analysis.R\n")
cat("==============================================================================\n\n")
