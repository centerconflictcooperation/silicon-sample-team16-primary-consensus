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
  library(nalanda)
  library(dplyr)
  library(readr)
})

aggregation_path <- "outputs/derived/nalanda_forecast_aggregation_long.csv"
if (!file.exists(aggregation_path)) {
  stop("Run scripts/03_build_submission.R before this script.")
}

forecast_stages <- read_csv(aggregation_path, show_col_types = FALSE)
outcomes <- read_csv("inputs/tier3_outcomes.csv", show_col_types = FALSE) |>
  transmute(outcome, scale_width = native_max - native_min)

model_level <- forecast_stages |>
  filter(aggregation_level == "model") |>
  left_join(outcomes, by = "outcome")

prompt_level <- forecast_stages |>
  filter(aggregation_level == "prompt") |>
  left_join(outcomes, by = "outcome")

dir.create("outputs/diagnostics", recursive = TRUE, showWarnings = FALSE)

# The same generic Nalanda summary describes fixed-prompt sensitivity within
# each model and cross-model disagreement within each forecast target.
prompt_disagreement <- prompt_level |>
  summarize_forecast_disagreement(
    unit_by = c("condition", "outcome", "model_id"),
    contributor_col = "prompt_id",
    scale_width_col = "scale_width"
  ) |>
  arrange(desc(range_per_scale))

write_csv(
  prompt_disagreement,
  "outputs/diagnostics/prompt_disagreement_by_cell.csv"
)

models <- sort(unique(model_level$model_id))
if (length(models) < 2L) {
  cat(
    "Wrote prompt-sensitivity diagnostics. Only one model is present, so ",
    "inter-model diagnostics are intentionally withheld.\n"
  )
} else {
  model_disagreement <- model_level |>
    summarize_forecast_disagreement(
      unit_by = c("condition", "outcome"),
      contributor_col = "model_id",
      scale_width_col = "scale_width"
    ) |>
    arrange(desc(range_per_scale))

  # Normalize before comparing models across outcomes with very different
  # native units (for example, $0-$10 versus 0-100 versus binary outcomes).
  model_agreement_input <- model_level |>
    mutate(estimate_per_scale = estimate / scale_width)

  pairwise_correlations <- model_pairwise_cor(
    model_agreement_input,
    outcome = "estimate_per_scale",
    unit_by = c("condition", "outcome"),
    model_col = "model_id",
    methods = c("pearson", "spearman")
  )

  overall_agreement <- model_agreement(
    model_agreement_input,
    outcome = "estimate_per_scale",
    unit_by = c("condition", "outcome"),
    model_col = "model_id"
  )

  write_csv(
    model_disagreement,
    "outputs/diagnostics/model_disagreement_by_cell.csv"
  )
  write_csv(
    pairwise_correlations,
    "outputs/diagnostics/model_correlations_pairwise.csv"
  )
  write_csv(
    summarize_model_correlations(pairwise_correlations),
    "outputs/diagnostics/model_correlations_summary.csv"
  )
  write_csv(
    overall_agreement,
    "outputs/diagnostics/model_agreement_overall.csv"
  )

  cat(
    "Wrote scale-aware model agreement, pairwise correlations, and cell-level ",
    "model and prompt disagreement diagnostics.\n"
  )
  cat("These files are descriptive and do not remove or reweight any model.\n")
}
