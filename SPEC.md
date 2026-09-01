# Kentledge — Build Specification

> Portfolio app 57, batch pending. This document is the complete brief for
> building this application. Read all of it before writing any code. Anything
> not specified here is your decision, but must stay consistent with section 3.

**One-line positioning:** Jettison a brick. Seat the credit.

| Field | Value |
| --- | --- |
| Product name | Kentledge |
| Bundle identifier | `com.kentledge.beam` |
| Domain | https://kentledge-beam.pro |
| Contact URL | https://kentledge-beam.pro/contact-us |
| Deployment target | iOS 17.0 |
| Swift version | 6.2, strict concurrency `complete` |
| Devices | iPhone and iPad, portrait |
| Interface style | Dark |
| Asset prefix | `ktl_` |
| User-Agent | `Kentledge/1.0 (iOS; +https://kentledge-beam.pro)` |

---

## 1. Non-negotiable constraints

1. **No CocoaPods.** Dependencies come from Swift Package Manager, a local
   in-repo package, a vendored source folder, or nothing at all — per section 3.
2. **No shared code with other portfolio apps.** Business rules are re-implemented
   here under this app's own type names.
3. **All code, identifiers, comments, UI copy and the README are in English.**
4. **No launch gate, no WebView shell, no remote configuration, no analytics.**
5. **No CI files.** No `bitrise.yml`, no `Scripts/`, no `metadata/` folder.
6. **Assets are AI-generated.** No stock photography. SF Symbols may support
   small affordances but must never be the primary iconography.
7. **The app must build clean** with
   `xcodegen generate && xcodebuild -scheme Kentledge -destination 'generic/platform=iOS' build`.
8. **Nothing may echo another app in this batch** in naming, layout or visuals.
9. **This is not a calorie meal-slot tracker** unless family is `food_tracker`.
   Do not invent food logging to fill the brief.

---

## 2. Product core

The product is offline-first. No account, no sign-in, no ads, no in-app purchase,
no analytics SDK, no remote config. All user data stays on the device.

A cut must seat.

### 2.1 User flow

1. Open the Ledger load beam: this month's charge bricks plus the period-normalized monthly total.
2. Add a subscription by expanding a brick in place — amount, period, next charge day — with no pushed detail.
3. Drag a brick off the beam to prepare a cut; a credit equal to monthlyEquivalent appears.
4. Seat the credit on a remaining keep or a named sink; only then the cut commits and the load drops.
5. Open Insights as a sheet to rank which uncut bricks would free the most.
6. Open Settings as a sheet for currency and the local reminder.

### 2.2 Essential behaviour

- monthlyEquivalent = amount × period.occurrencesPerMonth (weekly = 52/12).
- Forecast bricks appear only in the charge month, never smeared across the year.
- Two-phase cut: prepare ghosts the brick; seating the credit commits; abandon restores it.
- Local only; no bank login.
- Mystery-charge flag when a brick has no period or a duplicate next-charge day.
- Cancel-savings is the seated credit on the beam, not a canceled status in a list.

---

## 3. Uniqueness assignment for Kentledge

| Axis | Assigned value |
| --- | --- |
| Architecture | **Two-phase cut (prepare ghosts the brick; seating the credit commits; abandon rolls back)** |
| UI approach | **SwiftUI hosting a UIView load-beam (CAShapeLayer posts; UIPanGestureRecognizer detaches a brick and seats a credit)** |
| Naming convention | **Ballast lexicon** |
| File organization | **By load role (Beam, Brick, Credit, Keep, Sink)** |
| Dependency strategy | **None** |
| Design direction | **Dry-dock hull plate (red-lead primer, zinc, stencil white, rivet shadow)** |
| Typography | **SF Pro** |
| Navigation pattern | **Beam-locked chrome (the load beam never leaves; Insights and Settings as sheets)** |
| AI art style | **Dry-dock hull still life (red-lead primer, chain slings, stencil draft marks)** |
| Functional twist | **Cut-and-seat credit (jettison a charge; freed monthlyEquivalent must seat on a keep or sink)** |
| Persistence | **UserDefaults+Codable** |
| Screen composition | see 3.6 |

