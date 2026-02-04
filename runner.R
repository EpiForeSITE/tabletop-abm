
R0s <- c(1.1, 1.5, 1.9)
isolation <- c(TRUE, FALSE)
quarantine <- c(TRUE, FALSE)

nsims <- 40L
nthreads <- 40L

# Generating all combinations as a data.frame
scenarios <- expand.grid(
  R0 = R0s,
  isolation = isolation,
  quarantine = quarantine
)

for (i in seq_len(nrow(scenarios))) {

  # Creating the filename based on the scenario parameters
  scenario <- scenarios[i, ]
  scenario_name <- sprintf(
    "R0_%.1f_isolation_%s_quarantine_%s",
    scenario$R0,
    ifelse(scenario$isolation, "yes", "no"),
    ifelse(scenario$quarantine, "yes", "no")  
    )

  # Verifying the file does not already exist
  fn <- file.path("scenarios", paste0(scenario_name, ".md"))
  fn_qmd <- gsub(".md$", ".qmd", fn)

  if (file.exists(fn)) {
    next  # Skip if the file already exists
  }

  # Creating a copy of the template
  file.copy("template.qmd", fn_qmd)
  
  quarto::quarto_render(
    input = fn_qmd,
    output_format = "gfm",
    execute_params = list(
      nthreads   = nthreads,
      nsims      = nsims,
      R0         = scenario$R0,
      quarantine = scenario$quarantine,
      isolation  = scenario$isolation
    )
  )
}

