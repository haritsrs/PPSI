# Controllers

Folder ini berisi controller yang mengelola state aplikasi menggunakan ChangeNotifier.

## Tujuan

Controller bertanggung jawab untuk:
* Mengelola state UI
* Memanggil services untuk operasi data
* Memberitahu listener ketika state berubah
* Menangani logika bisnis yang terkait dengan state

## Aturan

### Wajib

* Semua controller HARUS extends ChangeNotifier
* Controller HARUS memanggil notifyListeners() ketika state berubah
* Controller BOLEH memanggil services, tapi TIDAK BOLEH berisi logika UI
* Controller HARUS dispose resources (subscriptions, timers, dll) di method dispose()
* Nama file: [nama]_controller.dart (contoh: home_controller.dart)

### Dilarang

* Menambahkan widget atau UI code di controller
* Menambahkan business logic yang tidak terkait state (gunakan services/)
* Membuat controller tanpa extends ChangeNotifier
* Lupa dispose resources

## Contoh Struktur

```dart
class HomeController extends ChangeNotifier {
  User? _currentUser;
  
  User? get currentUser => _currentUser;
  
  Future<void> initialize() async {
    // Load data
    notifyListeners();
  }
  
  @override
  void dispose() {
    // Cleanup subscriptions, timers, dll
    super.dispose();
  }
}
```

## File yang Ada

* account_controller.dart - Mengelola state halaman account
* berita_controller.dart - Mengelola state halaman berita
* customer_controller.dart - Mengelola state pelanggan
* home_controller.dart - Mengelola state halaman home
* kasir_controller.dart - Mengelola state kasir dan cart
* laporan_controller.dart - Mengelola state laporan
* login_controller.dart - Mengelola state login
* logout_controller.dart - Mengelola state logout
* notification_controller.dart - Mengelola state notifikasi
* onboarding_controller.dart - Mengelola state onboarding
* printer_controller.dart - Mengelola state printer
* product_controller.dart - Mengelola state produk
* register_controller.dart - Mengelola state registrasi
* settings_controller.dart - Mengelola state pengaturan

