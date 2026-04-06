# Kitab — V1 Product Specification

## 1. Product Vision & Principles

### Vision

**One-liner:** Kitab is a living book of deeds — a comprehensive habit and activity tracker that helps users grow individually and collectively through meaningful self-reflection and powerful insights.

**Core metaphor:** Your life is a book being written in real-time. Every habit you build, every action you take, every streak you maintain is a page in your Kitab. The app makes that book visible, measurable, and beautiful.

**Cultural foundation:** The word "Kitab" comes from the Arabic word for "book." The app draws inspiration from the Islamic concept of the book of deeds — a record of one's actions presented on the Day of Judgement. Kitab acts as a digital, living version of that concept. While rooted in Islamic philosophy, the app is inclusive and equally valuable to all users regardless of background.

### Design Principles (Ranked)

When two principles conflict, the higher-ranked one wins.

1. **Clarity over cleverness** — Every screen should be immediately understandable. No mystery icons, no hidden gestures, no jargon. A first-time user and a power user should both feel at home.

2. **Progressive depth** — Simple on the surface, powerful underneath. A beginner sees a clean tracker. A power user discovers custom categories, detailed analytics, and automation. The complexity is there but never forced.

3. **Reflection, not judgment** — The app feels like a wise companion, not a disappointed parent. Missed a habit? Here's your pattern. Not a guilt trip. The tone is encouraging, insightful, and never punishing.

4. **Beauty with purpose** — Every visual element earns its place. Islamic geometric patterns represent the interconnectedness of habits and growth. Gold accents mark achievement and progress. Nothing is purely ornamental.

5. **Accessible by default** — Not an afterthought. Every color, every interaction, every piece of text is designed to work for everyone — screen readers, color blindness, motor impairments, large text. If it doesn't work for everyone, it doesn't ship.

6. **Offline is real** — On native devices, the app works fully without internet. Sync is seamless and invisible. Users should never think about connectivity.

---

## 2. Feature List & Information Architecture

### 2.1 Core Concept: Activities

Activities are the fundamental unit of Kitab. Everything the user tracks is an activity.

#### Activity Configuration (Template)

A configured activity is a reusable template that defines what the user wants to track and how. It includes:

- **Identity:** Name, icon, color, category
- **Metric fields:** The user chooses which data points to capture per entry (one or more):
  - Start date/time
  - End date/time
  - Duration
  - Number value (float or integer)
  - Text value
  - Star rating (1–5 stars, half-star intervals)
  - Boolean value (yes/no)
  - Single select (from a user-defined dropdown list)
  - Multi select (from a user-defined dropdown list)
  - Number bounded by a range (user-defined min/max)
  - Location (stored as coordinates)
  - List of items
- **Frequency schedule (optional):** How often the user expects to do this activity (daily, specific days, X times per week, custom intervals)
- **Goals (optional):** One or more targets tied to specific metrics. Each goal defines:
  - The metric being measured
  - The target value/threshold
  - The assessment window (how the goal is evaluated):
    - Per activity entry (each individual log is assessed)
    - Per expected frequency (e.g., "did I hit my goal this week?") — **default**
    - Over last X entries (rolling window)
    - Over X period of time (e.g., last 30 days)
    - Over all-time entries (cumulative)

**UX: Progressive disclosure for metric selection:**
- Common presets are pre-selected based on category/template (e.g., "Exercise" defaults to duration + boolean)
- Advanced metrics are hidden behind "Add more fields" — beginners see 3–4 obvious options, power users expand to see all 12
- Goal assessment windows default to "per frequency"; other modes available under "Advanced"
- Plain-language preview of goal behavior: *"Your streak counts how many consecutive weeks you hit 3 workouts"*

#### Activity Log (Entry)

An activity log is a single recorded instance. It can be:

- **Linked to a configured activity** — metric fields are pre-populated based on the template
- **Ad-hoc (no template)** — the user logs a freeform entry with whatever data they choose

After repeated ad-hoc entries with similar names/patterns, the app suggests creating a configured activity template from them.

#### Habits

A "habit" is not a separate concept — it is an activity with:
- A frequency schedule set
- A boolean or existence-based goal (did I do it or not within the expected frequency?)

The word "habit" may appear in the UI as a label/filter, but the underlying data model is always an activity.

### 2.2 Streaks

Streaks are derived from goals. Each goal evaluates to a pass/fail per assessment window.

- **Current streak:** How many consecutive assessment windows the goal has been met
- **Best streak:** The longest consecutive streak ever achieved for that goal

The UI must clearly communicate what a streak means per goal — not just "🔥 5" but "🔥 5 weeks" or "🔥 5 out of last 5 entries" depending on the assessment window.

### 2.3 Social Features

#### Friends
- Users can add/accept friends
- No public feed, no posting, no commenting on others' progress
- Profile is minimal: name, avatar, bio

#### Sharing
- Users choose specific activities to share with specific friends (or all friends)
- Default is private — nothing is shared unless explicitly configured
- Shared activities allow friends to see: streaks, goal progress, completion rates

#### Competitions
- Any user can create a competition
- A competition is essentially a shared activity configuration — same metrics, same rules for all competitors
- Competitions can have one or more **leaderboards**, each tied to a single goal/metric
  - Leaderboards rank competitors by the goal's measure (total value, streak length, completion rate, highest single value, etc.)
  - Leaderboard goals do not need to be streak-based — they can measure any metric (e.g., total distance ran)
- Competitions can be:
  - **Public** — any Kitab user can join
  - **Private** — invite-only
- Individual competition only (teams = V2)
- The competition creator defines all rules: activity configuration, metrics tracked, leaderboard goals, duration (start and end dates required, maximum span 3 months)

### 2.4 Insights & Analytics
- Daily / weekly / monthly / yearly views
- Streak visualizations, completion heat maps
- Pattern detection (correlations between activities: "you exercise more on days you wake up early")
- Progress over time, trend lines
- Personal records and milestones
- Per-activity and cross-activity analysis

### 2.5 Onboarding & Personalization
- First-time setup flow: experience level, interests, goals
- Suggested activity templates (beginner packs, faith-based packs, fitness packs, productivity packs, etc.)
- No account required to start on native — full functionality with local data
- Account creation prompted when user wants: cloud sync, social features, or web access
- On sign-up: local data pushes to cloud → last-write-wins conflict resolution → pull from cloud
- App suggests creating templates from repeated ad-hoc entries

### 2.6 Settings & Profile
- Account management (create, sign in, sign out, delete)
- Theme toggle (light / dark / system auto)
- Notification preferences
- Data export
- Privacy controls (what's shared, what's private per activity per friend)
- Accessibility options
- About / legal

### 2.7 Information Architecture (Screen Map)

```
App Launch
├── [No account, first time] → Onboarding Flow → Home
├── [No account, returning] → Home (local data, session persisted)
├── [Has account, native] → Home (synced data, session persisted)
├── [Has account, web] → Home (session persisted) or Sign In page (if session expired)
└── [Web, no account] → Sign In / Create Account page → Onboarding → Home

Bottom Navigation (phone) / Icon Rail (web desktop) / Bottom Nav (web mobile)
├── Home
│   ├── Summary card (greeting, dates, progress ring, all-goals streak)
│   │   └── Tap → Today's Summary bottom sheet (detailed breakdown)
│   ├── Active condition chips (if any, horizontally scrollable)
│   ├── Scheduled Today (activity + routine cards with status icons)
│   │   └── Tap card → action bottom sheet (Record/Link/Miss/Reason)
│   ├── Needs Attention (unaddressed past periods, max 3 shown)
│   │   └── See All → dedicated sub-screen with filters, search, bulk actions
│   ├── Mini-timer/routine widgets (if active, above bottom nav)
│   ├── Notification bell (top right, badge dot)
│   │   └── Tap → Notifications sub-screen
│   └── FAB (always visible, arc speed dial)
│
├── Book
│   ├── Filter row (⚙ Filters, 🔍 Search, 📅 Date, Categories, Goal Status, Conditions)
│   ├── Chronological timeline with sticky day separators
│   │   ├── Day headers show active conditions (tappable)
│   │   ├── Entry cards (category color border, goal status inline)
│   │   ├── Routine entry cards (completion count, duration)
│   │   └── Condition cards (in Conditions filter only)
│   ├── + button (top right, expanded entry form for retroactive logging)
│   └── FAB
│
├── Insights
│   ├── [Dashboard] tab — ready-made insights
│   │   ├── Period selector (week, month, 3m, 6m, year, all-time, Ramadan comparisons)
│   │   ├── Overview stat tiles (goals met %, best streak, entries, time tracked)
│   │   ├── Completion heat map (calendar grid)
│   │   ├── Category breakdown (horizontal bars, expandable)
│   │   ├── Activity rankings (best first / needs attention toggle)
│   │   ├── Trends (line charts, metric dropdown)
│   │   ├── Patterns (auto-generated insights, 6 pattern types)
│   │   ├── Conditions summary (days, impact, adjusted rate)
│   │   ├── Routines performance
│   │   └── Personal records (all-time, gold accent)
│   ├── [My Charts] tab — user-created visualizations
│   │   ├── Favorites section
│   │   ├── All charts list
│   │   └── Chart builder (8 chart types, live preview)
│   └── FAB
│
├── Social (account required)
│   ├── [Friends] tab
│   │   ├── Pending requests (accept/decline)
│   │   ├── Friends list (tap → Friend Detail with shared activities, reactions)
│   │   └── Add Friend (search by email/username, invite link)
│   ├── [Shared] tab
│   │   ├── All activities/routines with sharing status
│   │   └── Per-activity sharing editor (Private / Specific friends / All friends)
│   ├── [Competitions] tab
│   │   ├── Active, Upcoming, Completed sections
│   │   ├── Competition detail (rules, leaderboard, progress, log entry)
│   │   └── Create competition (3-step: basics, activity/leaderboard, invite)
│   └── FAB
│
└── Profile
    ├── Profile card (avatar, name, email, member since — or Guest card with Create Account / Sign In)
    ├── My Activities (activity templates + categories, Activity Detail View with history)
    ├── My Routines (routine templates, Routine Detail View)
    ├── Calendar & Date (Hijri, Islamic personalization, date/time/timezone format, week start)
    ├── Appearance (theme: light, dark, system auto)
    ├── Notifications (per-type toggles, reminder time, condition interval)
    ├── Privacy & Sharing (default sharing, profile visibility, competition invites)
    ├── Condition Presets (system + custom, hide/show, reorder)
    ├── Data & Storage (export JSON/CSV, import JSON, favorite locations, local cache)
    ├── Account (sign in/out, change email/password, biometric lock, delete account)
    └── About (version, terms, privacy, licenses, contact, rate app, re-run onboarding)
```

### 2.8 Platform Differences

| Feature | Native (iOS/Android) | Web |
|---|---|---|
| Data storage | Local-first (Drift/SQLite) + cloud sync | Cloud-only (Supabase direct) |
| Account required | No (local mode available) | Yes |
| Offline support | Full functionality | No (graceful "you're offline" message) |
| Haptic feedback | Yes | No |
| Push notifications | Yes (APNs/FCM) | Browser notifications (if permitted) |
| Location capture | Native GPS | Browser geolocation API |
| App icon badging | Yes | No |
| Widgets | V2 (with Apple Watch) | N/A |

---

## 3. Design System

### 3.1 Color Palette

#### Primary — Deep Teal/Emerald

Inspired by turquoise and teal tiles found in Islamic mosques and madrasas (Shah Mosque in Isfahan, Al-Aqsa dome interior). Communicates depth, wisdom, and calm.

| Token | Hex | Use |
|-------|-----|-----|
| Primary | `#0D7377` | Main actions, active states, primary buttons |
| Primary Light | `#14A3A8` | Hover states, lighter surfaces, focus rings |
| Primary Dark | `#095456` | Pressed states, dark mode primary |

#### Accent — Warm Gold/Amber (Aged/Antique)

Inspired by illuminated Quran manuscripts and gold leaf calligraphy. Signals achievement, milestones, and importance. Muted and sophisticated — not flashy.

| Token | Hex | Use |
|-------|-----|-----|
| Accent | `#C8963E` | Achievements, streaks, highlights, premium actions |
| Accent Light | `#E8B960` | Badges, celebration accents |
| Accent Dark | `#9A7230` | Dark mode accent |

#### Neutrals — Warm Grays

Warm grays (not cool/blue) — evoke aged paper and stone, tied to the "book" metaphor.

| Token | Hex | Use |
|-------|-----|-----|
| White | `#FAFAF8` | Light mode background (warm, like quality paper) |
| Gray 50 | `#F5F4F2` | Subtle background variation |
| Gray 100 | `#E8E6E3` | Borders, dividers (light mode) |
| Gray 200 | `#D4D1CC` | Disabled states (light mode) |
| Gray 300 | `#B8B4AE` | Placeholder text |
| Gray 400 | `#9C9790` | Secondary text (dark mode) |
| Gray 500 | `#7A756E` | Secondary text (light mode) |
| Gray 600 | `#5C5850` | Primary text (light secondary) |
| Gray 700 | `#3E3B35` | Borders (dark mode) |
| Gray 800 | `#2A2722` | Surface cards (dark mode) |
| Gray 900 | `#1A1815` | Dark mode background |
| Black | `#121110` | Deepest dark mode background |

#### Semantic Colors

Never used alone to convey meaning — always paired with an icon or text label (accessibility requirement).

| Token | Hex | Icon Pairing | Use |
|-------|-----|-------------|-----|
| Success | `#2D8659` | ✓ Checkmark | Goal met, activity completed |
| Warning | `#C4841D` | ⚠ Triangle | Streak at risk, approaching limit |
| Error | `#C43D3D` | ✕ Cross / ! Bang | Failed goal, validation error |
| Info | `#2D6B8A` | ℹ Circle-i | Tips, neutral information |

#### Theme Modes

**Light Mode (default):**

| Token | Hex |
|-------|-----|
| Background | `#FAFAF8` |
| Surface (cards) | `#FFFFFF` |
| Text Primary | `#1A1815` |
| Text Secondary | `#5C5850` |
| Border | `#E8E6E3` |

**Dark Mode:**

| Token | Hex |
|-------|-----|
| Background | `#121110` |
| Surface (cards) | `#1A1815` |
| Text Primary | `#F5F4F2` |
| Text Secondary | `#9C9790` |
| Border | `#3E3B35` |

**System Auto:** Follows device light/dark setting.

**High Contrast Mode:**
- All text meets WCAG AAA (7:1 contrast ratio minimum)
- Borders become more prominent (2px, higher contrast color)
- Semantic colors shift to higher saturation/contrast versions
- Activated via system accessibility settings, not an in-app toggle

### 3.2 Typography

#### Font Families

| Role | Font | Why |
|------|------|-----|
| Headings / Display | **DM Serif Display** | Elegant modern serif, distinctive, pairs well with sans-serif. Evokes the "book" metaphor |
| Body / UI | **Inter** | Gold standard for UI readability, excellent variable font, first-class Flutter support |
| Mono / Data | **JetBrains Mono** | Best readability for numbers, stats, streaks, timers at small sizes |
| Arabic text | **Amiri** | Traditional Naskh-style, beautiful for Quranic phrases and Arabic labels in faith-based features |

#### Type Scale (Major Third — 1.250 ratio)

| Token | Size | Weight | Font | Use |
|-------|------|--------|------|-----|
| Display | 32px | Bold (700) | DM Serif Display | Screen titles, big streak numbers |
| H1 | 26px | Semibold (600) | DM Serif Display | Section headers |
| H2 | 21px | Semibold (600) | DM Serif Display | Sub-section headers |
| H3 | 17px | Medium (500) | Inter | Card titles, list headers |
| Body Large | 17px | Regular (400) | Inter | Primary body text |
| Body | 15px | Regular (400) | Inter | Standard body text |
| Body Small | 13px | Regular (400) | Inter | Secondary info, captions |
| Caption | 11px | Medium (500) | Inter | Labels, timestamps, badges |

#### Dynamic Text

All sizes scale with system dynamic text settings (iOS Dynamic Type, Android font scale). Layouts must reflow gracefully — no fixed-height containers that clip text. Minimum readable size: 11px at 1x scale.

### 3.3 Spacing Scale

Based on a 4px base unit. Used consistently for padding, margins, and gaps.

| Token | Value | Use |
|-------|-------|-----|
| xs | 4px | Tight gaps (icon-to-label, inline elements) |
| sm | 8px | Related elements within a group |
| md | 12px | Default padding inside components |
| lg | 16px | Between components, standard content padding |
| xl | 24px | Between sections |
| 2xl | 32px | Major section breaks |
| 3xl | 48px | Screen-level padding, hero spacing |

### 3.4 Border Radii

| Token | Value | Use |
|-------|-------|-----|
| none | 0px | Hard edges (dividers, horizontal rules) |
| sm | 6px | Small components (chips, badges, tags) |
| md | 12px | Cards, inputs, buttons |
| lg | 16px | Modal sheets, larger cards |
| xl | 24px | Bottom sheets, floating panels |
| full | 999px | Circular (avatars, FAB, dot indicators) |

12px card radius is the signature — modern but grounded, not bubbly/generic.

### 3.5 Shadows & Elevation

Warm-toned shadows (using neutral-warm rgba, not cool/blue).

| Level | Value | Use |
|-------|-------|-----|
| Level 0 | None | Flat elements, inline content |
| Level 1 | `0 1px 3px rgba(26,24,21,0.08)` | Cards, subtle lift |
| Level 2 | `0 4px 12px rgba(26,24,21,0.12)` | Dropdowns, hover cards |
| Level 3 | `0 8px 24px rgba(26,24,21,0.16)` | Modals, floating action buttons |

In dark mode, shadows are replaced with subtle light borders (shadows are invisible on dark backgrounds).

### 3.6 Islamic Geometric Patterns

Used as **subtle structural textures** — felt more than seen.

**Opacity levels:**
- Background texture: 5–10% opacity (watermark-level)
- Section dividers: 15–20% opacity
- Achievement / celebration moments: 30–40% opacity (briefly, animated)

**Pattern style:** Tessellations and arabesques — interlocking stars, hexagons, and interlaced geometric shapes. Represent the interconnectedness of habits and growth.

**Where they appear:**
- Home screen header background texture
- Section dividers between major content blocks
- Empty state illustrations (woven into background)
- Achievement badges and milestone cards
- Loading / splash screen
- Onboarding flow backgrounds

**Where they do NOT appear:**
- Inside cards or interactive elements (too noisy)
- As borders or outlines (competes with content)
- On data-heavy screens like insights (distracting)

### 3.7 Iconography

**Source:** Phosphor Icons (MIT licensed)
- Broadest library, outlined + filled variant system
- Visual weight matches Inter body text

**States:**
- Outlined (1.5px stroke) = default / inactive
- Filled = selected / active

**Sizes:**
| Token | Size | Use |
|-------|------|-----|
| sm | 20px | Compact UI, inline with small text |
| md | 24px | Standard (buttons, list items, nav) |
| lg | 28px | Prominent actions, empty states |

**Custom icons** (designed to match Phosphor style):
- Kitab book logo
- Streak fire
- Geometric pattern elements for achievements

### 3.8 Animation & Motion

**Durations:**
| Type | Duration | Use |
|------|----------|-----|
| Micro | 200ms | Tap feedback, toggle, checkbox |
| Transition | 300ms | Page transitions, tab switches |
| Reveal | 400ms | Bottom sheets, modals, dropdowns |
| Celebration | 800ms | Streak milestones, achievements |

**Easing curves:**
- Entrance: ease-out (fast start, gentle settle)
- Exit: ease-in (gentle start, fast disappear)
- Movement: ease-in-out (smooth repositioning)

**Haptic feedback (native only):**
| Event | Haptic |
|-------|--------|
| Toggle / check complete | Light impact |
| Streak milestone reached | Medium impact |
| Goal achieved | Medium impact |
| Error / validation failure | Light notification (error pattern) |
| Navigation | None |
| Scrolling | None |

**Streak celebrations:**
- Subtle gold-colored shimmer/particle animation on milestone streaks (7, 30, 100 days, etc.)
- Brief (< 1 second)
- Accompanied by medium haptic

**Reduced motion:**
- All animations respect the system "Reduce Motion" accessibility setting
- Crossfade replaces slide transitions
- No particle effects
- Haptics are unaffected (separate accessibility control)

---

## 4. Component Library

All reusable UI building blocks. Screen-by-screen specs (Section 6) reference these components by name.

### 4.1 Navigation

#### Bottom Navigation Bar (phone < 600px)

- **Tabs:** Home, Book, Insights, Social, Profile
- **Icons:** Phosphor — outlined (inactive), filled (active)
- **Colors:** Active tab = Primary, inactive = Gray 400, label always visible
- **Badge:** Notification dot on Social tab (unread friend requests, competition updates)
- **Position:** Fixed (not floating). Content stops above the nav bar — nothing scrolls behind it. Solid background (theme surface color) with subtle top border (Gray 100 light mode, Gray 700 dark mode).
- **Why fixed:** Avoids visual noise on data-dense screens, prevents overlap confusion with the FAB, better accessibility with solid background, minimal screen cost on modern tall-aspect phones.
- **Behavior:** Respects safe area / system gesture bars.

#### Side Navigation Rail (tablet 600–1024px)

- Collapsed by default: icons only, 56px wide
- Tooltip on hover shows label
- Same 5 sections as bottom nav

#### Side Navigation Rail (desktop > 1024px)

- Icon-only rail, 56px wide (same as tablet — consistent across non-phone viewports)
- Tooltip on hover shows section label
- Active section highlighted with Primary tint background
- No expanded/collapsed toggle — always icon-only to maximize content space

#### Top App Bar

- Screen title: DM Serif Display, H1
- Left: optional back arrow
- Right: optional action icons (max 2, overflow to "more" menu)
- Phone: scrolls away on long content (returns on scroll-up)
- Tablet/desktop: stays fixed

### 4.2 Buttons

#### Primary Button

- Background: Primary, text: white
- Min height: 48px, padding: lg (16px) horizontal, md (12px) vertical
- Border radius: md (12px)
- States: default, hover (Primary Light bg), focused (focus ring), pressed (Primary Dark bg), disabled (Gray 200 bg, Gray 400 text), loading (spinner replaces text)
- Full-width on phone, auto-width on tablet/desktop

#### Secondary Button

- Background: transparent, border: 1.5px Primary, text: Primary
- Same dimensions and states as Primary (hover fills with Primary at 10% opacity)

#### Tertiary / Text Button

- No background or border, text: Primary
- Used for less prominent actions (Cancel, Skip, See All)
- Hover: underline

#### Icon Button

- **Ghost:** No background, icon: Gray 600 (default), Primary (hover)
- **Contained:** Gray 50 background, icon: Gray 600. Hover: Gray 100 background
- Size: 44×44px minimum touch target
- Border radius: md (12px) for square, full for circular

#### Floating Action Button (FAB)

- Background: Primary, icon: white, "+" icon
- Size: 56×56px, border radius: full
- Elevation: Level 3
- Position: bottom-right, 16px from edges, above bottom nav
- **Visible on every screen** (global quick-log action)
- Tap opens quick-log bottom sheet
- Phone: circular FAB. Tablet/desktop: extended FAB with label ("Log Activity")

### 4.3 Input Components

#### Text Input

- Label above (Body Small, Medium weight, Gray 600)
- Placeholder inside (Gray 300)
- Border: 1.5px Gray 200, radius: md (12px)
- Height: 48px (single line), flexible (multiline)
- States: empty, focused (Primary border + light Primary bg tint), filled (Gray 700 border), error (Error border + error message below in Body Small), disabled (Gray 100 bg)
- Optional: prefix icon (left), suffix icon (right), character count (bottom right)

#### Number Input

- Same styling as text input
- Numeric keyboard on mobile
- Optional stepper buttons (+/−) on right side
- Supports integer and float based on activity metric configuration

#### Date/Time Picker

- Displays as a text input showing formatted date/time
- Tap opens native platform picker (iOS wheels, Android calendar/clock)
- Web: HTML5 date/time input with custom styling

#### Duration Picker

- Quick-select chips row: 15m, 30m, 1h, 2h, Custom
- Custom opens hours:minutes:seconds wheel picker
- Chips use Secondary Button styling, selected chip uses Primary Button styling

#### Star Rating Input

- 5 stars in a row, half-star intervals
- Empty: Gray 200 outline. Filled: Accent gold
- Tap interaction: left half of star = half star, right half = full star
- Clear/reset button (small X) appears after selection
- Accessible: screen reader announces "3.5 out of 5 stars", controllable via +/− stepper alternative

#### Boolean Toggle

- Switch: 48px wide, 28px tall
- On: Primary color track + white thumb. Off: Gray 200 track + white thumb
- Label always adjacent (never rely on toggle alone for meaning)
- Light haptic on toggle (native)

#### Single Select Dropdown

- Displays as text input with chevron-down suffix icon
- Tap opens: bottom sheet (phone), dropdown menu (tablet/desktop)
- Items show radio buttons, selected item gets checkmark
- Search/filter field appears if list > 7 items
- Selected value displays in the input field

#### Multi Select

- Same trigger as single select but with checkboxes per item
- Selected items shown as removable chips below the input field
- Chip: Body Small text, Gray 100 bg, sm radius, X icon to remove

#### Range Slider

- Track: Gray 200 (unfilled), Primary (filled)
- Thumb: 24px circle, white with Level 2 shadow
- Min/max labels at ends (Caption text)
- Current value displayed above thumb while dragging
- Snap-to-increment option based on configuration

#### Location Picker

- "Use current location" button with GPS/crosshair icon (Primary text button)
- Text input below for manual search entry
- After selection: shows place name + mini static map thumbnail (optional, text-only fallback)
- Stores coordinates in database, displays human-readable name in UI

#### Item List Input

- Text input with "Add" button (icon button, +) on right
- Added items appear as removable chips below, ordered vertically
- Drag handle for reorder (native), up/down buttons (web)
- Maximum items configurable per use case

#### Search Bar

- Rounded: radius xl (24px)
- Search icon (Phosphor MagnifyingGlass) prefix
- Clear button (X) appears when text entered
- Phone: can collapse to icon-only, expands on tap
- Height: 44px

#### KitabDateTimePicker

A custom-built date/time/timezone component used consistently across the entire app. Not a native picker — custom-built to match the Kitab design system and provide consistent cross-platform behavior.

**Display format (all three components always visible):**
```
Apr 2, 2026 · 8:00 AM · EDT
```

Three segments separated by dots. When editable, each segment is independently tappable to edit just that component. When read-only, rendered as plain text.

**Date segment — tapping opens:**
- Bottom sheet with a calendar month grid
- Swipe between months
- Tap a day to select
- If Hijri calendar is enabled in Settings, a toggle at the top switches between Gregorian and Hijri calendar views
- Border radius: lg (16px) on the bottom sheet

**Time segment — tapping opens:**
- Scroll wheel picker (bottom sheet)
- 12-hour mode: hours (1-12), minutes (00-59), AM/PM columns
- 24-hour mode: hours (00-23), minutes (00-59) columns
- Smooth scroll with haptic snaps on each value (native)
- Mode determined by user's time format setting

**Timezone segment — tapping opens:**
- Searchable list (bottom sheet)
- Sorted by UTC offset (UTC-12:00 at top → UTC+14:00 at bottom)
- User's current timezone (or last known if location is off) is pre-selected and pinned at the top of the list
- Search by city name (e.g., "Dubai") or timezone abbreviation (e.g., "GST")
- Each row shows: city/region name, abbreviation, and UTC offset
- Recently used timezones appear in a "Recent" section above the full list

**Formatting options (configured in Settings):**

| Setting | Options |
|---------|---------|
| Date format | MM/DD/YYYY, DD/MM/YYYY, YYYY-MM-DD, Written short (Apr 2, 2026), Written long (2 April 2026) |
| Time format | 12-hour (8:00 AM), 24-hour (20:00) |
| Timezone display | Abbreviation (EDT), UTC offset (-05:00) |

Timezone is **always shown** — there is no option to hide it.

**Default timezone:** Auto-detected from the device. If location services are off, the last known timezone is used. Users can manually override in Settings.

**Storage:** All date/times are stored as UTC in the database. The picker handles conversion: display = UTC → user's timezone; save = user's input → UTC.

**Where this component appears:**

| Location | Components Shown | Editable |
|----------|-----------------|----------|
| Entry form — Start Time | Date + Time + TZ | Yes |
| Entry form — End Time | Date + Time + TZ | Yes |
| Entry form — logged_at | Date + Time + TZ | Yes |
| Entry form — timer "Started at" | Date + Time + TZ | Yes |
| Timer segment start/end | Time + TZ | Yes |
| Activity template — Schedule start date | Date only + TZ | Yes |
| Activity template — Schedule end date | Date only + TZ | Yes |
| Condition — start date | Date only | Yes |
| Condition — end date | Date only | Yes |
| Book timeline — entry cards | Date + Time | No |
| Book timeline — day separators | Date only | No |
| Home screen — greeting card (Gregorian) | Date only | No |
| Home screen — greeting card (Hijri) | Date only (Hijri format) | No |
| Needs Attention — expected period | Date + Time (if windowed) | No |
| Period link display in entry detail | Date + Time + TZ | No |

### 4.4 Data Display Components

#### Activity Card

- **Layout:** Icon (colored circle, 40px) + name + status + streak badge
- **Status indicators:** Dedicated checkbox for boolean goals (not tap-to-complete on the card itself to avoid accidental completions). Checkbox: 28px, rounded square, Primary fill + white checkmark when complete. Tap triggers light haptic.
- **Variants:**
  - Compact (list item): single row, 64px height, used in activity lists
  - Expanded (card): shows metric preview values, used on Home screen
- **Tap behavior:** Opens activity detail (tap anywhere except the checkbox)
- **Elevation:** Level 1
- **Border radius:** md (12px)

#### Streak Badge

- Inline badge: fire icon (Phosphor Fire) + number + unit
- Active streak: Accent gold color, filled fire icon
- Broken/no streak: Gray 400, outlined fire icon
- Sizes: small (Caption text, 16px icon) for inline, large (H3 text, 24px icon) for detail views
- Long-press / tooltip shows best-ever streak

#### Metric Value Display

Adapts rendering based on metric type:

| Metric Type | Display |
|-------------|---------|
| Number | Large text (H2) + unit label (Caption) |
| Star rating | Filled/empty star icons (Accent gold) |
| Boolean | Checkmark (Success) or X (Gray 400) icon |
| Duration | Formatted "Xh Xm Xs" |
| Text | Body text, truncated with "..." if long |
| Location | Place name (Body), coordinates (Caption) |
| Date/time | Formatted date/time string |
| Select | Chip with selected value |
| Multi select | Row of chips |
| Range | Value + progress bar showing position in range |
| Item list | Bulleted list or chip row |

#### Progress Ring / Arc

- Circular: 64px (compact) or 96px (large)
- Track: Gray 100, fill: Primary
- Center: fraction text ("3/5") or percentage
- Animated fill on load (300ms, ease-out)
- Used for: weekly goal progress, competition standings

#### Heat Map Calendar

- Grid of day squares (like GitHub contributions graph)
- Color: Primary at varying opacities — 0% (empty), 10%, 25%, 50%, 75%, 100%
- Scrollable by month
- Tap a day → tooltip/bottom sheet showing that day's entries
- Today highlighted with border ring

#### Stat Tile

- Small card: ~160px wide (fits 2 per row on phone)
- Content: label (Caption), large value (H2 or Display), trend indicator
- Trend: ↑ arrow (Success green) for positive, ↓ arrow (Error red) for negative, → (Gray 400) for flat
- Elevation: Level 1, radius: md (12px)
- Used in: Insights dashboard, activity detail stats section

#### Leaderboard Row

