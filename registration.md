# Silicon Sample Benchmark — method registration form

This registration describes one primary Tier-3 entry from `team_16`.

---

## 0 · Approach identity and output

- **0.1 Team ★** — Team name: **Nalanda Model Consensus** (`team_16`). Members:
  Rémi Thériault (Université du Québec à Rimouski and New York University) and
  Jay Van Bavel (New York University). Corresponding contact:
  `remi.theriault@nyu.edu`.
- **0.2 Plain-language summary ★** — This entry asks three language models from
  different developer families to forecast the effects of each study
  intervention directly. Each model sees the intervention, neutral-control
  material, outcome definitions, and native response scales. Two fixed prompt
  formulations elicit signed average treatment effects. Repeated forecasts are
  combined within prompts and models before the three developer families are
  given equal weight in a median consensus.
- **0.3 Submission tier & approach family ★** — Tier 3; automated direct-effect
  forecasting; three-family LLM ensemble; zero-shot structured prompting;
  hierarchical median consensus.
- **0.4 Pipeline diagram** — (1) Extract the 16 intervention texts, three
  neutral-control texts, and 13 scored outcome definitions from the frozen
  benchmark template. (2) Construct one intervention-level job per condition.
  (3) Insert the same study description, control material, outcome definitions,
  and one intervention into each of two fixed prompt templates. (4) Obtain 13
  numeric ATE fields through a structured response schema. (5) Save every
  completion and a resumable checkpoint. (6) Take the median across completions
  within prompt and intervention, then across prompts within model. (7) Assign
  each selected model to its developer family and take the median across the
  three equally weighted families. (8) Reshape the consensus to the required
  `condition, outcome, ate` Tier-3 file and verify complete coverage.
- **0.5 Coverage ★** — Complete coverage: 16 interventions × 13 outcomes = 208
  ATE point predictions, each relative to the shared control condition. Every
  intervention–outcome pair occurs exactly once; there are no missing values.

## A · Scope of LLM use

- **A.1 Purpose** — LLMs generate the numerical ATE forecasts. Deterministic R
  code performs job construction, structured parsing, validation, checkpoint
  collection, hierarchical aggregation, diagnostics, and file creation.
- **A.2 Degree of automation ★** — Prediction generation and aggregation were
  fully automated, with no human editing or selection of individual ATEs.
  Humans selected the design, prompts, model roster, and aggregation rule and
  inspected content-neutral smoke tests and completeness diagnostics.

## B · Model / system details (once per model)

- **B.1 Model name(s)** — Primary contributors were:
  (1) `anthropic.claude-opus-4-6` (Anthropic Claude Opus 4.6, served through
  Vertex AI); (2) `gemini-3.1-pro-preview` (Google Gemini 3.1 Pro Preview,
  served through Vertex AI); and (3) `@gpt-5-mini/gpt-5-mini` (OpenAI
  GPT-5-mini, served through Azure OpenAI). All were accessed through the NYU AI
  Gateway. The hosted routes did not expose immutable weight hashes; route
  names and call dates are therefore part of the archived provenance.
- **B.2 Access & context mode** — API access through the NYU AI Gateway
  (`https://ai-gateway.apps.cloud.rt.nyu.edu/v1/`) using `nalanda` and `ellmer`.
  Calls were made on August 23, 2026. Each intervention–prompt–completion was a
  stateless one-turn request; context was not carried between interventions or
  prompt variants. Web search and tools were prohibited in the prompts.
- **B.3 Configuration** — Claude Opus 4.6: configured temperature 0, one
  completion per intervention and prompt. Gemini 3.1 Pro Preview: configured
  temperature 0, one completion per intervention and prompt. GPT-5-mini: five
  completions per intervention and prompt; sampling temperature was not
  user-controllable through the route, and the gateway-compatible configuration
  value was 1. A seed value of 42 was recorded in the model configuration where
  accepted, but deterministic replay is not guaranteed for hosted endpoints.
  Top-p, top-k, maximum output tokens, penalties, stop sequences, and reasoning
  effort were not manually overridden and therefore used route/provider
  defaults. The response schema constrained output to 13 numeric fields.
- **B.4 Customization** — No fine-tuning, RAG, automated prompt optimization,
  tools, web search, or agentic scaffolding. The only scaffolding was the fixed
  prompt text, structured numeric schema, checkpointing, and deterministic
  aggregation code.
- **B.5 Persistent memory** — None. Every request was stateless.
- **B.6 Inference stack** — N/A for local inference. All three models were
  remotely hosted commercial endpoints; quantization and serving hardware were
  not exposed.
- **B.7 Ensembles** — For each intervention–outcome cell, medians were taken in
  this order: completions within prompt; the two prompt-level values within
  model; models within developer family; and the three family values into the
  final consensus. There was one selected model in each family, so Anthropic,
  Google, and OpenAI each received one equal final vote. Five GPT-5-mini
  completions improved the stability of that component without increasing the
  OpenAI family's final weight.

