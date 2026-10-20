# GramHealth — Design System: Clear Careway

> The replacement visual world for the GramHealth Flutter client.
> Source of truth: `.impeccable/design.json`. Implementation: `GramHealth/lib/theme/`,
> `GramHealth/lib/widgets/`. Mode: **Operate** — task completion over persuasion.

---

## 1. North Star

**The Clear Careway.** GramHealth reads as excellent civic wayfinding translated into a caring
Android healthcare companion: direct, legible, impossible to get lost inside.

Every screen answers three questions quickly:

1. **Where am I** — screen context and navigation
2. **What matters now** — current state, expressed in words, never by color alone
3. **What is the safest next action** — exactly one dominant action per screen

Reassurance comes from generous breathing room, warm neutral surfaces, friendly typography, and
human status language — not from haze, excessive rounding, or pale text. High contrast is the
signature: important information is allowed to look important, and offline/emergency states are
unmistakable without turning the whole interface into an alert.

This world **replaces** the previous leaf-green glassmorphism identity. Product truth, content,
function, role boundaries, and privacy behavior are preserved; the old visual treatment is
anti-reference, not a starting point.

---

## 2. Color

### Palette (canonical, from `design.json`)

| Role | Token | Value | Meaning |
|---|---|---|---|
| Ink | `AppColors.ink` | `#17211D` | Headings, primary text, user bubble |
| Ink soft | `AppColors.inkSoft` | `#3B4A43` | Supporting copy |
| Ink muted | `AppColors.inkMuted` | `#53625A` | Metadata, inactive icons |
| Ink faint | `AppColors.inkFaint` | `#718078` | Placeholders, dividers of last resort |
| Clear Teal | `AppColors.teal` | `#007A6E` | Primary action, brand, nav indicator |
| Clear Teal deep | `AppColors.tealDeep` | `#00574F` | Hover, selected text, focus ring |
| Careway Mint | `AppColors.mint` | `#D5F3EC` | Tonal button, selected chip, focus wash |
| Careway Mint light | `AppColors.mintLight` | `#F0FCF9` | Banner and section wash |
| Sunlit Amber | `AppColors.amber` | `#F0A624` | Secondary signal, upload action |
| Amber deep | `AppColors.amberDeep` | `#9A5B00` | Amber text on wash |
| Warm Coral | `AppColors.coral` | `#D9584B` | Non-emergency alert |
| Emergency Red | `AppColors.emergency` | `#B3261E` | SOS and urgent care **only** |
| Careway Ground | `AppColors.ground` | `#F7FAF7` | Screen background |
| Surface White | `AppColors.surface` | `#FFFFFF` | Card and bar surfaces |
| Border light | `AppColors.borderLight` | `#EAF1ED` | 1px card border |
| Border | `AppColors.border` | `#C4CEC8` | Field and chip border |
| Border strong | `AppColors.borderStrong` | `#718078` | Resting field border |

### Rules

- **The Signal Budget Rule** — one dominant + one supporting signal color per screen. Emergency
  red is never decorative. Status is never communicated by color alone: every status carries a
  dot **and** text (`● Offline — saved on this device`).
- **The Opaque Surface Rule** — if removing blur makes text harder to read, the component was
  relying on decoration. All surfaces are opaque; hierarchy does the work.
- **No glass, no blur, no translucency, no gradients as default depth.** Tonal elevation and two
  ambient shadows only.
- **No muddy olive greens, desaturated corporate blues, or gray-on-gray text** as identity cues.
- Emergency red, amber, and coral are reserved. Mint is the only "tint" color.

### Elevation

| Name | Value | Use |
|---|---|---|
| `AppColors.shadowLow` | `0 1px 3px rgba(23,33,29,.12)` | Resting cards, nav surfaces |
| `AppColors.shadowRaised` | `0 6px 18px rgba(23,33,29,.14)` | Menus, bottom sheets, the single FAB |

---

## 3. Typography

Two families, two weights, one size per component role.

| Role | Family | Size | Weight | Line height |
|---|---|---|---|---|
| Display | Manrope | 28 / 20 / 18 | 800 / 700 | 1.15 – 1.3 |
| Body | Manrope | 16 / 15 / 14 | 500 / 400 | 1.43 – 1.45 |
| Label | Manrope | 14 / 13 / 12 | 700 / 600 | 1.2 – 1.25 |

- **The Two-Weight Rule** — a component uses one text size and two weights at most: a clear title
  and a readable supporting value.
- Display (Manrope) appears **once per screen** at most, for the greeting, the onboarding promise,
  or a rare patient summary. Everything else is body or label.
- Patient-facing body text is **16sp minimum**. Translations are verified at Android font scale
  **1.3x**; nothing clips, nothing truncates, and no CTA shrinks to fit.
- Labels are never all-caps. Chips keep persistent text labels, never icon-only.
- Devanagari and Gujarati render through the same family stack with the same weight ladder.

---

