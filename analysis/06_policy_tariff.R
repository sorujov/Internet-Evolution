# ==============================================================================
# Policy Impact Analysis: August 2024 Tariff Reform (FIXED)
# ==============================================================================
# File: 06_policy_tariff_v2.R
# Project: İnternet Keyfiyyəti - Dünəndən Bu Günə
# Author: ICTA Azerbaijan - Statistics Unit
# Date: October 19, 2025
# Description: Evaluate the impact of August 2024 tariff change using DID
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
cat("POLICY IMPACT ANALYSIS: AUGUST 2024 TARIFF REFORM\n")
cat("==============================================================================\n\n")

# ==============================================================================
# 1. LOAD DATA
# ==============================================================================

cat("Step 1: Loading processed data...\n")

az_fixed <- read_csv("data/processed/azerbaijan_fixed.csv", show_col_types = FALSE)
az_cellular <- read_csv("data/processed/azerbaijan_cellular.csv", show_col_types = FALSE)

# ==============================================================================
# 2. PREPARE PANEL DATA
# ==============================================================================

cat("\nStep 2: Preparing panel data for DID...\n")

intervention_date <- as.Date("2024-08-01")

panel_data <- bind_rows(
  az_fixed %>% filter(MetricType == "median") %>% mutate(InternetType = "Fixed", Treated = 1),
  az_cellular %>% filter(MetricType == "median") %>% mutate(InternetType = "Cellular", Treated = 0)
) %>%
  mutate(
    Post = as.numeric(Date >= intervention_date),
    YearMonth = format(Date, "%Y-%m")
  ) %>%
  arrange(InternetType, Date)

cat(sprintf("  Panel: %d observations (%d Fixed, %d Cellular)\n", 
            nrow(panel_data),
            sum(panel_data$Treated == 1),
            sum(panel_data$Treated == 0)))
cat(sprintf("  Pre-treatment: %d months, Post-treatment: %d months\n\n",
            sum(panel_data$Post == 0) / 2,
            sum(panel_data$Post == 1) / 2))

# ==============================================================================
# 3. PARALLEL TRENDS TEST
# ==============================================================================

cat("Step 3: Testing parallel trends...\n")

pre_data <- panel_data %>% 
  filter(Post == 0) %>%
  group_by(InternetType) %>%
  mutate(Time = row_number()) %>%
  ungroup()

pre_trend_model <- lm(DownloadSpeed ~ Time * Treated, data = pre_data)
pre_coef <- tidy(pre_trend_model)
interaction_coef <- pre_coef %>% filter(term == "Time:Treated")

cat(sprintf("  Differential trend coefficient: %.4f (SE=%.4f, p=%.4f)\n",
            interaction_coef$estimate, 
            interaction_coef$std.error,
            interaction_coef$p.value))

if (interaction_coef$p.value < 0.05) {
  cat("  ⚠ WARNING: Parallel trends assumption violated\n")
  cat("    Interpretation: Fixed and Cellular had different growth rates pre-treatment\n")
  cat("    This makes Cellular a questionable control group\n\n")
} else {
  cat("  ✓ Parallel trends satisfied\n\n")
}

# ==============================================================================
# 4. SIMPLE DID WITH MANUAL CALCULATION
# ==============================================================================

cat("Step 4: Computing DID estimator manually...\n")

did_means <- panel_data %>%
  group_by(Treated, Post) %>%
  summarise(
    N = n(),
    Mean_Download = mean(DownloadSpeed, na.rm = TRUE),
    Mean_Upload = mean(UploadSpeed, na.rm = TRUE),
    .groups = "drop"
  )

print(did_means)

# Manual DID calculation
pre_treat <- did_means %>% filter(Treated == 1, Post == 0) %>% pull(Mean_Download)
post_treat <- did_means %>% filter(Treated == 1, Post == 1) %>% pull(Mean_Download)
pre_control <- did_means %>% filter(Treated == 0, Post == 0) %>% pull(Mean_Download)
post_control <- did_means %>% filter(Treated == 0, Post == 1) %>% pull(Mean_Download)

