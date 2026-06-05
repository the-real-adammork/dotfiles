#!/usr/bin/env node
// extract-ui-kit — extract a page's design system (color, spacing, radii,
// borders, shadows, buttons + observed hover, nav, layout, motion) PLUS the
// full typographic system, reusing extract-typography's shared engine (lib.mjs).
//
// Usage: node scripts/extract.mjs <url> [--out <dir>] [--no-write] [--json]
// Emits: <out>/ui-kit-report-<domain>.model.json
//
// Requires extract-typography to be installed (it provides lib.mjs + Playwright).

import { writeFile, mkdir } from "node:fs/promises";
import { dirname, join } from "node:path";
import {
  VIEWPORTS, launchBrowser, openPage, gotoAndSettle, collectStatic,
  collectViewport, buildTypographyModel, contrast, domainOf,
} from "../../extract-typography/scripts/lib.mjs";

// --------------------------------------------------------------------------
// Node-side helpers
// --------------------------------------------------------------------------
const rgbToHex = (rgb) => {
  if (!rgb) return null;
  if (/^#/.test(rgb)) return rgb;
  const m = rgb.match(/rgba?\(([^)]+)\)/);
  if (!m) return rgb;
  const p = m[1].split(",").map((s) => parseFloat(s.trim()));
  const a = p[3] === undefined ? 1 : p[3];
  if (a === 0) return "transparent";
  const h = (n) => Math.max(0, Math.min(255, Math.round(n))).toString(16).padStart(2, "0");
  return "#" + h(p[0]) + h(p[1]) + h(p[2]);
};
const freqSorted = (arr) => {
  const m = new Map();
  for (const v of arr) { if (v == null || (typeof v === "number" && Number.isNaN(v))) continue; m.set(v, (m.get(v) || 0) + 1); }
  return [...m.entries()].sort((a, b) => b[1] - a[1]).map((x) => x[0]);
};
const parseDur = (d) => { d = (d || "").trim(); if (d.endsWith("ms")) return Math.round(parseFloat(d)); if (d.endsWith("s")) return Math.round(parseFloat(d) * 1000); return 0; };
const hslSat = (hex) => {
  const m = /^#([0-9a-f]{6})$/i.exec(hex || "");
  if (!m) return 0;
  const n = parseInt(m[1], 16);
  const r = ((n >> 16) & 255) / 255, g = ((n >> 8) & 255) / 255, b = (n & 255) / 255;
  const mx = Math.max(r, g, b), mn = Math.min(r, g, b), l = (mx + mn) / 2;
  if (mx === mn) return 0;
  return l > 0.5 ? (mx - mn) / (2 - mx - mn) : (mx - mn) / (mx + mn);
};
const splitTop = (s) => (s || "").split(/,(?![^(]*\))/).map((x) => x.trim()).filter(Boolean);
const decodeTransform = (t) => {
  if (!t || t === "none") return "none";
  const m = t.match(/matrix\(([^)]+)\)/);
  if (!m) return t;
  const p = m[1].split(",").map(Number);
  const out = [];
  if (Math.abs(p[5]) > 0.1) out.push(`translateY(${p[5].toFixed(0)}px)`);
  if (Math.abs(p[0] - 1) > 0.01) out.push(`scale(${p[0].toFixed(3)})`);
  return out.length ? out.join(" ") : "none";
};
const shortShadow = (s) => (s && s !== "none" ? s.replace(/rgba?\([^)]+\)/g, (m) => rgbToHex(m)) : "none");

// In-page snapshot for hover diffing (returns raw computed strings).
const SNAP = (sel) => {
  const el = document.querySelector(sel);
  if (!el) return null;
  const cs = getComputedStyle(el);
  return { bg: cs.backgroundColor, color: cs.color, border: cs.borderTopColor, shadow: cs.boxShadow, transform: cs.transform, opacity: cs.opacity };
};

