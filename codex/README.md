# Codex Adaptation

This directory contains a Codex skill adaptation of the Claude Code Playwright
Test Harness.

## Install

Copy the skill into your Codex skills directory:

```bash
mkdir -p ~/.codex/skills
cp -R /Users/57block/Jia/hobnob/generate-case-agent/codex/skills/playwright-test-harness ~/.codex/skills/
```

Start a fresh Codex session after installing so the skill metadata is available.

## Use

Open Codex in a real Playwright target project, then ask:

```text
使用 playwright-test-harness，根据这张截图新增 TC-050 的 Playwright 测试
```

The skill preserves the Claude Code harness behavior by keeping each phase
isolated and passing context through `/tmp/tc_{case_id}_*.md` artifacts:

```text
analyst -> architect -> coder -> runner -> summarizer
```

On first use in a target project, the skill copies its bundled helper scripts
into the target project's `scripts/` directory if they are missing.
If the target project has no Codex coding rules, copy the template:

```bash
mkdir -p .codex/context
cp ~/.codex/skills/playwright-test-harness/references/coding-rules.md .codex/context/coding-rules.md
```

Then adapt it to the target app's UI library and test conventions.

## Target Project Expectations

The target project should provide:

- `playwright.config.*`
- `tests/` or `e2e/` with neighboring `*.spec.ts` examples
- page-object files under a consistent directory such as `pages/`
- fixtures such as `fixtures.ts`
- role/constants definitions where applicable
- `AGENTS.md` and/or `.codex/context/coding-rules.md` for project conventions
- browser, Playwright trace, screenshot, or MCP support for selector validation

Run this from the target project root to check readiness:

```bash
bash scripts/preflight.sh --codex
```