### 3.0 Product concept

This is the product the contracts below are assigned to. Do not substitute another.

**Family** — subscription_load

**Core** — A cut must seat.

**Audience** — People drowning in forgotten renewals who need to see what a cancel actually funds, not a list of logos.

**User flow**

1. Open the Ledger load beam: this month's charge bricks plus the period-normalized monthly total.
2. Add a subscription by expanding a brick in place — amount, period, next charge day — with no pushed detail.
3. Drag a brick off the beam to prepare a cut; a credit equal to monthlyEquivalent appears.
4. Seat the credit on a remaining keep or a named sink; only then the cut commits and the load drops.
5. Open Insights as a sheet to rank which uncut bricks would free the most.
6. Open Settings as a sheet for currency and the local reminder.

**Essential features**

- monthlyEquivalent = amount × period.occurrencesPerMonth (weekly = 52/12).
- Forecast bricks appear only in the charge month, never smeared across the year.
- Two-phase cut: prepare ghosts the brick; seating the credit commits; abandon restores it.
- Local only; no bank login.
- Mystery-charge flag when a brick has no period or a duplicate next-charge day.
- Cancel-savings is the seated credit on the beam, not a canceled status in a list.

**Twist** — Cut-and-seat credit. The home is a load beam of this month's charge bricks — only charges whose charge month is now, never a smeared year. Dragging a brick off the beam is a prepare: it ghosts, and a credit equal to monthlyEquivalent appears. The cut commits only when that credit seats on a remaining keep or a named sink; abandoning the credit restores the brick. The home verb is seat-the-credit, not toggle-canceled. Insights ranks uncut bricks by how much they would free.

**Why this is not a repeat** — This is the first subscription_load in the portfolio. Home is a load beam, not a tab plus a list of subscriptions. The new verb is seat-the-credit: a cut is a two-phase prepare that only commits when the freed monthlyEquivalent lands on a keep or a sink. That is not Restante's payday wait-to-buy, not Occupath's token on a single-line block, and not cost-per-use grading of owned tools. The family invariant stays: period-normalized load and forecast bricks only in the charge month. Exhausted unique axes take new ballast and dry-dock values; the free screens slot is No Detail screen so add and edit stay on the beam. No food, slots, or product barcodes.

### 3.0a Craft from the shipped portfolio

Full craft is in KNOWLEDGE.md. Follow it. Do not copy type names or layouts.
- Home: Leaf: month-total + upcoming charges + cancel-savings.
- Invariant: monthlyEquivalent = amount × period.occurrencesPerMonth (weekly = 52/12). Forecast charges only in the charge month, not smeared.
- Never: No login to a bank. Period-normalized load is the product.
- Desk `group_ellipse`: Covariance ellipse; flyer if dist/semiMajor>2.5; sightCorrection=(−cx,−cy). Keep x,y.

### 3.1 Architecture contract

The product is a two-phase cut over one LoadBeam document that holds ChargeBricks, Credits, Keeps, and named Sinks. Prepare detaches a brick: it ghosts and a Credit equal to monthlyEquivalent is minted in memory — that step is not persisted. Seating the credit on a remaining Keep or a named Sink is the only commit; abandon restores the brick and drops the credit. Views observe the beam and never toggle a canceled flag. Unit-test prepare, seat, abandon, monthlyEquivalent = amount × period.occurrencesPerMonth (weekly = 52/12), and that forecast bricks appear only in the charge month.

Put a short comment block at the top of each principal type stating the role it
plays in this architecture. The README must justify the pattern for this product.

### 3.2 UI contract

