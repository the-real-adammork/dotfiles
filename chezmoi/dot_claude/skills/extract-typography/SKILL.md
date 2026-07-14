---
name: extract-typography
description: Use when given a URL and asked to extract its fonts, type scale, or typographic system — to document, audit, or reverse-engineer how a website handles typography (headings, body, links, weights, line-height, tracking, responsive/fluid type).
---

# extract-typography

## Overview

Extract a web page's **fonts and typographic system** into a canonical model,
then render a human-readable report. A bundled Playwright script does the
deterministic extraction (computed styles at desktop + mobile, `document.fonts`
enumeration, usage clustering, scale inference); you turn the resulting
`model.json` into the report and write the interpretive observations.

The model schema and field meanings live in `references/report-format.md` — read
it before rendering a report.

## When to Use

- "Extract the fonts / typography / type system from <url>"
- "What's the type scale on <site>?" / "Document <site>'s typography"
- Reverse-engineering heading/body styles, weights, line-height, letter-spacing
- Comparing responsive type (mobile vs desktop, fluid `clamp()` scaling)

Not for: editing local CSS, generating new type systems from scratch, or
screenshots. Single URL per run (no crawling).

## Workflow

1. **Ensure dependencies** (first run only). From the skill directory:
   ```bash
   cd ~/.claude/skills/extract-typography
   [ -d node_modules ] || npm install        # installs playwright + chromium (postinstall)
   ```
   If `npm install` ran but the browser is missing: `npx playwright install chromium`.

2. **Run the extractor** from the user's project directory (so output lands in
   their repo):
   ```bash
   node ~/.claude/skills/extract-typography/scripts/extract.mjs <url>
   ```
   Writes `docs/briefs/typography-report-<domain>.model.json` and prints the path.
   Flags: `--out <dir>` (default `docs/briefs`), `--no-write` (stdout only),
   `--json` (also print model).

3. **Read the model** (`references/report-format.md` explains every field), then
   **render the report** to `docs/briefs/typography-report-<domain>.md` following
   the layout in that reference.

4. **Write the `observations`** yourself from the data — name discovered styles
   (e.g. "hero", "eyebrow/overline"), call out the ratio, single-vs-multi
   typeface hierarchy, optical tracking, fluid behavior. Surface every entry in
   the model's `caveats` array in the report.

5. **Report back** the file path and a 2–3 line summary.

## Quick Reference

| Field | Meaning |
|-------|---------|
| `fonts[]` | Typefaces actually rendered: source, weights used, fallbacks, variable axes |
| `roles[]` | Fixed standard classes (h1–h6, body, a, code…), per-viewport, `fluid` flag |
| `discovered[]` | Distinct styles clustered by usage; `mappedRole:"unmapped"` = not tied to a tag |
| `scale` | base, size ramp, inferred modular `ratio` (named), `fluid` |
| `colors[]` | Top text colors by usage + WCAG `contrast` |
| `caveats[]` | Extraction limits to surface in the report (CORS src, consent, blocked) |

## Common Mistakes

- **Inventing values instead of reading `model.json`.** All numbers come from the
  script. You only write `observations` and name discovered styles.
- **Dropping caveats.** If `caveats[]` is non-empty, the report must say so
  (e.g. "font src unavailable for cross-origin sheets").
- **Forgetting deps.** A `Cannot find package 'playwright'` error means step 1
  was skipped.
- **Running from the wrong directory.** Output goes to `./docs/briefs` relative to
  CWD — run from the target project.
