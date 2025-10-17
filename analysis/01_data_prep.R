# ==============================================================================
# Data Preparation Script
# ==============================================================================
# File: 01_data_prep.R
# Project: İnternet Keyfiyyəti - Dünəndən Bu Günə
# Author: ICTA Azerbaijan - Statistics Unit
# Date: October 17, 2025
# Description: Load, clean, and prepare internet quality data for analysis
# ==============================================================================

# Load required packages
suppressPackageStartupMessages({
  library(tidyverse)
  library(lubridate)
  library(readr)
  library(here)
})

# Resolve namespace conflicts explicitly
filter <- dplyr::filter
lag <- dplyr::lag

cat("\n==============================================================================\n")
cat("DATA PREPARATION - INTERNET QUALITY ANALYSIS\n")
cat("==============================================================================\n\n")

# Set working directory
setwd(here::here())

# ==============================================================================
# 1. LOAD RAW DATA
# ==============================================================================

cat("Step 1: Loading raw data...\n")

# Load Fixed Internet data
fixed_data <- read_csv("data/raw/Fixed.csv", 
                       show_col_types = FALSE)
cat("  - Fixed Internet data loaded: ", nrow(fixed_data), " rows\n")

# Load Cellular Internet data
cellular_data <- read_csv("data/raw/Cellular.csv",
                          show_col_types = FALSE)
cat("  - Cellular Internet data loaded: ", nrow(cellular_data), " rows\n\n")

# ==============================================================================
# 2. DATE PARSING FUNCTION
# ==============================================================================

cat("Step 2: Creating date parsing function...\n")

# Function to parse "MMM-YY" format to proper date
parse_date_custom <- function(date_str) {
  # Parse using lubridate
  parsed <- parse_date_time(date_str, orders = c("b-y", "B-y"))
  # Set to first day of month
  parsed <- floor_date(parsed, "month")
  return(parsed)
}

cat("  - Date parsing function created\n\n")

# ==============================================================================
# 3. CLEAN FIXED INTERNET DATA
# ==============================================================================

cat("Step 3: Cleaning Fixed Internet data...\n")

fixed_clean <- fixed_data %>%
  mutate(
    # Parse dates
    Date = parse_date_custom(`Aggregate Date`),
    Year = year(Date),
    Month = month(Date),
    Quarter = quarter(Date),
    YearQuarter = paste0(Year, "-Q", Quarter),
    # Create year-month string for easy reference
    YearMonth = format(Date, "%Y-%m")
  ) %>%
  # Rename columns for easier access
  rename(
    Country = Location,
    DownloadSpeed = `Download Speed Mbps`,
    UploadSpeed = `Upload Speed Mbps`,
    Latency = `Multi-Server Latency`,
    Jitter = `Multi-Server Jitter`,
    MetricType = `Metric Type`
  ) %>%
  # Add internet type column
  mutate(InternetType = "Fixed") %>%
  # Reorder columns
  select(Date, Year, Month, Quarter, YearQuarter, YearMonth,
         Country, Provider, InternetType, MetricType,
         DownloadSpeed, UploadSpeed, Latency, Jitter,
         everything())

# Check for missing values
missing_fixed <- fixed_clean %>%
  summarise(across(everything(), ~sum(is.na(.)))) %>%
  pivot_longer(everything(), names_to = "Column", values_to = "MissingCount") %>%
  filter(MissingCount > 0)

cat("  - Fixed Internet data cleaned\n")
cat("  - Date range: ", format(min(fixed_clean$Date), "%B %Y"), 
    " to ", format(max(fixed_clean$Date), "%B %Y"), "\n")
cat("  - Countries: ", n_distinct(fixed_clean$Country), "\n")
cat("  - Total observations: ", nrow(fixed_clean), "\n\n")

# ==============================================================================
# 4. CLEAN CELLULAR INTERNET DATA
# ==============================================================================

cat("Step 4: Cleaning Cellular Internet data...\n")

cellular_clean <- cellular_data %>%
  mutate(
    # Parse dates
    Date = parse_date_custom(`Aggregate Date`),
    Year = year(Date),
    Month = month(Date),
    Quarter = quarter(Date),
    YearQuarter = paste0(Year, "-Q", Quarter),
    YearMonth = format(Date, "%Y-%m")
  ) %>%
  # Rename columns
  rename(
    Country = Location,
    DownloadSpeed = `Download Speed Mbps`,
    UploadSpeed = `Upload Speed Mbps`,
    Latency = `Multi-Server Latency`,
    Jitter = `Multi-Server Jitter`,
    MetricType = `Metric Type`,
    Technology = `Technology Type`
  ) %>%
  # Add internet type column
  mutate(InternetType = "Cellular") %>%
  # Reorder columns
  select(Date, Year, Month, Quarter, YearQuarter, YearMonth,
         Country, Provider, InternetType, Technology, MetricType,
         DownloadSpeed, UploadSpeed, Latency, Jitter,
         everything())

# Check for missing values
missing_cellular <- cellular_clean %>%
  summarise(across(everything(), ~sum(is.na(.)))) %>%
  pivot_longer(everything(), names_to = "Column", values_to = "MissingCount") %>%
  filter(MissingCount > 0)

cat("  - Cellular Internet data cleaned\n")
cat("  - Date range: ", format(min(cellular_clean$Date), "%B %Y"), 
    " to ", format(max(cellular_clean$Date), "%B %Y"), "\n")
