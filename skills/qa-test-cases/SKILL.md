---
description: Generate a Markdown QA test-case sheet from a feature's plan/spec. Use as stage 1 of the feature-gate pipeline, or when the user asks to write test cases for a feature.
disable-model-invocation: false
---

# Generate the QA test-case sheet (Markdown)

Produce ONE Markdown file at `docs/qa/<YYYY-MM-DD>-<feature-slug>-test-cases.md`, derived
from the feature's plan/spec. Do not invent requirements — cover what the plan specifies.

## Structure

### `## Summary`
- Milestone title, one-line scope, sources (links to the plan + any release notes), environment (dev URLs).
- **Case-counts matrix** — a table: rows = features; columns `Happy | Edge | Negative | Critical | High | Medium | Low | TOTAL`, plus a final **TOTAL** row.
- **Browser / device matrix** — which browsers/devices map to which TC-ID ranges.
- **Test accounts** — login/roles per environment.

### `## <Feature>` (one section per feature)
A table with columns:
`TC ID | Type | Priority | Title | Preconditions | Steps | Expected Result | Status`
- **TC ID**: feature-prefixed, zero-padded (e.g. `GEN-001`).
- **Type**: `Happy` | `Edge` | `Negative`. **Priority**: `Critical` | `High` | `Medium` | `Low`.
- **Steps**: numbered, written from the END-USER's point of view.
- **Expected Result**: the observable outcome.
- **Status**: leave BLANK — `feature-gate:qa-run` fills it (`Pass`/`Fail`/`Blocked`).

Cover happy paths, edge cases, and negative/error cases for each requirement. Keep the
counts matrix consistent with the cases you actually wrote.