SwiftUI hosts a UIView load-beam through UIViewRepresentable. CAShapeLayer draws each charge post; UIPanGestureRecognizer detaches a brick (prepare) and seats the resulting credit. Add and edit expand a brick in place on the beam — no NavigationLink and no pushed detail. Insights and Settings are SwiftUI sheets over the beam. Empty and onboarding are full-page SwiftUI with the CTA at the bottom, full width. Beam chrome, posts, and credits are procedural CAShapeLayer or Path — never a generated texture. Hit the whole chrome inside the Button label with contentShape; min 44pt; buttonStyle plain.

### 3.3 Naming contract

Convention: Ballast lexicon.

Examples to follow: `LoadBeam`, `ChargeBrick`, `SeatCredit`, `NamedSink`

### 3.4 Dependency contract

Ship no third-party code. Foundation, UIKit, and SwiftUI only. The beam UIView and Codable snapshot stay inside the Kentledge target.

### 3.5 Navigation contract

The load beam never leaves. There is no TabView. Beam chrome presents Insights and Settings as sheets. Read ProcessInfo.processInfo.arguments once after onboarding: ReviewScreen today stays on Ledger, log presents Insights, goals presents Settings. Close dismisses a sheet. Contact URL lives on Settings.

### 3.6 Screen composition contract

No Detail screen. Add and edit expand a brick in place on the beam.

Physical screens: Ledger (root load beam; ReviewScreen today), Insights (sheet ranking uncut bricks by what they would free; ReviewScreen log), Settings (sheet; ReviewScreen goals; contact URL, currency, local reminder).

No Today, Scan, Search, or Goals screens.

Section 5 lists the logical functions that must exist. This section decides how
they are grouped into actual screens. Where the two disagree, this section wins.

---

## 4. Target file organization

Scheme: **By load role (Beam, Brick, Credit, Keep, Sink)**

```
Kentledge/
  Beam/
  Brick/
  Credit/
  Keep/
  Sink/
  Assets.xcassets/
```

Adapt the leaf files to the architecture, but the top-level shape is fixed. Do
not create a `Utils/` or `Helpers/` dumping ground.

---

## 5. Screens

Build the screens named in section 3.6. The labels below are logical;
actual type names follow this app's naming convention.

### 5.1 Onboarding
Three to four pages. Explains the product, writes initial settings, sets a
completion flag. Skip still writes sensible defaults. Re-runnable from Settings.

### 5.2 Ledger
A first-class screen for **Ledger**. Must render empty, populated and error states.

### 5.3 Insights
A first-class screen for **Insights**. Must render empty, populated and error states.

### 5.4 Settings
A first-class screen for **Settings**. Must render empty, populated and error states.

### 5.5 Settings
Holds: re-run onboarding, reset all data (confirmed), and the contact link to
the domain contact-us URL.

### 5.6 Twist screen
See section 12. The twist needs at least one screen of its own plus a surface on the home screen.

---

## 6. Domain model

Minimum entities, named per this app's convention:

- **Subscription** — named per this app's convention.
- Plus whatever the twist in section 12 requires.


---

## 7. Design system

Direction: **Dry-dock hull plate (red-lead primer, zinc, stencil white, rivet shadow)**

### 7.1 Palette

| Token | Hex | Use |
| --- | --- | --- |
| `background` | `#14110E` | Screen background |
| `surface` | `#2A241C` | Cards, rows, sheets |
| `ink` | `#EDE6D6` | Primary text and icons |
| `accent` | `#C24A22` | Primary action, key figure, progress fill |
| `muted` | `#8B8574` | Secondary text, dividers, disabled |

Define these as named colours in `Assets.xcassets` and reach them through one
typed accessor. Never hard-code a hex string anywhere else.

### 7.2 Typography

Family: **SF Pro**

SF Pro via Font.system. Stencil captions use caption2 uppercase tracking; the monthly load uses largeTitle tabular figures. Six steps max. No Font.custom, no fixedSize, never below 12pt.

