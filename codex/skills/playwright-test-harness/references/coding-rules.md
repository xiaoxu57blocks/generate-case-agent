# Coding Rules — Reference Template

> **This file is a reference template shipped with Playwright Test Harness.**
>
> It collects Playwright authoring patterns the harness's `test-architect` and
> `test-coder` agents will respect when generating tests. **Copy this file into
> your target project's `docs/coding-rules.md`** and adapt it to your project.
>
> - **Generic rules** (no element-interaction gating, no element-level timeouts,
>   virtual scroll handling, MCP workflow) apply to any Playwright project.
> - **Ant Design–specific rules** (`.ant-spin-spinning`, `.ant-modal`,
>   `.ant-table-tbody-virtual-holder`) are kept as concrete examples — replace
>   the selectors with your UI library's equivalents (Material UI, Chakra, etc.)
>   or delete the section if it doesn't apply.
> - **Project-specific rules** (filename without extension, "Files tab",
>   connector flows) are illustrative — delete or replace with your own.
>
> The architect agent reads this file from the **target project's**
> `docs/coding-rules.md` (preferred) or `.claude/coding-rules.md` (fallback).
> If neither exists, it falls back to the project's `CLAUDE.md`.

Full examples behind the high-level rules. Read this when you need a concrete
code pattern or want to understand *why* a rule exists.

---

## MCP Workflow

### Step-by-step

1. `browser_navigate` → open the test page
2. `browser_snapshot` → understand DOM structure
3. `browser_click` / `browser_evaluate` → verify each interaction works
4. `browser_close` → **mandatory** before running Playwright tests
5. Write test code only after MCP confirms all elements and interactions work

```javascript
// Check page state (useful on timeout or unexpected behaviour)
await mcp__playwright__browser_evaluate({
  function: `() => ({
    url: window.location.href,
    isLoading: !!document.querySelector('.ant-spin'),
    hasOverlay: !!document.querySelector('.ant-modal'),
    visibleText: document.body.textContent.substring(0, 200)
  })`,
});
```

### Post-action verification

After submitting a dialog or clicking a button, observe the resulting page state *in MCP* before writing any code:

1. Execute the action
2. Wait for completion signals (toast disappears, dialog closes)
3. Observe whether the target area updates automatically

Only add `page.reload()` if you observe the page does **not** auto-refresh. Never infer reload behaviour from code — the application's reactive update behaviour varies.

---

## Element Interaction

### Direct interaction — never gate on `isVisible()`

```typescript
// ❌ WRONG: isVisible() returns false during page load even if element will appear
const isAvailable = await element.isVisible();
if (isAvailable) { await element.click(); }

// ✅ CORRECT: Playwright auto-waits; fails with a clear error if element never appears
await element.click();
```

`isVisible()` is acceptable only for **conditional logic** where the element may legitimately not exist:

```typescript
// ✅ OK: avoid double-clicking an already-open drawer
const isOpen = await this.page.locator("text=Newest First").isVisible().catch(() => false);
if (!isOpen) { await openButton.click(); }
```

### Never use element-level timeouts

```typescript
// ❌ WRONG
await expect(element).toBeVisible({ timeout: 3000 });

// ✅ CORRECT — rely on global/test-level timeout
await expect(element).toBeVisible();
```

### Never use `test.skip()` for missing elements

```typescript
// ❌ WRONG — hides real failures
if (!(await element.isVisible())) { test.skip(); }

// ✅ CORRECT — let the test fail with a clear error
await element.click();
```

---

## Waiting for UI to Stabilise

### Loading spinners

```typescript
// Wait for Ant Design spinner before interacting
await this.page.locator(".ant-spin-spinning").first().waitFor({ state: "detached" }).catch(() => {});

// Inside a modal: wait for modal-scoped spinner too
await this.page.locator(".ant-modal .ant-spin-spinning").first().waitFor({ state: "detached" }).catch(() => {});
```

### Blocking modal dialogs ("intercepts pointer events")

```typescript
// Dismiss any blocking OK modal before the intended action
try {
  await this.page.locator('button:has-text("OK")').first().click({ timeout: 1000 });
  await this.page.waitForTimeout(500);
} catch { /* no modal, continue */ }
await closeButton.click();
```

