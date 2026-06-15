# feature-gate-plugin

A Claude Code plugin that gates a feature through a quality pipeline and **blocks unverified commits**.
It exists to fix one failure mode: an agent confidently reporting "done / fixed" when it isn't.
"Done" is redefined to mean *a verification command exited 0 and its output was shown* — not a claim.

## Components

| Piece | Type | What it does |
|---|---|---|
| `skills/feature-gate` | skill (the command) | Orchestrates the 8-stage pipeline: QA sheet → TDD → full tests → execute QA → security → code review → optimize → human gate. Halts on the first failure; commits only on explicit user approval. |
| `skills/qa-test-cases` | skill | Generates a Markdown QA test-case sheet from a feature's plan. |
| `skills/qa-run` | skill | Executes the QA sheet in a real browser (Playwright) and writes Pass/Fail/Blocked back. |
| `hooks/block-unverified-commit.sh` | PreToolUse(Bash) | Blocks `git commit` unless verification passes. Token-aware (catches `git -c k=v commit`, `git -C path commit`, env-prefixed, chained). Fail-closed. |
| `hooks/check-edited-file.sh` | PostToolUse(Edit\|Write) | Advisory per-file lint (`php -l`, `eslint`). Never blocks. |
| `lib/run-verify.sh` | helper | Resolves and runs the project's verify command (see config below). |

## Per-project config: `.feature-gate.json`

Each project that should gate commits puts a `.feature-gate.json` at its repo root. See
`feature-gate.json.example`:

```json
{ "verify": "npm run typecheck && npm run lint && npm run test" }
```

- `verify` — the shell command the commit gate runs. Exit 0 = allow the commit; non-zero = block.
- **React Native projects:** set `verify` to `npm run typecheck && npm run build` only — **never** run RN jest
  locally (it OOMs the machine). Run the full RN test suite in CI instead.

### Defaults & overrides

- No `.feature-gate.json` present → the gate runs a conservative default: `npm run typecheck && npm run lint`
  (no test runner, so it can't trigger an RN-jest OOM on an unconfigured project). Configure `.verify` to
  include your tests so the commit gate enforces them too.
- `FEATURE_GATE_DEFAULT_VERIFY` env var overrides that default command.
- Malformed `.feature-gate.json` → the gate **blocks** (exit 2) rather than silently falling back.

## Security properties (as built)

Hardened during code review and covered by the test suite:

- **Token-aware commit detection** — the gate catches `git commit`, `git -c key=val commit`
  (e.g. GPG-skip), `git -C <path> commit`, `git --no-pager commit`, env-prefixed and chained
  forms, and double-spaced variants. It does not rely on a fragile substring match.
- **Fail-closed** — a malformed `.feature-gate.json` blocks the commit (exit 2) instead of
  silently falling back to the default.
- **Honest reporting** — the orchestrator shows the real verify command and its output and
  never claims tests passed when they were not run.
- **Hermetic tests** — the suites ignore the ambient `CLAUDE_PROJECT_DIR` so results are
  deterministic regardless of where they run.

## Install

`feature-gate` is the **plugin** name and `local-tools` is the **marketplace** name (both
defined in `.claude-plugin/marketplace.json`). Installs persist across sessions, so once
installed the commit gate and lint hooks are active in every project.

### For your team (recommended)

This repo is a self-contained marketplace, so teammates install it straight from GitHub —
no shared filesystem path required. Run these inside Claude Code:

```
/plugin marketplace add janvid2025/feature-gate-plugin
/plugin install feature-gate@local-tools
```

Update later with `/plugin marketplace update local-tools`, then restart Claude Code.

### From a local clone

Point `marketplace add` at the **repo root** — the directory that *contains* `.claude-plugin/`,
not the `.claude-plugin/` folder itself:

```
/plugin marketplace add /path/to/feature-gate-plugin
/plugin install feature-gate@local-tools
```

### Per session only (quick dev / testing)

Load the plugin for the current session without installing it:

```bash
claude --plugin-dir /path/to/feature-gate-plugin
```

### Verify it loaded

```bash
claude plugin list                                # feature-gate@local-tools, enabled
claude plugin details feature-gate@local-tools    # inventory: 3 skills + 2 hooks
```

Or run `/plugin` in a session and open the **Installed** tab; the three skills then appear
in the skills list and the PreToolUse/PostToolUse hooks show under `/hooks`.

## Tests

```bash
for t in tests/*.test.sh; do bash "$t"; done
```

All suites are hermetic and pass in a clean environment (17 assertions across 3 files).
