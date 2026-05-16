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
Struktur data dirancang untuk mendukung transisi dari MVP ke fitur *Merchant* di masa depan.

### A. Collection: `users`
*   `uid`: string (Primary Key - dari Firebase Auth)
*   `name`: string
*   `username`: string (unique)
*   `email`: string
*   `role`: string ("customer", "admin", "merchant")
*   `created_at`: timestamp

### B. Collection: `foods`
*   `food_id`: string (Primary Key)
*   `name`: string
*   `description`: text
*   `photo_url`: string
*   `health_labels`: array (e.g., ["High Protein", "Low Calorie", "Vegan"])
*   `base_price`: number
*   `merchant_id`: string (Reference to `merchants`)
*   `is_available`: boolean
*   `comparison_data`: object (Data perbandingan harga dan tautan)
    *   `gofood`: object (`price`: number, `url`: string)
    *   `grabfood`: object (`price`: number, `url`: string)
    *   `shopeefood`: object (`price`: number, `url`: string)

### C. Collection: `merchants`
*   `merchant_id`: string (Primary Key)
*   `name`: string
*   `address`: string
*   `coordinates`: geopoint (lat, long)
*   `geohash`: string (Digunakan untuk optimasi query pencarian berbasis lokasi/radius)
*   `is_verified`: boolean

---

## 5. API Design (Nest.js Endpoints)

### 1. Authentication
*   `POST /auth/signup`: Pendaftaran user baru (di-handle Frontend via Firebase, backend opsional menyimpan data profil ke Firestore).
*   `POST /auth/login`: Login user via Firebase Auth.
*   *(Backend mengandalkan token Firebase Auth JWT yang dikirim via header `Authorization: Bearer <token>` untuk validasi endpoint lainnya)*

### 2. Foods (Public/User - Membutuhkan Auth Token)
*   `GET /foods`: Mengambil daftar makanan (support filter: `category`, `price_range`, `label`, `lat`, `lng`).
*   `GET /foods/:id`: Detail makanan termasuk perbandingan harga.
*   `GET /foods/search?q=`: Pencarian berdasarkan nama/deskripsi.

### 3. Comparison Logic (Local Static Mock Data)
*   `GET /compare-price/:food_id`: Backend mengambil dokumen terkait dari Firestore yang berisi harga dan URL yang telah diinput admin secara manual. Backend dapat mengembalikan harga tersebut secara statis, atau menerapkan simulasi dinamis (misalnya fluktuasi harga acak $\pm 5\%$) untuk menyimulasikan promo atau perubahan harga secara real-time.

### 4. Admin (Internal - Membutuhkan Auth Token & Role 'admin')
*   `POST /admin/foods`: Input data makanan baru.
*   `PUT /admin/foods/:id`: Update data makanan.
*   `DELETE /admin/foods/:id`: Soft delete data makanan.

---

## 6. Business Logic & Algorithms

### A. Perhitungan Jarak dan Geolocation Query
Untuk menghitung jarak antara lokasi mahasiswa dan merchant, MVP akan menggunakan pendekatan:
1.  **Geohash Filtering (Scale-up/Optimasi):** Memanfaatkan library seperti `geofire-common` pada backend untuk memfilter merchant dalam radius tertentu (misal 5-10km) guna membatasi jumlah data yang di-fetch dari Firestore.
2.  **Formula Haversine (Backend Logic):** Setelah data merchant terdekat didapatkan, backend menghitung presisi jarak *real* menggunakan formula Haversine:

$$d = 2r \arcsin\left(\sqrt{\sin^2\left(\frac{\phi_2 - \phi_1}{2}\right) + \cos(\phi_1) \cos(\phi_2) \sin^2\left(\frac{\lambda_2 - \lambda_1}{2}\right)}\right)$$

Dimana:
*   $r$: Jari-jari bumi (6.371 km).
*   $\phi_1, \phi_2$: Lintang (latitude) lokasi 1 dan 2.
*   $\lambda_1, \lambda_2$: Bujur (longitude) lokasi 1 dan 2.

### B. Filter & Ranking
Algoritma filter pada MVP akan memprioritaskan hasil berdasarkan:
1.  **Relevansi Label:** Kesesuaian dengan input kategori user (misal: "Vegan", "High Protein").
2.  **Jarak:** Merchant terdekat dari koordinat user hasil kalkulasi backend.
3.  **Harga:** Urutan dari yang termurah berdasarkan data perbandingan yang disimulasikan dari backend.

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
    *   User menekan tombol "Sign in with Google" di Flutter.
    *   Flutter menggunakan Firebase SDK untuk login dan menghasilkan **Firebase ID Token** (JWT).
    *   Token ini disimpan secara lokal di `flutter_secure_storage`.
2.  **API Requests dengan Interceptor:**
    *   Untuk setiap request ke endpoint Nest.js yang terproteksi (seperti interaksi Admin atau User Profile), interceptor dari `dio` akan mengambil token dan otomatis menambahkan header: `Authorization: Bearer <Firebase_ID_Token>`.
3.  **Query Location-Based:**
    *   Pada *Homepage*, Flutter menggunakan `geolocator` lalu mengirim *GET request* ke backend Nest.js dengan membawa *query parameter*: `GET /foods?lat=-6.20&lng=106.81`.
    *   Backend Nest.js merespon dengan daftar makanan bergizi yang sudah difilter dan diurutkan berdasarkan *Haversine distance*.
4.  **Redirect / Deep Linking Pemesanan:**
    *   Aplikasi memanfaatkan package `url_launcher`. Saat user menekan tombol harga dari GoFood/GrabFood hasil balasan backend dari data statis yang diolah, Flutter akan membuka URL *scheme* aplikasi terkait yang telah diinput admin (contoh: `gofood://merchant/...` atau link web *fallback*) untuk meneruskan pesanan.

---

## 9. Roadmap Pengembangan (MVP)
*   **Minggu 1:** Setup Environment (Nest.js & Flutter), Firebase Configuration, Auth Module.
*   **Minggu 2:** Pengembangan Schema Firestore, Admin Dashboard (API), Manual Data Entry.
*   **Minggu 3:** Implementasi Simulasi Data & Deep Linking untuk Price Comparison, UI Homepage & Search.
*   **Minggu 4:** Testing (UAT), Bug Fixing, dan Persiapan Pitching Hackathon.

---
**Rekomendasi Tambahan:**
Untuk integrasi ke tiga layanan pengiriman makanan, pastikan di dalam Flutter diimplementasikan **Deep Linking**. Sehingga saat tombol "Pesan via GoFood" diklik, aplikasi akan langsung mencoba membuka aplikasi GoFood di ponsel user dengan parameter pencarian merchant terkait.