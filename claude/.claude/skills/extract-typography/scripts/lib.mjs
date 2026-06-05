// Shared extraction core for extract-typography and extract-ui-kit.
// Exports: the in-page collector (collectStatic), pure model helpers, the
// typography model builder, and Playwright session helpers. extract-ui-kit
// imports this module so the two skills share one extraction engine.

import { chromium } from "playwright";

export const VIEWPORTS = [
  { name: "desktop", width: 1440, height: 900 },
  { name: "mobile", width: 390, height: 844 },
];

export const UA =
  "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 " +
  "(KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36";

export const NAMED_RATIOS = [
  [1.067, "minor second"], [1.125, "major second"], [1.2, "minor third"],
  [1.25, "major third"], [1.333, "perfect fourth"], [1.414, "augmented fourth"],
  [1.5, "perfect fifth"], [1.6, "minor sixth"], [1.618, "golden ratio"],
];

export const ROLE_DEFS = [
  { role: "h1", tags: ["h1"] }, { role: "h2", tags: ["h2"] },
  { role: "h3", tags: ["h3"] }, { role: "h4", tags: ["h4"] },
  { role: "h5", tags: ["h5"] }, { role: "h6", tags: ["h6"] },
  { role: "body", tags: ["p"] }, { role: "lead", tags: ["p"], lead: true },
  { role: "a", tags: ["a"] }, { role: "strong", tags: ["strong", "b"] },
  { role: "em", tags: ["em", "i"] }, { role: "blockquote", tags: ["blockquote"] },
  { role: "code", tags: ["code"] }, { role: "pre", tags: ["pre"] },
  { role: "li", tags: ["li"] }, { role: "small", tags: ["small"] },
  { role: "button", tags: ["button"] }, { role: "label", tags: ["label"] },
  { role: "caption", tags: ["figcaption", "caption"] },
];

