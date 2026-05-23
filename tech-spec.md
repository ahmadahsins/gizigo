# Technical Specification: GiziGo Mobile Application

## 1. Project Overview

GiziGo adalah platform agregator makanan sehat yang ditujukan khusus untuk mahasiswa. Aplikasi ini memfasilitasi pencarian makanan bergizi dan memberikan perbandingan harga dari tiga layanan pengiriman makanan utama (GoFood, GrabFood, ShopeeFood) guna membantu mahasiswa mendapatkan pilihan terbaik sesuai anggaran.

---

## 2. System Architecture

Sistem menggunakan arsitektur **Client-Server** dengan komunikasi melalui **RESTful API**.

- **Frontend:** Flutter (Mobile App).
- **Backend:** Nest.js (REST API & Business Logic) dengan `firebase-admin` SDK.
- **Database & Infrastructure:** Firebase (Firestore, Authentication, Storage).

---

## 3. Tech Stack Details

| Komponen              | Teknologi                        | Alasan Pemilihan                                                                                 |
| :-------------------- | :------------------------------- | :----------------------------------------------------------------------------------------------- |
| **Mobile App**        | Flutter                          | _Cross-platform_ (Android & iOS) dengan satu basis kode.                                         |
| **Backend Framework** | Nest.js                          | Struktur modular, dukungan TypeScript yang kuat, dan skalabilitas tinggi.                        |
| **Authentication**    | Firebase Auth & `firebase-admin` | Mendukung OAuth2 (Google Sign-In) di Frontend dan verifikasi token JWT di Backend via Admin SDK. |
| **Database**          | Cloud Firestore                  | _NoSQL document-based_, mendukung sinkronisasi _real-time_ dan query fleksibel.                  |
| **File Storage**      | Cloudinary                       | Penyimpanan aset gambar. Cloudinary cocok untuk optimasi gambar _on-the-fly_.                    |
| **API Documentation** | Swagger/OpenAPI                  | Standarisasi dokumentasi API untuk integrasi Frontend-Backend.                                   |

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
- `food_preferences`: array string (dicocokkan longgar dengan `foods.health_labels`)
- `dietary_restrictions`: array string (pembatasan diet untuk rekomendasi Gemini)
- `taste_profile`: array string (profil rasa untuk rekomendasi Gemini)
  - `onboarding_completed`: boolean
- `created_at`: timestamp
- `updated_at`: timestamp (server)

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
- **`food_category`**: string salah satu: `main_course`, `appetizers`, `snacks`, `desserts`, `beverages` (chip **Categories** di home)
- `health_labels`: array string (tag tambahan, mis. “High Protein”; **bukan** pengganti `nutrition_grade`)
- `nutritional_info`: map hasil analisis Gemini per serving `{ calories, protein_g, fat_g, carb_g }`
- `nutrition_assessment_reason`: string alasan penilaian umum dari Gemini
- `nutrition_analyzed_at`: timestamp analisis terakhir
- Resep dan rincian bahan bersifat request-only dan tidak disimpan di dokumen `foods`.
- `base_price`: number (IDR)
- `merchant_id`: string (referensi ke `merchants`)
- `is_available`: boolean
- `is_featured`: boolean (opsional; kartu hero “You Might Like This”)
- `recommendation_score`: number (opsional; urutan `sort=recommended`)
- `comparison_data`: object per provider (harga & deeplink)
  - `gofood` | `grabfood` | `shopeefood`: `{ price: number, url: string, icon_url?: string }`

### D. Collection: `merchants`

- `merchant_id`: string (Primary Key konsisten dengan referensi di `foods`)
- `owner_uid`: string (opsional; Firebase Auth UID pemilik akun merchant)
- `name`: string (nama warung / vendor untuk UI)
- `address`: string
- `coordinates`: GeoPoint
- `geohash`: string (opsional; optimasi radius)
- `is_verified`: boolean
- `is_active`: boolean (default `true`; soft delete set `false`)

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
| GET    | `/meta/locations/search?q=` | **Placeholder** — mengembalikan `items: []` sampai integrasi Places/Mapbox |

### 5.3 Foods (Bearer wajib)

