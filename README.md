# Economic and Social Determinants of Life Expectancy

Econometric analysis of what drives life expectancy across countries, using World Bank panel data (2010–2023). The full paper is included as a PDF. It was written as a co-authored course paper; the authors are listed in the PDF.

## Data

Five World Bank indicators, one CSV each, merged into `final_data.csv` (1,649 country-year observations, 142 countries):

| File | Variable |
|---|---|
| `life_expectancy.csv` | Life expectancy at birth (years) |
| `gdp_per_capita.csv` | GDP per capita (log-transformed in the models) |
| `health_expenditure.csv` | Health expenditure |
| `education_secondary.csv` | Secondary education |
| `unemployment_rate.csv` | Unemployment rate |

## Method

Pooled OLS, country fixed effects and two-way fixed effects (`plm`), with cluster-robust standard errors, separate 2020 and 2021 (COVID) dummies, a balanced-panel check and an income-group interaction test.

## Files

- `Economic And Social Determinants Of Life Expectancy.pdf`: the paper
- `corrected_analysis_v2.R`: final analysis script (`corrected_analysis.R` is the earlier version)
- `verify.R` and `r_verify_output.txt`: independent check of the results and its output
- `regression_tables_clustered.html`: regression tables with clustered standard errors

## Reproduce

Put the five CSV files next to the script and run `Rscript corrected_analysis_v2.R` (packages: readr, dplyr, tidyr, ggplot2, plm, car, modelsummary, lmtest, sandwich; installed automatically if missing).
