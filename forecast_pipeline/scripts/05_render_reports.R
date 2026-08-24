# Locate the pipeline from this script so the RStudio project can stay at the
# repository root. This works with Source and with Run All in RStudio.
.source_files <- vapply(
  sys.frames(),
  function(frame) {
    value <- frame$ofile
    if (is.null(value) || !length(value)) "" else as.character(value[[1]])
  },
  character(1)
)
.source_files <- .source_files[nzchar(.source_files)]
.script_path <- if (length(.source_files)) {
  normalizePath(tail(.source_files, 1), winslash = "/", mustWork = TRUE)
} else {
  ""
}
rm(.source_files)
if (!nzchar(.script_path) && requireNamespace("rstudioapi", quietly = TRUE) &&
    rstudioapi::isAvailable()) {
  .script_path <- rstudioapi::getSourceEditorContext()$path
}
if (nzchar(.script_path)) {
  .pipeline_root <- dirname(dirname(normalizePath(
    .script_path, winslash = "/", mustWork = TRUE
  )))
  if (file.exists(file.path(.pipeline_root, "DECISION_GUIDE_BOOK_TO_SILICON.md"))) {
    setwd(.pipeline_root)
  }
}
rm(.script_path)
if (exists(".pipeline_root", inherits = FALSE)) rm(.pipeline_root)

suppressPackageStartupMessages({
  library(rmarkdown)
})

required_files <- c(
  "reports/primary_submission_report.Rmd",
  "reports/model_diagnostics_report.Rmd",
  "outputs/derived/team_16_T3_candidate_median_unscaled.csv",
  "outputs/derived/primary_model_roster.csv",
  "outputs/derived/nalanda_forecast_aggregation_long.csv",
  "outputs/diagnostics/model_correlations_pairwise.csv",
  "outputs/diagnostics/prompt_disagreement_by_cell.csv",
  "inputs/tier3_outcomes.csv",
  "inputs/tier3_interventions.csv",
  "config/models.csv"
)

missing_files <- required_files[!file.exists(required_files)]
if (length(missing_files)) {
  stop(
    "Cannot render the primary report. Missing files:\n- ",
    paste(missing_files, collapse = "\n- "),
    "\nRun the earlier numbered scripts first."
  )
}

exploratory_output_path <- rmarkdown::render(
  input = "reports/model_diagnostics_report.Rmd",
  output_file = "model_diagnostics_report.html",
  output_dir = normalizePath("reports", winslash = "/"),
  envir = new.env(parent = globalenv()),
  quiet = FALSE
)

primary_output_path <- rmarkdown::render(
  input = "reports/primary_submission_report.Rmd",
  output_file = "primary_submission_report.html",
  output_dir = normalizePath("reports", winslash = "/"),
  envir = new.env(parent = globalenv()),
  quiet = FALSE
)

# Keep an archival report in the pipeline and a GitHub Pages entry point at
# the submission-repository root.
repository_root <- normalizePath("..", winslash = "/", mustWork = TRUE)
pages_dir <- file.path(repository_root, "docs")
dir.create(pages_dir, recursive = TRUE, showWarnings = FALSE)
pages_path <- file.path(pages_dir, "index.html")

if (!file.copy(primary_output_path, pages_path, overwrite = TRUE)) {
  stop("The report rendered, but it could not be copied to ", pages_path, ".")
}

nojekyll_path <- file.path(pages_dir, ".nojekyll")
if (!file.exists(nojekyll_path)) {
  file.create(nojekyll_path)
}

cat(
  "\nExploratory diagnostics report created successfully:\n",
  normalizePath(exploratory_output_path, winslash = "/"),
  "\nPrimary submission report created successfully:\n",
  normalizePath(primary_output_path, winslash = "/"),
  "\nGitHub Pages copy updated:\n",
  normalizePath(pages_path, winslash = "/", mustWork = FALSE),
  "\nOpen the HTML file in a web browser to review it.\n"
)
