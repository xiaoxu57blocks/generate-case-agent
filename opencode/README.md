# OpenCode Adaptation

This directory contains an OpenCode skill adaptation of the Claude Code
Playwright Test Harness.

## Install The Skill

Copy the skill into OpenCode's global skill directory:

```bash
mkdir -p ~/.config/opencode/skill
cp -R /Users/57block/Jia/hobnob/generate-case-agent/opencode/skill/playwright-test-harness ~/.config/opencode/skill/
```

Restart OpenCode after installing so the skill metadata is loaded.

## Install Helper Scripts In A Target Project

OpenCode will use the skill instructions, but the target Playwright project
still needs the helper scripts:

```bash
cd /path/to/your/playwright-project
mkdir -p scripts
cp ~/.config/opencode/skill/playwright-test-harness/scripts/*.sh scripts/
chmod +x scripts/*.sh
```

If the target project lacks coding rules, copy the template:

```bash
mkdir -p .opencode/context
cp ~/.config/opencode/skill/playwright-test-harness/references/coding-rules.md .opencode/context/coding-rules.md
```

Then adapt it to the target app's UI library and test conventions.

## Configure DeepSeek V4 Pro

OpenCode chooses models with `--model provider/model`. Use the provider and
model name configured in your OpenCode installation.

Check available providers:

```bash
opencode providers list
```

Check available DeepSeek models:

```bash
opencode models deepseek
```

Typical forms are:

```bash
deepseek/deepseek-v4-pro
openai/deepseek-v4-pro
```

The exact name depends on your provider setup. If DeepSeek is exposed through an
OpenAI-compatible gateway, configure that provider in OpenCode first, then use
the model string reported by `opencode models <provider>`.

## Use From A Target Project

Run OpenCode in the target project:

```bash
cd /path/to/your/playwright-project
opencode run \
  --model deepseek/deepseek-v4-pro \
  "使用 playwright-test-harness，根据截图新增 TC-050 的 Playwright 测试。测试地址是 https://staging.example.com"
```

If your model is registered under another provider name, replace the model
argument:

```bash
opencode run \
  --model openai/deepseek-v4-pro \
  "使用 playwright-test-harness，根据截图新增 TC-050 的 Playwright 测试。测试地址是 https://staging.example.com"
```

The skill preserves the Claude Code harness behavior by passing context through
artifact files:

```text
/tmp/tc_{case_id}_requirement.md
/tmp/tc_{case_id}_design.md
/tmp/tc_{case_id}_run_report.md
```

The phase flow is:

```text
analyst -> architect -> coder -> runner -> summarizer
```

## Verify The Harness Is Being Used

From the target project root:

```bash
bash scripts/preflight.sh --opencode --json
```

Expected OpenCode-specific finding:

```json
{"level": "info", "key": "opencode_skill", "message": "OpenCode mode enabled..."}
```

During a real run, the model should mention or create the `/tmp/tc_*` artifacts
and follow the analyst/architect/coder/runner/summarizer phases.

## Target Project Expectations

The target project should provide:

- `playwright.config.*`
- `tests/` or `e2e/` with neighboring `*.spec.ts` examples
- page-object files under a consistent directory such as `pages/`
- fixtures such as `fixtures.ts`
- role/constants definitions where applicable
- `AGENTS.md` and/or `.opencode/context/coding-rules.md` for project conventions
- browser, Playwright trace, screenshot, or MCP support for selector validation

If the current repository only contains frontend app code and has no Playwright
project yet, first ask OpenCode to initialize the minimal Playwright
infrastructure, then generate the first smoke tests.
