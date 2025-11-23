# Settings Widgets

Folder ini berisi widget-widget yang digunakan di halaman pengaturan.

## Tujuan

Widget di folder ini digunakan untuk:
* Section untuk berbagai kategori pengaturan
* Dialog untuk berbagai konfigurasi
* Dialog untuk memilih printer

## File yang Ada

* business_settings_section.dart - Section untuk pengaturan bisnis
* data_security_settings_section.dart - Section untuk pengaturan keamanan data
* general_settings_section.dart - Section untuk pengaturan umum
* notifications_settings_section.dart - Section untuk pengaturan notifikasi
* printer_selection_dialog.dart - Dialog untuk memilih printer
* printer_settings_section.dart - Section untuk pengaturan printer
* settings_dialogs.dart - Dialog-dialog untuk pengaturan
* support_settings_section.dart - Section untuk support

## Aturan

* Widget di folder ini HARUS menerima data melalui constructor
* Widget BOLEH menggunakan controller yang di-pass dari parent
* Widget TIDAK BOLEH berisi business logic (gunakan controller)
* Widget TIDAK BOLEH memanggil Firebase/API langsung

