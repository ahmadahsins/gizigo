# Technical Specification: GiziGo Mobile Application

## 1. Project Overview

GiziGo adalah platform agregator makanan sehat yang ditujukan khusus untuk mahasiswa. Aplikasi ini memfasilitasi pencarian makanan bergizi dan memberikan perbandingan harga dari tiga layanan pengiriman makanan utama (GoFood, GrabFood, ShopeeFood) guna membantu mahasiswa mendapatkan pilihan terbaik sesuai anggaran.

---

## 2. System Architecture

Sistem menggunakan arsitektur **Client-Server** dengan komunikasi melalui **RESTful API**.

- **Frontend:** Flutter (Mobile App).
- **Backend:** Nest.js (REST API & Business Logic) dengan `firebase-admin` SDK.
- **Database & Infrastructure:** Firebase (Firestore & Authentication), Cloudinary untuk aset gambar, dan Vercel untuk deployment backend serverless.

---

## 3. Tech Stack Details

| Komponen              | Teknologi                        | Alasan Pemilihan                                                                                 |
| :-------------------- | :------------------------------- | :----------------------------------------------------------------------------------------------- |
| **Mobile App**        | Flutter                          | _Cross-platform_ (Android & iOS) dengan satu basis kode.                                         |
| **Backend Framework** | Nest.js                          | Struktur modular, dukungan TypeScript yang kuat, dan skalabilitas tinggi.                        |
| **Authentication**    | Firebase Auth & `firebase-admin` | Mendukung OAuth2 (Google Sign-In) di Frontend dan verifikasi token JWT di Backend via Admin SDK. |
| **Database**          | Cloud Firestore                  | _NoSQL document-based_, mendukung sinkronisasi _real-time_ dan query fleksibel.                  |
| **File Storage**      | Cloudinary                       | Penyimpanan aset gambar. Cloudinary cocok untuk optimasi gambar _on-the-fly_.                    |
| **AI Service**        | Gemini (`@google/genai`)         | Analisis gizi resep dan ranking rekomendasi personal.                                            |
| **API Documentation** | Swagger/OpenAPI                  | Standarisasi dokumentasi API untuk integrasi Frontend-Backend.                                   |
| **Backend Deploy**    | Vercel Serverless Function       | Backend NestJS dibungkus Express handler serverless melalui `api/index.js`.                      |

---

## 4. Database Schema (Firestore)

Struktur data dirancang untuk mendukung MVP UI (badge gizi, filter, lokasi, histori).

### A. Collection: `users`

- `uid`: string (Primary Key – sama dengan Firebase Auth UID; dokumen `users/{uid}`)
- `name`: string
- `username`: string (unique, opsional)
- `email`: string
- `role`: string (`customer`, `admin`, `merchant`)
- `merchant_id`: string (opsional; diisi untuk akun `merchant`, sama dengan ID dokumen `merchants`)
- `preferred_language`: string (opsional, mis. `en_US`)
- `dark_mode`: boolean (opsional; bisa juga hanya lokal di Flutter)
- **Onboarding / personalisasi (diset lewat `PATCH /users/me`):**
  - `gender`: string enum `MALE` | `FEMALE` | `OTHER` | `PREFER_NOT_TO_SAY`
  - `age`: number (tahun)
  - `weight_kg`, `height_cm`: number
  - `nutrition_goal`: string enum `DIET` | `BULKING` | `MAINTAIN` (memengaruhi `/foods/recommendations`)
- `food_preferences`: array string; preference tertentu dipakai sebagai hard filter rekomendasi (mis. `Vegetarian Lifestyle` -> menu dengan sinyal vegetarian/vegan/plant-based), lalu sisanya dipakai untuk scoring/ranking
- `dietary_restrictions`: array string (pembatasan diet untuk rekomendasi Gemini)
- `taste_profile`: array string (profil rasa untuk rekomendasi Gemini)
- `onboarding_completed`: boolean
- `created_at`: timestamp
- `updated_at`: timestamp (server)

Untuk merchant yang dibuat admin, dokumen `users/{uid}` menggunakan
`role: "merchant"`, `merchant_id` yang menunjuk dokumen toko,
`onboarding_completed: true`, dan `food_preferences: []`. Credential password
selalu berada di Firebase Auth dan tidak pernah menjadi field Firestore.

### B. Subcollections under `users/{uid}`

**`recently_viewed/{food_id}`** (ID dokumen = ID dokumen food di koleksi `foods`)

- `food_id`: string
- `viewed_at`: timestamp

**Firestore index disarankan:** subcollection `recently_viewed` dengan `orderBy viewed_at desc` (Firebase Console akan mengarahkan pembuatan index jika diperlukan).

**`recent_locations/{location_id}`** (`location_id` deterministik dari pembulatan lat/lng)

- `label`: string (mis. nama POI)
- `address`: string
- `lat`, `lng`: number
- `distance_km`: number (opsional; bisa diisi klien)
- `last_used_at`: timestamp

### C. Collection: `foods`