| Method | Path                     | Keterangan                                                                                        |
| :----- | :----------------------- | :------------------------------------------------------------------------------------------------ |
| GET    | `/foods`                 | Daftar terpaginasi + filter; respons `{ items, total, page, limit, total_pages }`                 |
| GET    | `/foods/search`          | **Sama** dengan `/foods` (semua query parameter dapat dipakai bersamaan, termasuk `q`)            |
| GET    | `/foods/recommendations` | Home: `{ featured, recommendations, context }` — personalisasi dari profil + opsional `lat`/`lng` |
| GET    | `/foods/:id`             | Detail; menyertakan `price_comparisons[]` dan simulasi ±5% per provider                           |

**Query `GET /foods/recommendations`:**

| Parameter        | Keterangan                                                                               |
| :--------------- | :--------------------------------------------------------------------------------------- |
| `lat`, `lng`     | Opsional — menambah `distance_in_km` pada item dan sedikit boost jarak dekat             |
| `featured_limit` | Default `1` — jumlah slot hero “You Might Like This” (mis. `is_featured` diprioritaskan) |
| `limit`          | Default `15` — panjang list “Recommendations for You” setelah featured                   |

Jika profil memiliki data tubuh atau preferensi, Gemini meranking menu aktif berdasarkan `gender`, `age`, `height_cm`, `weight_kg`, `nutrition_goal`, `food_preferences`, `dietary_restrictions`, dan `taste_profile`. Tanpa profil personalisasi atau saat Gemini gagal, ranking fallback ke `recommendation_score` + tier gizi (+ jarak jika ada).

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

**Response detail (`GET /foods/:id`):** selain field dokumen, tersedia:

- `vendor_name`, `image_url`
- `price_comparisons`: array `{ platform_key, platform, price, base_price, order_url, icon_url }`

Perbandingan harga di-detail menggunakan fluktuasi tersimulasi pada nilai `price` yang dikembalikan (lihat implementasi backend). Endpoint terpisah `/compare-price/:food_id` **tidak** digunakan; gunakan `GET /foods/:id`.

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
| GET    | `/merchant/me`              | Profil toko merchant login                                                                             |
| PATCH  | `/merchant/me`              | Update nama, alamat, koordinat                                                                         |
| GET    | `/merchant/foods`           | Daftar menu milik merchant                                                                             |
| POST   | `/merchant/foods`           | Buat menu tanpa file foto; wajib resep request-only, gizi dibuat Gemini, grade di bawah `GOOD` ditolak |
| PUT    | `/merchant/foods/:id`       | Update metadata menu milik sendiri; kirim resep hanya untuk analisis gizi ulang                        |
| POST   | `/merchant/foods/:id/photo` | Multipart field `file`; upload/replace foto menu milik sendiri ke Cloudinary dan menyimpan `photo_url` |
| DELETE | `/merchant/foods/:id`       | Soft delete menu milik sendiri                                                                         |

### 5.6 Admin (Bearer + role `admin`)

| Method | Path                         | Keterangan                                                                                               |
| :----- | :--------------------------- | :------------------------------------------------------------------------------------------------------- |
| GET    | `/admin/merchants`           | List merchant (filter `is_active` opsional)                                                              |
| GET    | `/admin/merchants/:id`       | Detail merchant                                                                                          |
| POST   | `/admin/merchants`           | Buat merchant                                                                                            |
| PUT    | `/admin/merchants/:id`       | Update merchant                                                                                          |
| DELETE | `/admin/merchants/:id`       | Soft delete merchant (`is_active: false`)                                                                |
| GET    | `/admin/merchants/:id/foods` | List foods per merchant                                                                                  |
| POST   | `/admin/foods`               | Buat dokumen `foods` tanpa file foto; wajib `food_category` dan resep request-only untuk analisis Gemini |
| PUT    | `/admin/foods/:id`           | Partial update                                                                                           |
| POST   | `/admin/foods/:id/photo`     | Multipart field `file`; upload/replace foto menu ke Cloudinary dan menyimpan `photo_url`                 |
| DELETE | `/admin/foods/:id`           | Soft delete (`is_available: false`)                                                                      |

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

Gemini meranking kandidat menu aktif dengan profil tubuh dan preferensi pengguna, termasuk restrictions serta taste profile. Slot **featured** tetap mengutamakan `is_featured` pada urutan hasil. Scoring lokal lama (`recommendation_score`, tier gizi, nutrisi, preferensi, dan jarak) dipertahankan sebagai fallback ketika Gemini tidak tersedia atau profil belum berisi data personalisasi; response menandai sumber melalui `context.recommendation_source`.

