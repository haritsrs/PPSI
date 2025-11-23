# Home Widgets

Folder ini berisi widget-widget yang digunakan di halaman home.

## Tujuan

Widget di folder ini digunakan untuk:
* Banner carousel
* Bottom navigation bar
* Business menu
* Custom app bar
* Drawer untuk navigasi
* Content utama home
* Layout untuk landscape/tablet
* News section
* Profile header
* Summary card

## File yang Ada

* banner_carousel.dart - Carousel untuk banner
* bottom_nav_bar.dart - Bottom navigation bar
* business_menu.dart - Menu bisnis
* custom_app_bar.dart - Custom app bar untuk home
* drawer_item.dart - Item untuk drawer
* home_content.dart - Konten utama halaman home
* home_drawer.dart - Drawer untuk navigasi
* home_landscape_layout.dart - Layout untuk landscape/tablet
* news_section.dart - Section berita
* notification_rail_destination.dart - Destination untuk notification rail
* profile_header.dart - Header dengan profil user
* summary_card.dart - Card summary

## Aturan

* Widget di folder ini HARUS menerima data melalui constructor
* Widget BOLEH menggunakan controller yang di-pass dari parent
* Widget TIDAK BOLEH berisi business logic (gunakan controller)
* Widget TIDAK BOLEH memanggil Firebase/API langsung