- `food_id`: string (disimpan konsisten dengan ID dokumen Firestore)
- `name`: string
- `description`: string
- `photo_url`: string (opsional sampai foto menu berhasil di-upload; URL Cloudinary ditetapkan backend, bukan input bebas pada create menu)
- **`nutrition_grade`**: string enum **`EXCELLENT` | `VERY_GOOD` | `GOOD`** (badge “Excellent / Very good / Good” + filter **Label** di UI)
- **`food_category`**: string salah satu: `main_course`, `appetizers`, `snacks`, `desserts`, `beverages`, `breakfast`, `lunch`, `dinner`, `salads` (chip **Categories** di home/search)
- `health_labels`: array string (tag tambahan, mis. “High Protein”; **bukan** pengganti `nutrition_grade`). Opsi statis form Flutter saat ini: `High Protein`, `Low Calorie`, `Vegan`, `Vegetarian`, `Low Carb`, `Gluten Free`, `Dairy Free`, `Sugar Free`.
- `nutritional_info`: map hasil analisis Gemini per serving `{ calories, protein_g, fat_g, carb_g }`
- `nutrition_assessment_reason`: string alasan penilaian umum dari Gemini
- `nutrition_analyzed_at`: timestamp analisis terakhir
- Resep dan rincian bahan bersifat request-only dan tidak disimpan di dokumen `foods`.
- `base_price`: number (IDR)
- `merchant_id`: string (referensi ke `merchants`)
- `is_available`: boolean
- `is_featured`: boolean (opsional; kartu hero “You Might Like This”)
- `recommendation_score`: number (opsional; urutan `sort=recommended`)
- `comparison_data`: konfigurasi deeplink per provider; tidak berisi harga platform
  - `gofood` | `grabfood` | `shopeefood`: `{ url: string, icon_url?: string }`
  - Harga comparison tidak disimpan di Firestore; backend mensimulasikannya dari `base_price` saat detail diminta.

### D. Collection: `merchants`

- `merchant_id`: string (Primary Key konsisten dengan referensi di `foods`)
- `owner_uid`: string (opsional; Firebase Auth UID pemilik akun merchant)
- `business_email`: string | null (email login/display admin; disinkronkan dengan Firebase Auth)
- `name`: string (nama warung / vendor untuk UI)
- `address`: string
- `coordinates`: GeoPoint
- `geohash`: string (opsional; optimasi radius)
- `is_verified`: boolean
- `is_active`: boolean (default `true`; soft delete set `false`)

Merchant buatan admin menggunakan UID akun Firebase Auth sebagai
`merchant_id`, `owner_uid`, sekaligus ID dokumen merchant. Password tidak
pernah disimpan, dicatat pada log, ataupun dikembalikan melalui API.

### E. Catatan query backend

- Listing saat ini mengambil semua `foods` dengan `is_available == true`, lalu memfilter/pagination di memori (cukup untuk dataset hackathon). Untuk produksi, tambahkan composite index Firestore jika memindahkan filter `nutrition_grade` / `food_category` ke query native.

---

## 5. API Design (Nest.js)

Base URL contoh: `https://<host>/` — dokumentasi interaktif: `GET /api` (Swagger).

**Header umum (endpoint terproteksi):** `Authorization: Bearer <Firebase_ID_Token>`

### 5.1 Authentication

| Method | Path           | Auth   | Keterangan                                                                                                                                                  |
| :----- | :------------- | :----- | :---------------------------------------------------------------------------------------------------------------------------------------------------------- |
| POST   | `/auth/sync`   | Bearer | Sinkronisasi user ke `users/{uid}` jika belum ada. Body opsional: `account_type` (`customer` default, `merchant`) + objek `merchant` (wajib jika merchant). |
| POST   | `/auth/signup` | Bearer | **Alias** handler yang sama dengan `/auth/sync` — panggil setelah Firebase signup. Merchant signup satu langkah: kirim profil toko bersamaan.               |

### 5.2 Meta (publik, tanpa token)

| Method | Path                        | Keterangan                                                                 |
| :----- | :-------------------------- | :------------------------------------------------------------------------- |
| GET    | `/meta/food-categories`     | Daftar kategori + label EN/ID untuk chip Flutter                           |
| GET    | `/meta/nutrition-grades`    | Daftar tier gizi + label EN/ID (selaras `nutrition_grade`)                 |
| GET    | `/meta/nutrition-goals`     | Label wizard untuk `nutrition_goal` (`DIET`, `BULKING`, `MAINTAIN`)        |
| GET    | `/meta/locations/search?q=` | **Placeholder** — backend mengembalikan `items: []`; pencarian alamat saat ini dilakukan Flutter via Nominatim/OpenStreetMap |

### 5.3 Foods (Bearer wajib)

| Method | Path                     | Keterangan                                                                                        |
| :----- | :----------------------- | :------------------------------------------------------------------------------------------------ |
| GET    | `/foods`                 | Daftar terpaginasi + filter; respons `{ items, total, page, limit, total_pages }`                 |
| GET    | `/foods/search`          | **Sama** dengan `/foods` (semua query parameter dapat dipakai bersamaan, termasuk `q`)            |
| GET    | `/foods/recommendations` | Home: `{ featured, recommendations, context }` — personalisasi dari profil + opsional `lat`/`lng` |
| GET    | `/foods/:id`             | Detail; menyertakan `price_comparisons[]` Universal Mock harga + estimasi delivery fixed per window UTC enam jam |

**Query `GET /foods/recommendations`:**

| Parameter        | Keterangan                                                                               |
| :--------------- | :--------------------------------------------------------------------------------------- |
| `lat`, `lng`     | Opsional — menambah `distance_in_km` pada item dan sedikit boost jarak dekat             |
| `featured_limit` | Default `1` — jumlah slot hero “You Might Like This” (mis. `is_featured` diprioritaskan) |
| `limit`          | Default `15` — panjang list “Recommendations for You” setelah featured                   |

