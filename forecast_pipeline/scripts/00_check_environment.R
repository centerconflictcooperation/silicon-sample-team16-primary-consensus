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

required_packages <- c(
  "nalanda",
  "ellmer",
  "dplyr",
  "tidyr",
  "readr",
  "stringr",
  "jsonlite",
  "digest",
  "rmarkdown",
  "knitr",
  "ggplot2",
  "scales"
)

missing_packages <- required_packages[
  !vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)
]

required_files <- c(
  "../README.md",
  "../metadata.json",
  "../registration.md",
  "../codebook.csv",
  "../survey/questionnaire.txt",
  "../survey/condition_codenames.csv",
  "../scripts/check.R",
  "config/models.csv",
  "prompts/tier3_direct_forecast_v1.txt",
  "prompts/tier3_direct_forecast_v2.txt",
  "reports/primary_submission_report.Rmd"
)

missing_files <- required_files[!file.exists(required_files)]

cat("Silicon Benchmark local environment check\n")
cat("-----------------------------------------\n")
cat("Working directory:", normalizePath(".", winslash = "/"), "\n")

if (length(missing_packages)) {
  cat("Missing R packages:", paste(missing_packages, collapse = ", "), "\n")
} else {
  cat("R packages: OK\n")
  cat("nalanda version:", as.character(utils::packageVersion("nalanda")), "\n")
  cat("ellmer version:", as.character(utils::packageVersion("ellmer")), "\n")
}

nalanda_too_old <- !"nalanda" %in% missing_packages &&
  utils::packageVersion("nalanda") < numeric_version("0.0.2.2")
if (nalanda_too_old) {
  cat("nalanda 0.0.2.2 or later is required.\n")
}

if (length(missing_files)) {
  cat(
    "Missing project files:\n-",
    paste(missing_files, collapse = "\n- "),
    "\n"
  )
} else {
  cat("Official template and local pipeline files: OK\n")
}

models <- if (file.exists("config/models.csv")) {
  utils::read.csv("config/models.csv", stringsAsFactors = FALSE)
} else {
  data.frame()
}

if (nrow(models)) {
  cat("Model routes in roster:", paste(models$model_id, collapse = ", "), "\n")
}

if (length(missing_packages) || length(missing_files) || nalanda_too_old) {
  cat(
    "Environment check incomplete. Resolve the items listed above, then ",
    "click Source again. The R session remains open.\n"
  )
} else {
  cat("Environment check complete. The pipeline is ready for the next step.\n")
}
