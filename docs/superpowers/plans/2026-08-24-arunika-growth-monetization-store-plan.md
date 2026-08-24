# Arunika Growth Monetization and Store Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship a tested Arunika Android release with stable AdMob banners, one-time Play Billing remove-ads, privacy/store assets, a Remotion promo video, and a closed-testing-ready Play Console setup.

**Architecture:** Keep monetization behind a small Riverpod service boundary. A single stable banner slot lives in `MainShell` above the bottom navigation so it survives tab changes and does not disappear because individual screens rebuild; it reserves its height while loading or retrying. Play Billing is the authoritative entitlement source, while local state is only a startup hint. Store and video assets live beside the app source and are generated from repeatable scripts/configuration.

**Tech Stack:** Flutter 3.44.6 / Dart 3.12.2, Riverpod, `google_mobile_ads`, `in_app_purchase`, SharedPreferences, Android Gradle, emulator screenshots, Remotion/React, GitHub Pages, Google Play Console, AdMob, YouTube Studio.

**Spec:** `docs/superpowers/specs/2026-08-24-arunika-growth-monetization-store-design.md`

## Global Constraints

- Product ID is exactly `arunika_remove_ads` and the one-time price is US$4.99.
- Android application ID is exactly `id.arunika.arunika_growth`.
- The app is for parents/caregivers and is not designed for children.
- The privacy page path is exactly `docs/privacy-policy.html` and the intended URL is `https://fareza777.github.io/arunika-tumbuh-anak/privacy-policy.html`.
- Debug/profile builds use Google test ad IDs; a release build must not silently ship test IDs.
- The banner slot retains layout height during loading, errors, retries, and unverified billing state.
- Ads never appear on onboarding, profile entry, or measurement entry screens.
- No signing passwords, AdMob secrets, payment details, or personal tester data are committed.
- All external saves/uploads are re-read after the action; any account, payment, CAPTCHA, signing, or publication gate is handed back to the user.

---

### Task 1: Add monetization dependencies and release configuration

**Files:**
- Modify: `pubspec.yaml` dependency section and version.
- Modify: `android/app/src/main/AndroidManifest.xml`.
- Create: `android/app/src/main/res/values/strings.xml`.
- Create: `lib/domain/monetization/monetization_config.dart`.
- Create: `test/monetization_config_test.dart`.

**Interfaces:**
- Produces `MonetizationConfig.fromEnvironment({bool? isRelease})` with
  `productId`, `bannerAdUnitId`, `interstitialAdUnitId`, `admobAppId`, and
  `isRelease`.

- [ ] **Step 1: Add dependencies and version.** Add `google_mobile_ads` and
  `in_app_purchase` using versions accepted by Flutter 3.44.6, and advance the
  package to `1.2.0+3`. Keep `AppIdentity.version` aligned to `1.2.0`.
- [ ] **Step 2: Write configuration tests.** Verify that debug configuration
  returns the official Google test values and that release configuration marks
  missing `ADMOB_*` values as invalid instead of silently using test IDs.

```dart
test('debug uses test ads and the fixed product id', () {
  final config = MonetizationConfig.fromEnvironment(isRelease: false);
  expect(config.productId, 'arunika_remove_ads');
  expect(config.bannerAdUnitId, contains('3940256099942544'));
  expect(config.isValidForRelease, isTrue);
});

test('release without real IDs is invalid', () {
  final config = MonetizationConfig(
    productId: 'arunika_remove_ads',
    admobAppId: '',
    bannerAdUnitId: '',
    interstitialAdUnitId: '',
    isRelease: true,
  );
  expect(config.isValidForRelease, isFalse);
});
```

- [ ] **Step 3: Run the focused test.** Run `flutter test test/monetization_config_test.dart`; it must fail because the config class does not exist yet.
- [ ] **Step 4: Implement configuration.** Use `String.fromEnvironment` for
  `ADMOB_APP_ID`, `ADMOB_BANNER_ID`, and `ADMOB_INTERSTITIAL_ID`; use Google
  test IDs when `isRelease` is false. Add the Android AdMob application-id
  metadata using `@string/admob_app_id`, initially set to the Google test app
  ID and replaced with the real AdMob app ID before the release build.
- [ ] **Step 5: Run the focused test.** The config tests must pass.
- [ ] **Step 6: Commit.** `git add pubspec.yaml pubspec.lock android lib/domain/monetization/monetization_config.dart test/monetization_config_test.dart && git commit -m "feat: add monetization configuration"`.