Jika profil memiliki data tubuh atau preferensi, backend menerapkan hard filter terlebih dahulu untuk preference yang punya makna diet jelas, misalnya `Vegetarian Lifestyle`, `Vegan`, `Plant-Based`, dan `Gluten Free`. Jika filter menghasilkan kandidat, hanya kandidat tersebut yang masuk scoring dan ranking Gemini; jika tidak ada kandidat cocok, backend fallback ke semua menu agar home tidak kosong. Setelah itu Gemini meranking menu aktif berdasarkan `gender`, `age`, `height_cm`, `weight_kg`, `nutrition_goal`, `food_preferences`, `dietary_restrictions`, dan `taste_profile`. Tanpa profil personalisasi atau saat Gemini gagal, ranking fallback ke `recommendation_score` + tier gizi (+ jarak jika ada). Response `context.hard_filters` menandai filter keras yang benar-benar diterapkan.

**Query `GET /foods` & `GET /foods/search`:**

| Parameter                | Tipe    | Keterangan                                                                               |
| :----------------------- | :------ | :--------------------------------------------------------------------------------------- |
| `q`                      | string  | Substring `name` / `description`                                                         |
| `nutrition_grade`        | enum    | `EXCELLENT`, `VERY_GOOD`, `GOOD`                                                         |
| `food_category`          | string  | Salah satu key kategori (lihat `/meta/food-categories`)                                  |
| `min_price`, `max_price` | number  | Filter `base_price`                                                                      |
| `lat`, `lng`             | number  | Lokasi user (WGS84) untuk jarak                                                          |
| `max_distance_km`        | number  | Butuh `lat` & `lng`; membuang item di luar radius                                        |
| `sort`                   | string  | `distance` (default jika ada lat/lng), `price_asc`, `recommended` (default tanpa lokasi) |
| `page`, `limit`          | number  | Pagination (`limit` maks. 100 pada implementasi saat ini)                                |
| `featured_only`          | boolean | `true` → hanya `is_featured`                                                             |

**Field tambahan pada item list:** `vendor_name`, `image_url` (alias `photo_url`), dan `distance_in_km` jika `lat`/`lng` dikirim.

**Query `GET /foods/:id`:**

| Parameter    | Tipe   | Keterangan                                                                                      |
| :----------- | :----- | :---------------------------------------------------------------------------------------------- |
| `lat`, `lng` | number | Opsional; lokasi user (WGS84) untuk membuat Universal Mock estimasi delivery berbasis jarak      |

**Response detail (`GET /foods/:id`):** selain field dokumen, tersedia:

- `vendor_name`, `image_url`
- `price_comparisons`: array `{ platform_key, platform, price, base_price, delivery_eta_min_minutes, delivery_eta_max_minutes, delivery_eta_text, order_url, icon_url }`; `price` dan ETA adalah nilai mock backend sedangkan `base_price` adalah harga menu Firestore.
- `price_comparison_updated_at`, `price_comparison_valid_until`: batas window UTC enam jam saat mock price dan ETA berlaku; bernilai `null` jika tidak ada price comparison.

Perbandingan harga dan estimasi delivery dihitung on-the-fly oleh backend dari `foods.base_price`, deeplink provider, platform, window waktu, dan opsional jarak user ke merchant. Simulasi memakai seed deterministik berbasis `foodId`, platform, awal bucket waktu, dan bucket jarak. Nilai tetap sama selama window UTC enam jam yang sama untuk lokasi/bucket jarak yang sama, lalu dapat berubah pada window berikutnya. Endpoint terpisah `/compare-price/:food_id` **tidak** digunakan; gunakan `GET /foods/:id`.

### 5.4 Users (Bearer wajib)

| Method | Path                         | Keterangan                                                                                                                                                                           |
| :----- | :--------------------------- | :----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| GET    | `/users/me`                  | Profil lengkap termasuk field onboarding                                                                                                                                             |
| PATCH  | `/users/me`                  | Partial update — onboarding (`gender`, `age`, `weight_kg`, `height_cm`, `nutrition_goal`, `food_preferences`, `dietary_restrictions`, `taste_profile`, `onboarding_completed`, dll.) |
| POST   | `/users/me/photo`            | Multipart field `file`; upload/replace foto profil Cloudinary dan menyimpan `profile_photo_url`                                                                                      |
| POST   | `/users/me/recently-viewed`  | Body `{ "food_id": "<docId>" }` — panggil saat membuka detail menu                                                                                                                   |
| GET    | `/users/me/recently-viewed`  | Query `q`, `page`, `limit` — histori untuk layar “Recently viewed”                                                                                                                   |
| POST   | `/users/me/recent-locations` | Body lokasi; menyimpan/refresh entri recent                                                                                                                                          |
| GET    | `/users/me/recent-locations` | Daftar lokasi terbaru                                                                                                                                                                |

### 5.5 Merchant (Bearer + role `merchant`)

| Method | Path                        | Keterangan                                                                                             |
| :----- | :-------------------------- | :----------------------------------------------------------------------------------------------------- |
| GET    | `/merchant/me`              | Profil toko merchant login termasuk `business_email`                                                   |
| PATCH  | `/merchant/me`              | Update nama, alamat, koordinat                                                                         |
| GET    | `/merchant/dashboard`       | Kartu landing merchant: `{ total_active_items, total_inactive_items }`                                 |
| GET    | `/merchant/foods`           | Daftar menu milik merchant; query `q`, `is_available`, `page`, `limit`                                 |
| GET    | `/merchant/foods/:id`       | Detail menu milik merchant untuk management, termasuk menu hidden                                      |
| POST   | `/merchant/foods`           | Buat menu tanpa file foto; wajib resep request-only, gizi dibuat Gemini, grade di bawah `GOOD` ditolak |
| PUT    | `/merchant/foods/:id`       | Update metadata menu milik sendiri; kirim resep hanya untuk analisis gizi ulang                        |
| POST   | `/merchant/foods/:id/photo` | Multipart field `file`; upload/replace foto menu milik sendiri ke Cloudinary dan menyimpan `photo_url` |
| DELETE | `/merchant/foods/:id`       | Soft delete menu milik sendiri                                                                         |