Define a type scale of at most six steps behind one accessor and use only those
steps. Text stays legible at the largest Dynamic Type size.

### 7.3 Layout

- One base spacing unit (4 or 8 pt); only multiples of it.
- One corner radius value applied consistently, or deliberately none if the
  design direction calls for hard edges.
- Every interactive element is at least 44x44 pt.

---

## 8. UI and UX quality bar

Every item here is a defect if it is missing. Do not treat this as advice.

**Layout**

- Respect safe areas on every screen. Nothing sits under the notch, the Dynamic
  Island or the home indicator.
- The app is portrait-only on iPhone. Lock it in the Info settings and do not
  write rotation-dependent layout.
- No layout shift when asynchronous data arrives. Reserve the final size up
  front, or use a redacted placeholder of the same dimensions.
- Long product names must truncate gracefully, never push a number off screen.
  Numbers win; names truncate.
- Minimum tap target 44x44 pt for every interactive element, including small
  icon buttons and list accessories.
- Pick one base spacing unit and use only multiples of it. No arbitrary values.

**Keyboard**

- The grams field uses `.decimalPad`, and the decimal separator matches the
  user's locale.
- Content scrolls out from under the keyboard. The focused field is always
  visible.
- Tapping outside the field, or scrolling, dismisses the keyboard.
- Validate on the fly: reject negative and non-numeric input rather than
  crashing the parser later.

**Loading and state**

- Every asynchronous operation has a visible loading state.
- Guard against the spinner flash: if the work finishes in under 150 ms, do not
  show a spinner at all.
- Every list has a designed empty state containing a primary action, not just a
  sentence of text.
- Every error state offers a retry, and states plainly what failed.
- Disable the primary button while its action is in flight so it cannot be
  double-tapped into a double push or a duplicate entry.

**Typography and accessibility**

- All text scales with Dynamic Type. Verify at the largest accessibility size:
  nothing may clip or overlap.
- Every icon-only control has an `accessibilityLabel`. Decorative images are
  marked as decorative so VoiceOver skips them.
- Colour is never the only signal. Pair it with a label, a shape or an icon.
- Honour Reduce Motion: replace movement-heavy transitions with a fade.
- Meet contrast requirements against the palette in section 7. Check the muted
  colour against the background specifically; that is where these palettes fail.

**Formatting**

- Format every number with `NumberFormatter`, never string interpolation. Group
  separators and decimal separators must follow the locale.
- Energy is shown as a whole number of kcal. Macros are shown with at most one
  decimal place.
- Round only at the point of display. Stored values keep full precision.
- Day boundaries use `Calendar.current.startOfDay(for:)` in the user's current
  time zone. Handle the day changing while the app is open, and handle the
  short and long days that daylight saving produces.
- Unknown macro values render as a dash or the word "unknown", never as 0.

**Motion and feedback**

- One haptic on a successful commit (a food logged, a target saved). No haptic
  on navigation.
- Animations are short (0.2 to 0.35 s) and use a single shared easing curve.
- Nothing animates on first appearance of a screen except an intentional entry
  transition.

**Navigation**

- Back always works and never loses entered data without asking.
- A destructive action (delete a log row, reset all data) is confirmed.
- Modal sheets can always be dismissed; there is no dead end.
- Deep state is restorable: relaunching returns the user to a sane screen.


---

## 9. Concurrency

The target builds with Swift 6.2 and `SWIFT_STRICT_CONCURRENCY = complete`. It
must compile with **zero concurrency warnings**. Warnings here become crashes
later, so they are not negotiable.

- All UI types are `@MainActor`. Annotate the type, not individual methods.
- Any value crossing an actor boundary is `Sendable`. Prefer immutable structs
  of primitives.
- Do not use `@unchecked Sendable`. If it is genuinely unavoidable, it needs a
  comment explaining what guarantees the safety.
