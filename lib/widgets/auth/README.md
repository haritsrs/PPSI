# Auth Widgets

Folder ini berisi widget-widget yang digunakan untuk autentikasi (login dan register).

## Tujuan

Widget di folder ini digunakan untuk:
* Form field untuk input autentikasi
* Button untuk submit form
* Header dan footer untuk halaman auth
* Checkbox untuk terms and conditions
* Row untuk remember me dan forgot password

## File yang Ada

* auth_button.dart - Button untuk submit form auth
* auth_divider.dart - Divider untuk memisahkan section
* auth_footer.dart - Footer dengan link ke halaman lain
* auth_form_container.dart - Container untuk form auth
* auth_form_field.dart - Form field khusus untuk auth
* back_button_app_bar.dart - AppBar dengan tombol back
* confirmation_content.dart - Konten untuk konfirmasi
* info_card.dart - Card untuk menampilkan informasi
* login_header.dart - Header untuk halaman login
* remember_me_forgot_password_row.dart - Row untuk remember me dan forgot password
* terms_and_conditions_checkbox.dart - Checkbox untuk terms and conditions

## Aturan

* Widget di folder ini HARUS menerima callback melalui constructor
* Widget BOLEH menggunakan controller yang di-pass dari parent
* Widget TIDAK BOLEH berisi business logic (gunakan controller)
* Widget TIDAK BOLEH memanggil Firebase/API langsung