### 5.6 Admin (Bearer + role `admin`)

| Method          | Path                                               | Keterangan                                                                          |
| :-------------- | :------------------------------------------------- | :---------------------------------------------------------------------------------- |
| GET             | `/admin/dashboard`                                 | Kartu statistik: total merchant, menu aktif, dan menu nonaktif                      |
| GET             | `/admin/merchants`                                 | List merchant; query `q`, `is_active`, `page`, `limit`                              |
| GET             | `/admin/merchants/:id`                             | Detail merchant termasuk `business_email`, tanpa password                           |
| POST            | `/admin/merchants`                                 | Buat toko sekaligus akun Auth merchant (`business_email`, `password`)               |
| PUT             | `/admin/merchants/:id`                             | Update metadata/email/password baru/status aktif dan sinkronkan Firebase Auth       |
| DELETE          | `/admin/merchants/:id`                             | Soft delete merchant serta disable akun Auth                                        |
| GET             | `/admin/merchants/:merchantId/foods`               | List/search/tab menu canonical untuk merchant tertentu                              |
| GET             | `/admin/merchants/:merchantId/foods/:foodId`       | Detail menu scoped untuk form edit admin; recipe tidak dikembalikan                 |
| POST            | `/admin/merchants/:merchantId/foods`               | Buat menu canonical tanpa `merchant_id`; resep dianalisis Gemini dan tidak disimpan |
| PUT             | `/admin/merchants/:merchantId/foods/:foodId`       | Edit/toggle menu; recipe opsional untuk analisis ulang                              |
| POST            | `/admin/merchants/:merchantId/foods/:foodId/photo` | Upload/replace foto menu Cloudinary                                                 |
| DELETE          | `/admin/merchants/:merchantId/foods/:foodId`       | Soft delete menu merchant tersebut                                                  |
| GET/POST/PUT/DELETE | `/admin/foods...`                              | Endpoint global legacy untuk kompatibilitas client lama; `GET /admin/foods/:id` mengembalikan detail edit tanpa recipe |

---

## 6. Business Logic & Algorithms

### A. Perhitungan Jarak dan Geolocation Query

Untuk menghitung jarak antara lokasi mahasiswa dan merchant, MVP akan menggunakan pendekatan:

1.  **Geohash Filtering (Scale-up/Optimasi):** Memanfaatkan library seperti `geofire-common` pada backend untuk memfilter merchant dalam radius tertentu (misal 5-10km) guna membatasi jumlah data yang di-fetch dari Firestore.
2.  **Jarak geodesik (`geofire-common.distanceBetween`):** Listing menghitung jarak dalam km antara koordinat user dan `merchants.coordinates`, mengurutkan atau memotong dengan `max_distance_km`.

$$d = 2r \arcsin\left(\sqrt{\sin^2\left(\frac{\phi_2 - \phi_1}{2}\right) + \cos(\phi_1) \cos(\phi_2) \sin^2\left(\frac{\lambda_2 - \lambda_1}{2}\right)}\right)$$

Dimana:

- $r$: Jari-jari bumi (6.371 km).
- $\phi_1, \phi_2$: Lintang (latitude) lokasi 1 dan 2.
- $\lambda_1, \lambda_2$: Bujur (longitude) lokasi 1 dan 2.

### B. Filter & Ranking

1.  **Tingkat gizi:** Filter eksak pada `nutrition_grade` (badge & filter Label).
2.  **Kategori menu:** Filter pada `food_category` (bukan lagi `array-contains` pada `health_labels`).
3.  **Tag tambahan:** `health_labels` tetap ada untuk konten/marketing; filter utama Label memakai `nutrition_grade`.
4.  **Jarak / harga / rekomendasi:** Kombinasi query parameter `sort`, `min_price` / `max_price`, dan `max_distance_km`.

### C. Rekomendasi personal (`GET /foods/recommendations`)

Backend mengambil menu aktif dari merchant aktif, lalu menerapkan hard filtering berdasarkan `food_preferences` sebelum ranking. Saat ini preference seperti `Vegetarian Lifestyle`, `Vegetarian`, `Vegan`, atau `Plant-Based` hanya meloloskan menu yang memiliki sinyal vegetarian/vegan/plant-based pada `health_labels`, `food_category`, `name`, atau `description`; `Gluten Free` meloloskan menu dengan sinyal gluten-free. Jika hard filter tidak menghasilkan kandidat, backend memakai semua menu sebagai fallback agar home tidak kosong. Setelah filtering, Gemini meranking kandidat berdasarkan profil tubuh, `nutrition_goal`, preferences, restrictions, dan taste profile. Slot **featured** dipilih dari hasil ranking yang sudah difilter, sehingga menu featured yang tidak cocok dengan hard preference tidak dipaksa tampil. Scoring lokal (`recommendation_score`, tier gizi, nutrisi, preferensi, dan jarak) dipertahankan sebagai fallback ketika Gemini tidak tersedia atau profil belum berisi data personalisasi; response menandai sumber melalui `context.recommendation_source` dan filter aktif melalui `context.hard_filters`. Menu merchant dengan `is_active: false` tidak tampil pada list, rekomendasi, maupun detail customer tanpa mengubah status `foods.is_available`.

### D. Gemini AI Nutrition Analysis

Backend memakai `AiService` untuk dua fungsi AI: analisis gizi resep pada create/update menu dan ranking rekomendasi personal. Model default adalah `gemini-2.5-flash`, dapat dioverride dengan `GEMINI_MODEL`.

