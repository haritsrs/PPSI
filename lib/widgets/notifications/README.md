# Notification Widgets

Folder ini berisi widget-widget yang digunakan di halaman notifikasi.

## Tujuan

Widget di folder ini digunakan untuk:
* Menampilkan list notifikasi
* Card untuk menampilkan notifikasi
* Filter untuk notifikasi
* Dialog konfirmasi hapus semua
* State untuk empty notifikasi
* AppBar untuk halaman notifikasi

## File yang Ada

* delete_all_confirmation_dialog.dart - Dialog konfirmasi hapus semua notifikasi
* empty_notification_state.dart - State ketika tidak ada notifikasi
* notification_app_bar.dart - AppBar untuk halaman notifikasi
* notification_card.dart - Card untuk menampilkan notifikasi
* notification_filter_section.dart - Section filter notifikasi

## Aturan

* Widget di folder ini HARUS menerima data melalui constructor
* Widget BOLEH menggunakan controller yang di-pass dari parent
* Widget TIDAK BOLEH berisi business logic (gunakan controller)
* Widget TIDAK BOLEH memanggil Firebase/API langsung