- Layout: rank # (H3) + avatar (32px circle) + name (Body) + metric value (H3, right-aligned)
- Top 3 ranks: gold (#1), silver (#2), bronze (#3) accent on rank number
- Current user's row: Primary tint background (10% opacity) + "You" label
- Divider between rows (Gray 100)

#### Empty State

- Centered layout: geometric pattern illustration (40% opacity), headline (H2), description (Body, Gray 500), CTA primary button
- Tone: always encouraging ("Your Kitab awaits its first page. Start by creating an activity.")
- Unique illustration per context (no activities, no friends, no competitions, no insights yet)

#### Loading State (Skeleton)

- Skeleton shapes match the layout of content being loaded
- Gray 100 rectangles with shimmer animation (left-to-right gradient sweep)
- Duration: 1.5s loop until content loads
- No spinners for content areas (spinners only for button loading states)

#### Error State

- Layout: Error icon (48px, Error color), headline (H2), description (Body, Gray 500), retry button (Primary)
- Tone: helpful, not technical ("Something went wrong. Tap to try again.")
- For network errors: includes "You're offline" variant with different messaging

### 4.5 Feedback Components

#### Toast / Snackbar

- Position: bottom center, 16px above bottom nav (phone), bottom-right (tablet/desktop)
- Auto-dismiss: 4 seconds
- Background: Gray 800 (light mode), Gray 100 (dark mode)
- Text: white (light mode), Gray 900 (dark mode)
- Optional action link (e.g., "Undo") on right
- Semantic variants: success (Success tint bg), error (Error tint bg)
- Max 1 toast visible at a time (new replaces old)

#### Bottom Sheet

- **Phone:** slides up from bottom, drag handle (32px wide, 4px tall, Gray 300) at top, background dims (50% opacity)
- **Tablet/desktop:** renders as centered modal dialog instead
- Border radius: xl (24px) on top corners only
- Can be: partial height (content-sized), half-screen, or full-screen
- Swipe down to dismiss (phone), click backdrop or X button (tablet/desktop)

#### Modal Dialog

- Centered, max-width 400px
- Backdrop: dim overlay (50% opacity)
- Border radius: lg (16px)
- Content: title (H2), body text, action buttons (right-aligned: secondary + primary)
- Used for: destructive confirmations (delete, leave, sign out), important choices
- Always has a clear cancel/dismiss action — never forced single-action

#### Alert Banner

- Full-width strip at top of screen content (below app bar)
- Background: semantic tint color (info blue, warning amber)
- Icon + text + optional dismiss X
- Persistent banners: offline mode, sync in progress
- Dismissible banners: tips, one-time notices

### 4.6 Social Components

#### Friend Row

- Layout: avatar (40px circle) + name (Body) + shared count (Caption, Gray 500)
- Right side: chevron for navigation to friend detail
- Swipe actions (phone): remove friend (destructive, Error bg)
- Variants: friend row, friend request row (with Accept/Decline buttons)

#### Competition Card

- Layout: competition name (H3) + participant count (Caption) + status chip + mini leaderboard
- Status chip: "Active" (Success bg), "Upcoming" (Info bg), "Completed" (Gray 200 bg)
- Mini leaderboard: top 3 as small avatar row with rank numbers
- Tap opens full competition detail
- Elevation: Level 1, radius: md (12px)

#### Sharing Toggle Row

- Layout: activity icon + name (Body) on left
- Right: sharing status text ("Private" / "3 friends" / "All friends") + chevron
- Tap opens friend selector bottom sheet with checkboxes
- Default state: "Private" (Gray 500 text)

### 4.7 Layout Components

#### Screen Scaffold

- Standard screen wrapper providing: top app bar + scrollable content area + optional FAB
- Handles: safe areas (notch, home indicator), keyboard avoidance, scroll-to-top on tab re-tap
- Background: theme background color

#### Section Header

- Title: H2 (DM Serif Display)
- Optional right-side action: "See all" text button
- Optional geometric divider line below (15% opacity, 1px)
- Margin: xl (24px) top, lg (16px) bottom

#### Responsive Grid

- Adapts columns by breakpoint:
  - Phone (< 600px): 1 column, lg (16px) horizontal padding
  - Tablet (600–1024px): 2 columns, xl (24px) gap
  - Desktop (> 1024px): 2–3 columns, xl gap, max-width 1200px centered
- Used for: stat tiles, activity cards, settings groups

#### Pull to Refresh (native only)

- Custom indicator: Primary color circular progress
- Triggers data sync from Supabase
- Web: no pull-to-refresh (standard browser behavior)

#### Adaptive Layout Wrapper

- Detects screen width and renders appropriate variant
- Breakpoints: phone (< 600px), tablet (600–1024px), desktop (> 1024px)
- Components can register phone/tablet/desktop variants
- Also detects platform (native vs web) for feature gating

---

## 5. Activity Template Specification

The activity template is the foundational data structure of Kitab. Every entry, goal, streak, condition reason, competition, and insight is built upon how activities are configured.

### 5.1 Terminology

| Internal / Technical Term | User-Facing Name | Context |
|--------------------------|-----------------|---------|
| Activity Template / Configuration | **Activity** | "Create an Activity" — the template IS the activity |
| Activity Log / Entry / Record | **Entry** | "Log an Entry" — you write entries in your book |
| Ad-hoc log (no template) | **Quick Entry** | Unlinked freeform entry |
| Category | **Category** | Grouping with shared icon and color |
| Metric | **Field** | "Add a Field" — what data to capture per entry |
| Goal | **Goal** | Target to achieve |
| Schedule frequency period | Not exposed | Referred to contextually: "today," "this week," etc. |
| Streak | **Streak** | Consecutive goal successes |
| Condition | **Condition** | Life event marker (illness, travel, etc.) |
| Excuse / linking missed activity to condition | **Reason** | "Mark as missed with a reason" — non-judgmental |
| Metric scope | **Look at** | "Look at: most recent entry / last 7 days" |
| Metric aggregation | **Calculate** | "Calculate the: sum / average / highest" |
| Consistency threshold | **Consistency** | "Meet this goal X times out of last Y periods" |
| Group goal | **Combined Goal** | Multiple targets evaluated together |
| Simple goal mode | **Quick Setup** | Basic sentence-builder goal |
| Advanced goal mode | **Custom Goal** | Full formula builder |

### 5.2 Identity

| Property | Required | Description |
|----------|----------|-------------|
| Activity Name | Yes | Freeform text. Must be unique within user's activities. |
| Category | Yes | Select from user-created categories or create a new one inline. The category provides the **icon and color** — there is no separate icon or color per activity. All activities in a category share the same visual identity. |
| Description | No | Optional freeform text explaining what this activity is. |

**Categories:**
- User-created or selected from presets (Health & Fitness, Spiritual, Learning, Work, Social, Personal, etc.)
- Each category has: name, icon (emoji), color (from a preset palette)
- Creating a new category inline during activity setup: user provides name, picks icon and color
- Categories are managed in Settings (rename, reorder, change icon/color, delete — with warning if activities exist)

### 5.3 Schedule

Toggle on/off (default off). When off, the activity has no expected frequency — the user logs entries whenever they want.

When toggled on, the following fields appear:

#### Calendar

| Property | Required | Default | Description |
|----------|----------|---------|-------------|
| Calendar | Yes | Gregorian | **Gregorian** — day starts at midnight. **Hijri** — day starts at sunset. Only available if Hijri is enabled in Settings. Determines how frequency periods are calculated and which calendar the start/end dates use. |

#### Date Range

| Property | Required | Default | Description |
|----------|----------|---------|-------------|
| Starts on | Yes | Today | The date the schedule begins. Uses the selected calendar type. |
| Ends on | No | Never | When the schedule ends. Null = runs indefinitely. A **✕ clear button** appears once a date is set, allowing the user to reset back to "Never" without restarting the form. |

#### Repeat Frequency

| Property | Required | Default | Description |
|----------|----------|---------|-------------|
| Repeat | Yes | Daily | How often this activity is expected. |

**Repeat options:**
- **Daily** — every day
- **Weekly** — specific days of the week (checkboxes: Mon–Sun) or entire week. Week start day is determined by the user's global setting in Settings.
- **Monthly** — specific days of the month (1–28/29/30/31) or entire month. Multiple days can be selected. If all selected days are consecutive, the app asks whether to treat them as **one period** (assessed together) or **separate periods** (assessed individually). Non-consecutive days are always separate periods. If a selected day doesn't exist in a given month (e.g., day 31 in a 30-day month, or day 30 in a 29-day Hijri month), the period defaults to the **last day of that month** instead of being skipped. An info note is shown during setup: "If a selected day doesn't exist in a month, the last day of the month is used instead."
- **Custom Interval** — every X days, every X weeks, every X months, every X years. Each recurrence spans a **single day** (the day that falls on the interval, computed from the start date). If a time window is set, the period is that window within the single day.

#### Expected Entries

| Property | Required | Default | Description |
|----------|----------|---------|-------------|
| Expected entries | Yes | Once | **Once** per period — the auto-linking engine links at most 1 entry per period. **Multiple** per period — the engine can link as many entries as exist. This does NOT ask the user for a specific count. |

#### Time Window

| Property | Required | Default | Description |
|----------|----------|---------|-------------|
| Time Window | No | Off | Toggle on/off. When on, the user defines a specific time window for this activity within each period. |
| Time Type | Yes (if window on) | Specific | **Specific** — fixed clock times (e.g., 8:00 AM – 9:00 AM). **Dynamic** — tied to prayer/astronomical times. Both start and end must be the same type (no mixing). |
| Window Start | Yes (if window on) | — | The start of the expected time window. |
| Window End | Yes (if window on) | — | The end of the expected time window. |

**Dynamic time options** (availability depends on settings):

| Option | Requires Islamic Personalization | Requires Location Services |
|--------|--------------------------------|---------------------------|
| Fajr | Yes | Yes |
| Sunrise | No | Yes |
| Duha | Yes | Yes |
| Dhuhr | Yes | Yes |
| Asr | Yes | Yes |
| Maghrib / Sunset | No (shown as "Sunset") | Yes |
| Isha | Yes | Yes |
| 1/3 of Night | Yes | Yes |
| Middle of Night | Yes | Yes |
| 2/3 of Night | Yes | Yes |

**Night calculations:** "Night" = sunset to sunrise the next day. 1/3 of Night = the point when one-third of the night has passed. Middle of Night = the midpoint. 2/3 of Night = two-thirds passed. These are standard Islamic jurisprudence calculations used for Isha timing and Tahajjud.

**Dynamic time preview:**
- As soon as either a start or end dynamic time is selected, show today's computed time for that selection immediately (e.g., "Today: 5:12 AM"). Do not wait until both are selected.
- Once both are selected, both computed times are shown side by side.

**Time window edge cases (applies to BOTH Specific and Dynamic times):**
- If end time ≤ start time, this implies a midnight crossover. The UI must show a clear warning: "This time window crosses midnight — the activity is expected from [start] today to [end] tomorrow. Is this correct?" Do not silently assume intent.
- For dynamic times, the warning uses the prayer time names: "This crosses midnight — expected from Isha today to Fajr tomorrow. Is this correct?"
- If location services are off AND Islamic personalization is off, no dynamic times are available — only specific times.
- If location services are off but Islamic personalization is on, no dynamic times are available (they require location to calculate).

#### Frequency Period Computation

Frequency periods are **computed on-the-fly, never stored in the database.** Reasons:
1. Open-ended schedules (no end date) would create infinite rows
2. Dynamic time windows depend on the user's current location and timezone, which changes with travel
3. A user in New York who travels to Dubai should have their Fajr window adapt to Dubai's prayer times

A frequency period always has a computed start datetime and end datetime:
- **No time window:** period spans the full day (midnight-to-midnight for Gregorian, sunset-to-sunset for Hijri)
- **With time window:** period spans the specified window within each scheduled day
- All datetimes are computed in the user's current timezone and stored/compared as UTC

**Week start day:** Determined by the user's global setting in Settings (default: Sunday). Applies to all weekly-frequency activities — not configurable per activity.

### 5.4 Fields (Metrics)

At least 1 field must be added to the template. Maximum 20 fields per activity. No fields are required to fill in during entry logging — all are optional at entry time to minimize friction.

All fields have: **type**, **label**, **value** (captured at log time), and optional **unit**. Labels must be unique within a template.

Fields appear in the entry form in the order configured in the template. Users can reorder fields in both the template and the entry form via drag handles.

Every entry also has a default **Notes** field (freeform text) that is not part of the template configuration — it appears automatically on every entry form. No custom field can use the label "Note" or "Notes" (reserved).

#### Preset Fields

These have fixed labels that cannot be renamed.

**Start Time**
- Type: Date/time (stored as UTC, displayed in user's local timezone)
- Label: "Start Time" (fixed)
- Unit: None

**End Time**
- Type: Date/time (stored as UTC, displayed in user's local timezone)
- Label: "End Time" (fixed)
- Unit: None

**Duration**
- Type: Time (HH:MM:SS format)
- Label: "Duration" (fixed)
- Unit: None
- **Auto-calculation rules:**
  - If both Start Time and End Time are captured → Duration is auto-calculated, non-editable
  - If Start Time + Duration captured (no End Time field) → End Time is auto-calculated
  - If End Time + Duration captured (no Start Time field) → Start Time is auto-calculated
  - If neither Start Time nor End Time fields exist → Duration is freely editable by the user
  - Duration always adjusts when Start or End Time is edited — user cannot directly edit Duration when it's auto-calculated

#### Custom Fields

| UI Type Name | Technical Type | Label | Unit | Additional Configuration |
|-------------|---------------|-------|------|------------------------|
| **Number** | Float | Required (user-defined) | Optional (locked once set in template — cannot be edited per entry) | None |
| **Text** | String (multiline) | Required (user-defined, cannot be "Note" or "Notes") | None | System-enforced max character limit (5,000 characters) |
| **Star Rating** | Float (0–5) | "Star Rating" (fixed) | None | Displayed as 5 stars with half-star intervals. Interaction: tap star = full, tap again = half, tap third time = clear all. Stored as float (0, 0.5, 1.0, ... 5.0). |
| **Yes / No** | Boolean | Required (user-defined) | None | Displayed as two buttons: "Yes" and "No" |
| **Single Choice** | String or Number | Required (user-defined) | None | User defines list of options. Optionally mark as **ordinal** (ordered from highest to lowest) — enables >, ≥, <, ≤ comparisons in goals. Options can be strings or numbers. |
| **Multiple Choice** | Array of String or Number | Required (user-defined) | None | Same as Single Choice but user can select multiple. **Cannot be ordinal** (multiple selections make ordering comparisons meaningless). |
| **Range** | Float | Required (user-defined) | Optional (locked once set) | User defines **min**, **max**, and optional **step** (default: 1). Entry form shows a number input + slider. Value must be within min–max bounds. |
| **Location** | Coordinates (lat/lng) | Required (user-defined) | None | Entry form offers: use current GPS location, pin on map, or search address/place name. Users can save favorite locations in Settings for quick access. Uses free cross-platform mapping (flutter_map + OpenStreetMap). |
| **List** | Array of Strings | Required (user-defined) | None | User adds items one by one in the entry form. Items are ordered. Drag to reorder. |
| **Mood** | Integer (1–5) | "Mood" (fixed) | None | Displayed as 5 emoji faces with labels: 😢 Very Bad (1), 😟 Bad (2), 😐 Neutral (3), 😊 Good (4), 😄 Great (5). Labels always visible next to emojis. Tap to select, tap same to deselect. Only one selectable. Fixed emojis and labels (not customizable). Stored as integer 1–5. In goals and insights, values are displayed as labels ("≥ Good") not numbers ("≥ 4"). Goal-compatible with numeric comparisons (≥, ≤, >, <, =). High insights value for cross-activity correlations. |

### 5.5 Goals

Toggle on/off (default off). When toggled on, at least 1 goal is required. Only fields configured above are available for goal configuration.

**Schedule + Goals relationship:**
- Schedule requires goals. If the user enables a schedule but adds no explicit goals, the system auto-creates an implicit Yes/No goal: "Did at least one entry get logged in this period?" This is the fundamental habit goal.
- Goals do not require a schedule. A user can have goals without any frequency (e.g., "I want my average weight to be below 80 kg" — assessed against all entries ever).

#### Quick Setup Mode (Default)

A sentence-builder that covers ~80% of goal use cases. The sentence structure adapts based on whether a schedule is set.

**With Schedule — Frequency goals:**
> "I want to do this activity [at least ▾] [3] times per [week]"

The period ("per week") is **locked to match the schedule's repeat frequency** — not a separate dropdown. The comparison ("at least") is a dropdown with options: at least (≥), at most (≤), more than (>), less than (<), exactly (=), between, not between.

**With Schedule — Value goals:**
> "I want the [distance ▾] to be [at least ▾] [5] [km] per [day]"

The field dropdown shows only numeric-compatible fields (Number, Range, Duration). The unit auto-fills from the field's configured unit. The period is locked to the schedule.

**When "between" is selected:**
> "I want the [distance ▾] to be [between ▾] [3] and [5] [km] per [day]"

A second value input appears for the upper bound.

**Without Schedule — Value goals only (no frequency goals available):**
> "I want the [weight ▾] to be [at most ▾] [200] [lbs]"

No "per [period]" — the goal is a standing target assessed against the most recent entry or configured scope. Frequency goals are hidden because there is no schedule to define periods.

**Examples:**
- "I want to do this activity at least 3 times per week" (frequency, with schedule)
- "I want the distance to be at least 5 km per day" (value, with schedule)
- "I want the weight to be between 170 and 180 lbs" (value range, without schedule)
- "I want the pages read to be at least 10 pages per day" (value, with schedule)

Quick Setup translates internally to a Custom Goal with the appropriate scope, aggregation, comparison, and target — the user just doesn't see the complexity.

#### Custom Goal Mode (Advanced)

The full formula builder for power users. Each goal follows the structure: **X [comparison] Y** with an optional **Consistency** layer.

##### X — What You're Measuring ("Measure")

| Property | Options | Description |
|----------|---------|-------------|
| Field | Any configured field | Which field's values to evaluate |
| Look at | Most recent entry, All entries in current period, Last ___ entries, Last ___ days/weeks/months, All entries ever | Which entries to include. When "Last ___ entries" is selected, a number input labeled **"How many entries?"** appears. When "Last ___ days/weeks/months" is selected, a number input labeled **"How many?"** and a unit dropdown appear. Never use "N" in the UI — always use plain human language. |
| Calculate | (only if "Look at" is not "Most recent entry") Sum, Count, Min (Lowest), Max (Highest), Average, Mode | How to aggregate multiple entries into one value. UI labels use plain language: "Lowest" not "Min", "Highest" not "Max". |

##### Comparison ("Target Rule")

**Standard comparisons:** ≥, ≤, >, <, = (with optional tolerance, default 0), between (≥ X AND ≤ Y), not between (< X OR > Y)

When "between" or "not between" is selected, two target inputs appear (From and To). Internally, "between" is stored as two bounds in a single goal — not as a combined/group goal.

**User-facing comparison labels:**
- ≥ → "at least"
- ≤ → "at most"
- \> → "more than"
- < → "less than"
- = → "exactly"
- between → "between"
- not between → "not between"

**Type-specific comparisons:**

| Field Type | Available Comparisons |
|-----------|----------------------|
| Number, Range, Star Rating, Mood, Duration | ≥, ≤, >, <, =, between, not between (with tolerance). Mood comparisons use labels in UI ("≥ Good") but integers internally. |
| Start Time, End Time | ≥, ≤, >, <, =, between, not between (with tolerance in minutes) |
| Text | Contains, Does not contain (whole word matching) |
| Yes / No | = only |
| Single Choice (ordinal) | ≥, ≤, >, <, =, between, not between |
| Single Choice (non-ordinal) | = only |
| Multiple Choice | Contains, Does not contain |
| Location | At location, Not at location (with optional radius) |
| List | Contains item, Does not contain item |

##### Y — The Target

**Static target:** A user-defined value appropriate to the field type:
- Number/Range: a number
- Start Time/End Time: a specific time or dynamic time (see constraints below)
- Duration: HH:MM:SS value
- Text: a string
- Rating: 0–5 (float)
- Yes/No: Yes or No
- Single Choice: one of the configured options
- Multiple Choice: one or more of the configured options
- Location: a saved location, pinned location, or searched address
- List: an item string

**Dynamic target:** Another aggregation over historical entries (same scoping and calculation options as X). This allows relative goals like: "My most recent weight < my average weight over the last 7 days."

**Time-based target constraints (when schedule has a time window):**

| Schedule Time Type | Goal Target Constraints |
|-------------------|------------------------|
| No time window | Any specific time is valid as a target |
| Specific times (e.g., 8:00 AM – 9:00 AM) | Target must be a specific time within the window bounds |
| Dynamic times (e.g., Fajr – Sunrise) | Target must be relative to the window: "≤ window start + X minutes" or "≥ window end − X minutes". Cannot use specific clock times or different dynamic references. |

##### Consistency Layer (Optional)

Any goal can optionally have a consistency threshold that evaluates the goal's pass rate across multiple periods:

| Property | Description |
|----------|-------------|
| Enabled | On/off (default off) |
| Evaluate over | Last N periods |
| Threshold type | Count or Percentage |
| Threshold value | A number (count) or percentage |
| Success when | ≥ threshold (e.g., "met in at least 5 of the last 10 periods" or "met at least 50% of the time") |

**Example — Fajr consistency goal:**
```
Field: Start Time
Look at: Most recent entry per period
Comparison: ≤
Target: Window Start + 30 minutes (relative dynamic)

Consistency:
  Evaluate over: Last 10 periods
  Threshold: ≥ 5 periods (or ≥ 50%)
```

**Plain text summary:** "Goal is met when you start Fajr within 30 minutes of the Athan in at least 5 of the last 10 scheduled periods."

#### Combined Goals (Group Goals)

Multiple X-comparison-Y evaluations grouped together:
- Only one goal per standalone field
- A combined goal assesses across multiple fields
- Combination logic:
  - **All must be met** (AND) — every sub-goal must pass for the combined goal to succeed
  - **At least one must be met** (OR) — any sub-goal passing means the combined goal succeeds

#### Primary Goal

When an activity has multiple goals, the user designates one as the **primary goal.**

- If only one goal exists, it is automatically the primary
- The primary goal is what appears on the Home screen activity card (progress indicator, status icon)
- All other goals are visible in the entry detail screen and activity detail screen
- The user can change which goal is primary at any time from the activity template settings
- The primary goal designation is stored as a flag in the goals JSONB: `"is_primary": true`

### 5.6 Streak Rules

| Entry Status | Per-Activity Streak | All-Goals Day Streak | Icon |
|-------------|--------------------|--------------------|------|
| ✓ Completed / Goal Met | +1 | Day counts as met only if ALL expected activities are ✓ | 🔥 |
| ⊘ Excused (with reason) | No change (stays at current) | No change | 🔥 |
| ○ Upcoming (not yet due) | No effect | No effect | 🔥 |
| ? Pending (past due, unaddressed) | Frozen (no change, blocks advancement) | Frozen | 🧊 |
| — Missed (confirmed) | Reset to 0 | Reset to 0 | 🔥 |

**Key rules:**
- Streak only advances (+1) on confirmed completion
- Excuses preserve but do not advance the streak
- Pending freezes the streak (shown with 🧊 icon) — the streak is neither broken nor advanced until the user addresses the pending entry
- Any confirmed miss resets to 0
- No auto-conversion of pending to missed — pending remains frozen indefinitely until the user takes action
- All-goals day streak only advances on days where every expected activity was completed (✓). Days with any excuse, pending, or miss do not advance the all-goals streak. Days with all ✓ = +1. Days with any — = reset. Days with any ? = frozen. Days with mix of ✓ and ⊘ (no miss) = no change.

**Unscheduled goals (no schedule) have NO streaks:**
- Goals without a schedule are **standing targets** — they show a current status of met (✓) or not met (✕) based on the configured scope
- They do NOT participate in the streak system at all
- They do NOT affect the all-goals day streak
- If a user logs a value that doesn't meet an unscheduled goal, nothing resets — there's no streak to reset
- Only scheduled activities with goals contribute to streaks

### 5.7 Summary View

At the end of the activity template setup, the user is presented with a **plain-text summary** of their entire configuration. This helps users:
- Verify their setup is correct
- Catch configuration errors
- Understand what they've built in simple language

**Example summary:**
> "Morning Run is a daily Health & Fitness activity starting April 1, 2026 (Gregorian calendar). Each entry captures duration, distance (km), and completion status. Your goal is to run at least 5 km per day. Your streak counts consecutive days where this goal is met. Excused days (with a reason) preserve your streak without advancing it."

### 5.8 Template Setup UI Flow

```
CREATE AN ACTIVITY
─────────────────────────────

DETAILS
  Activity Name:  [________________________]
  Category:       [Health & Fitness      ▾]  [+ New]
  Description:    [________________________] (optional)

SCHEDULE                                      [off ○─]
  ┌───────────────────────────────────────────────────┐
  │ Calendar:     [Gregorian ▾]                       │
  │ Starts on:    [April 1, 2026]                     │
  │ Ends on:      [Never                   ▾]  [✕]    │
  │ Repeat:       [Daily ▾]                           │
  │ Expected:     ○ Once per day                      │
  │               ○ Multiple times per day            │
  │                                                   │
  │ Time Window                          [off ○─]     │
  │ ┌───────────────────────────────────────────────┐ │
  │ │ Time type:  ○ Specific  ○ Dynamic             │ │
  │ │ Start:      [________]                        │ │
  │ │ End:        [________]                        │ │
  │ └───────────────────────────────────────────────┘ │
  └───────────────────────────────────────────────────┘

FIELDS
  Add the data you want to capture for each entry.

  Preset:  [+ Start Time] [+ End Time] [+ Duration]
  Custom:  [+ Number] [+ Text] [+ Star Rating] [+ Mood]
           [+ Yes/No] [+ Single Choice] [+ Multiple Choice]
           [+ Range] [+ Location] [+ List]

  Added (drag to reorder):
  ┌───────────────────────────────────────────────────┐
  │ ≡  1. Duration            Duration (preset)       │
  │ ≡  2. Distance            Number  ·  Unit: km     │
  │ ≡  3. Completed?          Yes / No                │
  └───────────────────────────────────────────────────┘

GOALS                                         [off ○─]
  ┌───────────────────────────────────────────────────┐
  │                                                   │
  │  ○ Quick Setup                                    │
  │    With schedule:                                 │
  │    "I want the [distance ▾] to be [at least ▾]   │
  │     [5] [km] per [day]"  ← period locked          │
  │    Without schedule:                              │
  │    "I want the [weight ▾] to be [at most ▾]      │
  │     [200] [lbs]"  ← no period                     │
  │                                                   │
  │  ○ Custom Goal                                    │
  │    [Full formula builder...]                      │
  │                                                   │
  │  [+ Add another goal]                             │
  │                                                   │
  └───────────────────────────────────────────────────┘

SUMMARY
  ┌───────────────────────────────────────────────────┐
  │ "Morning Run is a daily Health & Fitness activity  │
  │  starting April 1, 2026. Each entry captures       │
  │  duration, distance (km), and completion status.   │
  │  Your goal is to run at least 5 km per day."       │
  └───────────────────────────────────────────────────┘

                                    [Cancel]  [Save]
```

**Tablet/Desktop adaptation:**
- Two-column layout: left column for configuration, right column shows a live preview of how the entry form will look with the configured fields
- The summary updates in real-time as the user makes changes

**Progressive disclosure:**
- Schedule section is collapsed by default (toggle off)
- Time Window is collapsed within Schedule (toggle off)
- Goals section is collapsed by default (toggle off)
- Custom Goal mode is behind a radio button (Quick Setup is default)
- Advanced options within Custom Goal (consistency, combined goals) are behind expandable sections

---

## 6. Routines

A routine is a sequence of activity templates grouped together for habit stacking. It allows users to execute a series of activities one after another with minimal friction — starting once and flowing through each step instead of logging each activity individually.

### 6.1 Core Concept

**A routine references existing activity templates.** It does not create new templates — it groups existing ones into an ordered sequence. Users must create activity templates first before adding them to a routine.

**A routine is an orchestration layer.** It coordinates entry creation across multiple activities but never collects its own data. All routine-level metrics (start time, end time, duration, idle time) are derived from the underlying activity entries.

**Relationship to activities:**
- A routine contains 2+ activity templates in a defined order
- The same activity template can appear in multiple routines
- An activity template can exist independently without being in any routine
- Completing an activity within a routine creates a real entry linked to that activity's template and period — identical to logging the activity standalone

### 6.2 Routine Configuration

Configured in **Settings → My Routines** (separate from My Activities). The user must create activity templates first.

#### Identity

| Property | Required | Description |
|----------|----------|-------------|
| Routine Name | Yes | Unique per user (case-insensitive) |
| Category | Yes | Select from user's categories (shares icon + color) |
| Description | No | Optional text |

#### Activity Sequence

An ordered list of activity templates that make up the routine:

```
┌─────────────────────────────────────┐
│ ☀️ Morning Routine                  │
│                                     │
│ Activities (drag ≡ to reorder):     │
│                                     │
│ ≡  1. Body Scale                    │
│ ≡  2. Shower                        │
│ ≡  3. Wudu                          │
│ ≡  4. Fajr Sunnah                   │
│ ≡  5. Fajr Prayer                   │
│ ≡  6. Post-Prayer Athkar            │
│ ≡  7. Read Quran                    │
│ ≡  8. Morning Athkar                │
│ ≡  9. Pray Duha                     │
│                                     │
│ [+ Add Activity]                    │
└─────────────────────────────────────┘
```

- "Add Activity" opens a searchable list of the user's activity templates
- Activities can be reordered via drag handles
- Activities can be removed (swipe left or ✕)
- Minimum 2 activities per routine
- An activity template can only appear once in a routine (no duplicates within the same routine)

#### Schedule (Optional)

Same structure as activity template schedules (§5.3):
- Toggle on/off (default off)
- Calendar type (Gregorian / Hijri)
- Start date, end date
- Repeat frequency (daily, weekly, monthly, custom interval)
- Expected entries (once / multiple per period)
- Time window (optional — specific or dynamic times)

A routine's schedule is **independent** from its underlying activities' schedules. "Morning Routine 6-8 AM" is a separate concept from each activity's own schedule.

#### Goals (Optional)

Toggle on/off (default off). Same rules as activity templates: if a schedule is set but no goals are defined, the system auto-creates an implicit "Did the routine get completed?" goal.

**Routine-level goal metrics are limited to:**

| Metric | Type | Description |
|--------|------|-------------|
| Routine start time | Time | When the first activity in the routine started |
| Routine end time | Time | When the last activity in the routine ended |
| Routine active duration | Duration | Sum of all activity durations (excludes idle time between activities) |
| Activities completed | Count or % | How many of the routine's activities were completed |

**The user cannot set goals on individual activity metrics within the routine** (e.g., "run at least 5 km in the routine"). Those goals belong to the individual activity template. Routine goals are about the routine as a whole.

**Quick Setup examples:**
- "I want to complete at least 7 of 9 activities per day"
- "I want to complete at least 80% of activities per day"
- "I want the routine active duration to be at most 90 minutes per day"
- "I want the routine start time to be at most 6:30 AM per day"

**Custom Goal** uses the same formula builder as activity templates (§5.5) but with only the 4 routine-level metrics available.

**Primary goal** designation works the same as activities — one goal is marked primary for Home screen display and streak.

#### Routine Period Status Rules

A routine's period status is derived from the statuses of its individual activities. Evaluated in this order:

| Priority | Status | Condition |
|----------|--------|-----------|
| 1 | **Pending** | At least one activity in the routine has a pending status. The routine cannot resolve until every activity is addressed. |
| 2 | **Partial** | All activities have a non-pending status, but they're not all the same status (mix of completed, excused, and/or missed). |
| 3 | **Excused** | All activities have an excused status (uniformly excused). |
| 4 | **Missed** | All activities have a missed status (uniformly missed). |
| 5 | **Completed** | All activities have a linked entry. No pending, no missed, no excused. Every activity was actually done. |

**'in_progress'** is a transient state — only while the user is actively in the routine flow screen. Once the routine session ends (user exits, ends routine, or all activities are addressed), it resolves to one of the 5 states above.

**Examples:**
- 5/5 completed → **Completed**
- 4 completed + 1 excused → **Partial**
- 3 completed + 2 missed → **Partial**
- 2 completed + 1 excused + 1 missed + 1 pending → **Pending**
- 5/5 excused → **Excused**
- 5/5 missed → **Missed**
- 0 addressed → **Pending**

#### Routine Streaks

The routine's streak is driven by its **primary goal evaluation**, not the period status directly. The goal engine evaluates the routine's data (completion count, timing, duration) against the goal targets.

| Routine Period Status | Streak Effect | Icon |
|----------------------|---------------|------|
| Completed | Depends on primary goal: met = +1, not met = reset | 🔥 or resets |
| Partial | Depends on primary goal: if goal allows partial (e.g., "3/5 activities"), could be met = +1 | 🔥 or resets |
| Excused | No change (preserved) | 🔥 |
| Missed | Reset to 0 | 🔥 |
| Pending | Frozen | 🧊 |

**Key distinction from activities:** An activity's streak is simpler (completed = +1). A routine's streak depends on its goals because "partial" is ambiguous — partial could mean the primary goal was met (e.g., "complete at least 3/5") or not met (e.g., "complete all 5"). The goal engine decides.

A routine's streak is independent from its individual activities' streaks. Completing activities within a routine advances both the routine's streak (via routine goals) and each completed activity's own streak (via activity goals).

**All-goals day streak:** Routines with daily schedules whose periods end before midnight participate in the all-goals day streak, using their primary goal — same rules as individual activities.

### 6.3 Routine Execution Flow

The routine is started from the **Home screen only** — tapping a scheduled routine card and selecting "Start Routine" from the action bottom sheet.

#### Routine Flow Screen

```
┌─────────────────────────────────────┐
│ ‹ Minimize    Morning Routine       │
│                                     │
│ ⏱️ 00:23:45 total · 00:18:30 active │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ ✓  Body Scale           2 min  │ │
│ │ ✓  Shower              10 min  │ │
│ │ ✓  Wudu                 3 min  │ │
│ │ ▶  Fajr Sunnah        ← NOW    │ │
│ │ ○  Fajr Prayer                 │ │
│ │ ○  Post-Prayer Athkar          │ │
│ │ ○  Read Quran                  │ │
│ │ ○  Morning Athkar              │ │
│ │ ○  Pray Duha                   │ │
│ └─────────────────────────────────┘ │
│                                     │
│ [Current activity form here]        │
│                                     │
│ [Skip]  [Excuse]  [Mark Missed]     │
└─────────────────────────────────────┘
```

**Top section:**
- Minimize button (‹) — collapses routine to mini-widget
- Routine name as title
- Two timers: total elapsed time (wall clock) and active time (sum of activity durations, excluding idle gaps)

**Activity list:**
- All activities in order with status icons
- ✓ = completed (shows duration if available)
- ▶ = current activity (highlighted)
- ○ = upcoming
- ⊘ = excused
- — = missed
- ? = skipped (pending)
- Tapping an upcoming activity **jumps to it** — the suggested order is not enforced
- Drag handles appear on upcoming activities for reordering mid-routine

**Current activity section:**
- Below the activity list, the current activity's entry form appears inline
- **Smart form selection** (same logic as Home screen cards):
  - Activity has time fields → timer auto-starts
  - Boolean-only habit → checkmark buttons (✓ / ✕)
  - Numeric fields → quick metric form
  - No time/habit/numeric → expanded form
- Completing the activity (submitting the form) auto-advances to the next activity in the sequence

**Action buttons for current activity:**
- **Skip** — leaves the activity as pending (?). Can come back to it later by tapping it in the list. The routine advances to the next activity.
- **Excuse** — opens reason picker, marks the activity as excused (⊘) within the routine. Advances to next.
- **Mark Missed** — marks the activity as missed (—) within the routine. Advances to next.

**Bulk routine actions (overflow menu or long-press on routine title):**
- "Excuse All Remaining" — excuses all incomplete activities in the routine with a selected reason
- "Mark All Remaining as Missed" — marks all incomplete activities as missed
- "End Routine" — stops the routine with whatever progress exists

#### How Activity Entries Are Created During a Routine

When the user completes an activity step within the routine:
1. A standard entry is created, linked to the activity template (Layer 1)
2. The entry is linked to the activity's own period if one exists and the entry's timestamp falls within it (Layer 2)
3. The entry is also linked to the routine entry via `routine_entry_id`
4. The activity's standalone Home screen card (if visible) updates to show completion — no duplication
5. The activity's goals and streaks are evaluated normally

The idle time between activities (gap from completing one to starting the next) is tracked automatically. No user action needed.

#### Routine Window Behavior

**If the routine's scheduled time window ends while the user is mid-routine:**
- The routine **stays open** — the user can finish remaining activities
- Activities completed after the window ends still count as completed
- Routine-level goals that involve timing (start before X, end before X, duration under X) evaluate against the actual times — if the user finished late, timing goals may fail
- The completion count goal ("complete 8/9") is unaffected by the window — it counts what was done regardless of timing

**If the routine period expires without being started:**
- The routine period becomes pending (?) and appears in Needs Attention
- The user can still start the routine late — entries are created and linked, but timing goals will reflect the late start
- Or they can mark the entire routine as missed/excused, which cascades to all activities

#### Cascade Rules

**Routine → Activities (cascade down):**
- Marking an entire routine as excused/missed sets all its activity segments to that status
- This only affects the activities **within the context of the routine's period** — it does NOT affect the activities' standalone period statuses
- Exception: if the activity's standalone period overlaps with the routine's period AND the entry was created during the routine, then the standalone period is also affected

**Activities → Routine (cascade up):**
- If the user independently logs an activity outside the routine flow but within the routine's time window, the routine's corresponding segment updates automatically
- Example: User excuses entire Morning Routine, then logs "Read Quran" at 7:30 AM (within the 6-8 AM routine window). The Quran segment in the routine changes from excused to completed. The routine's overall stats recalculate.
- If the independent entry is outside the routine's time window, the routine segment is unaffected

### 6.4 Routine Mini-Widget

When the user minimizes an active routine (taps ‹ or navigates away), it appears as a mini-widget above the bottom nav, alongside any active timer widgets:

```
┌──────────────────────────────────────────────┐
│ ☀️ Morning Routine  3/9  00:23:45 │ ⏱️ ...  │
└──────────────────────────────────────────────┘
```

- Shows: routine icon/emoji, name (marquee if long), progress (X/Y activities), elapsed time
- No action buttons on the mini-widget (prevents accidents)
- Tap to reopen the routine flow screen
- **Only one routine can be active at a time.** If the user tries to start a second routine, they're warned: "You already have a routine in progress. End it first?"
- Up to 3 timers can run alongside an active routine (for standalone activities not in the routine)

### 6.5 Home Screen Integration

Routine cards appear in Scheduled Today alongside activity cards:

```
┌─────────────────────────────────────┐
│ ○  ☀️ Morning Routine      🔥 12d  │
│      0/9 completed                  │
└─────────────────────────────────────┘
```

- Same card format as activities: status icon, category icon, name, streak badge
- Subtitle shows progress: "0/9 completed" or "5/9 completed" or "9/9 completed"
- Status follows the same lifecycle as activities (○ in progress, ✓ completed, ? pending, ⊘ excused, — missed)

**Tapping a routine card** opens the action bottom sheet:
- **Start Routine** — opens the routine flow screen (see §6.3)
- **Mark as Missed** — cascades to all activities
- **Add Reason** — excuses the routine, cascades to all activities

**No "Record Activity" or "Link Activity"** options for routines — those only apply to individual activities. A routine must be started through the routine flow.

**Activities that are part of a routine:** Individual activity cards for activities that belong to a scheduled routine should still appear independently in Scheduled Today. They might get completed through the routine or independently. The period linkage logic handles deduplication — if the activity was already completed during the routine, the standalone card shows as completed.

### 6.6 Book Screen Integration

Routine entries appear in the Book timeline as a distinct card type:

```
┌─ teal ─────────────────────────────────┐
│ │ ☀️ Morning Routine      6:05 AM  ✓   │
│ │ 🕌 Spiritual            52 min  9/9  │
└─────────────────────────────────────────┘
```

- Same left-border color from category
- Shows routine name, start time, total active duration, completion count
- Tapping opens a routine detail view showing all individual activity entries within that routine session
- Individual activity entries created during the routine also appear in the timeline as regular entry cards (they exist independently)

### 6.7 Database Schema

#### routines
| Column | Type | Notes |
|--------|------|-------|
| id | UUID | Primary key |
| user_id | UUID | FK → users |
| category_id | UUID | FK → categories |
| name | Text | **UNIQUE per user (case-insensitive).** `UNIQUE(user_id, LOWER(name))` |
| description | Text | |
| is_archived | Boolean | Default false |
| activity_sequence | JSONB | Ordered array of activity template IDs: `[{ "activity_id": "uuid", "sort_order": 1 }, ...]` |
| schedule | JSONB | Same versioned structure as activities.schedule. Null if no schedule. |
| goals | JSONB | Same versioned structure as activities.goals. Limited to routine-level metrics only. |
| primary_goal_id | Text | Which goal is primary |
| is_private | Boolean | Default false. When true, routine name and details are blurred throughout the app (see §16.0). |
| created_at | Timestamp (UTC) | |
| updated_at | Timestamp (UTC) | |

#### routine_entries (routine sessions)
| Column | Type | Notes |
|--------|------|-------|
| id | UUID | Primary key |
| user_id | UUID | FK → users |
| routine_id | UUID | FK → routines |
| started_at | Timestamp (UTC) | Derived from first activity entry's start time |
| ended_at | Timestamp (UTC) | Nullable. Derived from last activity entry's end time. Null if routine is still in progress. |
| active_duration | Interval | Sum of all completed activity durations |
| idle_duration | Interval | Sum of gaps between consecutive activities |
| total_duration | Interval | active + idle |
| activities_completed | Integer | Count of completed activities in this session |
| activities_total | Integer | Total activities in the routine at time of execution |
| period_start | Timestamp (UTC) | Nullable. Frozen routine period start |
| period_end | Timestamp (UTC) | Nullable. Frozen routine period end |
| status | Text | 'in_progress' (transient), 'completed', 'partial', 'missed', 'excused', 'pending'. Determined by the routine period status rules: pending if any activity pending, partial if all addressed but mixed, excused if all excused, missed if all missed, completed if all have linked entries. |
| condition_id | UUID | Nullable FK → conditions. Set when status = 'excused' |
| created_at | Timestamp (UTC) | |
| updated_at | Timestamp (UTC) | |

**New column on entries table:**

| Column | Type | Notes |
|--------|------|-------|
| routine_entry_id | UUID | Nullable FK → routine_entries. Links this activity entry to the routine session it was created in. Null for standalone entries. |

#### routine_period_statuses
| Column | Type | Notes |
|--------|------|-------|
| id | UUID | Primary key |
| user_id | UUID | FK → users |
| routine_id | UUID | FK → routines |
| period_start | Timestamp (UTC) | Frozen period boundaries |
| period_end | Timestamp (UTC) | |
| status | Text | 'completed', 'partial', 'missed', 'excused', 'pending' |
| condition_id | UUID | Nullable FK → conditions |
| resolved_at | Timestamp (UTC) | Nullable |
| created_at | Timestamp (UTC) | |
| updated_at | Timestamp (UTC) | |

**Uniqueness:** `UNIQUE(user_id, routine_id, period_start, period_end)`

#### routine_goal_period_statuses
| Column | Type | Notes |
|--------|------|-------|
| id | UUID | Primary key |
| user_id | UUID | FK → users |
| routine_id | UUID | FK → routines |
| goal_id | Text | Matches goal ID inside routines.goals JSONB |
| period_start | Timestamp (UTC) | |
| period_end | Timestamp (UTC) | |
| status | Text | 'met', 'not_met', 'excused' |
| condition_id | UUID | Nullable FK → conditions |
| reason_text | Text | Nullable |
| created_at | Timestamp (UTC) | |
| updated_at | Timestamp (UTC) | |

**Uniqueness:** `UNIQUE(user_id, routine_id, goal_id, period_start, period_end)`

### 6.8 Sync Conflict Resolution for Routines

Follows the same rules as activities:

| Data Type | Unique Constraint | Same ID | Different ID + Same Name | No Overlap |
|-----------|------------------|---------|--------------------------|------------|
| Routines | `UNIQUE(user_id, LOWER(name))` | Last-write-wins | **Ask user** which to keep (same UI as template conflicts) | Union |
| Routine entries | None | Last-write-wins | N/A | Union |
| Routine period statuses | `UNIQUE(routine_id, period_start, period_end)` | Last-write-wins | Recomputed from routine entries | Union |
| Routine goal statuses | `UNIQUE(routine_id, goal_id, period_start, period_end)` | Last-write-wins | Recomputed | Union |

### 6.9 Constraints and Limits

- **One active routine at a time.** Starting a second routine requires ending the first.
- **Up to 3 standalone timers can run alongside an active routine.**
- **Routines can only be started from the Home screen** — not from the FAB, Book, or Settings.
- **Minimum 2 activities, no maximum** (but practically, more than 15-20 would be unwieldy).
- **An activity template can only appear once per routine** — no duplicates within the same routine.
- **A routine cannot contain other routines** — no nesting.
- **Routine-level data is always derived** — the user never directly enters routine-level metrics.

---

## 7. FAB (Floating Action Button)

The FAB is the primary action button, visible on every screen. It provides fast access to all logging and condition actions.

### 7.1 Appearance and Position

- Circular, 56px, Primary color, white icon
- Phone (native + web mobile): bottom-right, 16px from edges, above bottom nav
- Tablet: bottom-right, 24px from edges, above bottom nav
- Web desktop: bottom-right of content area, 24px from edges (no bottom nav, so above the page bottom)
- The FAB is never hidden — it remains visible even when timers are running. Mini-timer widgets are positioned so they don't overlap the FAB.

### 7.2 Single Tap — Arc Speed Dial

Tapping the FAB fans out **4 options in an arc** around the button (not a vertical list):

```
        🏷️
    📊       ✓
        [✕ FAB]
```

The 4 options:
1. **⏱️ Start a Timer** — begin timing an activity
2. **✓ Record a Habit** — quickly mark an activity as done or not done
3. **📊 Record a Metric** — log a numeric value
4. **🏷️ Start a Condition** — begin a life condition (illness, travel, etc.)

**Animation:**
- The + icon rotates 45° to become ✕
- The 4 options fan out in an arc with staggered animation (200ms each, 50ms stagger)
- Backdrop dims slightly behind the speed dial
- Light haptic on tap (native)

**Dismissing:** Tap the ✕, tap the backdrop, or tap one of the options.

**Web desktop:** Single click shows all 4 options (no long press available with a mouse).

**Native (phone/tablet):** Single tap shows all 4 options. Long press auto-starts a timer immediately (see §7.3) — the fastest path to begin tracking.

**Timer limit:** If 3 timers are already running and the user taps "Start a Timer," the option is grayed out. Tapping it shows a toast: "Maximum 3 timers at a time. Stop a timer to start a new one."

### 7.3 Quick Log 1: Start a Timer ⏱️

**Purpose:** Track something happening right now. The timer starts immediately — no "Start Timer" button needed.

**On native long press:** The timer starts instantly with no intermediate screen. An untitled timer begins, and the entry form appears with the timer already running.

**On tapping "Start a Timer" from the arc:** The entry form opens with the timer already counting from 00:00:00.

#### Timer Entry Form (Bottom Sheet)

```
┌─────────────────────────────────────┐
│ Timer                          [✕]  │
│                                     │
│     ┌──────────────────────┐        │
│     │     00:05:23         │        │
│     └──────────────────────┘        │
│         [⏸ Pause]  [■ Stop]        │
│                                     │
│ Activity                            │
│ [Search or type a name...     ]     │
│   └ Matching templates appear       │
│                                     │
│ 📖 Spiritual                        │  ← only shown if linked
│                                     │
│ Started at                          │
│ [9:42 AM, April 1, 2026    ]  [✎]  │
│                                     │
│ ▼ More details                      │
└─────────────────────────────────────┘
```

**Key behaviors:**

**Timer starts immediately.** No friction. The user chose "Start a Timer" — the timer is already running.

**Activity name is a search field,** not a dropdown. As the user types, matching activity templates appear as suggestions. The user can:
- Select a matching template → entry links to that activity (Layer 1), category icon + name appears
- Continue typing a new name → entry is saved with that name, no template link
- Leave it empty → saved as "Untitled"

**Category line** only appears if the entry is linked to a template. Shows the template's category icon and name.

**Started at** is editable. If the user actually started the activity 5 minutes ago but only now opened the app, they can adjust the start time. The timer display adjusts accordingly (e.g., changing start time to 5 minutes ago makes the timer jump to 05:00 and continue counting from there).

**Pause button:** Tapping pause creates a **segment boundary.** The button immediately changes to a ▶ Play button. The timer display freezes but the wall clock continues.

**Stop button:** Ends the activity. The timer stops, and the form auto-expands to show all fields (More details opens automatically). The user can review, add details, and then save.

#### Segments

When the user pauses and resumes, the activity is broken into segments:

```
Segment 1: 9:42:00 AM → 9:55:00 AM (13 min active)
  [paused at 9:55 AM]
Segment 2: 10:02:00 AM → 10:30:00 AM (28 min active)
  [paused at 10:30 AM]
Segment 3: 10:35:00 AM → (still running)
```

**Segment rules:**
- Segments are stored in the database but are primarily visual — the overall activity is what gets linked, assessed, and counted toward goals
- **Total active time** = sum of all segment durations
- **Total idle time** = sum of gaps between segments
- **Activity Start Time** = first segment's start time
- **Activity End Time** = last segment's end time
- If the user pauses (ending a segment) and then clicks Stop without resuming: the idle time between the last pause and the stop is **discarded.** Example: paused at 8:10 AM, stopped at 8:15 AM → those 5 minutes don't count as idle time. The activity's end time is 8:10 AM.
- **Duration** field (if configured) captures the **total active time** (not wall clock time)

#### Mini-Timer Widget

When the user taps outside the entry form (or taps ✕), the timer continues running and appears as a **mini-widget just above the bottom nav bar** (or at the bottom of the viewport on web desktop where there's no nav bar):

```
┌─────────────────────────────────────────────────┐
│ ⏱️ Morning Run  00:35:12 │ ⏱️ Cooking  00:12:4… │
├─────────────────────────────────────────────────┤
│ 🏠  📖  📊  👥  👤                              │
└─────────────────────────────────────────────────┘
```

**Mini-widget rules:**
- Shows activity name (scrolling marquee if too long, like music player widgets)
- Shows elapsed time, updating in real-time
- **No action buttons** on the mini-widget (no pause/play/stop) — too easy to trigger accidentally
- Tapping a mini-widget reopens the full timer entry form as a bottom sheet **above** the mini-timer bar. The other mini-widgets remain visible and tappable below the bottom sheet, allowing quick switching between timers.
- The tapped timer's chip in the mini-bar is **highlighted** (Primary color border or background tint) — not hidden — so the user can see which timer is currently expanded
- Tapping a different timer's chip closes the current bottom sheet and opens the other timer's form
- Up to 3 mini-widgets shown side by side
- Mini-widgets never overlap the FAB — they sit to the left of it

**Native app behavior:**
- Timer runs in background when app is closed
- Timer appears as a **Live Activity** (iPhone Dynamic Island / Lock Screen) or persistent notification (Android) with native platform controls
- Timer state is preserved across app restarts

**Web app behavior:**
- Timer runs only while the tab is open
- If the user tries to close the tab/window while a timer is active or paused: browser confirmation dialog "You have a running timer. Closing this tab will discard it. Are you sure?"
- If force-closed without stopping: the entry is discarded as if it never happened

#### Multi-Timer Support

- Maximum **3 concurrent timers**
- To start a second timer: minimize the current one (tap outside or ✕), then tap FAB → Start a Timer again
- Each timer is independent — different activities, different segments
- All active timers appear in the mini-widget row
- When 3 timers are running, "Start a Timer" is grayed out in the FAB arc with a toast explanation

### 7.4 Quick Log 2: Record a Habit ✓

**Purpose:** The fastest way to mark an activity as done or not done.

#### Habit Entry Form (Bottom Sheet)

```
┌─────────────────────────────────────┐
│ Record a Habit                 [✕]  │
│                                     │
│ Activity                            │
│ [Search or type a name...     ]     │
│                                     │
│ 📖 Spiritual                        │  ← only if linked
│                                     │
│      ┌─────┐         ┌─────┐       │
│      │  ✓  │         │  ✕  │       │
│      │ Yes │         │ No  │       │
│      └─────┘         └─────┘       │
│                                     │
│  🔥 7d · 3/5 this week              │  ← only if applicable
│                                     │
│ ▼ More details                      │
└─────────────────────────────────────┘
```

**Key behaviors:**

**Activity name** is a search field (same as Timer). Not a dropdown. Suggestions appear as the user types.

**The ✓ / ✕ buttons** represent the fundamental question: "Did you do this activity?"
- **✓ (Yes):** Creates an entry with `logged_at = now`. The form closes immediately. Toast: "✓ [Activity name] logged."
- **✕ (No):** Does NOT create an entry. Instead, marks the current period as **missed** (if linked to a scheduled activity with a current period). Toast: "[Activity name] marked as missed." If no schedule/period, the ✕ simply closes the form with no action.

**The ✓ / ✕ is not mapped to any specific Yes/No field** in the template. It represents existence: did the activity happen or not? If the template has Yes/No fields (e.g., "On time?", "With congregation?"), those are filled in from the entry detail later.

**Streak/goal status line** only appears when ALL of these are true:
- The entry is linked to an activity template
- The activity has a schedule with an active current period
- The period expects multiple entries (e.g., "5 times per week")

When shown, it displays: streak badge + progress toward the current period's goal (e.g., "🔥 7d · 3/5 this week"). This gives the user quick feedback without cluttering the minimal form.

**More details** expands to show: Notes, all configured fields, date/time picker.

**No minimizing.** Unlike timers, the habit form either submits (✓ or ✕) or is discarded (tapping ✕ close button). The user cannot minimize a habit entry.

### 7.5 Quick Log 3: Record a Metric 📊

**Purpose:** Log a specific numeric value quickly.

#### Metric Entry Form (Bottom Sheet)

```
┌─────────────────────────────────────┐
│ Record a Metric                [✕]  │
│                                     │
│ Activity                            │
│ [Search or type a name...     ]     │
│                                     │
│ 🏃 Health & Fitness                 │  ← only if linked
│                                     │
│ Distance                            │
│      [−]    ┌─────┐    [+]         │
│             │  0  │                 │
│             └─────┘                 │
│ Unit: [km_____________]             │
│                                     │
│  🔥 14d · 3.2/5 km today            │  ← only if applicable
│                                     │
│         [Save]                      │
│                                     │
│ ▼ More details                      │
└─────────────────────────────────────┘
```

**Key behaviors:**

**Activity name** is a search field (same pattern). Suggestions appear. Linking is optional.

**Primary numeric field:** Defaults to the **first numeric-compatible field** (Number, Range, or Duration) by sort order from the template. If the template has multiple numeric fields, the **field label is a dropdown** — the user can tap it to switch to a different numeric field without expanding "More details":

```
[Heart Rate ▾]                    ← tap to switch fields
     [−]    ┌─────┐    [+]
            │  —  │
            └─────┘
Unit: [bpm]
```

Tapping the field label shows all numeric fields from the template. Selecting one switches the collapsed view to that field with its label and unit.

- If no template is linked: shows a generic number field with an editable text label
- If template is linked but has no numeric fields: shows a generic number field with an editable text label

**Value input:** Defaults to **0**.
- Tapping [+] increments by 1 whole integer
- Tapping [−] decrements by 1 whole integer (minimum depends on field config — no lower than min for Range fields)
- Tapping the value box opens the keyboard for direct input
- Saving with 0 is valid — it records 0 as a real value
- If the user doesn't want to record the currently shown field (e.g., heart rate monitor isn't working), they switch to a different field via the label dropdown
- Only the field shown in the collapsed view has a default value of 0. All other fields (visible in "More details") default to **null** and remain null until the user explicitly enters a value. Null fields are not included in the entry's `field_values`.

**Unit field:** Pre-populated from the template's field configuration if one exists. Otherwise empty and optional. The user can type a unit.

**Streak/goal status line** only appears when ALL of these are true:
- Entry is linked to a template
- The activity has a current period with a goal on this field

When shown: streak badge + current aggregated progress (e.g., "🔥 14d · 3.2/5 km today"). Each new entry adds to the period's aggregation — it creates a **new entry with this value**, not incrementing a previous entry.

**Save button:** Creates the entry with the metric value + `logged_at = now`. A value of 0 is valid and can be submitted. Toast: "✓ [value] [unit] logged."

**More details** expands to show: Notes, all other configured fields, date/time picker.

**No minimizing.** The metric form either submits (Save) or is discarded (✕ close button).

### 7.6 Start a Condition 🏷️

Opens a bottom sheet for creating a new condition:

```
┌─────────────────────────────────────┐
│ Start a Condition              [✕]  │
│                                     │
│ Condition                           │
│ [Select or create...           ▾]   │
│                                     │
│ Presets:                            │
│ [🤒 Sick] [✈️ Traveling]            │
│ [🤕 Injured] [😴 Rest Day]          │
│ [🩸 Menstrual] [🕊️ Bereavement]    │
│ [+ Custom]                          │
│                                     │
│ Start Date                          │
│ [Today, April 1, 2026]        [✎]  │
│                                     │
│         [Start]                     │
└─────────────────────────────────────┘
```

- Shows preset conditions from the user's configured presets (managed in Settings)
- "Custom" lets the user type a name and pick an emoji
- Start date defaults to today, editable
- No end date at creation — condition is active until the user ends it
- The condition immediately appears as a chip on the Home screen

### 7.7 Platform-Specific Behaviors

| Behavior | Native (iOS/Android) | Web Desktop | Web Mobile |
|----------|---------------------|-------------|------------|
| Single tap FAB | 4-option arc | 4-option arc | 4-option arc |
| Long press FAB | Auto-starts timer immediately | N/A (no long press) | Auto-starts timer |
| Timer in background | Runs via system (Live Activity on iOS, persistent notification on Android) | Tab must stay open |
| Timer on lock screen | Yes (native platform controls) | No |
| Tab close with timer | N/A | Confirmation dialog, discard if forced | Confirmation dialog |
| Haptic feedback | Light on FAB tap, medium on timer stop | None | None |
| Max concurrent timers | 3 | 3 | 3 |

---

## 8. Entry Points — How Entries Are Created

Beyond the FAB, entries can be created from several places in the app. Each entry point pre-fills different data to reduce friction.

### 8.1 From the FAB (Quick Logs)

See §7.3–7.5. Nothing is pre-linked — the user searches/types an activity name and the system suggests matches.

### 8.2 From Home Screen — Activity Card Tap

When the user taps a scheduled activity card on the Home screen (Scheduled Today section), a bottom sheet appears:

```
┌─────────────────────────────────────┐
│ Morning Run                    [✕]  │
│ 🏃 Health & Fitness                 │
│ Period: Today, 8:00 AM – 9:00 AM   │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ ⏱️  Record Activity             │ │
│ ├─────────────────────────────────┤ │
│ │ 🔗  Link Activity               │ │
│ ├─────────────────────────────────┤ │
│ │ ─   Mark as Missed              │ │
│ ├─────────────────────────────────┤ │
│ │ ⊘   Add Reason                  │ │
│ └─────────────────────────────────┘ │
└─────────────────────────────────────┘
```

**Record Activity** — Opens a collapsed entry form. Both layers are **pre-linked** (activity template + current period). The user does not need to search or select an activity. Which form opens depends on the template:

| Template Has... | Form That Opens |
|----------------|----------------|
| Start Time, End Time, or Duration field | Collapsed **Timer** form (timer starts immediately) |
| No time fields + default habit goal only | Collapsed **Habit** form (✓ / ✕) |
| No time fields + no default habit goal + numeric field(s) | Collapsed **Metric** form |
| None of the above | **Expanded entry form** (all fields shown) |

`logged_at` defaults to now.

**Link Activity** — Shows a list of orphaned entries: entries linked to this activity template (Layer 1) but not linked to any period (Layer 2). The user selects one to link it to the current period. If no orphaned entries exist: "No unlinked entries for this activity."

**Mark as Missed** — Immediate action. Sets `activity_period_statuses` to 'missed'. Toast with undo: "Morning Run marked as missed. [Undo]" Undo reverts the status. Toast visible for 5 seconds.

**Add Reason** — Sets `activity_period_statuses` to 'excused'. Opens the reason picker: active conditions first, recent closed conditions, preset conditions, custom reason option.

### 8.3 From Home Screen — Needs Attention Card Tap

Same 4 options as §8.2. The only difference:

- The period is a **past period** (not today's)
- **Record Activity:** Both layers are pre-linked (activity template + the specific past period). `logged_at` defaults to **now** (when the user is actually logging it). The period link is what determines which period this entry belongs to — `logged_at` and period link are independent.
- **Link Activity, Mark as Missed, Add Reason:** Same behavior as §8.2, applied to the past period.

### 8.4 From Book Screen — Add Button (+)

A **+ button** in the Book screen's app bar (near the search icon). Tapping it opens an **expanded entry form** — all fields visible, no collapsed/iceberg state, no template pre-linked.

This is designed for:
- Retroactive logging (entering something from days ago)
- Detailed entries where the user wants to fill in everything at once
- Unhurried data entry — the user is not in a rush

The expanded entry form includes:
- Activity search field (search, match templates, or type new name)
- Category display (shown if linked to a template)
- All configured fields from the template (or freeform fields if no template)
- Date/time picker for `logged_at` (defaults to now, easily editable for past entries)
- Notes field (always present)
- Period link display (auto-suggested based on `logged_at` and linkage timestamp priority, but user can change or unlink)
- Save button

### 8.5 Entry Creation Summary

| Entry Point | Layer 1 (Template) | Layer 2 (Period) | `logged_at` Default | Form Type | Source |
|-------------|-------------------|-----------------|--------------------| ----------|--------|
| FAB → Timer | User searches | Auto-suggested | Now | Collapsed timer | manual |
| FAB → Habit | User searches | Auto-suggested | Now | Collapsed habit | manual |
| FAB → Metric | User searches | Auto-suggested | Now | Collapsed metric | manual |
| Home → Activity card → Record | Pre-linked | Pre-linked (today) | Now | Smart (depends on template) | manual |
| Home → Needs Attention → Record | Pre-linked | Pre-linked (past period) | Now | Smart (depends on template) | manual |
| Book → + button | User searches | Auto-suggested | Now | Expanded (all fields) | manual |
| V2: Health device auto-import | Auto-linked | Auto-linked | From source data | Auto (no form) | apple_health, etc. |

### 8.6 Expanded Entry Form

The expanded entry form is the full-featured form for creating or editing an entry. It appears when:
- Book screen + button is tapped
- Home card → Record Activity for a template with no time/habit/numeric fields
- A timer is stopped (auto-expands with timer data pre-filled)
- "More details" is expanded on any quick log form
- An existing entry is tapped in the Book screen (edit mode)

#### Layout

```
┌─────────────────────────────────────┐
│ New Entry                      [✕]  │
│                                     │
│ Activity                            │
│ [Search or type a name...     ]     │
│                                     │
│ 🏃 Health & Fitness                 │  ← only if linked
│                                     │
│ ── Fields ──                        │
│                                     │
│ [All fields listed with values]     │
│                                     │
│ ── Notes ──                         │
│                                     │
│ [Freeform text area]                │
│                                     │
│ ── Entry Details ──                 │
│                                     │
│ Logged at: [Apr 1, 2026 9:42 AM]   │
│ Period: [Today 8:00 AM – 9:00 AM]  │
│                                     │
│ [Duplicate]              [Save]     │
└─────────────────────────────────────┘
```

#### Activity Search Field

- Text input that searches configured activity templates as the user types
- Matching templates appear as suggestions — tap to link (Layer 1)
- User can type a new name with no template link
- User can leave empty — saved as "Untitled"
- If pre-linked (from Home card or timer): shows the activity name as a read-only chip with ✕ to unlink
- Category line (icon + name) appears only if linked to a template

#### Fields Section

**If linked to a template:** All configured fields appear in the template's sort order. Each field renders according to its type:

| Field Type | Rendered As |
|-----------|-------------|
| Start Time | Date/time picker, defaults to null |
| End Time | Date/time picker, defaults to null |
| Duration | HH:MM:SS input (auto-calculated if Start + End both have values, otherwise editable). User cannot directly edit Duration when auto-calculated — it adjusts when Start or End is edited. |
| Number | Number input with +/− steppers (increment by 1), unit label if configured. Default null. |
| Text | Multiline text area. Default empty. |
| Star Rating | 5 tappable stars (tap = full, tap again = half, third tap = clear). Default empty. |
| Mood | 5 emoji faces with labels (😢 Very Bad, 😟 Bad, 😐 Neutral, 😊 Good, 😄 Great). Default unselected. |
| Yes / No | Two large buttons. Default unselected. |
| Single Choice | Dropdown (bottom sheet on phone). Default unselected. |
| Multiple Choice | Checkboxes in a list (bottom sheet on phone). Default unselected. |
| Range | Number input + slider with min/max labels. Default null. |
| Location | "Use current location" button + search/pin on map + saved favorites. Default empty. |
| List | Text input + Add button, items appear as removable rows. Default empty. |

**All fields default to null.** Nothing is required. The user fills in only what they want.

**If NOT linked to a template:** The user can add fields manually via addable chips:

Available without a template:
- Preset: Start Time, End Time, Duration
- Custom: Number, Text, Star Rating, Mood, Yes/No, Location, List

**NOT available without a template** (require pre-configuration):
- Single Choice (needs pre-defined options)
- Multiple Choice (needs pre-defined options)
- Range (needs pre-defined min/max/step)

The user taps a chip to add a field, configures it inline (label, unit for Number), and fills in the value.

**Field limits:**
- Entries have a maximum of **20 fields** when creating normally
- If a template switch/union produces more than 20, the excess is allowed — no blocking or warning

#### Timer Segments Display

If the entry was created via a timer with pause/resume, a segments timeline appears:

```
── Timer Segments ──

▶ 9:42 AM → 9:55 AM    (13 min)
  ⏸ 7 min idle
▶ 10:02 AM → 10:30 AM  (28 min)

Active: 41 min  ·  Idle: 7 min  ·  Total: 48 min
```

**Segment editing:**
- Each segment's start and end time is individually editable
- Overall Start Time = first segment's start (inherited, not independently editable)
- Overall End Time = last segment's end (inherited)
- Total Active Time = sum of segment durations (auto-calculated)
- Total Idle Time = sum of gaps between segments (auto-calculated)
- Duration field = Total Active Time
- User can **delete a segment** (if they accidentally created one)
- User can **merge adjacent segments** (combines two into one, eliminating the idle gap)
- If a segment edit causes overlap with the next segment: warning "This segment overlaps with the next one. Merge them?"

#### Notes Section

Always present on every entry, regardless of template or field configuration. Multiline text area with placeholder "Add notes..." Not configurable in the template — built into every entry.

#### Entry Details Section

**Logged at:** When this entry was recorded. Defaults to now. Editable via date/time picker. Independent from Start Time (which is when the activity happened). Example: user logs at 2 PM that they ran at 7 AM — `logged_at` = 2 PM, Start Time = 7 AM.

**Linked Period:** Only shown if the activity has a schedule. Shows the auto-suggested period based on linkage timestamp priority (Start Time → End Time → `logged_at`). The user can:
- Tap to see available periods and select a different one
- Unlink from any period (orphaned entry)
- If pre-linked from a Home card: pre-set to that card's period

**Period display format:**
- "Today, 8:00 AM – 9:00 AM" (time-windowed daily period)
- "Today" (full-day period)
- "This week (Mon – Sun)" (weekly period)
- "Mar 13 – Mar 15" (multi-day range period)

#### Actions

**Save / Save Changes:** Creates or updates the entry. Validation:
- Activity name or template link must exist (if both empty, saved as "Untitled")
- All field values are optional
- `logged_at` must be set (defaults to now)
- After save: toast "✓ Entry saved" and form closes

**Duplicate (edit mode only):** Creates a new entry with the same field values but `logged_at` = now and no period link (auto-suggested fresh). Useful for recurring similar entries.

**Delete Entry (edit mode only):** Red text button at the bottom. Confirmation required: "Delete this entry? This cannot be undone. [Cancel] [Delete]"

#### Closing / Discarding

When the user taps ✕ or swipes to dismiss:
- System compares current form state to last saved state
- If unchanged: close immediately
- If changed: "You have unsaved changes. [Discard] [Keep Editing]"

#### Changing Activity Template Link

When the user changes the template link from one activity to another, fields are merged using a **union approach** — nothing is lost:

1. All existing fields and their values remain
2. Each field in the new template is compared against existing fields by **label** (case-insensitive) + **type** + **unit** (if applicable)
3. If a match is found: the field is already present with its value — skip it
4. If no match: add the new template's field with a null value
5. Nothing from the old template is removed or cleared

**Example:** Switching from "Morning Run" (Duration, Distance km, Completed?, Mood) to "Evening Walk" (Duration, Distance miles, Steps, Star Rating):

| Existing Field | New Template Match? | Result |
|---------------|-------------------|--------|
| Duration: 00:35:00 | ✓ Duration matches | Kept as-is |
| Distance: 5.2 km | ✕ Unit differs (km ≠ miles) | Kept as-is |
| Completed?: Yes | ✕ Not in new template | Kept as-is |
| Mood: 😊 | ✕ Not in new template | Kept as-is |
| — | Distance (miles) — no match | Added as null |
| — | Steps — no match | Added as null |
| — | Star Rating — no match | Added as null |

The user sees all 7 fields. They can remove any they don't need via the ✕ on each field row.

**Field ordering after switch:** Matched fields stay in their current position. New unmatched fields from the new template appear at the bottom in the template's sort order.

#### Tablet / Desktop Adaptation

On tablet and desktop, the expanded form appears as a **centered modal dialog** (max-width 560px) instead of a full-screen bottom sheet. On desktop, fields that pair naturally (Start Time + End Time, min + max for Range) can lay out side by side in two columns.

---

## 9. Period Engine

The period engine computes **when activities are expected** based on their schedule configuration. Periods are the time boundaries that the linkage engine, goal engine, and streak engine all depend on.

### Core Principle: Computed, Never Stored

Period definitions are never persisted in the database. They are computed on-the-fly based on:
1. The activity's schedule configuration (calendar type, repeat, start/end dates, time window)
2. The user's current timezone and GPS coordinates (for dynamic prayer times)
3. The date or date range being queried

**Why not store them?**
- Open-ended schedules would create infinite rows
- Dynamic time windows depend on the user's real-time location, which changes with travel
- Schedule versioning (retroactive vs forward changes) requires recomputation anyway

### Period Computation Rules

**Input:** Activity schedule config + target date (or date range)
**Output:** List of period objects, each with `period_start` (datetime, UTC) and `period_end` (datetime, UTC)

#### By Frequency Type

**Daily:**
- One period per day from schedule start date to end date (or indefinitely)
- Gregorian: midnight to 11:59:59 PM in user's timezone
- Hijri: previous day's sunset to today's sunset
- With time window: narrowed to the specified window within the day

**Weekly (specific days):**
- Generates periods only on the selected days
- If "entire week": one period spanning the full week (week start to week end, per user's global week-start setting)
- Specific consecutive days as "one period": single period spanning the range
- Specific days as "separate periods": one period per selected day
- Non-consecutive days: always separate periods

**Monthly (specific days):**
- Generates periods only on the selected days of each month
- Consecutive days as "one period" or "separate periods" (user's choice during setup)
- **Short month handling:** If a selected day doesn't exist in a given month (e.g., day 31 in a 30-day month, day 30 in a 29-day Hijri month), the period defaults to the **last day of that month**. If a range spans non-existent days (e.g., 29-31 in February), the range shrinks to the available days (28th only in non-leap February, 28th-29th in leap February).

**Custom Interval:**
- Starting from the schedule start date, compute every Xth day/week/month/year
- Each recurrence = single day period
- With time window: the period is that window within the single day

#### Dynamic Time Windows

When an activity has a dynamic time window (e.g., Fajr to Sunrise):
- Period boundaries are calculated using the user's current GPS coordinates at computation time
- Prayer times use the calculation method and madhab from user settings (e.g., ISNA + Shafi)
- Night fractions (1/3, middle, 2/3) are computed as fractions of sunset-to-sunrise duration

### When Periods Are Computed

| Trigger | What's Computed |
|---------|----------------|
| App open | Today's periods for all scheduled activities (cached in memory) |
| Navigate to Home screen | Use cached periods; recompute if stale (day changed, location changed significantly) |
| Midnight/sunset boundary crossed while app is open | Recompute today's periods |
| Activity detail view | Periods for the requested date range (on demand) |
| Streak calculation | Walk backward through periods as needed |
| Entry linkage | Compute the relevant period for the entry's timestamp |

**Periods are never precomputed for future dates.** Only today and historical dates are computed as needed.

**Performance:** Period computation is pure math — no database queries required (except reading the activity's schedule config, which is already loaded). Computing 365 days of daily periods for one activity takes milliseconds.

### What the Home Screen Shows

The Home screen shows **all periods where today falls within the period bounds** — not just periods that start or end today. This means:
- A daily activity shows today's status
- A weekly activity shows current progress (e.g., "3/5 gym sessions this week")
- A monthly activity shows current progress within the month

### Schedule Versioning

When a user changes a schedule or goals, they are asked:

```
You've changed the schedule for Morning Run.

○ Apply to future periods only (recommended)
   Past periods and streaks stay as they were.

○ Apply retroactively to all periods
   Past periods will be recalculated. Streaks may change.

[Cancel]  [Apply]
```

**Future only (default):** The schedule config is versioned with `effective_from` and `effective_to` dates. The period engine uses the version that was effective on the queried date.

```json
{
  "versions": [
    {
      "effective_from": "2026-01-01",
      "effective_to": "2026-04-01",
      "config": { /* old schedule */ }
    },
    {
      "effective_from": "2026-04-01",
      "effective_to": null,
      "config": { /* new schedule */ }
    }
  ]
}
```

**Retroactive:** The versions array is collapsed to a single entry with the new config. All `activity_period_statuses` rows are deleted and recomputed. Entries are re-linked to new period boundaries. A warning is shown: "This will recalculate your entire history for this activity. Your streaks may change."

**Retroactive re-linkage rules when expected entries changes from "multiple" to "once" per period:**
- For each past period that had multiple linked entries: keep only the **latest entry** (by `logged_at`)
- All other entries are unlinked from the period (orphaned — they still exist in the Book but are not linked to any period)
- The user can manually re-link orphaned entries to other periods later if desired

Goals are versioned identically — each version has an `effective_from`/`effective_to` and the goal definitions for that era.

### Smart Schedule Edit Detection

When the user edits a schedule and chooses "apply to future periods only," the system checks:

**Start date conflict:** If the new start date is in the past, it is automatically adjusted to today. A note is shown: "Start date adjusted to today since changes apply to future periods only."

**End date conflict:** If the user sets an end date that is before today, warn: "This end date is in the past. The schedule will have no future periods."

**Frequency change with existing entries:** If the new frequency would create periods that conflict with already-linked entries (e.g., changing from daily to weekly when entries exist for individual days), the system warns but allows the change — past periods retain their old frequency version.

---

## 10. Goal Engine

The goal engine evaluates whether goals are met, tracks progress mid-period, and manages goal status lifecycle.

### 10.1 Evaluation Triggers

| Trigger | What Gets Evaluated |
|---------|-------------------|
| Entry linked to a period | All goals for that activity in that period |
| Entry edited | Re-evaluate all goals for that entry's period |
| Entry deleted | Re-evaluate all goals for that period |
| Entry unlinked from a period | Re-evaluate the period's goals (entry no longer counts) |
| User opens Home screen | Today's goal statuses for all scheduled activities (from cache, recompute if stale) |
| User views activity detail | Goals for the visible date range |
| Period closes (end datetime passes) | Final evaluation — writes definitive `goal_period_statuses` rows |
| Goal configuration changes | Re-evaluate affected periods (future only or retroactive, per user's choice) |

### 10.2 Active vs Finalized Evaluation

**Active period (ongoing, hasn't ended yet):**
- Goal status is computed **on-the-fly** from current entries
- Status can be: **in progress** (goal not yet met but period isn't over) or **met** ✓
- "In progress" is neutral — NOT shown as failed. The user still has time.
- The display shows progress: "3/5 this week" or "3.2/5 km today"

**Finalized period (ended):**
- Goal status is locked and written to `goal_period_statuses`
- Status is: **met**, **not met**, or **excused** (with reason)
- Finalized statuses drive streak calculations

**Late linkage exception:** A user can link an entry to a period that has already ended. When this happens:
- The period's goal evaluation is **recomputed** with the new entry included
- If the goal now passes, the `goal_period_statuses` row is updated from 'not_met' to 'met'
- Streaks are recalculated accordingly
- Linkage to periods is never permanently locked — it's always adaptable to changes

### 10.3 Evaluation Logic by Goal Type

#### Frequency Goal (Quick Setup)
> "I want to do this activity at least 3 times per week"

1. Count entries linked to the current period for this activity
2. Compare: count [comparison] target?
3. Result: met or in progress (active) / met or not met (finalized)

**Mid-period display:** "2/3 this week"

#### Value Goal (Quick Setup)
> "I want the distance to be at least 5 km per day"

1. Collect all values for the target field from entries linked to the current period
2. Aggregate (sum by default for Quick Setup)
3. Compare: aggregated value [comparison] target?
4. Result: met or in progress / met or not met

**Mid-period display:** "3.2/5 km today"

#### Custom Goal — Most Recent Entry
> "I want my weight to be between 170 and 180 lbs"

1. Find the most recent entry for this activity that has the target field value
2. Compare against target(s)
3. Result: met or not met (standing target — no "in progress" since there's no period)

#### Custom Goal — Aggregated Over Period
> "I want my average mood this week to be at least Good"

1. Find all entries linked to the current period with the target field
2. Collect values, apply aggregation (average)
3. Compare: aggregated value [comparison] target?
4. Result: met or in progress / met or not met

#### Custom Goal — Aggregated Over Last N Entries
> "I want the average of my last 10 weight entries to be at most 180 lbs"

1. Find the N most recent entries for this activity with the target field (regardless of period)
2. Collect values, apply aggregation
3. Compare against target
4. Result: met or not met (no period — standing target)

#### Custom Goal — Aggregated Over Last N Days/Weeks/Months
> "I want the sum of my distance over the last 7 days to be at least 30 km"

1. Compute date range (today minus N units)
2. Find all entries for this activity within that date range with the target field
3. Collect values, apply aggregation
4. Compare against target
5. Result: met or not met

#### Custom Goal — Dynamic Target
> "I want my most recent weight to be less than my average weight over the last 30 days"

1. Evaluate X: most recent weight value
2. Evaluate Y: average weight over last 30 days (collect all entries in range, aggregate)
3. Compare: X [comparison] Y?
4. Result: met or not met

#### Custom Goal — With Consistency Layer
> "Start Fajr within 30 min of Athan in at least 5 of the last 10 periods"

1. Compute the last 10 periods for this activity
2. For each period: evaluate the base goal (Start Time ≤ Window Start + 30 min)
3. Count how many periods passed
4. Compare: passing_count [comparison] threshold?
5. Result: met or not met

### 10.4 Combined Goal Evaluation

When an activity has multiple goals with combination logic:

**All must be met (AND):**
- Evaluate each goal independently
- Combined result: met only if every goal is met (or excused)
- If any goal is "not met" (without reason): combined result is not met

**At least one must be met (OR):**
- Evaluate each goal independently
- Combined result: met if any goal is met
- Only fails if every goal is not met

### 10.5 Primary Goal Display

The **primary goal** (designated in the activity template) is what appears on the Home screen activity card:

- Shows progress indicator: "3/5 this week" or "3.2/5 km today"
- Shows status icon: ✓ (met), "in progress" (active period, not yet met), ✕ (finalized, not met), ⊘ (excused)
- If the primary goal is a combined goal, shows the combined status

All other goals are visible in:
- Entry detail screen (per-entry goal evaluation)
- Activity detail screen (historical goal performance)
- Goal management in the activity template settings

### 10.6 Tolerance and Edge Cases

**Tolerance on comparisons:** If a goal has tolerance set (e.g., "weight = 175 lbs ± 2"), values between 173 and 177 pass.

**Between comparison:** Inclusive on both bounds. "Between 170 and 180" means 170 ≤ value ≤ 180. Both 170 and 180 pass.

**Not between comparison:** "Not between 170 and 180" means value < 170 OR value > 180.

**No entries in period yet:** All goals show as "in progress" — not failed. A goal can only be finalized as "not met" when the period closes.

**Entry deleted that was the only one in a period:** If the period had a 'completed' status and the only linked entry is deleted, the period reverts to 'pending'. Goal statuses for that period are cleared.

**Single entry per period + multiple entries exist:** If the activity expects "once per period," only one entry can be linked. The linked entry is what's evaluated. Other entries for the same activity exist in the Book but are not linked to this period and don't affect its goals.

**Aggregation with zero entries:** If a scope returns zero entries (e.g., "last 10 entries" but only 3 exist), evaluate with what exists. Sum of 0 entries = 0. Average of 0 entries = undefined → goal is "in progress" or "not met" depending on context.

### 10.7 Goal Evaluation Caching

Goal evaluations are **cached** to avoid recomputing on every screen load.

**Cache invalidation triggers:**
- Entry created, edited, deleted, or re-linked for the relevant activity
- Goal configuration changed
- Schedule configuration changed
- Period status changed (missed, excused)
- **Sync pulls new data from cloud** — if the sync engine receives updated entries, period statuses, or goal configurations from the cloud (e.g., user logged something on the web app), the goal cache is invalidated for the affected activities and goals are re-evaluated. If the sync brings no new data, the cache stays valid — no unnecessary recomputation.

**Cache scope:** Per-activity, per-period. Each activity+period combination caches:
- Each goal's computed value (the X side)
- Each goal's status (met, not met, in progress)
- Timestamp of last computation

**Cache storage:** In-memory on native (Riverpod state). Not persisted to local DB — recomputed on app open from entry data.

**Cache lifecycle:**
- Populated on Home screen load
- Updated when entries change
- Cleared on app close (recomputed on next open)
- For finalized periods, the `goal_period_statuses` DB rows serve as the permanent cache — no recomputation needed for closed periods

---

## 11. Linkage Engine

The linkage engine connects **entries to activity templates and scheduled periods.** It's the bridge between what the user logged and the structure they defined.

### Two-Layer Linkage

Every entry has two independent layers of linking:

**Layer 1 — Activity Template Link:**
- Which activity template does this entry belong to?
- Set when the user selects an activity during logging, or manually afterward
- Options: link to an activity, change to a different activity, unlink (becomes a quick entry)
- Changing the activity link automatically clears the period link (Layer 2)

**Layer 2 — Period Link:**
- Within the linked activity, which scheduled period does this entry fall in?
- Only available if Layer 1 is set AND the activity has a schedule
- Options: link to a period (app suggests based on timestamp), change to a different period, unlink from period
- The app suggests the most likely period based on the entry's timestamp, but the user can always override

**Why two layers matter:**
- An entry can be linked to an activity but not to any period (activity has no schedule, or user wants it unlinked from a period)
- Retroactive logging: user logs yesterday's run today and links it to yesterday's period
- Makeup sessions: user does a makeup gym session and links it to the period they missed
- Quick entries have neither layer set

### Entry Types

| Type | Layer 1 | Layer 2 | How Created |
|------|---------|---------|-------------|
| Linked entry | Set (explicit) | Set (if scheduled) | User selects activity from dropdown |
| Quick entry | Null | Null | User logs without selecting an activity |
| Retroactive entry | Set (explicit) | Set (user picks period) | User logs for a past date/period |

### Linkage Timestamp Priority

When auto-suggesting which period an entry belongs to, the engine uses a timestamp from the entry. Priority order:

1. **Start Time field** — if the entry has a Start Time value, use that
2. **End Time field** — if no Start Time but End Time exists, use that
3. **`logged_at` timestamp** — if neither Start Time nor End Time fields exist in the template, use the entry's `logged_at` value

The suggested period is always overridable — the user can manually link to any period regardless of timestamps.

### Linkage Flow

**When the user logs via FAB → "Log Activity":**
1. User selects an activity → Layer 1 set (explicit)
2. Engine determines the linkage timestamp (per priority above) and computes the matching period
3. Layer 2 auto-set to the computed period
4. If the activity expects "once per period" and a linked entry already exists for this period: warning "You already have an entry for [activity] in this period. Log another?" User can proceed or cancel.
5. If "multiple per period": no warning, just link

**When the user logs a Quick Entry:**
1. Entry saved with both layers null
2. No auto-scanning or matching suggestions (too noisy, too many false positives)
3. User can manually link to an activity and period from the entry detail screen later
4. After repeated similar quick entries, the app may suggest creating an activity template (gentle, infrequent nudge — not on every entry)

### Pending Detection

When the app computes today's periods (on app open or Home navigation):
1. For each scheduled activity, check each past period that has no linked entry AND no `activity_period_statuses` row
2. Create a 'pending' status row in `activity_period_statuses` for each detected gap
3. These pending periods appear in the Home screen's "Needs Attention" section

This approach (proactive pending row creation) avoids expensive period recomputation on every query — finding pending items becomes a simple database query.

### Frozen Period Boundaries

When an entry is linked to a period, the computed `period_start` and `period_end` are **frozen onto the entry record** (stored in UTC). This is critical because:
- The user may have been in a different timezone when they logged the entry
- Dynamic prayer times change daily — the Fajr window on March 15 is different from April 15
- If the user travels, recalculating would shift boundaries and potentially orphan entries

**Frozen boundaries on entries are never recalculated** unless the user explicitly chooses "apply retroactively" when changing a schedule.

### Goal-Level Evaluation and Reasons

When an entry is linked to a period, the system evaluates each goal independently. This creates a **hierarchical status model:**

```
Period Status (activity_period_statuses):
  "Did I do this activity in this period?"
  → completed, missed, excused, pending

  └── Goal Statuses (goal_period_statuses):
        "For each goal, did I meet it?"
        → met, not_met, excused, pending
        (only evaluated when period status = 'completed')
```

**Hierarchy rules:**
- If the period is **excused** (user didn't do the activity at all, with a reason) → all goals inherit the excused status. No individual goal evaluation.
- If the period is **missed** (user didn't do it, no reason) → all goals inherit the missed status.
- If the period is **completed** (entry linked) → each goal is evaluated independently and can have its own status.

**Goal status options when period is completed:**

| Goal Status | Meaning | Effect on Goal's Streak |
|-------------|---------|------------------------|
| Met | Goal target achieved | +1 |
| Not met | Goal target not achieved, user accepts | Reset to 0 |
| Excused (with reason) | Goal target not achieved, but user has a valid reason | No change (preserved) |

**Example — Dhuhr prayer while traveling:**
- Period: completed ✓ (entry linked — user prayed)
- Habit goal (did I pray?): ✓ met
- On-time goal (start within Dhuhr window): ✕ not met (prayed at 5:10 PM, window ended at 5:04 PM)
- User adds reason "Traveling" to the on-time goal → ⊘ excused → on-time streak preserved

#### Prompt UX — When Goals Fail

**If the user has an active condition AND one or more goals fail upon linking:**

The app proactively asks:

```
┌─────────────────────────────────────┐
│ You're currently marked as          │
│ Traveling. These goals weren't met: │
│                                     │
│   ✕ On-time (5:10 PM > 5:04 PM)    │
│                                     │
│ Would you like to add a reason?     │
│                                     │
│   [Skip]              [Add Reason]  │
└─────────────────────────────────────┘
```

- **Skip** — neutral, no judgment. The goal stays as "not met." User can add a reason later from the entry detail.
- **Add Reason** — links the active condition as the reason for the failed goal. Streak preserved.

**If no active condition exists AND goals fail:**

No prompt. The entry detail screen shows each goal's evaluation silently:

```
Goals:
  ✓ Prayed (Yes = Yes)
  ✕ On-time (5:10 PM > 5:04 PM)    [Add Reason]
```

The "Add Reason" link is small and non-intrusive. Tapping it opens the reason picker: select an existing condition, create a new condition, or give a one-off reason.

**If all goals are met:** No prompt, no action needed.

**The "Needs Attention" section on the Home screen only surfaces period-level pending items (?)** — not individual failed goals. Goal failures are visible in the entry detail but do not clutter the Home screen. This follows Principle #3 (reflection, not judgment).

---

## 12. Database Schema

### 12.1 Cloud Schema (Supabase — PostgreSQL)

#### users
| Column | Type | Notes |
|--------|------|-------|
| id | UUID | Primary key |
| email | Text | Nullable (not required for native-only pre-auth users) |
| username | Text | Unique. Used for friend search and invite links (kitab.app/add/username). Set during account creation or profile setup. |
| name | Text | |
| avatar_url | Text | |
| bio | Text | |
| birthday | Date | For birthday greeting |
| timezone | Text | User's preferred timezone |
| settings | JSONB | All app settings: theme, hijri on/off, islamic personalization, week start day, date format, time format, timezone display, hijri calc method, hijri day advancement, notification preferences, etc. |
| created_at | Timestamp (UTC) | |
| updated_at | Timestamp (UTC) | |

#### categories
| Column | Type | Notes |
|--------|------|-------|
| id | UUID | Primary key |
| user_id | UUID | FK → users |
| name | Text | **UNIQUE per user (case-insensitive).** Constraint: `UNIQUE(user_id, LOWER(name))` |
| icon | Text | Emoji |
| color | Text | Hex code |
| sort_order | Integer | For user-defined ordering |
| created_at | Timestamp (UTC) | |
| updated_at | Timestamp (UTC) | |

#### activities (templates)
| Column | Type | Notes |
|--------|------|-------|
| id | UUID | Primary key |
| user_id | UUID | FK → users |
| category_id | UUID | FK → categories |
| name | Text | **UNIQUE per user (case-insensitive).** Constraint: `UNIQUE(user_id, LOWER(name))` |
| description | Text | |
| is_archived | Boolean | Default false |
| schedule | JSONB | Null if no schedule. Versioned: `{ "versions": [{ "effective_from", "effective_to", "config": { calendar_type, start_date, end_date, repeat_type, repeat_config, expected_entries, time_window } }] }` |
| fields | JSONB | Array of field definitions: `[{ id, type, label, unit, config, sort_order }]` |
| goals | JSONB | Versioned: `{ "versions": [{ "effective_from", "effective_to", "goals": [{ id, mode, field_id, scope, scope_count, scope_unit, aggregation, comparison, target, target_to, target_type, consistency, is_primary }] }] }` |
| primary_goal_id | Text | Which goal ID (inside goals JSONB) is the primary goal |
| is_private | Boolean | Default false. When true, activity name and details are blurred throughout the app (see §16.0). |
| created_at | Timestamp (UTC) | |
| updated_at | Timestamp (UTC) | |

**JSONB rationale:** Schedule, fields, and goals are complex nested structures that vary per activity. They are always read/written as a whole unit (the user saves the entire template at once). JSONB avoids excessive joins while still supporting PostgreSQL indexing for queries.

**Periods** are not stored in any table. They are computed on-the-fly by the period engine from the schedule JSONB. Periods for a single activity template never overlap — the schedule configuration guarantees this.

**Goals** are stored inside the `goals` JSONB, each with an internal UUID string as its ID. Goal IDs are referenced by `goal_period_statuses.goal_id`.

**Schedule/Goal versioning:** When a user changes a schedule or goals and chooses "apply to future only," a new version is appended to the versions array. When they choose "apply retroactively," the array collapses to a single version with the new config, and all related period/goal statuses are deleted and recomputed.

#### entries (activity records)
| Column | Type | Notes |
|--------|------|-------|
| id | UUID | Primary key |
| user_id | UUID | FK → users |
| name | Text | **Required.** Display name. If linked to a template, set to the template's name at creation (stored independently so entry is self-contained if template is renamed or unlinked). For ad-hoc entries, whatever the user typed or "Untitled". **No uniqueness constraint** — multiple entries can share the same name. |
| activity_id | UUID | Nullable FK → activities. Null = ad-hoc/quick entry (Layer 1 link) |
| period_start | Timestamp (UTC) | Nullable. Frozen period start at time of linkage (Layer 2 link) |
| period_end | Timestamp (UTC) | Nullable. Frozen period end at time of linkage |
| link_type | Text | 'explicit' or null |
| field_values | JSONB | Key-value pairs: `{ field_id: value }`. Values in native types. |
| timer_segments | JSONB | Nullable. Array of segments: `[{ "start": "UTC timestamp", "end": "UTC timestamp" }]`. Total active time = sum of segment durations. Total idle time = sum of gaps. Activity start = first segment start. Activity end = last segment end. If last action was pause then stop, idle time between last pause and stop is discarded. |
| notes | Text | Default notes field (always available on every entry) |
| routine_entry_id | UUID | Nullable FK → routine_entries. Links this entry to the routine session it was created in. Null for standalone entries. |
| source | Text | Nullable. How this entry was created: null or 'manual' (default — user logged it), or a V2 external source identifier ('apple_health', 'google_health', 'fitbit', 'garmin', 'withings', etc.). Used for V2 health device import and competition verification. |
| external_id | Text | Nullable. The unique ID from the external source to prevent duplicate imports during V2 auto-import. Unused in V1. |
| logged_at | Timestamp (UTC) | When the activity occurred (user's intended time, may be retroactive) |
| created_at | Timestamp (UTC) | System timestamp |
| updated_at | Timestamp (UTC) | |

#### activity_period_statuses
| Column | Type | Notes |
|--------|------|-------|
| id | UUID | Primary key |
| user_id | UUID | FK → users |
| activity_id | UUID | FK → activities |
| period_start | Timestamp (UTC) | Frozen period boundaries |
| period_end | Timestamp (UTC) | |
| status | Text | 'completed', 'missed', 'excused', 'pending' |
| condition_id | UUID | Nullable FK → conditions. Set when status = 'excused' |
| resolved_at | Timestamp (UTC) | Nullable. When the user addressed this period |
| created_at | Timestamp (UTC) | |
| updated_at | Timestamp (UTC) | |

**Uniqueness:** `UNIQUE(user_id, activity_id, period_start, period_end)` — one status per activity per period.

**How statuses are set:**
- **'pending'** — created proactively by the period engine when a past period has no linked entries and no status
- **'completed'** — set automatically when an entry is linked to the period
- **'missed'** — set by user action ("Mark as Missed")
- **'excused'** — set by user action ("Add Reason"), links to a condition record

**'completed' and 'pending' are system-computed.** 'missed' and 'excused' are **user decisions.** This distinction matters for sync conflict resolution — user decisions are preserved during merge, system-computed statuses are recomputed from merged entry data.

#### goal_period_statuses
| Column | Type | Notes |
|--------|------|-------|
| id | UUID | Primary key |
| user_id | UUID | FK → users |
| activity_id | UUID | FK → activities |
| goal_id | Text | Matches a goal ID inside activities.goals JSONB |
| period_start | Timestamp (UTC) | Frozen period boundaries |
| period_end | Timestamp (UTC) | |
| status | Text | 'met', 'not_met', 'excused' |
| condition_id | UUID | Nullable FK → conditions. Set when status = 'excused' |
| reason_text | Text | Nullable. For one-off reasons not tied to a condition |
| created_at | Timestamp (UTC) | |
| updated_at | Timestamp (UTC) | |

**Uniqueness:** `UNIQUE(user_id, activity_id, goal_id, period_start, period_end)` — one status per goal per period.

**Only created when the period status is 'completed'** (an entry exists). If the period is excused or missed, goals inherit that status — no goal status rows are created.

**'met' and 'not_met' are system-computed** by the goal engine. **'excused' is a user decision.** Same distinction as period statuses for sync purposes.

#### condition_presets
| Column | Type | Notes |
|--------|------|-------|
| id | UUID | Primary key |
| user_id | UUID | FK → users |
| label | Text | **UNIQUE per user (case-insensitive).** Constraint: `UNIQUE(user_id, LOWER(label))` |
| emoji | Text | |
| is_system | Boolean | True for built-in defaults, false for user-created |
| created_at | Timestamp (UTC) | |

#### conditions (actual condition instances)
| Column | Type | Notes |
|--------|------|-------|
| id | UUID | Primary key |
| user_id | UUID | FK → users |
| preset_id | UUID | FK → condition_presets |
| label | Text | Inherited from preset at creation |
| emoji | Text | Inherited from preset |
| start_date | Date | Day-level granularity. When checking if a condition covers a period, the condition's date range is compared against the calendar date(s) the period falls on — not against period timestamps directly. |
| end_date | Date | Nullable. Null = active/ongoing |
| created_at | Timestamp (UTC) | |
| updated_at | Timestamp (UTC) | |

**Non-overlap rule:** For the same user + same `preset_id`, date ranges **cannot overlap.** If "Sick" spans March 20 – April 2, another "Sick" cannot span March 31 – April 4. Enforced at the application level. No uniqueness on label — multiple "Sick" instances can exist over time, they just can't overlap.

#### notifications
| Column | Type | Notes |
|--------|------|-------|
| id | UUID | Primary key |
| user_id | UUID | FK → users |
| type | Text | 'streak_risk', 'streak_milestone', 'reminder', 'friend_request', 'competition_invite', 'competition_update', 'sync_issue', 'condition_reminder' |
| title | Text | Headline |
| description | Text | Detail text |
| action_type | Text | Nullable. 'navigate_activity', 'navigate_social', 'navigate_competition', 'trigger_sync', etc. |
| action_data | JSONB | Nullable. Data for the action: activity_id, competition_id, etc. |
| created_at | Timestamp (UTC) | |

#### friends
| Column | Type | Notes |
|--------|------|-------|
| id | UUID | Primary key |
| user_id | UUID | FK → users (requester) |
| friend_id | UUID | FK → users (recipient) |
| status | Text | 'pending', 'accepted', 'declined' |
| created_at | Timestamp (UTC) | |
| updated_at | Timestamp (UTC) | |

**Uniqueness:** One relationship per user pair. `UNIQUE(user_id, friend_id)`

#### activity_shares
| Column | Type | Notes |
|--------|------|-------|
| id | UUID | Primary key |
| user_id | UUID | FK → users (owner) |
| activity_id | UUID | Nullable FK → activities. Set when sharing an activity. |
| routine_id | UUID | Nullable FK → routines. Set when sharing a routine. One of activity_id or routine_id must be set. |
| shared_with | UUID | Nullable FK → users. Null = shared with all friends |
| is_private_for_viewer | Boolean | Default false. Set by the recipient to blur this shared item on their device. Does not affect the sharer's display. |
| created_at | Timestamp (UTC) | |

#### competitions
| Column | Type | Notes |
|--------|------|-------|
| id | UUID | Primary key |
| creator_id | UUID | FK → users |
| name | Text | |
| activity_config | JSONB | Shared activity configuration |
| rules | JSONB | Leaderboard configs, duration, scoring |
| visibility | Text | 'public' or 'private' |
| status | Text | 'upcoming', 'active', 'completed' |
| start_date | Timestamp (UTC) | |
| end_date | Timestamp (UTC) | Required. Maximum span: 3 months from start_date. |
| created_at | Timestamp (UTC) | |
| updated_at | Timestamp (UTC) | |

#### competition_participants
| Column | Type | Notes |
|--------|------|-------|
| id | UUID | Primary key |
| competition_id | UUID | FK → competitions |
| user_id | UUID | FK → users |
| joined_at | Timestamp (UTC) | |

**Uniqueness:** `UNIQUE(competition_id, user_id)` — one participation per user per competition.

#### competition_entries
| Column | Type | Notes |
|--------|------|-------|
| id | UUID | Primary key |
| competition_id | UUID | FK → competitions |
| user_id | UUID | FK → users |
| personal_entry_id | UUID | Nullable FK → entries. Links this competition entry to the user's personal entry when dual-tracking is enabled. Null if "just compete" mode. |
| source | Text | Nullable. Same as entries.source. In V2, competition creators can optionally require verified sources (e.g., only GPS-verified runs count). |
| external_id | Text | Nullable. Same as entries.external_id. Prevents duplicate imports from health devices in V2. |
| field_values | JSONB | Same structure as entries.field_values |
| logged_at | Timestamp (UTC) | |
| created_at | Timestamp (UTC) | |

### 12.2 Relationship Diagram

```
users (username UNIQUE)
 ├── 1:many → categories (UNIQUE name per user)
 │                ├── 1:many → activities (UNIQUE name per user, is_private)
 │                │                ├── 1:many → entries (name stored independently, routine_entry_id nullable, source nullable, external_id nullable)
 │                │                ├── 1:many → activity_period_statuses (UNIQUE per activity+period)
 │                │                │               └── references → conditions
 │                │                └── 1:many → goal_period_statuses (UNIQUE per activity+goal+period)
 │                │                                └── references → conditions
 │                │
 │                └── 1:many → routines (UNIQUE name per user, is_private)
 │                                 ├── 1:many → routine_entries (routine sessions)
 │                                 │               └── 1:many → entries (via routine_entry_id)
 │                                 ├── 1:many → routine_period_statuses
 │                                 └── 1:many → routine_goal_period_statuses
 │
 │                [goals live inside activities/routines .goals JSONB]
 │                [periods computed on-the-fly, never stored]
 │
 ├── 1:many → condition_presets (UNIQUE label per user)
 │                └── 1:many → conditions (non-overlapping per preset)
 │
 ├── 1:many → notifications
 ├── 1:many → friends (UNIQUE per user pair)
 ├── 1:many → activity_shares (activity_id OR routine_id, is_private_for_viewer)
 ├── 1:many → reactions (emoji/canned messages to friends)
 ├── 1:many → user_charts (custom Insights charts)
 ├── 1:many → competition_participants (UNIQUE per user+competition)
 │                └── competition_entries (personal_entry_id nullable, source nullable, external_id nullable)
 ├── 1:many → competitions (creator)
 └── settings (1:1, stored in users.settings JSONB)
```

### 12.3 Local Schema (Drift / SQLite — Native Devices Only)

The local schema **mirrors the cloud schema exactly** — same tables, same columns, same constraints. This makes sync straightforward: rows are the same shape in both databases.

**Additional local-only tables:**

#### sync_queue
| Column | Type | Notes |
|--------|------|-------|
| id | UUID | Primary key |
| table_name | Text | Which table was modified |
| record_id | UUID | Which record |
| operation | Text | 'insert', 'update', 'delete' |
| payload | JSONB | The full record data |
| created_at | Timestamp (UTC) | When the change was made locally |
| synced_at | Timestamp (UTC) | Nullable. When pushed to cloud |

#### local_meta
| Column | Type | Notes |
|--------|------|-------|
| key | Text | Primary key |
| value | Text | |

Stores: `last_sync_timestamp`, `device_id`, `local_user_id` (for pre-auth users), `sync_status`.

---

## 13. Sync Engine

### 13.1 Architecture

```
Native App
  ↓ writes to
Local SQLite (Drift) — immediate, no network required
  ↓ queues changes in
sync_queue table
  ↓ when online
Sync Engine pushes to Supabase
  ↓ pulls latest from
Supabase (cloud)
  ↓ merges into
Local SQLite (last-write-wins)
```

### 13.2 Core Principles

1. **Local-first on native:** Every write goes to local SQLite first. The UI reads from local. The user never waits for cloud.
2. **Cloud-only on web:** The web app reads/writes directly to Supabase. No local storage, no sync queue. Offline on web shows "You're offline" message.
3. **Last-write-wins conflict resolution:** When the same record exists in both local and cloud with different data, the record with the most recent `updated_at` wins. The losing version is overwritten.

### 13.3 Sync Cycle

**Push phase:**
1. Read unsynced rows from `sync_queue` (ordered by `created_at`)
2. For each row, push to Supabase via API (insert, update, or delete)
3. On success: mark `synced_at` on the queue row
4. On failure (network error): skip, retry on next cycle

**Pull phase:**
1. Query Supabase for all records where `updated_at > last_sync_timestamp`
2. For each returned record, compare with local version by `updated_at`
3. If cloud is newer: overwrite local
4. If local is newer: keep local (it was already pushed or will be on next cycle)
5. Update `last_sync_timestamp`

**Real-time sync (when online):**
- Subscribe to Supabase real-time channels for the user's data
- When a change arrives from another device (e.g., web app), immediately write to local SQLite
- Provides near-instant cross-device sync when both devices are online

### 13.4 Sync Triggers

| Trigger | Action |
|---------|--------|
| App open | Full sync (push queue + pull latest) |
| Every 5 minutes (app in foreground) | Background sync |
| Navigate to Home screen | Sync if last sync > 1 minute ago |
| New/edit entry | Push this change immediately |
| New/edit activity template | Push this change immediately |
| Change settings/profile | Push this change immediately |
| New/edit condition | Push this change immediately |
| Period status change (complete, miss, excuse) | Push this change immediately |
| Pull-to-refresh on Home screen | Full manual sync |
| App returns to foreground (after being backgrounded) | Sync if last sync > 1 minute ago |

**Performance protection:** Syncs run on a background isolate/thread. They never block the UI. If a sync is already in progress and another is triggered, the second is queued (not duplicated).

### 13.5 Pre-Auth → Account Sync

When a native user creates an account after using the app locally:

1. All local records get the new `user_id` assigned
2. Entire local database is batch-pushed to Supabase
3. If the user already had cloud data (e.g., used the web app first): last-write-wins conflict resolution per record
4. After push + merge, local and cloud are synchronized
5. Normal sync cycle resumes going forward

### 13.6 Sync Status — What the User Sees

| State | UI |
|-------|-----|
| Fully synced | Nothing shown (invisible) |
| Sync in progress | Brief spinner during pull-to-refresh only |
| Unsynced changes exist (offline) | Small amber dot on the Profile/Settings nav icon |
| Tapping the amber dot (in Settings) | Shows: "X changes waiting to sync. Last synced: 5 min ago." with "Sync Now" button |
| Sync failed repeatedly (3+ attempts) | Alert banner on Home: "Some changes haven't synced yet. They're saved on your device and will sync when you're back online." |
| Offline for 24+ hours with unsynced changes | Same alert banner (persistent, not dismissible until synced) |
| Web app offline | Full-screen overlay: "You're offline. Kitab needs an internet connection on the web." |

**Principle:** Sync is invisible when working. The user should never think about it. Only surface sync status when there's a problem or when the user explicitly asks (pull-to-refresh, Settings detail).

### 13.7 All-Goals Day Streak Rules

#### "Today" Definition

For both the **Scheduled Today** section on the Home screen and the **all-goals day streak**, "today" is always **midnight to midnight** in the user's local timezone — regardless of the activity's calendar type (Gregorian or Hijri). This is a universal, simple boundary.

An activity shows in Scheduled Today if any of its periods overlap with today's midnight-to-midnight window. A Hijri activity (sunset-based periods) can still appear on the Home screen — it just uses midnight as the grouping boundary for display, not for its own period computation.

#### Which Activities Count for the All-Goals Day Streak

An activity's period must **end before tonight's midnight** to count toward today's all-goals day streak.

| Scenario | Period End | Counts for Today's Streak? |
|----------|----------|--------------------------|
| Fajr (5:00 AM → 6:30 AM) | 6:30 AM today | ✓ Yes |
| Dhuhr (12:30 PM → 4:00 PM) | 4:00 PM today | ✓ Yes |
| Gym (8:00 AM → 9:00 AM) | 9:00 AM today | ✓ Yes |
| Daily with no time window (midnight → midnight) | Midnight tonight | ✓ Yes |
| Isha (8:00 PM → next day's Fajr 5:00 AM) | 5:00 AM tomorrow | ✗ No (counts for tomorrow) |
| Weekly (Mon → Sun) | Sunday midnight | ✗ No (counts for Sunday only) |

Activities whose periods end after midnight still show in Scheduled Today (they span today) but they don't affect today's streak.

#### Only Primary Goal Matters

Each activity's **primary goal** (designated in the template) is what counts for the all-goals day streak. If an activity has 5 goals and the primary goal is met, the activity counts as ✓ for the day — regardless of the other goals' statuses. Non-primary goals have their own per-goal streaks but do not affect the daily all-goals calculation.

#### Frequency Participation

| Activity Frequency | Per-Activity Streak | Per-Goal Streak | Participates in All-Goals Day Streak |
|-------------------|--------------------|-----------------|------------------------------------|
| Daily (period ends today) | Yes | Yes (per goal) | Yes (primary goal only) |
| Daily (period ends tomorrow, e.g., Isha→Fajr) | Yes | Yes (per goal) | Tomorrow's streak |
| Weekly | Yes (per-week) | Yes (per goal) | Only on the day the period ends |
| Monthly | Yes (per-month) | Yes (per goal) | Only on the day the period ends |
| Custom Interval | Yes (per-occurrence) | Yes (per goal) | Only on the day the period ends |
| No schedule | No streak (standing target) | No streak | No |

### 13.8 Streak Hierarchy

**Per-activity streak (habit streak):** Driven by `activity_period_statuses`. Did I do this activity? Completed = +1, excused = preserved, missed = reset, pending = frozen.

**Per-goal streak:** Driven by `goal_period_statuses`. Did I meet this specific goal? Met = +1, excused = preserved, not met = reset. Only evaluated when the period is completed. If the period is excused/missed, the goal streak inherits that status.

**All-goals day streak:** Evaluated at the end of each day (midnight). For all activities whose periods ended today:
- Every primary goal met → day streak **+1**
- Mix of met and excused (none missed) → day streak **no change** (excused preserves but does not advance)
- Any primary goal missed (not met, no reason) → day streak **resets to 0**
- Any primary goal pending (period ended, unaddressed) → day streak **frozen** 🧊
- No periods ended today → **no effect** on streak (day is neutral)

### 13.9 Scheduled Today vs Needs Attention — Period Lifecycle

**Scheduled Today** only shows periods that are currently active (haven't ended yet). Once a period ends, it is immediately removed from Scheduled Today.

| Period State | Visible in Scheduled Today? | Visible in Needs Attention? | Notes |
|-------------|---------------------------|---------------------------|-------|
| Period is active, no entry yet | ✓ Yes (○ in progress) | No | User still has time |
| Period is active, entry exists, goal in progress | ✓ Yes (○ with progress count) | No | Partial progress shown |
| Period is active, entry exists, primary goal met | ✓ Yes (✓, faded) | No | Completed, still visible until period ends |
| Period is active, excused | ✓ Yes (⊘, faded) | No | |
| Period ended, entry exists, goal met | No (removed) | No | Resolved → Book timeline |
| Period ended, entry exists, goal not met | No (removed) | No | Resolved (unsuccessfully) → Book timeline |
| Period ended, marked as missed | No (removed) | No | Resolved → Book timeline |
| Period ended, excused | No (removed) | No | Resolved → Book timeline |
| Period ended, no entry, unaddressed | No (removed) | ✓ Yes (?) | Unresolved → Needs Attention |

**Removal timing:** Activities are removed from Scheduled Today immediately when their period's end datetime passes. No grace period. If the period was unresolved, it appears in Needs Attention on the same screen.

---

## 14. Screen Specifications

### 14.1 Home Screen

The Home screen is the first thing the user sees when opening the app. It answers: **"What should I do today, and how am I doing?"**

#### App Bar

- **Left:** "Kitab" in DM Serif Display (H1). Once a branded logo exists, replace with the logo.
- **Right:** Notification bell icon button with badge dot (if unread notifications).

#### Section 1 — Summary Card

A tappable card at the top of the screen with the Islamic geometric pattern at subtle opacity as background texture.

**Content:**

```
Assalamu Alaikum, Ahmed            ← greeting
Tuesday, April 1, 2026            ← full date in user's format
☽ Night of 13 Shawwal 1447 AH    ← Hijri date (if enabled)
                                         ┌────────┐
3 of 5 goals met today            ← stat │  3/5   │ ← progress ring
🔥 12 day all-goals streak        ← streak └────────┘
```

**Greeting logic (single greeting, highest priority wins):**

| Priority | Greeting | Condition |
|----------|----------|-----------|
| 1 | "Happy Birthday, [Name]" | User's birthday (from profile) |
| 2 | "Eid Mubarak, [Name]" | 1-3 Shawwal or 10-13 Dhul Hijjah (Islamic personalization ON) |
| 3 | "Happy New Year, [Name]" | January 1 |
| 4 | "Happy Hijri New Year, [Name]" | 1 Muharram (Islamic personalization ON) |
| 5 | "Jumu'ah Mubarak, [Name]" | Friday (Islamic personalization ON) |
| 6 | "Ramadan Mubarak, [Name]" | 1-29/30 Ramadan (Islamic personalization ON) |
| 7 | "Assalamu Alaikum, [Name]" | Default (Islamic personalization ON) |
| 8 | "Good morning/afternoon/evening/night, [Name]" | Default (Islamic personalization OFF) |

If user is not signed in, greeting shows without the name: "Assalamu Alaikum" or "Good evening".

**Time-of-day greeting phases (for priority 8):**

| Phase | Trigger (with location) | Trigger (no location) |
|-------|------------------------|----------------------|
| Early Morning | 1hr before Fajr → Sunrise | 5:00 AM → 8:00 AM |
| Morning | Sunrise → Noon | 8:00 AM → 12:00 PM |
| Afternoon | Noon → 1hr before Sunset | 12:00 PM → 5:00 PM |
| Evening | 1hr before Sunset → Isha | 5:00 PM → 9:00 PM |
| Night | Isha → 1hr before Fajr | 9:00 PM → 5:00 AM |

**Hijri date line:**
- Only shown if Hijri calendar is enabled in Settings
- Format: [sun/moon icon] [Day/Night] of [day] [month] [year] AH
- ☀ (sun icon) between sunrise and sunset, ☽ (crescent moon) between sunset and sunrise
- Hijri day advances at sunset (default) or midnight (user setting)
- Text rendered in Body Small, gray — visually secondary to the Gregorian date

**Progress ring:**
- Shows primary goals met today / total goals whose periods end today
- Counts all activities whose periods end before tonight's midnight (daily activities, and weekly/monthly on their last day)
- Primary color fill, gray track
- Number in center (JetBrains Mono)

**All-goals streak:**
- Flame icon + number + "day all-goals streak"
- Only counts daily-frequency activities
- Shows 🔥 when active, 🧊 when frozen (pending activities exist)
- Gold accent color

**Time-of-day visual adaptation (subtle, not structural):**

| Phase | Pattern Tint | Background Shift |
|-------|-------------|-----------------|
| Early Morning | Soft amber, 4% opacity | +1% warm |
| Morning | Warm gold, 6% opacity | +2% warm |
| Afternoon | Default teal, 5% opacity | Neutral (baseline) |
| Evening | Deep teal, 5% opacity | +1% cool |
| Night | Muted teal, 3% opacity | +2% cool |

Layout, typography, and functionality do NOT change — only the atmospheric color tint on the summary card's geometric pattern.

**Tapping the summary card** opens a **"Today's Summary" bottom sheet:**

```
┌─────────────────────────────────────┐
│ Today's Summary                [✕]  │
│                                     │
│ Tuesday, April 1, 2026             │
│ ☀ Day of 13 Shawwal 1447 AH       │
│                                     │
│       ┌──────────┐                  │
│       │   3/5    │  ← large ring   │
│       │goals met │                  │
│       └──────────┘                  │
│  ✓ 3 Done  ○ 1 Pending  ⊘ 1 Excused│
│                                     │
│ ── All-Goals Streak ──              │
│ 🔥 12 consecutive days              │
│                                     │
│ Week grid (3 weeks):                │
│ M  T  W  T  F  S  S                │
│ 🟢 🟢 🟢 🟢 🟢 🟢 🟢   ← 2 wks ago │
│ 🟢 🟢 🟢 🟢 🟢 🔵 🟢   ← last week │
│ 🟢 🟡 ·  ·  ·  ·  ·    ← this week│
│ 🟢 All met  🟡 Partial  🔵 Excused │
│                                     │
│ ── Today's Stats ──                 │
│ Time tracked: 1h 15m                │
│ Entries logged: 3                   │
│ Most active: Spiritual              │
│                                     │
│ ── Active Conditions ──             │
│ ✈️ Traveling · Day 4          [End] │
└─────────────────────────────────────┘
```

Active conditions shown here with End button. Starting new conditions is FAB-only.

#### Section 2 — Active Condition Chips

Only appears if one or more conditions are currently active. Horizontally scrollable row of chips. No "+ Add" chip — starting conditions is FAB-only.

```
[✈️ Traveling · Day 4  ✕] [🤒 Sick · Day 1  ✕]
```

- Each chip shows: emoji + label + duration + ✕ (tap ✕ to end the condition with today as end date)
- Tapping the chip itself (not ✕) opens a bottom sheet to edit the condition's start date and/or set a custom end date
- If multiple chips overflow the screen width, the row scrolls horizontally
- If no active conditions, this entire section is hidden — no empty state shown

#### Section 3 — Scheduled Today

Shows all activities with periods that overlap with today's midnight-to-midnight window — regardless of the activity's calendar type (Gregorian or Hijri). A Hijri activity with a sunset-based period still appears if its period overlaps with today.

**Section header:** "Scheduled Today" in DM Serif Display (H2)

**Activity cards** listed in order: in-progress first (upcoming ○), then completed (✓), then excused (⊘). Each card:

```
┌─────────────────────────────────────┐
│ [status] [icon] Activity Name  🔥 Xd│
│                 4/8 glasses         │
└─────────────────────────────────────┘
```

**Status icons:**

| Icon | Status | Meaning | Color |
|------|--------|---------|-------|
| ○ | Upcoming / in progress | Not yet completed, period still active | Gray 400 |
| ✓ | Completed | Entry linked to this period, goal met | Success green |
| ? | Pending | Past period, not yet addressed | Warning amber |
| ⊘ | Excused | Period excused with a reason | Info blue |
| — | Missed | Period confirmed missed | Error red (muted) |

**Card details:**
- Category icon (from the activity's category)
- Activity name
- Streak badge on the right (primary goal's streak): 🔥 for active, 🧊 for frozen
- Subtitle line (if applicable): progress toward primary goal ("4/8 glasses", "3/5 this week", "in progress")
- Completed and excused cards are faded (reduced opacity)

**Tapping a card** opens the action bottom sheet (defined in §8.2):
- Record Activity
- Link Activity
- Mark as Missed
- Add Reason

**No checkbox or quick-complete on the card itself.** All actions require intentional tap → bottom sheet → deliberate choice. Prevents accidental completions.

#### Section 4 — Needs Attention

Only appears if there are unaddressed past periods (?). Shows the most recent 3-5 pending items.

**Section header:** "Needs Attention" in DM Serif Display (H2) — colored in Warning amber. Right side: "See All (X)" link if more than 5 pending items.

```
┌─────────────────────────────────────┐
│ [?] Study Arabic                    │
│     Expected yesterday · Mon, Mar 31│
└─────────────────────────────────────┘
```

Each card shows: ? status icon, activity name, which day/period it was expected.

**Tapping a card** opens the same action bottom sheet as §8.3:
- Record Activity (pre-linked to the past period, `logged_at` = now)
- Link Activity
- Mark as Missed (immediate + toast with undo)
- Add Reason

**What qualifies as "Needs Attention":** Only periods that have expired with **no linked entries and no status set** (truly unaddressed). Periods with linked entries but unmet goals are considered resolved (unsuccessfully) and do NOT appear here — they go to the Book timeline.

**If no pending items exist, this entire section is hidden** — no "all caught up" empty state. The section simply doesn't appear.

**"See All" sub-screen:** A dedicated full-screen view of all pending activities across all dates.

**App bar:**
- Back button (‹) on the left → returns to Home
- Title: "Needs Attention" in DM Serif Display
- "Select" button on the right → enters bulk select mode
- Swipe from left edge (iOS) also navigates back
- Tapping Home in the bottom nav also navigates back
- Bottom nav remains visible (this is a sub-screen within the Home tab, not a modal)

**Filter row (below app bar):**
- Search icon (🔍) on the left — tapping opens a search bar that filters by activity name
- Horizontally scrollable filter chips: All (default), Today, This Week, category-specific chips (e.g., 🕌 Spiritual, 🏃 Health) based on the user's categories that have pending items

**Content:**
- Cards grouped by date with day separators
- Day separators show the date and any active conditions interwoven: "Yesterday, April 2 · ✈️ Traveling (Day 5)". Condition chips in separators are tappable (opens condition detail).
- Each card shows: ? status icon, category icon, activity name, expected time window + date
- Tapping a card opens the action bottom sheet with the **full date and time window** displayed: "Wed, April 2, 2026 · 8:00 AM – 9:00 AM". The user always knows which date the pending item belongs to.
- Action options: Record Activity, Link Activity, Mark as Missed (immediate + toast with undo), Add Reason

**Select / bulk mode:**
- Tapping "Select" enters select mode — checkboxes appear on each card
- User taps cards to select/deselect (selected cards are highlighted with Primary border)
- A bulk action bar appears at the bottom showing: selected count + "Mark as Missed" and "Add Reason" buttons
- "Mark as Missed" applies missed status to all selected periods at once with a toast + undo
- "Add Reason" opens the reason picker and applies the selected reason to all selected periods
- Tapping "Cancel" (replaces "Select" button) exits select mode and clears all selections

#### Section 5 — Mini-Timer Widgets

Only appears if one or more timers are currently running or paused. Positioned just above the bottom nav bar.

```
┌─────────────────────────────────────────────────┐
│ ⏱️ Morning Run  00:35:12 │ ⏱️ Cooking  00:12:4… │
├─────────────────────────────────────────────────┤
│ 🏠  📖  📊  👥  👤                              │
└─────────────────────────────────────────────────┘
```

- Up to 3 mini-widgets side by side
- Activity name scrolls (marquee) if too long
- Elapsed time updates in real-time
- No action buttons on the mini-widget (prevents accidental stops)
- Tap opens the full timer entry form
- Mini-widgets sit to the left of the FAB, never overlapping it

See §7.3 for full timer widget specification.

#### Bottom Navigation Bar (Phone)

Fixed (not floating). Solid background (theme surface color) with subtle top border.

**5 tabs:** Home (filled/active), Book, Insights, Social, Profile
- Phosphor icons: outlined = inactive, filled = active
- Active tab: Primary color. Inactive: Gray 400.
- Badge dot on Social tab for unread notifications

#### FAB

Always visible, bottom-right, above bottom nav. See §7 for full specification.

#### Empty State (First-Time User)

When the user has no activities configured:

```
┌─────────────────────────────────────┐
│ [Greeting, no name]                 │
│ [Date]                              │
│                                     │
│   ┌─────────────────────────┐       │
│   │  [Geometric pattern     │       │
│   │   illustration]         │       │
│   │                         │       │
│   │  Your Kitab awaits      │       │
│   │  its first page.        │       │
│   │                         │       │
│   │  [Create an Activity]   │       │
│   └─────────────────────────┘       │
│                                     │
└─────────────────────────────────────┘
```

- Summary card shows greeting and date but no progress ring or streak (nothing to track yet)
- A centered card with geometric pattern illustration, encouraging headline, and a primary CTA button
- The CTA "Create an Activity" navigates to Settings → My Activities → New Activity template form
- FAB is still visible and functional

#### All-Done State

When all scheduled activities for today are completed:

The Scheduled Today section shows all cards as completed (✓) with faded opacity. No special "all done" banner or celebration — the progress ring showing 5/5 and the streak incrementing IS the celebration. The gold accent on the progress ring provides visual reward.

**Streak milestone celebrations** occur at: 7, 14, 21, 30, 60, 90, 100, 180, 365 days, then every 365 thereafter. Milestones apply to both individual activity streaks and the all-goals day streak:

- **All-goals day streak milestone:** Gold shimmer animation on the summary card's streak badge (< 1 second) + medium haptic (native). This is the prominent celebration.
- **Individual activity streak milestone:** Smaller gold shimmer on that activity's streak badge in the Scheduled Today card + light haptic (native). Less prominent but still a moment of recognition.

#### Offline Indicator

If the user is on a native device with no internet connectivity:

- A subtle amber dot appears on the Profile icon in the bottom nav (same as sync indicator)
- No banner on the Home screen unless sync has failed repeatedly (3+ attempts) — then the alert banner defined in §12 Sync Engine appears
- The Home screen is fully functional offline — all data reads from local SQLite

#### Pull to Refresh

Pulling down on the Home screen triggers:
1. Full sync cycle (push + pull)
2. Period recomputation
3. Goal evaluation cache refresh
4. UI updates with any new data

Custom refresh indicator using Primary color. See §12 for sync details.

#### Responsive Layout

**Phone (< 600px):** Single column. Summary card full width. Activity cards stacked vertically. Bottom nav.

**Tablet (600–1024px):** Two columns. Left: Summary card + condition chips + Needs Attention. Right: Scheduled Today. Bottom nav.

**Web desktop (> 1024px):** Single column content area (max-width 600px) to the right of the icon rail (56px). Same layout as phone but with more breathing room. No bottom nav — icon rail provides navigation.

**Web mobile (< 600px):** Same as native phone. Bottom nav (not icon rail).

### 14.2 Notifications Screen

A full-screen view accessed by tapping the notification bell icon on the Home screen app bar.

#### App Bar

- **Left:** Back button (‹) → returns to Home
- **Center:** "Notifications" in DM Serif Display (H1)
- **Right:** "Clear All" text button — only visible when notifications exist. Tapping deletes all notifications with a confirmation: "Clear all notifications? [Cancel] [Clear All]"

Bottom nav remains visible — this is a sub-screen, not a modal.

#### Notification Bell Badge

The bell icon on the Home screen shows a **dot** (not a count) when one or more notifications exist. The dot disappears when all notifications are dismissed.

#### Notification List

Single column, chronological (newest at top). Each notification is a card:

```
┌─────────────────────────────────────┐
│ [icon]  Notification title          │
│         Description text            │
│         2 hours ago                 │
└─────────────────────────────────────┘
```

**Card content:**
- Icon: contextual (🔥 for streak, 👥 for social, ⏱️ for reminder, ⚠ for system)
- Title: brief headline (e.g., "Streak at risk", "Friend request from Ali")
- Description: additional context (e.g., "Morning Run is pending — your 14-day streak is at risk")
- Timestamp: relative time ("2 hours ago", "Yesterday", "3 days ago")

#### Notification Types

| Type | Icon | Title Example | Description Example | Action on Tap |
|------|------|--------------|--------------------| -------------|
| Streak at risk | 🔥 | "Streak at risk" | "Morning Run is pending — your 14-day streak is at risk" | Navigate to Home → card for that activity |
| Streak milestone | 🔥 | "30 day streak!" | "Read Quran — you've been consistent for 30 days" | Navigate to activity detail |
| Reminder to log | ⏱️ | "Don't forget" | "You haven't logged Drink Water today" | Navigate to Home → card for that activity |
| Friend request | 👥 | "Friend request" | "Ali wants to connect with you" | Navigate to Social → friend requests |
| Competition invite | 🏆 | "Competition invite" | "Ali invited you to '30 Day Reading Challenge'" | Navigate to competition detail |
| Competition update | 🏆 | "Leaderboard update" | "You moved to 2nd place in '30 Day Reading Challenge'" | Navigate to competition detail |
| Sync issue | ⚠ | "Sync issue" | "Some changes haven't synced. Tap to retry." | Trigger sync |
| Condition reminder | 🏷️ | "Condition still active" | "You've been marked as Traveling for 7 days" | Navigate to Home → condition chip |

#### Interactions

**Tap a notification:**
- If the notification has an associated action (most do): executes the action (navigates to the relevant screen) AND **deletes the notification** from the list
- If no action (purely informational): tapping does nothing. The card stays until swiped or cleared.

**Swipe left:** Deletes the individual notification. No undo — it's gone.

**Clear All:** Deletes all notifications. Confirmation dialog first.

**No read/unread state.** A notification either exists in the list or it doesn't. There is no visual distinction between seen and unseen notifications.

**No bulk select mode.** Individual swipe or Clear All covers all use cases.

#### Empty State

When no notifications exist:
```
┌─────────────────────────────────────┐
│                                     │
│   [Subtle geometric illustration]   │
│                                     │
│   You're all caught up              │
│                                     │
└─────────────────────────────────────┘
```

A centered message with a subtle geometric pattern illustration. Encouraging, not empty-feeling.

#### Notification Storage

Notifications are stored in the `notifications` table (see §12.1 for full schema). Notifications are generated by the system (streak engine, period engine, social engine) and pushed to the user. On native devices, they also trigger push notifications (APNs/FCM) if the user has notification permissions enabled. The in-app notification list and push notifications are independent — dismissing a push doesn't dismiss the in-app card, and vice versa.

#### Notification Settings (in Profile → Settings)

Users can configure which notifications they receive:
- Streak at risk: on/off (default on)
- Streak milestones: on/off (default on)
- Reminders to log: on/off (default on) + configurable time (e.g., "remind me at 9 PM if I have pending activities")
- Friend requests: on/off (default on)
- Competition updates: on/off (default on)
- Sync issues: always on (cannot disable)
- Condition reminders: on/off (default on) + configurable interval (e.g., "remind me every 7 days if a condition is still active")

### 14.3 Book Screen

The Book is the complete chronological record of everything the user has done — entries and conditions. It's the "book of deeds" in digital form. The user scrolls through their history like flipping through pages.

#### App Bar

```
Book                        [+]
```

- **Left:** "Book" in DM Serif Display (H1) — consistent with other screens (Home shows "Kitab" left-aligned)
- **Right:** Plain + icon (Phosphor Plus, 24px, no circle, no shadow) — tapping opens the expanded entry form for retroactive/detailed logging. Visually distinct from the FAB.

**No bulk select mode.** Individual entries are deleted via swipe-left or long-press menu. Bulk operations are rarely needed for a personal history log and add unnecessary UI complexity.

#### Filter Row

Below the app bar. Horizontally scrollable.

```
[⚙ Filters] [🔍] [📅 Date] [Categories ▾] [Goal Status ▾] [Conditions]
```

- **⚙ Filters button** (leftmost) — opens a bottom sheet with advanced filter options: date range picker, specific activity templates (multi-select), entry type (timer/habit/metric/quick entry). For less common filtering needs.
- **🔍 Search icon** — tapping opens/closes a search bar. Searchable fields: activity name and notes only (categories and conditions have their own filter chips).
- **📅 Date chip** — tapping opens a mini-calendar overlay (using the KitabDateTimePicker calendar component). User taps a date and the Book scrolls to that date. Days without entries still show the day separator with a subtle "No entries" message.
- **Categories chip** — tapping opens a dropdown below with a multi-select list of the user's categories (each with icon and color). Selecting categories filters entries to only show activities from those categories. When active, chip shows count: "Categories (2)".
- **Goal Status chip** — tapping opens a dropdown with multi-select options: Met, Missed, Excused. Filters entries based on their primary goal status. When active, chip shows selections: "Goal: Met, Excused".
- **Conditions chip** — when tapped, switches the view to show condition cards instead of entries. Conditions appear as full cards grouped by date. Day headers do NOT have conditions interwoven in this mode. Tapping again returns to the normal entries view.

Search and filter results maintain the same date-grouped layout. Multiple filters can be active simultaneously (e.g., Categories: Spiritual + Goal Status: Missed = show all Spiritual entries where the primary goal was missed).

#### Content — Timeline

Infinite scroll, newest at top. Entries and conditions grouped by date.

**Day separators (sticky headers):**

```
── Today, April 3, 2026 · ✈️ Traveling (Day 6) ──
```

- Date shown as "Today", "Yesterday", then full date for older days
- Active conditions interwoven in the header — tappable, opens condition detail/edit bottom sheet
- Conditions show contextual labels: "started" on day 1, "Day X" on continuation, "ended" on the last day
- Day separators stick at the top while scrolling so the user always knows what date they're viewing
- When filtering to "Conditions" only: conditions appear as **full cards** (not in headers), grouped by date. Day headers do NOT have conditions interwoven in this filter mode.

**Entry cards:**

```
┌─ teal ─────────────────────────────────┐
│ │ Read Quran              7:00 AM   ✓  │
│ │ 🕌 Spiritual  ⓘ       20 min  12/10 │
└─────────────────────────────────────────┘
```

**Left border:** Color of the linked category. Gray (#9C9790) if unlinked.

**Left side (two lines):**
- Line 1: Activity name (Body, font-weight 500)
- Line 2: Category icon + category name (if linked to a template). Nothing if unlinked. If linked to a template with a schedule but NOT linked to a period, a tooltip icon (ⓘ) appears after the category name. Tapping ⓘ shows a tooltip message: "This entry isn't linked to a scheduled period. Tap the entry to link it."

**Right side (two lines):**
- Line 1: Time display — start time to end time if both exist ("7:00 – 7:20 AM"), or just start time, or just end time, or just `logged_at` time if no time fields exist. Goal status icon (✓ or ✕) at the far right.
- Line 2: Duration if available ("20 min"). Primary goal progress fraction ("12/10 pages") next to it.

**If only `logged_at` exists** (no start/end/duration): show just the logged time on line 1 with goal status. Line 2 shows goal progress if applicable, otherwise empty.

**Card interactions:**
- **Tap:** Opens the expanded entry form in edit mode (pre-populated with all field values, linkage visible and editable)
- **Long press:** Options menu — Duplicate, Edit, Delete
  - **Duplicate:** Creates a new expanded entry form with the same field values but `logged_at` = now. All date/time field values are nulled out. Period link is cleared UNLESS `logged_at` (now) falls within an appropriate period for the linked activity.
  - **Edit:** Same as tap (opens expanded entry form)
  - **Delete:** Confirmation dialog "Delete this entry? This cannot be undone. [Cancel] [Delete]"
- **Swipe left:** Delete action with confirmation

**Quick entry cards (unlinked):**

```
┌─ gray ─────────────────────────────────┐
│ │ Untitled                 9:42 AM     │
│ │                                      │
└─────────────────────────────────────────┘
```

Gray left border, no category line, no goal status. Minimal. Tapping opens the expanded form where the user can add details, link to a template, etc.

**Condition cards (in Conditions filter only):**

```
┌─────────────────────────────────────────┐
│ ✈️  Traveling                           │
│     Mar 29, 2026 – Present              │
└─────────────────────────────────────────┘
```

- Condition icon + label on top line
- Date range on second line: "Mar 29, 2026 – Apr 3, 2026" (if ended) or "Mar 29, 2026 – Present" (if active)
- **Tap:** Opens condition edit (start date, end date, delete)
- **Swipe left:** Delete with confirmation: "Delete this condition? Activities excused with this reason will become unexcused. [Cancel] [Delete]"
- **Long press:** Options — Edit, Delete

#### Scroll Behavior

- **Infinite scroll:** Older entries load as the user scrolls down. Loading spinner at the bottom while fetching.
- **Scroll to top:** Tapping the top of the screen (iOS status bar gesture) or a floating "Today ↑" pill button that appears when the user has scrolled significantly past today. One tap scrolls back to today.
- **Sticky date headers:** Day separators stick to the top of the scroll area so the user always knows which date they're viewing.

#### Empty State

When no entries or conditions exist:

```
┌─────────────────────────────────────────┐
│                                         │
│    [Subtle geometric illustration]      │
│                                         │
│    Every journey starts with a          │
│    single entry. Start writing          │
│    your Kitab.                          │
│                                         │
│    [Log Your First Entry]               │
│                                         │
└─────────────────────────────────────────┘
```

CTA button opens the expanded entry form. FAB is also available.

#### Responsive Layout

**Phone (< 600px):** Single column timeline. Full width cards. Bottom nav.

**Tablet (600–1024px) and Web desktop (> 1024px) — Master-detail layout:**

```
┌──────────────────────┬──────────────────────────┐
│ Timeline (40%)       │ Entry Detail (60%)       │
│                      │                          │
│ [filters + search]   │ [expanded entry form     │
│                      │  for the selected entry] │
│ ── Today ──          │                          │
│ [card] ← selected    │  Read Quran              │
│ [card]               │  🕌 Spiritual            │
│ [card]               │                          │
│ ── Yesterday ──      │  Start Time: 7:00 AM     │
│ [card]               │  Duration: 20 min        │
│                      │  Pages: 12               │
│                      │  ...                     │
│                      │  [Save] [Delete]         │
└──────────────────────┴──────────────────────────┘
```

- Left panel: timeline (scrollable, same as phone but narrower)
- Right panel: expanded entry form for the selected card
- Tapping a different card in the left panel swaps the right panel content instantly — no navigation, no page transition
- If no card is selected: right panel shows placeholder "Select an entry to view details"
- The + button creates a new entry that appears in the right panel

**Web desktop:** Icon rail (56px) on the far left + master-detail. No bottom nav.
**Web mobile (< 600px):** Same as native phone. Bottom nav.

#### FAB

Always visible, same position and behavior as all other screens. See §7.

### 14.4 Profile Screen

The Profile screen is the user's identity and the central hub for all app configuration. It combines the user's profile with all settings, organized by category.

#### Navigation Icon

The Profile tab icon in the bottom nav / icon rail follows this priority:
1. **Profile photo** — circular cutoff of uploaded photo (if exists)
2. **First name initial** — uppercase letter in a circle with Primary color background, white text (if signed in but no photo)
3. **Generic person icon** — Phosphor User (if not signed in)

#### App Bar

```
Profile
```

- **Left:** "Profile" in DM Serif Display (H1)
- No other icons in the app bar — the entire screen is settings, so a gear icon would be redundant.

```
Profile
```

#### Section 1 — Profile Card

**Signed in:**

```
┌─────────────────────────────────────┐
│                                     │
│         [Avatar circle]             │
│            56px                     │
│                                     │
│         Ahmed Al-Ahmed              │
│         ahmed@email.com             │
│         Kitab user since Apr 2026   │
│                                     │
│         [Edit Profile]              │
│                                     │
└─────────────────────────────────────┘
```

- Avatar: profile photo in circle (56px), or first name initial (Primary bg, white text)
- Full name (H2, DM Serif Display)
- Email (Body Small, gray)
- Member since date (Caption, gray)
- "Edit Profile" secondary button → opens Edit Profile sub-screen

**Edit Profile sub-screen:**
- Back button + "Edit Profile" title + "Save" button
- Avatar with camera overlay icon (tap to change photo — take photo or choose from gallery)
- Name field (editable)
- Bio field (multiline, optional, max 150 characters)
- Birthday (date picker — used for birthday greeting)
- Email (editable, requires verification if changed)

**Not signed in (Guest):**

```
┌─────────────────────────────────────┐
│                                     │
│      [Generic user icon circle]     │
│               48px                  │
│                                     │
│             Guest                   │
│                                     │
│   Your data is stored on this       │
│   device only. Create an account    │
│   to sync, back up, and access      │
│   social features.                  │
│                                     │
│       [Create Account]              │
│          Sign In                    │
│                                     │
└─────────────────────────────────────┘
```

- Generic Phosphor User icon in a circle (Gray 300 background)
- "Guest" as the display name (Body Large, gray)
- Brief value proposition — informational, not pushy
- "Create Account" — primary button
- "Sign In" — text button below for returning users
- No badge, no warning indicator — the card messaging is enough

#### Section 2 — My Activities

```
┌─────────────────────────────────────┐
│ 📋  My Activities                 › │
│     12 activities · 4 categories    │
└─────────────────────────────────────┘
```

Tapping opens a sub-screen:

**My Activities sub-screen:**
- Back button + "My Activities" title + [+ New Activity] button
- **Tab bar:** Activities | Categories
- **Activities tab:**
  - List of all activity templates grouped by category
  - Each row: category color dot + activity name + schedule summary ("Daily", "3x/week", "No schedule") + chevron
  - Tap → opens the **Activity Detail View** (see below)
  - Swipe left → archive (not delete — preserves historical data)
  - Long press → options: View, Edit, Duplicate, Archive, Delete
  - **Archive** (recommended): sets `is_archived = true`. Activity disappears from Home screen and active lists but all entries, period statuses, and goal statuses are preserved. Can be unarchived.
  - **Delete**: confirmation "Delete [activity] and all its data? This removes the template, all linked entries, period statuses, and goal statuses permanently. This cannot be undone. [Cancel] [Delete]". Cascade deletes: all `entries` where `activity_id` matches, all `activity_period_statuses`, all `goal_period_statuses`, all `activity_shares` for this activity.
  - Archived activities shown at the bottom in a collapsible "Archived" section (grayed out)

**Activity Detail View:**

When the user taps an activity template, they land on a read-only detail view — not directly into edit mode. This is the complete picture of one activity's performance.

```
┌─────────────────────────────────────┐
│ ‹ Back          Morning Run    [✎]  │
│ 🏃 Health & Fitness                 │
├─────────────────────────────────────┤
│                                     │
│ ── Overview ──                      │
│                                     │
│ 🔥 14 day streak    Best: 21 days   │
│ 85% all-time completion rate        │
│                                     │
│ ── Goals ──                         │
│                                     │
│ Run ≥ 5 km per day                  │
│ 🔥 14d streak · 85% all-time        │
│                                     │
│ Duration ≥ 30 min per day           │
│ 🔥 18d streak · 92% all-time        │
│                                     │
│ ── History ──                       │
│                                     │
│ [All] [Met] [Missed] [Excused] [?]  │
│                                     │
│ Today, Apr 3         ○ In progress  │
│   No entries yet                    │
│                                     │
│ Yesterday, Apr 2     ✓ Met          │
│   7:30 AM · 40 min · 6.2 km        │
│                                     │
│ Monday, Mar 31       ✓ Met          │
│   8:00 AM · 35 min · 5.1 km        │
│                                     │
│ Sunday, Mar 30       ⊘ Excused      │
│   Traveling                         │
│                                     │
│ Saturday, Mar 29     — Missed       │
│   (no entry)                        │
│                                     │
│ Friday, Mar 28       ✓ Met          │
│   7:45 AM · 38 min · 5.8 km        │
│                                     │
└─────────────────────────────────────┘
```

**App bar:**
- Back button (‹) → returns to My Activities list
- Activity name as title
- Edit button (✎) → opens the activity template form (§5.8) in edit mode

**Category line:** Category icon + name displayed below the activity name.

**Overview section:**
- Primary goal's current streak + best-ever streak
- Primary goal's all-time completion rate (percentage of all finalized scheduled occurrences where the primary goal was met)

**Goals section:**
- Lists all goals (primary goal first, but no "Primary"/"Secondary" labels — just listed by goal description)
- Each goal shows: plain-language description, current streak, all-time completion rate
- Tapping a goal could expand to show more detail (streak history, recent pass/fail) — future enhancement

**History section:**
- Chronological list of every scheduled occurrence for this activity, newest first
- The word "period" is never used in the UI — each row is just a date + status
- **Filter chips:** All (default), Met, Missed, Excused, Pending (shown as ?)
- Infinite scroll for activities with long histories

**Each history row shows:**

| Status | Display |
|--------|---------|
| ○ In progress | Date + "In progress" + partial progress if applicable ("3/5 km so far") |
| ✓ Met | Date + "Met" + key metric values from the linked entry (time, duration, primary metrics) |
| ⊘ Excused | Date + "Excused" + condition/reason name |
| — Missed | Date + "Missed" + "(no entry)" |
| ? Pending | Date + "Pending" + "(no entry)" |

**Row interactions:**
- **Tap a row with a linked entry (✓):** Opens the expanded entry form in edit mode for that entry
- **Tap a row with no entry (? Pending, — Missed):** Opens the action bottom sheet: Record Activity (pre-linked to this activity + this date's occurrence), Link Activity, Mark as Missed, Add Reason
- **Tap an excused row (⊘):** Opens condition detail / option to change reason or undo excuse

**Activities without a schedule:** The Overview shows goal status (met/not met as standing target, no streak). Goals section shows all goals with current status. History section is replaced by a simple list of all linked entries in reverse chronological order (no occurrence structure since there's no schedule).

**Tablet/Desktop adaptation:** Same master-detail pattern — My Activities list on the left, Activity Detail View on the right. Edit button opens the template form in the right panel.
- **Categories tab:**
  - List of categories with icon, color, name, activity count
  - Tap → edit (name, icon, color)
  - Drag to reorder
  - Swipe left → delete (with confirmation if activities exist: "Move X activities to which category?")
  - [+ New Category] button at the bottom

#### Section 2.5 — My Routines

```
┌─────────────────────────────────────┐
│ 🔄  My Routines                   › │
│     3 routines                      │
└─────────────────────────────────────┘
```

Tapping opens a sub-screen with the same structure as My Activities:
- Back button + "My Routines" title + [+ New Routine] button
- List of all routines with category color dot, name, schedule summary, activity count
- Tap → opens **Routine Detail View** (same pattern as Activity Detail View: Overview with primary goal streak + completion rate, Goals section listing all goals, History section showing routine occurrences with status and activity breakdown)
- Swipe left → archive
- Long press → options: View, Edit, Duplicate, Archive, Delete
- [+ New Routine] opens the routine configuration form (§6.2)

#### Section 3 — Calendar & Date

```
┌─────────────────────────────────────┐
│ 📅  Calendar & Date               › │
└─────────────────────────────────────┘
```

Tapping opens a sub-screen with the following settings:

| Setting | Type | Default | Options |
|---------|------|---------|---------|
| Show Hijri calendar | Toggle | Off | On/Off |
| Islamic personalization | Toggle | Off | On/Off — controls Islamic greetings, Eid/Ramadan/Jumu'ah awareness |
| Hijri calculation method | Dropdown | Umm al-Qura | Umm al-Qura, Astronomical, Tabular, etc. (only visible if Hijri is on) |
| Hijri day advancement | Dropdown | At sunset | At sunset, At midnight (only visible if Hijri is on) |
| Manual Hijri adjustment | Stepper | 0 | -1, 0, +1 days (only visible if Hijri is on) |
| Date format | Dropdown | Written short | MM/DD/YYYY, DD/MM/YYYY, YYYY-MM-DD, Written short (Apr 2, 2026), Written long (2 April 2026) |
| Time format | Radio | 12-hour | 12-hour (8:00 AM), 24-hour (20:00) |
| Timezone display | Radio | Abbreviation | Abbreviation (EDT), UTC offset (-05:00) |
| Default timezone | Dropdown | Auto-detect | Auto-detect from device, or manual city/timezone selection |
| Week start day | Dropdown | Sunday | Sunday, Monday, Saturday |

Settings that depend on others (e.g., Hijri calculation method only visible when Hijri is on) appear/disappear with smooth animation.

#### Section 4 — Appearance

```
┌─────────────────────────────────────┐
│ 🎨  Appearance                    › │
└─────────────────────────────────────┘
```

Tapping opens a sub-screen:

| Setting | Type | Default | Options |
|---------|------|---------|---------|
| Theme | Segmented control | System Auto | Light, Dark, System Auto |

Preview of the selected theme shown below the control. Minimal for V1 — can expand with accent color options, font size, display density in future versions.

#### Section 5 — Notifications

```
┌─────────────────────────────────────┐
│ 🔔  Notifications                 › │
└─────────────────────────────────────┘
```

Tapping opens a sub-screen:

| Setting | Type | Default | Notes |
|---------|------|---------|-------|
| Streak at risk | Toggle | On | Notifies when a pending activity could break a streak |
| Streak milestones | Toggle | On | Celebrates milestone streaks (7, 14, 21, 30, etc.) |
| Reminders to log | Toggle | On | |
| Reminder time | Time picker | 9:00 PM | "Remind me at this time if I have pending activities" (only visible if reminders on) |
| Friend requests | Toggle | On | |
| Competition updates | Toggle | On | |
| Condition reminders | Toggle | On | Reminds if a condition has been active for a while |
| Condition reminder interval | Dropdown | 7 days | "Remind me every X days" (only visible if condition reminders on) |
| Sync issues | Label | Always on | Shown as non-toggleable with explanation: "You'll always be notified about sync problems" |

If push notification permissions are not granted (native), a banner at the top of this sub-screen: "Notifications are disabled in your device settings. [Open Settings]"

#### Section 6 — Privacy & Sharing

```
┌─────────────────────────────────────┐
│ 🔒  Privacy & Sharing             › │
└─────────────────────────────────────┘
```

Tapping opens a sub-screen:

| Setting | Type | Default | Options |
|---------|------|---------|---------|
| Default sharing for new activities | Dropdown | Private | Private, Specific Friends, All Friends |
| Profile visibility | Dropdown | Friends only | Friends only, Anyone on Kitab, Nobody |
| Competition invites | Dropdown | Friends only | Friends only, Anyone on Kitab |
| Per-activity sharing | Link | — | "Manage sharing per activity →" navigates to My Activities |

#### Section 7 — Conditions

```
┌─────────────────────────────────────┐
│ 🏷️  Condition Presets             › │
└─────────────────────────────────────┘
```

Tapping opens a sub-screen:

- List of all condition presets (system + user-created)
- System presets: 🤒 Sick, ✈️ Traveling, 🤕 Injured, 😴 Rest Day, 🩸 Menstrual, 🕊️ Bereavement
- System presets cannot be deleted but can be hidden (toggle visibility)
- User-created presets: editable (name, emoji), deletable
- [+ New Preset] button at the bottom
- Each preset shows how many times it's been used: "Used 3 times"
- Reorder via drag

#### Section 8 — Data & Storage

```
┌─────────────────────────────────────┐
│ 💾  Data & Storage                 › │
└─────────────────────────────────────┘
```

Tapping opens a sub-screen:

| Setting | Type | Notes |
|---------|------|-------|
| Export data | Button | Opens the Export Data sub-screen (see below) |
| Import data | Button | Opens the Import Data flow (see below) |
| Favorite locations | Sub-screen | Manage saved locations for the Location field type. Add (current GPS / search / pin on map), rename, reorder, delete. Each shows name + address + mini map. |
| Local storage usage | Display | "Using 45 MB on this device" (native only) |
| Clear local cache | Button | Clears cached data (not entries — just temporary cache). Confirmation required. Native only. |

**Export Data sub-screen:**

```
┌─────────────────────────────────────┐
│ ‹ Back       Export Data            │
├─────────────────────────────────────┤
│                                     │
│ Export your Kitab data for backup    │
│ or analysis.                        │
│                                     │
│ ── What to Export ──                │
│                                     │
│ ○ All data (recommended)            │
│ ○ Specific activities               │
│   └ [Select activities...]          │
│                                     │
│ ── Date Range ──                    │
│                                     │
│ ○ All time                          │
│ ○ Custom range                      │
│   └ [Start date] to [End date]      │
│                                     │
│ ── Format ──                        │
│                                     │
│ ○ JSON (single file, full detail)   │
│ ○ CSV (zip of spreadsheets)         │
│                                     │
│        [Export]                      │
│                                     │
└─────────────────────────────────────┘
```

**What to Export:**
- **All data (default):** Exports everything — entries, activity templates, categories, conditions, goals, streaks
- **Specific activities:** Opens a multi-select list of activity templates. Only exports entries and configuration for selected activities, plus their categories and any conditions referenced by excused entries.

**Date Range:**
- **All time (default):** Exports all entries regardless of date
- **Custom range:** Start and end date pickers (using KitabDateTimePicker date component). Only entries within the range are exported. Activity templates, categories, and conditions are always included in full regardless of date range.

**Format:**
- **JSON:** Single `.json` file. Preserves full data structure including nested relationships (entries within activities, goals within templates, segments within timer entries). Best for backup and re-importing into Kitab.
- **CSV:** `.zip` file containing multiple `.csv` spreadsheets: `entries.csv`, `activities.csv`, `categories.csv`, `conditions.csv`, `goals.csv`. Relationships expressed via ID columns. Best for spreadsheet analysis.

**Export flow:**
1. User selects options and taps Export
2. Progress indicator: "Preparing your export..." with a progress bar (for large datasets)
3. On completion: native devices open the system share sheet (save to Files, AirDrop, etc.). Web triggers a browser download.
4. Toast: "Export complete"

**No previous export history.** Each export is generated fresh. No stored files.

**V2 enhancements:** Auto-scheduled exports (monthly to cloud storage), email delivery option.

**Import Data flow:**

```
┌─────────────────────────────────────┐
│ ‹ Back       Import Data            │
├─────────────────────────────────────┤
│                                     │
│ Restore data from a Kitab backup.   │
│                                     │
│ Only Kitab JSON format is           │
│ supported.                          │
│                                     │
│        [Select File]                │
│                                     │
│ ⚠ Importing will merge with your    │
│ existing data. Duplicates are       │
│ resolved using last-write-wins      │
│ (most recent timestamp kept).       │
│                                     │
└─────────────────────────────────────┘
```

**Import rules:**
- Only Kitab's own JSON format is supported (the same format produced by Export)
- CSV import is not supported (too ambiguous without schema context)
- Import **merges** with existing data — it does not replace. Same conflict resolution as the sync engine: last-write-wins based on `updated_at` timestamps.
- If an imported record has the same ID as an existing record, the one with the more recent `updated_at` wins
- If an imported record has a new ID, it's inserted as new data
- Progress indicator during import with record count: "Importing... 245 of 1,203 records"
- On completion: toast "Import complete. X new records added, Y records updated."
- Confirmation before starting: "Import X records? This will merge with your existing data. [Cancel] [Import]"

#### Section 9 — Account

```
┌─────────────────────────────────────┐
│ 👤  Account                       › │
└─────────────────────────────────────┘
```

**If signed in:**

| Setting | Type | Notes |
|---------|------|-------|
| Email | Display + Edit | Shows current email. Tap to change (requires verification). |
| Change password | Button | Opens change password flow |
| Biometric lock | Toggle (native only) | "Require Face ID / Touch ID / Fingerprint to open." Default OFF. When ON, app launch prompts for biometric before showing data. Falls back to password if biometric fails. |
| Sign out | Button | Confirmation: "Sign out? Your data is saved in the cloud." |
| Delete account | Button (danger) | Serious confirmation flow: warning text explaining consequences + type "DELETE" to confirm. Deletes all cloud data. Local data on current device is preserved unless user explicitly clears it. |

**If not signed in:**
- "Create Account" and "Sign In" buttons (same as profile card — redundant access point)
- Explanation: "Creating an account enables cloud sync, backup, and social features."

#### Section 10 — About

```
┌─────────────────────────────────────┐
│ ℹ️  About                         › │
└─────────────────────────────────────┘
```

| Item | Type |
|------|------|
| App version | Display ("Kitab v1.0.0 (build 42)") |
| Terms of service | Link (opens in-app browser or external) |
| Privacy policy | Link |
| Open source licenses | Sub-screen listing all packages and their licenses |
| Contact / Feedback | Link (opens email or feedback form) |
| Rate Kitab | Link (opens App Store / Play Store review page) |

#### Visual Layout

The Profile screen is a single scrollable column. Sections are separated by spacing (xl, 24px) and optional thin dividers.

Each settings group is a **tappable row** with:
- Left: icon + label
- Right: chevron (›) indicating it opens a sub-screen
- Subtle elevation (Level 1 shadow) or just a clean flat card with border

The profile card at the top has slightly more prominence — subtle geometric pattern background (same as Home summary card, very low opacity).

#### Responsive Layout

**Phone (< 600px):** Single column, full width. Each settings group opens as a full-screen sub-page with back button.

**Tablet (600–1024px):** Master-detail. Left: settings list (40%). Right: the selected settings sub-screen content (60%). Tapping a group in the left panel loads its content in the right panel.

**Web desktop (> 1024px):** Same master-detail as tablet, with icon rail on the far left.

#### FAB

Always visible on this screen. Same behavior as all other screens. See §7.

### 14.5 Insights Screen

The Insights screen surfaces meaningful patterns from the user's data. It answers: **"What patterns exist in my life, and how am I growing?"**

#### App Bar and Tabs

```
Insights    [Dashboard] [My Charts]
```

- **Left:** "Insights" in DM Serif Display (H1)
- **Two tabs** below the title: Dashboard (ready-made insights) and My Charts (user-created visualizations)

#### Tab 1 — Dashboard

A single scrollable page of ready-made insights. All sections respond to the selected time period.

##### Period Selector

A chip below the tabs showing the active period. Tapping opens a bottom sheet:

```
[This Month ▾  Apr 1 – Apr 30, 2026]
```

**Standard periods:**
- This Week
- This Month
- Last 30 Days
- Last 3 Months
- Last 6 Months
- This Year
- All Time
- Custom Range (start date → end date using KitabDateTimePicker)

**Ramadan periods (only if Islamic personalization ON):**
- **Ramadan Comparison** — select a Hijri year. Shows pre-Ramadan (Sha'ban), Ramadan, and post-Ramadan (Shawwal) side by side in a three-column layout across all metrics.
- **Ramadan vs Ramadan** — compares the most recent Ramadan's performance against the previous Ramadan. Two-column layout showing year-over-year changes.

Everything on the Dashboard updates when the period changes.

##### Section 1 — Overview Stat Tiles

A horizontally scrollable row of 4 stat tiles:

```
┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐
│ 85%      │ │ 🔥 12    │ │ 47       │ │ 14h 30m  │
│ Goals met│ │ Best     │ │ Entries  │ │ Time     │
│ ↑ 5%     │ │ streak   │ │ logged   │ │ tracked  │
└──────────┘ └──────────┘ └──────────┘ └──────────┘
```

| Tile | Value | Trend |
|------|-------|-------|
| Goals met | Overall completion % for all scheduled activities' primary goals | ↑↓→ vs previous equivalent period |
| Best streak | Longest all-goals day streak achieved in this period | Number only, no trend |
| Entries logged | Total entries recorded | ↑↓→ vs previous period |
| Time tracked | Sum of all duration/timer entries | ↑↓→ vs previous period |

Trend arrows: ↑ Success green (improvement), ↓ Error red (decline), → Gray 400 (no change). Trend compares to the previous equivalent period (this month vs last month, this week vs last week).

##### Section 2 — Completion Heat Map

Month-view calendar where each day is a colored square:

```
── Completion ──

Apr 2026
M  T  W  T  F  S  S
      1  2  3  4  5
 6  7  8  9 10 11 12
13 14 15 16 17 18 19
20 21 22 23 24 25 26
27 28 29 30
```

**Color intensity = % of daily goals met:**
- No goals met / no data: empty (surface color)
- 1–25%: lightest Primary tint
- 26–50%: light Primary
- 51–75%: medium Primary
- 76–99%: dark Primary
- 100%: full Primary with subtle gold border (perfect day)
- Days with active conditions: small Info blue dot in corner

Swipe left/right to navigate months. Tap a day → bottom sheet showing that day's breakdown: which activities were completed, missed, excused.

For periods longer than 1 month: multiple months shown in a scrollable grid (GitHub contribution graph style).

##### Section 3 — Category Breakdown

Horizontal bar charts grouped by category:

```
── By Category ──

🕌 Spiritual          92%  ████████████████████░
🏃 Health & Fitness   75%  ███████████████░░░░░░
📚 Learning           48%  █████████░░░░░░░░░░░░
💼 Work               88%  ████████████████████░
```

Each bar uses the category's own color. Shows completion rate (% of scheduled activities where primary goal was met).

Tapping a category **expands** to show individual activities within it:

```
🕌 Spiritual          92%
  ├ Read Quran       95%  🔥 30d
  ├ Pray on Time     90%  🔥 45d
  └ Morning Athkar   88%  🔥 12d
```

Tapping an activity navigates to the Activity Detail View.

##### Section 4 — Activity Rankings

Ranked list of all activities sorted by completion rate:

```
── Activity Rankings ──

[Best first ▾]  ← toggle: Best first / Needs attention

1. Pray on Time       95%   🔥 45d  ↑ 3%
2. Read Quran         92%   🔥 30d  ↑ 1%
3. Morning Routine    88%   🔥 12d  → 0%
4. Morning Run        75%   🔥 14d  ↓ 5%
5. Study Arabic       48%   🔥 3d   ↓ 12%
```

**"Best first"** shows highest completion rate at top. **"Needs attention"** flips to show lowest first — useful for identifying weak areas.

Each row shows: rank, name, completion %, streak, trend vs previous period.

Tapping an activity navigates to Activity Detail View.

##### Section 5 — Trends

Line chart showing progress over time:

```
── Trends ──

[Goals Met % ▾]           ← dropdown to switch metric

100% ┤
 80% ┤      ╱─╲   ╱─────
 60% ┤   ╱─╱   ╲─╱
 40% ┤──╱
     └─────────────────
     W1   W2   W3   W4
```

**Metric dropdown options:**
- Overall goals met % over time
- Total entries per day/week
- Total time tracked per day/week
- Specific activity's completion rate (sub-dropdown lists activities)
- Specific metric field's value over time (e.g., weight, distance, mood average)
- Specific routine's completion rate

**X-axis granularity adapts to period:**
- This week: daily
- This month: daily
- 3–6 months: weekly
- Year / all time: monthly

**When viewing a specific metric** (e.g., weight trend): line chart with data points, dashed average line, min/max labels, overall trend direction.

**Condition overlay:** Active condition periods shown as a subtle colored band behind the chart (Info blue at 10% opacity), so the user can see how conditions correlated with performance changes.

##### Section 6 — Patterns (Auto-Generated Insights)

```
── Patterns ──

💡 You complete 92% of goals on weekdays but only
   68% on weekends
   Based on 120 data points

💡 Your mood averages 😊 Good on days you exercise
   vs 😐 Neutral on days you don't
   Based on 45 data points

💡 You tend to skip Study Arabic on Fridays
   Missed 8 of last 12 Fridays

💡 Morning Routine completed before 7 AM: 95%
   completion vs 72% after 7 AM
   Based on 30 routines

💡 You were sick for 20 days this year, reducing
   your completion rate by 8%
```

**Pattern types detected (V1):**
1. Day-of-week patterns (strongest/weakest days)
2. Time-of-day patterns (morning vs evening performance)
3. Mood correlations (mood on active days vs inactive)
4. Condition impact (performance during conditions vs without)
5. Streak breaking patterns (what typically breaks streaks)
6. Routine timing impact (early start vs late start)

**Minimum data threshold:** Patterns only appear with 2–4 weeks of data and sufficient data points per pattern type. Before that: "Keep tracking! Patterns will appear after a few weeks of data."

**Read-only** — no actions. The user reflects and adjusts behavior.

##### Section 7 — Conditions Summary

```
── Conditions ──

This period:
  ✈️ Traveling      8 days
  🤒 Sick           3 days

Impact:
  12 activities excused
  Adjusted rate: 85% → 91% (excluding excused)
```

Shows days per condition, total excused activities, and **adjusted completion rate** — what the rate would be excluding excused days. Helps users see "real" performance without life event penalties.

##### Section 8 — Routines Performance

Only appears if user has routines.

```
── Routines ──

☀️ Morning Routine    88%  completed  🔥 12d
   Avg active time: 52 min
   Avg start: 6:15 AM
   Best: Read Quran (98%)
   Weakest: Pray Duha (72%)
```

Each routine shows: completion %, streak, avg active duration, avg start time, best and weakest activity within it.

Tapping navigates to the routine's detail view.

##### Section 9 — Personal Records

```
── Personal Records ──

🏆 Longest all-goals streak     21 days
🏆 Most entries in one day      12 entries
🏆 Longest Morning Run         12.4 km
🏆 Most consistent activity     Pray on Time (95%)
🏆 Longest routine streak       18 days
```

**Always shows all-time records** regardless of period selector. Gold accent color. New records highlighted with "NEW 🌟" badge.

##### Ramadan Comparison View

When a Ramadan period is selected, the Dashboard restructures into a comparison layout:

**Ramadan Comparison (single year):**

```
              Pre-Ramadan  Ramadan  Post-Ramadan
              (Sha'ban)             (Shawwal)

Goals Met        72%    →   94%   →    81%
Daily Entries    3.2    →   5.8   →    4.1
Time Tracked    45 min  → 1h 20m →   55 min
Best Streak     12 days → 28 days → 15 days

── Per Activity ──

Read Quran       75%   →   98%   →    85%
Pray on Time     88%   →   97%   →    90%

── Insight ──

💡 Post-Ramadan improved by 9% vs pre-Ramadan.
   You maintained 86% of your Ramadan gains.

[Year: 1447 AH ▾]
```

**Ramadan vs Ramadan:**

```
              Ramadan 1446    Ramadan 1447

Goals Met        88%      →     94%
Daily Entries    4.5      →     5.8
Time Tracked    55 min    →   1h 20m
Best Streak     22 days   →    28 days

💡 You improved across all metrics compared
   to last Ramadan.
```

Arrows between columns show direction of change. The insight at the bottom calculates retention rates and year-over-year improvements.

#### Tab 2 — My Charts

User-created custom charts. Shows favorited charts first, then all charts.

```
┌─────────────────────────────────────┐
│ ★ Favorites                        │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ Weight Trend         📈 Line    │ │
│ │ [chart preview thumbnail]      │ │
│ └─────────────────────────────────┘ │
│ ┌─────────────────────────────────┐ │
│ │ Mood by Day of Week  📊 Bar    │ │
│ │ [chart preview thumbnail]      │ │
│ └─────────────────────────────────┘ │
│                                     │
│ All Charts                          │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ Running Distance     📈 Line    │ │
│ │ Prayer On-Time Rate  📊 Bar    │ │
│ │ Category Breakdown   🥧 Pie    │ │
│ └─────────────────────────────────┘ │
│                                     │
│         [+ Create Chart]            │
│                                     │
└─────────────────────────────────────┘
```

**Chart cards** show: name, chart type icon, small preview thumbnail. Tapping opens the chart full-screen. Long press → options: Edit, Duplicate, Favorite/Unfavorite, Delete.

**[+ Create Chart]** button at the bottom opens the chart builder.

##### Chart Builder

```
┌─────────────────────────────────────┐
│ ‹ Back       New Chart       Save   │
├─────────────────────────────────────┤
│                                     │
│ Chart Name                          │
│ [________________________]          │
│                                     │
│ Chart Type                          │
│ [📈 Line ▾]                        │
│                                     │
│ Data Source                          │
│ [Activity ▾] → [Morning Run ▾]     │
│                                     │
│ Measure                             │
│ [Field: Distance (km) ▾]           │
│                                     │
│ Calculation                         │
│ [Average ▾]                        │
│                                     │
│ Group By                            │
│ [Weekly ▾]                         │
│                                     │
│ Period                              │
│ [Last 3 Months ▾]                  │
│                                     │
│ Show Conditions                     │
│ [On ○─]                            │
│                                     │
│ ── Live Preview ──                  │
│ ┌─────────────────────────────────┐ │
│ │ [chart renders here in          │ │
│ │  real-time as user changes      │ │
│ │  options above]                 │ │
│ └─────────────────────────────────┘ │
│                                     │
└─────────────────────────────────────┘
```

**Chart Type options:**
- 📈 Line — trends over time
- 📊 Vertical Bar — comparisons by group
- 📊 Horizontal Bar — ranked comparisons
- 🥧 Pie — proportional breakdown
- 🗓️ Heat Map — calendar-style daily view
- ⭕ Progress Ring — single KPI with target
- 📋 Table — raw data view
- 🔢 KPI Number — single large number with optional trend

**Data Source:**
- Activity → select one specific activity
- Routine → select one specific routine
- Category → select one category (aggregates all activities in it)
- All Activities (aggregate across everything)
- All Routines (aggregate across all routines)
- Conditions (condition data: days per condition, frequency)

**Measure** (adapts based on data source):
- Completion rate (% of goals met)
- Entry count
- Goal met count
- Specific field value (e.g., Distance, Weight, Pages — lists configured fields for the selected activity)
- Duration (total tracked time)
- Streak length (current or best)
- Active time / idle time (for routines)
- Condition days

**Calculation** (for field values when multiple entries exist):
- Sum, Average, Min (Lowest), Max (Highest), Count, Latest

**Group By:**
- Daily, Weekly, Monthly, Yearly
- Day of Week (Mon–Sun)
- Time of Day (Early Morning, Morning, Afternoon, Evening, Night)
- Category (when data source is All Activities)
- Activity (when data source is a Category)

**Period:**
Same options as the Dashboard period selector, including Ramadan periods if Islamic personalization is ON.

**Show Conditions toggle:**
When ON, condition periods are overlaid on the chart as colored bands (Info blue at 10% opacity). Helps visualize how conditions correlated with the data.

**Live Preview:**
Updates in real-time as the user changes any option. The user sees immediately if their chart configuration produces something meaningful. If the configuration produces no data: "No data for this combination. Try a different period or measure."

**Save:** Saves the chart to My Charts. The user can optionally mark it as a favorite immediately.

**V1 constraint:** Each chart can only use **one activity or one routine** as the data source (plus conditions as an overlay). Multi-activity comparison charts are V2.

**V2 enhancements:**
- Multi-data-source charts (compare two activities on the same axes)
- Export charts as image/PDF
- Group charts into Reports
- Email delivery of reports
- AI chatbot for natural language data queries

#### Empty State

**Dashboard (new user, no data):**
```
┌─────────────────────────────────────┐
│                                     │
│   [Subtle geometric illustration]   │
│                                     │
│   Your insights are brewing ☕       │
│                                     │
│   Start tracking activities and     │
│   your patterns will appear here.   │
│   Give it a couple of weeks!        │
│                                     │
└─────────────────────────────────────┘
```

**My Charts (no charts created):**
```
┌─────────────────────────────────────┐
│                                     │
│   Create your first custom chart    │
│   to visualize your data your way.  │
│                                     │
│   [+ Create Chart]                  │
│                                     │
└─────────────────────────────────────┘
```

#### Responsive Layout

**Phone (< 600px):** Single column. Charts adapt to screen width. Stat tiles scroll horizontally.

**Tablet (600–1024px):** Stat tiles in a 2×2 grid. Category breakdown and rankings side by side. Charts wider.

**Web desktop (> 1024px):** Max-width content area (800px — wider than other screens to give charts room). Icon rail on left. Stat tiles in a single row. Chart builder shows preview side-by-side with configuration (instead of below).

#### Chart Data Storage

Custom charts are stored in the database:

#### user_charts
| Column | Type | Notes |
|--------|------|-------|
| id | UUID | Primary key |
| user_id | UUID | FK → users |
| name | Text | Chart name |
| chart_type | Text | 'line', 'vertical_bar', 'horizontal_bar', 'pie', 'heat_map', 'progress_ring', 'table', 'kpi_number' |
| data_source_type | Text | 'activity', 'routine', 'category', 'all_activities', 'all_routines', 'conditions' |
| data_source_id | UUID | Nullable. FK → activities or routines. Null for aggregate sources. |
| measure | Text | What's being measured |
| measure_field_id | Text | Nullable. Specific field ID if measuring a field value. |
| calculation | Text | 'sum', 'average', 'min', 'max', 'count', 'latest' |
| group_by | Text | 'daily', 'weekly', 'monthly', 'yearly', 'day_of_week', 'time_of_day', 'category', 'activity' |
| period_type | Text | 'this_week', 'this_month', 'last_30', 'last_3m', 'last_6m', 'this_year', 'all_time', 'custom', 'ramadan_compare', 'ramadan_vs_ramadan' |
| period_start | Date | Nullable. For custom range. |
| period_end | Date | Nullable. For custom range. |
| period_hijri_year | Integer | Nullable. For Ramadan periods. |
| show_conditions | Boolean | Default false |
| is_favorite | Boolean | Default false |
| sort_order | Integer | For ordering in My Charts list |
| created_at | Timestamp (UTC) | |
| updated_at | Timestamp (UTC) | |

**Sync:** Same rules as other user data — last-write-wins on same ID, union on different IDs.

#### FAB

Always visible. Same behavior as all other screens. See §7.

### 14.6 Social Screen

The Social screen is a focused accountability and motivation space — not a social media feed. Users share specific activities with chosen friends and compete in structured challenges.

**Requires an account.** If the user is anonymous (no account), tapping the Social tab shows a prompt: "Create an account to connect with friends, share progress, and join competitions. [Create Account] [Sign In]"

#### App Bar

```
Social                      [👤+]
```

- **Left:** "Social" in DM Serif Display (H1)
- **Right:** Add Friend button (👤+ icon) — opens the Add Friend flow

#### Tab Bar

```
[Friends] [Shared] [Competitions]
```

Three tabs below the app bar. Badge dot on Friends tab if there are pending friend requests.

#### Tab 1 — Friends

##### Pending Requests Section

Only appears if incoming requests exist.

```
── Pending Requests (2) ──

┌─────────────────────────────────────┐
│ [avatar] Ali Hassan                 │
│          ali@email.com              │
│          [Accept]  [Decline]        │
└─────────────────────────────────────┘
```

- Each request: avatar, name, email
- **Accept:** Creates bidirectional friendship. Notification sent to the requester: "[Name] accepted your friend request."
- **Decline:** Removes the request silently. The sender is NOT notified of the decline.

##### Friends List

```
── Friends (12) ──

┌─────────────────────────────────────┐
│ [avatar] Omar Khalid            ›  │
│          3 shared activities        │
└─────────────────────────────────────┘
```

- Sorted alphabetically
- Each row: avatar, name, shared activity count (or "No shared activities")
- **Tap** → opens Friend Detail view
- **Swipe left** → Remove Friend with confirmation: "Remove [name]? They won't be notified. You'll lose access to each other's shared data. [Cancel] [Remove]"

##### Add Friend Flow (👤+ button)

```
┌─────────────────────────────────────┐
│ ‹ Back       Add Friend             │
├─────────────────────────────────────┤
│                                     │
│ Search by email or username         │
│ [________________________]          │
│                                     │
│ Results:                            │
│ ┌─────────────────────────────────┐ │
│ │ [avatar] Ali Hassan             │ │
│ │          ali@email.com          │ │
│ │                  [Send Request] │ │
│ └─────────────────────────────────┘ │
│                                     │
│ Or share your invite link:          │
│ [kitab.app/add/ahmed215]  [Copy]    │
│                                     │
└─────────────────────────────────────┘
```

- Search by email or username
- Results show matching Kitab users with "Send Request" button
- Invite link for sharing outside the app (leads to app store if recipient isn't on Kitab)
- Toast after sending: "Friend request sent to Ali"
- Cannot send a request to someone who is already a friend or has a pending request

##### Friend Detail View

```
┌─────────────────────────────────────┐
│ ‹ Back       Omar Khalid            │
├─────────────────────────────────────┤
│                                     │
│         [avatar large]              │
│         Omar Khalid                 │
│  "Trying to be better every day"    │
│      Friends since Mar 2026         │
│                                     │
│ ── Shared With You ──               │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ 📖 Read Quran          🔥 45d  │ │
│ │    92% this month       [👏]   │ │
│ ├─────────────────────────────────┤ │
│ │ 🏃 Morning Run         🔥 12d  │ │
│ │    78% this month       [💪]   │ │
│ └─────────────────────────────────┘ │
│                                     │
│ ── You Share With Omar ──           │
│ 2 activities · [Manage Sharing →]   │
│                                     │
└─────────────────────────────────────┘
```

**What you can see about a friend's shared activity:**
- Current streak number
- Completion rate (this week, this month)
- Which days they completed (heat map dots — not detailed entry data)

**What you CANNOT see:**
- Actual entry data (times, distances, pages, metric values)
- Their goals or goal targets
- Non-shared activities
- Conditions or excuses

**Reaction button** on each shared activity — tapping opens the reaction picker:

```
┌─────────────────────────────────────┐
│ Send encouragement to Omar:         │
│                                     │
│ [🔥] [💪] [👏] [⭐] [🤲]          │
│                                     │
│ [Keep going!]  [MashAllah!]         │
│ [You got this!] [Proud of you!]     │
│ [Stay consistent!]                  │
└─────────────────────────────────────┘
```

5 emoji reactions + 5 canned text messages. Sent as a notification: "🔥 Ahmed sent you encouragement on Read Quran." No free-text, no replies, no conversations.

Tapping a shared activity shows a **mini progress view:**
- Small heat map of their recent completion (last 2 weeks)
- Streak history (current + best)
- Read-only — no interaction with their data

#### Tab 2 — Shared

Centralized management of what the user shares with friends.

```
── Your Sharing ──

┌─────────────────────────────────────┐
│ 📖 Read Quran                       │
│    Shared with: All friends         │
├─────────────────────────────────────┤
│ 🏃 Morning Run                      │
│    Shared with: Omar, Fatima        │
├─────────────────────────────────────┤
│ 💧 Drink Water                      │
│    Shared with: Omar                │
├─────────────────────────────────────┤
│ ☀️ Morning Routine                  │
│    Shared with: All friends         │
├─────────────────────────────────────┤
│ 📝 Study Arabic                     │
│    Private                          │
└─────────────────────────────────────┘
```

Lists all activities and routines with their current sharing status. Tapping opens the sharing editor:

```
┌─────────────────────────────────────┐
│ ‹ Back    Read Quran Sharing        │
├─────────────────────────────────────┤
│                                     │
│ Share with:                         │
│ ○ Private (nobody)                  │
│ ○ Specific friends                  │
│ ○ All friends                       │
│                                     │
│ ── Select Friends ──                │
│ (only if "Specific friends")        │
│                                     │
│ [✓] Omar Khalid                     │
│ [✓] Fatima Ali                      │
│ [ ] Yusuf Ibrahim                   │
│ [ ] Sara Ahmed                      │
│                                     │
│ Friends can see:                    │
│ • Your current streak               │
│ • Your completion rate              │
│ • Which days you completed it       │
│ • NOT your actual entry data,       │
│   goals, or conditions              │
│                                     │
│         [Save]                      │
└─────────────────────────────────────┘
```

**Routines are shareable** — friends see routine completion rate and streak, but not individual activity details within it.

Default sharing preference for new activities is set in Settings → Privacy & Sharing.

#### Tab 3 — Competitions

Lists competitions grouped by status: Active, Upcoming, Completed.

```
── Active (2) ──

┌─────────────────────────────────────┐
│ 🏆 30-Day Reading Challenge         │
│    12 participants · Day 18/30      │
│    You: 2nd place                   │
│    🥇 Omar: 45 pg/day              │
└─────────────────────────────────────┘

── Upcoming (1) ──

┌─────────────────────────────────────┐
│ 🏆 April Fitness Challenge          │
│    5 participants · Starts Apr 5    │
└─────────────────────────────────────┘

── Completed (1) ──

┌─────────────────────────────────────┐
│ 🏆 March Reading Challenge          │
│    Result: 3rd of 10               │
└─────────────────────────────────────┘
```

**[+ Create]** button at the top or bottom opens the competition creation flow.

**Tapping a competition card** opens the Competition Detail screen.

##### Competition Detail Screen

```
┌─────────────────────────────────────┐
│ ‹ Back    30-Day Reading Challenge  │
├─────────────────────────────────────┤
│                                     │
│ Day 18 of 30 · Ends Apr 30         │
│ Created by Omar Khalid              │
│ 🔒 Private (invite only)           │
│                                     │
│ ── Rules ──                         │
│                                     │
│ Activity: Reading                   │
│ Track: Pages read per day           │
│ Ranked by: Daily average            │
│ Duration: Apr 1 – Apr 30, 2026     │
│                                     │
│ ── Leaderboard ──                   │
│                                     │
│ 🥇 1. Omar Khalid       45 pg/day  │
│ 🥈 2. You (Ahmed)       38 pg/day  │
│ 🥉 3. Fatima Ali        35 pg/day  │
│    4. Sara Ahmed         30 pg/day  │
│    5. Yusuf Ibrahim      28 pg/day  │
│                                     │
│ ── Your Progress ──                 │
│                                     │
│ Today: 12 pages (so far)            │
│ Average: 38 pages/day               │
│ Best day: 52 pages (Apr 8)          │
│ Streak: 18 days                     │
│                                     │
│ [Log Entry]                         │
│                                     │
│ ── Participants (12) ──             │
│                                     │
│ [avatar row...]                     │
│                                     │
│ [Share Invite Link]                 │
│ [Leave Competition]                 │
│                                     │
└─────────────────────────────────────┘
```

**Rules section:** Activity being tracked, leaderboard metric, ranking method, duration.

**Leaderboard:** Ranked by the competition's defined metric. Top 3 get gold/silver/bronze (Accent gold, silver #C0C0C0, bronze #CD7F32). Current user highlighted with Primary tint background. Updates in real-time as participants log entries.

**Multiple leaderboards:** If the competition has more than one leaderboard, they appear as tabs within the leaderboard section: `[Pages ▾] [Streak ▾]`

**Your Progress:** Personal stats within this competition — today's value, average, best day, streak.

**[Log Entry]:** Opens an entry form pre-configured with the competition's activity template. The entry counts toward both the competition leaderboard AND personal activity tracking if the user has a matching personal template.

**Personal activity linkage — prompted on join:**

When a user joins a competition, they are always asked how to link it to their personal tracking:

```
┌─────────────────────────────────────┐
│ Link to Personal Tracking           │
│                                     │
│ Would you like competition entries  │
│ to also count toward your personal  │
│ activity tracking?                  │
│                                     │
│ ○ Link to existing activity         │
│   [Read Quran ▾]                   │
│   (shows only templates with        │
│    compatible fields)               │
│                                     │
│ ○ Create a new personal activity    │
│   (pre-filled from competition      │
│    config)                          │
│                                     │
│ ○ No, just compete                  │
│   (entries only count in the        │
│    competition)                     │
│                                     │
│         [Join Competition]          │
└─────────────────────────────────────┘
```

- **Link to existing:** User selects from their personal templates. Only templates with compatible fields are shown. Competition entries dual-track to both the competition leaderboard and the personal activity's Book/streaks/goals.
- **Create new:** Opens simplified template creation pre-filled from the competition's activity config. After creation, all entries dual-track.
- **No, just compete:** Entries only go to `competition_entries`. They appear on the leaderboard but not in the user's personal Book.
- The user can change this linkage later from the competition detail screen (link, unlink, or switch template). Retroactive linking of past competition entries is supported.

**Participants list:** Avatar row. If private, the creator can remove participants. Each participant shows their name — tapping shows their leaderboard stats (not their personal data).

**[Share Invite Link]:** Generates a shareable link. For private competitions, only invited users can join. For public, anyone with the link.

**[Leave Competition]:** Confirmation: "Leave this competition? Your entries and position will be removed from the leaderboard. [Cancel] [Leave]". All of the user's `competition_entries` for this competition are deleted. Their `competition_participants` row is removed.

**Creator-specific actions (overflow menu ⋮):**
- Edit competition (name, dates — cannot change activity config after entries exist)
- End competition early
- Remove a participant
- Delete competition (confirmation required, affects all participants)

##### Competition Creation Flow

**Screen 1 — Basics:**

```
┌─────────────────────────────────────┐
│ ‹ Cancel  Create Competition  Next  │
├─────────────────────────────────────┤
│                                     │
│ Competition Name                    │
│ [________________________]          │
│                                     │
│ Visibility                          │
│ ○ Private (invite only)             │
│ ○ Public (anyone can join)          │
│                                     │
│ Duration                            │
│ Start: [Apr 1, 2026]               │
│ End:   [Apr 30, 2026]  (required)  │
│ Max span: 3 months                  │
│                                     │
└─────────────────────────────────────┘
```

**Screen 2 — Activity & Leaderboard:**

```
┌─────────────────────────────────────┐
│ ‹ Back   Create Competition   Next  │
├─────────────────────────────────────┤
│                                     │
│ What are competitors tracking?      │
│                                     │
│ ○ Use one of my templates           │
│   [Read Quran ▾]                   │
│                                     │
│ ○ Create a custom activity          │
│   [+ Set Up Activity]              │
│                                     │
│ Leaderboard 1:                      │
│ Metric: [Pages read ▾]            │
│ Rank by: [Daily average ▾]        │
│   Options: Total sum, Daily average,│
│   Best single entry, Longest streak,│
│   Completion count                  │
│                                     │
│ [+ Add Another Leaderboard]         │
│                                     │
└─────────────────────────────────────┘
```

"Use one of my templates" — the competition uses the user's existing template config (fields, metrics). All participants track the same metrics.

"Create a custom activity" — opens a simplified activity config (name, fields only — no schedule/goals since the competition defines those). This config is stored on the competition, not as a personal template.

**Screen 3 — Invite:**

```
┌─────────────────────────────────────┐
│ ‹ Back   Create Competition  Create │
├─────────────────────────────────────┤
│                                     │
│ Invite friends:                     │
│                                     │
│ [✓] Omar Khalid                     │
│ [✓] Fatima Ali                      │
│ [ ] Yusuf Ibrahim                   │
│ [ ] Sara Ahmed                      │
│                                     │
│ You can invite more after creation. │
│                                     │
│        [Create Competition]         │
│                                     │
└─────────────────────────────────────┘
```

Selected friends receive a competition invite notification. The creator is automatically a participant.

#### Social Notification Badge

The Social tab in the bottom nav shows a badge dot (same dot style as the notification bell) when there are:
- Pending friend requests
- Competition invites
- Competition updates (leaderboard changes, competition started/ended)
- Reactions received from friends

One dot for all social notifications — no distinction between types.

#### Empty States

**Friends (no friends):**
```
Connect with friends to share
your journey and stay accountable.

[Add a Friend]
```

**Shared (no friends or nothing shared):**
```
Share activities with friends so they
can cheer you on and keep you motivated.

[Add a Friend]
```

**Competitions (none):**
```
Compete with friends and the community
to push each other further.

[Create a Competition]
```

#### Responsive Layout

**Phone (< 600px):** Single column. Tabs at top. Full-width cards.

**Tablet (600–1024px):** Master-detail. Friends/Shared/Competitions list on left (40%), detail view on right (60%). Selecting a friend shows Friend Detail. Selecting a competition shows Competition Detail.

**Web desktop (> 1024px):** Same master-detail with icon rail. Wider content area.

#### Database Additions

**reactions** (for friend encouragement)
| Column | Type | Notes |
|--------|------|-------|
| id | UUID | Primary key |
| sender_id | UUID | FK → users |
| recipient_id | UUID | FK → users |
| activity_id | UUID | FK → activities (the shared activity being reacted to) |
| reaction_type | Text | 'emoji' or 'message' |
| reaction_value | Text | '🔥', '💪', '👏', '⭐', '🤲', 'Keep going!', 'MashAllah!', 'You got this!', 'Proud of you!', 'Stay consistent!' |
| created_at | Timestamp (UTC) | |

Reactions are ephemeral — they generate a notification and are stored for history, but there's no "reaction feed" or conversation thread.

#### FAB

Always visible. Same behavior as all other screens. See §7.

---

### 14.7 Onboarding Flow

The onboarding flow introduces new users to Kitab and sets them up with activities so they don't face a cold start. It should be completable in under 60 seconds for users who tap through quickly, and ~45-60 seconds for users who engage with each step.

#### When Onboarding Runs

| Platform | Trigger | Auth Required? |
|----------|---------|---------------|
| Native (first install) | App opened for the first time | No |
| Native (returning) | Never — onboarding is a one-time experience per install | N/A |
| Web (first sign-in) | After account creation or first sign-in | Yes (account required on web) |
| Re-run | Settings → About → "Re-run Setup" | Optional |

Onboarding state is tracked in `local_meta` (native) or user settings (cloud). If not completed, onboarding shows on every app open until completed or explicitly skipped.

#### Flow — Native App

#### Screen 0 — Splash (2-3 seconds, auto-advances)

```
┌─────────────────────────────────────┐
│                                     │
│         [Kitab logo]                │
│                                     │
│   Your living book of deeds         │
│                                     │
│    [Islamic geometric pattern       │
│     animation — subtle, brief]      │
│                                     │
└─────────────────────────────────────┘
```

App logo, tagline, brief geometric pattern animation. Auto-advances. No button needed.

#### Screen 0.5 — Returning User Check

```
┌─────────────────────────────────────┐
│                                     │
│         [Kitab logo]                │
│                                     │
│   Welcome to Kitab                  │
│                                     │
│   Already have an account?          │
│                                     │
│       [Sign In]                     │
│                                     │
│   ── or ──                          │
│                                     │
│   [Get Started]                     │
│                                     │
└─────────────────────────────────────┘
```

- **Sign In:** Opens the sign-in flow (§15.4). After successful sign-in, data syncs from cloud and user skips to the Home screen. Onboarding is marked as completed.
- **Get Started:** Continues to Screen 1 as a new/anonymous user.

#### Screen 1 — Your Name

```
┌─────────────────────────────────────┐
│                                     │
│   What should we call you?          │
│                                     │
│   [Ahmed____________________]       │
│                                     │
│   This personalizes your            │
│   experience.                       │
│                                     │
│   [Continue]          [Skip]        │
│                                     │
└─────────────────────────────────────┘
```

One field. Optional — "Skip" leaves the name blank (greeting will say "Assalamu Alaikum" or "Good morning" without a name). The name is stored locally and used immediately for the greeting.

#### Screen 2 — Intro Carousel (3 screens, swipeable)

Quick, visual, minimal text. One large illustration and one sentence per screen:

```
Screen 2a:
┌─────────────────────────────────────┐
│                                     │
│    [Illustration: book opening]     │
│                                     │
│   Track your habits, activities,    │
│   and goals in one place.           │
│                                     │
│         · ○ ○        [Skip]         │
└─────────────────────────────────────┘

Screen 2b:
┌─────────────────────────────────────┐
│                                     │
│    [Illustration: streaks/fire]     │
│                                     │
│   Build streaks, discover           │
│   patterns, and grow every day.     │
│                                     │
│         ○ · ○        [Skip]         │
└─────────────────────────────────────┘

Screen 2c:
┌─────────────────────────────────────┐
│                                     │
│    [Illustration: community]        │
│                                     │
│   Share progress with friends       │
│   and compete in challenges.        │
│                                     │
│         ○ ○ ·        [Next]         │
└─────────────────────────────────────┘
```

Dot pagination at bottom. "Skip" on first two screens, "Next" on the last.

#### Screen 3 — Islamic Personalization

```
┌─────────────────────────────────────┐
│                                     │
│   Personalize Your Experience       │
│                                     │
│   Kitab draws inspiration from      │
│   Islamic tradition. Would you      │
│   like Islamic personalization?     │
│                                     │
│   This includes:                    │
│   • Islamic greetings               │
│   • Hijri calendar dates            │
│   • Prayer time tracking            │
│   • Ramadan insights                │
│                                     │
│   [Yes, enable]                     │
│   [No thanks]                       │
│                                     │
│   You can change this anytime       │
│   in Settings.                      │
│                                     │
└─────────────────────────────────────┘
```

**If "Yes":** Enables Islamic personalization + Hijri calendar in settings. Immediately requests **location permission** with context: "Kitab needs your location to calculate prayer times for your area." If granted, prayer times are computed. If denied, fallback fixed times are used.

**If "No":** Both settings stay off. No location permission requested. User can enable later.

#### Screen 4 — Choose Starting Activities

```
┌─────────────────────────────────────┐
│                                     │
│   What would you like to track?     │
│                                     │
│   Pick a few to get started.        │
│   You can always add more later.    │
│                                     │
│   ── Popular ──                     │
│                                     │
│   [✓] 💧 Drink Water (daily)       │
│   [ ] 🏃 Exercise (3x/week)        │
│   [✓] 📖 Read (daily)              │
│   [ ] 😴 Track Sleep               │
│   [ ] 📝 Journal (daily)            │
│                                     │
│   ── Spiritual ──                   │
│   (only if Islamic enabled)         │
│                                     │
│   [✓] 🕐 Pray on Time (5x/day)    │
│   [ ] 📖 Read Quran (daily)        │
│   [ ] 🤲 Morning Athkar            │
│   [ ] 🤲 Evening Athkar            │
│   [ ] 📿 Dhikr Counter             │
│                                     │
│   ── Health ──                      │
│                                     │
│   [ ] ⚖️ Track Weight              │
│   [ ] 🧘 Meditate (daily)          │
│   [ ] 💊 Take Medication           │
│                                     │
│   ── Productivity ──                │
│                                     │
│   [ ] 📚 Study (daily)             │
│   [ ] 💻 Deep Work (daily)         │
│   [ ] 📋 Plan Tomorrow (daily)     │
│                                     │
│   Selected: 3 activities            │
│                                     │
│   [Continue with 3 activities]      │
│   [Skip — I'll set up my own]       │
│                                     │
└─────────────────────────────────────┘
```

Each template is pre-configured with sensible defaults (schedule, fields, a basic goal). The user checks the ones they want — no configuration needed. They can customize later in Settings → My Activities.

**A few pre-selected by default** (Drink Water, Read, and Pray on Time if Islamic enabled) to nudge toward adoption.

"Spiritual" section only appears if Islamic personalization was enabled on Screen 3.

Selected count shown at bottom. "Skip" starts with zero activities (empty Home screen with empty state).

These templates are a curated subset of the full template library available in Settings → My Activities.

#### Screen 4.5 — Routine Suggestion (Conditional)

Only shown if the user selected 3+ activities that are commonly grouped into a routine (e.g., multiple spiritual activities that form a morning routine):

```
┌─────────────────────────────────────┐
│                                     │
│   Want a Morning Routine?           │
│                                     │
│   You selected activities that      │
│   work great together:              │
│                                     │
│   ☀️ Morning Routine                │
│   1. Pray on Time (Fajr)            │
│   2. Read Quran                     │
│   3. Morning Athkar                 │
│                                     │
│   A routine lets you flow through   │
│   activities one by one with a      │
│   single start.                     │
│                                     │
│   [Add this routine]                │
│   [Skip]                            │
│                                     │
└─────────────────────────────────────┘
```

If fewer than 3 related activities were selected, this screen is skipped.

#### Screen 5 — You're Ready

```
┌─────────────────────────────────────┐
│                                     │
│      [Geometric pattern             │
│       celebration animation]        │
│                                     │
│   Your Kitab is ready!              │
│                                     │
│   3 activities and 1 routine        │
│   added to your book.               │
│                                     │
│   ┌─────────────────────────────┐   │
│   │ 💡 Your data is saved on    │   │
│   │ this device. Create an      │   │
│   │ account anytime to sync     │   │
│   │ across devices and connect  │   │
│   │ with friends.               │   │
│   └─────────────────────────────┘   │
│                                     │
│   You'll stay signed in             │
│   automatically. Just open Kitab    │
│   and start tracking.              │
│                                     │
│   [Start Your Journey]              │
│                                     │
└─────────────────────────────────────┘
```

Brief celebration. Summary of what was set up. Account tip as a subtle card (not a prompt). "Start Your Journey" → Home screen.

#### Flow — Web App

Web users must authenticate first (landing page with Sign In / Create Account). After creating an account:

1. **Skip Screen 0.5** (already authenticated)
2. **Screen 1** — Your Name (pre-filled from account creation if provided)
3. **Screen 2** — Intro Carousel
4. **Screen 3** — Islamic Personalization (no location permission on web — uses browser geolocation later if needed)
5. **Screen 4** — Choose Starting Activities
6. **Screen 4.5** — Routine Suggestion (if applicable)
7. **Screen 5** — You're Ready (no account tip — they already have one. Instead show: "You'll stay signed in automatically. Just open Kitab and start tracking.")

#### Session Persistence

Users should never have to re-authenticate just to log an activity. The app stays signed in automatically.

**Native (iOS/Android):**
- Auth token stored in secure platform storage (iOS Keychain, Android EncryptedSharedPreferences)
- Token refreshes automatically via Supabase Auth
- Opening the app goes straight to the Home screen — no sign-in screen
- Session persists until the user explicitly signs out or the account is deleted/revoked
- Anonymous users (no account) always go straight to Home — there's nothing to sign into

**Web:**
- Supabase session persists across browser sessions via the Supabase JS client
- Opening app.kitab.com lands on the Home screen directly if session is valid
- Session persists until explicit sign-out, session expiry (Supabase default refresh token lifetime), or cookie/storage cleared

**Optional biometric lock (native only):**
- Settings → Account → "Require Face ID / Touch ID / Fingerprint to open"
- When enabled, app launch prompts for biometric before showing data
- If biometric fails, falls back to password entry
- Default: OFF (no lock — app opens directly)
- Useful for shared devices or users with sensitive data

**Re-authentication required only when:**
- User explicitly signed out
- Account was deleted on another device
- Password was changed on another device (token revoked)
- Refresh token expired (rare — typically 1 week+ depending on Supabase config)

#### Permissions — Contextual Requests

Permissions are requested in context when the user first needs them, NOT in a bulk permissions screen during onboarding.

| Permission | When Requested | Context Message |
|-----------|---------------|----------------|
| Location | Screen 3 (Islamic personalization) OR first use of Location field | "Kitab needs your location to calculate prayer times for your area" / "Allow location access to pin your current location" |
| Notifications | After onboarding, as a card on the Home screen on second app open | "Turn on reminders so you never miss a streak? [Enable] [Later]" |
| Camera | First attempt to upload a profile photo | Standard system prompt |

If a permission is denied, the app works without it using fallbacks (fixed prayer times, no push notifications, no camera — use photo gallery instead).

#### Onboarding Starter Templates

Pre-configured activity templates offered during onboarding. Each has sensible defaults:

| Template | Category | Schedule | Fields | Goal |
|----------|----------|----------|--------|------|
| 💧 Drink Water | Health & Fitness | Daily | Number (glasses, unit: glasses) | ≥ 8 glasses per day |
| 🏃 Exercise | Health & Fitness | 3x/week | Duration, Yes/No (Completed) | ≥ 3 times per week |
| 📖 Read | Learning | Daily | Duration, Number (pages) | ≥ 1 time per day |
| 😴 Track Sleep | Health & Fitness | Daily | Duration, Star Rating, Mood | ≥ 1 time per day |
| 📝 Journal | Personal | Daily | Text | ≥ 1 time per day |
| 🕐 Pray Fajr | Spiritual | Daily, dynamic window Fajr–Sunrise | Start Time, Yes/No (On Time) | ≥ 1 time per day |
| 🕐 Pray Dhuhr | Spiritual | Daily, dynamic window Dhuhr–Asr | Start Time, Yes/No (On Time) | ≥ 1 time per day |
| 🕐 Pray Asr | Spiritual | Daily, dynamic window Asr–Maghrib | Start Time, Yes/No (On Time) | ≥ 1 time per day |
| 🕐 Pray Maghrib | Spiritual | Daily, dynamic window Maghrib–Isha | Start Time, Yes/No (On Time) | ≥ 1 time per day |
| 🕐 Pray Isha | Spiritual | Daily, dynamic window Isha–Fajr (crosses midnight) | Start Time, Yes/No (On Time) | ≥ 1 time per day |
| 📖 Read Quran | Spiritual | Daily | Duration, Number (pages) | ≥ 1 time per day |
| 🤲 Morning Athkar | Spiritual | Daily (Fajr-Sunrise window) | Yes/No (Completed) | ≥ 1 time per day |
| 🤲 Evening Athkar | Spiritual | Daily (Asr-Maghrib window) | Yes/No (Completed) | ≥ 1 time per day |
| 📿 Dhikr Counter | Spiritual | No schedule | Number (count) | None |
| ⚖️ Track Weight | Health & Fitness | Daily | Number (weight, unit: lbs/kg) | None (standing target) |
| 🧘 Meditate | Health & Fitness | Daily | Duration | ≥ 1 time per day |
| 💊 Take Medication | Health & Fitness | Daily | Yes/No (Taken), Text (notes) | ≥ 1 time per day |
| 📚 Study | Learning | Daily | Duration, Text (subject) | ≥ 1 time per day |
| 💻 Deep Work | Work | Daily | Duration | ≥ 1 time per day |
| 📋 Plan Tomorrow | Productivity | Daily | Yes/No (Completed) | ≥ 1 time per day |

Users can modify any of these after onboarding via Settings → My Activities. The templates use the user's locale for units (lbs vs kg based on region).

#### Routine Suggestion Logic

After Screen 4, the app checks if the selected activities form a natural routine:

**Morning Routine suggestion triggers** when 3+ of these are selected: Pray on Time, Read Quran, Morning Athkar, Meditate, Exercise, Plan Tomorrow.

**Evening Routine suggestion triggers** when 3+ of these are selected: Evening Athkar, Journal, Read, Track Sleep, Plan Tomorrow.

If triggered, Screen 4.5 appears with the suggested routine pre-built from the selected activities. If not triggered, Screen 4.5 is skipped.

---

## 15. Authentication Flow

### 15.1 Account States

| State | Where | Capabilities |
|-------|-------|-------------|
| Anonymous (Guest) | Native only | Full local functionality. No cloud sync, no social features, no web access. |
| Signed in | Native + Web | Full functionality. Cloud sync, social, cross-device access. |
| Signed out (with preserved data) | Native only | App reverts to anonymous mode with last-synced data preserved locally. User can view and edit. On sign-back-in, local changes merge with cloud. |

### 15.2 First Launch (Native)

No sign-up screen, no login wall. The user lands directly on the onboarding flow (or Home screen empty state if onboarding is skipped). The app generates a local anonymous user ID. All data stored in local SQLite. Profile screen shows the Guest card.

**Unavailable features for anonymous users:**
- Cloud sync / backup
- Social features (friends, sharing, competitions)
- Web app access

### 15.3 Create Account

Accessible from: Profile card "Create Account" button, or any prompt where an account is needed (e.g., tapping Social tab).

**Screen 1 — Create Account:**

```
┌─────────────────────────────────────┐
│             Create your             │
│               Kitab                 │
│                                     │
│ Name                                │
│ [________________________]          │
│                                     │
│ Email                               │
│ [________________________]          │
│                                     │
│ Password                            │
│ [••••••••____________] [👁]         │
│                                     │
│ Confirm Password                    │
│ [••••••••____________] [👁]         │
│                                     │
│       [Create Account]              │
│                                     │
│ Already have an account? Sign In    │
│                                     │
│ ── or continue with ──              │
│ [G Google]  [ Apple]               │
└─────────────────────────────────────┘
```

**Fields:**
- Name: required
- Email: required, valid format
- Password: minimum 8 characters, no complexity requirements. Eye icon toggles visibility.
- Confirm password: must match

**Social sign-in:** Google and Apple. Both supported via Supabase Auth. One tap — pulls name and email from the social provider. Skips email verification (already verified by Google/Apple).

**Screen 2 — Email Verification (OTP):**

```
┌─────────────────────────────────────┐
│          Verify your email          │
│                                     │
│ We sent an 8-digit code to          │
│ ahmed@email.com                     │
│                                     │
│ ┌──┬──┬──┬──┬──┬──┬──┬──┐         │
│ │  │  │  │  │  │  │  │  │         │
│ └──┴──┴──┴──┴──┴──┴──┴──┘         │
│                                     │
│ Didn't receive it? Resend           │
│                                     │
└─────────────────────────────────────┘
```

- 8-digit OTP code sent via Resend (configured in Supabase)
- Auto-advances as digits are entered
- Verification is **required** — cannot proceed without it
- "Resend" link with cooldown timer (60 seconds between resends)
- On successful verification → proceed to data migration

**Screen 3 — Data Migration (if anonymous data exists):**

```
┌─────────────────────────────────────┐
│        Welcome, Ahmed!              │
│                                     │
│ Syncing your existing data to       │
│ the cloud...                        │
│                                     │
│      [════════════70%═══]           │
│      128 of 183 records             │
│                                     │
│ Your data will be backed up and     │
│ accessible from any device.         │
│                                     │
└─────────────────────────────────────┘
```

- Shows progress bar with record count
- All local anonymous data gets the new user ID and pushes to Supabase
- On completion: "Sync complete ✓" → navigates to Home screen
- If no anonymous data existed: skip this screen, go directly to Home

### 15.4 Sign In

Accessible from: Profile card "Sign In" button, or any prompt where an account is needed.

```
┌─────────────────────────────────────┐
│            Welcome back             │
│                                     │
│ Email                               │
│ [________________________]          │
│                                     │
│ Password                            │
│ [••••••••____________] [👁]         │
│                                     │
│       [Sign In]                     │
│                                     │
│ Forgot password?                    │
│                                     │
│ ── or continue with ──              │
│ [G Google]  [ Apple]               │
│                                     │
│ Don't have an account? Create one   │
└─────────────────────────────────────┘
```

**After sign-in on native with existing local anonymous data:**
- Merge flow triggers (see §15.6 Sync Conflict Resolution)
- Progress screen shown during merge

**After sign-in on native with no local data:**
- Cloud data pulls down to local SQLite
- Progress: "Loading your data... X records"

**After sign-in on web:**
- No local data to consider. Data loads from Supabase directly.

### 15.5 Forgot Password

```
┌─────────────────────────────────────┐
│         Reset Password              │
│                                     │
│ Enter the email associated with     │
│ your account.                       │
│                                     │
│ Email                               │
│ [________________________]          │
│                                     │
│       [Send Reset Link]             │
│                                     │
│ Back to Sign In                     │
└─────────────────────────────────────┘
```

- Sends a password reset link via Supabase Auth
- Confirmation screen: "Check your email. We sent a reset link to a****@email.com"
- "Resend" link with cooldown
- Reset link opens a Supabase-hosted page for setting a new password

### 15.6 Sync Conflict Resolution

When data from two sources (local + cloud) must be merged, conflicts are resolved per data type:

#### Conflict Resolution Rules

| Data Type | Unique Constraint | Same ID Conflict | Different ID + Same Unique Key | No Overlap |
|-----------|------------------|-----------------|-------------------------------|------------|
| **Categories** | `UNIQUE(user_id, LOWER(name))` | Last-write-wins | Last-write-wins. Cascade: all `activities.category_id` referencing losing ID → updated to winner's ID. All entries under those activities inherit the winning category's icon/color. Losing record deleted. | Union |
| **Activity templates** | `UNIQUE(user_id, LOWER(name))` | Last-write-wins (entire record including versioned schedule/goals) | **Ask user** which version to keep. All entries referencing losing ID → relinked to winner's ID. All period/goal statuses referencing losing ID → deleted and recomputed. Losing record deleted. | Union |
| **Entries** | None | Last-write-wins | N/A | Union |
| **Condition presets** | `UNIQUE(user_id, LOWER(label))` | Last-write-wins | Last-write-wins. All `conditions.preset_id` referencing losing ID → updated to winner's ID. Losing record deleted. | Union |
| **Condition records** | Non-overlapping per preset | Last-write-wins | N/A | Union. If overlapping dates for same preset after merge: merge overlapping records into one (earliest start, latest end or null if either active). All period/goal statuses referencing losing condition ID → updated to winner's. |
| **Period statuses** | `UNIQUE(activity_id, period_start, period_end)` | Last-write-wins | **Recomputed from entries.** User-set statuses (excused, missed) preserved. System-computed statuses (completed, pending) recomputed from merged entry data. | Union |
| **Goal statuses** | `UNIQUE(activity_id, goal_id, period_start, period_end)` | Last-write-wins | **Recomputed from entries.** User-set excuses preserved. System-computed (met, not_met) recomputed from merged entries using winning template's goals. | Union |
| **Settings / Profile** | One per user | Last-write-wins | N/A | N/A |
| **Friends** | `UNIQUE(user_id, friend_id)` | Last-write-wins | Most advanced status wins (accepted > pending > declined) | Union |
| **Activity shares** | Per activity + friend | Last-write-wins | Updated to winning template ID after template resolution | Union |
| **Competitions** | `UNIQUE(competition_id, user_id)` for participation | Last-write-wins | N/A | Union |
| **Competition entries** | None | Last-write-wins | N/A | Union |
| **Notifications** | None | N/A | N/A | Clear all and regenerate |

**Key distinction for period/goal statuses:** 'excused' and 'missed' are **user decisions** — the user deliberately set these. 'completed', 'pending', 'met', 'not_met' are **system-computed** from entry data. During merge, user decisions are preserved; system-computed statuses are recomputed from the merged entries to ensure accuracy.

**Template versioning during merge:** If the winning template has versioned schedules/goals (from "apply to future only" changes), the version history is used as-is for period/goal recomputation. Old periods use the old version's config, new periods use the new version's config. If the losing template had applied retroactive changes (collapsed versions), that intent is lost — the winning template's structure takes precedence.

**Template modified on both devices:** If the same template ID was edited on both devices (detected by comparing `updated_at` from both sources), an informational toast is shown after merge: "[Activity name] was edited on another device. Your latest changes were kept."

#### Merge Algorithm — Execution Order

Dependencies between tables require a specific merge order:

```
Step 1: Merge settings/profile (last-write-wins)
Step 2: Merge categories (resolve name conflicts, cascade IDs to activities)
Step 3: Merge condition presets (resolve label conflicts, cascade IDs to conditions)
Step 4: Merge activities/templates
        - Same ID: last-write-wins
        - Different IDs, same name: ASK USER (pause merge for resolution)
        - Cascade: relink entries, delete losing period/goal statuses
Step 5: Merge condition records (resolve date overlaps within same preset, cascade IDs)
Step 6: Merge entries (union + last-write-wins on same ID)
Step 7: Recompute period statuses from merged entries
        - Use winning template's schedule versions for period computation
        - Preserve user-set statuses (excused, missed)
        - Recompute system statuses (completed, pending) from entry data
Step 8: Recompute goal statuses from merged entries
        - Use winning template's goal versions for evaluation
        - Preserve user-set excuses
        - Recompute met/not_met from entry data
Step 9: Merge friends (most advanced status wins for same user pair)
Step 10: Merge activity shares (cascade to winning template IDs)
Step 11: Merge competitions + participants + entries (union + last-write-wins)
Step 12: Clear and regenerate notifications
```

Steps 7-8 are **recomputation, not merge** — they derive correct statuses from the merged data rather than trying to reconcile two possibly stale status sets.

#### Template Conflict Resolution UI

When duplicate activity template names are detected during merge (Step 4), the sync pauses and presents each conflict:

```
┌─────────────────────────────────────┐
│       Resolve Duplicates            │
│                                     │
│ You have two versions of            │
│ "Morning Run"                       │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ Version A (this device)         │ │
│ │ Daily · 3 fields · 2 goals     │ │
│ │ 45 entries                      │ │
│ │ Last edited: Apr 1, 2026       │ │
│ │ Last record: Apr 3, 2026       │ │
│ └─────────────────────────────────┘ │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ Version B (cloud)               │ │
│ │ Daily · 4 fields · 1 goal      │ │
│ │ 12 entries                      │ │
│ │ Last edited: Mar 28, 2026      │ │
│ │ Last record: Mar 30, 2026      │ │
│ └─────────────────────────────────┘ │
│                                     │
│ All entries from both versions      │
│ will be linked to the one you       │
│ choose.                             │
│                                     │
│   [Use Version A]  [Use Version B]  │
└─────────────────────────────────────┘
```

**Each version shows:**
- Source label ("this device" or "cloud")
- Schedule summary (Daily, Weekly, etc.)
- Field count + goal count
- Entry count (how many entries are linked to this version)
- Last edited (when the template configuration was last modified)
- Last record (when the most recent entry linked to this template was logged)

If multiple template conflicts exist, they are presented sequentially. After all are resolved, the merge continues from Step 5.

**All other conflicts** (categories, condition presets, condition records, friends, etc.) are resolved silently — no user prompt needed.

#### Merge Summary

After merge completes:

- **No conflicts:** Toast "Sync complete ✓"
- **Silent merges happened:** Toast "Sync complete. X new records synced."
- **Template conflicts were resolved:** Toast "Sync complete. Activities merged successfully."
- **Template modified on both devices (same ID):** Toast "[Activity name] was edited on another device. Your latest changes were kept."

### 15.7 Sign Out

When the user signs out on a native device:
- Local data from the last sync is **preserved** on the device
- The app reverts to anonymous mode — user can continue viewing and editing local data
- Profile screen shows the Guest card
- Sync stops (no cloud connection)
- If the user signs back in later, any local changes made while signed out are merged with cloud using the same conflict resolution rules (§15.6)

On web: sign out redirects to the sign-in screen. No local data to preserve.

### 15.8 Delete Account

Specced in §14.4 Profile → Account:
- Confirmation: type "DELETE"
- All cloud data is permanently deleted
- Local data on the current device is preserved (app reverts to anonymous mode)
- If the user opens the app on another device that was signed in: auth error detected → "Your account has been deleted. Your local data is still available on this device." → revert to anonymous mode

### 15.9 Change Email

- User enters new email in Profile → Account
- 8-digit OTP verification sent to the **new** email address
- Email is only changed after successful verification
- If verification is abandoned, the old email remains

### 15.10 Web App — Account Required

The web app shows a sign-in / create-account screen as the landing page. No anonymous mode on web. After authentication, data loads from Supabase directly (no local DB).

```
┌─────────────────────────────────────┐
│                                     │
│            [Kitab logo]             │
│                                     │
│     Your living book of deeds       │
│                                     │
│       [Sign In]                     │
│       [Create Account]             │
│                                     │
│ ── or continue with ──              │
│ [G Google]  [ Apple]               │
│                                     │
└─────────────────────────────────────┘
```

---

## 16. Security

### 16.0 Private Activities

Activities and routines can be marked as **Private** — their names and details are visually blurred throughout the app to protect sensitive information from casual onlookers.

#### Configuration

In the activity template editor or routine editor (Settings → My Activities / My Routines → Edit):

```
── Privacy ──

Mark as Private                    [off ○─]

When enabled, this activity's name and
details are blurred throughout the app.
Tap to temporarily reveal. Notifications
will use a generic message.
```

Database: `is_private` boolean column on `activities` and `routines` tables (default false). Syncs normally across devices.

#### What Gets Blurred

- Activity/routine name
- Category name and icon (when shown inline with the activity)
- Field values and metric data
- Notes
- Goal descriptions
- Entry details and subtitles (duration, pages, metric values)

#### What Stays Visible

- Status icon (○ ✓ ? ⊘ —) — user needs to see the state
- Streak badge (🔥 12d) — a number alone doesn't identify the activity
- Category color (left border in Book) — subtle, doesn't identify the specific activity
- Time displays on timers — user needs to see elapsed time
- Aggregate stats in Insights — the activity contributes to totals without being named

#### Per-Screen Behavior

| Screen | Blurred Elements | Reveal |
|--------|-----------------|--------|
| **Home — Scheduled Today** | Activity name, subtitle, category line | Tap card to reveal temporarily |
| **Home — Needs Attention** | Activity name, expected date/time | Tap card to reveal |
| **Home — Condition chips** | Not affected (conditions aren't tied to specific activities) | N/A |
| **Book — Entry cards** | Activity name, category, field values, notes | Tap card to reveal |
| **Book — Condition filter** | Not affected | N/A |
| **Insights — Dashboard** | Activity names in category breakdown, rankings, trends, patterns. Patterns use "a private activity" instead of the name. | Tap individual items to reveal |
| **Insights — My Charts** | Charts using private activity as data source: axis labels and legends blurred | Tap chart to reveal |
| **Mini-timer widget** | Activity name | Tap widget to open form (reveals in form) |
| **Routine flow** | The private activity's step within the routine is blurred. Routine name itself is NOT blurred (unless the routine is also marked private). | Tap the step to reveal |
| **Notifications — Push (native)** | Title uses generic text: "Activity reminder" or "Streak update". No activity name in the push. | Opening the in-app notification reveals the name |
| **Notifications — In-app** | Description uses generic text until tapped: "A private activity needs attention." | Tap to reveal |
| **Profile — Activity Detail View** | All content blurred until revealed | Tap to reveal |

#### Reveal Mechanisms

**Individual reveal (tap):** Tap a blurred card/element → it reveals. Stays revealed until the user navigates away from the current screen. Next visit to that screen, it's blurred again. No timer-based auto-hide.

**Reveal all (double-tap Kitab title):** Double-tapping the "Kitab" title on the Home screen app bar toggles all private activities visible/hidden globally. The reveal persists until:
- The app is backgrounded / minimized (native)
- The user switches to another app (native)
- The browser tab/window is switched or closed (web)
- The user double-taps the title again to re-hide

When the app regains focus after being backgrounded, private activities are automatically re-blurred. This ensures that if someone picks up the user's phone, private activities are hidden.

Toast feedback on double-tap:
- Reveal: "Private activities revealed"
- Re-hide: "Private activities hidden"

#### Sharing Private Activities

Privacy and sharing are **independent concepts:**
- **Sharing** = I choose to let a friend see my activity data
- **Privacy** = I choose to blur it on MY device

Private activities **CAN be shared** with friends. The privacy feature hides from casual onlookers on the user's own device — it does not restrict social sharing. If the user chooses to share "Intimacy with Spouse" with their wife, the wife sees the activity normally on her device.

Private activities CAN be used in competitions if the user chooses.

**Recipient-side privacy:** When a friend shares an activity with you, you can independently mark it as private **on your device.** This blurs the shared activity in your Social → Friend Detail view using the same blur treatment. This does not affect how it appears on the sharer's device.

Database: `is_private_for_viewer` boolean column on `activity_shares` table (default false). Set by the recipient, not the sharer.

#### Export

Exported data (JSON/CSV) includes private activities with full details. The export is for the user's own use.

### 16.1 Database Security — Row Level Security (RLS)

All Supabase tables have RLS enabled. No table is accessible without a valid policy. This is the primary defense against unauthorized data access.

**Policy rules:**
- Users can only read, create, update, and delete their own records (`user_id = auth.uid()`)
- Social tables (friends, activity_shares) have expanded read policies for accepted friends
- Competition tables have read policies for all participants in the same competition
- Public competitions are readable by any authenticated user
- No anonymous access to cloud data — authentication required for all Supabase operations

**Critical implementation rules:**
- RLS policies are applied at the database level, not the application level — even if client code is bypassed, the database rejects unauthorized operations
- Every new table MUST have RLS enabled before any data is inserted
- RLS policies are tested with multiple user accounts during development to verify isolation

### 16.2 Input Validation

All user-provided text is validated on both client (Flutter) and server (Supabase/Postgres):

| Field | Max Length | Validation |
|-------|-----------|------------|
| Activity name | 100 chars | Required. Trimmed. No leading/trailing whitespace. |
| Category name | 50 chars | Required. Trimmed. Case-insensitive uniqueness check. |
| Condition preset label | 50 chars | Required. Trimmed. Case-insensitive uniqueness check. |
| Entry name | 100 chars | Required. Defaults to "Untitled" if empty. |
| Description | 500 chars | Optional. |
| Bio | 150 chars | Optional. |
| Notes | 5,000 chars | Optional. |
| Text field (custom metric) | 5,000 chars | Optional. |
| User name | 100 chars | Required for account creation. |
| Email | 254 chars | Valid email format. |
| Password | 8–128 chars | Minimum 8 characters. |

**Sanitization:**
- All text is stored as plain text, never rendered as HTML. Flutter's Text widget does not interpret HTML, so XSS via rendered content is not a risk on native.
- On web, any user-generated text displayed in the UI uses Flutter's text rendering (which escapes by default) — not raw HTML injection.
- JSONB values (`field_values`, `schedule`, `goals`, `settings`) are serialized/deserialized through Dart's `jsonEncode`/`jsonDecode` which handle escaping. Malformed JSON is rejected at the parsing level before reaching the database.

**Emoji and special characters:** Allowed in all text fields. The database uses UTF-8 encoding. No character blacklisting — just length limits.

### 16.3 Authentication & Token Security

**Supabase Auth handles:**
- JWT token issuance, refresh, and revocation
- Password hashing (bcrypt) — plaintext passwords are never stored
- OAuth flows for Google and Apple sign-in
- Email OTP verification

**Token storage:**
- **Native (iOS/Android):** JWT stored in platform-secure storage (iOS Keychain, Android EncryptedSharedPreferences). Never in plain SharedPreferences or local SQLite.
- **Web:** JWT stored in memory (Supabase JS client default). Not in localStorage or cookies to prevent XSS token theft.

**Token refresh:** Supabase handles automatic token refresh. If a refresh fails (e.g., token revoked after account deletion), the app detects the auth error and reverts to anonymous mode.

**Session timeout:** Sessions do not auto-expire while the refresh token is valid. Supabase's default refresh token lifetime is used (typically 1 week). The user stays signed in until they explicitly sign out or the refresh token expires.

### 16.4 Data Encryption

**In transit:** All communication between the app and Supabase uses HTTPS/TLS. No plaintext HTTP. Supabase enforces TLS on all connections.

**At rest (cloud):** Supabase uses encrypted storage at the infrastructure level (AES-256). The app does not implement additional application-level encryption.

**At rest (local/native):** SQLite data on the device is not encrypted by default. For V1 this is acceptable — the device's own security (passcode, biometrics) protects local data. Application-level SQLite encryption (using `sqlcipher`) can be added in V2 if required for compliance.

### 16.5 JSONB Safety

Several tables store JSONB: `schedule`, `fields`, `goals`, `field_values`, `settings`, `timer_segments`, `action_data`, `activity_config`, `rules`.

**Risks:**
- Oversized JSONB payloads consuming storage/memory
- Deeply nested structures causing parsing performance issues
- Unexpected keys or types breaking the application

**Mitigations:**
- Maximum JSONB payload size enforced at the application level: 100KB per field. Supabase/Postgres can also enforce this via check constraints.
- The app defines strict TypeScript/Dart types for each JSONB structure. Unknown keys are ignored (not rejected — for forward compatibility), but required keys are validated.
- JSONB fields are never constructed by string concatenation — always through structured serialization (`jsonEncode` in Dart, Supabase client SDK for writes).
- No user-provided text is interpreted as a JSONB key — field IDs are system-generated UUIDs, not user-typed strings.

### 16.6 Rate Limiting

**Supabase built-in rate limiting:** Supabase applies rate limits on auth endpoints (sign-up, sign-in, password reset) to prevent brute-force attacks. Default limits are sufficient for V1.

**Application-level considerations:**
- Sync queue processing: max 100 records per sync batch to prevent one user from overloading the API
- Entry creation: no hard rate limit (a user legitimately logging "Drink Water" 8 times a day should not be blocked), but monitor for abuse patterns
- Competition entries: one entry per user per logged_at timestamp — prevents rapid-fire duplicate submissions

**V2 enhancement:** If the app scales, implement API rate limiting via Supabase Edge Functions or a reverse proxy (e.g., Cloudflare) to protect against abuse.

### 16.7 Social & Competition Security

**Friends:**
- Friend requests require authentication — no anonymous access
- A user can only see activity data that has been explicitly shared with them via `activity_shares`
- Unfriending immediately revokes access to shared activity data

**Competitions:**
- Private competitions: only participants can see entries and leaderboards
- Public competitions: any authenticated user can view but must join to submit entries
- Competition entries are validated server-side — the entry's field values must match the competition's `activity_config` structure
- The competition creator can remove participants but cannot modify their entries
- Participants can only modify/delete their own entries

**Profile visibility:** Controlled by user setting (friends only, anyone, nobody). The RLS policy on the `users` table enforces this — if set to "friends only," non-friends cannot query that user's name, avatar, or bio from the API.

### 16.8 Local Data Security (Native)

- SQLite database is stored in the app's private directory (sandboxed by iOS/Android)
- Other apps cannot access Kitab's local data
- If the user uninstalls the app, local data is deleted by the OS
- Sync queue payloads may contain sensitive data (entries, settings) — they are stored in the same sandboxed SQLite, not in temporary/shared directories
- Exported data files (JSON/CSV) are generated in a temporary directory and shared via the system share sheet — the app does not persist exported files

### 16.9 Development Security Practices

- **No hardcoded secrets** in the codebase. Supabase URL and anon key are stored in environment configuration (not committed to git). Service role key is never used in the client.
- **Dependency scanning** before release — check for known vulnerabilities in Flutter packages
- **Supabase service role key** is only used in Edge Functions (server-side), never in the client app. The client only uses the anon key + user JWT.
- **No debug logging of sensitive data** in production builds. Auth tokens, passwords, and personal data are never logged.

---

## 17. Technical Implementation Details

### 17.1 Activity Search — Suggestion Ranking

When the user types in any activity search field (FAB quick logs, expanded entry form, Book search), suggestions are ranked:

1. **Most recently logged** — activities with the most recent entry appear first
2. **Most frequently logged** — higher total entry count ranks higher
3. **Alphabetical** — tiebreaker for equal recency and frequency

**Display:** Maximum 5 suggestions shown below the text field, filtered in real-time as the user types. Beginning-of-word matches are prioritized over mid-word matches (typing "Mor" ranks "Morning Run" above "Good Morning Routine").

### 17.2 Error Handling

**Network errors:**
- Action failures (save, sync): toast with "Retry" action — "Couldn't save. Check your connection. [Retry]"
- No full-screen error pages — the app works offline on native
- Web: alert banner at top when connection drops — "You're offline. Changes can't be saved." Auto-dismisses when connection returns.

**Validation errors:**
- Inline, field-level. The offending field gets an Error border (red) + error message below in Body Small
- Save button highlights the first invalid field and scrolls to it — no dialog
- Examples: "Activity name is required", "This name is already taken", "Password must be at least 8 characters"

**Data corruption:**
- If an entry references a deleted activity: treat as unlinked (null activity_id). Log for debugging, no user-facing error.
- If local SQLite is corrupted: offer "Reset local data and sync from cloud" in Settings → Data & Storage. Wipes local DB and pulls fresh from Supabase.

### 17.3 Loading States

**Skeleton screens** shown immediately on screen load, replaced when data arrives:
- **Home:** Skeleton summary card (rectangle + circle for ring) + 3–4 skeleton activity cards. Shimmer animation.
- **Book:** Skeleton day separator + 3–4 skeleton entry cards with left border placeholder. Shimmer.
- **Profile:** Skeleton avatar circle + text lines. Shimmer.
- **Insights/Social:** Skeleton chart placeholders + card placeholders. Shimmer.

All use the shimmer animation defined in §4 Component Library (left-to-right gradient sweep, 1.5s loop).

**Pull-to-refresh:** Primary color circular spinner at top of scroll area.

**Button loading:** Spinner replaces button text while action processes. Button disabled during loading.

**Data-heavy operations** (export, import, merge): Progress bar with record count.

### 17.4 Accessibility

**Screen reader labels:**
- Activity cards: "[Activity name], [status], streak [X] days"
- Status icons: text alternatives — "completed", "in progress", "pending", "excused", "missed"
- Progress ring: "[X] of [Y] goals met today"
- Star rating: "[X] out of 5 stars"
- Mood: "Mood: [label]" (e.g., "Mood: Good")
- Timer: "[Activity name] timer, [elapsed time], [running/paused]"
- FAB: "Log activity, button"
- Condition chip: "[Condition name], day [X], button. Double tap to edit. Swipe to end."

**Focus order:** Top-to-bottom, left-to-right. Tab key (web) moves through interactive elements in visual order. Bottom nav/icon rail always reachable.

**Touch targets:** Minimum 44×44px (iOS) / 48×48dp (Android). Already defined in §3.

**Dynamic text:** All text scales with system font size settings. Layouts reflow — no clipping, no overflow hidden on text. Tested at 200% system font scale.

**Reduced motion:** System "Reduce Motion" disables: shimmer animations, slide transitions (replaced with crossfade), streak celebration particles, FAB arc animation (instant show/hide), timer segment animations. Haptics unaffected.

**High contrast:** System high contrast mode triggers: WCAG AAA (7:1 ratio) on all text, 2px borders (up from 1.5px), higher saturation semantic colors. Defined in §3.

**Color independence:** No information conveyed by color alone — every color signal paired with icon, label, or pattern.

### 17.5 Push Notifications (Native)

**iOS:**
- Standard notification banner / lock screen / notification center
- Tap deep-links to relevant screen (Home for activity reminders, Social for friend requests, Competition detail for updates)
- Action buttons on reminders: "Log Now" (opens entry form for that activity), "Dismiss"
- Badge count on app icon = number of in-app notifications. Clears when Notifications screen is opened.

**Android:**
- Standard notification with icon, title, description
- Same deep-linking behavior as iOS
- Notification channels: "Activity Reminders", "Streaks", "Social", "System" — per-channel management in Android settings
- No badge count (launcher-dependent)

**Web (browser notifications):**
- Only if user grants permission
- Permission request on first sign-in with explanation of what they'll receive
- Click focuses browser tab and navigates to relevant screen

**Independence:** Push notifications and in-app notifications are independent systems. Dismissing a push does not dismiss the in-app card. Tapping a push that triggers an action also deletes the corresponding in-app notification.

### 17.6 Schema Migrations

**Cloud (Supabase):** Migrations applied server-side via Supabase migration files. The cloud schema is always the latest version.

**Backward compatibility rules:**
- Only add columns/tables — never remove or rename in production
- New columns always have default values so old data isn't broken
- Deprecated columns are ignored in code but not dropped from the schema

**Local (Drift/SQLite):** Each app version defines a schema version number. On launch, Drift detects outdated schema and runs migration scripts sequentially (e.g., v1→v2: add `name` column to entries; v2→v3: add `notifications` table).

**Migration failure:** Show error screen with "Contact Support" option + "Export Data" button so the user can save their data before troubleshooting.

### 17.7 Edge Functions (Supabase)

Minimal for V1 — logic runs client-side where possible:

1. **Notification generation (scheduled cron):** Runs hourly. Checks all users for: streak-at-risk (pending activity that would break a streak before midnight), reminder-to-log (pending activities at user's configured reminder time), condition reminders (active conditions exceeding user's reminder interval). Creates `notifications` rows + triggers push via APNs/FCM.

2. **Competition leaderboard computation:** Database trigger on `competition_entries` insert/update — recalculates rankings for the competition.

3. **Account deletion cleanup:** Cascades deletion across all tables when a user deletes their account.

Everything else (period computation, goal evaluation, streak calculation, sync) runs on the client.

### 17.8 Prayer Time Caching

- **Compute once per day per location.** On app open, compute all 10 prayer/solar times for today using the user's current GPS coordinates. Cache in memory (Riverpod state).
- **Recompute when location changes significantly** — GPS shift > ~50km (0.5° lat/lng). Handles travel without recomputing on minor GPS fluctuations.
- **Recompute at day boundary** — midnight (Gregorian) or sunset (Hijri) when the current day changes.
- **No server-side caching or external API.** Calculation is pure math (solar position algorithms) — fast enough client-side. No API costs.
- **Historical dates** (viewing past periods in Activity Detail): compute on-demand for the requested date using current location as approximation. If location history were stored (V2), use the historical location instead.
- **Calculation method and madhab** from user settings (e.g., ISNA + Shafi). Applied consistently to all computations.

---

## 18. V2 Roadmap (Deferred Features)

Features deliberately excluded from V1. The V1 architecture is designed to accommodate these without breaking changes.

### 18.1 Health Device Integration

Auto-import data from Apple HealthKit, Google Health Connect, and third-party APIs (Fitbit, Garmin, Withings, etc.) into Kitab entries.

**V1 preparation:** `source` and `external_id` columns added to `entries` and `competition_entries` tables. All V1 entries have `source = null` (treated as 'manual'). V2 will populate these with the source identifier and external record ID to prevent duplicate imports.

**V2 scope:**
- Settings → Integrations screen for connecting health sources
- Per-field import mapping on activity templates: "Import 'weight' from Apple Health → Body Mass"
- Auto-entry creation when new data arrives from connected sources
- Background sync from health sources (added to existing sync triggers)
- Unit conversion system (kg ↔ lbs, km ↔ miles, etc.)
- Competition anti-cheat: verified source badges on leaderboard entries, optional "verified sources only" competition rule

### 18.2 Other V2 Features

- **Apple Watch companion app** — native Swift/SwiftUI, notifications + quick actions
- **AI chatbot for data queries** — natural language questions about user's data (like Whoop)
- **Multi-activity comparison charts** — plot two activities on the same axes
- **Chart export** — save charts as image/PDF
- **Reports** — group charts into shareable reports
- **Email delivery** — email exports and reports to the user
- **Auto-scheduled exports** — monthly backup to cloud storage
- **Team competitions** — group-based challenges
- **Community template library** — share and browse activity templates
- **SQLite encryption** — application-level encryption using sqlcipher for compliance
- **Location history** — store GPS coordinates over time for historical prayer time accuracy