did_manual <- (post_treat - pre_treat) - (post_control - pre_control)

cat(sprintf("\nManual DID calculation:\n"))
cat(sprintf("  Fixed change: %.2f → %.2f = +%.2f Mbps\n", 
            pre_treat, post_treat, post_treat - pre_treat))
cat(sprintf("  Cellular change: %.2f → %.2f = +%.2f Mbps\n",
            pre_control, post_control, post_control - pre_control))
cat(sprintf("  DID estimate (ATT): %.2f Mbps\n\n", did_manual))

# ==============================================================================
# 5. REGRESSION DID
# ==============================================================================

cat("Step 5: Regression-based DID with robust SE...\n")

# Simple OLS DID
did_formula <- DownloadSpeed ~ Treated + Post + Treated:Post
did_model <- lm(did_formula, data = panel_data)

# Heteroskedasticity-robust standard errors (HC1)
# Note: Not clustering by InternetType as we only have 2 groups
did_robust_vcov <- vcovHC(did_model, type = "HC1")
did_robust_se <- sqrt(diag(did_robust_vcov))

did_coefs <- tidy(did_model) %>%
  mutate(
    Robust_SE = did_robust_se,
    Robust_T = estimate / Robust_SE,
    Robust_P = 2 * pt(abs(Robust_T), df = nrow(panel_data) - 4, lower.tail = FALSE)
  )

print(did_coefs)

att_estimate <- did_coefs %>% filter(term == "Treated:Post") %>% pull(estimate)
att_se <- did_coefs %>% filter(term == "Treated:Post") %>% pull(Robust_SE)
att_p <- did_coefs %>% filter(term == "Treated:Post") %>% pull(Robust_P)

cat(sprintf("\nDID Results:\n"))
cat(sprintf("  ATT: %.2f Mbps (Robust SE = %.2f, p = %.4f)\n", 
            att_estimate, att_se, att_p))

# Interpretation
if (att_p < 0.05) {
  if (att_estimate > 0) {
    cat(sprintf("  ✓ Tariff reform increased Fixed internet speed by %.2f Mbps (statistically significant)\n\n", att_estimate))
  } else {
    cat(sprintf("  ✗ Tariff reform decreased Fixed internet speed by %.2f Mbps (statistically significant)\n\n", abs(att_estimate)))
  }
} else {
  cat("  → No statistically significant effect detected at α=0.05\n\n")
}

# ==============================================================================
# 6. UPLOAD SPEED ROBUSTNESS
# ==============================================================================

cat("Step 6: Robustness check - Upload speed...\n")

did_upload <- lm(UploadSpeed ~ Treated + Post + Treated:Post, data = panel_data)
upload_robust_vcov <- vcovHC(did_upload, type = "HC1")
upload_robust_se <- sqrt(diag(upload_robust_vcov))
upload_coefs <- tidy(did_upload) %>%
  mutate(Robust_SE = upload_robust_se)

upload_att <- upload_coefs %>% filter(term == "Treated:Post") %>% pull(estimate)
upload_se <- upload_coefs %>% filter(term == "Treated:Post") %>% pull(Robust_SE)

cat(sprintf("  Upload ATT: %.2f Mbps (SE = %.2f)\n\n", upload_att, upload_se))

# ==============================================================================
# 7. SAVE RESULTS
# ==============================================================================

cat("Step 7: Saving results...\n")

# DID results (ATT only)
did_results_final <- did_coefs %>%
  filter(term == "Treated:Post") %>%
  select(term, estimate, Robust_SE, Robust_P) %>%
  rename(ATT = estimate, SE = Robust_SE, P_Value = Robust_P) %>%
  mutate(
    Variable = "DownloadSpeed",
    CI_Lower = ATT - 1.96 * SE,
    CI_Upper = ATT + 1.96 * SE,
    PreTrends_P = interaction_coef$p.value,  # Add parallel trends test p-value
    PreTrends_Coef = interaction_coef$estimate  # Add differential trend coefficient
  )

