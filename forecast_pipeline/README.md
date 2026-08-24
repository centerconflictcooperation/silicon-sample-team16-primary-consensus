# Silicon Sample Benchmark — team_16 workspace

This project requires `nalanda` 0.0.2.2 or later.

This folder is the working area for a bounded Tier-3 submission to the Silicon
Sample Benchmark. The goal is one automated, effect-level entry: 16
interventions x 13 outcomes = 208 predicted average treatment effects (ATEs).

## Folder map

- The repository root is the organizers' submission template. It contains the
  survey, codebook, validator, registration form, prediction, and Zenodo
  helpers. Pipeline scripts refer to those files through explicit parent paths.
- `scripts/` — the local Tier-3 forecasting pipeline.
- `prompts/` — fixed direct-forecast prompt variants.
- `config/models.csv` — the candidate model-route roster. Select which routes
  to run through `active_model_ids` in script 02; the CSV need not be edited.
- `inputs/` — generated, authoritative inputs extracted from the official
  template. These files are created by `scripts/01_prepare_inputs.R`.
- `outputs/raw/` — the completed primary and exploratory model-response tables.
  Their row-level provenance is enough to rebuild the submission without
  making model calls again.
- `outputs/derived/` — hierarchical forecast stages, aggregation comparisons,
  consensus predictions, and sensitivity candidates.
- `outputs/diagnostics/` — Nalanda prompt/model disagreement, correlations,
  and agreement summaries generated without changing model weights.
- `references/` — source links and design notes.
- `DECISION_GUIDE_BOOK_TO_SILICON.md` — plain-language record of the choices
  involved in adapting the earlier book model-consensus approach.
- `reports/` — reproducible R Markdown and rendered HTML for the official and
  exploratory reports. Only the official report is copied to GitHub Pages.

## Intended workflow

Open the project in RStudio. Run each step by opening the named R script and
clicking **Source**. No Terminal or command-line arguments are required.

1. Check the local setup:

   Open `scripts/00_check_environment.R` and click **Source**.

2. If the prepared inputs ever need to be regenerated, extract intervention
   texts and outcome definitions from the official repository-root files:

   Open `scripts/01_prepare_inputs.R` and click **Source**.

3. The completed model responses are already archived in `outputs/raw/`; do
   not rerun forecasts merely to reproduce the submission. To inspect how new
   calls would be planned without contacting a model:

   Open `scripts/02_run_forecasts.R`. In its USER SETTINGS block, set
   `active_model_ids` to the model IDs you want, leave
   `run_mode <- "preview"` and `confirm_model_calls <- FALSE`, and click
   **Source**.

4. For a genuinely new model run only, make a one-intervention smoke test:

   In the USER SETTINGS block, set `run_mode <- "smoke"` and
   `confirm_model_calls <- TRUE`, then click **Source**.

5. Only when intentionally adding a new model after reviewing its smoke test,
   run all 16 interventions:

   Set `run_mode <- "full"`, keep `confirm_model_calls <- TRUE`, and click
   **Source**.

   Nalanda's `run_prompt_grid()` handles model/prompt expansion, provenance,
   checkpoints, strong task identities, pending-call previews, and resume.
   New cost-gated phases accumulate in the canonical
   `outputs/raw/full_prompt_grid_results.csv`; compatible earlier results and
   checkpoints are reused without project-specific append/deduplicate code.

6. Aggregate all completed model/prompt forecasts:

   Open `scripts/03_build_submission.R` and click **Source**.

7. If at least two models were run, summarize agreement without changing the
   predeclared model set:

   Open `scripts/04_model_diagnostics.R` and click **Source**.

   This always writes prompt-sensitivity diagnostics. With two or more models,
   it also writes scale-normalized model agreement and correlations plus raw
   and scale-normalized cell-level disagreement.

8. Render both included reports:

   Open `scripts/05_render_reports.R` and click **Source**. The exploratory
   report is retained in `reports/model_diagnostics_report.html` for transparent
   comparison across all completed models. The concise official report is
   retained in `reports/primary_submission_report.html` and copied to
   `../docs/index.html` for GitHub Pages. Only the official report uses the
   three preselected family representatives.

9. After completing the human-authored registration fields, open
   `scripts/06_finalize_submission_in_rstudio.R`, read its checks, set
   `confirm_finalize <- TRUE`, and click **Source**.

Script 03 writes an unscaled median-consensus candidate and a separately
labelled GPT-4-`0.56` transfer sensitivity under `outputs/derived/`. The latter
is not presumed to be the primary method; the locked official prediction is at
`../predictions/team_16_T3_primary_v1.csv`.
Nalanda's native aggregation helper builds both the registered robust-median
hierarchy with equal family weight and explicitly labelled arithmetic-mean
sensitivity files.
Completing `metadata.json` and `registration.md` and creating the Zenodo release
remain deliberately separate lock-stage actions.

## Guardrails

- Tier 3 only; no personas, Tier-1 respondents, or Tier-2 moderator cells.
- No human outcome data from the benchmark or its pilots.
- No manual editing of individual prediction values.
- The forecasting script defaults to a no-cost preview and requires a separate
  explicit confirmation setting before contacting models.
- Save every model-level output before aggregation.
- Fix model inclusion, prompt inclusion, aggregation, and shrinkage before the
  full run is inspected.
- Drop the attempt if a complete valid first draft is not available by
  August 26, 2026, or if validation/deposit logistics are not settled by
  August 27.
