# Buildkite Web UI Setup: Integration Tests

**Steps editor**: paste the contents of `buildkite-pipeline.yml`.

Configure `HF_TOKEN` as a protected Buildkite environment variable; do not
paste a token into the pipeline definition.

**GitHub trigger settings**:
- Filter: *(none — runs on every push/PR)*
- Skip queued / cancel running branch builds: Yes

Lightweight (1 GPU) — good candidate for a required GitHub status check.
PRs labeled `"skip expensive ci"` still trigger the upload step, but the repo
wrapper exits green before uploading integration jobs. Add `force-ci` to run the
full suite anyway.

> Builds whose only changes are docs/`*.md`/`LICENSE`/`.github/**` auto-pass
> via the repository path filter. Changes under `.buildkite/` always run. Add
> the `force-ci` label to the PR to
> bypass.
