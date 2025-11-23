# Onboarding Widgets

Folder ini berisi widget-widget yang digunakan di halaman onboarding.

## Tujuan

Widget di folder ini digunakan untuk:
* Konten slide onboarding
* Button untuk navigasi
* Skip button
* Page indicators

## File yang Ada

* onboarding_button.dart - Button untuk onboarding
* onboarding_slide_content.dart - Konten untuk slide onboarding
* page_indicators.dart - Indicator untuk halaman
* skip_button.dart - Button untuk skip onboarding

## Aturan

* Widget di folder ini HARUS menerima data melalui constructor
* Widget BOLEH menggunakan controller yang di-pass dari parent
* Widget TIDAK BOLEH berisi business logic (gunakan controller)
* Widget TIDAK BOLEH memanggil Firebase/API langsung

