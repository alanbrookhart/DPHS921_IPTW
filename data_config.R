
# read-in data sets and configure related lists that describe them for Shiny app

ns <- readRDS("data_raw/ns.rds")
sta <- readRDS("data_raw/sta.rds")

data_list <- list(`New Users of NSAIDs` = 'ns', `New Users of Statins` = 'sta')

data_descript <- list(
  ns = "This cohort is built from the 2005-2009 public use files from National Ambulatory Medical Care Data Survey (NAMCS). The NAMCS survey covers over 20,000 visits per year and includes data on patient demographics, comorbidities, physician and practice characteristics, and treatment received, including medications. Currently, medications are classified using the Multum Lexicon. Each year a few variables are added to, deleted from, or recoded in the public use dataset.
From these data, we identify new users of either a non-selective non-steroidal antiinflammatory drug (NSAID) or Cox-2 selective NSAID. The data are augmented with a simulated peptic ulcer disease outcome. Variables were selected for this extract based on relevance to the example analyses and on availability for most or all of the 2005-2009 time range. 
  For more information, see https://github.com/alanbrookhart/NAMCS#codebook"
  , 
  sta = "To be added."
  )

factor_vars_list = list(
  ns = c("year", "region", "arthritis", "asthma", "cancer", "cerebrovascular_disease", "chronic_kidney_disease", "heart_failure", "chronic_pulmonary_disease", "depression", "diabetes", "hyperlipidemia", "hypertension", "coronory_artery_disease", "osteoporosis",  "anti_hypertensive_use", "statin_use", "h2_antagonist_use", "ppi_use", "aspirin_use", "anti_coagulant_use", "corticosteroid_use", "sex", "race", "incident_pud"),
  sta = c("year", "region", "arthritis", "asthma", "cancer", "cerebrovascular_disease", "chronic_kidney_disease", "heart_failure", "chronic_pulmonary_disease", "depression", "diabetes", "hyperlipidemia", "hypertension", "coronory_artery_disease", "osteoporosis",  "anti_hypertensive_use", "statin_use", "h2_antagonist_use", "ppi_use", "aspirin_use", "anti_coagulant_use", "corticosteroid_use", "sex", "race", "incident_pud")
)

cont_vars_list = list(
  ns = c("age"),
  sta  = c("age")
)

default_treatment = list(
  ns = "cox2_initiation",
  sta  = "aspirin_use"
  )

default_outcome = list(
  ns = "incident_pud",
  sta  = "cv_indicator"
)