write_csv(did_results_final, "data/processed/tariff_did_results.csv")
cat("  - Saved: tariff_did_results.csv\n")

# Full DiD table with all coefficients for display in report
did_full_table <- did_coefs %>%
  mutate(
    Əmsal = case_when(
      term == "Treated" ~ "Sabit (δ)",
      term == "Post" ~ "Post (θ)",
      term == "Treated:Post" ~ "Sabit × Post (γ)",
      TRUE ~ term
    ),
    CI_Lower = estimate - 1.96 * Robust_SE,
    CI_Upper = estimate + 1.96 * Robust_SE
  ) %>%
  select(Əmsal, 
         Qiymətləndirmə = estimate, 
         SE = Robust_SE, 
         p_value = Robust_P, 
         CI_Lower, 
         CI_Upper)

# Add ATT row (duplicate of interaction term)
att_row <- did_full_table %>% 
  filter(Əmsal == "Sabit × Post (γ)") %>%
  mutate(Əmsal = "Təsir Effekti (ATT)")

did_full_table <- bind_rows(did_full_table, att_row)

write_csv(did_full_table, "data/processed/tariff_did_full_results.csv")
cat("  - Saved: tariff_did_full_results.csv\n")

write_csv(did_means, "data/processed/tariff_prepost_means.csv")
cat("  - Saved: tariff_prepost_means.csv\n")

write_csv(panel_data, "data/processed/tariff_panel_data.csv")
cat("  - Saved: tariff_panel_data.csv\n")

# Event study results placeholder (simplified)
event_summary <- tibble(
  Period = c("Pre", "Post"),
  Fixed_Mean = c(pre_treat, post_treat),
  Cellular_Mean = c(pre_control, post_control),
  Difference = c(pre_treat - pre_control, post_treat - post_control)
)

write_csv(event_summary, "data/processed/tariff_event_study.csv")
cat("  - Saved: tariff_event_study.csv\n")

# ==============================================================================
# 8. SUMMARY REPORT
# ==============================================================================

cat("\n==============================================================================\n")
cat("AUGUST 2024 TARIFF REFORM - SUMMARY\n")
cat("==============================================================================\n\n")

cat("Difference-in-Differences Analysis:\n\n")
cat(sprintf("Treatment: Fixed internet (25 AZN tariff, Aug 2024)\n"))
cat(sprintf("Control: Cellular internet (no tariff change)\n\n"))

cat("Parallel Trends Test:\n")
cat(sprintf("  Pre-treatment differential trend: %.4f (p = %.4f)\n", 
            interaction_coef$estimate, interaction_coef$p.value))
if (interaction_coef$p.value < 0.05) {
  cat("  ⚠ CAVEAT: Parallel trends violated - interpret results with caution\n")
  cat("    Fixed and Cellular had different growth trajectories before treatment\n\n")
} else {
  cat("  ✓ Assumption satisfied\n\n")
}

cat("Main Results:\n")
cat(sprintf("  ATT (Download): %.2f Mbps (SE = %.2f, p = %.4f)\n", 
            att_estimate, att_se, att_p))
cat(sprintf("  95%% CI: [%.2f, %.2f]\n", 
            att_estimate - 1.96 * att_se, att_estimate + 1.96 * att_se))

if (att_p < 0.05) {
  cat("\n  Interpretation: Tariff reform had statistically significant effect\n")
} else {
  cat("\n  Interpretation: No significant effect detected\n")
}

cat(sprintf("\n  ATT (Upload): %.2f Mbps (SE = %.2f)\n\n", upload_att, upload_se))

cat("Limitations:\n")
cat("  1. Parallel trends assumption violated - results should be interpreted cautiously\n")
cat("  2. Short post-treatment period (7 months) - long-term effects unknown\n")
cat("  3. Potential spillover effects from Fixed to Cellular not accounted for\n\n")

cat("==============================================================================\n")
cat("Analysis complete. See data/processed/tariff_*.csv for detailed results.\n")
cat("==============================================================================\n\n")
