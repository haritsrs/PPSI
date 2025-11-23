# Product Dialogs

Subfolder ini berisi dialog-dialog khusus untuk produk.

## Tujuan

Dialog di folder ini digunakan untuk:
* Menambah dan mengedit produk
* Update stock produk (single dan bulk)
* Melihat history stock

## File yang Ada

* add_edit_product_dialog.dart - Dialog untuk menambah atau mengedit produk
* bulk_stock_update_dialog.dart - Dialog untuk update stock banyak produk sekaligus
* edit_stock_dialog.dart - Dialog untuk mengedit stock satu produk
* stock_history_dialog.dart - Dialog untuk melihat history perubahan stock

## Aturan

* Dialog HARUS menerima data melalui constructor
* Dialog BOLEH menggunakan controller yang di-pass dari parent
* Dialog TIDAK BOLEH berisi business logic (gunakan controller)
* Dialog TIDAK BOLEH memanggil Firebase/API langsung

