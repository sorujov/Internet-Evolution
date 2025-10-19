# ==============================================================================
# Enhanced Descriptive Statistics Script
# ==============================================================================
# File: 02_descriptive_stats_v2.R
# Project: İnternet Keyfiyyəti - Dünəndən Bu Günə
# Author: ICTA Azerbaijan - Statistics Unit
# Date: October 19, 2025
# Description: Enhanced descriptive statistics with robust measures, regression
#              diagnostics, and Mann-Kendall trend tests
# ==============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(knitr)
  library(kableExtra)
  library(lmtest)      # Durbin-Watson test
  library(sandwich)    # Robust standard errors
  library(Kendall)     # Mann-Kendall trend test
  library(broom)       # Tidy model outputs
})

# Resolve namespace conflicts
filter <- dplyr::filter
lag <- dplyr::lag

cat("\n==============================================================================\n")
cat("ENHANCED DESCRIPTIVE STATISTICS - INTERNET QUALITY ANALYSIS\n")
cat("==============================================================================\n\n")

# ==============================================================================
# HELPER FUNCTIONS
# ==============================================================================

# Compute robust statistics
compute_robust_stats <- function(data, type_label) {
  data %>%
    summarise(
      Type = type_label,
      Observations = n(),
      
      # Central tendency
      Mean_Download = mean(DownloadSpeed, na.rm = TRUE),
      Median_Download = median(DownloadSpeed, na.rm = TRUE),
      Mean_Upload = mean(UploadSpeed, na.rm = TRUE),
      Median_Upload = median(UploadSpeed, na.rm = TRUE),
      
      # Dispersion
      SD_Download = sd(DownloadSpeed, na.rm = TRUE),
      IQR_Download = IQR(DownloadSpeed, na.rm = TRUE),
      MAD_Download = mad(DownloadSpeed, na.rm = TRUE),
      SD_Upload = sd(UploadSpeed, na.rm = TRUE),
      IQR_Upload = IQR(UploadSpeed, na.rm = TRUE),
      MAD_Upload = mad(UploadSpeed, na.rm = TRUE),
      
      # Range
      Min_Download = min(DownloadSpeed, na.rm = TRUE),
      Max_Download = max(DownloadSpeed, na.rm = TRUE),
      Min_Upload = min(UploadSpeed, na.rm = TRUE),
      Max_Upload = max(UploadSpeed, na.rm = TRUE),
      
      # Percentiles
      P25_Download = quantile(DownloadSpeed, 0.25, na.rm = TRUE),
      P75_Download = quantile(DownloadSpeed, 0.75, na.rm = TRUE),
      P25_Upload = quantile(UploadSpeed, 0.25, na.rm = TRUE),
      P75_Upload = quantile(UploadSpeed, 0.75, na.rm = TRUE),
      
      # Coefficient of variation
      CV_Download = SD_Download / Mean_Download,
      CV_Upload = SD_Upload / Mean_Upload,
      
      .groups = "drop"
    )
}

# Run linear regression with diagnostics
run_regression_analysis <- function(data, type_label, metric_type_filter) {
  
  series <- data %>%
    filter(MetricType == metric_type_filter) %>%
    arrange(Date) %>%
    mutate(Time = row_number())
  
  results_list <- list()
  
  for (var in c("DownloadSpeed", "UploadSpeed")) {
    
    formula_str <- paste(var, "~ Time")
    model <- lm(as.formula(formula_str), data = series)
    
    # Basic coefficients
    coef_summary <- tidy(model, conf.int = TRUE, conf.level = 0.95)
    
    # Model fit
    glance_summary <- glance(model)
    
    # Durbin-Watson test (autocorrelation)
    dw_test <- dwtest(model)
    
    # Shapiro-Wilk test (normality of residuals)
    shapiro_test <- shapiro.test(residuals(model))
    
    # Newey-West robust standard errors
    robust_se <- sqrt(diag(NeweyWest(model, lag = 3, prewhite = FALSE)))
    
    # Compile results
    results_list[[var]] <- tibble(
      Type = type_label,
      MetricType = metric_type_filter,
      Variable = var,
      Intercept = coef_summary$estimate[1],
      Slope = coef_summary$estimate[2],
      SE_Slope = coef_summary$std.error[2],
      SE_Slope_Robust = robust_se[2],
      CI_Lower = coef_summary$conf.low[2],
      CI_Upper = coef_summary$conf.high[2],
      P_Value = coef_summary$p.value[2],
      R_Squared = glance_summary$r.squared,
      Adj_R_Squared = glance_summary$adj.r.squared,
      Residual_SE = glance_summary$sigma,
      DW_Statistic = dw_test$statistic,
      DW_PValue = dw_test$p.value,
      Shapiro_W = shapiro_test$statistic,
      Shapiro_PValue = shapiro_test$p.value
    )
  }
  
  bind_rows(results_list)
}

