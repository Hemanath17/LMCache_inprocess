# Buildkite Web UI Setup: Comprehensive Tests

**Steps editor**: paste the contents of `buildkite-pipeline.yml`.

Configure `HF_TOKEN` as a protected Buildkite environment variable; do not
paste a token into the pipeline definition.

**GitHub trigger settings**:
- Filter: `build.pull_request.labels includes "full" || build.branch == 'main'`
- Rebuild on PR label change: Yes
- Skip queued / cancel running branch builds: Yes

Heavy test (10 parallel GPU steps) — run on `"full"` label or main push, not every PR.

> Builds whose only changes are docs/`*.md`/`LICENSE`/`.github/**` auto-pass
> via the repository path filter. Changes under `.buildkite/` always run. Add
> the `force-ci` label to the PR to
> bypass.

## Nightly Scheduled Build (rolling baselines)

Create a **Scheduled Build** on this same pipeline to upload performance baselines:

- **Schedule**: daily (e.g. `0 2 * * *` — 2am UTC)
- **Branch**: `main`
- **Extra Environment Variables**: `NEED_UPLOAD=true`

Each config step writes a date-stamped baseline (`<feature>-YYYYMMDD.json`) as a Buildkite artifact. The finalize step (`scripts/upload-baselines.sh`) collects them all, prunes files older than 5 days, and pushes a single commit to the `benchmarks-main` branch.

PR builds automatically compare against the rolling 5-day worst-case (max latency) baseline.
