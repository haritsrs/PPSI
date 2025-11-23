# Services

Folder ini berisi service yang menangani business logic tanpa state.

## Tujuan

Services digunakan untuk:
* Operasi Firebase (CRUD)
* API calls
* Utility functions yang stateless
* Operasi file/storage
* Integrasi dengan third-party services

## Aturan

### Wajib

* Service HARUS stateless (tidak extends ChangeNotifier)
* Service BOLEH menggunakan static methods atau singleton pattern
* Service HARUS fokus pada satu tanggung jawab
* Nama file: [nama]_service.dart (contoh: auth_service.dart)

### Dilarang

* Menambahkan state management di service (gunakan controller)
* Menambahkan UI code
* Menambahkan widget
* Membuat service yang mengelola state UI

## Contoh Struktur

```dart
class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  
  static User? get currentUser => _auth.currentUser;
  
  static Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    // Implementation
  }
}
```

## File yang Ada

* auth_service.dart - Service untuk autentikasi (login, register, logout)
* barcode_scanner_service.dart - Service untuk scanning barcode
* database_service.dart - Service untuk operasi database Firebase
* news_service.dart - Service untuk berita
* onboarding_service.dart - Service untuk onboarding
* printer_commands.dart - Command untuk printer
* receipt_builder.dart - Builder untuk struk
* receipt_service.dart - Service untuk struk
* report_export_service.dart - Service untuk export laporan
* settings_service.dart - Service untuk pengaturan
* storage_service.dart - Service untuk file storage
* xendit_service.dart - Service untuk integrasi Xendit (pembayaran)

