library(multigroup.vaccine)
library(socialmixr)
library(data.table)

# Get the path to the included census data file
census_csv <- getCensusDataPath()

# Get FIPS code for Utah
utah_fips <- getStateFIPS("Utah")
cat("Utah FIPS code:", utah_fips, "\n")

# List counties in Utah
utah_counties <- listCounties(utah_fips)
print(utah_counties)

# Get population by age groups for Davis County (2024)
davis_population <- getCensusData(state_fips = utah_fips, county_name = "Davis")

agelims <- c(0, 1, 5, 12, 14, 18, 25, 45, 70)
ageveff <- c(0.93, 0.93, rep(0.97, 6), 1)

davis_aggregated <- aggregateByAgeGroups(
  ages = davis_population$ages,
  pops = davis_population$data$TOT_POP,
  age_groups = agelims
  )

# Creating as a data.frame
davis_aggregated <- with(
  davis_aggregated,
    data.frame(
      age_labels = labels,
      agepops = pops,
      agelims = sapply(age_ranges, "[[", 1)
    )
)

# Creating the mixing matrix
davis_school_path <- system.file(
  "extdata/DavisSchools.csv", package = "multigroup.vaccine"
  )
davis_school_data <- fread(davis_school_path)
davis_school_data

schoolpops <- davis_school_data$pop
schoolagegroups <- davis_school_data$level + 2
schoolvax <- rep(0, length(schoolagegroups))

agepops <- davis_aggregated$agepops

for (a in unique(schoolagegroups)) {
  inds <- which(schoolagegroups == a)
  schoolpops[inds] <- round(agepops[a] * schoolpops[inds] / sum(schoolpops[inds]))
}
cm <- contactMatrixAgeSchool(agelims, agepops, schoolagegroups, schoolpops, schportion = 0.7)
grouppops <- c(agepops[1:(min(schoolagegroups) - 1)],
  schoolpops,
  agepops[(max(schoolagegroups) + 1):length(agepops)])


## Set up outbreak analysis
## STOP()

################################################
# Short Creek Data Preparation
################################################

# Making it row-stochastic for use in epiworld
davis_population_mixing <- cm
davis_population_mixing <- davis_population_mixing / rowSums(davis_population_mixing)

saveRDS(davis_population_mixing, file = "data/davis_mixing_matrix.rds")


davis_population <- data.table(
  age_labels = rownames(davis_population_mixing),
  agepops = grouppops,
  agelims = gsub(
    ".+to([0-9]+).*", "\\1",
    rownames(davis_population_mixing)
  ) |> as.integer(),
  vacc_rate = 0
)

davis_population[age_labels == "under1", agelims := 1L]
davis_population[age_labels == "70+", agelims := 90L]

fwrite(davis_population, file = "data/davis_population.csv")