# Remove Script-Side Host Descriptors Progress

Related plan:
- [038-remove-script-side-host-descriptors.md](../plans/038-remove-script-side-host-descriptors.md)

## Baseline

- Parallel host metadata was not used by runtime code.
- Active script consumers were:
  - host extension checks
  - the host skeleton generator
- `lib/` is not empty; it still contains:
  - `lib/_helpers.nix`
  - `lib/mutable-copy.nix`
- There is no active `framework/` directory in the repo.

## Phase 0 Audit

Commands run:
- `sed -n '1,260p' scripts/lib/extension_contracts_checks.sh`
- `sed -n '1,260p' tests/scripts/new-host-skeleton-fixture-test.sh`
- `sed -n '1,260p' tests/fixtures/new-host-skeleton/desktop/modules/hosts/zeus.nix`
- `sed -n '1,260p' tests/fixtures/new-host-skeleton/server/modules/hosts/ci-runner.nix`

Findings:
- Host descriptors currently provide only two categories of facts:
  - host names
  - script-only integration booleans
- Host names can be derived directly from `hardware/*` and `modules/hosts/*`.
- The onboarding descriptor check is no longer protecting runtime architecture;
  it only validates the shape of the descriptor file itself.
- The generator fixture already validates the generated host files directly.

## Outcome

- Parallel host metadata is gone.
- Host tooling now derives tracked hosts from `hardware/*` and `modules/hosts/*`.
- The dedicated onboarding descriptor check and its fixture test were removed.