### D. Upload foto menu (Cloudinary)

Foto menu dipilih pada form yang sama dengan metadata dan resep, tetapi upload dilakukan melalui request terpisah setelah create menu berhasil. Pemisahan ini mencegah aset Cloudinary tidak terpakai apabila Gemini menolak resep dengan grade di bawah `GOOD`.

1.  Flutter mengirim metadata + `recipe` ke `POST /merchant/foods` atau `POST /admin/foods`; file gambar belum dikirim.
2.  Backend menganalisis resep. Jika ditolak (`422`) atau layanan analisis gagal (`503`), dokumen menu dan aset gambar tidak dibuat.
3.  Setelah create sukses dan menghasilkan `id`, Flutter mengirim file yang sudah dipilih ke `POST /merchant/foods/:id/photo` atau `POST /admin/foods/:id/photo`.
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

## 8. Frontend Implementation (Flutter) & Backend Integration

### A. State Management & Architecture

- **State Management:** Menggunakan **Riverpod** atau **Provider** (direkomendasikan untuk kecepatan MVP Hackathon)
- **Routing:** Menggunakan `go_router` untuk navigasi halaman yang deklaratif dan mempermudah setup _Deep Linking_ di masa depan.

### B. Paket Utama (Dependencies)

- **HTTP Client:** `dio` - Digunakan untuk memanggil endpoint API Nest.js. `dio` sangat ideal karena mendukung fitur _Interceptor_ untuk menyelipkan token Auth ke Header secara otomatis.
- **Geolocation:** `geolocator` - Mengambil lokasi terkini perangkat (latitude & longitude) untuk diteruskan ke backend sebagai parameter pencarian jarak.
- **Local Storage:** `flutter_secure_storage` - Menyimpan Firebase ID Token atau sesi _auth_ secara aman di perangkat.
- **Firebase SDK:** `firebase_core`, `firebase_auth`, dan `google_sign_in` untuk menangani proses autentikasi di sisi klien.

### C. Alur Integrasi Frontend ke Backend

1.  **Flow Autentikasi:**
    - **Email signup:** Firebase `createUserWithEmailAndPassword` → `POST /auth/signup` (atau `/auth/sync`) dengan Bearer.
    - **Google:** sign-in → token → `POST /auth/sync` atau `/auth/signup` (handler sama).
    - Token disimpan di `flutter_secure_storage`; interceptor `dio` menyematkan header Bearer.
2.  **Onboarding (setelah registrasi):**
    - Ambil label goal dari `GET /meta/nutrition-goals`.
    - Kirim `PATCH /users/me` dengan `gender`, `age`, `weight_kg`, `height_cm`, `nutrition_goal`, `food_preferences`, `dietary_restrictions`, `taste_profile`, `onboarding_completed: true`.
3.  **API Requests dengan Interceptor (`dio`):**
    - Set `BaseOptions(baseUrl: 'https://<your-api-host>/')`.
    - Pada setiap request ke endpoint terproteksi, tambahkan header `Authorization: Bearer <Firebase_ID_Token>` (biasanya via `Interceptor` yang membaca token dari `flutter_secure_storage`).
4.  **Konvensi JSON:** Backend memakai **`snake_case`** untuk field JSON (selaras Firestore). Di Flutter gunakan `@JsonKey(name: 'base_price')` / `json_serializable` atau mapper manual; hindari mengubah kontrak API hanya untuk gaya Dart.
5.  **Meta bootstrap:** `GET /meta/food-categories`, `GET /meta/nutrition-grades`, `GET /meta/nutrition-goals` untuk chip/filter dan wizard onboarding.
6.  **Home — rekomendasi personal:**
    - `GET /foods/recommendations?lat=&lng=&featured_limit=1&limit=15` → `featured[]` untuk kartu besar “You Might Like This”, `recommendations[]` untuk list “Recommendations for You”.
    - Kategori horizontal / filter lain boleh tetap pakai `GET /foods` dengan query yang sama seperti sebelumnya.
