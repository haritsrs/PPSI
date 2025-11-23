# Widgets

Folder ini berisi widget yang dapat digunakan ulang di seluruh aplikasi.

## Tujuan

Widgets digunakan untuk:
* Komponen UI yang digunakan di banyak tempat
* Memecah UI kompleks menjadi bagian-bagian kecil
* Membuat UI yang reusable dan maintainable

## Aturan

### Wajib

* Widget HARUS diorganisir berdasarkan fitur/fungsi dalam subfolder
* Widget HARUS menerima data melalui constructor parameters
* Widget BOLEH menggunakan controller yang di-pass dari parent
* Nama file: [nama]_widget.dart atau deskriptif (contoh: product_card.dart)

### Dilarang

* Menambahkan business logic langsung di widget (gunakan controller)
* Menambahkan state management kompleks di widget (gunakan controller)
* Membuat widget yang terlalu besar (pecah menjadi widget lebih kecil)

## Struktur Subfolder

Widget diorganisir berdasarkan fitur:
* account/ - Widget untuk halaman account
* auth/ - Widget untuk autentikasi
* customers/ - Widget untuk pelanggan
* home/ - Widget untuk halaman home
* kasir/ - Widget untuk kasir
* notifications/ - Widget untuk notifikasi
* onboarding/ - Widget untuk onboarding
* products/ - Widget untuk produk
* settings/ - Widget untuk pengaturan

## Widget Umum

Beberapa widget yang digunakan di berbagai tempat diletakkan langsung di folder widgets/:
* contact_us_modal.dart - Modal kontak kami
* download_success_dialog.dart - Dialog sukses download
* export_dialog.dart - Dialog export
* feature_card.dart - Card untuk fitur
* gradient_app_bar.dart - AppBar dengan gradient
* home_feature.dart - Widget fitur home
* loading_skeletons.dart - Loading skeleton
* news_card.dart - Card berita
* news_detail_modal.dart - Modal detail berita
* pattern_background.dart - Background pattern
* period_toggle.dart - Toggle periode
* print_receipt_dialog.dart - Dialog print struk
* receipt_preview.dart - Preview struk
* report_app_bar.dart - AppBar untuk laporan
* report_content.dart - Konten laporan
* report_error_state.dart - Error state untuk laporan
* report_filters.dart - Filter laporan
* report_transaction_list.dart - List transaksi laporan
* responsive_page.dart - Page wrapper responsive
* revenue_chart.dart - Chart revenue
* status_banner.dart - Banner status
* summary_card.dart - Card summary
* transaction_card.dart - Card transaksi
* transaction_detail_modal.dart - Modal detail transaksi
* welcome_header.dart - Header welcome
* withdrawal_dialog.dart - Dialog withdrawal

## Contoh Struktur

```dart
class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  
  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return Card(
      // UI implementation
    );
  }
}
```