## C · Prompts

- **C.1 Exact prompts** — The two verbatim templates are deposited as
  `forecast_pipeline/prompts/tier3_direct_forecast_v1.txt` and
  `forecast_pipeline/prompts/tier3_direct_forecast_v2.txt`. They were developed
  before the final three-model run. Revisions were based on task interpretation,
  schema completeness, conservative-calibration rationale, and content-neutral
  smoke-test behavior, never on hidden human outcomes. Placeholders were filled
  automatically with the archived control text, intervention text, and outcome
  definitions.
- **C.2 System-wide instructions** — No separate team-authored system prompt was
  used beyond provider defaults and the user prompt templates. The prompts
  instructed models to return all 13 numeric fields, avoid external tools and
  information, allow null or unintended effects, respect direction and native
  scales, and omit uncertainty intervals.
- **C.3 Prompt-design rationale** — Two differently worded but substantively
  aligned prompts reduce dependence on a single elicitation framing. Both
  define the estimand explicitly as intervention minus control, foreground the
  base rate of small effects from one brief exposure, distinguish proximal from
  distal outcomes, and remind models that negative or null effects are
  possible. Median aggregation limits the influence of an extreme generation.

## D · Persona / profile construction (Tiers 1–2)

- **D.1 Profile source** — N/A. This is a Tier-3 direct forecast; no personas or
  synthetic respondents were constructed.
- **D.2 Profile verbalization** — N/A.
- **D.3 Assignment & weighting** — N/A.

## E · Stimulus and survey administration

- **E.1 Stimulus presentation** — Intervention and control texts were extracted
  from the organizers' frozen questionnaire materials without paraphrasing.
  Each direct-forecast request displayed one complete intervention together
  with all three neutral control versions as the shared control material. For
  the state-adaptive extreme-weather condition, the source intervention field
  retained the complete state-to-case mapping and possible texts so the model
  could forecast the population-average effect rather than one state's effect.
- **E.2 Survey walk-through** — N/A as a respondent simulation. All 13 outcome
  definitions and scales were presented together in a single direct-forecast
  request for each intervention; no item-by-item conversation, attention check,
  or context carry-over was used.
- **E.3 Response elicitation** — Structured output with exactly 13 numeric
  fields, one signed ATE in original units for every scored outcome.

## F · Stochasticity and aggregation

- **F.1 Runs & seeds** — Each of 16 interventions was run through two fixed
  prompts. Claude Opus 4.6 and Gemini 3.1 Pro Preview each contributed one
  completion per intervention and prompt (32 each). GPT-5-mini contributed five
  completions per intervention and prompt (160), for 224 primary completion
  records. Seed 42 was requested/recorded where supported. Hosted endpoints may
  still change or be nondeterministic; raw outputs and checkpoints are archived.
- **F.2 Aggregation rule** — Median at every hierarchical level: completions
  within prompt, prompts within model, models within family, then families into
  the consensus. No completion or model was weighted by cost, repetition count,
  apparent agreement, or forecast magnitude.

## G · Validation & post-processing

- **G.1 Human validation** — Humans reviewed prompt previews, low-cost smoke
  tests, route failures, completeness, and aggregate diagnostic plots. No human
  benchmark outcomes were available. Individual ATEs were not manually edited,
  approved, removed, or reweighted.
- **G.2 Post-processing** — `ellmer` validated the 13 numeric response fields.
  `nalanda` checkpointed successful workflow units, permitted safe resumption,
  and recorded provenance. Failed units were not silently imputed; the final
  primary roster was required to have complete results. Tier-3 ATEs are
  differences and were not clipped to outcome endpoints. The final file was
  checked for 208 unique cells, required labels, numeric values, and no missing
  entries. No manual repairs or exclusions were applied.
- **G.3 Calibration corrections** — None. The submitted primary forecast is the
  unscaled hierarchical median consensus. A previously discussed GPT-4-derived
  `0.56` shrinkage factor was retained only as a labeled internal sensitivity
  file and was not applied to this entry.

## H · Learning and conditioning components

- **H.1 Fine-tuning data** — N/A. No team fine-tuning was performed.
- **H.2 Context & retrieval corpora** — No retrieval or literature corpus was
  used. Request context consisted only of the benchmark's study description,
  neutral control texts, focal intervention text, and outcome definitions,
  all archived under `forecast_pipeline/inputs/` and in the unchanged benchmark
  template. The underlying commercial models' proprietary pretraining corpora
  are not available to the team.

## I · Data inputs, blinding, and competing interests

