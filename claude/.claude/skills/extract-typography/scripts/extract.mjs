#!/usr/bin/env node
// extract-typography — extract a web page's fonts + typographic system into a
// canonical model. Thin CLI over lib.mjs (shared with extract-ui-kit).
//
// Usage: node scripts/extract.mjs <url> [--out <dir>] [--no-write] [--json]
// Emits: <out>/typography-report-<domain>.model.json

import { writeFile, mkdir } from "node:fs/promises";
import { dirname, join } from "node:path";
import { VIEWPORTS, launchBrowser, collectViewport, buildTypographyModel, domainOf } from "./lib.mjs";

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
  try {
    desktop = await collectViewport(browser, target, VIEWPORTS[0]);
    mobile = await collectViewport(browser, target, VIEWPORTS[1]);
  } finally {
    await browser.close();
  }

  if (desktop.blocked && !desktop.elements.length) {
    console.error(`Page appears to block headless access or returned no content: ${target}`);
    process.exit(1);
  }

  const type = buildTypographyModel(desktop, mobile);
  const host = domainOf(target);
  const model = {
    meta: {
      url: target, finalUrl: desktop.finalUrl, title: desktop.title, domain: host,
      viewports: VIEWPORTS, rootFontSize: desktop.rootFontSize || 16,
      capturedAt: new Date().toISOString(), tool: "extract-typography@0.1.0",
    },
    ...type,
    observations: [],
  };

  const jsonStr = JSON.stringify(model, null, 2);
  if (noWrite) { process.stdout.write(jsonStr + "\n"); return; }

  const file = join(outDir, `typography-report-${host}.model.json`);
  await mkdir(dirname(file), { recursive: true });
  await writeFile(file, jsonStr);
  if (alsoJson) process.stdout.write(jsonStr + "\n");
  console.error(`✓ model written: ${file}`);
  console.error(`  fonts: ${model.fonts.map((f) => f.family).join(", ") || "none"}`);
  console.error(`  roles present: ${model.roles.filter((r) => r.present).length}/${model.roles.length}  ·  discovered styles: ${model.discovered.length}`);
  process.stdout.write(file + "\n");
}

main().catch((e) => { console.error(e); process.exit(1); });