- No mutable global state. No `static var` that is written after launch.
- Networking and storage APIs are `async` and honour cancellation. When the
  search query changes, cancel the in-flight task; do not let a stale response
  overwrite fresh results.
- Use structured concurrency. Avoid `Task.detached` unless there is a stated
  reason. Never fire a `Task` that outlives the view without owning it.
- Never use `DispatchQueue.main.asyncAfter` to paper over an ordering problem.
  Fix the ordering.
- `Timer` and notification observers are invalidated in `deinit` or on
  disappear.


---

## 10. Persistence engineering

Chosen technology: **UserDefaults+Codable**

A single Codable BeamLedger snapshot under UserDefaults key ktl.beam.v1. Prepare ghosts stay in memory; only a seated cut or an abandoned restore writes. Atomic encode after the commit.

This app persists to **files on disk**. The following are mandatory.

- Write atomically. Either `Data.write(to:options: .atomic)` or write to a
  temporary file and `FileManager.replaceItemAt`. A non-atomic write that is
  interrupted leaves a truncated file and the app will not launch.
- Create the containing directory with
  `withIntermediateDirectories: true` before the first write.
- Every document carries a `schemaVersion` field from version 1, and the decoder
  switches on it.
- Decoding failure must be recoverable: keep the previous good file as a
  `.backup`, fall back to it, and if that also fails start from empty state and
  tell the user. Never crash on a corrupt file.
- All file IO happens off the main thread. The main thread never blocks on disk.
- Debounce writes during rapid edits, but force a flush when `scenePhase`
  becomes `.inactive` or `.background`, and after any destructive action.
- Exclude caches from backup with `URLResourceValues.isExcludedFromBackup` where
  appropriate; user data belongs in Application Support and should be backed up.
- Keep an explicit in-memory source of truth and treat the file as a projection
  of it, so a failed write never leaves the UI showing data that does not exist.


Regardless of technology:

- One seam between domain logic and storage; the UI never touches storage types.
- Writes survive a force-quit. Do not rely on `applicationWillTerminate`.
- Provide `resetAllData()`, used by tests and reachable from Settings.

---

## 11. Networking

- One client type owns both Open Food Facts endpoints.
- Set `User-Agent` on every request. Open Food Facts throttles clients that do
  not identify themselves.
- 15 second timeout. One retry on a transient transport failure, then a typed
  error. Do not retry a 404.
- Cancel the in-flight search when the query changes. Debounce input by roughly
  300 ms.
- Decode into DTO types that mirror the JSON exactly, then map to domain types.
  Never decode straight into your domain model.
- Open Food Facts data is user-contributed and frequently incomplete. Every
  numeric field is optional. A product with no energy value is a normal case
  that the UI must present, not an error.
- Some numeric fields arrive as strings. The decoder must accept both a number
  and a numeric string for every nutriment.
- `status` of `0` in the product response means not found. Map it to a distinct
  error case so the UI can offer manual entry.
- Never crash on malformed JSON. A decoding failure is a handled error.
- Cache every resolved product locally on success, so the app degrades to a
  working offline catalogue.


Set `User-Agent: Kentledge/1.0 (iOS; +https://kentledge-beam.pro)` on every request. Never reuse another app's string.
No required remote catalog. Network only if this product actually needs it.

---

## 11b. App Store readiness

The app must be submittable without further work.

- `PrivacyInfo.xcprivacy` in the target, declaring the UserDefaults access API
  reason `CA92.1` and the file timestamp reason `C617.1`, with
  `NSPrivacyTracking` false and no collected data types.
- `INFOPLIST_KEY_ITSAppUsesNonExemptEncryption = NO` in the pbxproj so TestFlight
  does not sit on Missing Compliance.
- `NSCameraUsageDescription` written specifically for this app. Generic strings
  get rejected.
- `LSApplicationCategoryType` of `public.app-category.healthcare-fitness`.
- Portrait only, iPhone and iPad (`TARGETED_DEVICE_FAMILY = "1,2"`).
- No account, no sign-in, no delete-account flow, no in-app purchase, no ads, no
  user-generated content, and therefore no report or block UI.
