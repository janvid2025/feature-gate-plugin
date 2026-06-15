---
description: Execute a Markdown QA test-case sheet in a real browser and record Pass/Fail/Blocked back into it. Use as stage 4 of the feature-gate pipeline, or when the user asks to run the QA cases for a feature.
disable-model-invocation: false
---

# Execute the QA test-case sheet

Run each case in the sheet and record the result. Pick the runner by surface:
- **Web** (React web apps) → Playwright.
- **React Native** → Detox / CI. **NEVER run RN jest locally** (it OOMs and reboots the machine) — defer RN execution to CI.

## Procedure (web, per row in each `## <Feature>` table)
1. Launch Playwright and navigate to the environment URL from the Summary.
2. **Hard-reload (cache-bust)** so stale cache is never mistaken for a code bug.
3. Satisfy the Preconditions (log in with the listed test account, etc.).
4. Perform the numbered Steps exactly.
5. Compare the observed outcome to **Expected Result**.
6. Write `Pass`, `Fail`, or `Blocked` into the row's **Status** column; capture a screenshot and record its path.

For any discrepancy, state explicitly whether it is a real code bug or a cache/environment artifact.
Return a summary (counts of Pass/Fail/Blocked). Any `Fail`/`Blocked` is a pipeline failure — the orchestrator halts.
