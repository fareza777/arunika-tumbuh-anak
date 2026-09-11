# Arunika Product Quality Overhaul Implementation Plan

> **For agentic workers:** Use the systematic-debugging and verification-before-completion skills; independent data, editor and notification work is dispatched using dispatching-parallel-agents. Keep edits within assigned files and report verification evidence.

**Goal:** Make every active family-journal page understandable, reliable and reviewable for an Android release.

**Architecture:** Preserve Flutter, Riverpod and SQLite. Separate media/backup, presentation and notification services. Keep the existing package and migration history.

**Tech Stack:** Flutter 3.44.6, Dart 3.12.2, Riverpod 2, SQLite, local notifications, Google Mobile Ads and Play Billing.

**Spec:** ../specs/2026-09-05-product-quality-overhaul-design.md

## Global constraints

- Preserve package id `id.arunika.arunika_growth`, user records and existing purchase product.
- Active product is an offline family journal for adults; Indonesian copy, no medical claims.
- UI must work on small screens, dark mode and large text; 48dp controls and usable error states.
- Do not publish, push or expose signing secrets; prepare reviewable local artifacts.

## Work and validation

- [x] Data: regression coverage for habit edit retaining check-ins, uncapped journal history, invalid/duplicate backup imports and durable photo storage. Implement in `lib/data`, `lib/domain/together`; use atomic writes and preserve legacy tables.
- [x] Editors: update the three `lib/ui/together/*editor*` forms with field validation, save recovery, unsaved-change protection and explicit removal actions. Verify invalid input, failure retry and back behavior.
- [x] Reminder: daily opt-in family journal reminder using the device time zone, permission denial recovery and reboot persistence; own notification service, settings preference fields and Android declarations.
- [x] Presentation: shared readable theme, feedback/loading/error components, clear four-tab shell, Today, Habits, Moments/detail, Family and Settings. Verify navigation, filtering, empty/loading/error states and screen layout.
- [x] Onboarding and integration: only mark setup done after successful writes, refresh date-sensitive state at midnight/resume, connect file services and reminders.
- [x] Release: update truthful store/privacy documentation, add repeatable CI verification and prepare APK/AAB. Record analyzer, tests, visual checks, target SDK and remaining Play Console checks in the audit report.