async function captureHover(page, sel) {
  const before = await page.evaluate(SNAP, sel);
  if (!before) return { changes: null, err: "not-found" };
  try {
    await page.locator(sel).first().scrollIntoViewIfNeeded({ timeout: 1500 });
    await page.locator(sel).first().hover({ timeout: 2000 });
  } catch { return { changes: null, err: "hover-failed" }; }
  await page.waitForTimeout(280);
  const after = await page.evaluate(SNAP, sel);
  if (!after) return { changes: null, err: "gone" };
  const ch = {};
  const col = (k, a, b) => { if (a !== b) ch[k] = `${rgbToHex(a)} → ${rgbToHex(b)}`; };
  col("background", before.bg, after.bg);
  col("color", before.color, after.color);
  col("border", before.border, after.border);
  if (before.shadow !== after.shadow) ch.shadow = `${shortShadow(before.shadow)} → ${shortShadow(after.shadow)}`;
  const tb = decodeTransform(before.transform), ta = decodeTransform(after.transform);
  if (tb !== ta) ch.transform = `${tb} → ${ta}`;
  if (before.opacity !== after.opacity) ch.opacity = `${before.opacity} → ${after.opacity}`;
  return { changes: Object.keys(ch).length ? ch : null, err: null };
}

// Choose ≤ maxReps representative candidates to hover (one per style cluster).
function pickHoverReps(desktop, maxReps = 14) {
  const byXtk = new Map();
  for (const e of desktop.elements) if (e.xtk) byXtk.set(e.xtk, e);
  const btnSig = (e) => [e.ownBg, e.border?.color, e.border?.width?.[0] || 0, e.radius?.[0] || 0, e.color, e.weight].join("|");
  const navSig = (e) => [Math.round(e.sizePx || 0), e.weight, e.color].join("|");
  const clusters = new Map();
  for (const c of desktop.candidates) {
    const e = byXtk.get(c.id);
    if (!e) continue;
    const key = c.kind + ":" + (c.kind === "button" ? btnSig(e) : navSig(e));
    const cur = clusters.get(key);
    if (!cur || e.area > cur.area) clusters.set(key, { selector: c.selector, xtk: c.id, area: e.area });
  }
  return [...clusters.values()].sort((a, b) => b.area - a.area).slice(0, maxReps);
}

