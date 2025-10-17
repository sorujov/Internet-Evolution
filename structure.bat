@echo off
REM Internet Quality Analysis Project Setup
REM Project: Internet Keyfiyyeti - Dunenden Bu Gune
REM Author: ICTA Azerbaijan
REM Date: October 17, 2025

echo ================================================
echo Creating Internet Quality Analysis Project
echo ================================================
echo.

REM Set project name
set PROJECT_NAME=internet-quality-analysis

REM Create root directory
echo Creating project root: %PROJECT_NAME%
mkdir "%PROJECT_NAME%" 2>nul
cd "%PROJECT_NAME%"

REM Create main directories
echo Creating directory structure...
mkdir "data" 2>nul
mkdir "data\raw" 2>nul
mkdir "data\processed" 2>nul
mkdir "analysis" 2>nul
mkdir "report" 2>nul
mkdir "figures" 2>nul
mkdir "output" 2>nul
mkdir "docs" 2>nul
mkdir ".github" 2>nul

REM Create empty files in root
echo Creating root files...
type nul > "README.md"
type nul > ".gitignore"
type nul > "run_all.R"

REM Create analysis script files
echo Creating analysis scripts...
type nul > "analysis\01_data_prep.R"
type nul > "analysis\02_descriptive_stats.R"
type nul > "analysis\03_trend_analysis.R"
type nul > "analysis\04_comparative_analysis.R"

REM Create report files
echo Creating report files...
type nul > "report\article.Rmd"
type nul > "report\icta_style.css"
type nul > "report\references.bib"

REM Create documentation files
echo Creating documentation...
type nul > "docs\DOCUMENTATION.md"
type nul > "docs\DATA_DICTIONARY.md"

REM Create placeholder files
echo Creating placeholder files...
type nul > "figures\.gitkeep"
type nul > "output\.gitkeep"
type nul > "data\raw\.gitkeep"
type nul > "data\processed\.gitkeep"

REM Create file list for reference
echo Creating file list...
echo Project Structure Created > "PROJECT_STRUCTURE.txt"
echo ======================= >> "PROJECT_STRUCTURE.txt"
echo. >> "PROJECT_STRUCTURE.txt"
tree /F >> "PROJECT_STRUCTURE.txt"

echo.
echo ================================================
echo Project structure created successfully!
echo ================================================
echo.
echo Project location: %CD%
echo.
echo Next steps:
echo   1. Copy Fixed.csv and Cellular.csv to data\raw\
echo   2. Fill in the empty files with content
echo   3. Initialize Git: git init
echo   4. Start analysis pipeline
echo.
echo Files to fill:
echo   - README.md
echo   - .gitignore
echo   - analysis\01_data_prep.R
echo   - analysis\02_descriptive_stats.R
echo   - analysis\03_trend_analysis.R
echo   - analysis\04_comparative_analysis.R
echo   - report\article.Rmd
echo   - report\icta_style.css
echo   - report\references.bib
echo   - docs\DOCUMENTATION.md
echo   - run_all.R
echo.
echo ================================================

pause
