---
name: respyr-design
description: The Respyr product design system — color palette, status-color semantics, typography, and the shared UI component/library vocabulary. Use whenever building, restyling, or reviewing any screen, widget, card, chart, or component so the UI stays consistent with the documented Respyr design language.
---

# Respyr Design System

Source of truth: the product design documentation (`product.md`). This skill
captures the **design layer only** — tokens, semantics, and the approved UI
vocabulary. It does NOT prescribe per-screen layout choices; those are product
decisions made case by case.

## Color palette

Use these exact hex values. Do not introduce off-palette colors.

| Token            | Hex                 | Use for                                   |
|------------------|---------------------|-------------------------------------------|
| Primary Blue     | `#308BF9`           | Buttons, links, active/selected states    |
| Text Dark        | `#252525`           | Primary text                              |
| Text Secondary   | `#535359`           | Secondary text, descriptions, subtitles   |
| Background Light  | `#F5F7FA`          | Screen backgrounds                        |
| Border / Divider | `#E5E7EB`           | Dividers, card borders                    |
| Success Green    | `#3EAF58`           | Active status, success states             |
| Error Red        | `#EA5455` / `#DA5747` | Error states, warnings                  |
| Neutral Gray     | `#A1A1A1`           | Disabled states, placeholders             |

## Status-color semantics

State is communicated with color consistently across the app:

- **Active / linked / success** → Success Green `#3EAF58`
- **Not linked / error / rejected** → Error Red `#EA5455`
- **Disabled / empty / placeholder** → Neutral Gray `#A1A1A1`
- **Selected / interactive / primary action** → Primary Blue `#308BF9`

Examples from the product: "Consultant Linked → Active (green) / Not Linked
(red)"; plan status "Active" (green) vs "No Active Plan" (gray); real-time
password-validation indicators (red → green).

## Typography

- **Primary typeface: Poppins** (via `google_fonts`), used app-wide.
- Weight/size scale is not centrally fixed in the product doc — follow the
  hierarchy already present in the screen you're editing rather than inventing a
  new scale. Titles heavier (w600), body/labels lighter (w400–w500).

## Approved UI component vocabulary

Reuse these shared components (`lib/common/widgets/`) instead of building
one-off equivalents:

- `CommonAppbar` — standard app bar
- `ProfileAvatar` / `ClientProfileAvatar` — profile images
- `Pill` — pill-shaped badges
- `RingProgress` — circular progress
- `LinearProgress` — linear progress bars
- `WaterProgress` — water-intake visualization
- `TextInputDecoration` — input-field styling
- `SlideToConfirm` — swipe-to-confirm interaction
- `LoadingWidget` — loading indicators
- `Threshold` — threshold visualization
- `InternetConnectivityHandler` — connection status
- `BatteryIndicatorWidget` — device battery display

## Charts, gauges & specialized UI libraries

Match the app's existing choices — don't add competing libraries:

- **Charts & gauges** → Syncfusion Flutter Gauges + FL Chart
- **Chat UI** → Dash Chat 2

## Architectural conventions (design-adjacent)

For consistency when wiring up new UI:

- **State management** → BLoC + Cubit (`flutter_bloc`)
- **Navigation** → GoRouter (named routes)
- **Score → color mapping** → use the `core/score_manager/` utilities
  (`ScoreColor`, `ScoreStatus`, `ScoreGradient`) rather than hardcoding score
  colors.

## What this skill deliberately does NOT cover

- Per-screen layout patterns (pickers vs. sheets, collapsing headers, etc.) —
  those are product/UX decisions, decided per screen, not global design rules.
- Feature/route architecture — see `product.md` directly for that.
