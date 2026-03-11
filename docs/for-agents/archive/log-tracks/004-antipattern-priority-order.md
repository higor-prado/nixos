# Antipattern Priority Order

Date: 2026-03-10
Status: prioritized backlog

Ordering rule:
- top = easier to fix and high positive impact
- bottom = broader or more architectural

This file reflects the live antipatterns still listed in
`docs/for-agents/current/003-antipattern-diag.md`.
Resolved items from earlier waves are intentionally omitted.

## Priority

1. `check-runtime-smoke.sh` tracked local-tool exception
   - Why first:
     - smallest remaining surface
     - mostly a boundary/placement decision
     - easy to simplify later if the repo stops wanting tracked local runtime smoke

2. Residual `custom.user.name` compatibility bridge
   - Why second:
     - largest architectural payoff
     - broadest blast radius
     - touches hosts, features, private overrides, and user identity ownership

Resolved from this wave:
- hostname ownership duplication
- treating descriptor integrations and `custom.host.role` as accidental duplication

## Suggested Next Wave

If the goal is pragmatic improvement with low churn, start with:

1. `check-runtime-smoke.sh` boundary cleanup or removal
2. the remaining compatibility bridge / private override story
