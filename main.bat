@echo off
setlocal

REM main.bat - Render article_modular.Rmd to specified format(s)
REM Usage: 
REM   main.bat              - renders all formats (HTML, PDF, Word)
REM   main.bat html         - renders HTML only
REM   main.bat pdf          - renders PDF only  
REM   main.bat word         - renders Word only
REM   main.bat html pdf     - renders HTML and PDF
REM   main.bat all          - renders all formats

set FORMAT=%1

if "%FORMAT%"=="" set FORMAT=all

if /i "%FORMAT%"=="all" (
    echo Rendering all formats...
    Rscript -e "rmarkdown::render('report/article_modular.Rmd', output_dir = 'output', output_format = 'html_document')"
    Rscript -e "rmarkdown::render('report/article_modular.Rmd', output_dir = 'output', output_format = 'pdf_document')"
    Rscript -e "rmarkdown::render('report/article_modular.Rmd', output_dir = 'output', output_format = 'word_document')"
    echo All formats rendered successfully!
    goto :end
)

:loop
if "%1"=="" goto :end

if /i "%1"=="html" (
    echo Rendering HTML...
    Rscript -e "rmarkdown::render('report/article_modular.Rmd', output_dir = 'output', output_format = 'html_document')"
)

if /i "%1"=="pdf" (
    echo Rendering PDF...
    Rscript -e "rmarkdown::render('report/article_modular.Rmd', output_dir = 'output', output_format = 'pdf_document')"
)

if /i "%1"=="word" (
    echo Rendering Word...
    Rscript -e "rmarkdown::render('report/article_modular.Rmd', output_dir = 'output', output_format = 'word_document')"
)

shift
goto :loop

:end
echo.
echo Output files saved to: output\
endlocal