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

# =============================================================================
# PRIMARY SUBMISSION MODELS -- one preselected representative per family
# Diagnostic models remain available for the all-model sensitivity analysis.
# =============================================================================
primary_model_ids <- c(
  "gemini-3.1-pro-preview",
  "claude-opus-4-6",
  "gpt-5-mini"
)
# =============================================================================

outcomes <- read_csv("inputs/tier3_outcomes.csv", show_col_types = FALSE)
interventions <- read_csv(
  "inputs/tier3_interventions.csv",
  show_col_types = FALSE
)
grid_path <- "outputs/raw/full_prompt_grid_results.csv"
archived_result_paths <- c(
  "outputs/raw/primary_model_responses.csv",
  "outputs/raw/exploratory_model_responses.csv"
)
archived_result_paths <- archived_result_paths[file.exists(archived_result_paths)]

if (file.exists(grid_path)) {
  raw <- read_csv(grid_path, show_col_types = FALSE)
  result_source <- grid_path
} else if (length(archived_result_paths)) {
  raw <- bind_rows(lapply(
    archived_result_paths,
    read_csv,
    show_col_types = FALSE
  ))
  message(
    "Using the archived completed model responses bundled with this ",
    "submission repository; forecasts will not be rerun."
  )
  result_source <- paste(archived_result_paths, collapse = ", ")
} else {
  stop(
    "No canonical or archived full results were found. Restore the bundled ",
    "raw response CSV files; do not rerun forecasts merely to rebuild outputs."
  )
}

required_provenance <- c(
  "condition", "model_id", "family", "prompt_id", "completion"
)
missing_provenance <- setdiff(required_provenance, names(raw))
if (length(missing_provenance)) {
  stop(
    "Raw outputs are missing provenance columns: ",
    paste(missing_provenance, collapse = ", ")
  )
}

missing_outcome_columns <- setdiff(outcomes$outcome, names(raw))
if (length(missing_outcome_columns)) {
  stop(
    "Raw outputs are missing outcome columns: ",
    paste(missing_outcome_columns, collapse = ", ")
  )
}

if (anyNA(raw[outcomes$outcome])) {
  stop("At least one raw forecast is missing.")
}

if (
  !is.character(primary_model_ids) || length(primary_model_ids) < 2L ||
    anyNA(primary_model_ids) || any(!nzchar(primary_model_ids)) ||
    anyDuplicated(primary_model_ids)
) {
  stop("`primary_model_ids` must contain unique model IDs.")
}
missing_primary_models <- setdiff(primary_model_ids, unique(raw$model_id))
if (length(missing_primary_models)) {
  stop(
    "Primary model(s) lack complete full-run results: ",
    paste(missing_primary_models, collapse = ", ")
  )
}

primary_roster <- raw |>
  filter(model_id %in% primary_model_ids) |>
  distinct(model_id, family) |>
  arrange(family, model_id)
if (n_distinct(primary_roster$family) != length(primary_model_ids)) {
  stop("The primary selection must contain exactly one model per family.")
}
primary_raw <- raw |>
  filter(model_id %in% primary_model_ids)

# Nalanda applies the same auditable, equal-weight hierarchy with either the
# registered robust median or the arithmetic-mean sensitivity rule.
median_aggregation <- aggregate_model_forecasts(
  data = primary_raw,
  outcomes = outcomes$outcome,
  unit_by = "condition",
  completion_col = "completion",
  prompt_col = "prompt_id",
  model_col = "model_id",
  family_col = "family",
  method = "median"
)

mean_aggregation <- aggregate_model_forecasts(
  data = primary_raw,
  outcomes = outcomes$outcome,
  unit_by = "condition",
  completion_col = "completion",
  prompt_col = "prompt_id",
  model_col = "model_id",
  family_col = "family",
  method = "mean"
)

all_model_aggregation <- aggregate_model_forecasts(
  data = raw,
  outcomes = outcomes$outcome,
  unit_by = "condition",
  completion_col = "completion",
  prompt_col = "prompt_id",
  model_col = "model_id",
  family_col = "family",
  method = "median"
)

primary_aggregation_long <- tidy_forecast_aggregation(
  median_aggregation,
  unit_by = "condition",
  outcomes = outcomes$outcome
)
all_model_aggregation_long <- tidy_forecast_aggregation(
  all_model_aggregation,
  unit_by = "condition",
  outcomes = outcomes$outcome
)

