# Customer Widgets

Folder ini berisi widget-widget yang digunakan untuk mengelola pelanggan.

## Tujuan

Widget di folder ini digunakan untuk:
* Menampilkan list pelanggan
* Card untuk menampilkan data pelanggan
* Form untuk menambah/edit pelanggan
* Dialog untuk detail pelanggan
* Dialog untuk menghapus pelanggan
* Search dan filter untuk pelanggan
* Summary section untuk pelanggan

## File yang Ada

* customer_app_bar.dart - AppBar untuk halaman pelanggan
* customer_card.dart - Card untuk menampilkan data pelanggan
* customer_delete_dialog.dart - Dialog konfirmasi hapus pelanggan
* customer_detail_modal.dart - Modal detail pelanggan
* customer_form_dialog.dart - Dialog form untuk tambah/edit pelanggan
* customer_list_section.dart - Section list pelanggan
* customer_search_filter_section.dart - Section search dan filter
* customer_summary_section.dart - Section summary pelanggan

## Aturan

* Widget di folder ini HARUS menerima data melalui constructor
* Widget BOLEH menggunakan controller yang di-pass dari parent
* Widget TIDAK BOLEH berisi business logic (gunakan controller)
* Widget TIDAK BOLEH memanggil Firebase/API langsung

