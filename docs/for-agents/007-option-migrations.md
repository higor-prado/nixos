# Option Migrations

Status: retired

The temporary option-migration compatibility layer has been removed from the live
repo.

Current policy:

1. Do not keep long-lived removed-option compatibility shims in tracked hosts.
2. When removing a custom option, update the owning docs and affected hosts in the
   same change.
3. Validate the result with the normal gate set:

```bash
./scripts/run-validation-gates.sh structure
./scripts/check-config-contracts.sh
```

Historical note:

1. The repo previously used a dedicated registry-driven gate to keep
   removed-option compatibility messages alive during the den/dendritic
   migration.
2. That migration was completed, the tracked repo stopped using the removed
   options, and the compatibility layer was intentionally deleted to simplify the
   workflow.
