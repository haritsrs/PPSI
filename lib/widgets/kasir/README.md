# Kasir Widgets

Folder ini berisi widget-widget yang digunakan di halaman kasir.

## Tujuan

Widget di folder ini digunakan untuk:
* Menampilkan produk di kasir
* Cart dan item cart
* Dialog untuk pembayaran
* Dialog untuk scan barcode
* Search dan filter produk
* State untuk empty dan error
* Dialog untuk transaksi sukses
* Dialog untuk pembayaran QRIS dan Virtual Account

## File yang Ada

* add_product_dialog.dart - Dialog untuk menambah produk ke cart
* barcode_scanner_instructions_dialog.dart - Dialog instruksi scanner barcode
* cart_fab.dart - Floating action button untuk cart
* cart_item_card.dart - Card untuk item di cart
* cart_panel.dart - Panel untuk cart
* empty_product_state.dart - State ketika tidak ada produk
* error_state_widget.dart - Widget untuk error state
* payment_modal.dart - Modal untuk pembayaran
* product_card.dart - Card produk di kasir
* product_list_item.dart - Item list produk
* qris_payment_dialog.dart - Dialog pembayaran QRIS
* search_and_category_section.dart - Section search dan kategori
* transaction_success_dialog.dart - Dialog sukses transaksi
* virtual_account_bank_selection_dialog.dart - Dialog pilih bank untuk VA
* virtual_account_payment_dialog.dart - Dialog pembayaran Virtual Account

## Aturan

* Widget di folder ini HARUS menerima data melalui constructor
* Widget BOLEH menggunakan controller yang di-pass dari parent
* Widget TIDAK BOLEH berisi business logic (gunakan controller)
* Widget TIDAK BOLEH memanggil Firebase/API langsung

