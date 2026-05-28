# GiziGo Backend

REST API untuk aplikasi **GiziGo** (student food-discovery), dibangun dengan [NestJS 11](https://nestjs.com/) + Firebase Admin (Auth & Firestore).

---

## Prasyarat

| Requirement | Versi |
| ----------- | ----- |
| Node.js     | 20.x  |
| pnpm        | 10.x  |

## Setup Lokal

```bash
pnpm install
cp .env.example .env   # isi credential Firebase
pnpm run start:dev
```

Server berjalan di `http://localhost:3000`. Swagger UI tersedia di `/api`.

## Gemini AI

Set `GEMINI_API_KEY` untuk mengaktifkan analisis gizi menu dan rekomendasi
personal. `GEMINI_MODEL` opsional dan default-nya `gemini-2.5-flash`;
`GEMINI_TIMEOUT_MS` default-nya `20000`.

- `POST /merchant/foods`, endpoint canonical
  `POST /admin/merchants/:merchantId/foods`, dan endpoint legacy
  `POST /admin/foods` menerima `recipe` berisi
  `servings` serta bahan dengan unit `pcs`, `g`, `ml`, `l`, `tsp`, `tbsp`,
  `cup`, atau `slice`.
- `recipe` hanya dipakai selama request analisis. Backend tidak menyimpannya
  ke Firestore dan tidak mengembalikannya pada response.
- Gemini menghasilkan `nutritional_info` per serving dan `nutrition_grade`.
  Menu dengan grade di bawah `GOOD` ditolak dengan status `422`.
- `PUT .../foods/:id` hanya menjalankan analisis ulang bila request membawa
  `recipe`; perubahan metadata tidak mengubah hasil gizi.
- Foto tidak dikirim pada create menu. Setelah create sukses, unggah gambar
  melalui `POST /merchant/foods/:id/photo` atau endpoint admin canonical
  `POST /admin/merchants/:merchantId/foods/:foodId/photo`;
  backend menyimpan URL Cloudinary pada `photo_url`.
- `GET /foods/recommendations` memakai data profil dan preferensi untuk
  meranking menu tersedia. Bila AI tidak tersedia, endpoint menggunakan
  ranking lokal dan mengembalikan `context.recommendation_source: "fallback"`.
- Price comparison memakai Universal Mock: create/update menu boleh mengirim
  `comparison_data` berisi URL GoFood/GrabFood/ShopeeFood saja. Backend
  menghasilkan harga platform dari `base_price` saat `GET /foods/:id`;
  nilainya fixed dalam window UTC enam jam dan dilengkapi
  `price_comparison_updated_at` serta `price_comparison_valid_until`. Harga
  platform tidak disimpan di Firestore.

## Merchant Menu Management

- `GET /merchant/me` mengembalikan business profile termasuk
  `business_email`; email ditampilkan pada profil tetapi tidak diubah melalui
  endpoint profil merchant.
- `GET /merchant/dashboard` mengembalikan jumlah menu aktif dan nonaktif untuk
  kartu landing page merchant.
- `GET /merchant/foods?q=&is_available=&page=&limit=` mendukung pencarian dan
  tab All / Active / Inactive. `GET /merchant/foods/:id` menampilkan detail
  menu sendiri, termasuk menu yang sedang hidden.
- `POST /merchant/foods` mengikat menu otomatis ke merchant yang login; Flutter
  tidak mengirim `merchant_id`. Request wajib memuat `recipe`, lalu foto
  dikirim terpisah ke `POST /merchant/foods/:id/photo` setelah menu lolos
  analisis.
- Flutter dapat mengirim deeplink opsional di `comparison_data`, misalnya
  `{ "gofood": { "url": "https://..." } }`; form tidak perlu meminta harga
  GoFood/GrabFood/ShopeeFood.
- `PUT /merchant/foods/:id` dapat mengubah metadata atau toggle
  `is_available`; Gemini hanya dipanggil kembali bila `recipe` baru dikirim.

## Admin Merchant Management

- `GET /admin/dashboard` menyediakan total merchant dan jumlah menu
  aktif/nonaktif untuk landing page admin.
- `GET /admin/merchants?q=&is_active=&page=&limit=` mendukung pencarian nama,
  alamat, atau business email.
- `POST /admin/merchants` menerima `name`, `business_email`, `password`,
  `address`, `lat`, dan `lng`. Backend membuat akun Firebase Auth serta
  dokumen merchant/user yang terhubung. Password tidak pernah disimpan di
  Firestore atau dikembalikan pada response.
- Menonaktifkan atau menghapus merchant akan men-disable akun login dan
  menyembunyikan menu merchant tersebut dari endpoint customer. Reactivation
  mengaktifkan akun dan menampilkan kembali menu yang masih available.
- UI admin baru harus memakai route menu bersarang
  `/admin/merchants/:merchantId/foods`; route global `/admin/foods` tetap ada
  hanya untuk client lama.

## Scripts

| Command               | Fungsi                         |
| --------------------- | ------------------------------ |
| `pnpm run start:dev`  | Dev server + hot reload        |
| `pnpm run build`      | Compile TypeScript ke `dist/`  |
| `pnpm run start:prod` | Jalankan production build      |
| `pnpm run test`       | Unit tests                     |
| `pnpm run test:e2e`   | End-to-end tests               |
| `pnpm run seed:foods` | Seed data makanan ke Firestore |

## API Routes

| Method  | Path                                               | Auth     | Keterangan                        |
| ------- | -------------------------------------------------- | -------- | --------------------------------- |
| `GET`   | `/`                                                | —        | Health check                      |
| `GET`   | `/meta/*`                                          | —        | Metadata publik                   |
| `POST`  | `/auth/signup`                                     | Bearer   | Sync user setelah Firebase signup |
| `GET`   | `/foods`                                           | Bearer   | Daftar & search makanan           |
| `GET`   | `/foods/recommendations`                           | Bearer   | Rekomendasi home                  |
| `PATCH` | `/users/me`                                        | Bearer   | Update profil                     |
| `POST`  | `/users/me/photo`                                  | Bearer   | Upload foto profil ke Cloudinary  |
| `GET`   | `/merchant/me`                                     | Merchant | Profil bisnis merchant            |
| `GET`   | `/merchant/dashboard`                              | Merchant | Statistik menu merchant           |
| `GET`   | `/merchant/foods`                                  | Merchant | Search/filter menu sendiri        |
| `POST`  | `/merchant/foods`                                  | Merchant | Buat menu dengan analisis Gemini  |
| `POST`  | `/merchant/foods/:id/photo`                        | Merchant | Upload foto menu milik sendiri    |
| `GET`   | `/admin/dashboard`                                 | Admin    | Statistik landing admin           |
| `POST`  | `/admin/merchants`                                 | Admin    | Buat akun dan toko merchant       |
| `POST`  | `/admin/merchants/:merchantId/foods`               | Admin    | Buat menu merchant                |
| `POST`  | `/admin/merchants/:merchantId/foods/:foodId/photo` | Admin    | Upload foto menu                  |
| `POST`  | `/admin/foods/:id/photo`                           | Admin    | Upload foto menu legacy           |
| `GET`   | `/api`                                             | —        | Swagger UI                        |

---

## Deployment ke Vercel

Repo ini bagian dari monorepo `gizigo/`. Deploy dengan **Root Directory = `backend`**.

### Arsitektur

```
Request ─→ Vercel rewrite (/*) ─→ api/index.js ─→ dist/src/serverless.js ─→ Express/NestJS
```

| File                                     | Peran                                                  |
| ---------------------------------------- | ------------------------------------------------------ |
| [`vercel.json`](vercel.json)             | Build command, rewrites, function config               |
| [`api/index.js`](api/index.js)           | Entry point serverless function Vercel                 |
| [`src/serverless.ts`](src/serverless.ts) | Bootstrap NestJS ke Express handler (Vercel `req/res`) |
| [`src/main.ts`](src/main.ts)             | Entry point development lokal (`pnpm start:dev`)       |

### Langkah 1 — Konfigurasi Project

1. Import repo di [vercel.com/new](https://vercel.com/new).
2. **Settings → General → Root Directory** → ketik `backend` → **Save**.
3. **Settings → Build and Deployment:**
   - Framework Preset: **Other**
   - Override Install / Build / Output: **OFF** (biarkan default)
   - Output Directory: biarkan **kosong**
4. Semua build & routing sudah diatur di [`vercel.json`](vercel.json) — **jangan override manual**.

### Langkah 2 — Environment Variables

Set di **Settings → Environment Variables** (centang Production + Preview):

| Variable                | Keterangan                                        |
| ----------------------- | ------------------------------------------------- |
| `FIREBASE_PROJECT_ID`   | Firebase project ID                               |
| `FIREBASE_CLIENT_EMAIL` | Service account email                             |
| `FIREBASE_PRIVATE_KEY`  | Private key (gunakan literal `\n` antar baris)    |
| `GEMINI_API_KEY`        | API key Gemini untuk analisis/rekomendasi AI      |
| `GEMINI_MODEL`          | Model Gemini opsional; default `gemini-2.5-flash` |
| `GEMINI_TIMEOUT_MS`     | Timeout request AI opsional; default `20000` ms   |

Format `FIREBASE_PRIVATE_KEY`:

```
-----BEGIN PRIVATE KEY-----\nMIIEv...\n-----END PRIVATE KEY-----\n
```

> Paste **satu baris** dengan `\n` literal — jangan newline sungguhan.

### Langkah 3 — Deploy & Verifikasi

Setelah push ke branch utama, Vercel otomatis build. Verifikasi:

```bash
# Health check
curl https://<project>.vercel.app/

# Endpoint publik
curl https://<project>.vercel.app/meta/food-categories
```

- **Swagger UI:** `https://<project>.vercel.app/api`
- Jangan lupa update `baseUrl` di `frontend/lib/core/constants/api_constants.dart`.

Simulasi lokal dengan Vercel CLI:

```bash
vercel dev
```

### Troubleshooting

Untuk Swagger UI di Vercel, file static dari `swagger-ui-dist` harus ikut
dibundel dalam function. Konfigurasi `vercel.json` mempertahankan aset tersebut
melalui `includeFiles: "api/dist/node_modules/swagger-ui-dist/**"`. Bila
`/api` menghasilkan HTML tetapi CSS atau JavaScript Swagger berstatus `404`,
Swagger juga memuat fallback asset dari jsDelivr yang diizinkan secara terbatas
pada CSP Helmet. Redeploy setelah memastikan konfigurasi ini tidak dihapus.

| Gejala                             | Penyebab & Solusi                                                                                                                                                        |
| ---------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `NOT_FOUND` di semua route         | Rewrites tidak aktif — pastikan [`vercel.json`](vercel.json) punya entry `"rewrites": [{ "source": "/(.*)", "destination": "/api" }]`                                    |
| Build error: `public` not found    | Folder [`public/.gitkeep`](public/.gitkeep) harus ada di repo (Framework **Other** membutuhkan output directory)                                                         |
| `500 FUNCTION_INVOCATION_FAILED`   | Cek **Runtime Logs** di dashboard Vercel. Kemungkinan: `dist/` tidak ter-copy ke `api/dist/` — pastikan build command di `vercel.json` mencakup `cp -r dist api/dist`    |
| `Nutrition analysis is temporarily unavailable` | Cek **Runtime Logs** untuk log `AiService`. Biasanya disebabkan timeout Gemini, quota/rate limit, model tidak tersedia untuk API key, atau response AI tidak sesuai schema. Set `GEMINI_TIMEOUT_MS=20000` atau nilai lain yang tetap di bawah `maxDuration` Vercel. |
| `Unable to determine event source` | Handler serverless masih menggunakan adapter AWS Lambda (`@vendia/serverless-express`). Ganti ke direct Express handler — lihat [`src/serverless.ts`](src/serverless.ts) |

---

## Platform Alternatif

Jika Vercel bermasalah, deploy sebagai Node.js server biasa:

| Platform                       | Root      | Build                        | Start            |
| ------------------------------ | --------- | ---------------------------- | ---------------- |
| [Railway](https://railway.app) | `backend` | `pnpm install && pnpm build` | `node dist/main` |
| [Render](https://render.com)   | `backend` | `pnpm install && pnpm build` | `node dist/main` |

---

## Environment

Lihat [`.env.example`](.env.example) untuk daftar lengkap variabel yang diperlukan.

### Upload Foto Profil

Kirim `multipart/form-data` ke `POST /users/me/photo` dengan field `file`.
File yang diterima adalah JPEG, PNG, atau WebP hingga 5 MB. Response berupa
profil user terbaru dengan field `profile_photo_url`; upload baru mengganti
aset Cloudinary user sebelumnya.

### Upload Foto Menu

Create menu tidak menerima `photo_url`. Setelah endpoint create mengembalikan
`id`, kirim `multipart/form-data` dengan field `file` ke
`POST /merchant/foods/:id/photo` atau
`POST /admin/merchants/:merchantId/foods/:foodId/photo`. Route
`POST /admin/foods/:id/photo` tetap tersedia sebagai kompatibilitas legacy. File yang
diterima adalah JPEG, PNG, atau WebP hingga 5 MB; URL hasil Cloudinary disimpan
backend ke `photo_url`. Upload foto tidak menjalankan analisis gizi ulang.
