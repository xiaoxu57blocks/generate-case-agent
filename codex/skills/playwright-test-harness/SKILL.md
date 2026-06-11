---
name: playwright-test-harness
description: Use this skill when the user wants Codex to add, update, or generate a Playwright test from a screenshot, spreadsheet row, CSV test case, or natural-language test case. It preserves the Claude Code harness workflow with staged artifacts: analyst, architect, coder, runner, and summarizer.
---

# Playwright Test Harness for Codex

Use this skill inside a real Playwright target project. Do not generate tests in
the harness repository itself.

This skill adapts the Claude Code agent harness to Codex by preserving the
important behavior: each phase has a narrow role, writes an artifact to disk,
and the next phase reads only that artifact plus the target project files.

## Trigger Phrases

Use this workflow for requests such as:

- `增加 SA-001 用例`
- `add test for TC-050`
- `更新 TC-050 用例`
- `create a Playwright test from this screenshot`
- `add a new test file`

## Phase References

Read only the relevant reference when entering a phase:

- Requirement analysis: `references/test-analyst.md`
- Test design and selector validation: `references/test-architect.md`
- Code generation: `references/test-coder.md`
- Test execution and repair: `references/test-runner.md`
- Session summary and knowledge extraction: `references/test-summarizer.md`

## Artifact Contract

Use the case ID from the user input. Normalize only for filenames when needed
(`TC-050` may be written as `tc_050` if the existing script expects that).

Required artifacts:

- `/tmp/tc_{case_id}_requirement.md`
- `/tmp/tc_{case_id}_design.md`
- `/tmp/tc_{case_id}_run_report.md`

If the user does not provide a case ID, use `tc_draft` until the analyst phase
extracts or assigns one.

Never pass raw phase output directly through chat to the next phase. Persist it
to the artifact file, then make the next phase read that file.

## Workflow

0. Bootstrap helper scripts from this skill into the target project if they are
   missing. Create `scripts/`, copy this skill's bundled `scripts/*.sh` into it,
   and make them executable. Do not overwrite project-modified scripts without
   reading them first. If the target project lacks coding rules, create
   `.codex/context/coding-rules.md` from `references/coding-rules.md` and adapt
   it to the target app.

1. Run preflight once from the target project root:
   `bash scripts/preflight.sh --codex --json`

2. If `errors > 0`, stop and report the blocking findings. If only warnings
   exist, continue and mention them once.

3. Analyst phase:
   Read `references/test-analyst.md`, inspect the user input, ask only blocking
   clarification questions, then write `/tmp/tc_{case_id}_requirement.md`.

4. Architect phase:
   Read `references/test-architect.md` and the requirement artifact. Inspect
   target project conventions, existing specs, page objects, fixtures, constants,
   and available browser/Playwright validation tools. Write
   `/tmp/tc_{case_id}_design.md`.

5. Coder phase:
   Read `references/test-coder.md`, the requirement artifact, and the design
   artifact. Edit only the required spec/page-object files. Use the design plan
   as the source of truth for selectors, methods, and file placement.

6. Local validation:
   Run `bash scripts/typecheck.sh`.
   Run `bash scripts/lint-patterns.sh {modified-file-or-directory}`.
   Fix issues before continuing.

7. Runner phase:
   Read `references/test-runner.md`. Run the single affected test with:
   `bash scripts/test-quick.sh {test-file} "{exact test name}" {env}`.
   Fix runner-owned failures directly. Escalate selector/design issues back to
   the architect phase. Stop on environment constraints. Limit repair loops to
   five iterations.

8. Summarizer phase:
   Read `references/test-summarizer.md` and all artifacts. Produce the final
   session summary. Persist only reusable, non-obvious lessons that caused real
   iteration cost.

9. Cleanup:
   Run `bash scripts/cleanup-artifacts.sh {CASE_ID}` after the summary unless
   the user asks to keep artifacts for debugging.

## Codex Fidelity Rules

- Keep phase boundaries strict. The analyst does not design selectors; the
  coder does not invent selectors; the runner does not reinterpret requirements.
- Prefer artifact files over conversation memory.
- Read project instructions from `AGENTS.md` first, then `CLAUDE.md` if the
  target project already maintains it.
- Store Codex project facts in `.codex/context/project-facts.md` when possible.
  Use `.claude/context/project-facts.md` only for projects that intentionally
  share knowledge with Claude Code.
- Use available browser or Playwright tooling to validate selectors. If no
  browser/MCP tool is available, rely on existing specs, page objects, traces,
  screenshots, and focused test runs. Do not guess selectors.
- Keep the harness project-agnostic. Target-project business rules belong in the
  target project's `AGENTS.md`, `.codex/context/`, or test docs.