- `GEMINI_API_KEY` wajib tersedia di environment backend agar analisis dan ranking AI aktif.
- `GEMINI_TIMEOUT_MS` default implementasi saat ini adalah `20000` ms agar lebih cocok untuk runtime serverless Vercel.
- Output analisis gizi divalidasi ketat: `calories`, `protein_g`, `fat_g`, `carb_g`, `grade`, `accepted`, dan `reason` wajib valid.
- Grade `BELOW_GOOD` tidak disimpan sebagai menu customer; caller management menolak menu dengan status `422`.
- Jika provider error, timeout, quota/rate limit, model tidak tersedia, response kosong, atau format JSON tidak valid, backend mengembalikan pesan aman `Nutrition analysis is temporarily unavailable` dan menulis detail internal ke log `AiService` tanpa membocorkan recipe atau API key.
- Pada rekomendasi, kegagalan Gemini tidak membuat home kosong karena backend memakai ranking lokal fallback dan menandai `context.recommendation_source: "fallback"`.

### E. Universal Mock Price Comparison & Delivery ETA

Untuk kebutuhan hackathon, aplikasi tidak memakai API harga live GoFood, GrabFood, atau ShopeeFood. Merchant/admin hanya menginput deeplink platform yang tersedia pada form add/edit menu:

```json
{
  "comparison_data": {
    "gofood": { "url": "https://gofood.co.id/menu/example" },
    "grabfood": { "url": "https://food.grab.com/menu/example" },
    "shopeefood": { "url": "https://shopeefood.co.id/menu/example" }
  }
}
```

- Frontend tidak menyediakan dan tidak mengirim field harga per platform.
- Firestore hanya menyimpan deeplink opsional (`url`, `icon_url`); harga platform tidak disimpan.
- Saat `GET /foods/:id`, backend menggunakan `base_price` menu sebagai dasar dan menghitung mock price menggunakan seed `foodId + platform + bucketStart`.
- Backend juga menghitung estimasi delivery mock (`delivery_eta_min_minutes`, `delivery_eta_max_minutes`, `delivery_eta_text`) untuk setiap platform. Jika `lat`/`lng` user dikirim dan merchant memiliki koordinat, ETA memakai bucket jarak: `0-2 km`, `2-5 km`, `5-10 km`, atau `>10 km`. Jika lokasi tidak tersedia, backend memakai fallback ETA default.
- Satu bucket berjalan selama enam jam berdasarkan UTC. Membuka/menutup ulang detail menu dalam bucket yang sama menghasilkan harga dan ETA identik untuk bucket jarak yang sama; nilai baru hanya mungkin muncul ketika bucket berikutnya dimulai.
- Response detail menyediakan `price_comparison_updated_at` dan `price_comparison_valid_until` agar Flutter dapat menampilkan masa berlaku atau men-cache hasil sampai window berakhir.
- Rentang markup simulasi: GoFood `12%-18%`, GrabFood `8%-15%`, ShopeeFood `5%-12%`; hasil dibulatkan ke ratusan rupiah.
- Rentang ETA dasar: tanpa lokasi `25-40 menit`; `0-2 km` sekitar `15-25 menit`; `2-5 km` sekitar `25-40 menit`; `5-10 km` sekitar `40-60 menit`; `>10 km` sekitar `55-75 menit`. Setiap platform mendapat offset kecil dan jitter deterministik.
- Platform tanpa deeplink tidak dimasukkan ke `price_comparisons`, karena customer tidak memiliki tujuan pemesanan yang dapat dibuka.

### F. Upload foto menu (Cloudinary)

Foto menu dipilih pada form yang sama dengan metadata dan resep, tetapi upload dilakukan melalui request terpisah setelah create menu berhasil. Pemisahan ini mencegah aset Cloudinary tidak terpakai apabila Gemini menolak resep dengan grade di bawah `GOOD`.

1.  Flutter mengirim metadata + `recipe` ke `POST /merchant/foods` atau `POST /admin/merchants/{merchantId}/foods`; file gambar belum dikirim.
2.  Backend menganalisis resep. Jika ditolak (`422`) atau layanan analisis gagal (`503`), dokumen menu dan aset gambar tidak dibuat.
3.  Setelah create sukses dan menghasilkan `id`, Flutter mengirim file yang sudah dipilih ke `POST /merchant/foods/:id/photo` atau `POST /admin/merchants/{merchantId}/foods/{id}/photo`.
4.  Backend memverifikasi role dan, untuk merchant, ownership menu; kemudian meng-upload atau mengganti aset Cloudinary dan menyimpan URL aman ke `foods.photo_url`.
5.  Mengganti foto menu tidak memicu analisis gizi ulang. Analisis ulang hanya terjadi saat `recipe` baru dikirim melalui update menu.

**Kontrak upload foto menu:**

| Properti        | Aturan                                                                              |
| :-------------- | :---------------------------------------------------------------------------------- |
| Content type    | `multipart/form-data` dengan field wajib `file`                                     |
| Format file     | JPEG, PNG, atau WebP                                                                |
| Ukuran maksimum | 5 MB                                                                                |
| Penyimpanan     | Folder Cloudinary `gizigo/foods`, menggunakan ID menu sebagai identitas aset stabil |
| Field Firestore | Persist hanya `photo_url` dan `updated_at`; binary file tidak disimpan di Firestore |
| Response        | Menu yang diperbarui atau minimal `{ food_id, photo_url }`                          |

`CloudinaryService` digunakan kembali dengan method khusus foto menu, misalnya `uploadFoodPhoto(foodId, buffer)`. Endpoint upload menu tetap diperlukan pada backend karena service tidak dapat dipanggil langsung oleh aplikasi Flutter dan harus berada di belakang validasi auth/ownership.

