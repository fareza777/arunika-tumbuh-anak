# Arunika: Tumbuh Bersama — Promo Video

Promo ini memperkenalkan Arunika sebagai ruang privat untuk ritual dan momen
keluarga. Komposisi landscape memakai narasi tujuh scene; folder
`Store-Screenshots` menyediakan delapan still portrait untuk listing Play
Store.

## Commands

```powershell
npm i
npm run lint
npx remotion studio --no-open
npx remotion render ArunikaPromo ../store/arunika-promo.mp4
```

Untuk merender screenshot store:

```powershell
$shots = @('01-today','02-rituals','03-ritual-editor','04-moments','05-moment-editor','06-garden','07-scrapbook','08-privacy-ads')
foreach ($shot in $shots) { npx remotion still $shot --output "../store/assets/$shot.png" }
```

Semua frame memakai palet ivory, espresso, champagne, terracotta, dan sage
yang sama dengan aplikasi Flutter. Headline dibuat besar dan singkat agar
terbaca pada thumbnail tanpa klaim kesehatan atau janji hasil.
