# Technical Specification: GiziGo Mobile Application

## 1. Project Overview
GiziGo adalah platform agregator makanan sehat yang ditujukan khusus untuk mahasiswa. Aplikasi ini memfasilitasi pencarian makanan bergizi dan memberikan perbandingan harga dari tiga layanan pengiriman makanan utama (GoFood, GrabFood, ShopeeFood) guna membantu mahasiswa mendapatkan pilihan terbaik sesuai anggaran.

---

## 2. System Architecture
Sistem menggunakan arsitektur **Client-Server** dengan komunikasi melalui **RESTful API**.

*   **Frontend:** Flutter (Mobile App).
*   **Backend:** Nest.js (REST API & Business Logic) dengan `firebase-admin` SDK.
*   **Database & Infrastructure:** Firebase (Firestore, Authentication, Storage).

---

## 3. Tech Stack Details
| Komponen | Teknologi | Alasan Pemilihan |
| :--- | :--- | :--- |
| **Mobile App** | Flutter | *Cross-platform* (Android & iOS) dengan satu basis kode. |
| **Backend Framework** | Nest.js | Struktur modular, dukungan TypeScript yang kuat, dan skalabilitas tinggi. |
| **Authentication** | Firebase Auth & `firebase-admin` | Mendukung OAuth2 (Google Sign-In) di Frontend dan verifikasi token JWT di Backend via Admin SDK. |
| **Database** | Cloud Firestore | *NoSQL document-based*, mendukung sinkronisasi *real-time* dan query fleksibel. |
| **File Storage** | Cloudinary | Penyimpanan aset gambar. Cloudinary cocok untuk optimasi gambar *on-the-fly*. |
| **API Documentation** | Swagger/OpenAPI | Standarisasi dokumentasi API untuk integrasi Frontend-Backend. |

---

## 4. Database Schema (Firestore)

Struktur data dirancang untuk mendukung MVP UI (badge gizi, filter, lokasi, histori).

### A. Collection: `users`

*   `uid`: string (Primary Key – sama dengan Firebase Auth UID; dokumen `users/{uid}`)
*   `name`: string
*   `username`: string (unique, opsional)
*   `email`: string
*   `role`: string (`customer`, `admin`, `merchant`)
*   `merchant_id`: string (opsional; diisi untuk akun `merchant`, sama dengan ID dokumen `merchants`)
*   `preferred_language`: string (opsional, mis. `en_US`)
*   `dark_mode`: boolean (opsional; bisa juga hanya lokal di Flutter)
*   **Onboarding / personalisasi (diset lewat `PATCH /users/me`):**
    *   `gender`: string enum `MALE` | `FEMALE` | `OTHER` | `PREFER_NOT_TO_SAY`
    *   `age`: number (tahun)
    *   `weight_kg`, `height_cm`: number
    *   `nutrition_goal`: string enum `DIET` | `BULKING` | `MAINTAIN` (memengaruhi `/foods/recommendations`)
    *   `food_preferences`: array string (dicocokkan longgar dengan `foods.health_labels`)
    *   `onboarding_completed`: boolean
*   `created_at`: timestamp
*   `updated_at`: timestamp (server)

### B. Subcollections under `users/{uid}`

**`recently_viewed/{food_id}`** (ID dokumen = ID dokumen food di koleksi `foods`)

*   `food_id`: string
*   `viewed_at`: timestamp

**Firestore index disarankan:** subcollection `recently_viewed` dengan `orderBy viewed_at desc` (Firebase Console akan mengarahkan pembuatan index jika diperlukan).

**`recent_locations/{location_id}`** (`location_id` deterministik dari pembulatan lat/lng)

*   `label`: string (mis. nama POI)
*   `address`: string
*   `lat`, `lng`: number
*   `distance_km`: number (opsional; bisa diisi klien)
*   `last_used_at`: timestamp

### C. Collection: `foods`

