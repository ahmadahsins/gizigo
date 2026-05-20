# GiziGo Backend

REST API untuk aplikasi GiziGo (student food-discovery), dibangun dengan [NestJS 11](https://nestjs.com/) + Firebase Admin (Auth & Firestore).

## Prasyarat

- Node.js 20.x
- pnpm 10.x

## Setup lokal

```bash
pnpm install
cp .env.example .env   # isi credential Firebase
pnpm run start:dev
```

Server berjalan di `http://localhost:3000`. Swagger UI di `/api`.

## Scripts

| Command | Fungsi |
|---------|--------|
| `pnpm run start:dev` | Dev server + hot reload |
| `pnpm run build` | Compile ke `dist/` |
| `pnpm run start:prod` | Jalankan production build |
| `pnpm run test` | Unit tests |
| `pnpm run test:e2e` | End-to-end tests |
| `pnpm run seed:foods` | Seed data makanan ke Firestore |

## API Routes

Entry point: [`src/main.ts`](src/main.ts)

| Method | Path | Auth | Keterangan |
|--------|------|------|------------|
| `GET` | `/` | — | Health check |
| `GET` | `/meta/*` | — | Metadata publik |
| `POST` | `/auth/signup` | Bearer | Sync user setelah Firebase signup |
| `GET` | `/foods` | Bearer | Daftar & search makanan |
| `GET` | `/foods/recommendations` | Bearer | Rekomendasi home |
| `PATCH` | `/users/me` | Bearer | Update profil |
| `GET` | `/api` | — | Swagger UI |

## Deployment

### Vercel

Repo ini bagian dari monorepo (`gizigo/`). Deploy dengan **Root Directory = `backend`**.

NestJS dijalankan via [`api/index.js`](api/index.js) + rewrites (cocok dengan Framework Preset **Other** di Vercel). [`src/main.ts`](src/main.ts) tetap dipakai untuk development lokal.

#### 1. Konfigurasi project

1. Import repo di [vercel.com/new](https://vercel.com/new)
2. **Settings → General → Root Directory** → `backend` → **Save**
3. **Settings → Build and Deployment**
   - Framework Preset: **Other** (OK)
   - Override Install / Build / Output: **OFF**
   - Output Directory: **kosong**
4. Build & routing diatur [`vercel.json`](vercel.json) — jangan override manual

#### Arsitektur deploy

```
Request → Vercel rewrite → api/index.js → dist/src/serverless.js → NestJS
```

| File | Fungsi |
|------|--------|
| [`api/index.js`](api/index.js) | Entry point Vercel |
| [`src/serverless.ts`](src/serverless.ts) | Handler serverless + cache cold-start |
| [`src/main.ts`](src/main.ts) | Dev lokal (`pnpm start:dev`) |
| [`vercel.json`](vercel.json) | Build (copy `dist` ke `api/dist/`), rewrites, function limits |

#### 2. Environment variables

Set di **Settings → Environment Variables** (Production + Preview):

| Variable | Keterangan |
|----------|------------|
| `FIREBASE_PROJECT_ID` | Firebase project ID |
| `FIREBASE_CLIENT_EMAIL` | Service account email |
| `FIREBASE_PRIVATE_KEY` | Private key; gunakan literal `\n` antar baris |

Contoh format private key:

```
-----BEGIN PRIVATE KEY-----\nMIIEv...\n-----END PRIVATE KEY-----\n
```

#### 3. Deploy & verifikasi

```bash
curl https://<project>.vercel.app/
curl https://<project>.vercel.app/meta/food-categories
```

- Swagger: `https://<project>.vercel.app/api`
- Update `baseUrl` di `frontend/lib/core/constants/api_constants.dart`

Simulasi lokal:

```bash
vercel dev
```

#### Troubleshooting

| Gejala | Penyebab & solusi |
|--------|-------------------|
| `NOT_FOUND` di semua route | Rewrites tidak aktif — pastikan [`vercel.json`](vercel.json) punya `"rewrites"` ke `/api` |
| Build error `public` not found | Folder [`public/.gitkeep`](public/.gitkeep) wajib ada (Framework `Other` butuh output directory) |
| `500 FUNCTION_INVOCATION_FAILED` | Cek Runtime Logs; biasanya `dist/` tidak ter-bundle — build command harus copy ke `api/dist/` |

### Platform alternatif

Jika Vercel bermasalah, gunakan Node.js server biasa:

| Platform | Root | Build | Start |
|----------|------|-------|-------|
| [Railway](https://railway.app) | `backend` | `pnpm install && pnpm build` | `node dist/main` |
| [Render](https://render.com) | `backend` | `pnpm install && pnpm build` | `node dist/main` |

## Environment

Lihat [`.env.example`](.env.example) untuk daftar lengkap variabel.
