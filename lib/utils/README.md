# Utils

Folder ini berisi utility functions yang dapat digunakan di seluruh aplikasi.

## Tujuan

Utils digunakan untuk:
* Formatting (currency, date, dll)
* Validasi input
* Error handling helpers
* Helper functions yang reusable

## Aturan

### Wajib

* Utils HARUS stateless (tidak menyimpan state)
* Utils HARUS fokus pada satu fungsi spesifik
* Utils BOLEH menggunakan static methods
* Nama file: [nama]_utils.dart atau [nama]_helper.dart

### Dilarang

* Menambahkan state management
* Menambahkan UI code
* Menambahkan business logic kompleks (gunakan service)

## Contoh Struktur

```dart
class FormatUtils {
  static String formatCurrency(num value) {
    return 'Rp ${value.toStringAsFixed(0).replaceAllMapped(...)}';
  }
}
```

## File yang Ada

* app_exception.dart - Exception classes untuk aplikasi
* currency_input_formatter.dart - Formatter untuk input currency
* error_helper.dart - Helper untuk error handling
* format_utils.dart - Utility untuk formatting (currency, date, dll)
* haptic_helper.dart - Helper untuk haptic feedback
* home_utils.dart - Utility khusus untuk halaman home
* notification_utils.dart - Utility untuk notifikasi
* responsive_helper.dart - Helper untuk responsive design
* security_utils.dart - Utility untuk security (enkripsi, dll)
* snackbar_helper.dart - Helper untuk menampilkan snackbar
* validation_utils.dart - Utility untuk validasi input

