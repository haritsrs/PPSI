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
                        "Cara Menggunakan Barcode Scanner",
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: const Color(0xFF1F2937),
                              fontWeight: FontWeight.w700,
                              fontSize:
                                  (Theme.of(context).textTheme.titleLarge?.fontSize ?? 22) * fontScale,
                            ),
                      ),
                      SizedBox(height: 4 * paddingScale),
                      Text(
                        "Panduan lengkap penggunaan scanner",
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
                    title: "Siapkan Barcode Scanner",
                    description: "Pastikan barcode scanner (barcode gun) sudah terhubung ke perangkat Anda melalui USB atau Bluetooth.",
                    icon: Icons.usb_rounded,
                    paddingScale: paddingScale,
                    fontSize: fontScale,
                    iconScale: iconScale,
                  ),
                  SizedBox(height: 16 * paddingScale),
                  _buildInstructionStep(
                    context,
                    step: 2,
                    title: "Aktifkan Mode Scanner",
                    description: "Tekan tombol pada barcode scanner untuk mengaktifkan mode scanning. Lampu indikator akan menyala.",
                    icon: Icons.power_settings_new_rounded,
                    paddingScale: paddingScale,
                    fontSize: fontScale,
                    iconScale: iconScale,
                  ),
                  SizedBox(height: 16 * paddingScale),
                  _buildInstructionStep(
                    context,
                    step: 3,
                    title: "Arahkan ke Barcode Produk",
                    description: "Arahkan sinar laser dari scanner ke barcode produk. Pastikan barcode terlihat jelas dan tidak terhalang.",
                    icon: Icons.center_focus_strong_rounded,
                    paddingScale: paddingScale,
                    fontSize: fontScale,
                    iconScale: iconScale,
                  ),
                  SizedBox(height: 16 * paddingScale),
                  _buildInstructionStep(
                    context,
                    step: 4,
                    title: "Scan Barcode",
                    description: "Tekan tombol trigger pada scanner atau biarkan scanner membaca barcode secara otomatis. Produk akan otomatis ditambahkan ke keranjang.",
                    icon: Icons.qr_code_scanner_rounded,
                    paddingScale: paddingScale,
                    fontSize: fontScale,
                    iconScale: iconScale,
                  ),
                  SizedBox(height: 16 * paddingScale),
                  _buildInstructionStep(
                    context,
                    step: 5,
                    title: "Lanjutkan Scanning",
                    description: "Setelah produk ditambahkan, scanner siap untuk scan produk berikutnya. Tidak perlu klik atau fokus manual - scanner selalu siap.",
                    icon: Icons.repeat_rounded,
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
                          "• Pastikan produk sudah memiliki barcode yang terdaftar di sistem\n• Jika produk tidak ditemukan, pastikan barcode sudah ditambahkan saat membuat produk\n• Scanner akan otomatis fokus kembali setelah setiap scan\n• Untuk menghapus item dari keranjang, gunakan tombol hapus pada item tersebut",
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

