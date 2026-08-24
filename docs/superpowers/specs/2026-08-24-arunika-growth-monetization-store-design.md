# Arunika: Monetization, Store Listing, and Promotion Design

Date: 2026-08-24

## Objective

Prepare Arunika: Tumbuh Kembang Anak for a Google Play closed test with a
reliable AdMob monetization layer, a one-time US$4.99 remove-ads product,
privacy-policy URL, eight store screenshots, ASO-oriented listing copy, and a
Remotion promotional video. Push the complete source and generated deliverable
metadata to `fareza777/arunika-tumbuh-anak`.

## Current project

- Flutter Android app using Riverpod, SQLite, WHO/CDC standards, and local
  notifications.
- Android application ID: `id.arunika.arunika_growth`.
- Current package version: `1.1.0+2`; the next release will use a higher
  version code.
- App data is local, but the new AdMob SDK introduces advertising-related
  device/network data and Play Billing introduces purchase state.
- No local git repository, AdMob integration, billing integration, or privacy
  page currently exists.

## Product decisions

### Monetization

Use a non-consumable Google Play product named `arunika_remove_ads` priced at
US$4.99. The entitlement is restored on every app start and when the user taps
Restore Purchases. Ad display is gated by the entitlement only; a transient
billing/network error must not hide ads for a user who has not been verified as
entitled.

Ad placement is deliberately predictable:

- One adaptive banner on the primary content surface, above the bottom safe-area
  padding and below meaningful content.
- The banner is not placed on onboarding, child/profile entry, measurement
  entry, or other flows where it could be mistaken for a control.
- Interstitials are limited to natural completion points and rate-limited; they
  are never shown immediately on launch or while entering health data.
- A banner reserves its layout height before loading, remains mounted while an
  ad is loading, and keeps a stable key across rebuilds. Load errors show the
  reserved slot and retry with backoff, preventing flicker or intermittent
  disappearance caused by widget replacement.

Use Google test ad IDs for debug/profile builds. Release IDs are supplied by
the AdMob setup and kept in build configuration rather than hard-coded into
tests.

### Privacy and data safety

Create a static, mobile-readable `docs/privacy-policy.html` describing local
child data storage, optional exports/sharing, AdMob advertising data, Google
Play purchase processing, diagnostics, retention, parental use, and support.
Use the GitHub Pages URL:

`https://fareza777.github.io/arunika-tumbuh-anak/privacy-policy.html`

The Play listing will target parents/caregivers, not children, and the data
safety answers will reflect the final SDK behavior rather than the current
offline-only README.

### Store listing

- Title: `Arunika: Tumbuh Kembang Anak`.
- Category: Health & Fitness.
- Short description emphasizes WHO/CDC growth charts, z-score, nutrition,
  milestones, and offline privacy.
- Full description uses natural Indonesian search terms without medical claims
  or keyword stuffing.
- Eight phone screenshots use consistent Arunika ivory/gold framing and show
  real app flows: home, nutrition status, growth chart, insight/prediction,
  milestones, immunization, daily nutrition, and PDF/settings.
- App access is no-login/offline; the listing keeps the medical disclaimer.

### Promotion video

Create a 30–35 second 16:9 Remotion composition in a `promo-video/` project.
Use the app palette and actual screenshots where available, with short readable
Indonesian captions and no copyrighted audio. Render an MP4 and upload it to
YouTube Studio as Unlisted. The resulting video URL can be added to Play's
store listing after review.

### Play Console and closed testing

Create the app with package `id.arunika.arunika_growth`, configure the store
listing, content rating, target audience, ads declaration, data safety, and
privacy URL. Create an Alpha closed-testing track, upload the release AAB, and
use the same four Google Groups currently configured for Vocatim:

- `swaptest-testers@googlegroups.com`
- `testers-community@googlegroups.com`
- `sstechnologies-test@googlegroups.com`
- `appdadz@googlegroups.com`

Configure the one-time product in Monetize with Play and create the Android
AdMob app with banner and interstitial units. Any account/payment/signing
credential gate is handed back to the user without committing secrets.

## Architecture

Add a focused monetization domain with:

1. A configuration object for product ID, AdMob app ID, banner ID, interstitial
   ID, debug IDs, and build-mode selection.
2. A Riverpod-owned monetization controller that initializes Mobile Ads once,
   listens to the purchase stream, queries product details, restores purchases,
   exposes `isAdsRemoved`, and handles pending/error/cancelled transactions.
3. A stable banner widget that keeps one `BannerAd` instance per mounted
   placement, uses adaptive anchored size, shows a reserved placeholder while
   loading, retries failed loads with bounded backoff, and disposes only when
   the placement is actually removed or the entitlement becomes verified.
4. A rate-limited interstitial helper with explicit `showIfEligible` calls;
   no implicit show from arbitrary widget rebuilds.
5. A settings card for purchase/restore state and clear price disclosure.

Persist only the last known entitlement hint locally for fast UI rendering, but
do not treat it as authoritative: Play Billing restore/query results are the
source of truth. If a cached entitlement says ads are removed and verification
has not completed, the UI must show a non-blocking verification state instead
of silently toggling banners on and off.

## Reliability and error handling

- Mobile Ads initialization is idempotent and non-fatal.
- Banner load failures retain the slot and retry after 15, 30, then 60 seconds,
  with a longer cap for repeated failures.
- A failed or unavailable billing query never causes the banner to disappear.
- Purchase updates are acknowledged through the plugin flow and the entitlement
  is rechecked after purchase completion.
- Configuration validation logs a clear non-sensitive warning when release IDs
  are missing and falls back to a safe no-ad-load state only for an explicitly
  configured preview build; it must not silently ship test IDs in release.

## Verification

- `flutter analyze`.
- `flutter test` plus unit tests for entitlement transitions, banner visibility
  gating, retry policy, and interstitial rate limiting.
- `flutter build appbundle --release` with release AdMob values supplied by
  configuration.
- Install the release/debug build on an available Android emulator and capture
  eight screenshots at a consistent phone resolution.
- Inspect the rendered Remotion MP4 and confirm duration, dimensions, and that
  no asset is missing.
- Re-read Play Console and AdMob screens after each external save; verify the
  closed-test groups and product IDs visibly match the intended configuration.

## Handoff boundaries

The user receives the app source, privacy page, screenshots, video, AAB, and
the exact Play/AdMob state reached. If Play requires a signing key, payments
profile, identity verification, CAPTCHA, or a final publication confirmation,
the workflow stops at that point and the user takes over.