// ---------------------------------------------------------------------------
// In-page collector. Runs in the browser (page.evaluate); returns serializable
// data. Captures TEXT elements (for typography) plus styled BOXES, CSS-variable
// tokens, and (optionally) tags button/nav candidates for hover capture.
// Self-contained: no outer-scope references.
// ---------------------------------------------------------------------------
export function collectStatic(opts) {
  opts = opts || {};
  const ICON_HINTS = [
    "icon", "fontawesome", "font awesome", "material icons", "material symbols",
    "glyphicon", "icomoon", "ionicons", "feather", "bootstrap-icons", "remixicon",
  ];
  const MAX_NODES = 20000;
  const root = document.documentElement;
  const rootFontSize = parseFloat(getComputedStyle(root).fontSize) || 16;

  // --- fonts (FontFaceSet is reliable across CORS) ---
  const loadedFamilies = new Set();
  const loadedFaces = [];
  try {
    for (const f of document.fonts) {
      const fam = (f.family || "").replace(/^['"]|['"]$/g, "");
      if (fam) loadedFamilies.add(fam.toLowerCase());
      loadedFaces.push({ family: fam, weight: f.weight, style: f.style, stretch: f.stretch, status: f.status });
    }
  } catch {}

  // --- @font-face + :root custom-property tokens (same-origin sheets only) ---
  const fontFaces = [];
  const tokens = {};
  const bps = new Set();
  let corsBlockedSheets = 0;
  for (const sheet of Array.from(document.styleSheets)) {
    let rules;
    try { rules = sheet.cssRules; } catch { corsBlockedSheets++; continue; }
    if (!rules) continue;
    for (const rule of Array.from(rules)) {
      const kind = rule.constructor && rule.constructor.name;
      if (kind === "CSSMediaRule") {
        const mt = (rule.media && rule.media.mediaText) || "";
        for (const m of mt.matchAll(/(?:min|max)-width:\s*([\d.]+)px/g)) bps.add(Math.round(parseFloat(m[1])));
      } else if (kind === "CSSFontFaceRule") {
        const s = rule.style;
        fontFaces.push({
          family: (s.getPropertyValue("font-family") || "").replace(/^['"]|['"]$/g, ""),
          weight: s.getPropertyValue("font-weight") || "",
          style: s.getPropertyValue("font-style") || "",
          stretch: s.getPropertyValue("font-stretch") || "",
          display: s.getPropertyValue("font-display") || "",
          unicodeRange: s.getPropertyValue("unicode-range") || "",
          src: s.getPropertyValue("src") || "",
        });
      } else if (kind === "CSSStyleRule" && /(^|,)\s*(:root|html)\s*(,|$)/.test(rule.selectorText || "")) {
        const st = rule.style;
        for (let i = 0; i < st.length; i++) {
          const p = st[i];
          if (p.startsWith("--")) {
            const v = getComputedStyle(root).getPropertyValue(p).trim();
            if (v && tokens[p] === undefined) tokens[p] = v;
          }
        }
      }
    }
  }

  // --- font provider link hrefs ---
  const linkHrefs = [];
  for (const l of Array.from(document.querySelectorAll('link[rel~="stylesheet"], link[rel~="preload"]'))) {
    const href = l.getAttribute("href") || "";
    const as = l.getAttribute("as") || "";
    if (href && (as === "font" || /font|typekit|gstatic|googleapis/i.test(href))) linkHrefs.push(href);
  }

  // --- helpers ---
  const num = (v) => parseFloat(v) || 0;
  const toHex = (rgb) => {
    const m = (rgb || "").match(/rgba?\(([^)]+)\)/);
    if (!m) return null;
    const parts = m[1].split(",").map((x) => x.trim());
    const [r, g, b] = parts.map((x) => parseFloat(x));
    const a = parts[3] !== undefined ? parseFloat(parts[3]) : 1;
    if (a === 0) return "transparent";
    const h = (n) => Math.max(0, Math.min(255, Math.round(n))).toString(16).padStart(2, "0");
    return "#" + h(r) + h(g) + h(b);
  };
  const bgOf = (el) => {
    let node = el;
    while (node && node.nodeType === 1) {
      const hex = toHex(getComputedStyle(node).backgroundColor);
      if (hex && hex !== "transparent") return hex;
      node = node.parentElement;
    }
    return "#ffffff";
  };
  const resolveFamily = (stack) => {
    const fams = (stack || "").split(",").map((s) => s.trim().replace(/^['"]|['"]$/g, ""));
    for (const f of fams) if (loadedFamilies.has(f.toLowerCase())) return f;
    return fams[0] || (stack || "");
  };
  const ROLE_TAGS = new Set(["h1","h2","h3","h4","h5","h6","p","a","strong","b","em","i","blockquote","code","pre","li","small","button","label","figcaption","caption"]);
  const nearestRoleTag = (el) => {
    let n = el;
    while (n && n.nodeType === 1) { const t = n.tagName.toLowerCase(); if (ROLE_TAGS.has(t)) return t; n = n.parentElement; }
    return null;
  };
  const isIcon = (family, text) => {
    const fam = (family || "").toLowerCase();
    if (ICON_HINTS.some((h) => fam.includes(h))) return true;
    const t = (text || "").trim();
    if (t.length <= 2) for (const ch of t) { const cp = ch.codePointAt(0); if (cp >= 0xe000 && cp <= 0xf8ff) return true; }
    return false;
  };
  const radiusOf = (cs) => {
    const raw = ["borderTopLeftRadius","borderTopRightRadius","borderBottomRightRadius","borderBottomLeftRadius"].map((k) => cs[k]);
    return { px: raw.map(num), pill: raw.some((c) => /%/.test(c) && parseFloat(c) >= 50) };
  };
  const isButtonish = (el) => {
    const t = el.tagName.toLowerCase();
    if (t === "button") return true;
    if (el.getAttribute("role") === "button") return true;
    if (t === "input" && /^(submit|button|reset)$/i.test(el.getAttribute("type") || "")) return true;
    if (t === "a" && /\b(btn|button|cta)\b/i.test(el.getAttribute("class") || "")) return true;
    return false;
  };
  const navAncestor = (el) => {
    let n = el;
    while (n && n.nodeType === 1) { const t = n.tagName.toLowerCase(); if (t === "nav" || t === "header" || n.getAttribute("role") === "navigation") return n; n = n.parentElement; }
    return null;
  };
  const boxRecord = (el, cs, r) => {
    const rad = radiusOf(cs);
    const transD = cs.transitionDuration && cs.transitionDuration !== "0s";
    return {
      tag: el.tagName.toLowerCase(),
      cls: (el.getAttribute("class") || "").split(/\s+/).filter(Boolean)[0] || "",
      padding: [num(cs.paddingTop), num(cs.paddingRight), num(cs.paddingBottom), num(cs.paddingLeft)],
      margin: [num(cs.marginTop), num(cs.marginRight), num(cs.marginBottom), num(cs.marginLeft)],
      radius: rad.px,
      pill: rad.pill,
      border: { width: [num(cs.borderTopWidth), num(cs.borderRightWidth), num(cs.borderBottomWidth), num(cs.borderLeftWidth)], style: cs.borderTopStyle, color: toHex(cs.borderTopColor) },
      shadow: cs.boxShadow && cs.boxShadow !== "none" ? cs.boxShadow : null,
      ownBg: toHex(cs.backgroundColor),
      bgImage: cs.backgroundImage && cs.backgroundImage !== "none" ? cs.backgroundImage.slice(0, 100) : null,
      display: cs.display,
      position: cs.position,
      gap: /(flex|grid)/.test(cs.display) ? num(cs.columnGap || cs.gap) : 0,
      transition: transD ? { property: cs.transitionProperty, duration: cs.transitionDuration, timing: cs.transitionTimingFunction } : null,
      w: Math.round(r.width), h: Math.round(r.height), area: Math.round(r.width * r.height),
    };
  };
  const styledBox = (cs, rec) => (
    !!rec.shadow || rec.border.width.some((x) => x > 0) || rec.radius.some((x) => x >= 2) ||
    (rec.ownBg && rec.ownBg !== "transparent") || rec.padding.filter((x) => x > 0).length >= 2
  );

  // --- walk (incl. shadow DOM) ---
  const elements = [], boxes = [], candidates = [];
  let nodeCount = 0, candId = 0;
  const walk = (rootNode) => {
    const tw = document.createTreeWalker(rootNode, NodeFilter.SHOW_ELEMENT);
    let el = tw.currentNode.nodeType === 1 ? tw.currentNode : tw.nextNode();
    while (el) {
      if (nodeCount++ > MAX_NODES) break;
      if (el.shadowRoot) walk(el.shadowRoot);
      const cs = getComputedStyle(el);
      if (cs.display === "none" || cs.visibility === "hidden" || parseFloat(cs.opacity || "1") === 0) { el = tw.nextNode(); continue; }
      const r = el.getBoundingClientRect();
      if (r.width <= 0 || r.height <= 0) { el = tw.nextNode(); continue; }

      let directText = "";
      for (const n of el.childNodes) if (n.nodeType === 3) directText += n.nodeValue;
      directText = directText.replace(/\s+/g, " ").trim();

      const box = boxRecord(el, cs, r);
      const btn = isButtonish(el);
      const nav = navAncestor(el);
      const aria = el.getAttribute("aria-hidden") === "true";

      // tag candidates for Node-side hover capture
      let xtk = null;
      if (opts.tagCandidates && !aria && (btn || (nav && el.tagName.toLowerCase() === "a" && directText))) {
        xtk = "c" + candId++;
        el.setAttribute("data-xtk", xtk);
        candidates.push({ id: xtk, kind: btn ? "button" : "navlink", selector: `[data-xtk="${xtk}"]`, tag: box.tag, cls: box.cls, area: box.area, text: directText.slice(0, 40) });
      }

      if (directText.length >= 1) {
        const stack = cs.fontFamily;
        const resolved = resolveFamily(stack);
        if (!isIcon(resolved, directText) && !aria) {
          const sizePx = parseFloat(cs.fontSize) || 0;
          const lhPx = cs.lineHeight === "normal" ? null : parseFloat(cs.lineHeight) || null;
          const lsPx = cs.letterSpacing === "normal" ? 0 : parseFloat(cs.letterSpacing) || 0;
          let weight = parseInt(cs.fontWeight, 10) || 400;
          const fvs = cs.fontVariationSettings;
          if (fvs && fvs !== "normal") { const wm = fvs.match(/['"]wght['"]\s+([\d.]+)/); if (wm) weight = Math.round(parseFloat(wm[1])); }
          const rec = box;
          rec.roleTag = nearestRoleTag(el);
          rec.resolved = resolved; rec.stack = stack;
          rec.sizePx = sizePx; rec.weight = weight; rec.lhPx = lhPx; rec.lsPx = lsPx;
          rec.transform = cs.textTransform; rec.style = cs.fontStyle;
          rec.color = toHex(cs.color); rec.bg = bgOf(el);
          rec.decoration = (cs.textDecorationLine || cs.textDecoration || "none").split(" ")[0];
          rec.textLen = directText.length; rec.sample = directText.slice(0, 80);
          rec.isButton = btn; rec.navContext = !!nav; rec.xtk = xtk;
          elements.push(rec);
          el = tw.nextNode();
          continue;
        }
      }
      if (styledBox(cs, box) && box.area > 0 && box.area < 4_000_000) {
        box.bg = bgOf(el); box.navContext = !!nav; box.xtk = xtk; box.isButton = btn;
        boxes.push(box);
      }
      el = tw.nextNode();
    }
  };
  walk(document.body);

  return {
    rootFontSize, tokens, breakpoints: Array.from(bps).sort((a, b) => a - b),
    rootBg: bgOf(document.body),
    loadedFamilies: Array.from(loadedFamilies), loadedFaces, fontFaces, linkHrefs, corsBlockedSheets,
    elements, boxes, candidates,
    title: document.title, finalUrl: location.href,
  };
}

// ---------------------------------------------------------------------------
// Pure helpers (Node side)
// ---------------------------------------------------------------------------
export const round = (n, step) => (n == null ? null : Math.round(n / step) * step);
export const px2rem = (px, base) => +(px / base).toFixed(4);

export function categorize(family, stack) {
  const f = (family || "").toLowerCase(), s = (stack || "").toLowerCase();
  if (/mono|consol|courier|code|menlo|fira code|jetbrains/.test(f) || /monospace/.test(s)) return "monospace";
  if (/system-ui|-apple-system|segoe|roboto$/.test(f)) return "system";
  if (/serif/.test(s) && !/sans-serif/.test(s)) return "serif";
  if (/georgia|times|garamond|playfair|merriweather|lora|cambria|serif/.test(f)) return "serif";
  if (/sans-serif/.test(s)) return "sans-serif";
  return "unknown";
}

export function detectSource(family, fontFaces, linkHrefs, loadedFamilies) {
  const famLc = (family || "").toLowerCase();
  const face = fontFaces.find((ff) => (ff.family || "").toLowerCase() === famLc);
  const urls = [];
  if (face) for (const m of face.src.matchAll(/url\(([^)]+)\)/g)) urls.push(m[1].replace(/['"]/g, ""));
  const all = urls.concat(linkHrefs).join(" ").toLowerCase();
  if (/gstatic\.com|fonts\.googleapis\.com/.test(all)) return { source: "google-fonts", host: "fonts.gstatic.com" };
  if (/typekit|adobe/.test(all)) return { source: "adobe-fonts", host: "use.typekit.net" };
  if (urls.length) {
    const u = urls[0];
    if (/^https?:\/\//.test(u)) { try { return { source: "cdn", host: new URL(u).host }; } catch {} }
    return { source: "self-hosted", host: null };
  }
  if (loadedFamilies.includes(famLc)) return { source: "self-hosted", host: null };
  return { source: "system-stack", host: null };
}

export function variableAxes(family, fontFaces) {
  const face = fontFaces.find((ff) => (ff.family || "").toLowerCase() === (family || "").toLowerCase());
  if (!face) return [];
  const m = (face.weight || "").trim().match(/^(\d+)\s+(\d+)$/);
  return m ? [{ tag: "wght", min: +m[1], max: +m[2], default: 400 }] : [];
}

export function propsFromEl(el, base) {
  return {
    fontFamily: { resolved: el.resolved, stack: el.stack },
    fontSize: { px: +el.sizePx.toFixed(1), rem: px2rem(el.sizePx, base) },
    fontWeight: el.weight,
    lineHeight: { px: el.lhPx == null ? null : +el.lhPx.toFixed(1), ratio: el.lhPx == null ? null : +(el.lhPx / el.sizePx).toFixed(2) },
    letterSpacing: { em: +(el.lsPx / el.sizePx).toFixed(4), px: +el.lsPx.toFixed(2) },
    textTransform: el.transform, fontStyle: el.style,
    color: el.color, textDecoration: el.decoration, sample: el.sample,
  };
}

export function clusterKey(el) {
  return [el.resolved.toLowerCase(), round(el.sizePx, 0.5), el.weight,
    el.lhPx == null ? "normal" : round(el.lhPx / el.sizePx, 0.01),
    round(el.lsPx / el.sizePx, 0.005), el.transform, el.style].join("|");
}

export function clusterStyles(elements, base) {
  const totalText = elements.reduce((s, e) => s + e.textLen, 0) || 1;
  const map = new Map();
  for (const el of elements) {
    const key = clusterKey(el);
    let c = map.get(key);
    if (!c) { c = { rep: el, els: 0, text: 0, selectors: new Map() }; map.set(key, c); }
    c.els++; c.text += el.textLen;
    if (el.area > c.rep.area) c.rep = el;
    const sel = el.cls ? `${el.tag}.${el.cls}` : el.tag;
    c.selectors.set(sel, (c.selectors.get(sel) || 0) + 1);
  }
  const clusters = Array.from(map.values()).map((c) => ({
    props: propsFromEl(c.rep, base),
    usage: { elements: c.els, textShare: +(c.text / totalText).toFixed(3) },
    representativeSelectors: Array.from(c.selectors.entries()).sort((a, b) => b[1] - a[1]).slice(0, 3).map((x) => x[0]),
    _text: c.text,
  })).sort((a, b) => b._text - a._text);
  return { clusters, totalText };
}

export function roleRep(def, elements, base, opts = {}) {
  let pool = elements.filter((e) => def.tags.includes(e.roleTag));
  if (def.lead) pool = opts.bodyPx ? pool.filter((e) => e.sizePx >= opts.bodyPx * 1.2) : [];
  if (!pool.length) return null;
  const map = new Map();
  for (const el of pool) {
    const k = clusterKey(el);
    let c = map.get(k);
    if (!c) { c = { rep: el, text: 0, els: 0 }; map.set(k, c); }
    c.text += el.textLen; c.els++;
    if (el.area > c.rep.area) c.rep = el;
  }
  let best = null;
  for (const c of map.values()) if (!best || c.text > best.text) best = c;
  const rep = best.rep;
  return { props: propsFromEl(rep, base), selector: rep.cls ? `${rep.tag}.${rep.cls}` : rep.tag, count: pool.length };
}

export function inferScale(desktopClusters, base) {
  const sizes = Array.from(new Set(desktopClusters.map((c) => c.props.fontSize.px))).filter((s) => s >= 8).sort((a, b) => a - b);
  const bodySize = desktopClusters[0]?.props.fontSize.px || base;
  const headings = sizes.filter((s) => s > bodySize);
  let ratio = null;
  if (headings.length >= 2) {
    const seq = [bodySize, ...headings], rs = [];
    for (let i = 1; i < seq.length; i++) rs.push(seq[i] / seq[i - 1]);
    rs.sort((a, b) => a - b);
    const median = rs[Math.floor(rs.length / 2)];
    let best = null;
    for (const [val, name] of NAMED_RATIOS) { const dist = Math.abs(val - median); if (!best || dist < best.dist) best = { val, name, dist }; }
    ratio = best && best.dist <= 0.06
      ? { value: best.val, name: best.name, confidence: +(1 - best.dist / 0.06).toFixed(2) }
      : { value: +median.toFixed(3), name: "custom/irregular", confidence: 0.3 };
  }
  return { base, unit: "px+rem", ramp: sizes, ratio };
}

export function contrast(hex1, hex2) {
  const lum = (hex) => {
    const m = (hex || "").match(/^#([0-9a-f]{6})$/i);
    if (!m) return null;
    const n = parseInt(m[1], 16);
    const ch = [(n >> 16) & 255, (n >> 8) & 255, n & 255].map((c) => { c /= 255; return c <= 0.03928 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4); });
    return 0.2126 * ch[0] + 0.7152 * ch[1] + 0.0722 * ch[2];
  };
  const l1 = lum(hex1), l2 = lum(hex2);
  if (l1 == null || l2 == null) return null;
  const [hi, lo] = l1 > l2 ? [l1, l2] : [l2, l1];
  return +((hi + 0.05) / (lo + 0.05)).toFixed(2);
}

export function buildColors(elements) {
  const total = elements.reduce((s, e) => s + e.textLen, 0) || 1;
  const map = new Map();
  for (const el of elements) {
    if (!el.color || el.color === "transparent") continue;
    let c = map.get(el.color);
    if (!c) { c = { text: 0, bg: new Map() }; map.set(el.color, c); }
    c.text += el.textLen;
    c.bg.set(el.bg, (c.bg.get(el.bg) || 0) + el.textLen);
  }
  return Array.from(map.entries()).map(([hex, c]) => {
    const onBg = Array.from(c.bg.entries()).sort((a, b) => b[1] - a[1])[0]?.[0] || "#ffffff";
    return { hex, usage: { textShare: +(c.text / total).toFixed(3) }, onBackground: onBg, contrast: contrast(hex, onBg) };
  }).sort((a, b) => b.usage.textShare - a.usage.textShare).slice(0, 8);
}

export function buildFonts(desktop, mobile, roles) {
  const all = desktop.elements.concat(mobile.elements);
  const totalText = all.reduce((s, e) => s + e.textLen, 0) || 1;
  const byFam = new Map();
  for (const el of all) {
    const fam = el.resolved;
    if (!fam) continue;
    let f = byFam.get(fam);
    if (!f) { f = { text: 0, weights: new Set(), stack: el.stack }; byFam.set(fam, f); }
    f.text += el.textLen;
    if (typeof el.weight === "number") f.weights.add(el.weight);
  }
  const roleUse = new Map();
  for (const r of roles) {
    const fam = r.desktop?.fontFamily.resolved || r.mobile?.fontFamily.resolved;
    if (!fam) continue;
    if (!roleUse.has(fam)) roleUse.set(fam, []);
    if (r.present) roleUse.get(fam).push(r.role);
  }
  const fonts = Array.from(byFam.entries()).map(([family, f]) => {
    const { source, host } = detectSource(family, desktop.fontFaces, desktop.linkHrefs, desktop.loadedFamilies);
    const faces = desktop.fontFaces.filter((ff) => (ff.family || "").toLowerCase() === family.toLowerCase()).map((ff) => ({
      weight: ff.weight, style: ff.style,
      format: (ff.src.match(/format\(([^)]+)\)/) || [])[1]?.replace(/['"]/g, "") || null,
      src: (ff.src.match(/url\(([^)]+)\)/) || [])[1]?.replace(/['"]/g, "") || null,
      display: ff.display || null, unicodeRange: ff.unicodeRange || null,
    }));
    const stack = (f.stack || "").split(",").map((s) => s.trim().replace(/^['"]|['"]$/g, ""));
    return {
      family, category: categorize(family, f.stack), source, host, faces,
      variableAxes: variableAxes(family, desktop.fontFaces),
      weightsUsed: Array.from(f.weights).sort((a, b) => a - b),
      fallbacks: stack.slice(1),
      usage: { roles: roleUse.get(family) || [], textShare: +(f.text / totalText).toFixed(3) },
    };
  }).sort((a, b) => b.usage.textShare - a.usage.textShare);
  for (const f of fonts) {
    if (f.category === "monospace") f.classification = "mono";
    else if (f === fonts[0]) f.classification = "primary-text";
    else if (f.usage.roles.some((r) => /^h[1-6]$/.test(r))) f.classification = "heading";
    else f.classification = "accent";
  }
  return fonts;
}

// Builds the typography sub-model from two raw collected viewports.
// Returns { fonts, scale, roles, discovered, colors, caveats } (no meta).
export function buildTypographyModel(desktop, mobile) {
  const base = desktop.rootFontSize || 16;
  const mBase = mobile.rootFontSize || base;
  const { clusters: dClusters } = clusterStyles(desktop.elements, base);

  const bodyDef = ROLE_DEFS.find((d) => d.role === "body");
  const bodyDeskPx = roleRep(bodyDef, desktop.elements, base)?.props.fontSize.px || base;
  const bodyMobPx = roleRep(bodyDef, mobile.elements, mBase)?.props.fontSize.px || mBase;

  const roles = ROLE_DEFS.map((def) => {
    const d = roleRep(def, desktop.elements, base, { bodyPx: bodyDeskPx });
    const m = roleRep(def, mobile.elements, mBase, { bodyPx: bodyMobPx });
    const present = !!(d || m);
    const dPx = d?.props.fontSize.px, mPx = m?.props.fontSize.px;
    const fluid = !!(dPx && mPx && Math.abs(dPx - mPx) > 0.5);
    return {
      role: def.role, present, selector: d?.selector || m?.selector || null,
      desktop: d?.props || null, mobile: m?.props || null,
      fluid, clampEstimate: fluid ? `clamp(${mPx}px → ${dPx}px)` : null,
      sizeDelta: present ? { desktopPx: dPx ?? null, mobilePx: mPx ?? null } : null,
      instances: { desktop: d?.count || 0, mobile: m?.count || 0 },
    };
  });

  const discovered = dClusters.filter((c) => c.usage.textShare >= 0.002 || c.usage.elements >= 2).map((c, i) => {
    const match = roles.find((r) => r.present && r.desktop &&
      r.desktop.fontSize.px === c.props.fontSize.px && r.desktop.fontWeight === c.props.fontWeight &&
      r.desktop.fontFamily.resolved === c.props.fontFamily.resolved);
    return { id: `style-${i + 1}`, rank: i + 1, props: c.props, usage: c.usage, representativeSelectors: c.representativeSelectors, mappedRole: match ? match.role : "unmapped" };
  });

  const fonts = buildFonts(desktop, mobile, roles);
  const scale = inferScale(dClusters, base);
  scale.fluid = roles.some((r) => r.fluid);
  const colors = buildColors(desktop.elements);

  const caveats = [];
  if (desktop.corsBlockedSheets) caveats.push(`${desktop.corsBlockedSheets} cross-origin stylesheet(s): some @font-face src/format and tokens unavailable.`);
  if (fonts.some((f) => f.faces.length === 0 && f.source !== "system-stack")) caveats.push("Some font src URLs unavailable (cross-origin or injected); family/weight from FontFaceSet.");
  if (desktop.blocked) caveats.push("networkidle timed out; captured after domcontentloaded (page may be incomplete).");

  return { fonts, scale, roles, discovered, colors, caveats };
}

// ---------------------------------------------------------------------------
// Playwright session helpers
// ---------------------------------------------------------------------------
export async function launchBrowser() {
  return chromium.launch({ headless: true, args: ["--no-sandbox"] });
}

export async function openPage(browser, vp) {
  const context = await browser.newContext({
    viewport: { width: vp.width, height: vp.height },
    userAgent: UA, deviceScaleFactor: 1, locale: "en-US",
  });
  const page = await context.newPage();
  return { context, page };
}

export async function gotoAndSettle(page, url) {
  let blocked = false;
  try { await page.goto(url, { waitUntil: "networkidle", timeout: 45000 }); }
  catch { try { await page.goto(url, { waitUntil: "domcontentloaded", timeout: 30000 }); } catch { blocked = true; } }
  for (const re of [/accept all/i, /accept cookies/i, /i agree/i, /^accept$/i, /got it/i]) {
    try { const b = page.getByRole("button", { name: re }); if (await b.count()) { await b.first().click({ timeout: 1500 }); break; } } catch {}
  }
  try { await page.evaluate(() => document.fonts && document.fonts.ready); } catch {}
  await page.waitForTimeout(600);
  return blocked;
}

// Convenience used by extract-typography (no hover needed): open, collect, close.
export async function collectViewport(browser, url, vp, opts = {}) {
  const { context, page } = await openPage(browser, vp);
  const blocked = await gotoAndSettle(page, url);
  const data = await page.evaluate(collectStatic, opts);
  await context.close();
  return { ...data, blocked };
}

export function domainOf(target) {
  try { return new URL(target).hostname.replace(/^www\./, ""); } catch { return "site"; }
}
