import 'package:flutter/material.dart';

class DownloadSuccessDialog extends StatelessWidget {
  final String filePath;
  final String fileName;
  final String fileType;
  final VoidCallback onShare;

  const DownloadSuccessDialog({
    super.key,
    required this.filePath,
    required this.fileName,
    required this.fileType,
    required this.onShare,
  });

  static void show({
    required BuildContext context,
    required String filePath,
    required String fileName,
    required String fileType,
    required VoidCallback onShare,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return DownloadSuccessDialog(
          filePath: filePath,
          fileName: fileName,
          fileType: fileType,
          onShare: onShare,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.check_circle_rounded, color: Colors.green[600], size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'File Berhasil Disimpan',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'File $fileType telah disimpan ke:',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: SelectableText(
              filePath,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Anda dapat menemukan file ini di folder Documents aplikasi.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Tutup'),
        ),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.of(context).pop();
            onShare();
          },
          icon: const Icon(Icons.share_rounded, size: 18),
          label: const Text('Bagikan'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}


