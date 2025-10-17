import 'package:flutter/material.dart';

// Import future pages (for modularity)
// Example: import 'pages/overview_page.dart';
// We'll add these later as the app grows

void main() {
  runApp(const KiosDarmaApp());
}

class KiosDarmaApp extends StatelessWidget {
  const KiosDarmaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KiosDarma',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        fontFamily: 'Segoe UI',
      ),
      // Routing setup: HomePage is still the default
      initialRoute: '/',
      routes: {
        '/': (context) => const HomePage(),
        // '/catalog': (context) => const CatalogPage(),
        // '/cart': (context) => const CartPage(),
        // '/profile': (context) => const ProfilePage(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        backgroundColor: Colors.indigo,
        elevation: 0,
        title: const Text(
          "KiosDarma",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
  children: [
    Image.asset(
      'assets/images/logo.png',
      height: 50,
      width: 50,
    ),
    SizedBox(width: 10),
    Text(
      'KiosDarma',
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.green[700],
      ),
    ),
  ],
),
SizedBox(height: 20),
            // Greeting
            const Text(
              "Selamat datang kembali, Harits 👋",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),

            // Summary card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(0, 4),
                  )
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Pendapatan Hari Ini",
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      SizedBox(height: 6),
                      Text(
                        "Rp 1.250.000",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Icon(Icons.show_chart, color: Colors.white, size: 36),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Feature grid
            const Text(
              "Fitur Utama",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),

            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: const [
                HomeFeature(icon: Icons.point_of_sale, label: "Kasir"),
                HomeFeature(icon: Icons.inventory, label: "Stok Barang"),
                HomeFeature(icon: Icons.receipt_long, label: "Laporan"),
                HomeFeature(icon: Icons.qr_code_scanner, label: "Scan Barcode"),
                HomeFeature(icon: Icons.people, label: "Pelanggan"),
                HomeFeature(icon: Icons.payment, label: "Pembayaran"),
                HomeFeature(icon: Icons.cloud_off, label: "Mode Offline"),
                HomeFeature(icon: Icons.settings, label: "Pengaturan"),
              ],
            ),

            const SizedBox(height: 24),

            // Recent section
            const Text(
              "Ringkasan Hari Ini",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),

            Column(
              children: const [
                SummaryCard(
                  title: "Transaksi Selesai",
                  value: "42",
                  icon: Icons.shopping_bag_outlined,
                  color: Colors.teal,
                ),
                SizedBox(height: 12),
                SummaryCard(
                  title: "Barang Hampir Habis",
                  value: "5 Produk",
                  icon: Icons.warning_amber_rounded,
                  color: Colors.orange,
                ),
                SizedBox(height: 12),
                SummaryCard(
                  title: "Total Pelanggan",
                  value: "120",
                  icon: Icons.people_alt_outlined,
                  color: Colors.blue,
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.indigo,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Beranda"),
          BottomNavigationBarItem(icon: Icon(Icons.store), label: "Produk"),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: "Kasir"),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: "Laporan"),
        ],
      ),
    );
  }
}

class HomeFeature extends StatelessWidget {
  final IconData icon;
  final String label;

  const HomeFeature({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {}, // TODO: add navigation later
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.indigo, size: 28),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const SummaryCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class FeatureCard extends StatelessWidget {
  final String icon;
  final String title;
  final String desc;

  const FeatureCard({
    super.key,
    required this.icon,
    required this.title,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))
        ],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 36)),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            desc,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }
}
