# 🏪 KiosDarma (PPSI)

<div align="center">

**Sistem Point of Sale (POS) Modern untuk Mengelola Bisnis Anda**

[![Flutter](https://img.shields.io/badge/Flutter-3.9.2+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.9.2+-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Enabled-FFCA28?logo=firebase&logoColor=black)](https://firebase.google.com)
[![License](https://img.shields.io/badge/License-Private-red)](LICENSE)

*Solusi lengkap untuk manajemen produk, transaksi, dan laporan bisnis Anda*

</div>

---

## 📋 Daftar Isi

- [Tentang Proyek](#-tentang-proyek)
- [Fitur Utama](#-fitur-utama)
- [Teknologi yang Digunakan](#-teknologi-yang-digunakan)
- [Persyaratan Sistem](#-persyaratan-sistem)
- [Instalasi](#-instalasi)
- [Konfigurasi](#-konfigurasi)
- [Struktur Proyek](#-struktur-proyek)
- [Penggunaan](#-penggunaan)
- [Kontribusi](#-kontribusi)
- [Lisensi](#-lisensi)

---

## 🎯 Tentang Proyek

**KiosDarma** adalah aplikasi Point of Sale (POS) berbasis Flutter yang dirancang untuk membantu pemilik bisnis mengelola operasional toko mereka dengan mudah dan efisien. Aplikasi ini menyediakan fitur lengkap mulai dari manajemen produk, transaksi kasir, manajemen pelanggan, hingga laporan keuangan yang komprehensif.

### Mengapa KiosDarma?

- ✅ **Mudah Digunakan** - Interface yang intuitif dan user-friendly
- ✅ **Real-time Sync** - Data tersinkronisasi secara real-time dengan Firebase
- ✅ **Multi-platform** - Berjalan di Android, iOS, Web, Windows, Linux, dan macOS
- ✅ **Integrasi Pembayaran** - Mendukung QRIS dan Virtual Account melalui Xendit
- ✅ **Offline Support** - Tetap berfungsi meskipun tanpa koneksi internet
- ✅ **Arsitektur Modern** - Clean architecture dengan separation of concerns

---

## ✨ Fitur Utama

### 🛒 Manajemen Produk
- Tambah, edit, dan hapus produk
- Manajemen stok dengan notifikasi stok rendah
- Kategori produk untuk organisasi yang lebih baik
- Scan barcode untuk pencarian cepat
- Upload gambar produk
- History perubahan stok

### 💰 Sistem Kasir
- Interface kasir yang cepat dan responsif
- Cart management yang intuitif
- Multiple metode pembayaran (Tunai, QRIS, Virtual Account)
- Print struk otomatis
- Riwayat transaksi lengkap

### 👥 Manajemen Pelanggan
- Database pelanggan terpusat
- Pencarian dan filter pelanggan
- Detail informasi pelanggan
- Riwayat transaksi per pelanggan

### 📊 Laporan & Analitik
- Laporan penjualan harian, mingguan, dan bulanan
- Grafik revenue untuk visualisasi data
- Export laporan ke Excel dan PDF
- Filter berdasarkan periode
- Detail transaksi lengkap

### 🔔 Notifikasi
- Notifikasi stok rendah
- Notifikasi transaksi baru
- Notifikasi pembayaran
- Sistem notifikasi real-time

### ⚙️ Pengaturan
- Pengaturan informasi bisnis
- Konfigurasi printer (Bluetooth & USB)
- Pengaturan keamanan data
- Manajemen notifikasi
- Support & bantuan

### 🔐 Keamanan
- Autentikasi dengan Firebase Auth
- Enkripsi data sensitif
- Verifikasi email
- Manajemen password yang aman

---

## 🛠️ Teknologi yang Digunakan

### Frontend
- **Flutter** - Framework UI cross-platform
- **Dart** - Bahasa pemrograman

### Backend & Services
- **Firebase Authentication** - Sistem autentikasi
- **Firebase Realtime Database** - Database real-time
- **Firebase Storage** - Penyimpanan file dan gambar
- **Xendit** - Integrasi pembayaran (QRIS & Virtual Account)

### Libraries Utama
- `mobile_scanner` - Scanner barcode/QR code
- `flutter_blue_plus` - Koneksi printer Bluetooth
- `usb_serial` - Koneksi printer USB
- `printing` - Print PDF dan struk
- `excel` & `pdf` - Export laporan
- `cached_network_image` - Optimasi loading gambar
- `connectivity_plus` - Monitoring koneksi internet

### Tools & Utilities
- `shared_preferences` - Local storage
- `intl` - Formatting tanggal dan currency
- `image_picker` & `flutter_image_compress` - Manajemen gambar
- `url_launcher` - Integrasi email dan WhatsApp

---

## 📱 Persyaratan Sistem

### Development
- Flutter SDK 3.9.2 atau lebih tinggi
- Dart SDK 3.9.2 atau lebih tinggi
- Android Studio / VS Code dengan Flutter extension
- Git

### Runtime
- **Android**: Minimum SDK 21 (Android 5.0 Lollipop)
- **iOS**: iOS 12.0 atau lebih tinggi
- Koneksi internet untuk sinkronisasi data
- (Opsional) Printer Bluetooth/USB untuk print struk

---

## 🚀 Instalasi

### 1. Clone Repository

```bash
git clone https://github.com/username/ppsi.git
cd ppsi
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Setup Firebase

1. Buat project baru di [Firebase Console](https://console.firebase.google.com)
2. Download file konfigurasi:
   - `google-services.json` untuk Android (letakkan di `android/app/`)
   - `GoogleService-Info.plist` untuk iOS (letakkan di `ios/Runner/`)
3. File `firebase_options.dart` sudah di-generate dan tersedia

### 4. Setup Environment Variables

Buat file `.env` di root project:

```env
XENDIT_SECRET_KEY=your_xendit_secret_key
XENDIT_PUBLIC_KEY=your_xendit_public_key
```

### 5. Run Aplikasi

```bash
# Development
flutter run

# Build APK (Android)
flutter build apk --release

# Build IPA (iOS)
flutter build ios --release
```

---

## ⚙️ Konfigurasi

### Firebase Database Rules

Pastikan aturan keamanan Firebase Database sudah dikonfigurasi dengan benar. Lihat file `firebase_database.rules.json` untuk referensi.

### Firebase Storage Rules

Konfigurasi aturan storage di `storage.rules` untuk mengatur akses file dan gambar.

### Xendit Setup

Untuk menggunakan fitur pembayaran QRIS dan Virtual Account, ikuti langkah berikut:

1. **Daftar Akun Xendit**
   - Daftar di [Xendit](https://www.xendit.co/)
   - Login ke dashboard Xendit

2. **Dapatkan API Keys**
   - Buka Settings > API Keys di dashboard Xendit
   - Copy Secret Key (dimulai dengan `xnd_secret_...`)
   - Copy Public Key (untuk development atau production)

3. **Konfigurasi Environment Variables**
   - Tambahkan keys ke file `.env`:
   ```env
   XENDIT_SECRET_KEY=your_xendit_secret_key_here
   XENDIT_PUBLIC_KEY=your_xendit_public_key_here
   ENCRYPTION_KEY=your_secure_encryption_key_here
   ```
   
   **Penting:**
   - Jangan commit file `.env` ke version control
   - Generate encryption key yang kuat (minimal 32 karakter)
   - Untuk development, gunakan development public key dari Xendit dashboard

4. **Metode Pembayaran yang Tersedia**
   - **QRIS**: Pembayaran via QR code yang dapat di-scan dengan aplikasi e-wallet
   - **Virtual Account**: Pembayaran via transfer bank ke nomor VA yang di-generate
     - Bank yang didukung: BCA, BNI, BRI, Mandiri, Permata

5. **Testing**
   - Development mode menggunakan Xendit sandbox environment
   - Production mode memerlukan aktivasi akun Xendit untuk production
   - Pastikan semua environment variables sudah di-set dengan benar

**Troubleshooting:**
- Jika error "Xendit secret key is not set": Pastikan `XENDIT_SECRET_KEY` sudah ditambahkan ke `.env` dan restart aplikasi
- Jika error "ENCRYPTION_KEY must be set": Tambahkan `ENCRYPTION_KEY` dengan key yang kuat (minimal 32 karakter)
- Jika payment status tidak update: Aplikasi akan polling setiap 3-5 detik, pastikan koneksi internet stabil

**Sumber Daya:**
- Dokumentasi Xendit: https://docs.xendit.co
- Dashboard Xendit: https://dashboard.xendit.co

---

## 📁 Struktur Proyek

Aplikasi ini menggunakan arsitektur clean dengan separation of concerns yang jelas. Setiap folder memiliki tanggung jawab spesifik:

```
lib/
├── controllers/     # State management (ChangeNotifier)
├── models/          # Data classes dan model
├── pages/           # Entry point halaman (minimal logic)
├── routes/          # Konfigurasi routing aplikasi
├── services/        # Business logic stateless
├── themes/          # Tema, warna, dan style
├── utils/           # Helper functions dan utilities
└── widgets/         # Komponen UI yang dapat digunakan ulang
    ├── account/     # Widget untuk halaman account
    ├── auth/        # Widget untuk autentikasi
    ├── customers/   # Widget untuk pelanggan
    ├── home/        # Widget untuk halaman home
    ├── kasir/       # Widget untuk kasir
    ├── notifications/ # Widget untuk notifikasi
    ├── onboarding/  # Widget untuk onboarding
    ├── products/    # Widget untuk produk
    └── settings/    # Widget untuk pengaturan
```

### Penjelasan Folder

#### `controllers/` - Manajemen State
- Mengelola state aplikasi menggunakan `ChangeNotifier`
- Memanggil services untuk operasi data
- Memberitahu listener ketika state berubah
- **Aturan:** HARUS extends `ChangeNotifier`, HARUS dispose resources, TIDAK BOLEH berisi UI code

#### `models/` - Data Classes
- Merepresentasikan struktur data aplikasi
- Konversi data dari/to Firebase/JSON
- **Aturan:** HARUS memiliki factory constructor `fromFirebase()` dan method `toFirebase()`

#### `pages/` - Entry Point Halaman
- Halaman utama aplikasi dengan logic minimal
- Hanya inisialisasi controller dan komposisi widget
- **Aturan:** HARUS minimal, BOLEH state UI sederhana, TIDAK BOLEH business logic

#### `routes/` - Routing
- Konfigurasi routing aplikasi
- Definisi semua route di `app_routes.dart`

#### `services/` - Business Logic
- Business logic stateless
- Operasi Firebase, API calls, integrasi third-party
- **Aturan:** HARUS stateless, TIDAK BOLEH state management

#### `themes/` - Tema & Styling
- Konfigurasi tema global aplikasi
- Warna, text styles, theme data

#### `utils/` - Helper Functions
- Utility functions yang reusable
- Formatting, validasi, error handling
- **Aturan:** HARUS stateless, fokus pada satu fungsi spesifik

#### `widgets/` - Komponen UI
- Widget yang dapat digunakan ulang
- Diorganisir berdasarkan fitur dalam subfolder
- **Aturan:** HARUS menerima data via constructor, TIDAK BOLEH business logic langsung

### Alur Data yang Benar

```
User Action (Page)
    ↓
Controller (mengelola state)
    ↓
Service (operasi data)
    ↓
Firebase/Database
```

**Contoh:**
1. User klik tombol di `HomePage` (page)
2. `HomePage` memanggil method di `HomeController` (controller)
3. `HomeController` memanggil `DatabaseService.getData()` (service)
4. `DatabaseService` membaca dari Firebase
5. Data dikembalikan ke controller
6. Controller update state dan call `notifyListeners()`
7. Page rebuild dengan data baru

### Aturan Penting

**JANGAN:**
- Menambahkan business logic di page
- Menambahkan state management di service
- Menambahkan UI code di controller
- Membuat widget terlalu besar tanpa dipecah
- Lupa dispose resources di controller

**Setiap folder memiliki README.md sendiri** yang menjelaskan aturan dan struktur detail. Lihat dokumentasi di masing-masing folder untuk informasi lebih lanjut.

---

## 💻 Penggunaan

### Menjalankan Aplikasi

1. **Development Mode**
   ```bash
   flutter run
   ```

2. **Build Release**
   ```bash
   # Android
   flutter build apk --release
   
   # iOS
   flutter build ios --release
   ```

3. **Build APK dengan Script**
   ```bash
   # Windows
   build_apk.bat
   ```

### Fitur Utama

#### 1. Login & Registrasi
- Buat akun baru atau login dengan email yang sudah terdaftar
- Verifikasi email untuk keamanan akun

#### 2. Manajemen Produk
- Tambah produk baru dengan detail lengkap
- Edit informasi produk
- Hapus produk yang tidak digunakan
- Scan barcode untuk pencarian cepat
- Monitor stok dan dapatkan notifikasi stok rendah

#### 3. Transaksi Kasir
- Pilih produk dari daftar
- Tambah ke cart
- Pilih metode pembayaran
- Print struk (jika printer tersedia)
- Lihat riwayat transaksi

#### 4. Laporan
- Lihat laporan penjualan berdasarkan periode
- Export laporan ke Excel atau PDF
- Analisis revenue dengan grafik

---

## 🤝 Kontribusi

Kontribusi sangat diterima! Untuk menjaga kualitas kode, silakan ikuti panduan berikut:

### Aturan Kontribusi

1. **Fork** repository ini
2. **Buat branch** untuk fitur baru (`git checkout -b feature/AmazingFeature`)
3. **Commit** perubahan Anda (`git commit -m 'Add some AmazingFeature'`)
4. **Push** ke branch (`git push origin feature/AmazingFeature`)
5. **Buka Pull Request**

### Pedoman Kode

- Ikuti struktur folder yang sudah ditetapkan
- Baca README.md di setiap folder sebelum menambahkan file baru
- Gunakan format kode yang konsisten
- Tambahkan komentar untuk kode yang kompleks
- Test aplikasi sebelum commit
- Pastikan tidak melanggar aturan folder (lihat penjelasan di bagian Struktur Proyek)

---

## 📄 Lisensi

Proyek ini adalah proyek **private** dan tidak tersedia untuk penggunaan publik tanpa izin.

---

## 📞 Support

Jika Anda memiliki pertanyaan atau membutuhkan bantuan:

- 📧 Email: [your-email@example.com]
- 💬 WhatsApp: [your-whatsapp-number]
- 🐛 Issues: [GitHub Issues](https://github.com/username/ppsi/issues)

---

## 🙏 Acknowledgments

- [Flutter Team](https://flutter.dev/) - Framework yang luar biasa
- [Firebase](https://firebase.google.com/) - Backend services
- [Xendit](https://www.xendit.co/) - Payment gateway
- Semua kontributor dan pengguna aplikasi ini

---

<div align="center">

**Dibuat dengan ❤️ menggunakan Flutter**

⭐ Jika proyek ini membantu Anda, berikan star di repository ini!

</div>