---

## 7. Security & Validation

- **Authentication Guard:** Mengimplementasikan custom _Guard_ di Nest.js yang menggunakan `firebase-admin` SDK (`admin.auth().verifyIdToken()`) untuk memvalidasi _Bearer Token_ dari request client.
- **Role-Based Access Control (RBAC):** Menggunakan custom Decorator (`@Roles()`) dan `RolesGuard` di Nest.js untuk memastikan endpoint Admin tidak diakses oleh Customer (memverifikasi field `role` di Firestore atau via Firebase Custom Claims).
- **Data Validation:** Menggunakan `class-validator` dan `class-transformer` melalui `ValidationPipe` bawaan Nest.js untuk memvalidasi DTO (Data Transfer Object) secara ketat.
- **Upload Validation:** Upload foto profil dan menu dibatasi pada JPEG/PNG/WebP maksimum 5 MB. Upload foto menu hanya dapat dilakukan admin atau merchant pemilik menu, dan URL Cloudinary ditulis backend ke `photo_url`.
- **Security Headers:** Implementasi `Helmet` pada Nest.js untuk perlindungan kerentanan standar web.

---

## 8. Backend Deployment & Environment

Backend dideploy sebagai Vercel Serverless Function dengan root directory `backend`. Konfigurasi utama berada di `backend/vercel.json`:

- `buildCommand`: `pnpm run build`, lalu menyalin `dist` dan `node_modules` ke `api/dist`.
- `rewrites`: semua route diarahkan ke `/api`.
- `api/index.js`: entry point Vercel yang memuat `dist/src/serverless.js`.
- `maxDuration`: 30 detik dan `memory`: 1024 MB.

Environment variable backend yang diperlukan:

| Variable                | Fungsi                                                                  |
| :---------------------- | :---------------------------------------------------------------------- |
| `FIREBASE_PROJECT_ID`   | Project ID Firebase                                                     |
| `FIREBASE_CLIENT_EMAIL` | Email service account Firebase Admin                                    |
| `FIREBASE_PRIVATE_KEY`  | Private key service account; di Vercel gunakan literal `\n` antar baris |
| `CLOUDINARY_CLOUD_NAME` | Cloudinary cloud name                                                   |
| `CLOUDINARY_API_KEY`    | Cloudinary API key                                                      |
| `CLOUDINARY_API_SECRET` | Cloudinary API secret                                                   |
| `GEMINI_API_KEY`        | API key Gemini                                                          |
| `GEMINI_MODEL`          | Opsional; default `gemini-2.5-flash`                                    |
| `GEMINI_TIMEOUT_MS`     | Opsional; default `20000` ms                                            |

Swagger tersedia di `/api`. Jika terjadi error AI di Vercel, cek Runtime Logs dan cari log dari `AiService`.

---

## 9. Frontend Implementation (Flutter) & Backend Integration

### A. State Management & Architecture

- **State Management:** Menggunakan **Riverpod** (`flutter_riverpod`) terutama pada flow Home dan data async.
- **Routing:** Menggunakan `go_router` untuk navigasi halaman yang deklaratif dan mempermudah setup _Deep Linking_ di masa depan.

### B. Paket Utama (Dependencies)

- **HTTP Client:** `dio` - Digunakan untuk memanggil endpoint API Nest.js. `dio` sangat ideal karena mendukung fitur _Interceptor_ untuk menyelipkan token Auth ke Header secara otomatis.
- **Geolocation:** `geolocator` - Mengambil lokasi terkini perangkat (latitude & longitude) untuk diteruskan ke backend sebagai parameter pencarian jarak.
- **Maps & Geocoding:** `flutter_map`, `latlong2`, dan Nominatim OpenStreetMap untuk pemilihan titik, pencarian alamat, dan reverse geocoding di sisi Flutter.
- **Local Storage:** `flutter_secure_storage` - Menyimpan Firebase ID Token atau sesi _auth_ secara aman di perangkat.
- **Firebase SDK:** `firebase_core`, `firebase_auth`, dan `google_sign_in` untuk menangani proses autentikasi di sisi klien.
- **Media & Deeplink:** `image_picker` untuk memilih foto profil/menu dan `url_launcher` untuk membuka deeplink GoFood/GrabFood/ShopeeFood.

### C. Alur Integrasi Frontend ke Backend

1.  **Flow Autentikasi:**
    - **Email signup:** Firebase `createUserWithEmailAndPassword` → `POST /auth/signup` (atau `/auth/sync`) dengan Bearer.
    - **Google:** sign-in → token → `POST /auth/sync` atau `/auth/signup` (handler sama).
    - Token disimpan di `flutter_secure_storage`; interceptor `dio` menyematkan header Bearer.
2.  **Onboarding (setelah registrasi):**
    - Ambil label goal dari `GET /meta/nutrition-goals`.
    - Kirim `PATCH /users/me` dengan `gender`, `age`, `weight_kg`, `height_cm`, `nutrition_goal`, `food_preferences`, `dietary_restrictions`, `taste_profile`, `onboarding_completed: true`.
3.  **API Requests dengan Interceptor (`dio`):**
    - Set `BaseOptions(baseUrl: ApiConstants.baseUrl)`. Default production saat ini `https://be-gizigo.vercel.app`; override lokal dapat memakai `--dart-define=API_BASE_URL=http://localhost:3000`.
    - Pada setiap request ke endpoint terproteksi, tambahkan header `Authorization: Bearer <Firebase_ID_Token>` (biasanya via `Interceptor` yang membaca token dari `flutter_secure_storage`).
    - Jika response `401`, interceptor mencoba refresh Firebase token dan retry request satu kali.