cat("  - Countries: ", n_distinct(cellular_clean$Country), "\n")
cat("  - Total observations: ", nrow(cellular_clean), "\n\n")

# ==============================================================================
# 5. CREATE AZERBAIJAN-SPECIFIC DATASETS
# ==============================================================================

cat("Step 5: Creating Azerbaijan-specific datasets...\n")

# Azerbaijan Fixed Internet
az_fixed <- fixed_clean %>% 
  filter(Country == "Azerbaijan") %>%
  arrange(Date, MetricType)

# Azerbaijan Cellular Internet
az_cellular <- cellular_clean %>% 
  filter(Country == "Azerbaijan") %>%
  arrange(Date, MetricType)

cat("  - Azerbaijan Fixed data: ", nrow(az_fixed), " observations\n")
cat("  - Azerbaijan Cellular data: ", nrow(az_cellular), " observations\n\n")

# ==============================================================================
# 6. CREATE COMBINED DATASET
# ==============================================================================

cat("Step 6: Creating combined dataset...\n")

# Combine fixed and cellular data
combined_data <- bind_rows(
  fixed_clean %>% mutate(Technology = NA_character_),
  cellular_clean
) %>%
  arrange(Country, Date, InternetType, MetricType)

cat("  - Combined dataset created: ", nrow(combined_data), " observations\n\n")

# ==============================================================================
# 7. SAVE PROCESSED DATA
# ==============================================================================

cat("Step 7: Saving processed data...\n")

# Create processed directory if it doesn't exist
dir.create("data/processed", showWarnings = FALSE, recursive = TRUE)

# Save cleaned datasets
write_csv(fixed_clean, "data/processed/fixed_clean.csv")
cat("  - Saved: data/processed/fixed_clean.csv\n")

write_csv(cellular_clean, "data/processed/cellular_clean.csv")
cat("  - Saved: data/processed/cellular_clean.csv\n")

write_csv(az_fixed, "data/processed/azerbaijan_fixed.csv")
cat("  - Saved: data/processed/azerbaijan_fixed.csv\n")

write_csv(az_cellular, "data/processed/azerbaijan_cellular.csv")
cat("  - Saved: data/processed/azerbaijan_cellular.csv\n")

write_csv(combined_data, "data/processed/combined_data.csv")
cat("  - Saved: data/processed/combined_data.csv\n\n")

# ==============================================================================
# 8. GENERATE DATA SUMMARY
# ==============================================================================

cat("Step 8: Generating data summary...\n")

# Summary statistics
data_summary <- tibble(
  Dataset = c("Fixed Internet", "Cellular Internet", "Azerbaijan Fixed", 
              "Azerbaijan Cellular", "Combined"),
  Observations = c(nrow(fixed_clean), nrow(cellular_clean), 
                   nrow(az_fixed), nrow(az_cellular), nrow(combined_data)),
  Countries = c(n_distinct(fixed_clean$Country), 
                n_distinct(cellular_clean$Country),
                1, 1, n_distinct(combined_data$Country)),
  DateFrom = c(format(min(fixed_clean$Date), "%Y-%m"),
               format(min(cellular_clean$Date), "%Y-%m"),
               format(min(az_fixed$Date), "%Y-%m"),
               format(min(az_cellular$Date), "%Y-%m"),
               format(min(combined_data$Date), "%Y-%m")),
  DateTo = c(format(max(fixed_clean$Date), "%Y-%m"),
             format(max(cellular_clean$Date), "%Y-%m"),
             format(max(az_fixed$Date), "%Y-%m"),
             format(max(az_cellular$Date), "%Y-%m"),
             format(max(combined_data$Date), "%Y-%m"))
)

# Save summary
write_csv(data_summary, "data/processed/data_summary.csv")
cat("  - Saved: data/processed/data_summary.csv\n\n")

# Print summary
print(data_summary)

# ==============================================================================
# 9. DATA QUALITY CHECK
# ==============================================================================

cat("\nStep 9: Data quality check...\n")

# Check for duplicates
dup_fixed <- fixed_clean %>%
  group_by(Date, Country, MetricType) %>%
  filter(n() > 1) %>%
  nrow()

dup_cellular <- cellular_clean %>%
  group_by(Date, Country, MetricType) %>%
  filter(n() > 1) %>%
  nrow()

cat("  - Duplicate rows in Fixed data: ", dup_fixed, "\n")
cat("  - Duplicate rows in Cellular data: ", dup_cellular, "\n")

# Check for negative values (shouldn't exist in speed data)
neg_fixed <- sum(fixed_clean$DownloadSpeed < 0 | fixed_clean$UploadSpeed < 0, na.rm = TRUE)
neg_cellular <- sum(cellular_clean$DownloadSpeed < 0 | cellular_clean$UploadSpeed < 0, na.rm = TRUE)

cat("  - Negative values in Fixed data: ", neg_fixed, "\n")
cat("  - Negative values in Cellular data: ", neg_cellular, "\n\n")

# ==============================================================================
# COMPLETION MESSAGE
# ==============================================================================

cat("==============================================================================\n")
cat("DATA PREPARATION COMPLETED SUCCESSFULLY!\n")
cat("==============================================================================\n")
cat("\nProcessed files saved to: data/processed/\n")
cat("\nYou can now proceed to: 02_descriptive_stats.R\n")
cat("==============================================================================\n\n")

# Clean up environment (optional)
# rm(fixed_data, cellular_data)


