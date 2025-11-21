import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

import '../utils/error_helper.dart';

class StorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload product image to Firebase Storage with compression
  /// Returns the download URL
  static Future<String> uploadProductImage({
    required File imageFile,
    required String productId,
  }) async {
    try {
      // Compress image
      final compressedFile = await _compressImage(imageFile);
      
      // Create unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = imageFile.path.split('.').last;
      final fileName = 'products/$productId/${timestamp}.$extension';
      
      // Upload to Firebase Storage
      final ref = _storage.ref().child(fileName);
      final uploadTask = ref.putFile(compressedFile);
      
      // Wait for upload to complete
      final snapshot = await uploadTask;
      
      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      // Clean up compressed file
      try {
        await compressedFile.delete();
      } catch (e) {
        // Ignore cleanup errors
      }
      
      return downloadUrl;
    } catch (error) {
      throw toAppException(
        error,
        fallbackMessage: 'Gagal mengunggah gambar.',
      );
    }
  }

  /// Delete product image from Firebase Storage
  static Future<void> deleteProductImage(String imageUrl) async {
    try {
      // Extract file path from URL
      final ref = _storage.refFromURL(imageUrl);
      if (imageUrl.isEmpty) {
        return;
      }
      
      await ref.delete();
    } catch (error) {
      throw toAppException(
        error,
        fallbackMessage: 'Gagal menghapus gambar produk.',
      );
    }
  }

  /// Compress image to reduce file size
  static Future<File> _compressImage(File imageFile) async {
    try {
      // Get temporary directory
      final tempDir = await getTemporaryDirectory();
      final targetPath = '${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      // Compress image
      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        imageFile.absolute.path,
        targetPath,
        quality: 85, // Quality 0-100, 85 is a good balance
        minWidth: 1024, // Max width
        minHeight: 1024, // Max height
        format: CompressFormat.jpeg,
      );
      
      if (compressedFile == null) {
        throw Exception('Image compression failed');
      }
      
      return File(compressedFile.path);
    } catch (e) {
      // If compression fails, return original file
      print('Compression error: $e, using original file');
      return imageFile;
    }
  }

  /// Get file size in MB
  static double getFileSizeInMB(File file) {
    final bytes = file.lengthSync();
    return bytes / (1024 * 1024);
  }
}