# Mann-Kendall trend test
run_mann_kendall <- function(data, type_label, metric_type_filter) {
  
  series <- data %>%
    filter(MetricType == metric_type_filter) %>%
    arrange(Date)
  
  results_list <- list()
  
  for (var in c("DownloadSpeed", "UploadSpeed")) {
    
    mk_result <- MannKendall(series[[var]])
    
    results_list[[var]] <- tibble(
      Type = type_label,
      MetricType = metric_type_filter,
      Variable = var,
      Tau = mk_result$tau,
      P_Value = mk_result$sl,
      S_Statistic = mk_result$S,
      Trend = case_when(
        mk_result$sl < 0.01 & mk_result$tau > 0 ~ "Significant Increasing",
        mk_result$sl < 0.01 & mk_result$tau < 0 ~ "Significant Decreasing",
        mk_result$sl < 0.05 & mk_result$tau > 0 ~ "Moderate Increasing",
        mk_result$sl < 0.05 & mk_result$tau < 0 ~ "Moderate Decreasing",
        TRUE ~ "No Significant Trend"
      )
    )
  }
  
  bind_rows(results_list)
}

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
# 2. DETAILED STATISTICS BY METRIC TYPE
# ==============================================================================

cat("Step 2: Computing detailed statistics for median and mean separately...\n")

az_detailed_stats <- bind_rows(
  az_fixed %>% filter(MetricType == "median") %>% compute_robust_stats("Fixed_Median"),
  az_fixed %>% filter(MetricType == "mean") %>% compute_robust_stats("Fixed_Mean"),
  az_cellular %>% filter(MetricType == "median") %>% compute_robust_stats("Cellular_Median"),
  az_cellular %>% filter(MetricType == "mean") %>% compute_robust_stats("Cellular_Mean")
)

print(az_detailed_stats)

# ==============================================================================
# 3. YEARLY AND QUARTERLY STATISTICS
# ==============================================================================

cat("\n\nStep 3: Computing yearly and quarterly statistics...\n")

# Yearly statistics
az_yearly_detailed <- bind_rows(
  az_fixed %>% 
    group_by(Year, MetricType) %>%
    summarise(
      Type = "Fixed",
      Avg_Download = mean(DownloadSpeed, na.rm = TRUE),
      Median_Download = median(DownloadSpeed, na.rm = TRUE),
      Avg_Upload = mean(UploadSpeed, na.rm = TRUE),
      Median_Upload = median(UploadSpeed, na.rm = TRUE),
      .groups = "drop"
    ),
  az_cellular %>%
    group_by(Year, MetricType) %>%
    summarise(
      Type = "Cellular",
      Avg_Download = mean(DownloadSpeed, na.rm = TRUE),
      Median_Download = median(DownloadSpeed, na.rm = TRUE),
      Avg_Upload = mean(UploadSpeed, na.rm = TRUE),
      Median_Upload = median(UploadSpeed, na.rm = TRUE),
      .groups = "drop"
    )
) %>% arrange(Type, MetricType, Year)

print(head(az_yearly_detailed, 10))

# Quarterly statistics
az_quarterly_detailed <- bind_rows(
  az_fixed %>%
    group_by(Year, Quarter, MetricType) %>%
    summarise(
      Type = "Fixed",
      Avg_Download = mean(DownloadSpeed, na.rm = TRUE),
      Avg_Upload = mean(UploadSpeed, na.rm = TRUE),
      .groups = "drop"
    ),
  az_cellular %>%
    group_by(Year, Quarter, MetricType) %>%
    summarise(
      Type = "Cellular",
      Avg_Download = mean(DownloadSpeed, na.rm = TRUE),
      Avg_Upload = mean(UploadSpeed, na.rm = TRUE),
      .groups = "drop"
    )
) %>% arrange(Type, MetricType, Year, Quarter)

# ==============================================================================
# 4. REGRESSION ANALYSIS WITH DIAGNOSTICS
# ==============================================================================

cat("\n\nStep 4: Running regression analysis with full diagnostics...\n")

regression_results <- bind_rows(
  run_regression_analysis(az_fixed, "Fixed", "median"),
  run_regression_analysis(az_fixed, "Fixed", "mean"),
  run_regression_analysis(az_cellular, "Cellular", "median"),
  run_regression_analysis(az_cellular, "Cellular", "mean")
)

