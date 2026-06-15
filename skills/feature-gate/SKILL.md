---
description: Run the full feature-gate pipeline for a feature — generate the QA sheet, implement test-first, run all tests, security review, code review, optimization — halting on the first failure and committing only on explicit user approval. Use when the user wants to build or ship a feature through the gate.
disable-model-invocation: false
---

# Feature Gate — run a feature through the full quality gate

Input: `$ARGUMENTS` = the feature name or the path to its plan/spec.

Run the stages **in order**. **Halt at the first failure** — do not proceed and do not auto-fix
silently; report what failed, where, and the evidence, then wait for the user. The only
success-path pause is the final gate (stage 8).

## Stages
1. **QA sheet** — invoke `feature-gate:qa-test-cases` to write `docs/qa/<date>-<feature>-test-cases.md` from the plan. Proceed automatically.
2. **Implement (TDD)** — use `superpowers:test-driven-development`: per requirement, write a failing test → confirm it fails → minimal code → confirm it passes.
3. **Full test suite** — run the project's verify command from `.feature-gate.json` `.verify`. If none is set, run the surface-appropriate suite explicitly — **web:** `npm run typecheck && npm run lint && npm run test`; **React Native:** `npm run typecheck && npm run build` locally (full RN tests run in CI — never run RN jest locally, it OOMs). Show the actual command(s) and their real output and confirm exit 0 (`superpowers:verification-before-completion`). **Never claim tests passed if they were not actually run.** On failure → HALT + report.
4. **Execute QA cases** — invoke `feature-gate:qa-run` to run each sheet case in a real browser and write Pass/Fail/Blocked into the sheet. On any Fail/Blocked → HALT + report.
5. **Security review** — invoke `security-review`. Cover SQL injection, XSS, auth/authz, secrets, injection, and — for multi-tenant projects — tenant isolation / cross-tenant data leaks (honor the isolation rules in the project's CLAUDE.md). On any finding → HALT + report.
6. **Code review** — invoke `review-gate` (or `code-review`) on the diff. On a blocking finding → HALT + report.
7. **Optimization** — invoke `simplify` to apply reuse/efficiency cleanups, then RE-RUN stage 3 once. If it goes red → HALT + report.
8. **Final gate** — present: the QA sheet (with Pass/Fail), the test output, the security verdict, the review verdict, the optimization notes, and the full `git diff`. Ask the user to review. **Commit ONLY when the user explicitly says to commit.** Never commit autonomously. No personal names or ticket IDs in the commit message.
