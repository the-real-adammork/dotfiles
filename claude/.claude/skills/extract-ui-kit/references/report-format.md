# UI-kit model schema & report layout

The extractor emits a design-system model as `ui-kit-report-<domain>.model.json`.
This documents every field and the Markdown layout to render from it.

## Model schema

```jsonc
{
  meta: { url, finalUrl, title, domain, viewports, rootFontSize, capturedAt, tool },

  tokens: {                       // CSS custom properties (same-origin :root)
    count, color:{}, space:{}, radius:{}, shadow:{}, font:{}, other:{}
  },

  pageBg,                         // page root background (drives contrast)
  colors: [ {                     // top text/bg/border colors by usage
    hex, role,                    // page-bg|surface|primary/accent|text|muted|border|subtle
    usage:{ share, as:["text","background","border"] },
    contrastOnPageBg
  } ],

  spacing: {
    baseUnit,                     // inferred grid unit (e.g. 4 or 8)
    scale:[…],                    // distinct spacing values by frequency
    hierarchy:{ sectionPaddingY, containerPaddingX, cardPadding, inlineGap }
  },

  radii:   [ { px, rem, label?, count, roles:[…] } ],       // label "pill/full" for 9999
  borders: [ { width, style, color, count } ],
  shadows: [ { level, value, count, roles:[…] } ],          // level sm→3xl by strength

  buttons: [ {
    variant,                      // filled | outline | ghost/link
    count,
    base:{ bg, color, border, radius, paddingY, paddingX, font:{size,weight}, textTransform, shadow },
    hover:{ background?, color?, border?, shadow?, transform?, opacity? } | null,  // observed deltas
    transition:{ property, duration, timing } | null,
    representativeSelector, sample
  } ],

  nav: {
    found, height, background:{color,hasImage}, position, borderBottom, shadow, paddingX,
    linkGap, links:{ font, color, hover, transition } | null,
    cta:{ variant, bg, color, radius } | null,
    mobile:{ desktopLinks, mobileLinks, collapses }
  },

  layout: { containerMaxWidth:[…], gutterX:[…], breakpoints:[…], grid:{ commonGaps:[…] } },

  motion: { durationsMs:[…], easings:[…], animatedProperties:[…] },

  typography: { fonts, scale, roles },   // reused from extract-typography (run that for full type report)

  caveats:[…], observations:[]           // YOU fill observations
}
```

## Report layout

Render to `docs/briefs/ui-kit-report-<domain>.md`:

```markdown
# Design system — <title> (<domain>)
captured <date> · desktop 1440 / mobile 390 · page bg <pageBg>

## Color
| hex | role | usage | contrast vs bg |
(accent first, then neutrals; note inferred roles)
+ tokens summary if tokens.count > 0

## Spacing
base <baseUnit>px · scale <scale> · section <sectionPaddingY> · container gutter <containerPaddingX> · card <cardPadding> · inline gap <inlineGap>

## Radii / Borders / Shadows
radii: <px → roles> · pill: yes/no
borders: <width style color>
elevation: sm <…> · md <…> · lg <…>  (with roles)

## Buttons
For each variant: a line of base props, then **hover:** the observed deltas, then transition.
e.g.  **primary (filled)** — bg #533afd, white, radius 4, pad 16/24, weight 400
      hover: background #533afd → #4032c8 · transition background 0.3s cubic-bezier(.25,1,.5,1)

## Navigation
height · background (note transparent/blur) · position (sticky/fixed) · border/shadow · link style + hover · CTA · mobile: collapses?

## Layout
container max-width <…> · gutter <…> · breakpoints <…> · grid gaps <…>

## Motion
durations <…>ms · easings <…> · animates <properties>

## Typography (summary)
fonts <families> · scale ratio <…> — full report via extract-typography

## Observations
- accent vs neutral system; spacing base unit; elevation ramp; hover language
  (color shift vs lift vs shadow); token-driven or not; nav behavior; etc.

## Caveats
- every entry from model.caveats[]
```

Stay faithful to the model — never invent numbers. Judgment goes only into
`## Observations`, naming the accent/neutrals, and prose. Color roles are
heuristic; confirm the accent against the brand.
```
