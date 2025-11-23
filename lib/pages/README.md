# Pages

Folder ini berisi halaman utama aplikasi. Pages adalah entry point yang menginisialisasi controller dan mengatur layout dasar.

## Tujuan

Pages digunakan untuk:
* Menginisialisasi controller
* Mengatur layout dasar (Scaffold, AppBar, dll)
* Mengomposisi widget-widget
* Menangani navigasi sederhana

## Aturan

### Wajib

* Page HARUS minimal - hanya inisialisasi controller dan komposisi widget
* Page BOLEH mengelola state UI sederhana (tab index, dropdown selection, dll)
* Page BOLEH memanggil method controller
* Page HARUS menggunakan widget dari folder widgets/ untuk UI kompleks
* Nama file: [nama]_page.dart (contoh: home_page.dart)

### Dilarang

* Menambahkan business logic di page (gunakan controller)
* Menambahkan kode UI panjang di page (ekstrak ke widget)
* Memanggil Firebase/API langsung dari page
* Menambahkan helper functions (gunakan utils/)
* Menambahkan data processing logic

## Contoh Struktur

```dart
class HomePage extends StatefulWidget {
  const HomePage({super.key});
  
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late HomeController _controller;
  int _selectedIndex = 0;
  
  @override
  void initState() {
    super.initState();
    _controller = HomeController()..initialize();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(controller: _controller),
      body: HomeContent(controller: _controller),
    );
  }
}
```

## File yang Ada

* account_page.dart - Halaman account
* berita_page.dart - Halaman berita
* home_page.dart - Halaman utama
* kasir_page.dart - Halaman kasir
* laporan_page.dart - Halaman laporan
* login_page.dart - Halaman login
* logout_page.dart - Halaman logout
* notification_page.dart - Halaman notifikasi
* onboarding_page.dart - Halaman onboarding
* pelanggan_page.dart - Halaman pelanggan
* pengaturan_page.dart - Halaman pengaturan
* produk_page.dart - Halaman produk
* register_page.dart - Halaman registrasi