4.  **Konvensi JSON:** Backend memakai **`snake_case`** untuk field JSON (selaras Firestore). Di Flutter gunakan `@JsonKey(name: 'base_price')` / `json_serializable` atau mapper manual; hindari mengubah kontrak API hanya untuk gaya Dart.
5.  **Meta bootstrap:** `GET /meta/food-categories`, `GET /meta/nutrition-grades`, `GET /meta/nutrition-goals` untuk chip/filter dan wizard onboarding.
6.  **Home — rekomendasi personal:**
    - `GET /foods/recommendations?lat=&lng=&featured_limit=1&limit=15` → `featured[]` untuk kartu besar “You Might Like This”, `recommendations[]` untuk list “Recommendations for You”.
    - Jika user memilih preference seperti `Vegetarian Lifestyle`, backend menerapkan hard filter sebelum Gemini/local ranking; frontend bisa membaca `context.hard_filters` untuk debug atau badge kecil bila dibutuhkan.
    - Kategori horizontal / filter lain boleh tetap pakai `GET /foods` dengan query yang sama seperti sebelumnya.
7.  **Search listing:** **`GET /foods/search`** dengan parameter **yang sama** seperti `/foods`, termasuk `q`.
8.  **Detail menu:**
    - Backend mendukung query opsional `lat`/`lng` pada `GET /foods/{id}` untuk ETA berbasis jarak.
    - Implementasi Flutter saat ini memanggil `GET /foods/{id}` tanpa `lat`/`lng`, sehingga `delivery_eta_text` memakai fallback ETA universal sampai lokasi diteruskan ke detail screen.
    - Render deskripsi, `vendor_name`, `nutrition_grade`, dan list **`price_comparisons`** (gunakan `price` untuk teks hijau, `delivery_eta_text` untuk estimasi pengiriman, dan `order_url` untuk `url_launcher`).
    - Setelah layar terbuka, panggil `POST /users/me/recently-viewed` dengan `{ "food_id": "<id>" }`.
9.  **Recently viewed:** `GET /users/me/recently-viewed?q=&page=&limit=` — kelompokkan di Flutter berdasarkan tanggal dari `viewed_at` (hari ini / kemarin / tanggal).
10. **Lokasi:** Setelah user memilih lokasi (map / GPS), `POST /users/me/recent-locations`; daftar “Recent” dari `GET /users/me/recent-locations`. Pencarian alamat dan reverse geocoding saat ini memakai Nominatim/OpenStreetMap di Flutter; `GET /meta/locations/search` di backend masih placeholder.
11. **Profil:** `GET /users/me` / `PATCH /users/me` untuk data akun + onboarding; `POST /users/me/photo` (`multipart/form-data`, JPEG/PNG/WebP maks. 5 MB) untuk mengganti foto profil.
12. **Tambah / edit menu merchant atau admin:**
    - User dapat memilih foto dan mengisi metadata maupun resep dalam satu form; urutan pengisian pada UI tidak dibatasi.
    - Form menyediakan URL opsional untuk GoFood, GrabFood, dan ShopeeFood; jangan meminta harga per platform karena backend membuat Universal Mock dari `base_price`.
    - Saat submit menu baru, kirim metadata + `recipe` + `comparison_data` deeplink terlebih dahulu ke `POST /merchant/foods` atau `POST /admin/merchants/{merchantId}/foods`, tanpa mengirim `photo_url` maupun binary foto.
    - Bila create sukses, ambil `id` dari response lalu upload file terpilih menggunakan `POST /merchant/foods/{id}/photo` atau `POST /admin/merchants/{merchantId}/foods/{id}/photo` sebagai `multipart/form-data` field `file`.
    - Bila create ditolak Gemini, tampilkan alasan penolakan dan jangan menjalankan upload foto.
    - Saat mengganti foto pada menu yang sudah ada, panggil endpoint `/photo` secara langsung; tidak perlu mengirim ulang resep.
    - Saat membuka form edit merchant, ambil default value dari `GET /merchant/foods/{id}`; response mengembalikan metadata tersimpan, deeplink platform, foto, dan status availability, tetapi tidak mengembalikan `recipe`.
    - Saat membuka form edit admin canonical, ambil default value dari `GET /admin/merchants/{merchantId}/foods/{foodId}`. Untuk client lama, `GET /admin/foods/{id}` juga tersedia sebagai route legacy dengan bentuk detail yang sama dan tanpa `recipe`.
13. **Landing dan profil merchant:**
    - `GET /merchant/dashboard` mengisi kartu jumlah menu aktif/nonaktif.
    - `GET /merchant/foods?q=&is_available=` mengisi list dan tab status; tombol detail membuka `GET /merchant/foods/{id}` sehingga menu hidden tetap dapat diedit.
    - `GET /merchant/me` menampilkan nama bisnis, `business_email`, alamat, dan koordinat. Edit profil merchant hanya mengubah identitas/lokasi bisnis; perubahan email login dikelola admin.

### D. Pemetaan layar UI → endpoint

