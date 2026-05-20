<p align="center">
  <a href="http://nestjs.com/" target="blank"><img src="https://nestjs.com/img/logo-small.svg" width="120" alt="Nest Logo" /></a>
</p>

[circleci-image]: https://img.shields.io/circleci/build/github/nestjs/nest/master?token=abc123def456
[circleci-url]: https://circleci.com/gh/nestjs/nest

  <p align="center">A progressive <a href="http://nodejs.org" target="_blank">Node.js</a> framework for building efficient and scalable server-side applications.</p>
    <p align="center">
<a href="https://www.npmjs.com/~nestjscore" target="_blank"><img src="https://img.shields.io/npm/v/@nestjs/core.svg" alt="NPM Version" /></a>
<a href="https://www.npmjs.com/~nestjscore" target="_blank"><img src="https://img.shields.io/npm/l/@nestjs/core.svg" alt="Package License" /></a>
<a href="https://www.npmjs.com/~nestjscore" target="_blank"><img src="https://img.shields.io/npm/dm/@nestjs/common.svg" alt="NPM Downloads" /></a>
<a href="https://circleci.com/gh/nestjs/nest" target="_blank"><img src="https://img.shields.io/circleci/build/github/nestjs/nest/master" alt="CircleCI" /></a>
<a href="https://discord.gg/G7Qnnhy" target="_blank"><img src="https://img.shields.io/badge/discord-online-brightgreen.svg" alt="Discord"/></a>
<a href="https://opencollective.com/nest#backer" target="_blank"><img src="https://opencollective.com/nest/backers/badge.svg" alt="Backers on Open Collective" /></a>
<a href="https://opencollective.com/nest#sponsor" target="_blank"><img src="https://opencollective.com/nest/sponsors/badge.svg" alt="Sponsors on Open Collective" /></a>
  <a href="https://paypal.me/kamilmysliwiec" target="_blank"><img src="https://img.shields.io/badge/Donate-PayPal-ff3f59.svg" alt="Donate us"/></a>
    <a href="https://opencollective.com/nest#sponsor"  target="_blank"><img src="https://img.shields.io/badge/Support%20us-Open%20Collective-41B883.svg" alt="Support us"></a>
  <a href="https://twitter.com/nestframework" target="_blank"><img src="https://img.shields.io/twitter/follow/nestframework.svg?style=social&label=Follow" alt="Follow us on Twitter"></a>