7.  **Search listing:** **`GET /foods/search`** dengan parameter **yang sama** seperti `/foods`, termasuk `q`.
8.  **Detail menu:**
    - `GET /foods/{id}` → render deskripsi, `vendor_name`, `nutrition_grade`, dan list **`price_comparisons`** (gunakan `price` untuk teks hijau; `order_url` untuk `url_launcher`).
    - Setelah layar terbuka, panggil `POST /users/me/recently-viewed` dengan `{ "food_id": "<id>" }`.
9.  **Recently viewed:** `GET /users/me/recently-viewed?q=&page=&limit=` — kelompokkan di Flutter berdasarkan tanggal dari `viewed_at` (hari ini / kemarin / tanggal).
10. **Lokasi:** Setelah user memilih lokasi (map / GPS), `POST /users/me/recent-locations`; daftar “Recent” dari `GET /users/me/recent-locations`. Autocomplete jalanan tetap bisa memakai Places di klien; `GET /meta/locations/search` saat ini placeholder.
11. **Profil:** `GET /users/me` / `PATCH /users/me` untuk data akun + onboarding; `POST /users/me/photo` (`multipart/form-data`, JPEG/PNG/WebP maks. 5 MB) untuk mengganti foto profil.
12. **Tambah / edit menu merchant atau admin:**
    - User dapat memilih foto dan mengisi metadata maupun resep dalam satu form; urutan pengisian pada UI tidak dibatasi.
    - Saat submit menu baru, kirim metadata + `recipe` terlebih dahulu ke `POST /merchant/foods` atau `POST /admin/foods`, tanpa mengirim `photo_url` maupun binary foto.
    - Bila create sukses, ambil `id` dari response lalu upload file terpilih menggunakan `POST /merchant/foods/{id}/photo` atau `POST /admin/foods/{id}/photo` sebagai `multipart/form-data` field `file`.
    - Bila create ditolak Gemini, tampilkan alasan penolakan dan jangan menjalankan upload foto.
    - Saat mengganti foto pada menu yang sudah ada, panggil endpoint `/photo` secara langsung; tidak perlu mengirim ulang resep.

### D. Pemetaan layar UI → endpoint

| Layar                  | Endpoint utama                                                                            |
| :--------------------- | :---------------------------------------------------------------------------------------- |
| Login / Sign up (sync) | `POST /auth/sync`, `POST /auth/signup`                                                    |
| Onboarding wizard      | `GET /meta/nutrition-goals`, `PATCH /users/me`                                            |
| Home (personalized)    | `GET /foods/recommendations`, `GET /meta/food-categories`, `GET /foods` (filter/kategori) |
| Search                 | `GET /foods/search`                                                                       |
| Detail menu            | `GET /foods/:id`, `POST /users/me/recently-viewed`                                        |
| Recently viewed        | `GET /users/me/recently-viewed`                                                           |
| Select location        | `GET /users/me/recent-locations`, `POST /users/me/recent-locations` (+ Places di Flutter) |
| Profil                 | `GET /users/me`, `PATCH /users/me`, `POST /users/me/photo`                                |
| Kelola menu merchant   | `POST /merchant/foods`, `PUT /merchant/foods/:id`, `POST /merchant/foods/:id/photo`       |
| Kelola menu admin      | `POST /admin/foods`, `PUT /admin/foods/:id`, `POST /admin/foods/:id/photo`                |

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
  "price_comparisons": [
    {
      "platform_key": "gofood",
      "platform": "GoFood",
      "price": 18000,
      "base_price": 17500,
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
    "personalized": true
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

## 9. Roadmap Pengembangan (MVP)

- **Minggu 1:** Setup Environment (Nest.js & Flutter), Firebase Configuration, Auth Module.
- **Minggu 2:** Pengembangan Schema Firestore, Admin Dashboard (API), Manual Data Entry.
- **Minggu 3:** Implementasi Simulasi Data & Deep Linking untuk Price Comparison, UI Homepage & Search.
- **Minggu 4:** Testing (UAT), Bug Fixing, dan Persiapan Pitching Hackathon.

---

**Rekomendasi Tambahan:**
Untuk integrasi ke tiga layanan pengiriman makanan, pastikan di dalam Flutter diimplementasikan **Deep Linking**. Sehingga saat tombol "Pesan via GoFood" diklik, aplikasi akan langsung mencoba membuka aplikasi GoFood di ponsel user dengan parameter pencarian merchant terkait.