### Task 2: Build pure entitlement, retry, and rate-limit logic with tests

**Files:**
- Create: `lib/domain/monetization/monetization_state.dart`.
- Create: `lib/domain/monetization/ad_retry_policy.dart`.
- Create: `lib/domain/monetization/interstitial_gate.dart`.
- Create: `test/monetization_state_test.dart`.
- Create: `test/ad_retry_policy_test.dart`.
- Create: `test/interstitial_gate_test.dart`.

**Interfaces:**
- `MonetizationState` contains `adsRemoved`, `isVerifying`, `storeAvailable`,
  `productPrice`, and `message`.
- `AdRetryPolicy.nextDelay(int failureCount)` returns 15, 30, 60 seconds for
  the first three failures, then caps at five minutes.
- `InterstitialGate.canShow(DateTime now)` and `recordShown(DateTime now)`
  enforce a minimum 10-minute interval and a maximum of one show per session
  until the user completes three successful measurement saves.

- [ ] **Step 1: Write state transition tests.** Cover initial state, verified
  purchase, restored purchase, cancelled purchase, error while unverified, and
  error after previously verified purchase. The error cases must never change
  `adsRemoved` to false after it was verified true.
- [ ] **Step 2: Write retry tests.** Verify exact delays for failure counts 0–4
  and that delay is bounded at five minutes.
- [ ] **Step 3: Write gate tests.** Verify first show, repeated call in the same
  session, the ten-minute cooldown, and reset after three completed saves.
- [ ] **Step 4: Run tests to confirm red.** Run the three focused test files and
  confirm failures identify the missing types/methods.
- [ ] **Step 5: Implement the pure value types.** Use immutable Dart classes and
  deterministic `DateTime` arguments; do not import Flutter widgets or plugins.
- [ ] **Step 6: Run tests to confirm green.** The three focused test files must
  pass without a device or network.
- [ ] **Step 7: Commit.** `git add lib/domain/monetization test/*monetization* test/ad_retry_policy_test.dart test/interstitial_gate_test.dart && git commit -m "feat: add monetization state policies"`.

### Task 3: Integrate Google Mobile Ads and Play Billing in a Riverpod controller

**Files:**
- Create: `lib/domain/monetization/monetization_service.dart`.
- Create: `lib/state/monetization_provider.dart`.
- Modify: `lib/main.dart`.
- Modify: `lib/state/app_settings.dart` only if a migration key is needed.
- Create: `test/monetization_provider_test.dart` using fakes for the service.

**Interfaces:**
- `MonetizationService.initialize()` is idempotent.
- `MonetizationService.queryRemoveAds()` returns product details or a typed
  unavailable result.
- `MonetizationService.restorePurchases()` and
  `MonetizationService.buyRemoveAds(ProductDetails product)` expose billing
  operations.
- `MonetizationController` exposes `monetizationProvider` and methods
  `buyRemoveAds()`, `restorePurchases()`, and `onMeasurementSaved()`.

- [ ] **Step 1: Write fake-service provider tests.** Verify that the controller
  starts with ads visible, marks ads removed only for a completed/purchased or
  restored `arunika_remove_ads` transaction, preserves verified state on later
  errors, and ignores unrelated product IDs.
- [ ] **Step 2: Run the provider test red.** Run `flutter test test/monetization_provider_test.dart` and confirm the missing controller/service failure.
- [ ] **Step 3: Implement the plugin service.** Initialize Mobile Ads only on
  Android/iOS, listen to `InAppPurchase.instance.purchaseStream`, query the
  exact product ID, call `completePurchase` for pending-complete transactions,
  and never throw plugin errors into the widget tree.
- [ ] **Step 4: Implement the Riverpod controller.** Initialize once in
  `build()`, restore/query purchases on mobile startup, expose a non-blocking
  verification state, and persist only a startup hint in SharedPreferences.
- [ ] **Step 5: Wire safe startup.** Start the controller from `main.dart` after
  SharedPreferences is ready; do not block the first frame on AdMob or Billing.
- [ ] **Step 6: Run provider tests green.** Re-run the focused provider test and
  all pure monetization tests.
- [ ] **Step 7: Commit.** `git add lib/domain/monetization lib/state/monetization_provider.dart lib/main.dart lib/state/app_settings.dart test/monetization_provider_test.dart && git commit -m "feat: integrate ads and Play Billing"`.