---

## Selector Patterns

### No `data-testid`: anchor on text, traverse to sibling button

```typescript
// ❌ WRONG: data-testid doesn't exist on this container
this.page.locator('[data-testid="table-views-panel"]').getByRole("button", { name: "ellipsis" });

// ✅ CORRECT: anchor on visible text, go up one level, find sibling button
this.page.getByText(viewName, { exact: true }).first().locator("..").getByRole("button", { name: "ellipsis" });
```

### Split-view top-right ellipsis: always `.last()`

```typescript
// ❌ WRONG: no wrapping testid exists
this.page.locator('[data-testid="split-view-view"]').last().getByRole("button", { name: "ellipsis" });

// ✅ CORRECT: top-right toolbar ellipsis is always the last one on the page
this.page.getByRole("button", { name: "ellipsis" }).last();
```

### Actions hidden behind a dropdown caret

Some actions (e.g. "Export all") live inside a dropdown triggered by a `"down"` caret, not a standalone button.

```typescript
// ❌ WRONG
await this.page.getByRole("button", { name: /export all/i }).click();

// ✅ CORRECT: open the caret first, then click the menuitem
await this.page.getByRole("button", { name: "down" }).first().click();
const downloadPromise = this.page.waitForEvent("download");
await this.page.getByRole("menuitem", { name: /export all/i }).click();
return await downloadPromise;
```

### Popover items vs dropdown menu items

Popovers render their content as `button` elements, not `menuitem`. Example: the Last Sync panel in the Files tab.

```typescript
// ❌ WRONG: "Sync now" is inside a popover, not a dropdown
await this.page.getByRole("menuitem", { name: /Sync now/i }).click();

// ✅ CORRECT
await this.page.getByRole("button", { name: /Sync now/i }).click();
```

### Inline banner buttons: scope to container, not `aria-label` filter

```typescript
// ❌ WRONG: aria-label filter is unreliable for SVG icon buttons
page.locator("button").filter({ has: page.locator('[aria-label="close"]') }).last();

// ✅ CORRECT: scope to the banner container class
page.locator(".ant-flex-gap-small").getByRole("button", { name: "close" });
```

### Ant Design SVG icons: use `data-icon` attribute

```typescript
// ❌ WRONG: button name doesn't match the icon name
page.getByRole("button", { name: "info-circle" });

// ✅ CORRECT: Ant Design renders icons as inline SVG with data-icon attribute
page.locator('button:has([data-icon="info-circle"])').first();
```

---

## Virtual Scroll Tables

Ant Design virtual scroll tables (`ant-table-tbody-virtual-holder`) only render rows inside the viewport. Off-screen rows have no DOM children.

### Infer row type from text content, not child visibility

```typescript
// ❌ WRONG: child isVisible() always false for off-screen rows
const isLeaf = await row.locator("button.some-indicator-class").isVisible();

// ✅ CORRECT: read from the row's own textContent
const text = (await row.textContent())?.trim() ?? "";
```

### Re-query after each DOM mutation

```typescript
// ❌ WRONG: snapshot taken once, misses rows revealed by expansion
const allRows = this.pickerRows();

// ✅ CORRECT: fresh query each iteration
while (!targetVisible) {
  const rows = this.pickerRows();
  let expanded = false;
  for (let i = 0; i < await rows.count(); i++) {
    if (await rows.nth(i).locator("button.expand-icon").isVisible()) {
      await rows.nth(i).locator("button.expand-icon").click();
      expanded = true;
      break;
    }
  }
  if (!expanded) break;
}
```

### Scroll into view before asserting off-screen rows

```typescript
// ✅ CORRECT: scroll the virtual holder until the row enters the DOM
const virtualHolder = this.page.getByRole("dialog").locator(".ant-table-tbody-virtual-holder");
for (let i = 0; i < 10; i++) {
  if (await targetRow.isVisible().catch(() => false)) break;
  await virtualHolder.evaluate((el) => (el.scrollTop += 200));
  await this.page.waitForTimeout(100);
}
await expect(targetRow.locator('button[role="switch"]')).toHaveAttribute("aria-checked", "false");
```

### Never use `scrollTop +=` on top-level SPA containers

