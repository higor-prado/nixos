# Performance Tuning Experiment

Branch-local benchmark harness for `predator`.

## Scope

This experiment area is intentionally outside shared `scripts/`.

It collects four buckets:
- eval/build throughput (`15%`)
- boot/session readiness (`35%`)
- runtime desktop health (gate only)
- targeted runtime signals (`50%`)

## Usage

Run a baseline:

```bash
experiments/perf-tuning/run-baseline.sh
```

Run the full benchmark suite into a custom directory:

```bash
experiments/perf-tuning/run-benchmarks.sh experiments/perf-tuning/results/my-run
```

## Output

Each run writes:
- `summary.md`
- `build-eval.json`
- `boot/`
- `runtime-health/`
- `runtime-signals/`
- `meta/`

`results/` is ignored by Git. Summaries that matter should be copied into the
active progress log.

## Notes

- The runtime health gate uses the tracked `scripts/check-runtime-smoke.sh`.
- `hyperfine` and `stress-ng` are provided via `nix shell` inside the runner.
- If a benchmark changes live runtime behavior, use a temporary system test
  switch before collecting the "after" measurements.
