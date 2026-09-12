import { chromium, devices } from "/opt/node22/lib/node_modules/playwright/index.mjs";
import http from "node:http";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const here = path.dirname(fileURLToPath(import.meta.url));
const root = path.join(here, "..", "web");
const TYPES = { ".html":"text/html", ".js":"text/javascript", ".json":"application/json",
                ".webmanifest":"application/manifest+json", ".png":"image/png" };

const server = http.createServer((req, res) => {
  let p = decodeURIComponent(req.url.split("?")[0]);
  if (p === "/") p = "/index.html";
  const f = path.join(root, p);
  if (!f.startsWith(root) || !fs.existsSync(f) || fs.statSync(f).isDirectory()) { res.writeHead(404); return res.end("nf"); }
  res.writeHead(200, { "content-type": TYPES[path.extname(f)] || "application/octet-stream" });
  fs.createReadStream(f).pipe(res);
});
await new Promise(r => server.listen(8099, r));
const URL_ = "http://127.0.0.1:8099/index.html";

const results = [];
function check(name, actual, expected) {
  const ok = String(actual) === String(expected);
  results.push({ name, ok, actual, expected });
  console.log((ok ? "  PASS " : "  FAIL ") + name + "  got=" + JSON.stringify(actual) + (ok ? "" : " want=" + JSON.stringify(expected)));
}

const browser = await chromium.launch();
const ctx = await browser.newContext({ ...devices["iPhone 13"], isMobile: true, hasTouch: true });
const page = await ctx.newPage();
const errors = [];
page.on("pageerror", e => errors.push("pageerror: " + e.message));
page.on("console", m => { if (m.type() === "error") errors.push("console.error: " + m.text()); });

const bal = () => page.locator("#bal .num").innerText();
const usd = () => page.locator("#bal .usd").innerText();
const goTab = async t => { await page.click(`[data-act="tab"][data-id="${t}"]`); await page.waitForTimeout(120); };
const sheetGone = async () => page.waitForFunction(() => !document.getElementById("sheet").classList.contains("on"));

await page.goto(URL_, { waitUntil: "networkidle" });

console.log("\n-- initial state --");
check("starts at zero MB", await bal(), "0");
check("starts at $0.00", await usd(), "$0.00 value");
check("five tabs rendered", await page.locator(".tab").count(), 5);
check("kid chips hidden for one kid", await page.locator("#kidrow").isVisible(), false);

console.log("\n-- earn: storybook = 1 MB --");
await goTab("earn");
await page.click('[data-act="earn"][data-id="r_story"]');
await page.waitForSelector(".sheet.on");
check("sheet shows per-unit value", await page.locator(".sheet .sub").innerText(), "1 Mills Bucks · $2.25 each");
await page.click("#confirm");
await sheetGone();
check("balance after storybook", await bal(), "1");
check("dollars after storybook", await usd(), "$2.25 value");

console.log("\n-- earn: A on a test x2 = 8 MB --");
await page.click('[data-act="earn"][data-id="a_test_a"]');
await page.waitForSelector(".sheet.on");
await page.click('[data-q="1"]');
check("stepper reads 2", await page.locator("#q").innerText(), "2");
check("preview totals 8 MB", await page.locator("#prev").innerText().then(t => t.replace(/\s+/g," ")), "Adding +8 MB · $18.00");
await page.fill("#note", "science unit 3");
await page.click("#confirm");
await sheetGone();
check("balance is 9", await bal(), "9");
check("dollars is $20.25", await usd(), "$20.25 value");

console.log("\n-- fractional: A on an assignment = 1.5 --");
await page.click('[data-act="earn"][data-id="a_assign_a"]');
await page.waitForSelector(".sheet.on");
await page.click("#confirm");
await sheetGone();
check("fraction adds correctly", await bal(), "10.5");
check("fraction converts correctly", await usd(), "$23.63 value");

console.log("\n-- championship = 100 --");
await page.click('[data-act="earn"][data-id="s_championship"]');
await page.waitForSelector(".sheet.on");
await page.click("#confirm");
await sheetGone();
check("championship balance", await bal(), "110.5");
check("championship dollars", await usd(), "$248.63 value");

