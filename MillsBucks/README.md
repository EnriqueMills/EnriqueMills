# Mills Bucks

A reward tracker for kids. One Mills Buck is worth **$2.25** by default; the rate is
editable in the app.

There are two builds of the same app from the same scoring data:

| | `web/` | `ios/` |
|---|---|---|
| Gets on your iPhone | Add to Home Screen, ~30 seconds | Build in Xcode on a Mac |
| Needs a Mac | No | Yes |
| Needs an Apple Developer account | No | Free account works, re-sign every 7 days |
| Works offline | Yes (service worker) | Yes |
| Verified | 34 automated UI checks pass | **Not compiled — see Status** |

Both store data **only on the device**. Nothing is uploaded, there is no account,
and there is no network call of any kind.

## Status, honestly

The web app is tested: 34 end-to-end checks drive a real browser at iPhone
viewport size and assert the arithmetic, persistence, multi-kid isolation, and
undo behaviour. Run them with `node tools/test_web.mjs`.

The iOS app has **never been compiled** — it was written on Linux, where no Swift
toolchain or Xcode exists. The project file is machine-generated and validated
structurally (`python3 tools/validate_pbxproj.py` parses it and checks every
object reference resolves), but "the project opens" is not "the code builds".
Expect to fix a compile error or two on first build.

## Install the web app on your iPhone

1. Host `web/` anywhere that serves HTTPS, or open the published link.
2. Open it in **Safari** (not Chrome — only Safari can install to the Home Screen).
3. Tap **Share** → **Add to Home Screen** → **Add**.

It then launches full-screen with its own icon, no browser chrome, and works
offline. Data lives in Safari's storage for that site, so:

- **Do not** use "Clear History and Website Data" without exporting a backup first.
- Settings → Export backup writes a JSON file you can restore on another phone.

## Build the iOS app

Requires a Mac with Xcode 14 or newer.

```sh
open ios/MillsBucks.xcodeproj
```

Then: select your iPhone as the run destination → **Signing & Capabilities** →
pick your Apple ID under Team → change the bundle identifier from
`com.millsbucks.tracker` to something unique (e.g. `com.yourname.millsbucks`) →
press ⌘R.

With a free Apple ID the app is signed for 7 days and then needs re-running from
Xcode. A paid Developer Program membership ($99/yr) extends that to a year.

Deployment target is iOS 16.0.

## Changing what things are worth

Two ways, and they do different things:

**In the app** (Settings → Reward catalog) — changes that device only. This is the
normal way; add a rule, retune a value, delete what you don't use.

**In the repo** (`scoring.json`) — changes the *starter* catalog that a fresh
install begins with. After editing, run:

```sh
python3 tools/gen_catalog.py
```

which rewrites `ios/MillsBucks/Catalog.swift` and the inlined catalog in
`web/index.html` so both stay in sync. Existing installs keep their own catalog.

## Starter scoring

The values you specified are the anchors: a short storybook is 1, an A on an
assignment is 1.5, an A on a test is 4, a soccer championship is 100. Everything
else is extrapolated from those and is meant to be retuned.

### Earning

#### 📚 Reading

| Activity | Mills Bucks | Value |
|---|--:|--:|
| 📖 Read a short storybook | 1 | $2.25 |
| 🗣️ Read aloud 20 minutes | 1 | $2.25 |
| 📗 Read a chapter book chapter | 1.5 | $3.38 |
| 🏁 Finish a chapter book | 5 | $11.25 |
| ✍️ Write a book report | 3 | $6.75 |

#### 🎓 School

| Activity | Mills Bucks | Value |
|---|--:|--:|
| 🅰️ A on an assignment | 1.5 | $3.38 |
| 🅱️ B on an assignment | 0.75 | $1.69 |
| 📝 A on a test | 4 | $9.00 |
| 📄 B on a test | 2 | $4.50 |
| ✅ Homework all week, no nagging | 3 | $6.75 |
| ✏️ Study/math practice 20 min | 1 | $2.25 |
| 🌟 A on report card (per subject) | 10 | $22.50 |
| 📅 Perfect attendance (term) | 8 | $18.00 |

#### ⚽ Sports & Activities

| Activity | Mills Bucks | Value |
|---|--:|--:|
| 🏃 Attend practice | 0.5 | $1.12 |
| 🥅 Play a game | 1 | $2.25 |
| 💪 Win a game | 2 | $4.50 |
| 🏅 Game ball / team MVP | 10 | $22.50 |
| 🥈 Win a tournament | 25 | $56.25 |
| 🏆 Win a championship | 100 | $225.00 |

#### 🏡 Home & Character

| Activity | Mills Bucks | Value |
|---|--:|--:|
| 🧹 Chores all week, no reminders | 2 | $4.50 |
| 🛏️ Room clean all week | 1.5 | $3.38 |
| 🤝 Helped without being asked | 1 | $2.25 |
| ❤️ Caught being kind | 1 | $2.25 |

### Spending

| Reward | Mills Bucks | Value |
|---|--:|--:|
| 💵 Cash out 1 Mills Buck | 1 | $2.25 |
| 💰 Cash out 5 Mills Bucks | 5 | $11.25 |
| 📱 30 min extra screen time | 1 | $2.25 |
| 🎮 1 hour extra screen time | 2 | $4.50 |
| 🍕 Pick dinner | 2 | $4.50 |
| 🎬 Pick movie night | 2 | $4.50 |
| 🌙 Stay up 30 min late | 2 | $4.50 |
| 🍦 Ice cream / treat run | 3 | $6.75 |
| 🎡 Park / arcade trip | 6 | $13.50 |
| 🧸 Small toy (~$20) | 9 | $20.25 |
| 🎁 Big toy / game (~$50) | 22 | $49.50 |
| 🌞 Day out, kid's choice | 30 | $67.50 |
### A note on the economics

At $2.25 a Mills Buck, the weekly-habit rules (chores 2, homework 3, room 1.5)
total about **$15/week, ~$60/month** before any test grades or reading. Report
cards add $22.50 per A. A championship is $225.

That is a real budget, and it is the one part of this I would push back on: the
catalog as written is generous enough that a good month could cost more than you
intend. If that is not what you want, the lever is the rate, not the rules —
dropping to $1.00 per Mills Buck keeps every relative value intact (a test is
still worth 4x a storybook) while cutting the bill by 56%.

## Layout

```
scoring.json                 source of truth for the starter catalog
web/
  index.html                 the whole app: no build step, no dependencies
  manifest.webmanifest       Home Screen name, icon, standalone display
  sw.js                      offline cache
  icons/                     app icons, rendered from tools/icon.html
ios/
  MillsBucks.xcodeproj/      generated; regenerate with tools/gen_xcodeproj.py
  MillsBucks/*.swift         SwiftUI app, iOS 16+
tools/
  gen_catalog.py             scoring.json -> Catalog.swift + web/index.html
  gen_xcodeproj.py           rebuild the Xcode project after adding a .swift file
  validate_pbxproj.py        parse the project file, check every reference
  test_web.mjs               34 end-to-end checks against real Chromium
  render_icons.mjs           re-render the icons
docs/                        screenshots from the test run
```

## Running the checks

```sh
node tools/test_web.mjs          # web app, 34 assertions, needs Chromium
python3 tools/validate_pbxproj.py # Xcode project integrity
```