*   `food_id`: string (disimpan konsisten dengan ID dokumen Firestore)
*   `name`: string
*   `description`: string
*   `photo_url`: string
*   **`nutrition_grade`**: string enum **`EXCELLENT` | `VERY_GOOD` | `GOOD`** (badge “Excellent / Very good / Good” + filter **Label** di UI)
*   **`food_category`**: string salah satu: `main_course`, `appetizers`, `snacks`, `desserts`, `beverages` (chip **Categories** di home)
*   `health_labels`: array string (tag tambahan, mis. “High Protein”; **bukan** pengganti `nutrition_grade`)
*   `nutritional_info`: map opsional `{ calories?, protein_g?, fat_g?, carb_g? }`
*   `base_price`: number (IDR)
*   `merchant_id`: string (referensi ke `merchants`)
*   `is_available`: boolean
*   `is_featured`: boolean (opsional; kartu hero “You Might Like This”)
*   `recommendation_score`: number (opsional; urutan `sort=recommended`)
*   `comparison_data`: object per provider (harga & deeplink)
    *   `gofood` | `grabfood` | `shopeefood`: `{ price: number, url: string, icon_url?: string }`

### D. Collection: `merchants`

*   `merchant_id`: string (Primary Key konsisten dengan referensi di `foods`)
*   `owner_uid`: string (opsional; Firebase Auth UID pemilik akun merchant)
*   `name`: string (nama warung / vendor untuk UI)
*   `address`: string
*   `coordinates`: GeoPoint
*   `geohash`: string (opsional; optimasi radius)
*   `is_verified`: boolean
*   `is_active`: boolean (default `true`; soft delete set `false`)

### E. Catatan query backend

*   Listing saat ini mengambil semua `foods` dengan `is_available == true`, lalu memfilter/pagination di memori (cukup untuk dataset hackathon). Untuk produksi, tambahkan composite index Firestore jika memindahkan filter `nutrition_grade` / `food_category` ke query native.

---

## 5. API Design (Nest.js)

Base URL contoh: `https://<host>/` — dokumentasi interaktif: `GET /api` (Swagger).

**Header umum (endpoint terproteksi):** `Authorization: Bearer <Firebase_ID_Token>`

### 5.1 Authentication

| Method | Path | Auth | Keterangan |
| :--- | :--- | :--- | :--- |
| POST | `/auth/sync` | Bearer | Sinkronisasi user ke `users/{uid}` jika belum ada. Body opsional: `account_type` (`customer` default, `merchant`) + objek `merchant` (wajib jika merchant). |
| POST | `/auth/signup` | Bearer | **Alias** handler yang sama dengan `/auth/sync` — panggil setelah Firebase signup. Merchant signup satu langkah: kirim profil toko bersamaan. |

### 5.2 Meta (publik, tanpa token)

| Method | Path | Keterangan |
| :--- | :--- | :--- |
| GET | `/meta/food-categories` | Daftar kategori + label EN/ID untuk chip Flutter |
| GET | `/meta/nutrition-grades` | Daftar tier gizi + label EN/ID (selaras `nutrition_grade`) |
| GET | `/meta/nutrition-goals` | Label wizard untuk `nutrition_goal` (`DIET`, `BULKING`, `MAINTAIN`) |
| GET | `/meta/locations/search?q=` | **Placeholder** — mengembalikan `items: []` sampai integrasi Places/Mapbox |

### 5.3 Foods (Bearer wajib)

| Method | Path | Keterangan |
| :--- | :--- | :--- |
| GET | `/foods` | Daftar terpaginasi + filter; respons `{ items, total, page, limit, total_pages }` |
| GET | `/foods/search` | **Sama** dengan `/foods` (semua query parameter dapat dipakai bersamaan, termasuk `q`) |
| GET | `/foods/recommendations` | Home: `{ featured, recommendations, context }` — personalisasi dari profil + opsional `lat`/`lng` |
| GET | `/foods/:id` | Detail; menyertakan `price_comparisons[]` dan simulasi ±5% per provider |

**Query `GET /foods/recommendations`:**

| Parameter | Keterangan |
| :--- | :--- |
| `lat`, `lng` | Opsional — menambah `distance_in_km` pada item dan sedikit boost jarak dekat |
| `featured_limit` | Default `1` — jumlah slot hero “You Might Like This” (mis. `is_featured` diprioritaskan) |
| `limit` | Default `15` — panjang list “Recommendations for You” setelah featured |

Tanpa `nutrition_goal` / `food_preferences` di profil, ranking fallback ke `recommendation_score` + tier gizi (+ jarak jika ada).

**Query `GET /foods` & `GET /foods/search`:**

