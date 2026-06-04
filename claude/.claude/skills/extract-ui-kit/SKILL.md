---
name: extract-ui-kit
description: Use when given a URL and asked to extract its design system / UI kit — color palette & tokens, spacing scale, border-radius, borders, shadows/elevation, button styles and hover animations, navigation bar styling, layout primitives (containers, breakpoints, gaps), and motion. Includes the typographic system. For type only, use extract-typography.
---

# extract-ui-kit

## Overview

Extract a web page's **design system** into a canonical model, then render a
report. A bundled Playwright script captures computed styles at desktop + mobile,
**hovers representative buttons/nav links to observe real hover deltas**,
enumerates CSS-variable tokens, and clusters everything into scales (color,
spacing, radii, shadows, borders, layout, motion). It reuses
`extract-typography`'s shared engine, so the typographic system comes along for
free in one crawl.

The model schema and report layout are in `references/report-format.md` — read it
before rendering a report.

## When to Use

- "Extract the design system / UI kit / component styles from <url>"
- "What are <site>'s button styles, hover animations, spacing, radii, colors?"
- "Document <site>'s nav bar / color palette / elevation / layout primitives"
- Reverse-engineering a design language to study or rebuild

Not for: type only (use **extract-typography**), editing local CSS, or screenshots.
Single URL per run.

## Dependency

This skill **reuses `extract-typography`'s `lib.mjs` and its Playwright/Chromium
install**. Ensure that skill is installed first:
```bash
[ -d ~/.claude/skills/extract-typography/node_modules ] || \
  (cd ~/.claude/skills/extract-typography && npm install)
```
extract-ui-kit itself needs no separate install.

## Workflow

1. Ensure the dependency above is satisfied.
2. Run from the user's project directory (output lands in their repo):
   ```bash
   node ~/.claude/skills/extract-ui-kit/scripts/extract.mjs <url>
   ```
   Writes `docs/briefs/ui-kit-report-<domain>.model.json` and prints the path.
   Flags: `--out <dir>` (default `docs/briefs`), `--no-write`, `--json`.
3. Read the model, then render `docs/briefs/ui-kit-report-<domain>.md` following
   `references/report-format.md`.
4. Write `observations` yourself: name the accent vs. neutrals, the spacing base
   unit, the elevation system, the hover language, whether the kit is token-driven.
   **Surface every entry in `caveats`** (esp. that color roles are inferred and
   tokens/breakpoints may be missing on cross-origin CSS).
5. Report the file path + a short summary.

## Quick Reference

| Field | Meaning |
|-------|---------|
| `tokens` | CSS custom properties grouped (color/space/radius/shadow/font) — the real token layer when same-origin |
| `colors` / `pageBg` | Palette by usage + inferred role; `pageBg` from the page's root background |
| `spacing` | `baseUnit`, `scale`, and `hierarchy` (section/container/card/inline) |
| `radii` `borders` `shadows` | Value scales mapped to element roles; shadows leveled sm→xl |
| `buttons` | Variant catalogue with `base`, observed `hover` deltas, and `transition` |
| `nav` | Header styling: height, bg, position, links + hover, CTA, mobile collapse |
| `layout` | `containerMaxWidth`, `gutterX`, `breakpoints`, grid gaps |
| `motion` | Aggregated `durationsMs`, `easings`, `animatedProperties` |
| `typography` | fonts + scale + roles (reused from extract-typography) |
| `caveats` | Limits to surface in the report |

## Common Mistakes

- **Inventing values** — every number comes from the model; you write prose only.
- **Treating inferred color roles as fact** — accent/surface/muted are heuristic
  (caveat says so); confirm against the brand in observations.
- **Skipping the dependency** — a `Cannot find package 'playwright'` or
  `Cannot find module '../../extract-typography/...'` error means extract-typography
  isn't installed.
- **Dropping caveats** — empty tokens/breakpoints usually mean cross-origin CSS, not
  that the site lacks them; say so.