### Task 4: Add the stable banner slot and remove-ads controls

**Files:**
- Create: `lib/ui/monetization/stable_banner_ad.dart`.
- Create: `lib/ui/monetization/remove_ads_card.dart`.
- Modify: `lib/ui/navigation/main_shell.dart`.
- Modify: `lib/ui/settings/settings_screen.dart`.
- Modify: `lib/ui/report/report_screen.dart` only if a natural interstitial
  completion point is used.
- Create: `test/stable_banner_ad_test.dart`.

**Interfaces:**
- `StableBannerAd({Key? key, required BannerPlacement placement})` keeps one
  `BannerAd` per mounted placement and renders a fixed-height reserved slot
  until the entitlement is verified.
- `RemoveAdsCard` calls the controller and displays the Play-provided localized
  price or the fallback `US$4.99`.

- [ ] **Step 1: Write widget tests.** Verify the slot has nonzero height while
  loading, stays the same height after a load error, does not replace the ad on
  ordinary parent rebuilds, and becomes `SizedBox.shrink()` only when
  `adsRemoved == true`.
- [ ] **Step 2: Run the widget test red.** Run `flutter test test/stable_banner_ad_test.dart` and record the missing widget failure.
- [ ] **Step 3: Implement the stable banner.** Use `ConsumerStatefulWidget`, a
  stable `ValueKey(placement.name)`, `AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize`, one `BannerAd`, a fixed placeholder height of 60 logical pixels until an adaptive size is known, and retry timers from `AdRetryPolicy`. Cancel timers and dispose the ad in `dispose()`.
- [ ] **Step 4: Mount exactly one banner.** Wrap the current `IndexedStack` in
  `Column` inside `MainShell`, place `StableBannerAd` between the expanded page
  area and bottom navigation, and preserve the existing safe-area padding. This
  keeps the banner present across the four tabs without putting it in data-entry
  routes.
- [ ] **Step 5: Add purchase controls.** Add a `Bebas Iklan` card to Settings
  with buy, restore, pending, success, and error states. Do not hide the banner
  until the controller receives a verified entitlement.
- [ ] **Step 6: Add rate-limited natural interstitial.** Call
  `onMeasurementSaved()` after a successful measurement save, and show only if
  `InterstitialGate` permits it and an interstitial is already loaded. Never
  show during forms or immediately at startup.
- [ ] **Step 7: Run widget and full Flutter tests.** The banner test and existing
  tests must pass.
- [ ] **Step 8: Commit.** `git add lib/ui/monetization lib/ui/navigation/main_shell.dart lib/ui/settings/settings_screen.dart lib/ui/report/report_screen.dart test/stable_banner_ad_test.dart && git commit -m "feat: add stable banner and remove ads UI"`.

### Task 5: Create privacy policy and ASO/store metadata

**Files:**
- Create: `docs/privacy-policy.html`.
- Create: `docs/index.html` linking to the policy.
- Create: `store/aso.md` with title, short description, full description,
  category, tags, data-safety notes, and release checklist.
- Create: `store/assets/README.md` listing the eight screenshot filenames and
  their intended listing order.
- Modify: `README.md` to document Ads, Billing, privacy URL, and release setup.

- [ ] **Step 1: Write the policy content.** State the app name, local SQLite
  storage, optional export/share behavior, AdMob data use, Play Billing
  processing, diagnostics, retention, parental use, support through the GitHub
  issue URL, medical disclaimer, and policy-change date. Avoid inventing a
  personal email address.
- [ ] **Step 2: Add mobile-first HTML.** Use the existing ivory/gold brand,
  readable contrast, semantic headings, a table of collected data/purpose, and
  no external tracking scripts.
- [ ] **Step 3: Write ASO copy.** Use `Arunika: Tumbuh Kembang Anak`, the
  80-character Indonesian short description, a benefit-led full description,
  and natural keywords including “tinggi badan anak”, “berat badan anak”,
  “grafik pertumbuhan WHO”, “status gizi”, “milestone”, “imunisasi”, “gizi
  harian”, “offline”, and “privat”.
- [ ] **Step 4: Validate locally.** Serve `docs/` with a local static server and
  verify the policy URL path and all links.
- [ ] **Step 5: Commit.** `git add docs/privacy-policy.html docs/index.html store README.md && git commit -m "docs: add privacy policy and store metadata"`.

### Task 6: Create repeatable demo data and capture eight phone screenshots