## 4. Shape, Space, Motion

**Radii** (`AppRadii`): `sm 8` · `md 10` · `lg 14` (cards) · `xl 20` (hero surfaces) · `pill 999`
(chips, status markers).

**Spacing**: 8dp rhythm. 20dp page gutters, 16dp card padding, 12dp between tightly related
elements. **The Breathing Room Rule** — the gap above a section heading is at least one rhythm step
larger than the gap below it, so hierarchy survives a tired, zoomed, or translated reader.

**Motion** (`AppMotion`): `ease-standard` = `cubic-bezier(0.2, 0, 0, 1)`.
`duration-state` = 180ms (selection, focus, pressed, chip state).
`duration-route` = 280ms (route changes). **Reduce Motion** collapses route transitions to a
crossfade. One FAB per screen. CustomPainters are sparse, semantic, and constraint-aware.

---

## 5. Components

All live in `GramHealth/lib/widgets/`.

| Component | Contract |
|---|---|
| `CareCard` | Opaque white, 1px `#EAF1ED`, 14r, `shadowLow`, 20 padding. The only card surface. |
| `CareChip` | Pill, mint when selected, white when not, persistent text label. |
| `StatusChip` | Compact dot + text, ambient wash. Never color alone. |
| `PrimaryButton` | Teal `#007A6E`, 48h, 10r, white label, 180ms press. The one dominant action. |
| `TonalButton` | Mint wash, 48h, supportive secondary. |
| `EmergencyButton` | Emergency red, 52h. Reserved for SOS. |
| `CareInput` / `CustomInput` | Opaque, 56h, persistent label, focus = 2px teal + mint wash. |
| `CareIconButton` / `CareInlineIconButton` | Minimum 48dp touch area, visual chip may be smaller. |
| `CareSearchField` / `CustomSearchBar` | Opaque, 1px border, teal focus. |
| `ConnectivityBadge` | Online hidden; weak = amber pill; offline = neutral pill. |
| `OfflineStatusIndicator` | AI • Online / Offline (+ Knowledge mode) with dot + text. |
| `OfflineSetupCard` | Shows only when offline and the model is not ready or lexicon-only. |
| `StatCard` / `StatusBadge` | KPI tile and status marker for console surfaces. |
| `LoadingState` / `EmptyState` | First-class list states with an actionable next step. |
| `StructuredClinicalResponseCard` | Nine-section clinical card with emergency banner. |
| `LanguageSelectorModal` | Bottom sheet, en/hi/mr/gu radios, instant swap, no restart. |
| `MainShell` | Compact: 80dp NavigationBar, mint indicator. Medium/expanded: NavigationRail. |
| `DashboardLayout` + `Sidebar` | Persistent nav ≥840dp, drawer below, content capped at 1200dp. |

`GlassCard` survives only as a compatibility shim rendering the opaque Careway surface. No screen
imports it.

---

## 6. Layout & Breakpoints

| Class | Width | Navigation |
|---|---|---|
| Compact | < 600dp | Top app bar + 80dp bottom NavigationBar, 5 tabs |
| Medium | 600 – 839dp | NavigationRail |
| Expanded | ≥ 840dp | Persistent nav, centered content, 1200dp max |

Every screen handles window and IME insets, keyboard avoidance for fields and the voice recorder,
and safe-area padding that is not double-counted.

---

## 7. Screen Composition

Hierarchy per screen, in order: **context → state → primary action → supporting detail.**

- **The Careway Rule** — the next safe action is more obvious than the decoration.
- Exactly one dominant action per task. Secondary actions are tonal, never competing.
- Lists are scannable rows, not stacks of same-size cards. No nested cards, no dashboard tile
  grids on patient surfaces.
- Every list defines **loading, empty, error, offline, and permission-denied** states.
- Emergency surfaces are unmistakable but contained: one red SOS target, plus quiet first-aid
  cards that work offline.

---

## 8. Constraints

- Material 3 throughout; Android system Back, insets, dynamic type, and Reduce Motion respected.
- 4 locales (en/hi/mr/gu) with full key parity — 138 keys, no English-only truncation.
- Offline-first: cached records, queued writes, `sync_queue` drain, deterministic offline
  lexicon responses, and a 70+ keyword emergency safety layer that runs before any network call.
- Role boundaries and privacy behavior are never changed by visual work. The backend remains the
  sole gateway; `clearAllData()` runs on login and logout.
- Clinical content, safety rules, and offline response strings are contractual and reproduced
  exactly — visual work never alters clinical meaning.

---

## 9. Anti-patterns

Do not ship: glassmorphism or blur-dependent legibility · muddy olive or desaturated corporate
blue identity cues · gray-on-gray low-contrast text · stacks of same-size cards or nested cards ·
color-only status · emoji as a system signal · icon-only chips with no label · hidden critical
guidance behind a tooltip or modal · text shrunk to preserve a fixed composition · oversized
floating buttons substituting for a coherent action system.
