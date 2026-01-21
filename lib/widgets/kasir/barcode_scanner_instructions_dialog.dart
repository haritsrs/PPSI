import 'package:flutter/material.dart';
import '../../utils/responsive_helper.dart';

class BarcodeScannerInstructionsDialog extends StatelessWidget {
  const BarcodeScannerInstructionsDialog({super.key});

  static Future<T?> show<T>(BuildContext context) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const BarcodeScannerInstructionsDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fontScale = ResponsiveHelper.getFontScale(context);
    final paddingScale = ResponsiveHelper.getPaddingScale(context);
    final iconScale = ResponsiveHelper.getIconScale(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: EdgeInsets.only(top: 12 * paddingScale),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: EdgeInsets.all(24 * paddingScale),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12 * paddingScale),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.qr_code_scanner_rounded,
                    color: const Color(0xFF6366F1),
                    size: 28 * iconScale,
                  ),
                ),
                SizedBox(width: 16 * paddingScale),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Cara Menggunakan Kasir",
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: const Color(0xFF1F2937),
                              fontWeight: FontWeight.w700,
                              fontSize:
                                  (Theme.of(context).textTheme.titleLarge?.fontSize ?? 22) * fontScale,
                            ),
                      ),
                      SizedBox(height: 4 * paddingScale),
                      Text(
                        "Panduan lengkap penggunaan aplikasi kasir",
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF9CA3AF),
                              fontSize:
                                  (Theme.of(context).textTheme.bodySmall?.fontSize ?? 12) * fontScale,
                            ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: Colors.grey[200]),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24 * paddingScale),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInstructionStep(
                    context,
                    step: 1,
                    title: "Menambahkan Produk ke Keranjang",
                    description: "Klik produk di daftar untuk menambahkannya ke keranjang, atau gunakan barcode scanner untuk scan produk secara otomatis.",
                    icon: Icons.shopping_cart_rounded,
                    paddingScale: paddingScale,
                    fontSize: fontScale,
                    iconScale: iconScale,
                  ),
                  SizedBox(height: 16 * paddingScale),
                  _buildInstructionStep(
                    context,
                    step: 2,
                    title: "Menggunakan Barcode Scanner",
                    description: "Pastikan tombol scanner aktif (ikon hijau di pojok kanan atas). Scan barcode produk dan produk akan otomatis ditambahkan ke keranjang. Tidak perlu klik - scanner selalu siap.",
                    icon: Icons.qr_code_scanner_rounded,
                    paddingScale: paddingScale,
                    fontSize: fontScale,
                    iconScale: iconScale,
                  ),
                  SizedBox(height: 16 * paddingScale),
                  _buildInstructionStep(
                    context,
                    step: 3,
                    title: "Melihat Keranjang",
                    description: "Klik ikon keranjang di pojok kanan bawah untuk melihat item di keranjang, mengubah jumlah, atau menghapus item.",
                    icon: Icons.shopping_bag_rounded,
                    paddingScale: paddingScale,
                    fontSize: fontScale,
                    iconScale: iconScale,
                  ),
                  SizedBox(height: 16 * paddingScale),
                  _buildInstructionStep(
                    context,
                    step: 4,
                    title: "Checkout & Pembayaran",
                    description: "Setelah semua item ditambahkan, klik tombol 'Checkout' di keranjang. Pilih metode pembayaran (Tunai, QRIS, atau Virtual Account), masukkan jumlah uang jika tunai, lalu proses pembayaran.",
                    icon: Icons.payment_rounded,
                    paddingScale: paddingScale,
                    fontSize: fontScale,
                    iconScale: iconScale,
                  ),
                  SizedBox(height: 16 * paddingScale),
                  _buildInstructionStep(
                    context,
                    step: 5,
                    title: "Cetak Struk",
                    description: "Setelah pembayaran berhasil, klik tombol 'Cetak Struk' untuk mencetak struk transaksi ke printer thermal atau PDF.",
                    icon: Icons.print_rounded,
                    paddingScale: paddingScale,
                    fontSize: fontScale,
                    iconScale: iconScale,
                  ),
                  SizedBox(height: 24 * paddingScale),
                  Container(
                    padding: EdgeInsets.all(16 * paddingScale),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.withOpacity(0.3), width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.lightbulb_outline_rounded, color: Colors.blue[700], size: 20 * iconScale),
                            SizedBox(width: 8 * paddingScale),
                            Text(
                              "Tips",
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue[700],
                                    fontSize: (Theme.of(context).textTheme.titleMedium?.fontSize ?? 16) * fontScale,
                                  ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8 * paddingScale),
                        Text(
                          "• Tombol (?) - Buka panduan ini\n• Tombol (+) - Tambah produk baru\n• Tombol Scanner (ikon QR) - Aktifkan/nonaktifkan barcode scanner\n• Scanner akan otomatis siap setelah diaktifkan - tidak perlu klik manual\n• Gunakan kotak pencarian untuk mencari produk berdasarkan nama\n• Filter kategori di atas untuk menyaring produk\n• Pastikan produk memiliki barcode yang terdaftar untuk bisa discan",
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.blue[900],
                                fontSize: (Theme.of(context).textTheme.bodyMedium?.fontSize ?? 14) * fontScale,
                                height: 1.5,
                              ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24 * paddingScale),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionStep(
    BuildContext context, {
    required int step,
    required String title,
    required String description,
    required IconData icon,
    required double paddingScale,
    required double fontSize,
    required double iconScale,
  }) {
    return Container(
      padding: EdgeInsets.all(16 * paddingScale),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40 * paddingScale,
            height: 40 * paddingScale,
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20 * paddingScale),
            ),
            child: Center(
              child: Text(
                '$step',
                style: TextStyle(
                  color: const Color(0xFF6366F1),
                  fontWeight: FontWeight.w700,
                  fontSize: 16 * fontSize,
                ),
              ),
            ),
          ),
          SizedBox(width: 12 * paddingScale),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      icon,
                      color: const Color(0xFF6366F1),
                      size: 18 * iconScale,
                    ),
                    SizedBox(width: 6 * paddingScale),
                    Flexible(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1F2937),
                              fontSize: (Theme.of(context).textTheme.titleSmall?.fontSize ?? 14) * fontSize,
                            ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4 * paddingScale),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                        fontSize: (Theme.of(context).textTheme.bodyMedium?.fontSize ?? 14) * fontSize,
                        height: 1.4,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


