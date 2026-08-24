# Arunika: Tumbuh Bersama Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Transform Arunika into an offline-first family ritual and memory journal with a premium Editorial Sunrise experience, while keeping the existing package ID, stable ad banner behavior, and the $4.99 Remove Ads purchase path.

**Architecture:** Add a new “together” domain/data slice beside the legacy measurement code, then make the new shell, onboarding, and active routes use only family moments and rituals. Keep legacy health tables/files isolated for safe migration, but remove them from active navigation and active copy. Use Riverpod over SQLite repositories, deterministic local recap logic, and small reusable visual components.

**Tech Stack:** Flutter/Dart, Riverpod, SQLite/sqflite, Phosphor Icons, existing Fraunces and Plus Jakarta Sans fonts, image_picker, pdf/printing, google_mobile_ads, in_app_purchase.

**Spec:** `docs/superpowers/specs/2026-08-24-arunika-tumbuh-bersama-design.md`

## Global Constraints

- Preserve application ID `id.arunika.arunika_growth`.
- Do not present health, medical, growth-chart, nutrition, immunization, or clinical language in active product flows, onboarding, notification copy, or store positioning.
- Store only family/member labels, rituals, check-ins, notes, tags, optional photo paths, and local settings in the new slice.
- Keep the banner mounted on every browse screen, with explicit reserved height; never place ads inside compose forms or between a save action and its confirmation.
- Keep ad-free state durable and let a purchase restore it; keep the existing purchase product ID unless the repository proves a different configured ID.
- Respect reduced-motion settings and provide semantic labels, large tap targets, and strong contrast.
- Use `apply_patch` for source edits, run formatting/analyze/tests at checkpoints, and never commit secrets or generated signing material.

---

## Task 1: Add the family moments and rituals data slice

- [ ] Update `pubspec.yaml` with `phosphor_flutter: ^2.1.0` and resolve dependencies.
- [ ] Bump `lib/data/db/app_database.dart` to schema version 3 and create `family_members`, `rituals`, `ritual_checkins`, and `moments` tables. Migrate only legacy display names where safe; do not map health fields into the new domain.
- [ ] Create `lib/data/models/family_member.dart`, `ritual.dart`, `ritual_check_in.dart`, and `moment.dart` with immutable models, SQLite mapping, date keys, labels, and serialization helpers.
- [ ] Create `lib/data/repositories/family_member_repository.dart`, `ritual_repository.dart`, and `moment_repository.dart` with typed CRUD, ordering, and check-in operations.
- [ ] Add pure model/repository contract tests under `test/data/` that do not require device-only plugins.

## Task 2: Add local state, actions, and weekly recap logic

- [ ] Create `lib/state/together_providers.dart` for active member, member list, rituals, moments, today check-ins, and refreshable action providers.
- [ ] Create `lib/domain/together/recap_service.dart` and `together_copy.dart` for deterministic local weekly recap cards and Indonesian copy.
- [ ] Extend `lib/data/models/app_settings.dart` only with together-product preferences required by the new shell (onboarding completion, reduced motion, and ad-free persistence); keep backwards-compatible defaults.
- [ ] Add recap and action-state tests under `test/domain/` and `test/state/`.

## Task 3: Build the Editorial Sunrise visual system

- [ ] Refine `lib/core/theme/app_colors.dart` and `app_theme.dart` around warm ivory, espresso, champagne gold, sage, and terracotta while retaining old token aliases needed by legacy files.
- [ ] Create `lib/core/theme/app_motion.dart` and `app_gradients.dart` with reduced-motion-aware durations and the sunrise gradient.
- [ ] Create reusable `lib/ui/widgets/editorial_background.dart`, `editorial_card.dart`, `ritual_check.dart`, `sunrise_progress.dart`, and `tag_chip.dart` using Phosphor thin/light icons and accessible semantics.
- [ ] Add widget tests for card semantics, contrast-sensitive controls, and reduced-motion durations.

