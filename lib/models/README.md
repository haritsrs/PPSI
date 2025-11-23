# Models

Folder ini berisi model data yang merepresentasikan struktur data aplikasi.

## Tujuan

Model digunakan untuk:
* Mendefinisikan struktur data dari Firebase/database
* Konversi data dari/to JSON/Firebase
* Menyediakan getter untuk computed properties

## Aturan

### Wajib

* Model HARUS berupa class dengan properties yang jelas
* Model HARUS memiliki factory constructor fromFirebase() atau fromJson()
* Model HARUS memiliki method toFirebase() atau toJson()
* Nama file: [nama]_model.dart (contoh: product_model.dart)
* Nama class: PascalCase (contoh: Product, Customer)

### Dilarang

* Menambahkan business logic kompleks di model
* Menambahkan UI code atau widget
* Menambahkan controller logic
* Membuat model tanpa factory constructor

## Contoh Struktur

```dart
class Product {
  final String id;
  final String name;
  final double price;
  
  Product({required this.id, required this.name, required this.price});
  
  factory Product.fromFirebase(Map<String, dynamic> data) {
    return Product(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
    );
  }
  
  Map<String, dynamic> toFirebase() {
    return {
      'id': id,
      'name': name,
      'price': price,
    };
  }
}
```

## File yang Ada

* cart_item_model.dart - Model untuk item di cart
* customer_model.dart - Model untuk pelanggan
* notification_model.dart - Model untuk notifikasi
* onboarding_slide.dart - Model untuk slide onboarding
* payment_method_model.dart - Model untuk metode pembayaran
* product_model.dart - Model untuk produk
* transaction_model.dart - Model untuk transaksi

