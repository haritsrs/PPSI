# Product Widgets

Folder ini berisi widget-widget yang digunakan di halaman produk.

## Tujuan

Widget di folder ini digunakan untuk:
* Menampilkan list produk
* Card untuk menampilkan produk
* Form untuk menambah/edit produk
* Dialog untuk detail produk
* Dialog untuk menghapus produk
* Search dan filter untuk produk
* Summary section untuk produk
* Status banner untuk produk
* Dialog untuk scan barcode
* Dialog untuk update stock

## Struktur

Folder ini memiliki subfolder dialogs/ yang berisi dialog-dialog khusus produk.

## File yang Ada

* product_app_bar.dart - AppBar untuk halaman produk
* product_card.dart - Card untuk menampilkan produk
* product_content_section.dart - Section konten produk
* product_delete_dialog.dart - Dialog konfirmasi hapus produk
* product_detail_modal.dart - Modal detail produk
* product_dismissible_background.dart - Background untuk dismissible
* product_error_state.dart - Error state untuk produk
* product_list_section.dart - Section list produk
* product_search_filter_section.dart - Section search dan filter
* product_status_banner.dart - Banner status produk
* product_summary_section.dart - Section summary produk
* scan_barcode_dialog.dart - Dialog untuk scan barcode

## Subfolder dialogs/

* add_edit_product_dialog.dart - Dialog untuk tambah/edit produk
* bulk_stock_update_dialog.dart - Dialog untuk update stock bulk
* edit_stock_dialog.dart - Dialog untuk edit stock
* stock_history_dialog.dart - Dialog untuk history stock

## Aturan

* Widget di folder ini HARUS menerima data melalui constructor
* Widget BOLEH menggunakan controller yang di-pass dari parent
* Widget TIDAK BOLEH berisi business logic (gunakan controller)
* Widget TIDAK BOLEH memanggil Firebase/API langsung