## Task 4: Replace active startup, onboarding, and Today shell

- [ ] Update `lib/app.dart`, `lib/main.dart`, `lib/ui/navigation/main_shell.dart`, `lib/ui/onboarding/onboarding_screen.dart`, and `lib/ui/splash/splash_screen.dart` so the active product is `Arunika: Tumbuh Bersama`.
- [ ] Create `lib/ui/together/today_screen.dart` and its small section widgets: sunrise greeting, progress card, next ritual, weekly recap, and recent moment.
- [ ] Use four destinations: Hari Ini, Ritual, Momen, and Taman; use a floating central action rail for “Catat momen” and “Buat ritual”.
- [ ] Add first-run onboarding that asks only for a family display name and optional member name, then seeds three useful starter rituals without health claims.
- [ ] Add shell/onboarding integration tests.

## Task 5: Implement Ritual and Momen creation flows

- [ ] Create `lib/ui/together/rituals_screen.dart`, `ritual_editor_sheet.dart`, and supporting widgets for browse, create, edit, weekday selection, time-of-day, and one-tap check-in.
- [ ] Create `lib/ui/together/moments_screen.dart`, `moment_editor_screen.dart`, and supporting widgets for note, tag, optional photo, member association, and save confirmation.
- [ ] Use `image_picker` only as an optional local attachment; keep compose screens ad-free and keyboard-safe.
- [ ] Add widget tests for ritual completion, moment validation, and save confirmation.

## Task 6: Implement Taman, family profile, and private export

- [ ] Create `lib/ui/together/garden_screen.dart`, `garden_constellation.dart`, and family member editor/list screens with a calm constellation visualization driven by moments and completed rituals.
- [ ] Add a local scrapbook export in `lib/domain/together/scrapbook_pdf.dart` and wire it from settings without exposing health language.
- [ ] Update `lib/ui/settings/settings_screen.dart` and backup/privacy surfaces to explain local-first storage, export, delete, and ad preferences in plain Indonesian.
- [ ] Add tests for empty garden, multi-member garden, and export data selection.

## Task 7: Preserve monetization and update product-facing assets/copy

- [ ] Refactor `lib/ui/monetization/` only where needed so `StableBannerAd` remains mounted with reserved height, interstitials use the existing cooldown and meaningful-save gate, and Remove Ads remains `$4.99` with durable restore behavior.
- [ ] Make sure no banner is conditionally removed due to rebuilds, loading states, or tab changes; add a regression test around the banner host contract.
- [ ] Update privacy policy, README, store listing/ASO copy, and promo-video composition to the Tumbuh Bersama positioning; create/refresh eight store screenshot assets using the same visual system where the existing asset pipeline supports it.
- [ ] Run an active-surface scan to confirm old health routes are no longer reachable from the new shell.

## Task 8: Verify, package, and push

- [ ] Bump `pubspec.yaml` to release version `1.3.0+4` and update release notes/changelog.
- [ ] Run `dart format`, `flutter analyze`, all tests, and an Android release AAB build; inspect output and ensure no signing secrets are added.
- [ ] Verify the final active flows on a running build: onboarding, Today, Ritual, Momen, Taman, stable banner host, Remove Ads surface, and local export.
- [ ] Review the diff, commit with a clear message, and push to `https://github.com/fareza777/arunika-tumbuh-anak`.

## Verification checklist

- [ ] Fresh install reaches onboarding and can complete without health-related fields.
- [ ] A ritual can be checked in offline and appears in Today/Taman.
- [ ] A moment can be saved with or without a photo and appears in Today/Momen/Taman.
- [ ] The banner has a stable reserved slot on all browse routes and never appears in compose forms.
- [ ] Remove Ads state survives restart and restore.
- [ ] `flutter analyze`, tests, and release build complete without new errors.
- [ ] Git push succeeds and the final commit is visible on the remote.