| Parameter | Tipe | Keterangan |
| :--- | :--- | :--- |
| `q` | string | Substring `name` / `description` |
| `nutrition_grade` | enum | `EXCELLENT`, `VERY_GOOD`, `GOOD` |
| `food_category` | string | Salah satu key kategori (lihat `/meta/food-categories`) |
| `min_price`, `max_price` | number | Filter `base_price` |
| `lat`, `lng` | number | Lokasi user (WGS84) untuk jarak |
| `max_distance_km` | number | Butuh `lat` & `lng`; membuang item di luar radius |
| `sort` | string | `distance` (default jika ada lat/lng), `price_asc`, `recommended` (default tanpa lokasi) |
| `page`, `limit` | number | Pagination (`limit` maks. 100 pada implementasi saat ini) |
| `featured_only` | boolean | `true` → hanya `is_featured` |

**Field tambahan pada item list:** `vendor_name`, `image_url` (alias `photo_url`), dan `distance_in_km` jika `lat`/`lng` dikirim.

**Response detail (`GET /foods/:id`):** selain field dokumen, tersedia:

*   `vendor_name`, `image_url`
*   `price_comparisons`: array `{ platform_key, platform, price, base_price, order_url, icon_url }`

Perbandingan harga di-detail menggunakan fluktuasi tersimulasi pada nilai `price` yang dikembalikan (lihat implementasi backend). Endpoint terpisah `/compare-price/:food_id` **tidak** digunakan; gunakan `GET /foods/:id`.

### 5.4 Users (Bearer wajib)

| Method | Path | Keterangan |
| :--- | :--- | :--- |
| GET | `/users/me` | Profil lengkap termasuk field onboarding |
| PATCH | `/users/me` | Partial update — onboarding (`gender`, `age`, `weight_kg`, `height_cm`, `nutrition_goal`, `food_preferences`, `onboarding_completed`, dll.) |
| POST | `/users/me/recently-viewed` | Body `{ "food_id": "<docId>" }` — panggil saat membuka detail menu |
| GET | `/users/me/recently-viewed` | Query `q`, `page`, `limit` — histori untuk layar “Recently viewed” |
| POST | `/users/me/recent-locations` | Body lokasi; menyimpan/refresh entri recent |
| GET | `/users/me/recent-locations` | Daftar lokasi terbaru |

### 5.5 Merchant (Bearer + role `merchant`)

| Method | Path | Keterangan |
| :--- | :--- | :--- |
| GET | `/merchant/me` | Profil toko merchant login |
| PATCH | `/merchant/me` | Update nama, alamat, koordinat |
| GET | `/merchant/foods` | Daftar menu milik merchant |
| POST | `/merchant/foods` | Buat menu (tanpa `merchant_id`; field admin-only di-strip) |
| PUT | `/merchant/foods/:id` | Update menu milik sendiri |
| DELETE | `/merchant/foods/:id` | Soft delete menu milik sendiri |

### 5.6 Admin (Bearer + role `admin`)

| Method | Path | Keterangan |
| :--- | :--- | :--- |
| GET | `/admin/merchants` | List merchant (filter `is_active` opsional) |
| GET | `/admin/merchants/:id` | Detail merchant |
| POST | `/admin/merchants` | Buat merchant |
| PUT | `/admin/merchants/:id` | Update merchant |
| DELETE | `/admin/merchants/:id` | Soft delete merchant (`is_active: false`) |
| GET | `/admin/merchants/:id/foods` | List foods per merchant |
| POST | `/admin/foods` | Buat dokumen `foods` (lihat DTO; wajib `nutrition_grade`, `food_category`) |
| PUT | `/admin/foods/:id` | Partial update |
| DELETE | `/admin/foods/:id` | Soft delete (`is_available: false`) |

---

## 6. Business Logic & Algorithms

### A. Perhitungan Jarak dan Geolocation Query

Untuk menghitung jarak antara lokasi mahasiswa dan merchant, MVP akan menggunakan pendekatan:

1.  **Geohash Filtering (Scale-up/Optimasi):** Memanfaatkan library seperti `geofire-common` pada backend untuk memfilter merchant dalam radius tertentu (misal 5-10km) guna membatasi jumlah data yang di-fetch dari Firestore.
2.  **Jarak geodesik (`geofire-common.distanceBetween`):** Listing menghitung jarak dalam km antara koordinat user dan `merchants.coordinates`, mengurutkan atau memotong dengan `max_distance_km`.

