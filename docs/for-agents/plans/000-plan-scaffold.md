# Plan Scaffold

Use this scaffold for new execution plans in `docs/for-agents/plans/NNN-name.md`.

## Naming

- Use the next available three-digit prefix.
- Keep the name short and task-specific.
- A plan should exist only while the work is still relevant as an active guide.
- When the work is fully complete and no longer useful as an active guide,
  move the plan to `docs/for-agents/archive/plans/`.

## Structure

```md
# <Title>

## Goal

One short paragraph describing the outcome.

## Scope

In scope:
- ...

Out of scope:
- ...

## Current State

- concrete repo facts
- current owners / files
- current constraints

## Desired End State

- what should be true when the work is done

## Phases

### Phase 0: Baseline

Validation:
- ...

### Phase 1: <slice>

Targets:
- ...

Changes:
- ...

Validation:
- ...

Diff expectation:
- ...

Commit target:
- `type: message`

## Risks

- ...

## Definition of Done

- ...
```

## Rules

- Prefer small slices with explicit validation after each one.
- Include `diff-closures` when changing evaluated Nix behavior.
- State non-goals so the task does not inflate.
- Use concrete file paths.
- Record the intended commit split when the work is non-trivial.