console.log("\n-- search --");
await page.fill("#earnsearch", "soccer");
await page.waitForTimeout(150);
check("no match shows empty state", await page.locator(".empty").count(), 1);
await page.fill("#earnsearch", "read");
await page.waitForTimeout(150);
check("search 'read' finds rules", await page.locator('[data-act="earn"]').count() > 0, "true");

console.log("\n-- spend --");
await goTab("spend");
await page.click('[data-act="spend"][data-id="p_bigtoy"]');
await page.waitForSelector(".sheet.on");
await page.click("#confirm");
await sheetGone();
check("balance after 22 MB spend", await bal(), "88.5");

console.log("\n-- overdraft warning --");
await page.click('[data-act="spend"][data-id="p_dayout"]');
await page.waitForSelector(".sheet.on");
for (let i = 0; i < 3; i++) await page.click('[data-q="1"]'); // 30 x 4 = 120 > 88.5
check("overdraft warns", await page.locator("#warn .warn").count(), 1);
await page.click('[data-act="closesheet"]');
await sheetGone();
check("cancel changed nothing", await bal(), "88.5");

console.log("\n-- custom entry --");
await goTab("home");
await page.click('[data-act="custom"][data-kind="earn"]');
await page.waitForSelector(".sheet.on");
await page.fill("#ctitle", "Helped a neighbour");
await page.fill("#camt", "2.5");
await page.click("#confirm");
await sheetGone();
check("custom earn applied", await bal(), "91");

console.log("\n-- history --");
await goTab("history");
check("six entries listed", await page.locator('[data-act="entry"]').count(), 6);
await page.click('[data-act="filter"][data-id="spend"]');
await page.waitForTimeout(100);
check("spend filter shows one", await page.locator('[data-act="entry"]').count(), 1);
await page.click('[data-act="filter"][data-id="all"]');
await page.waitForTimeout(100);

console.log("\n-- delete + undo --");
await page.click('[data-act="entry"] >> nth=0');
await page.waitForSelector(".sheet.on");
await page.click("#del");
await sheetGone();
check("delete removed 2.5", await bal(), "88.5");
await page.click("#toastact");
await page.waitForTimeout(150);
check("undo restored it", await bal(), "91");

console.log("\n-- persistence across reload --");
await page.reload({ waitUntil: "networkidle" });
check("balance survived reload", await bal(), "91");
check("entries survived reload", await page.evaluate(() => JSON.parse(localStorage.getItem("millsbucks.v1")).entries.length), 6);

console.log("\n-- rate change --");
await goTab("settings");
await page.fill("#rate", "3");
await page.dispatchEvent("#rate", "change");
await page.waitForTimeout(150);
check("dollars recompute at $3", await usd(), "$273.00 value");
await page.fill("#rate", "2.25");
await page.dispatchEvent("#rate", "change");
await page.waitForTimeout(150);

console.log("\n-- second kid isolation --");
await page.click('[data-act="addkid"]');
await page.waitForSelector(".sheet.on");
await page.fill("#kname", "Sam");
await page.click("#ksave");
await sheetGone();
check("new kid starts at zero", await bal(), "0");
check("kid chips now visible", await page.locator("#kidrow").isVisible(), true);
check("two kid chips", await page.locator('[data-act="kid"]').count(), 2);
await page.click('[data-act="kid"] >> nth=0');
await page.waitForTimeout(120);
check("switching back restores balance", await bal(), "91");

console.log("\n-- service worker --");
const swOK = await page.evaluate(() => navigator.serviceWorker.getRegistration().then(r => !!r));
check("service worker registered", swOK, "true");

console.log("\n-- screenshots --");
await goTab("home");
await page.screenshot({ path: path.join(here, "..", "docs", "shot-home.png") });
await goTab("earn");
await page.screenshot({ path: path.join(here, "..", "docs", "shot-earn.png") });
await goTab("history");
await page.screenshot({ path: path.join(here, "..", "docs", "shot-history.png") });

check("no JS errors", errors.length ? errors.join(" | ") : 0, 0);

await browser.close();
server.close();

const failed = results.filter(r => !r.ok);
console.log("\n================ " + (results.length - failed.length) + "/" + results.length + " checks passed ================");
if (failed.length) { failed.forEach(f => console.log("FAILED: " + f.name)); process.exit(1); }