$$d = 2r \arcsin\left(\sqrt{\sin^2\left(\frac{\phi_2 - \phi_1}{2}\right) + \cos(\phi_1) \cos(\phi_2) \sin^2\left(\frac{\lambda_2 - \lambda_1}{2}\right)}\right)$$

Dimana:

*   $r$: Jari-jari bumi (6.371 km).
*   $\phi_1, \phi_2$: Lintang (latitude) lokasi 1 dan 2.
*   $\lambda_1, \lambda_2$: Bujur (longitude) lokasi 1 dan 2.

### B. Filter & Ranking

1.  **Tingkat gizi:** Filter eksak pada `nutrition_grade` (badge & filter Label).
2.  **Kategori menu:** Filter pada `food_category` (bukan lagi `array-contains` pada `health_labels`).
3.  **Tag tambahan:** `health_labels` tetap ada untuk konten/marketing; filter utama Label memakai `nutrition_grade`.
4.  **Jarak / harga / rekomendasi:** Kombinasi query parameter `sort`, `min_price` / `max_price`, dan `max_distance_km`.

### C. Rekomendasi personal (`GET /foods/recommendations`)

Skor menggabungkan `recommendation_score`, bobot `nutrition_grade`, isi `nutritional_info` sesuai `nutrition_goal` (**DIET**: lebih rendah kalori / lemak; **BULKING**: lebih tinggi protein; **MAINTAIN**: keseimbangan), bonus kecocokan `food_preferences` dengan `health_labels`, dan bonus jarak jika `lat`/`lng` dikirim. Slot **featured** mengutamakan `is_featured` pada urutan skor tertinggi. Tanpa goal maupun preferensi, digunakan skor generik (`recommendation_score` + tier + jarak).

---

## 7. Security & Validation
*   **Authentication Guard:** Mengimplementasikan custom *Guard* di Nest.js yang menggunakan `firebase-admin` SDK (`admin.auth().verifyIdToken()`) untuk memvalidasi *Bearer Token* dari request client.
*   **Role-Based Access Control (RBAC):** Menggunakan custom Decorator (`@Roles()`) dan `RolesGuard` di Nest.js untuk memastikan endpoint Admin tidak diakses oleh Customer (memverifikasi field `role` di Firestore atau via Firebase Custom Claims).
*   **Data Validation:** Menggunakan `class-validator` dan `class-transformer` melalui `ValidationPipe` bawaan Nest.js untuk memvalidasi DTO (Data Transfer Object) secara ketat.
*   **Security Headers:** Implementasi `Helmet` pada Nest.js untuk perlindungan kerentanan standar web.

---

## 8. Frontend Implementation (Flutter) & Backend Integration

### A. State Management & Architecture
*   **State Management:** Menggunakan **Riverpod** atau **Provider** (direkomendasikan untuk kecepatan MVP Hackathon)
*   **Routing:** Menggunakan `go_router` untuk navigasi halaman yang deklaratif dan mempermudah setup *Deep Linking* di masa depan.

### B. Paket Utama (Dependencies)
*   **HTTP Client:** `dio` - Digunakan untuk memanggil endpoint API Nest.js. `dio` sangat ideal karena mendukung fitur *Interceptor* untuk menyelipkan token Auth ke Header secara otomatis.
*   **Geolocation:** `geolocator` - Mengambil lokasi terkini perangkat (latitude & longitude) untuk diteruskan ke backend sebagai parameter pencarian jarak.
*   **Local Storage:** `flutter_secure_storage` - Menyimpan Firebase ID Token atau sesi *auth* secara aman di perangkat.
*   **Firebase SDK:** `firebase_core`, `firebase_auth`, dan `google_sign_in` untuk menangani proses autentikasi di sisi klien.

### C. Alur Integrasi Frontend ke Backend

1.  **Flow Autentikasi:**
    *   **Email signup:** Firebase `createUserWithEmailAndPassword` → `POST /auth/signup` (atau `/auth/sync`) dengan Bearer.
    *   **Google:** sign-in → token → `POST /auth/sync` atau `/auth/signup` (handler sama).
    *   Token disimpan di `flutter_secure_storage`; interceptor `dio` menyematkan header Bearer.
