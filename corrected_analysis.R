
# Corrected analysis script: Economic and Social Determinants of Life Expectancy
# Changes vs. original: cluster-robust SEs, separate 2020/2021 dummies, balanced-panel check,
# interaction test for income groups, no stray "}" and all packages installed/loaded.
# Run from the folder that holds the five World Bank CSV files.

pkgs <- c("readr","dplyr","tidyr","ggplot2","plm","car","modelsummary","lmtest","sandwich")
new  <- pkgs[!pkgs %in% rownames(installed.packages())]
if (length(new)) install.packages(new)
invisible(lapply(pkgs, library, character.only = TRUE))

# ---- Load, reshape, merge ----
rd <- function(f, nm) {
  read.csv(f) |>
    pivot_longer(cols = X2010:X2023, names_to = "Year", values_to = nm) |>
    mutate(Year = as.numeric(gsub("X", "", Year)))
}
final_data <- rd("life_expectancy.csv", "LifeExp") |>
  merge(rd("gdp_per_capita.csv", "GDP"),             by = c("Country.Name","Country.Code","Year")) |>
  merge(rd("health_expenditure.csv", "HealthExp"),   by = c("Country.Name","Country.Code","Year")) |>
  merge(rd("education_secondary.csv", "Education"),  by = c("Country.Name","Country.Code","Year")) |>
  merge(rd("unemployment_rate.csv", "Unemployment"), by = c("Country.Name","Country.Code","Year")) |>
  na.omit()

final_data$logGDP    <- log(final_data$GDP)
final_data$Y2020     <- as.numeric(final_data$Year == 2020)
final_data$Y2021     <- as.numeric(final_data$Year == 2021)
final_data$COVID2021 <- as.numeric(final_data$Year %in% c(2020, 2021))   # = 2020-21 dummy
high_income <- c("Australia","Austria","Belgium","Canada","Denmark","Finland","France","Germany",
                 "Ireland","Italy","Japan","Netherlands","New Zealand","Norway","Singapore","Spain",
                 "Sweden","Switzerland","United Kingdom","United States")
final_data$HighIncome <- as.numeric(final_data$Country.Name %in% high_income)

pdata <- pdata.frame(final_data, index = c("Country.Name", "Year"))
f <- LifeExp ~ logGDP + HealthExp + Education + Unemployment

# ---- Main models ----
m_pool <- plm(f, pdata, model = "pooling")
m_fe   <- plm(f, pdata, model = "within", effect = "individual")
m_twfe <- plm(f, pdata, model = "within", effect = "twoways")
pFtest(m_fe, m_pool); pFtest(m_twfe, m_fe)

# ---- Pandemic ----
m_c1 <- update(m_fe, . ~ . + COVID2021)
m_c2 <- update(m_fe, . ~ . + Y2020 + Y2021)
m_c3 <- plm(f, subset(pdata, !(as.numeric(as.character(Year)) %in% c(2020, 2021))), model = "within")
m_c4 <- plm(f, subset(pdata, as.numeric(as.character(Year)) <= 2019), model = "within")

# ---- Lag ----
pdata$logGDP_lag <- lag(pdata$logGDP, 1)
pl <- pdata[!is.na(pdata$logGDP_lag), ]
fl <- LifeExp ~ logGDP_lag + HealthExp + Education + Unemployment
m_l1 <- plm(fl, pl, model = "within", effect = "individual")
m_l2 <- plm(fl, pl, model = "within", effect = "twoways")

# ---- Balanced panel ----
full <- names(which(table(final_data$Country.Name) == 14))
m_bal <- plm(f, pdata[pdata$Country.Name %in% full, ], model = "within")

# ---- Income groups ----
m_hi <- plm(f, pdata[pdata$HighIncome == 1, ], model = "within")
m_lo <- plm(f, pdata[pdata$HighIncome == 0, ], model = "within")
m_int <- plm(LifeExp ~ (logGDP + HealthExp + Education + Unemployment) * HighIncome,
             pdata, model = "within", effect = "individual")

# ---- Cluster-robust SEs by country, all tables ----
cl <- function(m) vcovHC(m, method = "arellano", type = "HC1", cluster = "group")
models <- list("Pooled" = m_pool, "FE" = m_fe, "TWFE" = m_twfe,
               "FE+2020-21" = m_c1, "FE+2020,2021" = m_c2, "FE excl 2020-21" = m_c3, "FE 2010-19" = m_c4,
               "FE lag" = m_l1, "TWFE lag" = m_l2, "FE balanced" = m_bal,
               "High income" = m_hi, "Other" = m_lo, "Interactions" = m_int)
modelsummary(models, vcov = lapply(models, cl), stars = c("*" = .1, "**" = .05, "***" = .01),
             output = "regression_tables_clustered.html")

# ---- VIF (pooled) ----
print(vif(lm(f, final_data)))
source("~/Downloads/verify.R")
