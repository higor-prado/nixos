# Log Track Scaffold

Use this scaffold for new progress logs in `docs/for-agents/current/NNN-name-progress.md`.

## Naming

- Use the next available three-digit prefix.
- Match the active plan topic where possible.
- A log track records what happened during execution.
- When the work is closed and no longer needs to stay in the active surface,
  move the log to `docs/for-agents/archive/log-tracks/`.

## Structure

```md
# <Title> Progress

## Status

Planned / In progress / Completed / Blocked

## Related Plan

- [NNN-plan-name.md](/abs/path/to/plan.md)

## Baseline

- initial repo facts
- starting validation outputs

## Slices

### Slice 1

- changes made
- validation run
- diff result
- commit

### Slice 2

- ...

## Final State

- what is now true
- what remains open
```

## Rules

- Keep it factual.
- Prefer phase/slice summaries over chat-style narration.
- Record failed attempts only when they teach something useful.
- Always note the validation and diff outcomes for meaningful slices.
- Once a track is only historical, archive it.

