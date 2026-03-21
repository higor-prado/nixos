# Option Migrations

Status: retired.

There is no live option-migration compatibility layer in the tracked repo.

Current rule:

1. Remove dead option shims instead of preserving them long-term.
2. Update the owning docs and affected hosts in the same change.
3. Validate with the normal gate set.

Historical execution details now live under `docs/for-agents/archive/`.
