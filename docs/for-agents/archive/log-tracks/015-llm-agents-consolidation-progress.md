# LLM Agents Consolidation Progress

Date: 2026-03-10
Status: completed

Plan:
- `docs/for-agents/plans/013-llm-agents-consolidation-plan.md`

## Baseline

Current live shape:
- five HM-only agent wrappers on `predator`
- one NixOS-only agent wrapper on `aurelius`
- no meaningful per-agent custom logic left in tracked code

## Phase Checklist

- [x] Phase 0: baseline capture
- [x] Phase 1: create consolidated `llm-agents` feature
- [x] Phase 2: replace host includes
- [x] Phase 3: remove obsolete `ai/*`
- [x] Phase 4: docs cleanup and closeout

## Notes

- Baseline inspection showed `openclaw` exists in both `x86_64-linux` and `aarch64-linux` `llm-agents` package sets.
- The initial consolidation kept one file and one public aspect, but used a narrow `host.name == "aurelius"` gate for `openclaw`; this was intentionally left as a follow-up cleanup target for semantic host selection.
- `predator` now includes a single `llm-agents` feature instead of five thin HM wrappers.
- `aurelius` now includes the same `llm-agents` feature instead of a dedicated `ai-openclaw` wrapper.
- `nix store diff-closures` for `predator` system and Home Manager before/after consolidation were empty.
- `structure`, `aurelius`, docs drift, changed-file quality, and skeleton fixture validation passed during execution.
