# Modular Report Structure

## 📁 Directory Structure

```
report/
├── article_modular.Rmd      # Main file (uses child documents)
├── article.Rmd               # Original monolithic file (backup)
├── sections/
│   ├── 01_introduction.Rmd
│   ├── 02_methodology.Rmd
│   ├── 03_fixed_internet.Rmd
│   ├── 04_mobile_internet.Rmd
│   ├── 05_regional_comparison.Rmd
│   └── 06_conclusions.Rmd
├── references.bib
└── icta_style.css
```

## ✨ Benefits of Modular Structure

### 1. **Maintainability**
- Each section is in its own file
- Easy to locate and edit specific content
- Reduces cognitive load when working on complex analysis

### 2. **Collaboration**
- Multiple team members can work on different sections simultaneously
- Reduces merge conflicts in version control
- Clear ownership of sections

### 3. **Reusability**
- Sections can be reused in different reports
- Easy to create executive summaries or custom reports
- Mix and match sections as needed

### 4. **Testing**
- Test individual sections independently
- Faster iteration during development
- Easier to debug issues

### 5. **Organization**
- Logical separation of concerns
- Clear document structure
- Easier to navigate and understand

## 🚀 How It Works

### Main File (`article_modular.Rmd`)

The main file contains:
- YAML front matter (title, output formats, bibliography)
- Setup chunk (loads data, libraries, sets options)
- Executive summary
- Child document references using `child=` parameter
- References section
- Footer

### Section Files (`sections/*.Rmd`)

Each section file contains:
- Markdown content
- R code chunks for analysis and visualization
- No YAML front matter (inherited from main file)
- No setup code (shared from main file)

### Child Document Syntax

```r
```{r section-name, child='sections/01_introduction.Rmd'}
```
```

This tells knitr to:
1. Process the child document
2. Insert its content at that location
3. Share all variables and settings from parent

## 📝 Rendering the Document

### Render to HTML
```powershell
Rscript -e "rmarkdown::render('report/article_modular.Rmd', output_format = 'html_document')"
```

### Render to Word
```powershell
Rscript -e "rmarkdown::render('report/article_modular.Rmd', output_format = 'word_document')"
```

### Render to PDF
```powershell
Rscript -e "rmarkdown::render('report/article_modular.Rmd', output_format = 'pdf_document')"
```

### Render All Formats
```powershell
Rscript -e "rmarkdown::render('report/article_modular.Rmd', output_format = 'all')"
```

## 📋 Section Breakdown

### 01_introduction.Rmd
- Overview of digital transformation
- Research objectives
- Context and motivation

### 02_methodology.Rmd
- Data description table
- Coverage details (countries, metrics)
- Statistical methods
- Baseline 2019 comparison

### 03_fixed_internet.Rmd
- Fixed internet trend analysis
- Regression results
- Growth indicators
- Year-over-year dynamics

### 04_mobile_internet.Rmd
- Mobile internet trends
- Statistical indicators
- Fixed vs mobile comparison plots

### 05_regional_comparison.Rmd
- CIS countries comparison (September 2025)
- Regional rankings table
- Growth comparison charts

### 06_conclusions.Rmd
- Key findings
- Policy recommendations (short/medium/long-term)
- Concluding remarks

## 🔧 Editing Workflow

### Adding New Content

1. **Identify the appropriate section file**
2. **Edit the section file directly**
   ```r
   # Example: Adding a new subsection to fixed internet
   # Edit: report/sections/03_fixed_internet.Rmd
   
   ## New Analysis Subsection
   
   ```{r new-analysis}
   # Your R code here
   ```
   
   Your narrative here...
   ```

3. **Render to test**
   ```powershell
   Rscript -e "rmarkdown::render('report/article_modular.Rmd', output_format = 'html_document')"
   ```

### Creating New Sections

1. **Create new file**: `sections/07_new_section.Rmd`
2. **Add content** (no YAML, just markdown + R chunks)
3. **Reference in main file**:
   ```r
   ```{r new-section, child='sections/07_new_section.Rmd'}
   ```
   ```

### Rearranging Sections

Simply reorder the child document references in `article_modular.Rmd`:

```r
# Before
```{r fixed, child='sections/03_fixed_internet.Rmd'}
```
```{r mobile, child='sections/04_mobile_internet.Rmd'}
```

# After (mobile first)
```{r mobile, child='sections/04_mobile_internet.Rmd'}
```
```{r fixed, child='sections/03_fixed_internet.Rmd'}
```
```

## 🎯 Best Practices

### 1. **Keep Sections Focused**
- One main topic per file
- 100-300 lines per section file
- Use subsections (##, ###) within sections

### 2. **Consistent Naming**
- Use numbered prefixes: `01_`, `02_`, etc.
- Descriptive names: `introduction`, `methodology`
- Use underscores, not spaces

### 3. **Shared Resources**
- All data loading in main setup chunk
- All libraries loaded once in main file
- Theme and style settings in main file

### 4. **Comments**
- Document complex code chunks
- Explain unusual analysis decisions
- Note data dependencies

### 5. **Version Control**
- Commit sections independently
- Clear commit messages per section
- Use feature branches for major changes

## 🔄 Migration from Monolithic

The original `article.Rmd` is preserved as a backup. To switch back:

```powershell
# Use modular version (recommended)
Rscript -e "rmarkdown::render('report/article_modular.Rmd', output_format = 'word_document')"

# Use original monolithic version (backup)
Rscript -e "rmarkdown::render('report/article.Rmd', output_format = 'word_document')"
```

## 📊 Performance

- **Rendering time**: Similar to monolithic (knitr caches effectively)
- **File size**: Identical output (same content, different source organization)
- **Memory usage**: Same (all data loaded once in setup)

## 🐛 Troubleshooting

### Child document not found
```
Error: child document not found
```
**Solution**: Check file path relative to main file location

### Variables not available in child
```
Error: object 'az_fixed_median' not found
```
**Solution**: Ensure all data is loaded in main setup chunk before child references

### Duplicate chunk labels
```
Error: duplicate chunk label
```
**Solution**: Ensure unique chunk labels across all section files

## 📚 Additional Resources

- [R Markdown: The Definitive Guide - Child Documents](https://bookdown.org/yihui/rmarkdown-cookbook/child-document.html)
- [knitr Documentation](https://yihui.org/knitr/)
- [Bookdown for Long Documents](https://bookdown.org/)

---

**Last Updated**: October 17, 2025  
**Version**: 1.0  
**Maintained by**: ICTA Azerbaijan - Statistics Unit
