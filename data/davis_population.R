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

fwrite(davis_aggregated, file = "data/davis_population.csv")

# Creating the mixing matrix
n <- nrow(davis_aggregated)
mixmat <- matrix(1/n, n, n)

saveRDS(mixmat, file = "data/davis_mixing_matrix.rds")
