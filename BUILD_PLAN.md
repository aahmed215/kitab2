# Kitab V1 — Build Plan

> **Last Updated:** April 6, 2026
> **Estimated Duration:** 8-10 weeks
> **Prerequisites:** Flutter 3.41+, Xcode, Android Studio, Supabase project configured

---

## Phase 1 — Foundation (Week 1)

### Step 1.1: Flutter Project Setup
- [ ] Create Flutter project with iOS, Android, and Web targets
- [ ] Configure bundle ID / package name: `com.mykitab.kitab`
- [ ] Set up folder structure per §24 of SPEC (core/, config/, data/, engines/, features/, providers/, services/)
- [ ] Install all Flutter packages (see SPEC §31 Dependencies)
- [ ] Configure `.env` file with Supabase URL + publishable key (gitignored)
- [ ] Initialize Supabase client (`supabase_flutter`)
- [ ] Set up `go_router` for navigation
- [ ] Create `.gitignore` entries for `.env`, build artifacts, platform secrets

### Step 1.2: Design System Implementation
- [ ] Create `KitabTheme` with all color tokens (Primary, Accent, Neutrals, Semantic)
- [ ] Set up typography (DM Serif Display, Inter, JetBrains Mono, Amiri via `google_fonts`)
- [ ] Define spacing scale constants (xs through 3xl)
- [ ] Define border radii constants
- [ ] Define shadow/elevation constants
- [ ] Create light and dark theme variants
- [ ] Create `SystemAutoThemeProvider` (follows device setting)
- [ ] Implement Islamic geometric pattern as reusable widget (SVG or custom paint)

### Step 1.3: Core Reusable Components
- [ ] `KitabButton` — primary, secondary, tertiary, icon variants with all states
- [ ] `KitabCard` — standard card with optional category color left border
- [ ] `KitabBottomSheet` — standard bottom sheet wrapper (drag handle, dismiss)
- [ ] `KitabTextField` — text input with label, error state, prefix/suffix
- [ ] `KitabDateTimePicker` — custom date/time/timezone picker (3 segments)
- [ ] `KitabToggle` — on/off switch in Primary color
- [ ] `AdaptiveLayoutWrapper` — detects phone/tablet/desktop and renders appropriate layout
- [ ] Bottom Navigation Bar component (5 tabs: Home, Book, Insights, Social, Profile)
- [ ] Icon Rail component (56px, for tablet/web desktop)
- [ ] `KitabFAB` — floating action button with arc speed dial animation

### Step 1.4: Supabase Schema
- [ ] Create all database tables via SQL (users, categories, activities, entries, etc. — 20+ tables)
- [ ] Add all uniqueness constraints (case-insensitive names, user pairs, etc.)
- [ ] Add all foreign key relationships
- [ ] Add `deleted_at` column to all synced tables
- [ ] Enable RLS on all tables
- [ ] Create RLS policies (users can only access own data, social policies for friends)
- [ ] Create storage bucket policies (avatars)
- [ ] Run `get_advisors` to check for security/performance issues
- [ ] Verify schema matches SPEC §12 exactly

### Step 1.5: Core Data Models (Dart)
- [ ] Create all data model classes using `freezed` + `json_serializable`
- [ ] Models: User, Category, Activity, Entry, Condition, ConditionPreset, Routine, RoutineEntry
- [ ] Models: ActivityPeriodStatus, GoalPeriodStatus, RoutinePeriodStatus
- [ ] Models: Friend, ActivityShare, Competition, CompetitionEntry, Notification, Reaction, UserChart
- [ ] Models: SyncQueueItem, LocalMeta
- [ ] JSONB models: ScheduleConfig, ScheduleVersion, FieldDefinition, GoalDefinition, GoalVersion, TimerSegment
- [ ] Ensure all models serialize/deserialize correctly to/from JSON