**Files:**
- Create: `lib/domain/demo/demo_seed.dart` with a debug-only seed helper.
- Create: `tool/screenshots/capture_screenshots.ps1`.
- Create: `store/assets/screenshots/01-home.png` through `08-settings.png`.
- Modify: `store/assets/README.md` with final dimensions and capture dates.

- [ ] **Step 1: Add deterministic demo data behind a debug-only path.** Add
  `DemoSeed.seedIfEnabled()` and call it only when
  `const bool.fromEnvironment('ARUNIKA_DEMO_DATA')` is true and
  `kDebugMode` is true. Seed two fictional profiles, measurements across
  several dates, milestone states, immunization states, and daily nutrition
  checks. Use fictional names and no personal data. Do not enable the seed path
  in release.
- [ ] **Step 2: Start the `nitid_test` Android emulator** and launch the app in
  debug/profile mode with test ads. Confirm the app opens and demo data is
  visible.
- [ ] **Step 3: Capture the first four screens** at the same phone resolution:
  home, status/analysis, growth chart, and insight/prediction.
- [ ] **Step 4: Capture the remaining four screens:** milestones, immunization,
  daily nutrition, and report/settings with the remove-ads card.
- [ ] **Step 5: Inspect all images.** Verify no personal data, debug banner,
  clipped text, empty ad placeholder in the focal area, or device navigation
  controls are visible. Crop only the system chrome, not app content.
- [ ] **Step 6: Add final metadata.** Record each image's dimensions and listing
  order in `store/assets/README.md`.
- [ ] **Step 7: Commit.** `git add tool store/assets && git commit -m "assets: add Play listing screenshots"`.

### Task 7: Create and render the Remotion promotion video

**Files:**
- Create: `promo-video/package.json` and Remotion scaffold files.
- Create: `promo-video/src/ArunikaPromo.tsx`.
- Create: `promo-video/src/Root.tsx`.
- Create: `promo-video/public/screenshots/` with selected store images.
- Create: `promo-video/out/arunika-promo.mp4`.
- Create: `promo-video/README.md` with render command and YouTube metadata.

- [ ] **Step 1: Scaffold the Remotion project** with the existing Node 26.3.1
  runtime and install the project dependencies.
- [ ] **Step 2: Build the composition.** Use a 1920×1080, 30–35 second sequence
  with scenes: brand reveal, “Pantau pertumbuhan dengan data WHO/CDC”, home and
  charts, insight/milestone/nutrition collage, offline/private message, and
  final CTA. Keep captions at video-safe margins and use the ivory/gold Arunika
  palette.
- [ ] **Step 3: Preview the composition** with `npx remotion studio --no-open`
  and inspect the local preview.
- [ ] **Step 4: Render the MP4** with `npx remotion render src/index.ts
  ArunikaPromo out/arunika-promo.mp4 --codec=h264 --crf=18`.
- [ ] **Step 5: Verify the artifact** with media metadata: duration between 30
  and 35 seconds, 1920×1080, H.264 video, and every screenshot asset present.
- [ ] **Step 6: Commit.** `git add promo-video && git commit -m "feat: add Arunika promo video"`.

### Task 8: Run full tests, build a release AAB, and stage upload artifacts

**Files:**
- Modify: `android/app/src/main/res/values/strings.xml` with the real AdMob app
  ID after AdMob creation.
- Create: `build/release/` outputs (ignored by git).
- Modify: `store/release-checklist.md` with version code, SHA-256, and artifact
  paths.

- [ ] **Step 1: Run formatting.** Run `dart format lib test tool` and inspect the diff.
- [ ] **Step 2: Run static analysis.** Run `flutter analyze`; resolve all errors and warnings introduced by the feature.
- [ ] **Step 3: Run tests.** Run `flutter test`; require all existing and new tests to pass.
- [ ] **Step 4: Build debug/profile validation.** Run `flutter build apk --debug` and install it on `nitid_test` to exercise test ads and purchase UI without real billing.
- [ ] **Step 5: Configure release IDs.** Insert the AdMob app ID and ad unit IDs created in AdMob, and ensure `MonetizationConfig.fromEnvironment(isRelease: true).isValidForRelease` is true.
- [ ] **Step 6: Build release AAB.** Write the three AdMob IDs to the local,
  ignored file `tool/release/monetization.json`, then run
  `flutter build appbundle --release --dart-define-from-file=tool/release/monetization.json`;
  use an existing release/upload key if available and do not commit key files.
