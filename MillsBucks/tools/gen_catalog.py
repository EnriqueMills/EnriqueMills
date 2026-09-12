#!/usr/bin/env python3
"""Regenerate the starter catalog for both apps from scoring.json.

scoring.json is the single source of truth for reward values. Edit it, run this,
and both the iOS app (Catalog.swift) and the web app (the inlined JSON blob in
web/index.html) pick up the change.

    python3 tools/gen_catalog.py
"""
import io
import json
import pathlib
import re

ROOT = pathlib.Path(__file__).resolve().parent.parent
CATALOG = json.load(io.open(ROOT / "scoring.json", encoding="utf-8"))


def swift_string(s):
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"') + '"'


def swift_amount(a):
    return str(int(a)) if float(a) == int(a) else str(a)


def write_swift():
    lines = [
        "import Foundation",
        "",
        "/// Starter catalog. Generated from scoring.json — edit that file and re-run",
        "/// tools/gen_catalog.py rather than hand-editing this one.",
        "enum Catalog {",
        "",
        f"    static let defaultRate: Double = {CATALOG['rate']}",
        "",
        "    static let categories: [RewardCategory] = [",
    ]
    for c in CATALOG["categories"]:
        lines.append("        RewardCategory(id: %s, name: %s, emoji: %s),"
                     % (swift_string(c["id"]), swift_string(c["name"]), swift_string(c["emoji"])))
    lines += ["    ]", "", "    static let earnRules: [Rule] = ["]
    for r in CATALOG["earnRules"]:
        lines.append("        Rule(id: %s, title: %s, amount: %s, emoji: %s, categoryID: %s),"
                     % (swift_string(r["id"]), swift_string(r["title"]), swift_amount(r["amount"]),
                        swift_string(r["emoji"]), swift_string(r["category"])))
    lines += ["    ]", "", "    static let spendRules: [Rule] = ["]
    for r in CATALOG["spendRules"]:
        lines.append("        Rule(id: %s, title: %s, amount: %s, emoji: %s, categoryID: nil),"
                     % (swift_string(r["id"]), swift_string(r["title"]),
                        swift_amount(r["amount"]), swift_string(r["emoji"])))
    lines += [
        "    ]",
        "",
        "    static func starterData() -> AppData {",
        '        let kid = Kid(name: "My Kid")',
        "        return AppData(rate: defaultRate,",
        "                       kids: [kid],",
        "                       activeKidID: kid.id,",
        "                       entries: [],",
        "                       earnRules: earnRules,",
        "                       spendRules: spendRules,",
        "                       categories: categories)",
        "    }",
        "}",
        "",
    ]
    path = ROOT / "ios" / "MillsBucks" / "Catalog.swift"
    io.open(path, "w", encoding="utf-8").write("\n".join(lines))
    return path


def write_web():
    path = ROOT / "web" / "index.html"
    html = io.open(path, encoding="utf-8").read()
    payload = {
        "rate": CATALOG["rate"],
        "categories": CATALOG["categories"],
        "earnRules": CATALOG["earnRules"],
        "spendRules": CATALOG["spendRules"],
    }
    blob = json.dumps(payload, ensure_ascii=False, separators=(",", ":"))
    html, n = re.subn(
        r'(<script id="default-catalog" type="application/json">).*?(</script>)',
        lambda m: m.group(1) + blob + m.group(2),
        html, count=1, flags=re.S)
    if n != 1:
        raise SystemExit("could not find the default-catalog script tag in web/index.html")
    io.open(path, "w", encoding="utf-8").write(html)
    return path


if __name__ == "__main__":
    for p in (write_swift(), write_web()):
        print("wrote", p.relative_to(ROOT))
    print("%d earning rules, %d spending rules, rate $%s"
          % (len(CATALOG["earnRules"]), len(CATALOG["spendRules"]), CATALOG["rate"]))
