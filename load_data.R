
# this files loads the NAMCS data files and places them in ./data

devtools::install_github("alanbrookhart/NAMCS")
library(NAMCS)

saveRDS(ns, "data_raw/ns.rds")
saveRDS(sta, "data_raw/sta.rds")