Mutating `scrollTop` on a page-level container can trigger React Router to push a new URL, closing the page context.

```typescript
// ❌ WRONG: triggers URL navigation on the timeline page
await this.page.locator(".timeline-list").evaluate((el) => (el.scrollTop += 600));

// ✅ CORRECT: let Playwright scroll the target element into view
await this.page.locator(".target-card").scrollIntoViewIfNeeded();

// ✅ CORRECT: scrollTop inside a dialog is safe (no SPA routing)
await this.page.getByRole("dialog").locator(".ant-table-tbody-virtual-holder")
  .evaluate((el) => (el.scrollTop += 200));
```

---

## Assertions

### `not.toBeVisible()` on multi-match locators: add `.first()`

Playwright strict mode throws on negative assertions if the locator matches multiple elements.

```typescript
// ❌ WRONG: strict mode violation if 3 elements match
await expect(this.timeCardTag("New")).not.toBeVisible();

// ✅ CORRECT
await expect(this.timeCardTag("New").first()).not.toBeVisible();
```

### Toast notifications: assert on the persistent state that follows

Ant Design toasts auto-dismiss in 1–3 seconds — the assertion may evaluate after dismissal.

```typescript
// ❌ WRONG: toast may be gone already
await expect(page.getByText("Case created successfully!")).toBeVisible();

// ✅ CORRECT: assert on the screen that persists after the toast
await expect(page.getByText("Your case is uploading. Keep this browser window open until it is complete.")).toBeVisible();
```

### Check toggle/checkbox state before clicking

```typescript
// ❌ WRONG: unconditional click may deselect a pre-checked item
await checkbox.click();

// ✅ CORRECT
const isChecked = await checkbox.isChecked().catch(() => false);
if (!isChecked) { await checkbox.click(); }
```

---

## Role-Based UI Testing

Internal and external users often have different UI access paths for the same feature. Parameterize methods rather than hardcoding one path.

```typescript
async openCaseHistoryDrawer(userType: 'internal' | 'external' = 'internal') {
  await test.step("Ensure Case History drawer is open", async () => {
    const isOpen = await this.page.locator("text=Newest First").isVisible().catch(() => false);
    if (!isOpen) {
      if (userType === 'external') {
        await this.page.getByRole('button', { name: 'more' }).click();
        await this.page.getByRole('menuitem', { name: 'Open Case History' }).click();
      } else {
        await this.page.locator('button:has-text("Open Case History")').click();
      }
    }
    await this.page.locator('.ant-spin-spinning').first().waitFor({ state: 'detached' }).catch(() => {});
    await expect(this.page.locator("text=Newest First")).toBeVisible();
  });
}
```

Never assume the same UI elements exist across roles — always validate with MCP first.

---

## Timeouts

Valid reasons to set a large `test.setTimeout`:
- AI document processing / annotation pipeline
- Known slow connector APIs (SmartAdvocate: up to 90 s)

```typescript
test.setTimeout(300_000); // SmartAdvocate connector API
```

Never increase timeout speculatively. Reproduce the slow step in MCP first to confirm the cause.

---

## Debugging

### Runtime: use `console.log`, not MCP

MCP cannot be open while a Playwright test runs ("Browser is already in use"). For runtime debugging, add temporary `console.log` and grep the output:

```bash
npx playwright test ... 2>&1 | grep "console.log output"
```

### Read the full stack trace

Generic error messages ("Target page closed", "Test ended") don't show *where* the failure is. Filter for relevant frames:

```bash
npx playwright test ... 2>&1 | grep -E "(Error:|at pages/|at tests/|at factories/)"
```

Identify the exact method and file before making any fix.

---

## Case Factory: `create()` vs `update()` Navigation

- **`create()`** navigates to `/cases` internally — "Create Case" button only exists there.
- **`update()`** does **not** navigate — "Update case" button exists on any case page (timeline, chrono, flowsheets). The caller controls the current page context.

```typescript
// Stay on the chrono page throughout; update() opens the dialog in place
await timelinePage.load(sharedCaseId);
await casesPage.caseFactory.withExistingCase(caseName).withCaseType("MVA").update();
await timelinePage.verifyFirstTimecardHasTime(false); // still on chrono
```