2.  **Onboarding (setelah registrasi):**
    *   Ambil label goal dari `GET /meta/nutrition-goals`.
    *   Kirim `PATCH /users/me` dengan `gender`, `age`, `weight_kg`, `height_cm`, `nutrition_goal`, `food_preferences`, `onboarding_completed: true`.
3.  **API Requests dengan Interceptor (`dio`):**
    *   Set `BaseOptions(baseUrl: 'https://<your-api-host>/')`.
    *   Pada setiap request ke endpoint terproteksi, tambahkan header `Authorization: Bearer <Firebase_ID_Token>` (biasanya via `Interceptor` yang membaca token dari `flutter_secure_storage`).
4.  **Konvensi JSON:** Backend memakai **`snake_case`** untuk field JSON (selaras Firestore). Di Flutter gunakan `@JsonKey(name: 'base_price')` / `json_serializable` atau mapper manual; hindari mengubah kontrak API hanya untuk gaya Dart.
5.  **Meta bootstrap:** `GET /meta/food-categories`, `GET /meta/nutrition-grades`, `GET /meta/nutrition-goals` untuk chip/filter dan wizard onboarding.
6.  **Home — rekomendasi personal:**
    *   `GET /foods/recommendations?lat=&lng=&featured_limit=1&limit=15` → `featured[]` untuk kartu besar “You Might Like This”, `recommendations[]` untuk list “Recommendations for You”.
    *   Kategori horizontal / filter lain boleh tetap pakai `GET /foods` dengan query yang sama seperti sebelumnya.
7.  **Search listing:** **`GET /foods/search`** dengan parameter **yang sama** seperti `/foods`, termasuk `q`.
8.  **Detail menu:**
    *   `GET /foods/{id}` → render deskripsi, `vendor_name`, `nutrition_grade`, dan list **`price_comparisons`** (gunakan `price` untuk teks hijau; `order_url` untuk `url_launcher`).
    *   Setelah layar terbuka, panggil `POST /users/me/recently-viewed` dengan `{ "food_id": "<id>" }`.
9.  **Recently viewed:** `GET /users/me/recently-viewed?q=&page=&limit=` — kelompokkan di Flutter berdasarkan tanggal dari `viewed_at` (hari ini / kemarin / tanggal).
10. **Lokasi:** Setelah user memilih lokasi (map / GPS), `POST /users/me/recent-locations`; daftar “Recent” dari `GET /users/me/recent-locations`. Autocomplete jalanan tetap bisa memakai Places di klien; `GET /meta/locations/search` saat ini placeholder.
11. **Profil:** `GET /users/me` / `PATCH /users/me` untuk menampilkan dan mengubah data akun + onboarding.

### D. Pemetaan layar UI → endpoint

| Layar | Endpoint utama |
| :--- | :--- |
| Login / Sign up (sync) | `POST /auth/sync`, `POST /auth/signup` |
| Onboarding wizard | `GET /meta/nutrition-goals`, `PATCH /users/me` |
| Home (personalized) | `GET /foods/recommendations`, `GET /meta/food-categories`, `GET /foods` (filter/kategori) |
| Search | `GET /foods/search` |
| Detail menu | `GET /foods/:id`, `POST /users/me/recently-viewed` |
| Recently viewed | `GET /users/me/recently-viewed` |
| Select location | `GET /users/me/recent-locations`, `POST /users/me/recent-locations` (+ Places di Flutter) |
| Profil | `GET /users/me`, `PATCH /users/me` |

### E. Contoh payload

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
  "featured": [{ "id": "…", "personalization_score": 128.5, "is_featured": true }],
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
*   **Minggu 1:** Setup Environment (Nest.js & Flutter), Firebase Configuration, Auth Module.
*   **Minggu 2:** Pengembangan Schema Firestore, Admin Dashboard (API), Manual Data Entry.
*   **Minggu 3:** Implementasi Simulasi Data & Deep Linking untuk Price Comparison, UI Homepage & Search.
*   **Minggu 4:** Testing (UAT), Bug Fixing, dan Persiapan Pitching Hackathon.

---
**Rekomendasi Tambahan:**
Untuk integrasi ke tiga layanan pengiriman makanan, pastikan di dalam Flutter diimplementasikan **Deep Linking**. Sehingga saat tombol "Pesan via GoFood" diklik, aplikasi akan langsung mencoba membuka aplikasi GoFood di ponsel user dengan parameter pencarian merchant terkait.