</p>
  <!--[![Backers on Open Collective](https://opencollective.com/nest/backers/badge.svg)](https://opencollective.com/nest#backer)
  [![Sponsors on Open Collective](https://opencollective.com/nest/sponsors/badge.svg)](https://opencollective.com/nest#sponsor)-->

## Description

[Nest](https://github.com/nestjs/nest) framework TypeScript starter repository.

## Project setup

```bash
$ pnpm install
```

## Compile and run the project

```bash
# development
$ pnpm run start

# watch mode
$ pnpm run start:dev

# production mode
$ pnpm run start:prod
```

## Run tests

```bash
# unit tests
$ pnpm run test

# e2e tests
$ pnpm run test:e2e

# test coverage
$ pnpm run test:cov
```

## Deployment

### Deploy ke Vercel (disarankan)

NestJS **bisa** di-deploy ke Vercel. Cara yang paling stabil: gunakan **Root Directory = `backend`**, bukan deploy dari root monorepo dengan folder `api/` custom.

Vercel mendukung NestJS secara native sejak 2025 ([docs](https://vercel.com/docs/frameworks/backend/nestjs)) — `src/main.ts` langsung jadi satu serverless function, tanpa copy `node_modules` manual.

**Setup Vercel (penting — ikuti persis)**

1. Buka project di Vercel → **Settings → General**
2. Set **Root Directory** = `backend` → Save
3. Buka **Settings → Build and Deployment**
4. **Matikan semua Production Overrides** jika bisa (Install Command, Build Command, Output Directory)
5. **Framework Preset**: biarkan auto-detect NestJS, atau `Other`
6. **Output Directory**: kosong / default — [`vercel.json`](vercel.json) sudah set `public` (folder kosong, hanya untuk satisfy Vercel static check)
7. Set environment variables di **Settings → Environment Variables**:

| Variable | Keterangan |
|----------|------------|
| `FIREBASE_PROJECT_ID` | Firebase project ID |
| `FIREBASE_CLIENT_EMAIL` | Service account email |
| `FIREBASE_PRIVATE_KEY` | Private key dengan literal `\n` |

8. Redeploy

**API entry point & routes**

Entry point NestJS: [`src/main.ts`](src/main.ts) — Vercel mendeteksinya otomatis (zero-config).

Semua route berada di **root URL**, bukan di prefix `/api` Vercel:

| URL | Keterangan |
|-----|------------|
| `GET /` | Health check → `Hello World!` |
| `GET /meta/food-categories` | Public metadata |
| `GET /meta/nutrition-grades` | Public metadata |
| `POST /auth/signup` | Auth (butuh Firebase token) |
| `GET /foods` | Foods (butuh Firebase token) |
| `GET /api` | **Swagger UI** (dokumentasi interaktif) |

> `/api` di sini = Swagger docs NestJS, **bukan** folder `api/` Vercel serverless.

Jika `GET /` menampilkan **404 Not Found** (bukan 500): Vercel mungkin hanya serve folder `public/` static tanpa menjalankan NestJS. Pastikan **Production Override `framework: null` tidak aktif** dan [`vercel.json`](vercel.json) **tidak** set `"framework": null` atau `"outputDirectory": "public"`.

Override dari deploy lama (root monorepo) bisa "terkunci" di production deployment. Solusi:

1. **Commit fix terbaru** — [`vercel.json`](vercel.json) tanpa `framework: null` agar NestJS terdeteksi; [`public/.gitkeep`](public/.gitkeep) tetap ada jika override masih butuh folder `public`
2. Atau buat **Vercel project baru** (import repo yang sama, Root Directory = `backend`) — paling bersih, tanpa override legacy
3. Di Build Settings, toggle **Override** di baris Project Settings (bukan Production Overrides) — matikan satu per satu

**Verifikasi**

```bash
curl https://<project>.vercel.app/
curl https://<project>.vercel.app/meta/food-categories
```

Swagger UI: `https://<project>.vercel.app/api`

**Update Flutter app**

Ubah `baseUrl` di `frontend/lib/core/constants/api_constants.dart` ke URL Vercel production.

**Local development**

```bash
cd backend
pnpm install
pnpm run start:dev
```

Simulasi Vercel lokal (dari folder `backend/`):

```bash
cd backend
vercel dev
```

### Alternatif jika Vercel bermasalah

Platform yang menjalankan NestJS sebagai **Node.js server biasa** (lebih sederhana, tanpa serverless adapter):

| Platform | Keterangan |
|----------|------------|
| [Railway](https://railway.app) | Root: `backend`, start: `pnpm start:prod` |
| [Render](https://render.com) | Root: `backend`, build: `pnpm build`, start: `node dist/main` |
| [Fly.io](https://fly.io) | Docker atau `fly launch` di folder `backend` |

Build command: `pnpm install && pnpm build`  
Start command: `node dist/main`

### Mengapa tidak deploy dari root monorepo?

Deploy NestJS dari **root repo** (`gizigo/`) di Vercel membutuhkan workaround manual (copy dist, symlink node_modules, `includeFiles`, dll.) yang rapuh dan sering gagal. Root Directory = `backend` adalah pola resmi Vercel untuk monorepo — repo tetap monorepo, hanya **setting Vercel** yang menunjuk ke subfolder `backend/`.

### Deployment lainnya

When you're ready to deploy your NestJS application to production, there are some key steps you can take to ensure it runs as efficiently as possible. Check out the [deployment documentation](https://docs.nestjs.com/deployment) for more information.

## Resources

Check out a few resources that may come in handy when working with NestJS:

- Visit the [NestJS Documentation](https://docs.nestjs.com) to learn more about the framework.
- For questions and support, please visit our [Discord channel](https://discord.gg/G7Qnnhy).
- To dive deeper and get more hands-on experience, check out our official video [courses](https://courses.nestjs.com/).
- Deploy your application to AWS with the help of [NestJS Mau](https://mau.nestjs.com) in just a few clicks.
- Visualize your application graph and interact with the NestJS application in real-time using [NestJS Devtools](https://devtools.nestjs.com).
- Need help with your project (part-time to full-time)? Check out our official [enterprise support](https://enterprise.nestjs.com).
- To stay in the loop and get updates, follow us on [X](https://x.com/nestframework) and [LinkedIn](https://linkedin.com/company/nestjs).
- Looking for a job, or have a job to offer? Check out our official [Jobs board](https://jobs.nestjs.com).

## Support

Nest is an MIT-licensed open source project. It can grow thanks to the sponsors and support by the amazing backers. If you'd like to join them, please [read more here](https://docs.nestjs.com/support).

## Stay in touch

- Author - [Kamil Myśliwiec](https://twitter.com/kammysliwiec)
- Website - [https://nestjs.com](https://nestjs.com/)
- Twitter - [@nestframework](https://twitter.com/nestframework)

## License

Nest is [MIT licensed](https://github.com/nestjs/nest/blob/master/LICENSE).
