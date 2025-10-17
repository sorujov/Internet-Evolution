# İnternet Keyfiyyəti: Dünəndən Bu Günə

## Azərbaycanın Rəqəmsal Transformasiyası

### Layihə Haqqında

Bu layihə MDB ölkələrində internet keyfiyyətinin təhlilini, xüsusilə Azərbaycan kontekstində aparılmış araşdırmadır. Layihə ICTA (İnformasiya Texnologiyaları və Rabitə Agentliyi) tərəfindən həyata keçirilir.

**Müddət:** Aprel 2019 - Sentyabr 2025 (6.5 il)

### Məlumat Mənbəyi

- **Ölkələr:** Azərbaycan, Ermənistan, Belarus, Qazaxıstan, Qırğızıstan, Rusiya, Tacikistan, Özbəkistan (8 MDB ölkəsi)
- **Göstəricilər:** 
  - Download Speed (Mbps) - Yükləmə sürəti
  - Upload Speed (Mbps) - Göndərmə sürəti
  - Multi-Server Latency (ms) - Gecikmə
  - Multi-Server Jitter (ms) - Tərəddüd
- **Məlumat növləri:**
  - Sabit internet (Fixed Internet)
  - Mobil internet (Cellular Internet)

### Layihə Strukturu

```
/internet-quality-analysis
  ├── data/              # Məlumat faylları
  │   ├── raw/          # Orijinal məlumatlar (Fixed.csv, Cellular.csv)
  │   └── processed/    # Emal edilmiş məlumatlar
  ├── analysis/         # R analiz skriptləri (4 əsas skript)
  ├── report/           # RMarkdown hesabat faylları
  ├── figures/          # Qrafiklər və vizuallaşdırmalar
  ├── output/           # Son hesabatlar (PDF, HTML, DOCX)
  └── docs/             # Əlavə sənədlər və təlimatlar
```

### Texnologiyalar

- **R:** 4.0+
- **RStudio:** İnkişaf mühiti
- **R Paketləri:** 
  - tidyverse (məlumat manipulyasiyası)
  - lubridate (tarix işləmə)
  - ggplot2 (vizuallaşdırma)
  - rmarkdown (hesabat yaratma)
  - knitr (dinamik hesabatlar)
  - kableExtra (cədvəl formatlaması)

### Təhlil Mərhələləri

1. **Data Preparation** - Məlumatların təmizlənməsi və hazırlanması
2. **Descriptive Statistics** - Təsviri statistika
3. **Trend Analysis** - Trend təhlili və proqnozlaşdırma
4. **Comparative Analysis** - MDB ölkələri ilə müqayisə

### İstifadə

#### Tələblər

R və RStudio quraşdırılmalıdır. Lazımi paketləri yükləmək üçün:

```r
install.packages(c("tidyverse", "lubridate", "ggplot2", 
                   "rmarkdown", "knitr", "kableExtra", 
                   "scales", "ggthemes", "here", "broom"))
```

#### Təhlil Prosesi

1. Məlumat hazırlığı:
```r
source("analysis/01_data_prep.R")
```

2. Statistik təhlil:
```r
source("analysis/02_descriptive_stats.R")
```

3. Trend təhlili:
```r
source("analysis/03_trend_analysis.R")
```

4. Müqayisəli təhlil:
```r
source("analysis/04_comparative_analysis.R")
```

5. Hesabat yaratma:
```r
rmarkdown::render("report/article.Rmd", output_format = "all")
```

**və ya bütün prosesi avtomatik işə salmaq üçün:**

```r
source("run_all.R")
```

### Məqsədlər

1. Azərbaycanın internet keyfiyyətinin 2019-2025 dinamikasını təhlil etmək
2. Sabit və mobil internet xidmətlərinin müqayisəsi
3. MDB regional kontekstində Azərbaycanın mövqeyini qiymətləndirmək
4. İnkişaf tempini və artım trendlərini müəyyənləşdirmək
5. ICTA üçün siyasət tövsiyələri hazırlamaq

### Əsas Suallar

- Azərbaycanın internet sürəti son 6.5 ildə necə dəyişib?
- Sabit və mobil internet arasında fərq nədir?
- MDB ölkələri arasında Azərbaycan hansı mövqedədir?
- Hansı sahələrdə irəliləyiş var, hansılarda təkmilləşdirmə lazımdır?

### Nəticələr

Hesabatlar `output/` qovluğunda yaradılacaq:
- `article.pdf` - PDF formatda hesabat
- `article.html` - İnteraktiv HTML hesabat
- `article.docx` - Word formatda hesabat

### Müəllif və Təşkilat

**ICTA Azerbaijan - Statistics Unit**  
**Tarix:** Oktyabr 2025

### Əlaqə

- **Email:** statistics@icta.gov.az
- **Website:** https://icta.gov.az
- **Ünvan:** 27 Atatürk prospekti, Bakı 1069, Azərbaycan

### Lisenziya

© 2025 ICTA Azerbaijan. Bütün hüquqlar qorunur.

---

### Qeydlər

- Məlumatlar aylıq ölçülər şəklindədir (median və mean dəyərləri)
- Təhlil MDB ölkələrini əhatə edir
- Fokus Azərbaycan internet sektorunun inkişafındadır
- Hesabat Azərbaycan dilindədir
