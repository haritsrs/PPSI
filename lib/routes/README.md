# Routes

Folder ini berisi konfigurasi routing aplikasi.

## Tujuan

Routes digunakan untuk:
* Mendefinisikan semua route aplikasi
* Mengelola navigasi global
* Menangani deep linking

## Aturan

### Wajib

* Semua route HARUS didefinisikan di app_routes.dart
* Route constants HARUS menggunakan format: static const String [nama] = '/[nama]'
* Route builder HARUS return widget yang sesuai

### Dilarang

* Menambahkan business logic di routes
* Membuat route tanpa mendefinisikannya di app_routes.dart
* Menambahkan UI code di routes

## Contoh Struktur

```dart
class AppRoutes {
  static const String home = '/home';
  static const String login = '/login';
  
  static Map<String, WidgetBuilder> getRoutes() {
    return {
      home: (context) => const HomePage(),
      login: (context) => const LoginPage(),
    };
  }
}
```

## File yang Ada

* app_routes.dart - Definisi semua route aplikasi
* auth_wrapper.dart - Wrapper untuk auth state checking, menentukan apakah user harus login atau tidak