#### Testing — Phase 1
Once complete, you should be able to:
- [ ] **Run the app** on iPhone, Android, iPad, and Chrome — see a blank app with the correct theme colors (teal primary, warm white background)
- [ ] **See the bottom navigation bar** with 5 tabs (Home, Book, Insights, Social, Profile) — tapping switches between empty placeholder screens
- [ ] **See the correct fonts** — DM Serif Display for screen titles, Inter for body text
- [ ] **Toggle dark mode** in device settings and see the app switch themes
- [ ] **Verify Supabase connection** — check Supabase dashboard shows the new tables with RLS enabled
- [ ] **Test on all devices:** iPhone (wireless), iPad (wireless), Samsung (USB), Chrome browser, and resize Chrome window to see responsive layout changes

---

## Phase 2 — Core Engines (Week 2-3)

### Step 2.1: Local Database (Drift)
- [ ] Define all Drift tables mirroring Supabase schema
- [ ] Create DAOs for each table (CRUD operations)
- [ ] Set up database initialization and schema version
- [ ] Create sync_queue table (local only)
- [ ] Create local_meta table (local only)
- [ ] Test local read/write operations

### Step 2.2: Repository Layer
- [ ] Create repository interfaces for each entity (ActivityRepository, EntryRepository, etc.)
- [ ] Implement Supabase data source (for web / cloud operations)
- [ ] Implement Drift data source (for native / local operations)
- [ ] Create platform-aware repository that routes to correct data source
- [ ] Set up Riverpod providers for all repositories

### Step 2.3: Period Engine
- [ ] Implement period computation for each frequency type:
  - [ ] Daily (Gregorian midnight-midnight, Hijri sunset-sunset)
  - [ ] Weekly (specific days, full week, consecutive ranges)
  - [ ] Monthly (specific days, short month handling — default to last day)
  - [ ] Yearly (specific days/range within a month — Gregorian + Hijri)
  - [ ] Custom Interval (every X days/weeks/months/years)
- [ ] Implement time window computation (specific times)
- [ ] Implement dynamic time window computation (prayer times from API + offset)
- [ ] Implement schedule versioning (use correct version for queried date)
- [ ] Implement "today" definition (always midnight-to-midnight)
- [ ] Cache computed periods in memory (Riverpod)
- [ ] Implement pending detection (create pending status rows)

### Step 2.4: Prayer Time & Hijri Calendar Service
- [ ] Integrate Aladhan API for prayer times
- [ ] Integrate Aladhan API for Hijri calendar conversion
- [ ] Implement caching (1 month per location)
- [ ] Implement location change detection (>50km = refresh)
- [ ] Implement high-latitude adjustment methods
- [ ] Implement offline fallback (cached data, then fixed defaults)
- [ ] Implement dynamic time offset calculation (+/- minutes)
- [ ] Implement Hijri date adjustment (±2 days per user setting)

### Step 2.5: Goal Engine
- [ ] Implement evaluation for each goal type:
  - [ ] Frequency goal (count entries in period)
  - [ ] Value goal (aggregate field values)
  - [ ] Custom goal — most recent entry
  - [ ] Custom goal — aggregated over period
  - [ ] Custom goal — aggregated over last N entries
  - [ ] Custom goal — aggregated over last N days/weeks/months
  - [ ] Custom goal — dynamic target (compare to historical)
  - [ ] Custom goal — consistency layer (pass rate across N periods)
  - [ ] Combined goals (AND / OR logic)
  - [ ] Between / not between comparisons
- [ ] Implement active vs finalized evaluation (in progress vs met/not_met)
- [ ] Implement goal-level reasons (per-goal excuse with condition)
- [ ] Implement goal evaluation caching (invalidation triggers)
- [ ] Implement primary goal designation and display

### Step 2.6: Linkage Engine
- [ ] Implement two-layer linkage (template + period)
- [ ] Implement linkage timestamp priority (Start Time → End Time → logged_at)
- [ ] Implement auto-suggestion of matching period
- [ ] Implement frozen period boundaries on entries
- [ ] Implement "once per period" duplicate warning
- [ ] Implement activity search with suggestion ranking (recency → frequency → alphabetical)

