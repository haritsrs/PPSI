# Account Widgets

Folder ini berisi widget-widget yang digunakan di halaman account.

## Tujuan

Widget di folder ini digunakan untuk:
* Menampilkan informasi profil user
* Form untuk mengubah informasi account
* Dialog untuk perubahan password
* Dialog untuk verifikasi email
* Picker untuk foto profil

## File yang Ada

* account_action_tile.dart - Tile untuk aksi account
* account_actions_section.dart - Section berisi semua aksi account
* account_info_form.dart - Form untuk informasi account
* change_password_dialog.dart - Dialog untuk mengubah password
* image_picker_dialog.dart - Dialog untuk memilih gambar
* profile_header_section.dart - Header section dengan foto profil dan nama
* verification_dialog.dart - Dialog untuk verifikasi email

## Aturan

* Widget di folder ini HARUS menerima data melalui constructor
* Widget BOLEH menggunakan controller yang di-pass dari parent
* Widget TIDAK BOLEH berisi business logic (gunakan controller)
* Widget TIDAK BOLEH memanggil Firebase/API langsung

