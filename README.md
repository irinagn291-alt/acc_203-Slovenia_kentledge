# Kentledge

Jettison a brick. Seat the credit.

Kentledge is for people drowning in forgotten renewals who need to see what a cancel actually funds. Home is this month's load beam — charge bricks whose charge month is now, never a smeared year. Drag a brick off the beam to prepare a cut. A credit equal to `monthlyEquivalent` appears. The cut commits only when that credit seats on a remaining keep or a named sink. Abandon restores the brick. Cancel-savings is the seated credit on the beam, not a canceled row in a list.

No account, no ads, no Game tab. The beam is the calculator.

## Architecture

Two-phase cut over one `LoadBeam` document.

Prepare ghosts a brick and mints a `SeatCredit` in memory — that step is not persisted. Seating the credit on a remaining `Keep` or a `NamedSink` is the only commit. Abandon rolls the brick back and drops the credit. Views observe `BeamWatch`; they never toggle a canceled flag. Persistence is a Codable `BeamLedger` snapshot under `ktl.beam.v1`, with an Application Support file as the atomic projection.

This fits a subscription load: the legal move is seat-the-credit, not edit-a-row. A tab plus a list of subscriptions would be a journal clone.

## Cut-and-seat credit

This is why someone would pick the app. Dragging a post off the beam is prepare. The brick ghosts. A zinc credit equal to `amount × period.occurrencesPerMonth` (weekly = 52/12) appears. The load does not drop until that credit locks onto a keep or a named sink. Insights ranks uncut bricks by how much they would free. Forecast posts appear only in the charge month.

## Design

Dry-dock hull plate: red-lead primer, zinc, stencil white, rivet shadow. Palette lives in `Assets.xcassets` and is reached only through `HullSwatch`: background `#14110E`, surface `#2A241C`, ink `#EDE6D6`, accent `#C24A22`, muted `#8B8574`. Type is SF Pro behind `HullStep` — six steps, stencil is caption2 uppercase tracking, monthly load is largeTitle tabular. Hard edges. Spacing unit 8 pt. Tap targets 44 pt. The load beam never leaves; Insights and Settings arrive as sheets.

## Art

Style: dry-dock hull still life (red-lead primer, chain slings, stencil draft marks).

Base prompt reused for every asset:

```
Dry-dock hull still life, red-lead primer orange, weathered zinc plate, stencil-white draft marks, rivet shadow, chain slings, dark warm steel, photoreal, no readable text, no logo, no letters
```

| Image set | Prompt |
| --- | --- |
| `ktl_AppIcon` | Dry-dock hull still life, a single pig-iron kentledge ballast block centred on a riveted red-lead primer plate, weathered zinc edges, filling the canvas edge to edge, photoreal, NO text, NO letters, NO words, NO alpha, NO transparency, NO rounded corners, NO drop shadow outside the canvas |
| `ktl_Splash` | Vertical dry-dock hull photograph, red-lead primer and zinc plates, chain slings at the edges, quiet uncluttered centre band for a wordmark, dark warm steel, no readable text in the art |
| `ktl_Onboarding1` | Dry-dock still life of a horizontal load beam with a few charge bricks as riveted hull posts, red-lead primer and stencil-white draft marks, photoreal, no readable text |
| `ktl_Onboarding2` | A hull-plate brick mid-drag off a load beam, ghosted post left behind, a zinc credit token appearing beside it, chain sling in the background, photoreal, no readable text |
| `ktl_Onboarding3` | The same credit token seated on a remaining keep post, beam load visibly lighter, red-lead primer and rivet shadow, photoreal, no readable text |
| `ktl_EmptyHome` | An empty dry-dock load beam waiting for the first brick, quiet red-lead primer plate, chain slings slack, calm and inviting, never sad, no readable text |
| `ktl_EmptyList` | An empty named-sink rail on a zinc hull plate, no credits seated, stencil draft marks faint, calm, no readable text |
| `ktl_CardBackdrop` | Low-contrast weathered zinc hull plate with rivet shadow, red-lead primer wash at the edge, abstract, text must stay readable on top, no letters |
| `ktl_ControlFace` | Face of a single pig-iron ballast brick, red-lead primer top, zinc sides, rivet shadow, square, photoreal, no text |
| `ktl_TwistHero` | Emblem of a jettisoned brick becoming a seated credit: ghosted hull post plus a zinc token locked onto a keep, dry-dock still life, no readable text |
| `ktl_SuccessMark` | A stencil-white confirmation stamp of a seated credit on red-lead primer, rivet ring around it, no letters, no words |
| `ktl_HeaderDecor` | Wide decorative band of riveted dry-dock hull plate, red-lead primer, zinc, stencil draft-mark ticks, no readable text |

## How this is not a repeat

This is the first `subscription_load` in the portfolio. Home is a load beam, not a tab plus a list. The verb is seat-the-credit: a two-phase prepare that only commits when the freed monthly load lands on a keep or a sink. Distinct from Restante (payday wait-to-buy), Occupath (token on a single-line block), and Washfolio (year wash). No food, slots, or bank login.

## Build

```bash
cd Kentledge
xcodegen generate
xcodebuild -scheme Kentledge -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO build
```

Bundle identifier: `com.kentledge.beam`. Contact: https://kentledge-beam.pro/contact-us

Review screenshots: launch with `-ReviewScreen today|log|goals` after onboarding. Simulator seed uses `ktl.demo.v1` and never runs on a device. The driver captures PNG with `simctl`, not `ImageRenderer`.
