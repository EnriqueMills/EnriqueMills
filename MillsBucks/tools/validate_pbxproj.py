#!/usr/bin/env python3
"""Parse project.pbxproj as an OpenStep plist and cross-check every object reference.

Catches the failure mode that matters most when the file is generated rather than
written by Xcode: a dangling object id, which makes Xcode refuse to open the project.
"""
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
PBX = ROOT / "ios" / "MillsBucks.xcodeproj" / "project.pbxproj"

text = PBX.read_text(encoding="utf-8")
text = re.sub(r"^//.*?\n", "", text)                 # leading // !$*UTF8*$!
text = re.sub(r"/\*.*?\*/", " ", text, flags=re.S)   # /* comments */

TOKEN = re.compile(r'"(?:[^"\\]|\\.)*"|[A-Za-z0-9_./$@:+-]+|[{}()=;,]')
tokens = TOKEN.findall(text)
pos = 0


def peek():
    return tokens[pos] if pos < len(tokens) else None


def eat(expected=None):
    global pos
    tok = tokens[pos]
    if expected and tok != expected:
        raise SyntaxError(f"expected {expected!r}, got {tok!r} at token {pos}")
    pos += 1
    return tok


def parse_value():
    tok = peek()
    if tok == "{":
        return parse_dict()
    if tok == "(":
        return parse_array()
    raw = eat()
    return raw[1:-1] if raw.startswith('"') else raw


def parse_dict():
    eat("{")
    out = {}
    while peek() != "}":
        key = eat()
        key = key[1:-1] if key.startswith('"') else key
        eat("=")
        out[key] = parse_value()
        eat(";")
    eat("}")
    return out


def parse_array():
    eat("(")
    out = []
    while peek() != ")":
        out.append(parse_value())
        if peek() == ",":
            eat(",")
    eat(")")
    return out


root = parse_value()
errors = []

objects = root.get("objects")
if not isinstance(objects, dict):
    print("FAIL: no objects dict")
    sys.exit(1)

# every 24-hex token appearing as a value must resolve to a real object
OID = re.compile(r"^[0-9A-F]{24}$")


def walk(node, path):
    if isinstance(node, dict):
        for k, v in node.items():
            walk(v, f"{path}.{k}")
    elif isinstance(node, list):
        for i, v in enumerate(node):
            walk(v, f"{path}[{i}]")
    elif isinstance(node, str) and OID.match(node) and node not in objects:
        errors.append(f"dangling reference {node} at {path}")


for oid_, obj in objects.items():
    if not OID.match(oid_):
        errors.append(f"malformed object id {oid_!r}")
    if "isa" not in obj:
        errors.append(f"object {oid_} has no isa")
    walk(obj, objects[oid_].get("isa", "?") + "(" + oid_ + ")")

if root.get("rootObject") not in objects:
    errors.append("rootObject does not resolve")

project = objects[root["rootObject"]]
target = objects[project["targets"][0]]

# the sources phase must list exactly the .swift files on disk
src_dir = ROOT / "ios" / "MillsBucks"
on_disk = sorted(p.name for p in src_dir.glob("*.swift"))
sources_phase = next(objects[p] for p in target["buildPhases"]
                     if objects[p]["isa"] == "PBXSourcesBuildPhase")
compiled = sorted(
    objects[objects[bf]["fileRef"]]["path"] for bf in sources_phase["files"])
if compiled != on_disk:
    errors.append(f"sources phase mismatch\n  on disk : {on_disk}\n  compiled: {compiled}")

resources_phase = next(objects[p] for p in target["buildPhases"]
                       if objects[p]["isa"] == "PBXResourcesBuildPhase")
bundled = [objects[objects[bf]["fileRef"]]["path"] for bf in resources_phase["files"]]
if "Assets.xcassets" not in bundled:
    errors.append("Assets.xcassets is not in the resources phase")

# files referenced by the app group must exist on disk
app_group = next(o for o in objects.values()
                 if o["isa"] == "PBXGroup" and o.get("path") == "MillsBucks")
for child in app_group["children"]:
    name = objects[child]["path"]
    if not (src_dir / name).exists():
        errors.append(f"group references missing file: {name}")

settings = objects[objects[target["buildConfigurationList"]]["buildConfigurations"][0]]["buildSettings"]
for required in ("PRODUCT_BUNDLE_IDENTIFIER", "SWIFT_VERSION",
                 "GENERATE_INFOPLIST_FILE", "ASSETCATALOG_COMPILER_APPICON_NAME"):
    if required not in settings:
        errors.append(f"target is missing build setting {required}")

print(f"parsed OK: {len(objects)} objects, {len(compiled)} sources compiled")
print(f"target={target['name']}  bundle={settings['PRODUCT_BUNDLE_IDENTIFIER']}  "
      f"swift={settings['SWIFT_VERSION']}  ios={objects[objects[project['buildConfigurationList']]['buildConfigurations'][0]]['buildSettings']['IPHONEOS_DEPLOYMENT_TARGET']}")

if errors:
    print("\n".join("FAIL: " + e for e in errors))
    sys.exit(1)
print("all references resolve; project structure is consistent")