- App Tracking Transparency is never invoked.
- The camera is the only sensitive permission requested.
- The app must not present itself as medical advice. It is a personal food log.
- Nutrition data is credited to Open Food Facts, a public database.


Ignore the food-log and Open Food Facts lines above when they conflict with this
family. Category for this app is `public.app-category.finance`. Camera permission only if the
product actually captures.

Project settings that follow from the above:

```yaml
INFOPLIST_KEY_UIUserInterfaceStyle: Dark
INFOPLIST_KEY_UISupportedInterfaceOrientations: UIInterfaceOrientationPortrait
INFOPLIST_KEY_ITSAppUsesNonExemptEncryption: NO
INFOPLIST_KEY_LSApplicationCategoryType: public.app-category.finance
TARGETED_DEVICE_FAMILY: "1,2"
SWIFT_STRICT_CONCURRENCY: complete
```

---

## 12. Functional twist: Cut-and-seat credit (jettison a charge; freed monthlyEquivalent must seat on a keep or sink)

Home is a load beam of this month's charge bricks, never a smeared year. Dragging a brick off the beam is prepare: the brick ghosts and a credit equal to monthlyEquivalent appears. The cut commits only when that credit seats on a remaining keep or a named sink; abandoning the credit restores the brick. Cancel-savings is the seated credit on the beam, not a canceled status in a list. Insights ranks uncut bricks by how much they would free. The home verb is seat-the-credit.

This is the app's marketed differentiator. It must be:

- visible on the home screen, not buried in settings;
- backed by real persisted data, not a cosmetic flourish;
- covered by at least one unit test;
- described in the README as the reason a user would pick this app.

---

## 13. AI-generated assets

Art style: **Dry-dock hull still life (red-lead primer, chain slings, stencil draft marks)**

Base prompt, reused and extended for every asset:

```
Dry-dock hull still life, red-lead primer orange, weathered zinc plate, stencil-white draft marks, rivet shadow, chain slings, dark warm steel, photoreal, no readable text, no logo, no letters
```

All 12 images below are required. Generate each one, export
as PNG, and add it to `Assets.xcassets` as its own image set named exactly as
given. Every name carries the `ktl_` prefix.

### 13.1 App icon rules (strict)

The icon is rejected by App Store Connect if any of these are wrong:

- Exactly **1024 x 1024 px**.
- **No alpha channel.**
- sRGB colour profile, 8 bits per channel, PNG.
- **No text and no words** in the artwork.
- **No rounded corners and no built-in mask.**
- The subject stays inside the middle 80%.

### 13.2 Full asset list

| # | Image set | Size (px) | Alpha | Purpose |
| --- | --- | --- | --- | --- |
| 1 | `ktl_AppIcon` | 1024x1024 | **NO** | App Store icon. NO alpha channel, NO transparency, NO text, NO rounded corners, NO drop shadow outside the canvas. |
| 2 | `ktl_Splash` | 1290x2796 | allowed | Launch background. The middle third must stay quiet so the wordmark reads on top. |
| 3 | `ktl_Onboarding1` | 1024x1536 | allowed | Onboarding page 1 illustration: what the app is for. |
| 4 | `ktl_Onboarding2` | 1024x1536 | allowed | Onboarding page 2 illustration: the main verb. |
| 5 | `ktl_Onboarding3` | 1024x1536 | allowed | Onboarding page 3 illustration: why they stay. |
| 6 | `ktl_EmptyHome` | 1024x1024 | allowed | Empty state: the home screen has nothing yet. Calm and inviting, never sad. |
| 7 | `ktl_EmptyList` | 1024x1024 | allowed | Empty state: a secondary list has no rows. |
| 8 | `ktl_CardBackdrop` | 1200x800 | allowed | Backdrop art for a primary card. Low contrast so text stays readable. |
| 9 | `ktl_ControlFace` | 512x512 | allowed | Custom control artwork used for the primary interactive element. |
| 10 | `ktl_TwistHero` | 1024x1024 | allowed | Hero art for the 'Cut-and-seat credit (jettison a charge; freed monthlyEquivalent must seat on a keep or sink)' feature screen. |
| 11 | `ktl_SuccessMark` | 512x512 | allowed | Shown briefly when the primary action succeeds. |
| 12 | `ktl_HeaderDecor` | 1200x600 | allowed | Decorative header accent on the main screen. |

