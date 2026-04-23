# CLAUDE.md — Notch Wellness Coach

> This is the single source of truth for building Notch Wellness Coach.
> Place this file at the root of the Xcode project. Claude Code reads it automatically on every session.
> Do not split into multiple files — keep everything here so context is always complete.

---

## Table of contents

1. [Project overview](#1-project-overview)
2. [Target platform](#2-target-platform)
3. [Full file structure](#3-full-file-structure)
4. [Design system](#4-design-system)
5. [Notch visual states](#5-notch-visual-states)
6. [Core features — v1 MVP](#6-core-features--v1-mvp)
7. [Onboarding flow](#7-onboarding-flow)
8. [Settings — Liquid Glass](#8-settings--liquid-glass)
9. [Persistence and system](#9-persistence-and-system)
10. [v2 AI layer — future reference](#10-v2-ai-layer--future-reference)
11. [v3 Deep wellness — future reference](#11-v3-deep-wellness--future-reference)
12. [Build order](#12-build-order)
13. [Permissions and entitlements](#13-permissions-and-entitlements)
14. [Key technical notes](#14-key-technical-notes)
15. [v1 deliverable checklist](#15-v1-deliverable-checklist)

---

## 1. Project overview

Build a native macOS app called **Notch Wellness Coach** — a menubar + notch utility that lives silently at the top of the screen and acts as an ambient wellness companion for knowledge workers. It monitors how long the user has been working, surfaces break reminders through the MacBook notch, and glows in color-coded states to communicate wellness level at a glance.

**v1 scope — no AI.** Pure SwiftUI + AppKit, local data only, no networking, no cloud, no AI inference. The goal is a polished, shippable MVP that nails the notch UI, onboarding, and core break reminder loop.

App identity:
- **App name:** Notch Wellness (or Pulse — short, memorable)
- **Bundle ID:** `com.yourname.notchwellness`
- **Category:** `public.app-category.healthcare-fitness`
- **Distribution:** Direct download / Gumroad in v1. No App Store until v3.

---

## 2. Target platform

- macOS 14 (Sonoma) minimum, optimised for macOS 15 (Sequoia) and macOS 26 (Tahoe)
- Apple Silicon primary (M1/M2/M3/M4), Intel compatible
- MacBook Pro / Air with notch (14" and 16" MBP, M2+ MBA)
- Swift 5.9+, SwiftUI + AppKit hybrid
- Xcode 15+

---

## 3. Full file structure

```
NotchWellnessCoach/
├── CLAUDE.md                              # ← this file
│
├── App/
│   ├── NotchWellnessCoachApp.swift        # @main, NSApplicationDelegate
│   └── AppDelegate.swift                  # statusItem, window orchestration, onboarding gate
│
├── Notch/
│   ├── NotchWindowController.swift        # NSWindow positioned at notch
│   ├── NotchView.swift                    # SwiftUI root view, state router
│   ├── NotchIdleView.swift                # Breathing dot + label + mini bar
│   ├── NotchHoverView.swift               # Expanded stats strip (4 metrics)
│   ├── NotchExpandedView.swift            # Full message + action buttons
│   └── NotchGlowLayer.swift               # CALayer border glow + outer bloom
│
├── Engine/
│   ├── WellnessEngine.swift               # Central state machine (ObservableObject)
│   ├── WellnessState.swift                # Enum: .flow / .headsUp / .restNow
│   ├── FocusTracker.swift                 # NSWorkspace activity monitoring
│   ├── BreakScheduler.swift               # Timer logic, break intervals
│   └── CalendarBridge.swift               # EventKit — pause during meetings
│
├── Onboarding/
│   ├── OnboardingWindowController.swift   # NSWindow setup, show/hide logic
│   ├── OnboardingContainerView.swift      # Root SwiftUI view, step router
│   ├── OnboardingProgressDots.swift       # Bottom dot nav component
│   ├── Steps/
│   │   ├── OnboardingStep1Welcome.swift
│   │   ├── OnboardingStep2GlowStates.swift
│   │   ├── OnboardingStep3Breaks.swift
│   │   ├── OnboardingStep4Calendar.swift
│   │   ├── OnboardingStep5Notifications.swift
│   │   └── OnboardingStep6Schedule.swift
│   └── Components/
│       ├── NotchPillPreview.swift          # Reusable live notch pill (used in steps 1 & 2)
│       ├── PermissionCard.swift            # Reusable permission request UI
│       └── NotificationPreviewCard.swift   # Break reminder mock card
│
├── Settings/
│   ├── SettingsWindowController.swift     # Opens settings window
│   ├── SettingsView.swift                 # Root settings SwiftUI view, sidebar nav
│   ├── Pages/
│   │   ├── GeneralSettingsView.swift      # Includes "Rerun onboarding" button
│   │   ├── ScheduleSettingsView.swift
│   │   ├── BreaksSettingsView.swift
│   │   ├── NotchSettingsView.swift
│   │   └── PrivacySettingsView.swift
│   └── SettingsStore.swift                # @AppStorage persisted preferences
│
├── Notifications/
│   ├── NotificationManager.swift          # UNUserNotificationCenter
│   └── NotificationTemplates.swift        # Break message copy — 3 variants per type
│
├── Models/
│   ├── BreakRecord.swift                  # SwiftData model for break history
│   └── SessionRecord.swift                # Work session tracking
│
└── Resources/
    ├── Assets.xcassets
    └── Info.plist
```

---

## 4. Design system

### Color palette — Llama-inspired purple

The app uses a purple-forward palette inspired by the Meta Llama logo gradient (deep violet → mid purple → lilac). State warning colors (amber, red) live at the warm end of the spectrum and still feel cohesive with the brand.

```swift
extension Color {
    // Brand purples
    static let llamaCore    = Color(hex: "6B3FA0")  // deep Llama violet
    static let llamaMid     = Color(hex: "8B5FBF")  // mid purple
    static let llamaFlow    = Color(hex: "A97FD4")  // soft purple — flow state
    static let llamaHover   = Color(hex: "C9A0E8")  // light lavender — interactive
    static let llamaLight   = Color(hex: "E8C5FF")  // pale lilac — fills

    // Notch state colors
    static let stateFlow    = Color(hex: "A97FD4")  // calm purple — working well
    static let stateHeadsUp = Color(hex: "FF6B9D")  // pink-rose — gentle warning
    static let stateRestNow = Color(hex: "FF4757")  // coral-red — rest needed

    // Functional UI colors (settings, onboarding accents)
    static let uiBlue       = Color(hex: "378ADD")  // permission/calendar steps
    static let uiGreen      = Color(hex: "1D9E75")  // success, confirm, finish button
    static let uiAmber      = Color(hex: "EF9F27")  // break reminder accent
}
```

State color rationale:
- **Flow** (`#A97FD4`): soft mid-purple — barely visible in peripheral, calm and reassuring
- **Heads-up** (`#FF6B9D`): pink-rose, warm end of the Llama gradient — noticeable without alarm
- **Rest now** (`#FF4757`): coral-red — demands attention, fastest bloom pulse, hardest to ignore

### Notch sizing constants

```swift
struct NotchMetrics {
    static let idleWidth:      CGFloat = 130
    static let hoverWidth:     CGFloat = 280
    static let expandedWidth:  CGFloat = 340
    static let idleHeight:     CGFloat = 32
    static let expandedHeight: CGFloat = 84
    static let cornerRadius:   CGFloat = 15
}
```

### Animation timings

```swift
// Breathing dot — speed varies by urgency
Animation.easeInOut(duration: 3.0).repeatForever(autoreverses: true)  // flow
Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true)  // headsUp
Animation.easeInOut(duration: 1.4).repeatForever(autoreverses: true)  // restNow

// Notch expand / collapse
Animation.spring(response: 0.45, dampingFraction: 0.78)

// State color transition
withAnimation(.easeInOut(duration: 0.5))

// Onboarding step transitions
withAnimation(.spring(response: 0.4, dampingFraction: 0.82))

// Step slide direction
AnyTransition.asymmetric(
    insertion: .move(edge: .trailing),
    removal: .move(edge: .leading)
)
```

### Glow layer values per state

```swift
func glowColor(for state: WellnessState) -> NSColor {
    switch state {
    case .flow:    return NSColor(red: 0.66, green: 0.25, blue: 0.83, alpha: 1) // llamaFlow
    case .headsUp: return NSColor(red: 1.00, green: 0.42, blue: 0.61, alpha: 1) // stateHeadsUp
    case .restNow: return NSColor(red: 1.00, green: 0.28, blue: 0.34, alpha: 1) // stateRestNow
    }
}

// Border glow layer — tight, traces notch rounded edges
borderGlowLayer.shadowRadius  = 6
borderGlowLayer.shadowOpacity = 0.7
borderGlowLayer.shadowOffset  = .zero

// Outer bloom layer — wide, bleeds onto menu bar
outerBloomLayer.shadowRadius  = 14
outerBloomLayer.shadowOpacity = 0.45
outerBloomLayer.shadowOffset  = CGSize(width: 0, height: -4)

// Animate shadowColor on state change
let colorAnim = CABasicAnimation(keyPath: "shadowColor")
colorAnim.duration = 0.5
colorAnim.toValue  = newColor.cgColor

// Opacity pulse on outerBloomLayer
let pulseAnim = CABasicAnimation(keyPath: "opacity")
pulseAnim.fromValue    = 0.3
pulseAnim.toValue      = 0.6
pulseAnim.duration     = statePulseDuration  // matches breathing dot speed
pulseAnim.autoreverses = true
pulseAnim.repeatCount  = .infinity
```

---

## 5. Notch visual states

The notch renders in five distinct modes. The window is always positioned over the camera bump and uses `NSWindow.Level.statusBar + 1`.

### Idle (`~130 × 32pt`)

Default resting state. Three elements inside the black pill:

1. **Breathing dot** — 7pt circle, state color, scales 0.88 → 1.15 on repeat
2. **Label** — "In flow" / "Heads-up" / "Rest needed", 9pt SF Pro, state color
3. **Mini progress bar** — 2pt tall × 38pt wide, fill % encodes wellness score

Outside the black pill on the transparent canvas:
- **Left ambient** — focus streak duration e.g. "92m focus", 9pt, `#999999`
- **Right ambient** — current time e.g. "9:41", 9pt, `#999999`

```
[LEFT AMBIENT]   [● dot] [label] [▬▬▬▬▬]   [RIGHT AMBIENT]
  "92m focus"     purple  "In flow"  72%        "9:41"
```

### Hover (`~280 × 32pt`)

Triggered by `NSTrackingArea`. Expands horizontally with spring animation. Shows four-column stats strip:

```
[ 92m focus ]  |  [ 2h 14m no break ]  |  [ 5.2h today ]  |  [ 72 wellness ]
```

Border glow shifts to `llamaMid` purple indicating interactive state.

### Expanded (`~340 × 84pt`)

Triggered by click. Drops down with spring animation. Layout:

```
● HEADS-UP  ·  3:42 PM                              ✕
Typing speed dropped 38% in 20 mins — afternoon dip.
[ Take 5-min break ]   [ Snooze 15m ]
```

Border glow shifts to `uiBlue` indicating open/active state.

### Wellness state machine

```swift
enum WellnessState {
    case flow     // minutesSinceBreak < 90
    case headsUp  // minutesSinceBreak 90–150
    case restNow  // minutesSinceBreak >= 150
}

// WellnessEngine published properties
@Published var state:               WellnessState
@Published var focusStreakMinutes:  Int
@Published var minutesSinceBreak:   Int
@Published var screenTimeMinutes:   Int
@Published var wellnessScore:       Int  // 0–100

// Score formula (v1)
func computeScore() -> Int {
    let penalty = min(minutesSinceBreak, 180)
    let raw = 100 - Int((Double(penalty) / 180.0) * 60)
    return max(0, min(100, raw))
}
```

---

## 6. Core features — v1 MVP

### Notch window

```swift
// Positioning
let notchWidth: CGFloat  = 130   // idle default
let notchHeight: CGFloat = 32
let x = (screenWidth - notchWidth) / 2
let y = screenHeight - notchHeight

// Window config
window.styleMask       = .borderless
window.level           = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.statusWindow)) + 1)
window.backgroundColor = .clear
window.isOpaque        = false
window.hasShadow       = false
window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
```

Hit-testing: only the black pill area accepts mouse events. Transparent areas pass clicks through to the desktop.

Non-notch fallback: detect notch via `NSScreen.main?.safeAreaInsets.top > 0`. On non-notched screens render a floating pill at the same top-center position with identical UI.

### Break scheduler

`BreakScheduler` uses a 60-second `Timer` tick:

| Break type | Default interval | Copy category |
|---|---|---|
| Eye rest (20-20-20) | 45 min | `eyeRest` |
| Movement / stretch | 60 min | `movement` |
| Hydration | 45 min | `hydration` |
| Evening wind-down | 20:30 (configurable) | `windDown` |

On each tick:
1. Check `CalendarBridge.isInMeeting()` — if true, skip all timers
2. Check idle time via `CGEventSource.secondsSinceLastEventType` — if > 5 min, pause
3. Check working hours from `SettingsStore` — if outside range, skip
4. If break due: update `WellnessEngine`, call `NotificationManager.send(type:)`, expand notch

Snooze: reschedule trigger for +15 min.
Take break: record `BreakRecord` in SwiftData, reset `minutesSinceBreak = 0`.

### Focus tracker

```swift
// App switching
NSWorkspace.shared.notificationCenter.addObserver(
    forName: NSWorkspace.didActivateApplicationNotification, ...)

// Idle detection — polled every 60s
CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: .mouseMoved)
```

Track: `appSwitchCount`, `activeAppName`, `lastUserActivityDate`.

### Calendar bridge

```swift
class CalendarBridge {
    let store = EKEventStore()
    func requestAccess() async -> Bool
    func isInMeeting() -> Bool          // checks EKEvent spanning Date.now
    func nextMeetingIn(minutes: Int) -> EKEvent?
}
```

Request `EKEntityType.event` access. Check default calendar for events overlapping `Date.now`.

### Notification manager

`UNUserNotificationCenter` for banner fallback (external display / no notch visible).

3 copy variants per break type, randomly selected to avoid repetition:

```swift
// Eye rest
"Your eyes have been working hard. Look 20 feet away for 20 seconds."
"20-20-20 time. Pick something 20ft away and let your eyes relax."
"Eyes need a reset. Stare at something distant for 20 seconds."

// Movement
"Time to move. Even 2 minutes of standing resets your posture."
"Your body needs a reset. Stand up and stretch for a moment."
"You've been sitting a while. Stand up — your back will thank you."

// Hydration
"When did you last drink water? Now's a good time."
"Hydration check. A glass of water makes the next hour easier."
"Water break. Your brain works better hydrated."

// Wind-down
"Good work today. Closing Slack now helps your brain switch off."
"It's evening. What you close now, you won't dream about tonight."
"Time to wind down. The work will still be there tomorrow."
```

---

## 7. Onboarding flow

Onboarding runs once on first launch. Gated by `@AppStorage("hasCompletedOnboarding")`. The notch window and menu bar icon do **not** appear until onboarding completes.

### Window setup

```swift
let window = NSWindow(
    contentRect: NSRect(x: 0, y: 0, width: 720, height: 560),
    styleMask: [.titled, .fullSizeContentView, .closable],
    backing: .buffered,
    defer: false
)
window.titlebarAppearsTransparent = true
window.titleVisibility            = .hidden
window.isMovableByWindowBackground = true
window.backgroundColor            = .clear
window.center()
```

Root view: `NSVisualEffectView` with `.behindWindow` blending and `.dark` appearance. Content card: `RoundedRectangle` fill `.black.opacity(0.35)` with 0.5pt white-10% stroke.

### Step structure

```swift
struct OnboardingStep {
    let index:    Int
    let icon:     String      // SF Symbol name
    let iconColor: Color
    let title:    String
    let subtitle: String
    let detail:   String
    let action:   OnboardingAction
}

enum OnboardingAction {
    case next
    case demo
    case requestPermission(Permission)
    case finish
}

enum Permission { case calendar, notifications }
```

### Navigation

Progress dots at bottom of every step. Filled = completed, outline = upcoming, pulsing = current. Tapping a completed dot navigates back. No forward skipping.

Back button from step 2 onwards — `chevron.left`, top-left, secondary style.

Skip link at the bottom of every step:
```
Are you sure? You can always rerun onboarding in Settings → General.
[Skip setup]   [Continue setup]
```

### Step 1 — Welcome

**Title:** "Meet your notch"
**Subtitle:** "A wellness companion that lives at the top of your screen"
**Detail:** "Notch Wellness turns the camera bump on your MacBook into something useful — a quiet, always-visible signal of how your body and mind are doing right now."
**Action:** next

Hero: animated `NotchPillPreview` (160 × 40pt) showing Flow state with green bloom, centered in upper half of card.

Three feature pills below in a horizontal row:

```
[circle.fill]          [timer]               [bell.slash]
Ambient glow           Smart reminders        Never intrusive
```

### Step 2 — How the glow works

**Title:** "Three states, one glance"
**Subtitle:** "You always know how you're doing without opening anything"
**Detail:** "The notch changes color and breathing speed based on how long you've been working. Purple means you're in flow. Pink means a nudge is forming. Red means your body needs a reset."
**Action:** demo

Three live `NotchPillPreview` instances stacked (140 × 32pt, 16pt gaps):

```
[● purple bloom]   In flow       ·   < 90 min since break
[● pink bloom]     Heads-up      ·   90–150 min since break
[● red bloom]      Rest needed   ·   150+ min since break
```

Demo button cycles through states with 1.2s delay, animating real glow and pulse changes.

Caption: "The notch sits at the top of your screen at all times. No windows to open."

### Step 3 — Break reminders

**Title:** "Breaks that actually make sense"
**Subtitle:** "Timed to when your body needs them, not a fixed clock"
**Detail:** "Every 45 minutes your eyes get a 20-20-20 reminder. Every hour, a movement nudge. Reminders pause automatically during meetings and when you step away."
**Action:** next

Three `NotificationPreviewCard` instances with staggered slide-up animation:

```
┌──────────────────────────────────────────────┐
│ ● EYES  ·  2:14 PM                           │
│ Look 20 feet away for 20 seconds.            │
│ [Start eye break]   [Snooze 15m]             │
└──────────────────────────────────────────────┘

┌──────────────────────────────────────────────┐
│ ● MOVEMENT  ·  4:30 PM                       │
│ Time to stand. Even 2 minutes resets you.    │
│ [Take break]   [Snooze 15m]                  │
└──────────────────────────────────────────────┘

┌──────────────────────────────────────────────┐
│ ● EVENING  ·  8:30 PM                        │
│ Good work today. Time to close Slack.        │
│ [Wind down]   [Maybe later]                  │
└──────────────────────────────────────────────┘
```

Cards: dark glass `rgba(0,0,0,0.6)`, white text, `uiGreen` action pills.

### Step 4 — Calendar permission

**Title:** "Pause during meetings"
**Subtitle:** "We'll never interrupt you mid-call"
**Detail:** "Notch Wellness reads your calendar to automatically pause all reminders when you're in a meeting. Your calendar data never leaves your Mac."
**Action:** requestPermission(.calendar)

```swift
// Permission card
┌──────────────────────────────────────────────┐
│  [calendar SF Symbol, 48pt, uiBlue]          │
│  Allow Calendar Access                       │
│  Read-only · Local only · Never uploaded     │
│                                              │
│  [Allow Access]        [Skip for now]        │
└──────────────────────────────────────────────┘

// Trust signals row below card
[lock.fill]          [eye.slash]          [icloud.slash]
Read-only access     Event titles only    Never synced
```

"Allow Access" calls `EKEventStore.requestAccess(to: .event)`.
"Skip for now" advances to step 5 with note: "Enable in Settings → Schedule anytime."
Already-granted: show green checkmark, auto-advance after 1.2s.

### Step 5 — Notification permission

**Title:** "Banner reminders as backup"
**Subtitle:** "For when you're on an external display without a notch"
**Detail:** "The notch is the primary way we reach you. Banner notifications are a fallback when your MacBook's built-in display isn't active."
**Action:** requestPermission(.notifications)

```swift
┌──────────────────────────────────────────────┐
│  [bell SF Symbol, 48pt, llamaMid]            │
│  Allow Notifications                         │
│  Only when notch isn't visible               │
│                                              │
│  [Allow Notifications]   [Use notch only]    │
└──────────────────────────────────────────────┘
```

"Allow Notifications" calls `UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])`.
"Use notch only" sets `notificationStyle = .notchOnly`, advances without requesting.

### Step 6 — Set your schedule

**Title:** "When do you work?"
**Subtitle:** "We'll only nudge you during your hours"
**Detail:** "Set your typical working hours and active days. You can always adjust this in Settings."
**Action:** finish

Inline mini-settings panel with Liquid Glass inputs:

```
Working hours
  [09:00]  to  [18:00]

Active days
  [M]  [T]  [W]  [T]  [F]  [ ]  [ ]

Evening wind-down
  [20:30]

              [Start using Notch Wellness →]
```

Finish action:
1. Save schedule values to `@AppStorage`
2. `hasCompletedOnboarding = true`
3. Fade-out + scale-down onboarding window
4. Simultaneously fade-in notch window — user sees notch come alive for the first time

### Re-running onboarding

Button in `GeneralSettingsView`:
```
[arrow.clockwise]  Rerun onboarding
```

Resets only the walkthrough UI — does not reset permissions or wellness data.

---

## 8. Settings — Liquid Glass

### Window setup

```swift
// NSWindow
window.titlebarAppearsTransparent = true
window.titleVisibility = .hidden

// Root NSVisualEffectView
effectView.blendingMode = .behindWindow
effectView.material     = .sidebar

// Sidebar NSVisualEffectView
sidebarEffect.material = .sidebar

// Content NSVisualEffectView
contentEffect.material = .menu
```

Use SwiftUI `Settings { SettingsView() }` scene for automatic `⌘,` shortcut. `Form` with `.grouped` style + `List` gets inset rounded card grouping on macOS 14+ automatically. `Label` with SF Symbols + colored `RoundedRectangle` icon backgrounds matching System Settings.

### General page

- Launch at login — `SMAppService.mainApp.register()` / `unregister()`
- Show menu bar icon fallback — Toggle
- Sound effects — Toggle
- Notification style — Picker: Notch only / Notch + banner / Banner only
- Wellness score in hover — Toggle
- Urgency threshold — Picker: Low / Medium / High (shifts state transition timing ±20%)
- Rerun onboarding — Button with `arrow.clockwise` icon

### Schedule page

- Working hours — two `DatePicker` with `.hourAndMinute`
- Active days — custom 7-button `M T W T F S S` toggle row
- Pause during meetings — Toggle (requires calendar permission)
- Pause when idle — Toggle + idle threshold Slider (3–10 min)
- Evening wind-down time — `DatePicker`
- Weekend mode — Toggle (lighter nudges, longer intervals)

### Breaks page

- Eye rest — Toggle + interval Slider (15–90 min)
- Movement — Toggle + interval Slider (30–120 min)
- Hydration — Toggle + interval Slider (30–90 min)
- Never interrupt flow — Toggle (waits for current streak to end before nudging)

### Notch page

- Border glow — Toggle
- Glow intensity — Slider (1–10)
- Outer bloom — Toggle
- Side ambient info — Toggle
- Mini progress bar — Toggle
- Expand trigger — Picker: Hover / Click / Both
- Custom accent override — Toggle + 6 color swatches

### Privacy page

Info banner at top: "All data stays on your Mac. Nothing is ever uploaded, synced, or shared."

- Local processing only — Toggle, locked on in v1
- Crash reports — Toggle, default off
- Store wellness history — Toggle
- Retention period — Picker: 30 days / 90 days / 1 year / Forever
- Delete all wellness data — destructive Button with confirmation `Alert`

---

## 9. Persistence and system

### SwiftData models

```swift
@Model class BreakRecord {
    var timestamp: Date
    var type:      String   // "eyeRest" | "movement" | "hydration" | "windDown"
    var triggered: Bool     // true = app triggered, false = user took manually
    var snoozed:   Bool
}

@Model class SessionRecord {
    var date:             Date
    var focusMinutes:     Int
    var breakCount:       Int
    var appSwitchCount:   Int
    var peakFocusStreak:  Int
}
```

### AppStorage keys

```swift
// Onboarding
"hasCompletedOnboarding"   Bool    default: false

// General
"launchAtLogin"            Bool    default: true
"showMenuBarIcon"          Bool    default: false
"soundEffects"             Bool    default: true
"notificationStyle"        String  default: "notchOnly"
"showWellnessScore"        Bool    default: true
"urgencyThreshold"         String  default: "medium"

// Schedule
"workStartHour"            Int     default: 9
"workStartMinute"          Int     default: 0
"workEndHour"              Int     default: 18
"workEndMinute"            Int     default: 0
"activeDays"               String  default: "MTWTF"
"pauseDuringMeetings"      Bool    default: true
"pauseWhenIdle"            Bool    default: true
"idleThresholdMinutes"     Int     default: 5
"windDownHour"             Int     default: 20
"windDownMinute"           Int     default: 30
"weekendMode"              Bool    default: false

// Breaks
"eyeRestEnabled"           Bool    default: true
"eyeRestInterval"          Int     default: 45
"movementEnabled"          Bool    default: true
"movementInterval"         Int     default: 60
"hydrationEnabled"         Bool    default: true
"hydrationInterval"        Int     default: 45
"neverInterruptFlow"       Bool    default: true

// Notch appearance
"glowEnabled"              Bool    default: true
"glowIntensity"            Double  default: 6.0
"outerBloomEnabled"        Bool    default: true
"sideAmbientInfo"          Bool    default: true
"miniProgressBar"          Bool    default: true
"expandTrigger"            String  default: "both"
"customAccentEnabled"      Bool    default: false
"customAccentHex"          String  default: "A97FD4"

// Privacy
"crashReports"             Bool    default: false
"storeHistory"             Bool    default: true
"retentionDays"            Int     default: 90
```

### System behaviour

- `LSUIElement = YES` in Info.plist — no Dock icon, background agent
- Menu bar icon: right-click → Open Settings / Pause 1 hour / Quit
- Sleep/wake: observe `NSWorkspace.didWakeNotification` — reset idle timer, resume schedulers
- Spaces: `collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]` on notch window

---

## 10. v2 AI layer — future reference

> Do not implement in v1. Documented here for continuity across sessions.

- **Local Ollama** via `http://localhost:11434/api/generate` — no API key, fully air-gapped
- Recommended models: `llama3.2:1b` or `phi3:mini` for speed on M-series
- Detect if Ollama is running at app launch; show setup prompt in Privacy page if not
- AI generates personalized nudge copy based on: state, time of day, focus streak, recent break history, coaching tone preference
- Graceful fallback: if Ollama offline → v1 templated copy, no broken states
- **Keystroke cadence** via `CGEventTap` — measure WPM delta every 5 min, never log content. Speed drop > 30% = fatigue signal
- **App switch rate** — extend `FocusTracker`, count switches per 30-min window. High rate = distraction signal
- **Rhythm learning** — track focus quality per hour-of-day over 14-day sliding window. Stop nudging during historically productive windows
- **Weekly rhythm report** — Friday 5pm notch expand. Bar chart of peak hours, AI-generated one-liner, burnout risk indicator (local only, never uploaded)

New settings page additions for v2:
- AI Coach page: model picker, coaching tone (Friendly / Direct / Minimal), behavioral signal toggles
- Privacy page update: show active model name, confirm zero external calls

---

## 11. v3 Deep wellness — future reference

> Do not implement until v2 ships.

- **HealthKit** — HRV, resting heart rate, Activity rings. Read-only. Correlate with notch state
- **Apple Watch complication** — wellness score dot (purple/pink/red)
- **Daily mood check-in** — one-tap from notch, five states, stored in SwiftData
- **Burnout risk score** — private local weekly score based on evening work, streak lengths, break compliance
- **Wind-down journal prompt** — optional evening text prompt via notch, stored locally

Monetization at v3:
- Free tier: notch states, basic break reminders, schedule, privacy page
- Pro one-time ($29): AI coaching, behavioral signals, weekly report, mood tracking, HealthKit
- Pro subscription ($4.99/mo): same as one-time, includes future updates
- Evaluate Setapp listing at v3

---

## 12. Build order

Follow this sequence strictly. Each step is independently testable before starting the next.

### v1 — Phase 1: Notch window and visuals

1. `NotchWindowController` — window positioned over notch, verify on physical MBP
2. `WellnessState` enum + `WellnessEngine` stub with hardcoded `.flow` state
3. `NotchIdleView` — breathing dot, label, mini bar rendering in black pill
4. `NotchGlowLayer` — CALayer border glow + outer bloom, nail the visual before any logic
5. `NotchHoverView` — `NSTrackingArea` + spring expand to stats strip
6. `NotchExpandedView` — click toggle, message panel, action buttons

### v1 — Phase 2: Engine and scheduling

7. `FocusTracker` — app switch tracking, idle detection
8. `BreakScheduler` — 60s tick, break intervals, wire to `WellnessEngine`
9. `CalendarBridge` — EventKit access, `isInMeeting()` pause logic
10. `NotificationManager` — `UNUserNotificationCenter`, copy variants, banner fallback

### v1 — Phase 3: Onboarding

11. `OnboardingWindowController` — window setup, first-launch gate in `AppDelegate`
12. `OnboardingContainerView` — step router, progress dots, transitions
13. `NotchPillPreview` component — reusable live notch used in steps 1 & 2
14. `NotificationPreviewCard` component — break reminder mock card for step 3
15. `PermissionCard` component — reusable for steps 4 & 5
16. Steps 1–3 — welcome, glow demo, break previews
17. Steps 4–5 — calendar + notification permission requests
18. Step 6 — inline schedule picker + finish → notch fade-in transition
19. Skip flow + rerun onboarding button in `GeneralSettingsView`

### v1 — Phase 4: Settings and persistence

20. `SettingsStore` + all `@AppStorage` keys
21. `SettingsWindowController` + `SettingsView` sidebar
22. `GeneralSettingsView`, `ScheduleSettingsView`, `BreaksSettingsView`
23. `NotchSettingsView`, `PrivacySettingsView`
24. SwiftData models — `BreakRecord` + `SessionRecord`

### v1 — Phase 5: Polish

25. State transition animations, glow color changes
26. Sleep/wake handling
27. Non-notch screen fallback (floating pill)
28. Multi-space / Mission Control persistence
29. Menu bar icon right-click menu
30. TestFlight build — test on notched MBP, non-notched iMac, external display

---

## 13. Permissions and entitlements

### Info.plist

```xml
<key>LSUIElement</key>
<true/>

<key>NSCalendarsUsageDescription</key>
<string>Wellness Coach reads your calendar to pause break reminders during meetings.</string>

<key>NSUserNotificationsUsageDescription</key>
<string>Wellness Coach sends break reminders when the notch is not visible.</string>
```

### Entitlements

```xml
<key>com.apple.security.app-sandbox</key>
<true/>

<key>com.apple.security.personal-information.calendars</key>
<true/>

<key>com.apple.developer.service-management.login-items.allowed</key>
<true/>
```

---

## 14. Key technical notes

**Notch detection**
```swift
// Screen has a notch if safeAreaInsets.top > 0
let hasNotch = NSScreen.main?.safeAreaInsets.top ?? 0 > 0
```

**Hit-testing — pass clicks through transparent canvas**
```swift
// NotchWindow subclass
override func mouseDown(with event: NSEvent) {
    let point = contentView!.convert(event.locationInWindow, from: nil)
    let pillRect = CGRect(x: ..., y: 0, width: currentNotchWidth, height: 32)
    if !pillRect.contains(point) {
        // pass through to desktop
    } else {
        super.mouseDown(with: event)
    }
}
```

**Notch window must not steal focus** — set `window.level` correctly and ensure `canBecomeKey` returns `false` unless the expanded panel is open (for action button taps).

**External display behaviour** — detect when the primary screen changes via `NSApplication.didChangeScreenParametersNotification`. Reposition notch window accordingly. On external display with no notch, render floating pill at same coordinates with identical components.

**Onboarding gate in AppDelegate**
```swift
func applicationDidFinishLaunching(_ notification: Notification) {
    if !UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") {
        OnboardingWindowController.shared.show()
        // Do NOT create notch window or menu bar item yet
    } else {
        setupNotchWindow()
        setupMenuBarItem()
    }
}
```

**Memory management** — all `NSWorkspace` notification observers and `NSTrackingArea` instances must be explicitly removed on deinit. Use `[weak self]` in all timer closures to prevent retain cycles.

**CALayer animations and main thread** — all `CALayer` property changes must happen on the main thread. Use `DispatchQueue.main.async` when updating from timer callbacks.

---

## 15. v1 deliverable checklist

- [ ] Onboarding appears on first launch, notch hidden until complete
- [ ] All 6 onboarding steps render with correct content and animations
- [ ] Permission requests in steps 4 and 5 work and handle skip gracefully
- [ ] Step 6 schedule values persist and notch fades in on finish
- [ ] Notch window renders correctly on notched MacBook (14" and 16" MBP)
- [ ] Three glow states (purple/pink/red) with smooth color transitions
- [ ] Breathing dot animation speed varies per state
- [ ] Side ambient labels render outside the pill on transparent canvas
- [ ] Hover expands to stats strip with correct four metrics
- [ ] Click expands to message panel with action buttons
- [ ] Break scheduler fires at configured intervals
- [ ] Meeting detection via EventKit pauses timers correctly
- [ ] Idle detection pauses timers after 5 minutes of inactivity
- [ ] Snooze reschedules correctly, take break resets timer and records to SwiftData
- [ ] All five settings pages functional with Liquid Glass design
- [ ] `⌘,` opens settings window
- [ ] Launch at login via `SMAppService` works
- [ ] Notch-only and banner notification modes both function
- [ ] SwiftData persists break and session history
- [ ] App runs as background agent — no Dock icon
- [ ] Non-notched screen shows floating pill fallback
- [ ] Notch window persists across Spaces and Mission Control
- [ ] No crashes on sleep/wake cycle
- [ ] No memory leaks in timer, observer, or CALayer pattern
- [ ] Rerun onboarding button in General settings works