# Pulse

<p align="center">
  <b>Your macOS notch wellness companion</b><br/>
  Minimal, ambient, and always watching your focus flow.
</p>

<p align="center">
  <img alt="Platform" src="https://img.shields.io/badge/platform-macOS-111827?style=for-the-badge&logo=apple&logoColor=white">
  <img alt="SwiftUI" src="https://img.shields.io/badge/built%20with-SwiftUI-0ea5e9?style=for-the-badge&logo=swift&logoColor=white">
  <img alt="Status" src="https://img.shields.io/badge/status-v1%20in%20progress-1D9E75?style=for-the-badge">
  <img alt="Category" src="https://img.shields.io/badge/category-healthcare%20%26%20fitness-EF9F27?style=for-the-badge">
</p>

---

## Why Pulse?

Pulse lives in the notch and gently nudges healthier work rhythms: eye rest, movement, hydration, and wind-down timing.
At the center is **Pip**, a minimalist owl mascot that reacts to your wellness state in real-time.

- Flow-first ambient UI: useful without being distracting
- State-driven notch visuals with glow and breathing motion
- Friendly wellness prompts that never guilt-trip
- Background agent app (`LSUIElement = YES`) with no Dock icon

---

## Core Experience

### Notch wellness states

- `Flow` (green): under 90 minutes since break
- `Heads-up` (amber): 90-150 minutes since break
- `Rest now` (red): 150+ minutes since break

Each state updates:

- Pip expression and animation
- Notch glow color and pulse speed
- Label and mini wellness bar
- Notification tone and urgency

### Pip mascot states

| State | Visuals | Message style |
|---|---|---|
| Flow | Open eyes, relaxed tufts/wings | "I'll keep watch." |
| Heads-up | Amber squint pulse, raised tufts | Gentle check-in |
| Rest now | Half-closed eyes, head nod | Stronger nudge to step away |
| Break taken | Bright eyes, wave animation | Positive reinforcement |

---

## Features (v1)

- Notch window (idle, hover, expanded layouts)
- `WellnessEngine` score + state machine
- `FocusTracker` activity + idle detection
- `BreakScheduler` for timed interventions
- `CalendarBridge` meeting-aware pause behavior
- `UNUserNotificationCenter` fallback notifications
- Native macOS settings with Liquid Glass style
- SwiftData persistence for breaks and sessions
- Launch at login via `SMAppService`

---

## Tech Stack

- Swift + SwiftUI
- AppKit (`NSWindow`, notch positioning)
- EventKit (meeting detection)
- UserNotifications
- SwiftData
- XcodeGen

---

## Project Structure

```text
Pulse/
├── App/            # app entry and lifecycle
├── Notch/          # notch window, states, glow
├── Pip/            # owl views, animator, variants
├── Engine/         # wellness logic + schedulers
├── Settings/       # settings window + pages
├── Notifications/  # notification manager + templates
├── Models/         # SwiftData models
├── Support/        # palette/utilities
└── Resources/      # assets, plist, icons
```

---

## Quick Start

```bash
brew install xcodegen
xcodegen generate
open Pulse.xcodeproj
```

Then run with `Cmd + R`.

> Pulse works best on notched MacBooks. On non-notched displays, it falls back to a top-center floating pill.

---

## Design System

- Primary green: `#1D9E75`
- Heads-up amber: `#EF9F27`
- Rest red: `#E24B4A`
- Interactive blue: `#378ADD`
- Expanded purple: `#7F77DD`
- Dark base: `#0d1219`
- Navy body: `#1a2535`

Pip icon/brand language:
- Geometric owl construction (ellipses, circles, triangles)
- High-contrast glowing eyes for notch readability
- Dark variant as primary app icon

---

## Roadmap

### v1 (current)
- Complete notch wellness experience
- Pip state animations and templated copy
- Scheduling + settings + persistence

### v2 (planned, not implemented)
- Optional local LLM via Ollama (`llama3.2:1b` or `phi3:mini`)
- Personalized Pip responses with silent fallback to templates
- More context-aware suggestions

---

## Notes

- `Resources/Assets.xcassets/AppIcon.appiconset` currently uses placeholder assets unless replaced.
- This project is intended for direct download distribution (not App Store) in v1.
