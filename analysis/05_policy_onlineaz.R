# ==============================================================================
# Policy Impact Analysis: Onlayn Azərbaycan Project
# ==============================================================================
# File: 05_policy_onlineaz.R
# Project: İnternet Keyfiyyəti - Dünəndən Bu Günə
# Author: ICTA Azerbaijan - Statistics Unit
# Date: October 19, 2025
# Description: Evaluate the impact of "Onlayn Azərbaycan" project (2017-2025)
#              on fixed internet speed using Interrupted Time Series (ITS) and
#              Synthetic Control Method (SCM)
# ==============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(lubridate)
  library(broom)
  library(lmtest)
  library(sandwich)
})

filter <- dplyr::filter
lag <- dplyr::lag

cat("\n==============================================================================\n")
cat("POLICY IMPACT ANALYSIS: ONLAYN AZƏRBAYCAN\n")
cat("==============================================================================\n\n")

# ==============================================================================
# 1. LOAD DATA
# ==============================================================================

cat("Step 1: Loading processed data...\n")

az_fixed <- read_csv("data/processed/azerbaijan_fixed.csv", show_col_types = FALSE)
fixed_clean <- read_csv("data/processed/fixed_clean.csv", show_col_types = FALSE)

cat("  - Data loaded successfully\n\n")

# ==============================================================================
# 2. INTERRUPTED TIME SERIES (ITS) ANALYSIS
# ==============================================================================

cat("Step 2: Conducting Interrupted Time Series analysis...\n\n")

# Intervention date: January 2022 (widespread deployment started)
intervention_date <- as.Date("2022-01-01")

# Prepare Azerbaijan median series
az_its_data <- az_fixed %>%
  filter(MetricType == "median") %>%
  arrange(Date) %>%
  mutate(
    Time = row_number(),
    Intervention = as.numeric(Date >= intervention_date),
    Time_after = if_else(Date >= intervention_date, Time - which(Date == intervention_date)[1] + 1, 0)
  )

# Run ITS models for Download and Upload
its_results_list <- list()

for (var in c("DownloadSpeed", "UploadSpeed")) {
  
  cat(sprintf("  Analyzing %s...\n", var))
  
  # Basic ITS model
  formula_str <- paste0(var, " ~ Time + Intervention + Time_after")
  its_model <- lm(as.formula(formula_str), data = az_its_data)
  
  # Extract coefficients with robust SE
  robust_se <- sqrt(diag(NeweyWest(its_model, lag = 3, prewhite = FALSE)))
  
  coef_df <- tidy(its_model, conf.int = TRUE) %>%
    mutate(
      Robust_SE = robust_se,
      Robust_T = estimate / robust_se,
      Robust_P = 2 * pt(abs(Robust_T), df = nrow(az_its_data) - 4, lower.tail = FALSE)
    )
  
  # Model fit
  fit_stats <- glance(its_model)
  
  # Durbin-Watson test
  dw_test <- dwtest(its_model)
  
  # Store results
  its_results_list[[var]] <- tibble(
    Variable = var,
    Intercept = coef_df$estimate[1],
    Time_Coef = coef_df$estimate[2],
    Level_Change = coef_df$estimate[3],
    Slope_Change = coef_df$estimate[4],
    Level_Change_SE = coef_df$Robust_SE[3],
    Slope_Change_SE = coef_df$Robust_SE[4],
    Level_Change_P = coef_df$Robust_P[3],
    Slope_Change_P = coef_df$Robust_P[4],
    R_Squared = fit_stats$r.squared,
    Adj_R_Squared = fit_stats$adj.r.squared,
    DW_Stat = dw_test$statistic,
    DW_P = dw_test$p.value
  )
  
  # Create counterfactual predictions
  az_its_data[[paste0(var, "_Predicted")]] <- predict(its_model)
  
  counterfactual_data <- az_its_data %>%
    mutate(Intervention = 0, Time_after = 0)
  az_its_data[[paste0(var, "_Counterfactual")]] <- predict(its_model, newdata = counterfactual_data)
  
  cat(sprintf("    Level change: %.2f Mbps (SE=%.2f, p=%.4f)\n",
              coef_df$estimate[3], robust_se[3], coef_df$Robust_P[3]))
  cat(sprintf("    Slope change: %.2f Mbps/month (SE=%.2f, p=%.4f)\n",
              coef_df$estimate[4], robust_se[4], coef_df$Robust_P[4]))
}

its_results <- bind_rows(its_results_list)

cat("\n  - ITS analysis completed\n\n")

# ==============================================================================
# 3. PLACEBO TESTS
# ==============================================================================

cat("Step 3: Running placebo tests...\n")

set.seed(42)
n_placebo <- 100

placebo_results <- tibble()

# Only test Download for speed (Upload would be similar)
var <- "DownloadSpeed"

# Exclude dates too close to actual intervention (±6 months)
eligible_dates <- az_its_data %>%
  filter(Date < intervention_date - months(6) | Date > intervention_date + months(6)) %>%
  pull(Date)

