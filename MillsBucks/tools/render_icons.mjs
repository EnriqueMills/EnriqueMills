import { chromium } from "/opt/node22/lib/node_modules/playwright/index.mjs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const here = path.dirname(fileURLToPath(import.meta.url));
const src = "file://" + path.join(here, "icon.html");
const out = path.join(here, "..", "web", "icons");
const sizes = [180, 192, 512, 1024];

const browser = await chromium.launch();
for (const s of sizes) {
  const page = await browser.newPage({ viewport: { width: s, height: s }, deviceScaleFactor: 1 });
  await page.goto(src, { waitUntil: "networkidle" });
  await page.screenshot({ path: path.join(out, `icon-${s}.png`), omitBackground: false });
  await page.close();
  console.log("wrote icon-" + s + ".png");
}
await browser.close();
