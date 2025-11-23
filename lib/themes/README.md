# Themes

Folder ini berisi konfigurasi tema aplikasi.

## Tujuan

Themes digunakan untuk:
* Mendefinisikan warna aplikasi
* Mendefinisikan text styles
* Mendefinisikan theme data global

## Aturan

### Wajib

* Semua tema HARUS didefinisikan di app_theme.dart
* Theme HARUS konsisten di seluruh aplikasi
* Theme HARUS menggunakan Material Design guidelines

### Dilarang

* Menambahkan business logic
* Menambahkan widget
* Membuat theme yang tidak konsisten

## Contoh Struktur

```dart
class AppTheme {
  static ThemeData get theme {
    return ThemeData(
      primarySwatch: Colors.indigo,
      fontFamily: 'Inter',
      textTheme: const TextTheme(
        // Text styles
      ),
    );
  }
}
```

## File yang Ada

* app_theme.dart - Tema utama aplikasi, berisi warna, text styles, dan konfigurasi theme global