### Prompt per asset

**`ktl_AppIcon`** — 1024x1024

```
Dry-dock hull still life, a single pig-iron kentledge ballast block centred on a riveted red-lead primer plate, weathered zinc edges, filling the canvas edge to edge, photoreal, NO text, NO letters, NO words, NO alpha, NO transparency, NO rounded corners, NO drop shadow outside the canvas
```

**`ktl_Splash`** — 1290x2796

```
Vertical dry-dock hull photograph, red-lead primer and zinc plates, chain slings at the edges, quiet uncluttered centre band for a wordmark, dark warm steel, no readable text in the art
```

**`ktl_Onboarding1`** — 1024x1536

```
Dry-dock still life of a horizontal load beam with a few charge bricks as riveted hull posts, red-lead primer and stencil-white draft marks, photoreal, no readable text
```

**`ktl_Onboarding2`** — 1024x1536

```
A hull-plate brick mid-drag off a load beam, ghosted post left behind, a zinc credit token appearing beside it, chain sling in the background, photoreal, no readable text
```

**`ktl_Onboarding3`** — 1024x1536

```
The same credit token seated on a remaining keep post, beam load visibly lighter, red-lead primer and rivet shadow, photoreal, no readable text
```

**`ktl_EmptyHome`** — 1024x1024

```
An empty dry-dock load beam waiting for the first brick, quiet red-lead primer plate, chain slings slack, calm and inviting, never sad, no readable text
```

**`ktl_EmptyList`** — 1024x1024

```
An empty named-sink rail on a zinc hull plate, no credits seated, stencil draft marks faint, calm, no readable text
```

**`ktl_CardBackdrop`** — 1200x800

```
Low-contrast weathered zinc hull plate with rivet shadow, red-lead primer wash at the edge, abstract, text must stay readable on top, no letters
```

**`ktl_ControlFace`** — 512x512

```
Face of a single pig-iron ballast brick, red-lead primer top, zinc sides, rivet shadow, square, photoreal, no text
```

**`ktl_TwistHero`** — 1024x1024

```
Emblem of a jettisoned brick becoming a seated credit: ghosted hull post plus a zinc token locked onto a keep, dry-dock still life, no readable text
```

**`ktl_SuccessMark`** — 512x512

```
A stencil-white confirmation stamp of a seated credit on red-lead primer, rivet ring around it, no letters, no words
```

**`ktl_HeaderDecor`** — 1200x600

```
Wide decorative band of riveted dry-dock hull plate, red-lead primer, zinc, stencil draft-mark ticks, no readable text
```


### 13.3 Asset rules

- Assets must be semantically different from each other.
- Record the exact prompt used for every asset in the README.
- SF Symbols are permitted only for close, chevron, share and similar system
  affordances.

Scanner frames, reticles, background textures, and anything else that needs a guaranteed transparent region or a guaranteed seamless join are drawn in SwiftUI via `Path` or `Shape`. The image generator is not used for these elements: it guarantees neither an alpha channel nor a seamless tile.

---

## 14. Demo data

Seed a small local demo dataset for this family's entities so Simulator
screenshots are not empty. Never seed on a physical device. Guard with
`#if targetEnvironment(simulator)` and `ktl.demo.v1`.

---

## 16. Anti-patterns

The following will fail review:

- `try!`, `as!`, or force-unwrapping anything derived from the network, the
  database or a file.