print(regression_results)

# ==============================================================================
# 5. MANN-KENDALL TREND TESTS
# ==============================================================================

cat("\n\nStep 5: Running Mann-Kendall trend tests...\n")

mk_results <- bind_rows(
  run_mann_kendall(az_fixed, "Fixed", "median"),
  run_mann_kendall(az_fixed, "Fixed", "mean"),
  run_mann_kendall(az_cellular, "Cellular", "median"),
  run_mann_kendall(az_cellular, "Cellular", "mean")
)

print(mk_results)

# ==============================================================================
# 6. CIS COMPARATIVE STATISTICS (MEDIAN ONLY)
# ==============================================================================

cat("\n\nStep 6: Computing CIS comparative statistics...\n")

cis_fixed_summary <- fixed_clean %>%
  filter(MetricType == "median") %>%
  group_by(Country) %>%
  summarise(
    Observations = n(),
    Mean_Download = mean(DownloadSpeed, na.rm = TRUE),
    Median_Download = median(DownloadSpeed, na.rm = TRUE),
    SD_Download = sd(DownloadSpeed, na.rm = TRUE),
    IQR_Download = IQR(DownloadSpeed, na.rm = TRUE),
    Min_Download = min(DownloadSpeed, na.rm = TRUE),
    Max_Download = max(DownloadSpeed, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(desc(Median_Download))

cis_cellular_summary <- cellular_clean %>%
  filter(MetricType == "median") %>%
  group_by(Country) %>%
  summarise(
    Observations = n(),
    Mean_Download = mean(DownloadSpeed, na.rm = TRUE),
    Median_Download = median(DownloadSpeed, na.rm = TRUE),
    SD_Download = sd(DownloadSpeed, na.rm = TRUE),
    IQR_Download = IQR(DownloadSpeed, na.rm = TRUE),
    Min_Download = min(DownloadSpeed, na.rm = TRUE),
    Max_Download = max(DownloadSpeed, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(desc(Median_Download))

print(cis_fixed_summary)
print(cis_cellular_summary)

# ==============================================================================
# 7. SAVE ALL RESULTS
# ==============================================================================

cat("\n\nStep 7: Saving enhanced statistics...\n")

write_csv(az_detailed_stats, "data/processed/azerbaijan_detailed_stats.csv")
cat("  - Saved: azerbaijan_detailed_stats.csv\n")

write_csv(az_yearly_detailed, "data/processed/azerbaijan_yearly_detailed.csv")
cat("  - Saved: azerbaijan_yearly_detailed.csv\n")

write_csv(az_quarterly_detailed, "data/processed/azerbaijan_quarterly_detailed.csv")
cat("  - Saved: azerbaijan_quarterly_detailed.csv\n")

write_csv(regression_results, "data/processed/regression_diagnostics.csv")
cat("  - Saved: regression_diagnostics.csv\n")

write_csv(mk_results, "data/processed/mann_kendall_results.csv")
cat("  - Saved: mann_kendall_results.csv\n")

write_csv(cis_fixed_summary, "data/processed/cis_fixed_detailed.csv")
cat("  - Saved: cis_fixed_detailed.csv\n")

write_csv(cis_cellular_summary, "data/processed/cis_cellular_detailed.csv")
cat("  - Saved: cis_cellular_detailed.csv\n")

# ==============================================================================
# 8. SUMMARY REPORT
# ==============================================================================

cat("\n\n==============================================================================\n")
cat("ENHANCED DESCRIPTIVE STATISTICS COMPLETED\n")
cat("==============================================================================\n\n")

cat("Key Findings:\n\n")

cat("Regression Analysis (Median Series):\n")
reg_median <- regression_results %>% filter(MetricType == "median")
for (i in 1:nrow(reg_median)) {
  row <- reg_median[i,]
  cat(sprintf("  %s %s: Monthly increase = %.3f Mbps (R² = %.3f, p = %.2e)\n",
              row$Type, row$Variable, row$Slope, row$R_Squared, row$P_Value))
}

cat("\nMann-Kendall Tests (Median Series):\n")
mk_median <- mk_results %>% filter(MetricType == "median")
for (i in 1:nrow(mk_median)) {
  row <- mk_median[i,]
  cat(sprintf("  %s %s: %s (τ = %.3f, p = %.4f)\n",
              row$Type, row$Variable, row$Trend, row$Tau, row$P_Value))
}

cat("\n==============================================================================\n")
cat("All results saved to: data/processed/\n")
cat("Proceed to: 03_trend_analysis.R\n")
cat("==============================================================================\n\n")