- **I.1 Competing interests ★** — None. No funding was provided specifically
  for this project. Access to commercial model APIs was provided free of charge
  through the NYU AI Gateway as in-kind institutional infrastructure.
- **I.2 External human data †** — No external human dataset, published effect
  estimate, pilot result, meta-analysis, or calibration dataset was supplied to
  the models or used to fit the submitted forecasts. General knowledge encoded
  in proprietary model pretraining is not enumerable by the team.
- **I.3 Blinding attestation ★** — “I attest that no member of team_16 accessed,
  solicited, or was shown any human outcome data from this study, including
  pilots, before the prediction lock.” Signatures: **Rémi Thériault; Jay Van
  Bavel**. Date: **August 24, 2026**.
- **I.4 Contamination note †** — The exact training cutoff and corpus contents
  of the three hosted model routes were not disclosed to the team. The team has
  no known evidence that a model was trained on this benchmark's public
  preregistration or materials. The benchmark texts deliberately supplied in
  each request are fully documented and are not treated as contamination.

## J · Internal selection procedure

- **J.1 Design-space search †** — The primary roster was fixed as one capable
  representative from each of Anthropic, Google, and OpenAI before the final
  aggregation: Claude Opus 4.6, Gemini 3.1 Pro Preview, and GPT-5-mini. Two fixed
  prompts and the hierarchical median rule were also fixed before the final
  three-model aggregation. Eight models produced complete diagnostic runs:
  Claude Haiku 4.5, Claude Opus 4.6, Gemini 2.5 Flash-Lite, Gemini 2.5 Pro,
  Gemini 3.1 Flash-Lite, Gemini 3.1 Pro Preview, GPT-4o-mini, and GPT-5-mini. A
  GPT-OSS-120B route was attempted during technical testing but failed and did
  not contribute forecasts. Internal validation used only route availability,
  structured-schema success, full-cell completeness, resumability, cost, and
  descriptive agreement/sensitivity diagnostics against the other synthetic
  forecasts. No human outcome or pilot data were used, and disagreement with
  other models was not used to remove a preselected primary model. The
  exploratory response records are deposited separately from the primary
  records so this search remains auditable.

## K · Reproducibility & frozen artifacts

- **K.1 Code & materials** — Generation and aggregation code, exact prompts,
  configuration, extracted inputs, derived outputs, and the human-readable
  primary report are deposited in this repository under `forecast_pipeline/`:
  <https://github.com/centerconflictcooperation/silicon-sample-team16-primary-consensus>.
  The run used R 4.5.1, `nalanda` 0.0.2.2, `ellmer` 0.4.0, `dplyr` 1.2.1,
  `readr` 2.2.0, and `rmarkdown` 2.31. Credentials and gateway tokens are not
  deposited. Seed and route settings are recorded in `config/models.csv` and
  the response provenance.
- **K.2 Raw output logs †** — Two deposited CSVs separate the 224 primary
  completion records from 160 exploratory full-run records under
  `forecast_pipeline/outputs/raw/`. They retain the structured forecasts and
  row-level model, prompt, completion, task, configuration, and call-date
  provenance needed to reproduce aggregation and diagnostics without repeating
  model calls. File sizes, SHA-256 hashes, and UTC modification times are
  recorded in `forecast_pipeline/outputs/raw_output_sha256.csv`. Temporary
  smoke-run and resumability checkpoints were excluded from the clean release
  because they duplicate retained responses and are not inputs to the submitted
  prediction.
- **K.3 Computational resources** — The submitted primary ensemble contains 224
  full-run completion records: 32 Claude Opus 4.6, 32 Gemini 3.1 Pro Preview,
  and 160 GPT-5-mini. The NYU Gateway/Portkey export identified 427
  benchmark-related requests over the full development and execution workflow,
  including primary, exploratory, smoke-test, retry, and failed-route activity.
  Of these, 417 succeeded and 10 failed without recorded token usage.
  Successful requests consumed 1,230,196 input tokens and 349,721 output tokens
  (1,579,917 total). The Portkey export's cent-denominated cost values sum to a
  nominal provider cost of **US$3.5629788** for the 427 benchmark-related
  requests (US$3.5632102 across all 443 exported requests), consistent with the
  dashboard's rounded US$3.60 total. This cost was borne through the NYU AI
  Gateway and was not billed to the team. Benchmark-related requests ran from
  17:34:27 to 21:58:09 UTC on August 23, 2026, a 4.39-hour wall-clock window.
  Execution used at most four active requests and a 60-request-per-minute limit,
  with a 600-second timeout and up to three tries.

## L · Disclosure class

- **Disclosure class** — Intended Class A (open): method, prompts, code,
  predictions, and primary and exploratory structured outputs will be public in
  the released repository. A repository scan found no API keys, authorization
  headers, passwords, or other deposited secrets. No material requires escrow
  or withholding.