- `fatalError` anywhere reachable at runtime. It is acceptable only for a
  programmer error in an initialiser that cannot fail in practice, and needs a
  comment.
- Swallowing an error with an empty `catch`.
- `print` used as production logging.
- A hard-coded hex colour outside the single colour accessor.
- A hard-coded font name outside the single typography accessor.
- An SF Symbol used as primary iconography.
- Storing a value that can be computed (day totals, remaining budget, macro
  percentages).
- Blocking the main thread on disk or network work.
- `UIScreen.main` for sizing. Use the geometry the layout system gives you.
- Index positions used as list identity. Identity is a stable identifier.
- A view that reaches into the persistence layer directly, bypassing the
  architecture's designated seam.
- Business logic inside a `View` body or a `UIViewController` method, when the
  assigned architecture places it elsewhere.
- Copying a source file from another app in this batch.


---

## 17. Tests

Add a unit test target `KentledgeTests` covering at minimum:

1. The core domain invariant of this family (the thing that would be wrong if
   the calculator, decay, crate, or log lied).
2. Empty, populated and invalid input paths for the primary verb.
3. The section 12 twist logic.
4. One architecture-specific test proving the pattern holds.
5. A persistence round-trip: write, relaunch-equivalent reload, verify.
6. Snapshot unit tests for every main screen named in section 3.6.
   Each of those screens must be a `*View` or `*Screen` type that constructs
   with no arguments (demo fixtures inside the view). The factory runs these
   tests on iPhone and iPad and keeps the PNGs.

---

## 18. README.md

Write `README.md` at the app folder root covering:

1. What the app does and who it is for.
2. The architecture used and **why** it suits this product.
3. The unique feature added and how it works.
4. The AI art style and the exact prompt used for every asset.
5. How this app differs from others in the batch.
6. Build instructions.

---

## 19. Definition of done

**Build**
- [ ] `xcodegen generate` succeeds.
- [ ] `xcodebuild -scheme Kentledge -destination 'generic/platform=iOS' build` succeeds.
- [ ] Zero new compiler warnings.
- [ ] Strict concurrency `complete` compiles clean.
- [ ] Test target passes.

**Function**
- [ ] Onboarding to first successful primary action works on a clean install.
- [ ] Every screen in section 3.6 exists and handles empty / filled / error.
- [ ] Reset and contact link live in Settings.
- [ ] Force-quitting immediately after a write loses nothing.

**Uniqueness**
- [ ] Architecture matches **Two-phase cut (prepare ghosts the brick; seating the credit commits; abandon rolls back)** with no leakage across layers.
- [ ] UI approach matches **SwiftUI hosting a UIView load-beam (CAShapeLayer posts; UIPanGestureRecognizer detaches a brick and seats a credit)**.
- [ ] Navigation matches **Beam-locked chrome (the load beam never leaves; Insights and Settings as sheets)**.
- [ ] Screen composition follows section 3.6.
- [ ] Typography uses **SF Pro** and nothing else.
- [ ] Palette matches section 7.1 exactly.

**Quality**
- [ ] Section 8 UI/UX bar satisfied end to end.
- [ ] Contact link present.
- [ ] `PrivacyInfo.xcprivacy` present and correct.
- [ ] README complete.

---

## 20. Build commands

```bash
cd Kentledge
xcodegen generate
xcodebuild -scheme Kentledge -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO build
xcrun simctl list devices available
xcodebuild -scheme Kentledge -destination 'platform=iOS Simulator,id=<UDID>' test
```

Signing is off only on that command line. Do not put CODE_SIGNING_ALLOWED, CODE_SIGNING_REQUIRED, CODE_SIGN_IDENTITY or DEVELOPMENT_TEAM in project.yml — CI signs the archive. Leave CODE_SIGN_STYLE: Automatic as the scaffold set it. The exact simulator does not matter — use any available UDID from the list.
