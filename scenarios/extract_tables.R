# Script to extract probability tables from all scenario markdown files
# and combine them into a single data.table for comparison

library(data.table)

#' Extract the probability table from a markdown file
#' @param md_file Path to the markdown file
#' @return A data.table with the extracted table data
extract_prob_table <- function(md_file) {
  
  # Read the file content

lines <- readLines(md_file, warn = FALSE)
  
  # Find the table header line
  header_idx <- grep("^\\| Size \\| P\\(Greater or equal\\)", lines)
  
  if (length(header_idx) == 0) {
    warning(sprintf("No probability table found in %s", md_file))
    return(NULL)
  }
  
  # Use the first match if multiple found
  header_idx <- header_idx[1]
  
  # Find table rows (lines starting with | and containing numbers)
  # Skip the separator line (|-----:|...)
  table_lines <- character(0)
  i <- header_idx + 2  # Skip header and separator
  
  while (i <= length(lines) && grepl("^\\|\\s*\\d+", lines[i])) {
    table_lines <- c(table_lines, lines[i])
    i <- i + 1
  }
  
  if (length(table_lines) == 0) {
    warning(sprintf("No data rows found in table from %s", md_file))
    return(NULL)
  }
  
  # Parse each table row
  parsed <- lapply(table_lines, function(row) {
    # Remove leading/trailing pipes and split
    cells <- strsplit(gsub("^\\|\\s*|\\s*\\|$", "", row), "\\s*\\|\\s*")[[1]]
    data.table(
      size = as.integer(trimws(cells[1])),
      p_geq = as.numeric(trimws(cells[2])),
      p_leq = as.numeric(trimws(cells[3]))
    )
  })
  
  rbindlist(parsed)
}

#' Parse scenario parameters from filename
#' @param filename The filename (without path)
#' @return A data.table with scenario parameters
parse_scenario_params <- function(filename) {
  
  # Remove extension
  base_name <- gsub("\\.md$", "", basename(filename))
  
  # Extract R0 value
  r0_match <- regmatches(base_name, regexpr("R0_[0-9.]+", base_name))
  r0 <- as.numeric(gsub("R0_", "", r0_match))
  
  # Extract isolation (yes/no)
  isolation <- grepl("isolation_yes", base_name)
  
  # Extract quarantine (yes/no)
  quarantine <- grepl("quarantine_yes", base_name)
  
  # Extract pep (yes/no) - if present
  pep <- grepl("pep_yes", base_name)
  
  data.table(
    filename = base_name,
    R0 = r0,
    isolation = isolation,
    quarantine = quarantine,
    pep = pep
  )
}

#' Main function to extract and combine all tables
#' @param scenarios_dir Path to the scenarios directory
#' @return A combined data.table with all scenario results
extract_all_scenarios <- function(scenarios_dir = "scenarios") {
  
  # Find all markdown files
  md_files <- list.files(
    scenarios_dir,
    pattern = "^R0_.*\\.md$",
    full.names = TRUE
  )
  
  if (length(md_files) == 0) {
    stop("No markdown files found in ", scenarios_dir)
  }
  
  message(sprintf("Found %d scenario files", length(md_files)))
  
  # Process each file
  results <- lapply(md_files, function(f) {
    message(sprintf("Processing: %s", basename(f)))
    
    # Get scenario parameters
    params <- parse_scenario_params(f)
    
    # Extract the probability table
    prob_table <- extract_prob_table(f)
    
    if (is.null(prob_table)) {
      return(NULL)
    }
    
    # Combine parameters with table data
    cbind(params, prob_table)
  })
  
  # Combine all results
  combined <- rbindlist(results, fill = TRUE)
  
  # Reorder columns for clarity
  setcolorder(combined, c("R0", "isolation", "quarantine", "pep", "size", "p_geq", "p_leq", "filename"))
  
  # Sort by R0, intervention settings, and size
  setorder(combined, R0, -isolation, -quarantine, -pep, size)
  
  combined
}

# Run the extraction if called as a script
if (!interactive() || TRUE) {
  
  # Change to project root if we're in the scenarios folder
  if (basename(getwd()) == "scenarios") {
    setwd("..")
  }
  
  # Extract all scenario data
  scenario_data <- extract_all_scenarios("scenarios")
  
  # Display summary
  message("\n=== Summary ===")
  message(sprintf("Total scenarios: %d", uniqueN(scenario_data$filename)))
  message(sprintf("Total rows: %d", nrow(scenario_data)))
  message("\nUnique R0 values: ", paste(unique(scenario_data$R0), collapse = ", "))
  message("\nScenario combinations:")
  print(unique(scenario_data[, .(R0, isolation, quarantine, pep)]))
  
  # Save the combined results
  output_file <- "scenarios/combined_scenario_results.rds"
  saveRDS(scenario_data, output_file)
  message(sprintf("\nResults saved to: %s", output_file))
  
  # Also save as CSV for easy viewing
  csv_file <- "scenarios/combined_scenario_results.csv"
  fwrite(scenario_data, csv_file)
  message(sprintf("CSV version saved to: %s", csv_file))
  
  # Print a preview
  message("\n=== Preview of combined data ===")
  print(head(scenario_data, 20))
}
