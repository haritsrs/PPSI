import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

import '../utils/error_helper.dart';

class StorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload product image to Firebase Storage with automatic optimization
  /// Returns the download URL
  static Future<String> uploadProductImage({
    required File imageFile,
    required String productId,
  }) async {
    try {
      // Validate productId to prevent path injection
      if (productId.isEmpty || !RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(productId)) {
        throw Exception('Invalid product ID format');
      }
      
      // Optimize image (converts to JPEG, resizes to max 800px width, quality 80)
      final optimizedFile = await optimizeImage(imageFile);
      
      // Create unique filename (always .jpg since we convert to JPEG)
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'products/$productId/${timestamp}.jpg';
      
      // Upload to Firebase Storage
      final ref = _storage.ref().child(fileName);
      final uploadTask = ref.putFile(optimizedFile);
      
      // Wait for upload to complete
      final snapshot = await uploadTask;
      
      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      // Clean up optimized file
      try {
        await optimizedFile.delete();
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

  /// Optimize image for Firebase Storage upload
  /// 
  /// This function:
  /// - Accepts JPEG, PNG, and HEIC images
  /// - Converts all images to JPEG format
  /// - Resizes to maximum width of 800px while preserving aspect ratio
  /// - Applies compression with quality 80
  /// - Returns optimized JPEG file
  /// - Handles processing errors gracefully
  /// 
  /// Returns the optimized image file as JPEG
  static Future<File> optimizeImage(File imageFile) async {
    try {
      // Validate file exists
      if (!await imageFile.exists()) {
        throw Exception('Image file does not exist');
      }

      // Get temporary directory for output
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final targetPath = '${tempDir.path}/optimized_${timestamp}.jpg';
      
      // Compress and optimize image
      // minWidth: 800 means resize to max 800px width (preserves aspect ratio)
      // minHeight: 0 means no height constraint (aspect ratio preserved)
      // format: jpeg converts all formats (JPEG, PNG, HEIC) to JPEG
      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        imageFile.absolute.path,
        targetPath,
        quality: 80, // Quality 80 as specified
        minWidth: 800, // Maximum width 800px
        minHeight: 0, // No height constraint, preserves aspect ratio
        format: CompressFormat.jpeg, // Always convert to JPEG
        keepExif: false, // Remove EXIF data to reduce file size
      );
      
      if (compressedFile == null) {
        throw Exception('Image optimization failed: compression returned null');
      }
      
      final optimizedFile = File(compressedFile.path);
      
      // Validate optimized file exists
      if (!await optimizedFile.exists()) {
        throw Exception('Optimized image file was not created');
      }
      
      return optimizedFile;
    } catch (e) {
      // Log error for debugging (use debugPrint to avoid logging in production)
      debugPrint('Image optimization error: $e');
      
      // If optimization fails, try to convert original to JPEG as fallback
      try {
        final tempDir = await getTemporaryDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fallbackPath = '${tempDir.path}/fallback_${timestamp}.jpg';
        
        final fallbackFile = await FlutterImageCompress.compressAndGetFile(
          imageFile.absolute.path,
          fallbackPath,
          quality: 80,
          format: CompressFormat.jpeg,
        );
        
        if (fallbackFile != null) {
          return File(fallbackFile.path);
        }
      } catch (fallbackError) {
        debugPrint('Fallback conversion also failed: $fallbackError');
      }
      
      // If all else fails, throw the original error
      throw Exception('Failed to optimize image: $e');
    }
  }

  /// Get file size in MB
  static double getFileSizeInMB(File file) {
    final bytes = file.lengthSync();
    return bytes / (1024 * 1024);
  }

  /// Upload custom QR code to Firebase Storage with automatic optimization
  /// Returns the download URL
  static Future<String> uploadCustomQRCode({
    required File imageFile,
    required String userId,
  }) async {
    try {
      // Validate userId to prevent path injection
      if (userId.isEmpty || !RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(userId)) {
        throw Exception('Invalid user ID format');
      }
      
      // Optimize image (converts to JPEG, resizes to max 800px width, quality 80)
      final optimizedFile = await optimizeImage(imageFile);
      
      // Create filename (always .jpg since we convert to JPEG)
      final fileName = 'custom_qr_codes/$userId.jpg';
      
      // Upload to Firebase Storage
      final ref = _storage.ref().child(fileName);
      final uploadTask = ref.putFile(optimizedFile);
      
      // Wait for upload to complete
      final snapshot = await uploadTask;
      
      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      // Clean up optimized file
      try {
        await optimizedFile.delete();
      } catch (e) {
        // Ignore cleanup errors
      }
      
      return downloadUrl;
    } catch (error) {
      throw toAppException(
        error,
        fallbackMessage: 'Gagal mengunggah QR code.',
      );
    }
  }

  /// Delete custom QR code from Firebase Storage
  static Future<void> deleteCustomQRCode(String imageUrl) async {
    try {
      // Extract file path from URL
      if (imageUrl.isEmpty) {
        return;
      }
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (error) {
      throw toAppException(
        error,
        fallbackMessage: 'Gagal menghapus QR code.',
      );
    }
  }

  /// Upload profile picture to Firebase Storage with automatic optimization
  /// Returns the download URL
  static Future<String> uploadProfilePicture({
    required File imageFile,
    required String userId,
  }) async {
    try {
      // Validate userId to prevent path injection
      if (userId.isEmpty || !RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(userId)) {
        throw Exception('Invalid user ID format');
      }
      
      // Optimize image (converts to JPEG, resizes to max 800px width, quality 80)
      final optimizedFile = await optimizeImage(imageFile);
      
      // Create filename (always .jpg since we convert to JPEG)
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'profile_pictures/$userId/${timestamp}.jpg';
      
      // Upload to Firebase Storage
      final ref = _storage.ref().child(fileName);
      final uploadTask = ref.putFile(optimizedFile);
      
      // Wait for upload to complete
      final snapshot = await uploadTask;
      
      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      // Clean up optimized file
      try {
        await optimizedFile.delete();
      } catch (e) {
        // Ignore cleanup errors
      }
      
      return downloadUrl;
    } catch (error) {
      throw toAppException(
        error,
        fallbackMessage: 'Gagal mengunggah foto profil.',
      );
    }
  }

  /// Delete profile picture from Firebase Storage
  static Future<void> deleteProfilePicture(String userId) async {
    try {
      if (userId.isEmpty) {
        return;
      }
      
      // Delete entire profile pictures folder for user
      final ref = _storage.ref().child('profile_pictures/$userId');
      final listResult = await ref.listAll();
      
      for (final item in listResult.items) {
        await item.delete();
      }
    } catch (error) {
      throw toAppException(
        error,
        fallbackMessage: 'Gagal menghapus foto profil.',
      );
    }
  }
}