### Step 2.7: Streak Engine
- [ ] Implement per-activity streak calculation (from activity_period_statuses)
- [ ] Implement per-goal streak calculation (from goal_period_statuses)
- [ ] Implement all-goals day streak (daily activities only, primary goal, periods ending before midnight)
- [ ] Implement streak status icons (🔥 active, 🧊 frozen)
- [ ] Implement streak milestones (7, 14, 21, 30, 60, 90, 100, 180, 365)
- [ ] Implement excused = no change (preserved, not advanced)
- [ ] Implement pending = frozen behavior

#### Testing — Phase 2
Once complete, you should be able to:
- [ ] **Create a test activity** via Supabase dashboard (insert directly into DB) and see the period engine compute its periods correctly
- [ ] **Verify prayer times** — check that the Aladhan API returns correct times for your location, and that the Hijri date displays correctly
- [ ] **Test offline mode** — turn off WiFi on your phone, create an entry via code, turn WiFi back on, verify the entry exists locally
- [ ] **Run unit tests** for each engine (period computation, goal evaluation, linkage, streaks) — all should pass
- [ ] **Check Supabase** dashboard to verify RLS policies work (can't access another user's data)

---

## Phase 3 — Screens & Entry (Week 3-5)

### Step 3.1: Home Screen
- [ ] Summary card with greeting, date, Hijri date, progress ring, all-goals streak
- [ ] Greeting logic (8-level priority: birthday, Eid, New Year, Hijri New Year, Jumu'ah, Ramadan, Assalamu Alaikum, time-of-day)
- [ ] Time-of-day visual adaptation (5 phases, pattern tint changes)
- [ ] Active condition chips (horizontally scrollable, ✕ to end, tap to edit)
- [ ] Scheduled Today section (activity cards with status icons, sorted by status)
- [ ] Activity card tap → action bottom sheet (Record Activity, Link Activity, Mark as Missed, Add Reason)
- [ ] Routine cards in Scheduled Today
- [ ] Needs Attention section (max 3, "See All" link)
- [ ] Summary card tap → Today's Summary bottom sheet
- [ ] Pull to refresh (sync + recompute)
- [ ] Empty state (first-time user)
- [ ] All-done state (milestone shimmer animation)
- [ ] Double-tap Kitab title → reveal/hide private activities
- [ ] Responsive layout (phone single col, tablet 2 col, web desktop with icon rail)

### Step 3.2: Needs Attention — See All Sub-Screen
- [ ] Full-screen list grouped by date with day separators
- [ ] Conditions interwoven in day headers
- [ ] Filter row (search, All, Today, This Week, category chips)
- [ ] Same action bottom sheet per card
- [ ] Back navigation to Home

### Step 3.3: FAB Implementation
- [ ] Arc speed dial animation (+ rotates to ✕)
- [ ] Phone/tablet: 2-layer arc (Record Activity / Start Condition → Timer / Habit / Metric)
- [ ] Web desktop: 4-option arc (Timer / Habit / Metric / Condition)
- [ ] Long press (native): skip to Layer 2 (Timer / Habit / Metric)
- [ ] Start Condition bottom sheet (presets, custom, start date)

### Step 3.4: Timer Quick Log
- [ ] Timer starts immediately on selection
- [ ] Activity search field with suggestions
- [ ] Editable start time
- [ ] Pause/Play (creates segments) + Stop buttons
- [ ] Segment tracking (active time, idle time, total)
- [ ] Mini-timer widget above bottom nav (up to 3, marquee names, highlighted active)
- [ ] Timer persistence in background (native: Live Activity / notification)
- [ ] Web: tab close confirmation if timer active
- [ ] Timer form auto-expands on Stop

### Step 3.5: Habit & Metric Quick Logs
- [ ] Habit form: activity search, ✓/✕ buttons, auto-close on action
- [ ] Metric form: activity search, switchable numeric field (dropdown label), +/- steppers, default 0
- [ ] Both: "More details" expansion, streak/goal status line when applicable

### Step 3.6: Expanded Entry Form
- [ ] Activity search with template suggestions
- [ ] All 13 field types rendering correctly
- [ ] Duration auto-calculation (Start + End → Duration)
- [ ] Timer segments display and editing (individual segment edit, merge, delete)
- [ ] Notes field (always present)
- [ ] KitabDateTimePicker for logged_at
- [ ] Period link display and editing
- [ ] Template switching (union logic — no fields removed)
- [ ] Save / Duplicate / Delete actions
- [ ] Unsaved changes confirmation on close
- [ ] Tablet/desktop: modal dialog (max-width 560px)

### Step 3.7: Book Screen
- [ ] App bar with "Book" title + plain + button
- [ ] Filter row (⚙ Filters, 🔍 Search, 📅 Date, Categories ▾, Goal Status ▾, Conditions)
- [ ] Chronological timeline with sticky day separators
- [ ] Conditions in day headers (started/Day X/ended, tappable)
- [ ] Entry cards (category color border, name, category, time, goal status, progress)
- [ ] ⓘ tooltip for entries linked to template with schedule but not to period
- [ ] Tap → expanded entry form (edit mode)
- [ ] Long press → Duplicate / Edit / Delete
- [ ] Swipe left → Delete with confirmation
- [ ] Infinite scroll with loading spinner
- [ ] "Today ↑" pill button on deep scroll
- [ ] Date jump via mini-calendar
- [ ] Condition cards (in Conditions filter mode)
- [ ] Search (activity name + notes)
- [ ] Tablet/desktop: master-detail layout

### Step 3.8: Profile & Settings Screen
- [ ] Profile card (signed in: avatar, name, email, member since; guest: CTA to create account)
- [ ] Profile nav icon (photo → initial → generic icon priority)
- [ ] Edit Profile sub-screen (name, username, bio, birthday, avatar upload)
- [ ] My Activities — list with Activity Detail View (overview, goals, history)
- [ ] My Activities — create/edit activity template form (full spec from §5)
- [ ] My Activities — archive/delete with cascade rules
- [ ] My Routines — list with Routine Detail View
- [ ] My Routines — create/edit routine form
- [ ] Categories management (create, edit, reorder, delete with reassignment)
- [ ] Calendar & Date settings (Hijri, Islamic personalization, prayer calculation method, madhab, high-latitude, Hijri ±2, date/time/timezone format, week start)
- [ ] Appearance (Light / Dark / System Auto)
- [ ] Notifications settings (per-type toggles, reminder time)
- [ ] Privacy & Sharing (defaults, profile visibility, analytics opt-out)
- [ ] Condition Presets management
- [ ] Data & Storage (export JSON/CSV, import JSON, favorite locations, cache)
- [ ] Account (email, password, username change, biometric lock, sign out, delete)
- [ ] About (version, ToS, privacy policy, licenses, contact, re-run onboarding)
- [ ] Tablet/desktop: master-detail layout

#### Testing — Phase 3
Once complete, you should be able to:
- [ ] **Open the app** and see the Home screen with greeting, date, Hijri date (if enabled), and empty Scheduled Today
- [ ] **Create an activity** from Settings → My Activities → + New Activity. Set up a daily activity with fields and a goal
- [ ] **See the activity appear** on the Home screen's Scheduled Today section with ○ in-progress status
- [ ] **Tap the activity card** → see the action bottom sheet → tap "Record Activity" → fill in the form → save
- [ ] **See the activity card** change to ✓ completed (faded) and the progress ring update
- [ ] **Tap the FAB** → see the arc speed dial → start a timer → see the mini-timer widget → stop → see the expanded form
- [ ] **Open the Book** → see your entry in the timeline with the correct category color border
- [ ] **Swipe left on a Book entry** → see delete confirmation
- [ ] **Create a condition** (via FAB → Start Condition) → see the condition chip on Home
- [ ] **Excuse an activity** → see the ⊘ status and streak preserved
- [ ] **Miss an activity** → see the streak reset to 0
- [ ] **Wait for a period to expire** → see it move to Needs Attention
- [ ] **Test on all devices:** iPhone, iPad, Samsung, Chrome (resize window for responsive layouts)
- [ ] **Test dark mode** toggle in Settings → Appearance
- [ ] **Test private activities** — mark an activity as private, see it blurred, double-tap "Kitab" to reveal
- [ ] **Export data** from Settings → Data & Storage → Export (JSON format) → verify the file contains your entries

---

## Phase 4 — Social, Insights & Auth (Week 5-7)

### Step 4.1: Authentication Flow
- [ ] Create Account form (name, username, email, password, age checkbox, ToS agreement)
- [ ] Email OTP verification (8 digits, 1 hour expiry)
- [ ] Sign In form (email + password)
- [ ] Google Sign-In integration
- [ ] Apple Sign-In integration
- [ ] Forgot Password flow (reset link)
- [ ] Change Email (OTP on new email)
- [ ] Username change (30-day cooldown)
- [ ] Sign Out (preserve local data)
- [ ] Delete Account (type DELETE confirmation, cloud data deleted, local preserved)
- [ ] Session persistence (native: secure storage, web: localStorage)
- [ ] Biometric lock option (native only)
- [ ] Anonymous → account migration (local data push + merge)

### Step 4.2: Sync Engine
- [ ] Sync queue (local writes → queue → push to Supabase)
- [ ] Push phase (process queue, mark synced_at)
- [ ] Pull phase (query updated_at > last_sync, merge locally)
- [ ] Last-write-wins conflict resolution
- [ ] Real-time subscriptions (Supabase real-time channels)
- [ ] All sync triggers (app open, every 5 min, significant writes, Home navigation, pull-to-refresh, foreground resume)
- [ ] Pre-auth → account sync (anonymous data migration)
- [ ] 12-step merge algorithm for account creation/sign-in conflicts
- [ ] Template name conflict resolution UI (user picks which version to keep)
- [ ] Sync status indicator (invisible unless problem, amber dot on Profile)
- [ ] Soft delete handling (deleted_at in sync queries)

### Step 4.3: Social Screen
- [ ] Account required gate (prompt to create account)
- [ ] Friends tab — pending requests (accept/decline)
- [ ] Friends tab — friends list with shared activity count
- [ ] Add Friend flow (search by email/username, invite link)
- [ ] Friend Detail View (shared activities, streaks, completion rate, reactions)
- [ ] Reactions (4 emojis + 4 messages always; 1 emoji + 1 message Islamic personalization only)
- [ ] Shared tab — centralized sharing management per activity/routine
- [ ] Sharing editor (Private / Specific friends / All friends)
- [ ] Competitions tab — Active, Upcoming, Completed sections
- [ ] Competition Detail (rules, leaderboard, personal progress, log entry, leave)
- [ ] Competition Creation (3-step: basics, activity/leaderboard, invite)
- [ ] Personal activity linkage prompt on join
- [ ] Report & block user
- [ ] Social notification badge (dot on Social tab)

### Step 4.4: Insights Screen
- [ ] Dashboard tab with period selector
- [ ] Ramadan comparison periods (pre/during/post + year-over-year)
- [ ] Overview stat tiles (goals met %, streak, entries, time tracked — with trends)
- [ ] Completion heat map (calendar grid, color intensity, tap for breakdown)
- [ ] Category breakdown (horizontal bars, expandable)
- [ ] Activity rankings (best first / needs attention toggle)
- [ ] Trends (line chart with metric dropdown, condition overlay)
- [ ] Patterns (6 auto-generated pattern types, minimum data threshold)
- [ ] Conditions summary (days, excused count, adjusted rate)
- [ ] Routines performance
- [ ] Personal records (all-time, gold accent, NEW badge)
- [ ] My Charts tab — favorites + all charts list
- [ ] Chart builder (8 chart types, data source, measure, calculation, grouping, period, conditions toggle, live preview)
- [ ] Chart save, favorite, edit, duplicate, delete

### Step 4.5: Routine Execution
- [ ] Routine flow screen (activity list with statuses, current activity form inline)
- [ ] Smart form selection per activity (timer/habit/metric/expanded)
- [ ] Skip / Excuse / Mark Missed per activity
- [ ] Reorder activities mid-routine
- [ ] Jump to any activity (not strictly sequential)
- [ ] Routine mini-widget (progress X/Y, elapsed time)
- [ ] One active routine at a time (+ up to 3 standalone timers)
- [ ] Routine cascade rules (down: routine→activities, up: activities→routine)
- [ ] Routine period status computation (pending/partial/excused/missed/completed)
- [ ] Routine stays open past scheduled window

#### Testing — Phase 4
Once complete, you should be able to:
- [ ] **Create an account** with email + password → receive OTP code → verify → see data sync
- [ ] **Sign out and sign back in** → verify all data is preserved
- [ ] **Sign in on Chrome web** with the same account → see all your data
- [ ] **Make changes on web** → open native app → pull to refresh → see changes synced
- [ ] **Make changes offline** on native → reconnect → verify sync completes
- [ ] **Add a friend** (you'll need a second test account) → send friend request → accept on other account
- [ ] **Share an activity** with a friend → verify friend can see your streak and completion rate
- [ ] **Send a reaction** to a friend's shared activity → verify they receive a notification
- [ ] **Create a competition** → invite friend → both log entries → verify leaderboard updates
- [ ] **Open Insights** → see dashboard with heat map, category bars, and stat tiles
- [ ] **Create a custom chart** (e.g., weight over time) → save → verify it appears in My Charts
- [ ] **Select a Ramadan period** (if applicable) → see pre/during/post comparison
- [ ] **Start a routine** from Home screen → flow through activities → see routine completion stats
- [ ] **Test on all devices** — verify responsive layouts for Social and Insights

---

## Phase 5 — Polish & Launch Prep (Week 7-8)

### Step 5.1: Notifications
- [ ] Notification screen UI (list, tap actions, swipe delete, clear all)
- [ ] Bell badge on Home (dot when notifications exist)
- [ ] Push notifications — iOS (APNs) + Android (FCM) setup
- [ ] Push notification deep linking to relevant screens
- [ ] Private activity generic text in push ("Activity reminder")
- [ ] Browser notifications (web, permission request)
- [ ] Supabase Edge Function: notification generation (hourly cron)
  - [ ] Streak at risk detection
  - [ ] Reminder to log (at user's configured time)
  - [ ] Condition reminders (active condition duration threshold)
  - [ ] Streak milestones
- [ ] Notification settings respected (per-type toggles)

### Step 5.2: Onboarding Flow
- [ ] Splash screen (2-3s auto-advance, geometric pattern animation)
- [ ] Returning user check (Sign In / Get Started)
- [ ] Name input (optional)
- [ ] Intro carousel (3 screens, swipeable, skip option)
- [ ] Islamic personalization choice (enables Hijri + Islamic greetings + location permission)
- [ ] Activity template picker (50+ templates, organized by category, collapsible, Select All per sub-group)
- [ ] Routine suggestion (if 3+ related activities selected)
- [ ] Ready screen (summary, account tip, "Start Your Journey")
- [ ] Onboarding state tracking (shows until completed)
- [ ] Web onboarding (after auth, skip returning user check)
- [ ] Contextual permission requests (location at Islamic step, notifications after onboarding)

### Step 5.3: Accessibility
- [ ] Screen reader labels on all interactive elements
- [ ] Dynamic text scaling (test at 200% font size)
- [ ] Reduced motion support (crossfade instead of slide, no particles)
- [ ] High contrast mode (WCAG AAA ratios)
- [ ] Color independence (icon + label for every color signal)
- [ ] Minimum touch targets (44x44 iOS, 48x48 Android)
- [ ] Focus order (tab key navigation on web)

### Step 5.4: Error Handling & Loading States
- [ ] Skeleton screens per screen (shimmer animation)
- [ ] Button loading states (spinner replaces text)
- [ ] Network error toasts with retry
- [ ] Validation error inline field highlighting
- [ ] Pull-to-refresh indicator (Primary color)
- [ ] "You're offline" banner (web only)
- [ ] Corrupted local DB recovery ("Reset and sync from cloud")

### Step 5.5: Analytics & Crash Reporting
- [ ] PostHog integration (screen views, feature usage, onboarding funnel)
- [ ] Analytics opt-out toggle in Settings
- [ ] Cookie consent banner (web only)
- [ ] Sentry integration (crash reporting, breadcrumbs)
- [ ] No PII in analytics events (anonymized IDs only)

### Step 5.6: Legal & Compliance
- [ ] Privacy policy page (hosted at mykitab.app/privacy)
- [ ] Terms of service page (hosted at mykitab.app/terms)
- [ ] Age restriction enforcement (13+ checkbox)
- [ ] Open source license list in Settings → About
- [ ] Sign Supabase DPA (GDPR requirement)
- [ ] Prepare App Store privacy labels
- [ ] Prepare Play Store data safety form
- [ ] Draft breach response plan

### Step 5.7: Edge Functions
- [ ] Notification generation cron (hourly)
- [ ] Competition leaderboard computation (DB trigger)
- [ ] Account deletion cleanup (cascade)
- [ ] Soft-deleted records purge (30-day cleanup)

### Step 5.8: Final Testing & Submission Prep
- [ ] Full app walkthrough on all devices (iPhone, iPad, Samsung, Chrome desktop, Chrome mobile)
- [ ] Test all auth flows (create account, sign in, forgot password, sign out, delete account)
- [ ] Test offline → online sync on native
- [ ] Test with 100+ entries to verify performance
- [ ] Test with Islamic personalization ON and OFF
- [ ] Test Hijri date display and prayer times
- [ ] Test private activities (blur, reveal, double-tap)
- [ ] Test competitions end-to-end with 2 accounts
- [ ] Test data export (JSON + CSV) and import (JSON)
- [ ] Verify all accessibility features
- [ ] Prepare App Store screenshots and description
- [ ] Prepare Play Store screenshots and description
- [ ] Deploy web app to hosting (Vercel)
- [ ] Configure domain (mykitab.app) DNS

#### Testing — Phase 5
Once complete, you should be able to:
- [ ] **Install the app fresh** on a new device → go through full onboarding → select activities → see Home populated
- [ ] **Receive a push notification** when a streak is at risk → tap it → navigate to the activity
- [ ] **Use the app with VoiceOver/TalkBack** → verify all elements are announced correctly
- [ ] **Increase font size to maximum** → verify layouts reflow gracefully
- [ ] **Turn on "Reduce Motion"** → verify no slide animations, only crossfade
- [ ] **Export all data as JSON** → import on a different device → verify everything matches
- [ ] **Delete account** → verify cloud data is gone but local data remains
- [ ] **Visit mykitab.app** → see the web app sign-in page → sign in → use full app in browser
- [ ] **Complete a full day** of tracking (morning routine, activities throughout the day, evening) → verify all streaks, goals, and insights update correctly

---

## Post-Launch — Ongoing

- [ ] Monitor Sentry for crashes
- [ ] Monitor PostHog for user behavior patterns
- [ ] Respond to App Store / Play Store reviews
- [ ] Rotate Apple OAuth secret key every 6 months
- [ ] Review and address user feedback
- [ ] Plan V2 features (health device integration, Apple Watch, AI chatbot, team competitions)

---

## Quick Reference

| Resource | Location |
|----------|----------|
| Full Specification | `SPEC.md` (6,821 lines) |
| Spec Web Page | `docs/spec.html` |
| Interactive Mockups | `mockups/*.html` |
| Supabase Project | `ircnrwdulvgvpeyzvfjk` (us-east-1) |
| Domain | mykitab.app |
| Bundle ID | com.mykitab.kitab |
| Design Colors | Primary: #0D7377, Accent: #C8963E |
| Fonts | DM Serif Display, Inter, JetBrains Mono, Amiri |