// --------------------------------------------------------------------------
// Section builders (operate on raw collected data)
// --------------------------------------------------------------------------
function buildTokens(tokens) {
  const g = { color: {}, space: {}, radius: {}, shadow: {}, font: {}, other: {} };
  for (const [k, v] of Object.entries(tokens || {})) {
    const key = k.toLowerCase();
    if (/radius|rounded|corner/.test(key)) g.radius[k] = v;
    else if (/shadow|elevation/.test(key)) g.shadow[k] = v;
    else if (/color|colour|\bbg\b|background|foreground|\bfg\b|border|accent|primary|secondary|brand|surface|\btext\b|\bink\b|muted/.test(key) || /^#|^rgb|^hsl/.test(v)) g.color[k] = v;
    else if (/font|leading|line-height|tracking|letter|weight/.test(key)) g.font[k] = v;
    else if (/space|spacing|gap|gutter|\bsize\b|width|height|inset|margin|padding|radius/.test(key) || /^-?[\d.]+(px|rem|em)$/.test(v)) g.space[k] = v;
    else g.other[k] = v;
  }
  const count = Object.values(g).reduce((s, o) => s + Object.keys(o).length, 0);
  return { count, ...g };
}

function buildPalette(elements, boxes, accentHint, rootBg) {
  const map = new Map();
  const add = (hex, kind, w) => {
    if (!hex || hex === "transparent" || !/^#/.test(hex)) return;
    let c = map.get(hex);
    if (!c) { c = { text: 0, bg: 0, border: 0 }; map.set(hex, c); }
    c[kind] += w;
  };
  for (const e of elements) { add(e.color, "text", e.textLen || 1); add(e.ownBg, "bg", Math.sqrt(e.area || 1)); if (e.border?.color && e.border.width.some((x) => x > 0)) add(e.border.color, "border", 2); }
  for (const b of boxes) { add(b.ownBg, "bg", Math.sqrt(b.area || 1)); if (b.border?.color && b.border.width.some((x) => x > 0)) add(b.border.color, "border", 2); }
  // prefer the page's actual root background (handles dark themes); else most-used bg
  let pageBg = rootBg && /^#/.test(rootBg) && rootBg !== "transparent" ? rootBg : "#ffffff";
  if (!(rootBg && /^#/.test(rootBg) && rootBg !== "transparent")) { let maxbg = 0; for (const [h, c] of map) if (c.bg > maxbg) { maxbg = c.bg; pageBg = h; } }
  const total = [...map.values()].reduce((s, c) => s + c.text + c.bg + c.border, 0) || 1;
  const entries = [...map.entries()].map(([hex, c]) => {
    const as = []; if (c.text) as.push("text"); if (c.bg) as.push("background"); if (c.border) as.push("border");
    return { hex, _w: c.text + c.bg + c.border, _c: c, usage: { share: +((c.text + c.bg + c.border) / total).toFixed(3), as }, contrastOnPageBg: contrast(hex, pageBg) };
  }).sort((a, b) => b._w - a._w).slice(0, 14);
  let accent = accentHint && /^#/.test(accentHint) ? accentHint.toLowerCase() : null;
  if (!accent) { const cand = entries.find((e) => e.hex !== pageBg && hslSat(e.hex) > 0.4 && e.usage.share > 0.01); accent = cand ? cand.hex.toLowerCase() : null; }
  for (const e of entries) {
    const c = e._c;
    if (e.hex === pageBg) e.role = "page-bg";
    else if (accent && e.hex.toLowerCase() === accent) e.role = "primary/accent";
    else if (c.bg >= c.text && c.bg >= c.border) e.role = "surface";
    else if (c.border >= c.text && c.border >= c.bg) e.role = "border";
    else e.role = e.contrastOnPageBg && e.contrastOnPageBg >= 7 ? "text" : (e.contrastOnPageBg && e.contrastOnPageBg >= 3 ? "muted" : "subtle");
    delete e._w; delete e._c;
  }
  return { pageBg, colors: entries };
}

function buildSpacing(nodes) {
  const padVals = [], gapVals = [];
  for (const n of nodes) {
    for (const p of n.padding || []) if (p > 0 && p <= 200) padVals.push(Math.round(p));
    if (n.gap > 0 && n.gap <= 200) gapVals.push(Math.round(n.gap));
  }
  const allVals = padVals.concat(gapVals);
  const scale = freqSorted(allVals).slice(0, 12).sort((a, b) => a - b);
  let baseUnit = 8, best = 0;
  for (const b of [8, 4, 6, 5, 10]) { const f = allVals.filter((v) => v % b === 0).length / (allVals.length || 1); if (f > best) { best = f; baseUnit = b; } }
  const pick = (vals, n = 3) => freqSorted(vals.filter((x) => x > 0).map(Math.round)).slice(0, n).sort((a, b) => a - b);
  return {
    baseUnit, scale,
    hierarchy: {
      sectionPaddingY: pick(nodes.filter((n) => n.h >= 300 || /section|footer|header/.test(n.tag)).flatMap((n) => [n.padding?.[0], n.padding?.[2]])),
      containerPaddingX: pick(nodes.filter((n) => n.w >= 900).flatMap((n) => [n.padding?.[1], n.padding?.[3]])),
      cardPadding: pick(nodes.filter((n) => (n.shadow || n.border?.width.some((x) => x > 0) || n.radius?.some((x) => x >= 4)) && n.area < 300000 && !n.isButton).flatMap((n) => n.padding || [])),
      inlineGap: pick(gapVals, 4),
    },
  };
}

function buildRadii(nodes) {
  const map = new Map();
  for (const n of nodes) {
    const r = n.radius?.[0] || 0;
    const pill = n.pill || r >= 999;
    if (r === 0 && !pill) continue;
    const key = pill ? "pill" : Math.round(r);
    let c = map.get(key);
    if (!c) { c = { count: 0, roles: new Set() }; map.set(key, c); }
    c.count++;
    if (n.isButton) c.roles.add("button");
    else if (/input|textarea|select/.test(n.tag)) c.roles.add("input");
    else if (/img|image|picture/.test(n.tag) || /avatar/.test(n.cls)) c.roles.add("image");
    else if (n.shadow || n.border?.width.some((x) => x > 0)) c.roles.add("card");
    else c.roles.add("container");
  }
  return [...map.entries()].filter(([k, c]) => c.count >= 2 || k === "pill")
    .map(([k, c]) => ({ px: k === "pill" ? 9999 : k, rem: k === "pill" ? null : +(k / 16).toFixed(3), label: k === "pill" ? "pill/full" : undefined, count: c.count, roles: [...c.roles] }))
    .sort((a, b) => a.px - b.px);
}

function buildBorders(nodes) {
  const map = new Map();
  for (const n of nodes) {
    const w = n.border?.width?.find((x) => x > 0);
    if (!w || n.border.style === "none") continue;
    const key = `${Math.round(w)}|${n.border.style}|${n.border.color}`;
    map.set(key, (map.get(key) || 0) + 1);
  }
  return [...map.entries()].sort((a, b) => b[1] - a[1]).slice(0, 6).map(([k, count]) => { const [w, style, color] = k.split("|"); return { width: +w, style, color, count }; });
}

function buildShadows(nodes) {
  const map = new Map();
  for (const n of nodes) {
    if (!n.shadow) continue;
    let c = map.get(n.shadow);
    if (!c) { c = { count: 0, roles: new Set() }; map.set(n.shadow, c); }
    c.count++;
    if (n.isButton) c.roles.add("button");
    else if (/nav|header/.test(n.tag) || n.navContext) c.roles.add("nav");
    else c.roles.add("card");
  }
  const sev = (s) => { const nums = (s.match(/-?[\d.]+px/g) || []).map(parseFloat); return Math.abs(nums[1] || 0) + Math.abs(nums[2] || 0) + Math.abs(nums[3] || 0); };
  const labels = ["sm", "md", "lg", "xl", "2xl", "3xl"];
  return [...map.entries()].map(([value, c]) => ({ value: shortShadow(value), count: c.count, roles: [...c.roles], _sev: sev(value) }))
    .sort((a, b) => a._sev - b._sev).slice(0, 6)
    .map((s, i) => ({ level: labels[Math.min(i, labels.length - 1)], value: s.value, count: s.count, roles: s.roles }));
}

function buildButtons(elements, hoverByXtk) {
  const btns = elements.filter((e) => e.isButton);
  const sig = (e) => [e.ownBg, e.border?.color, e.border?.width?.[0] || 0, e.radius?.[0] || 0, Math.round(e.padding?.[0] || 0), Math.round(e.padding?.[3] || 0), e.color, e.weight].join("|");
  const map = new Map();
  for (const e of btns) { const k = sig(e); let c = map.get(k); if (!c) { c = { rep: e, count: 0 }; map.set(k, c); } c.count++; if (e.area > c.rep.area) c.rep = e; }
  return [...map.values()].sort((a, b) => b.count - a.count).slice(0, 6).map(({ rep, count }) => {
    const filled = rep.ownBg && rep.ownBg !== "transparent";
    const bordered = rep.border?.width?.some((x) => x > 0);
    const variant = filled ? "filled" : bordered ? "outline" : "ghost/link";
    const hover = rep.xtk ? hoverByXtk[rep.xtk] : null;
    return {
      variant, count,
      base: {
        bg: rep.ownBg, color: rep.color,
        border: bordered ? `${rep.border.width.find((x) => x > 0)}px ${rep.border.style} ${rep.border.color}` : "none",
        radius: rep.pill ? "pill" : (rep.radius?.[0] || 0),
        paddingY: Math.round(rep.padding?.[0] || 0), paddingX: Math.round(rep.padding?.[3] || 0),
        font: { size: rep.sizePx ? +rep.sizePx.toFixed(1) : null, weight: rep.weight }, textTransform: rep.transform,
        shadow: rep.shadow ? shortShadow(rep.shadow) : null,
      },
      hover: hover?.changes || null,
      transition: rep.transition || null,
      representativeSelector: rep.cls ? `${rep.tag}.${rep.cls}` : rep.tag,
      sample: rep.sample,
    };
  });
}

function buildNav(desktop, mobile, hoverByXtk) {
  const cand = desktop.boxes.concat(desktop.elements).filter((n) => (n.tag === "header" || n.tag === "nav") && n.w >= 600);
  cand.sort((a, b) => b.area - a.area);
  const navEl = cand.find((n) => n.position === "fixed" || n.position === "sticky") || cand[0];
  const links = desktop.elements.filter((e) => e.navContext && e.tag === "a" && e.textLen);
  let linkStyle = null;
  if (links.length) {
    const m = new Map();
    for (const e of links) { const k = `${Math.round(e.sizePx)}|${e.weight}|${e.color}`; let c = m.get(k); if (!c) { c = { rep: e, n: 0 }; m.set(k, c); } c.n++; if (e.area > c.rep.area) c.rep = e; }
    const rep = [...m.values()].sort((a, b) => b.n - a.n)[0].rep;
    const hv = rep.xtk ? hoverByXtk[rep.xtk] : null;
    linkStyle = { font: { size: +rep.sizePx.toFixed(1), weight: rep.weight }, color: rep.color, hover: hv?.changes || null, transition: rep.transition || null };
  }
  const cta = desktop.elements.find((e) => e.isButton && e.navContext);
  const desktopLinks = links.length;
  const mobileLinks = mobile.elements.filter((e) => e.navContext && e.tag === "a" && e.textLen).length;
  return {
    found: !!navEl,
    height: navEl ? navEl.h : null,
    background: navEl ? { color: navEl.ownBg, hasImage: !!navEl.bgImage } : null,
    position: navEl ? navEl.position : null,
    borderBottom: navEl && navEl.border?.width?.[2] > 0 ? `${navEl.border.width[2]}px ${navEl.border.color}` : null,
    shadow: navEl?.shadow ? shortShadow(navEl.shadow) : null,
    paddingX: navEl ? Math.round(navEl.padding?.[3] || 0) : null,
    linkGap: navEl && navEl.gap ? Math.round(navEl.gap) : null,
    links: linkStyle,
    cta: cta ? { variant: cta.ownBg && cta.ownBg !== "transparent" ? "filled" : "outline/ghost", bg: cta.ownBg, color: cta.color, radius: cta.pill ? "pill" : (cta.radius?.[0] || 0) } : null,
    mobile: { desktopLinks, mobileLinks, collapses: desktopLinks >= 3 && mobileLinks <= 1 },
  };
}

function buildLayout(desktop, gutterX) {
  const wide = desktop.boxes.filter((b) => b.w >= 700 && b.w <= 1600);
  const containerMaxWidth = freqSorted(wide.map((b) => b.w)).slice(0, 3);
  const breakpoints = (desktop.breakpoints || []).filter((b) => b >= 320 && b <= 1920);
  const gaps = freqSorted(desktop.boxes.filter((b) => /(flex|grid)/.test(b.display) && b.gap > 0).map((b) => Math.round(b.gap))).slice(0, 5).sort((a, b) => a - b);
  return { containerMaxWidth, gutterX, breakpoints, grid: { commonGaps: gaps } };
}

function buildMotion(nodes) {
  const durs = [], eases = [], props = new Set();
  for (const n of nodes) {
    if (!n.transition) continue;
    for (const d of (n.transition.duration || "").split(",")) { const ms = parseDur(d); if (ms) durs.push(ms); }
    if (n.transition.timing) { const e0 = splitTop(n.transition.timing)[0]; if (e0) eases.push(e0); }
    for (const p of splitTop(n.transition.property)) { if (p && p !== "all" && p !== "none") props.add(p); }
  }
  return { durationsMs: freqSorted(durs).slice(0, 5), easings: freqSorted(eases).slice(0, 3), animatedProperties: [...props].slice(0, 8) };
}

// --------------------------------------------------------------------------
async function main() {
  const args = process.argv.slice(2);
  const url = args.find((a) => !a.startsWith("--"));
  if (!url) { console.error("usage: extract.mjs <url> [--out <dir>] [--no-write] [--json]"); process.exit(2); }
  const noWrite = args.includes("--no-write");
  const alsoJson = args.includes("--json");
  const outIdx = args.indexOf("--out");
  const outDir = outIdx >= 0 ? args[outIdx + 1] : "docs/briefs";
  const target = /^https?:\/\//.test(url) ? url : "https://" + url;

  const browser = await launchBrowser();
  let desktop, mobile;
  const hoverByXtk = {};
  let hoverAttempts = 0, hoverOk = 0;
  try {
    const { context, page } = await openPage(browser, VIEWPORTS[0]);
    const blocked = await gotoAndSettle(page, target);
    desktop = await page.evaluate(collectStatic, { tagCandidates: true });
    desktop.blocked = blocked;
    for (const rep of pickHoverReps(desktop)) {
      hoverAttempts++;
      const h = await captureHover(page, rep.selector);
      hoverByXtk[rep.xtk] = h;
      if (h.changes) hoverOk++;
    }
    await context.close();
    mobile = await collectViewport(browser, target, VIEWPORTS[1]);
  } finally {
    await browser.close();
  }

  if (desktop.blocked && !desktop.elements.length) {
    console.error(`Page appears to block headless access or returned no content: ${target}`);
    process.exit(1);
  }

  const nodes = desktop.elements.concat(desktop.boxes);
  const typography = buildTypographyModel(desktop, mobile);
  const tokens = buildTokens(desktop.tokens);
  const buttons = buildButtons(desktop.elements, hoverByXtk);
  const accentHint = buttons.filter((b) => b.base.bg && /^#/.test(b.base.bg) && hslSat(b.base.bg) > 0.4)
    .sort((a, b) => b.count - a.count)[0]?.base.bg || null;
  const palette = buildPalette(desktop.elements, desktop.boxes, accentHint, desktop.rootBg);
  const spacing = buildSpacing(nodes);
  const radii = buildRadii(nodes);
  const borders = buildBorders(nodes);
  const shadows = buildShadows(nodes);
  const nav = buildNav(desktop, mobile, hoverByXtk);
  const layout = buildLayout(desktop, spacing.hierarchy.containerPaddingX);
  const motion = buildMotion(nodes);

  const caveats = [...typography.caveats];
  caveats.push("Color roles (primary/accent, surface, muted) are inferred heuristically — verify against the brand.");
  if (tokens.count === 0) caveats.push("No CSS custom-property tokens found in same-origin styles (may be cross-origin or not token-based).");
  if (hoverAttempts) caveats.push(`Hover: ${hoverOk}/${hoverAttempts} representative elements showed a state change (rest had no hover effect or could not be hovered).`);

  const host = domainOf(target);
  const model = {
    meta: {
      url: target, finalUrl: desktop.finalUrl, title: desktop.title, domain: host,
      viewports: VIEWPORTS, rootFontSize: desktop.rootFontSize || 16,
      capturedAt: new Date().toISOString(), tool: "extract-ui-kit@0.1.0",
    },
    tokens,
    colors: palette.colors,
    pageBg: palette.pageBg,
    spacing,
    radii,
    borders,
    shadows,
    buttons,
    nav,
    layout,
    motion,
    typography: {
      fonts: typography.fonts,
      scale: typography.scale,
      roles: typography.roles,
      // discovered/full type colors omitted here — run extract-typography for the full type report
    },
    caveats,
    observations: [],
  };

  const jsonStr = JSON.stringify(model, null, 2);
  if (noWrite) { process.stdout.write(jsonStr + "\n"); return; }

  const file = join(outDir, `ui-kit-report-${host}.model.json`);
  await mkdir(dirname(file), { recursive: true });
  await writeFile(file, jsonStr);
  if (alsoJson) process.stdout.write(jsonStr + "\n");
  console.error(`✓ model written: ${file}`);
  console.error(`  colors:${palette.colors.length} radii:${radii.length} shadows:${shadows.length} buttons:${buttons.length} tokens:${tokens.count}`);
  console.error(`  spacing base:${spacing.baseUnit}px  nav:${nav.found ? "found" : "—"}  hover:${hoverOk}/${hoverAttempts}  fonts:${typography.fonts.map((f) => f.family).join(",")}`);
  process.stdout.write(file + "\n");
}

main().catch((e) => { console.error(e); process.exit(1); });