scale_width_lookup <- tidyr::crossing(
  condition = interventions$condition,
  transmute(
    outcomes,
    outcome,
    scale_width = native_max - native_min
  )
)

aggregation_comparison <- compare_forecast_aggregations(
  median_aggregation,
  mean_aggregation,
  stage = "consensus",
  unit_by = "condition",
  outcomes = outcomes$outcome,
  labels = c("median_hierarchy_ate", "mean_hierarchy_ate"),
  scale_width = scale_width_lookup
)

family_disagreement <- primary_aggregation_long |>
  filter(aggregation_level == "family") |>
  summarize_forecast_disagreement(
    unit_by = c("condition", "outcome"),
    contributor_col = "family"
  )

model_counts <- primary_aggregation_long |>
  filter(aggregation_level == "model") |>
  summarize_forecast_disagreement(
    unit_by = c("condition", "outcome"),
    contributor_col = "model_id"
  ) |>
  select(condition, outcome, n_models = n_contributors)

diagnostics <- family_disagreement |>
  transmute(
    condition,
    outcome,
    n_families = n_contributors,
    median_ate = median,
    mean_ate = mean,
    min_ate = min,
    max_ate = max,
    mad_ate = mad
  ) |>
  left_join(model_counts, by = c("condition", "outcome")) |>
  left_join(
    select(outcomes, outcome, native_min, native_max),
    by = "outcome"
  )

expected_grid <- tidyr::expand_grid(
  condition = interventions$condition,
  outcome = outcomes$outcome
)
if (nrow(anti_join(expected_grid, diagnostics, by = c("condition", "outcome")))) {
  stop("Consensus output does not cover the complete 16 x 13 grid.")
}

raw_consensus <- diagnostics |>
  transmute(condition, outcome, ate = median_ate)

all_model_consensus <- all_model_aggregation_long |>
  filter(aggregation_level == "consensus") |>
  transmute(condition, outcome, ate = estimate)

# Sensitivity analysis only: transfer the GPT-4 coefficient from Ashokkumar,
# Hewitt, Ghezae, and Willer's primary archive. It is not validated for the
# present models or direct-forecast procedure.
shrinkage_factor <- 0.56
shrunk_consensus <- diagnostics |>
  mutate(
    physical_lower_bound = native_min - native_max,
    physical_upper_bound = native_max - native_min,
    ate = pmax(
      physical_lower_bound,
      pmin(physical_upper_bound, median_ate * shrinkage_factor)
    )
  ) |>
  select(condition, outcome, ate)

dir.create("outputs/derived", recursive = TRUE, showWarnings = FALSE)
write_csv(
  all_model_aggregation_long,
  "outputs/derived/nalanda_forecast_aggregation_long.csv"
)
write_csv(primary_roster, "outputs/derived/primary_model_roster.csv")
write_csv(
  aggregation_comparison,
  "outputs/derived/aggregation_method_comparison.csv"
)
write_csv(diagnostics, "outputs/derived/consensus_diagnostics.csv")
write_csv(raw_consensus, "outputs/derived/team_16_T3_candidate_median_unscaled.csv")
write_csv(
  all_model_consensus,
  "outputs/derived/team_16_T3_diagnostic_all_models_median_unscaled.csv"
)
write_csv(
  shrunk_consensus,
  "outputs/derived/team_16_T3_sensitivity_gpt4_transfer_056.csv"
)
saveRDS(
  list(
    primary_median = median_aggregation,
    primary_mean = mean_aggregation,
    all_models_median = all_model_aggregation
  ),
  "outputs/derived/nalanda_forecast_aggregations.rds"
)

cat("Built complete Tier-3 candidate files with", nrow(raw_consensus), "rows.\n")
cat("Raw source:", result_source, "\n")
cat("Primary candidate: hierarchical medians with equal family weight.\n")
cat("Primary models:", paste(primary_model_ids, collapse = ", "), "\n")
cat("All-model diagnostic sensitivity includes", n_distinct(raw$model_id), "models.\n")
cat("Nalanda median/mean hierarchy bundle and comparison saved separately.\n")
cat("The locked repository-root prediction file is not modified by this script.\n")