| Layar                  | Endpoint utama                                                                                      |
| :--------------------- | :-------------------------------------------------------------------------------------------------- |
| Login / Sign up (sync) | `POST /auth/sync`, `POST /auth/signup`                                                              |
| Onboarding wizard      | `GET /meta/nutrition-goals`, `PATCH /users/me`                                                      |
| Home (personalized)    | `GET /foods/recommendations`, `GET /meta/food-categories`, `GET /foods` (filter/kategori)           |
| Search                 | `GET /foods/search`                                                                                 |
| Detail menu            | `GET /foods/:id`, `POST /users/me/recently-viewed`                                                  |
| Recently viewed        | `GET /users/me/recently-viewed`                                                                     |
| Select location        | `GET /users/me/recent-locations`, `POST /users/me/recent-locations` (+ Nominatim/OpenStreetMap di Flutter) |
| Profil                 | `GET /users/me`, `PATCH /users/me`, `POST /users/me/photo`                                          |
| Landing merchant       | `GET /merchant/dashboard`, `GET /merchant/foods?q=&is_available=`                                   |
| Profil merchant        | `GET /merchant/me`, `PATCH /merchant/me`                                                            |
| Kelola menu merchant   | `GET/POST /merchant/foods`, `GET/PUT/DELETE /merchant/foods/:id`, `POST /merchant/foods/:id/photo`  |
| Landing admin          | `GET /admin/dashboard`, `GET /admin/merchants?q=&is_active=`                                        |
| Detail merchant admin  | `POST /admin/merchants`, `GET/PUT/DELETE /admin/merchants/:id`                                      |
| Kelola menu admin      | `GET/POST /admin/merchants/:merchantId/foods`, `GET/PUT/DELETE /admin/merchants/:merchantId/foods/:foodId`, `POST .../:foodId/photo`; legacy `GET/PUT/DELETE /admin/foods/:id`, `POST /admin/foods/:id/photo` |

### E. Contoh payload

**Create menu merchant tanpa foto (`POST /merchant/foods`):**

```json
{
  "name": "Chicken Salad",
  "description": "Fresh salad with grilled chicken",
  "food_category": "main_course",
  "health_labels": ["High Protein"],
  "base_price": 35000,
  "is_available": true,
  "recipe": {
    "servings": 1,
    "ingredients": [
      { "name": "Chicken breast", "amount": 150, "unit": "g" },
      { "name": "Lettuce", "amount": 80, "unit": "g" }
    ]
  },
  "comparison_data": {
    "gofood": { "url": "https://gofood.co.id/menu/chicken-salad" },
    "grabfood": { "url": "https://food.grab.com/menu/chicken-salad" },
    "shopeefood": { "url": "https://shopeefood.co.id/menu/chicken-salad" }
  }
}
```

Setelah response create mengembalikan `id`, Flutter meng-upload foto yang dipilih melalui:

```http
POST /merchant/foods/{id}/photo
Content-Type: multipart/form-data
file: <selected-image>
```

**List (`GET /foods`):**

```json
{
  "items": [
    {
      "id": "abc123",
      "name": "Ayam goreng",
      "description": "…",
      "photo_url": "https://…",
      "image_url": "https://…",
      "base_price": 17000,
      "nutrition_grade": "EXCELLENT",
      "food_category": "main_course",
      "vendor_name": "Warteg Sendowo",
      "distance_in_km": 1.2
    }
  ],
  "total": 1,
  "page": 1,
  "limit": 20,
  "total_pages": 1
}
```

**Detail (`GET /foods/:id`) — cuplikan:**

```json
{
  "id": "abc123",
  "name": "Ayam goreng",
  "base_price": 17000,
  "nutrition_grade": "EXCELLENT",
  "vendor_name": "Warteg Sendowo",
  "price_comparison_updated_at": "2026-05-27T00:00:00.000Z",
  "price_comparison_valid_until": "2026-05-27T06:00:00.000Z",
  "price_comparisons": [
    {
      "platform_key": "gofood",
      "platform": "GoFood",
      "price": 19500,
      "base_price": 17000,
      "delivery_eta_min_minutes": 24,
      "delivery_eta_max_minutes": 39,
      "delivery_eta_text": "24-39 menit",
      "order_url": "https://…",
      "icon_url": "https://…"
    }
  ]
}
```

**Badge di Flutter:** mapping `nutrition_grade` → warna/teks (label human-readable bisa dari `/meta/nutrition-grades` atau ARB lokal).

**Rekomendasi Home (`GET /foods/recommendations`) — bentuk respons:**

```json
{
  "featured": [
    { "id": "…", "personalization_score": 128.5, "is_featured": true }
  ],
  "recommendations": [{ "id": "…", "personalization_score": 95 }],
  "context": {
    "nutrition_goal": "DIET",
    "onboarding_completed": true,
    "personalized": true,
    "recommendation_source": "gemini",
    "hard_filters": ["vegetarian"]
  }
}
```

### F. Contoh `dio` + interceptor (cuplikan)

```dart
final dio = Dio(BaseOptions(baseUrl: 'https://your-api.example.com'));
dio.interceptors.add(InterceptorsWrapper(
  onRequest: (options, handler) async {
    final token = await secureStorage.read(key: 'id_token');
    if (token != null) options.headers['Authorization'] = 'Bearer $token';
    handler.next(options);
  },
));
```

---

## 10. Roadmap Pengembangan (MVP)

- **Minggu 1:** Setup Environment (Nest.js & Flutter), Firebase Configuration, Auth Module.
- **Minggu 2:** Pengembangan Schema Firestore, Admin Dashboard (API), Manual Data Entry.
- **Minggu 3:** Implementasi Simulasi Data & Deep Linking untuk Price Comparison, UI Homepage & Search.
- **Minggu 4:** Testing (UAT), Bug Fixing, dan Persiapan Pitching Hackathon.

---

**Rekomendasi Tambahan:**
Untuk integrasi ke tiga layanan pengiriman makanan, pastikan di dalam Flutter diimplementasikan **Deep Linking**. Sehingga saat tombol "Pesan via GoFood" diklik, aplikasi akan langsung mencoba membuka aplikasi GoFood di ponsel user dengan parameter pencarian merchant terkait.
