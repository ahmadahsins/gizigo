# GiziGo Backend

REST API untuk aplikasi **GiziGo** (student food-discovery), dibangun dengan [NestJS 11](https://nestjs.com/) + Firebase Admin (Auth & Firestore).

---

## Prasyarat

| Requirement | Versi |
|-------------|-------|
| Node.js     | 20.x  |
| pnpm        | 10.x  |

## Setup Lokal

```bash
pnpm install
cp .env.example .env   # isi credential Firebase
pnpm run start:dev
```

Server berjalan di `http://localhost:3000`. Swagger UI tersedia di `/api`.

## Scripts

| Command                | Fungsi                          |
|------------------------|---------------------------------|
| `pnpm run start:dev`   | Dev server + hot reload         |
| `pnpm run build`       | Compile TypeScript ke `dist/`   |
| `pnpm run start:prod`  | Jalankan production build       |
| `pnpm run test`        | Unit tests                      |
| `pnpm run test:e2e`    | End-to-end tests                |
| `pnpm run seed:foods`  | Seed data makanan ke Firestore  |

## API Routes

| Method  | Path                    | Auth   | Keterangan                        |
|---------|-------------------------|--------|-----------------------------------|
| `GET`   | `/`                     | —      | Health check                      |
| `GET`   | `/meta/*`               | —      | Metadata publik                   |
| `POST`  | `/auth/signup`          | Bearer | Sync user setelah Firebase signup |
| `GET`   | `/foods`                | Bearer | Daftar & search makanan           |
| `GET`   | `/foods/recommendations`| Bearer | Rekomendasi home                  |
| `PATCH` | `/users/me`             | Bearer | Update profil                     |
| `GET`   | `/api`                  | —      | Swagger UI                        |

---

## Deployment ke Vercel

Repo ini bagian dari monorepo `gizigo/`. Deploy dengan **Root Directory = `backend`**.

### Arsitektur

```
Request ─→ Vercel rewrite (/*) ─→ api/index.js ─→ dist/src/serverless.js ─→ Express/NestJS
```

| File | Peran |
|------|-------|
| [`vercel.json`](vercel.json) | Build command, rewrites, function config |
| [`api/index.js`](api/index.js) | Entry point serverless function Vercel |
| [`src/serverless.ts`](src/serverless.ts) | Bootstrap NestJS ke Express handler (Vercel `req/res`) |
| [`src/main.ts`](src/main.ts) | Entry point development lokal (`pnpm start:dev`) |

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

| Variable               | Keterangan                                         |
|------------------------|----------------------------------------------------|
| `FIREBASE_PROJECT_ID`  | Firebase project ID                                |
| `FIREBASE_CLIENT_EMAIL`| Service account email                              |
| `FIREBASE_PRIVATE_KEY` | Private key (gunakan literal `\n` antar baris)     |

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

| Gejala | Penyebab & Solusi |
|--------|-------------------|
| `NOT_FOUND` di semua route | Rewrites tidak aktif — pastikan [`vercel.json`](vercel.json) punya entry `"rewrites": [{ "source": "/(.*)", "destination": "/api" }]` |
| Build error: `public` not found | Folder [`public/.gitkeep`](public/.gitkeep) harus ada di repo (Framework **Other** membutuhkan output directory) |
| `500 FUNCTION_INVOCATION_FAILED` | Cek **Runtime Logs** di dashboard Vercel. Kemungkinan: `dist/` tidak ter-copy ke `api/dist/` — pastikan build command di `vercel.json` mencakup `cp -r dist api/dist` |
| `Unable to determine event source` | Handler serverless masih menggunakan adapter AWS Lambda (`@vendia/serverless-express`). Ganti ke direct Express handler — lihat [`src/serverless.ts`](src/serverless.ts) |

---

## Platform Alternatif

Jika Vercel bermasalah, deploy sebagai Node.js server biasa:

| Platform | Root | Build | Start |
|----------|------|-------|-------|
| [Railway](https://railway.app) | `backend` | `pnpm install && pnpm build` | `node dist/main` |
| [Render](https://render.com)   | `backend` | `pnpm install && pnpm build` | `node dist/main` |

---

## Environment

Lihat [`.env.example`](.env.example) untuk daftar lengkap variabel yang diperlukan.
