# Arunika product quality overhaul

Date: 2026-09-05. Baseline: 459a33e, Flutter 3.44.6. The active product is an offline family journal and shared routines app, not a medical tracker. Preserve package identity, the existing local database, historical records, purchases and the Flutter/Riverpod stack.

## Product direction

Give adults a clear daily loop: open Today, mark a scheduled habit, save one sentence or photo, then revisit a weekly reflection. Use Indonesian labels, warm paper surfaces, Fraunces headings and readable Jakarta Sans. Keep health functionality outside the active shell. Do not add accounts or a server.

## Screen contract

- Onboarding: explain concrete value and local storage, optional family details and starter habits; saving failure must be recoverable and onboarding is complete only after data is stored.
- Today: date, family name, visible settings, scheduled habits and accurate progress, quick journal prompt, latest readable memory, real weekly counts. An empty schedule is not a completed schedule. View-all buttons navigate to lists.
- Habits: today/all/archive filters, scheduled versus unscheduled state, safe completion with failure recovery, edit/archive/restore. Day labels use full short names with 48dp targets.
- Moments: lazy timeline, text search and mood filtering, distinguish no matches from an empty journal, read detail before editing, explicit delete confirmation.
- Editors: validated bounded fields, safe async error handling, prevent duplicate saves, preserve unsaved input when navigating back, photos copied into app storage. Save controls remain reachable with keyboard and larger type.
- Family/garden: useful weekly reflection and family management. Explain decorative visual; counts reflect complete data. Member rows edit; deletion keeps memories and removes only the association.
- Settings: family, appearance, daily optional reminder with device time, complete backup/restore, scrapbook export, readable in-app privacy policy and support. Show progress and safe errors for file operations.
- Navigation: four plainly labeled tabs, accessible controls, settings reachable from Today, contextual create action, back returns to Today before exit.

## Data and reliability

Replace destructive SQLite REPLACE writes for parent entities; editing a habit must retain all check-ins. Remove silent list/export limits. Copy selected images out of cache before saving. Backup family members, habits including archives, check-ins, memories and images, with validated versioned import and atomic database writes. Merge by identifier; do not overwrite existing data. Keep legacy records. Recap excludes future dates and refreshes after midnight/resume.

## Release and verification

Target Android API 36 or newer, inspect merged permissions and signing, keep real ad IDs out of committed content, disable unintended OS cloud backup consistently with local-storage copy. Do not publish automatically. Verify analyzer, domain/widget/database regression tests, representative light/dark/large-text screens, and release APK/AAB. Test Play Billing restoration through an internal Play track before a production rollout. Store descriptions must only promise implemented features. Record external release blockers and distinguish them from completed engineering.

## Confirmed advertising direction

Final user direction: all tabs and core features are free, using AdMob banner and limited interstitial ads plus an optional permanent Remove Ads purchase. Interstitial is only at a completed writing boundary (at least three successful saves and a ten-minute cooldown), never on startup, tab changes, cancel or failed saves. Rewarded was evaluated and prepared, then deferred by the user; it is disabled by default with no offer or rewarded request in this version.
