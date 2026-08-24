# Arunika: Tumbuh Bersama — Product & UI/UX Design

## Product intent

Arunika becomes a premium, offline-first family ritual and memory journal for adult caregivers. It helps a family choose small repeatable rituals, capture meaningful moments, and look back at a calm weekly recap.

The product must not collect, calculate, interpret, or display height, weight, nutrition, immunization, developmental assessment, diagnosis, treatment, or other health content. The existing health-oriented screens and copy are replaced, not merely hidden behind a new label.

The package ID remains `id.arunika.arunika_growth` so the existing Play listing and release history can be updated rather than creating a duplicate app.

## Design direction

### Recommended aesthetic

Use an **Editorial Sunrise** direction: warm ivory paper, espresso ink, champagne gold, muted sage, and soft terracotta accents. Preserve the existing Fraunces and Plus Jakarta Sans assets, but increase hierarchy, whitespace, and contrast so the interface feels like a premium printed family journal rather than a dashboard.

Use the **Asymmetrical Bento** layout on the Today screen, a vertical editorial timeline on Moments, and a garden-like constellation on the weekly Taman recap. Major surfaces use nested shells: an outer tonal bezel plus an inner content core. Cards are spacious, gently rounded, and never presented as a dense two-column admin grid.

### Brand language

- Product name: `Arunika: Tumbuh Bersama`
- Primary CTA: `Tambah momen`
- Ritual completion: `Selesai untuk hari ini`
- Empty-state voice: gentle, direct, and non-judgmental
- Avoid streak pressure, medical language, or competitive child scoring
- The caregiver is the user; the child is a private family profile, not an account

### Navigation

Four persistent destinations:

1. `Hari Ini` — the daily command center
2. `Ritual` — repeatable family routines
3. `Momen` — memory timeline and entries
4. `Taman` — weekly and monthly reflections

The profile switcher sits in the Today header. A centered floating `Tambah` action opens a bottom-sheet action rail with `Catat momen`, `Buat ritual`, and `Tambah foto`.

The existing stable banner remains mounted only in browse surfaces, above the bottom navigation. Compose flows never show an ad over an input or media picker.

## Core experience

### Onboarding

Use four short editorial panels:

1. `Ritual kecil, hari yang terasa` — explain the one-tap daily ritual loop.
2. `Simpan yang ingin diingat` — show a private moment card.
3. `Lihat perjalanan bersama` — show the Taman recap.
4. `Tetap milik keluarga` — explain local-first storage and backup/restore.

The onboarding asks for the first family member only after the value is understood. It never asks for birth date, gender, weight, height, or other health-related fields.

### Today screen

The screen opens with a calm greeting and a sun-phase eyebrow such as `SENIN PAGI · 24 AGUSTUS`.

Content order:

- Greeting header with family profile switcher and settings access
- Large `Hari ini` hero card with a sunrise arc, one featured ritual, and progress expressed as warm light segments rather than a competitive percentage
- `Tiga menit untuk bersama` ritual strip with up to three next actions
- `Momen terakhir` horizontal memory preview
- `Catatan kecil minggu ini` recap card
- Secondary quick actions in an asymmetrical bento arrangement

When there is no data, show one decisive CTA and a small example card; never show a blank grid.

### Rituals screen

Rituals are grouped into `Pagi`, `Siang`, `Sore`, and `Kapan saja`.

Each ritual has:

- title
- optional family member
- time-of-day group
- repeat days or flexible cadence
- optional reminder time
- color/mark chosen from the Arunika palette
- active/paused state

The list uses a vertical time rail and compact nested cards. Completing a ritual uses a spring check animation and a haptic tap. Skipping a ritual uses copy such as `Lewati hari ini`, never `gagal`.

Ritual creation is a focused three-step bottom-sheet flow: name and suggestion, cadence, reminder. The form has large touch targets and preserves draft state if dismissed.

### Moments screen

Moments are ordered newest first in an editorial timeline with month separators.

Each moment can contain:

- date
- title
- short note
- optional photo
- optional family member
- one of five tags: `Tawa`, `Belajar`, `Bersama`, `Berani`, `Syukur`

The editor is a clean full-screen composition surface with a large title field, photo tile, note area, and tag chips. It includes a live preview of the final memory card before saving.

The first release supports text and photos. Audio is intentionally deferred until the local storage and permission experience is proven.

### Taman screen

Taman is a reflection surface, not a score screen.

- Weekly recap: completed rituals, number of moments, and a short generated-from-local-data sentence
- A constellation of memory cards positioned around a sunrise disc
- Monthly view with one highlighted family theme based only on selected tags
- Export as a scrapbook PDF with the same warm editorial visual language

The recap must remain useful with sparse data. For example, two moments still produce a meaningful recap; there is no “empty failure” state.

### Family profiles

Profiles contain only the data needed for personalization:

- name
- optional photo
- optional color identity
- optional relationship label

Existing child profiles can be reused as family members where possible. Existing health-only fields are not displayed in the new UI and are not written by the new product.

### Settings and privacy

Settings include:

- profile management
- theme selection
- reminder preferences
- local backup and restore
- export all moments
- privacy policy
- Remove Ads purchase and restore purchase
- reduced-motion option

The app remains offline-first. Photos use app-private storage, SQLite stores metadata, and no Arunika server is introduced.

## Data architecture

Add focused models and repositories:

- `Ritual`: id, title, memberId, timeOfDay, cadence, reminderTime, colorKey, isActive, createdAt
- `RitualCheckIn`: ritualId, dayKey, completedAt
- `Moment`: id, memberId, date, title, note, photoPath, tag, createdAt
- `FamilyTheme`: persisted theme key and reduced-motion preference

Create SQLite tables for rituals, ritual check-ins, and moments. Bump the schema version. Keep legacy tables available for a safe upgrade, but remove all new reads and writes to health-oriented repositories. Do not silently expose legacy measurements in the new product.

Use Riverpod notifiers for:

- selected member
- today rituals and completion actions
- moment timeline and moment actions
- weekly recap derivation
- theme and accessibility settings

The recap is derived locally from rituals, check-ins, moments, and tags. No network call or AI service is required.

## Motion and interaction rules

- Use spring-like curves for completion, sheet transitions, and tab changes.
- Animate only opacity and transforms.
- Use staggered entry for Today sections, with reduced-motion fallback.
- Respect Android back behavior and preserve form drafts.
- Every interactive target is at least 48 logical pixels.
- Keep contrast at WCAG AA for text and controls.
- The banner slot remains reserved and visible while an ad is loading or retrying.

## Monetization

- Stable anchored banner on Today, Rituals, Moments, Taman, and settings browse surfaces.
- No banner inside the moment editor, ritual editor, photo picker, or onboarding.
- Interstitial only after a natural completion point, such as the third successful moment/ritual save, with the existing ten-minute cooldown.
- `arunika_remove_ads` remains a one-time US$4.99 purchase.
- Verified entitlement removes both the banner slot and interstitial behavior.

## Content and store positioning

Use the new store title `Arunika: Tumbuh Bersama` and position it under Parenting or Lifestyle as appropriate. Store copy must describe routines, family moments, privacy, and reflection. Remove references to WHO, CDC, z-score, status gizi, stunting, immunization, nutrition, doctor reports, and health outcomes.

## Acceptance criteria

- A new user can onboard, create a family member, create a ritual, complete it, add a photo moment, and see it in Today, Moments, and Taman.
- All core flows work offline after initial install.
- Existing ad behavior remains stable and does not overlay compose surfaces.
- Remove Ads continues to hide all ad placements after entitlement verification.
- No health-related screen, model write path, copy, asset, or store metadata remains in the active product.
- `flutter analyze`, all tests, and a release AAB build pass.
- The app feels distinct from a generic planner: sunrise phase language, editorial memory cards, ritual time rail, and Taman recap are visible in the first session.
