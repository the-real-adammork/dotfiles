# Model schema & report layout

The extractor emits a `TypographicSystem` model as `model.json`. This file
documents every field and the Markdown layout to render from it.

## Model schema

```jsonc
{
  meta: {
    url, finalUrl, title, domain,
    viewports: [ {name,width,height}, … ],   // desktop 1440 / mobile 390
    rootFontSize,                              // px on <html>; anchors rem math
    capturedAt, tool
  },

  fonts: [ {
    family,                 // resolved family name
    category,               // serif | sans-serif | monospace | display | system | unknown
    source,                 // google-fonts | adobe-fonts | self-hosted | cdn | system-stack | unknown
    host,                   // e.g. fonts.gstatic.com (or null)
    faces: [ { weight, style, format, src, display, unicodeRange } ],  // from @font-face (may be empty if CORS)
    variableAxes: [ { tag, min, max, default } ],   // e.g. wght 100–900
    weightsUsed: [400,600,700],                      // weights actually applied
    fallbacks: ["system-ui","sans-serif"],
    usage: { roles:[…], textShare },                 // share of visible text 0–1
    classification                                   // primary-text | heading | mono | accent
  } ],

  scale: {
    base, unit,                                       // base px, "px+rem"
    ramp: [12,14,16,20,24,32,48,56],                  // distinct sizes (desktop)
    ratio: { value, name, confidence } | null,        // name e.g. "major third" or "custom/irregular"
    fluid                                             // bool: any role changes across viewports
  },

  roles: [ {
    role,                   // h1…h6, body, lead, a, strong, em, blockquote, code, pre, li, small, button, label, caption
    present,                // false if not found on the page
    selector,               // representative instance used
    desktop: TypeProps | null,
    mobile:  TypeProps | null,
    fluid, clampEstimate,   // size changes desktop→mobile; "clamp(34px → 56px)"
    sizeDelta: { desktopPx, mobilePx },
    instances: { desktop, mobile }   // how many such elements found
  } ],

  discovered: [ {
    id, rank,               // ranked by visible-text share
    props: TypeProps,       // desktop values
    usage: { elements, textShare },
    representativeSelectors: [ "p", "div.prose>p" ],
    mappedRole              // a fixed role name, or "unmapped" (interesting!)
  } ],

  colors: [ { hex, usage:{textShare}, onBackground, contrast } ],   // top text colors

  caveats: [ "…" ],         // extraction limits — MUST surface in the report
  observations: [ ]         // YOU fill this in
}
```

### TypeProps (atomic unit, used by roles + discovered)

```jsonc
{
  fontFamily: { resolved, stack },
  fontSize:   { px, rem },
  fontWeight,
  lineHeight: { px, ratio },        // ratio null when CSS line-height:normal
  letterSpacing: { em, px },
  textTransform, fontStyle,
  color, textDecoration,
  sample                            // real text found, as evidence
}
```

## Report layout

Render to `docs/briefs/typography-report-<domain>.md`:

```markdown
# Typographic system — <title> (<domain>)
captured <date> · desktop 1440 / mobile 390 · root <rootFontSize>px

## Fonts
- **<family>** — <category> · <source> · weights <weightsUsed> · <variable axes if any> · <textShare>% of text
  fallbacks: <fallbacks>
  <faces: weight/format/display if present, else note src unavailable>

## Scale
base <base>px · ramp <ramp joined ·> · ratio <ratio.value> (<ratio.name>, conf <confidence>) · fluid: <yes/no>

## Standard roles
| role | desktop | mobile | family | weight | line-height | tracking | notes |
|------|---------|--------|--------|--------|-------------|----------|-------|
| h1   | 56/1.05 | 34/1.1 | Inter  | 600    | 1.05        | -0.02em  | fluid 34→56 |
| body | 16/1.5  | 16/1.5 | Inter  | 400    | 1.5         | 0        |       |
| …    |         |        |        |        |             |          | (mark absent roles "—") |

(format size column as `px/lineHeightRatio`)

## Discovered styles (by usage)
1. 16/1.5 Inter 400 — 61% — body
2. 48/1.05 Inter 600 — heroes (unmapped)  ← name unmapped ones
…

## Text colors
- #0a0a0a — 78% — 19.2:1 on #ffffff
…

## Observations
- <your interpretation: one typeface vs many, weight-driven hierarchy, ratio,
  optical tracking on large sizes, fluid behavior, link treatment, etc.>

## Caveats
- <every entry from model.caveats[]>
```

Keep the report faithful to the model — do not invent numbers. Your judgment goes
only into `## Observations`, naming `unmapped` discovered styles, and prose.