- [ ] **Step 7: Verify artifact.** Record the AAB path, version name/code, package ID, and SHA-256 in `store/release-checklist.md`. If the build is blocked by signing, record the exact key requirement and hand off.
- [ ] **Step 8: Commit.** `git add store/release-checklist.md pubspec.yaml pubspec.lock android lib test tool && git commit -m "chore: prepare Arunika closed test release"`.

### Task 9: Configure AdMob, Play Console, YouTube, and closed testing

**External surfaces:**
- AdMob tab: create Android app for `id.arunika.arunika_growth`, then banner
  and interstitial ad units.
- Play Console: create app, store listing, privacy URL, content rating, target
  audience, ads declaration, data safety, one-time product, Alpha track, AAB,
  and four Vocatim Google Groups.
- YouTube Studio tab: upload `promo-video/out/arunika-promo.mp4` as Unlisted.

- [ ] **Step 1: Create the AdMob app and units.** Use the exact package ID and
  names `Arunika Home Banner` and `Arunika Completion Interstitial`; copy the
  generated app/unit IDs into the local release configuration without exposing
  credentials.
- [ ] **Step 2: Create the Play app.** Use title `Arunika: Tumbuh Kembang Anak`,
  app type Application, free pricing, Health & Fitness, and the package ID
  already built in the AAB.
- [ ] **Step 3: Complete policy forms.** Use the privacy URL, parents/caregivers
  target audience, ads declaration, no-login app access, and data-safety answers
  that match the final privacy page and SDK behavior.
- [ ] **Step 4: Create the in-app product.** Create `arunika_remove_ads` as a
  non-consumable one-time product with US$4.99 base price and verify the product
  is active for testing.
- [ ] **Step 5: Upload store assets.** Add the icon, eight screenshots, ASO copy,
  and the Unlisted YouTube promo URL after the video upload returns it.
- [ ] **Step 6: Create Alpha closed testing.** Upload the release AAB, configure
  the four exact Google Groups from Vocatim, and verify the tester count/list
  visibly matches.
- [ ] **Step 7: Stop at account gates.** Do not bypass CAPTCHA, identity,
  payments profile, signing, or final production publication prompts; hand the
  user the exact page and next action.
- [ ] **Step 8: Re-read every saved surface.** Confirm product ID, price,
  package, privacy URL, listing title, YouTube visibility, release version, and
  tester groups.

### Task 10: Final verification, repository push, and handoff

**Files:**
- Modify: `store/release-checklist.md` with final external URLs/status.
- Modify: `README.md` with the exact release/test commands.

- [ ] **Step 1: Run the final verification suite.** Run `flutter analyze`,
  `flutter test`, `flutter build appbundle --release` with real AdMob values,
  and the Remotion media metadata check. Save fresh outputs.
- [ ] **Step 2: Inspect repository status.** Run `git status --short`, confirm no
  secrets, generated build caches, APKs, or local credential files are staged.
- [ ] **Step 3: Add the GitHub remote.** Use
  `https://github.com/fareza777/arunika-tumbuh-anak.git`, fetch if the remote has
  content, and reconcile only non-conflicting repository metadata.
- [ ] **Step 4: Push main.** Push the verified commits to `origin/main`; if
  authentication or remote history blocks the push, report the exact command
  and leave the local commits intact.
- [ ] **Step 5: Verify the public policy URL.** Open the GitHub Pages URL and
  confirm the policy renders over HTTPS; if Pages is not enabled, record the
  raw GitHub fallback URL and the one-click Pages setting still needed.
- [ ] **Step 6: Final handoff.** Provide clickable paths to the AAB, eight
  screenshots, video, privacy policy, ASO text, and repository, plus the exact
  Play/AdMob/YouTube state reached and any unavoidable account gate.

## Plan self-review

- Spec coverage: monetization reliability is covered by Tasks 1–4; privacy and
  data safety by Task 5; screenshots by Task 6; video by Task 7; AAB by Task 8;
  external setup by Task 9; push and handoff by Task 10.
- Placeholder scan: no `TBD`, `TODO`, or unspecified implementation step is
  required; environment-provided AdMob IDs are intentionally supplied by the
  AdMob setup task and validated before release.
- Type consistency: `MonetizationConfig`, `MonetizationState`, `AdRetryPolicy`,
  `InterstitialGate`, `MonetizationService`, `MonetizationController`,
  `StableBannerAd`, and `RemoveAdsCard` are introduced in dependency order.