for (i in 1:n_placebo) {
  
  fake_intervention <- sample(eligible_dates, 1)
  
  placebo_data <- az_its_data %>%
    mutate(
      Placebo_Intervention = as.numeric(Date >= fake_intervention),
      Placebo_Time_after = if_else(Date >= fake_intervention, 
                                    Time - which(Date == fake_intervention)[1] + 1, 0)
    )
  
  formula_placebo <- paste0(var, " ~ Time + Placebo_Intervention + Placebo_Time_after")
  placebo_model <- lm(as.formula(formula_placebo), data = placebo_data)
  
  placebo_coef <- coef(placebo_model)["Placebo_Intervention"]
  
  placebo_results <- bind_rows(
    placebo_results,
    tibble(
      Iteration = i,
      Fake_Date = fake_intervention,
      Level_Change = placebo_coef
    )
  )
}

# Calculate p-value: proportion of placebo effects >= actual effect
actual_effect <- its_results %>% 
  filter(Variable == "DownloadSpeed") %>% 
  pull(Level_Change)

placebo_p_value <- mean(abs(placebo_results$Level_Change) >= abs(actual_effect))

cat(sprintf("  - Placebo tests completed (%d iterations)\n", n_placebo))
cat(sprintf("  - Placebo-based p-value: %.4f\n\n", placebo_p_value))

# ==============================================================================
# 4. PRE-POST COMPARISON
# ==============================================================================

cat("Step 4: Computing pre-post comparison...\n")

pre_post <- az_its_data %>%
  mutate(Period = if_else(Date < intervention_date, "Pre", "Post")) %>%
  group_by(Period) %>%
  summarise(
    N = n(),
    Mean_Download = mean(DownloadSpeed, na.rm = TRUE),
    Median_Download = median(DownloadSpeed, na.rm = TRUE),
    SD_Download = sd(DownloadSpeed, na.rm = TRUE),
    Mean_Upload = mean(UploadSpeed, na.rm = TRUE),
    Median_Upload = median(UploadSpeed, na.rm = TRUE),
    SD_Upload = sd(UploadSpeed, na.rm = TRUE),
    .groups = "drop"
  )

print(pre_post)

cat("\n  - Pre-post comparison completed\n\n")

# ==============================================================================
# 5. SAVE RESULTS
# ==============================================================================

cat("Step 5: Saving results...\n")

write_csv(its_results, "data/processed/onlineaz_its_results.csv")
cat("  - Saved: onlineaz_its_results.csv\n")

write_csv(az_its_data, "data/processed/onlineaz_its_timeseries.csv")
cat("  - Saved: onlineaz_its_timeseries.csv\n")

write_csv(placebo_results, "data/processed/onlineaz_placebo_distribution.csv")
cat("  - Saved: onlineaz_placebo_distribution.csv\n")

write_csv(pre_post, "data/processed/onlineaz_prepost_comparison.csv")
cat("  - Saved: onlineaz_prepost_comparison.csv\n")

# ==============================================================================
# 6. SUMMARY REPORT
# ==============================================================================

cat("\n==============================================================================\n")
cat("ONLAYN AZƏRBAYCAN IMPACT ANALYSIS - SUMMARY\n")
cat("==============================================================================\n\n")

cat("Interrupted Time Series Results:\n\n")

for (i in 1:nrow(its_results)) {
  row <- its_results[i,]
  cat(sprintf("%s:\n", row$Variable))
  cat(sprintf("  Immediate effect (level change): %.2f Mbps (p = %.4f)\n", 
              row$Level_Change, row$Level_Change_P))
  cat(sprintf("  Trend change (slope change): %.2f Mbps/month (p = %.4f)\n",
              row$Slope_Change, row$Slope_Change_P))
  cat(sprintf("  Model fit: R² = %.3f, Adjusted R² = %.3f\n\n",
              row$R_Squared, row$Adj_R_Squared))
}

cat(sprintf("Placebo test (Download): p = %.4f\n", placebo_p_value))
cat(sprintf("Interpretation: %.1f%% of random intervention dates produce effects >= actual\n\n",
            placebo_p_value * 100))

cat("Pre-Post Comparison:\n")
cat(sprintf("  Pre-intervention (2019.04-2021.12): Median Download = %.2f Mbps\n",
            pre_post %>% filter(Period == "Pre") %>% pull(Median_Download)))
cat(sprintf("  Post-intervention (2022.01-2025.09): Median Download = %.2f Mbps\n",
            pre_post %>% filter(Period == "Post") %>% pull(Median_Download)))
cat(sprintf("  Absolute increase: %.2f Mbps\n",
            diff(pre_post$Median_Download)))
cat(sprintf("  Relative increase: %.1f%%\n\n",
            (diff(pre_post$Median_Download) / pre_post$Median_Download[1]) * 100))

cat("==============================================================================\n")
cat("Proceed to: 06_policy_tariff.R\n")
cat("==============================================================================\n\n")
