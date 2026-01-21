import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

import 'storage_service.dart';
import '../utils/security_utils.dart';
import '../utils/app_exception.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  
  // Get current user
  static User? get currentUser => _auth.currentUser;
  
  // Auth state changes stream
  static Stream<User?> get authStateChanges => _auth.authStateChanges();
  
  // Sign in with email and password
  static Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    // Rate limiting: prevent brute force attacks
    final rateLimitKey = 'auth_signin_${email.trim().toLowerCase()}';
    if (!RateLimiter.allow(rateLimitKey, interval: const Duration(seconds: 2))) {
      throw const RateLimitException(
        'Terlalu banyak percobaan masuk. Silakan tunggu beberapa saat sebelum mencoba lagi.',
      );
    }
    
    // Validate email format before authentication
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      throw Exception('Format email tidak valid.');
    }
    try {
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );
      return result;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      // Don't expose internal error details to users
      if (e is RateLimitException) rethrow;
      throw Exception('Terjadi kesalahan saat masuk. Silakan coba lagi.');
    }
  }
  
  // Create user with email and password
  static Future<UserCredential?> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    // Rate limiting: prevent rapid account creation
    final rateLimitKey = 'auth_register_${email.trim().toLowerCase()}';
    if (!RateLimiter.allow(rateLimitKey, interval: const Duration(seconds: 5))) {
      throw const RateLimitException(
        'Terlalu banyak percobaan pendaftaran. Silakan tunggu beberapa saat sebelum mencoba lagi.',
      );
    }
    
    // Validate email format before authentication
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      throw Exception('Format email tidak valid.');
    }
    try {
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );
      return result;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      // Don't expose internal error details to users
      if (e is RateLimitException) rethrow;
      throw Exception('Terjadi kesalahan saat masuk. Silakan coba lagi.');
    }
  }
  
  // Sign out
  static Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      // Don't expose internal error details to users
      throw Exception('Gagal keluar. Silakan coba lagi.');
    }
  }
  
  // Send password reset email
  static Future<void> sendPasswordResetEmail(String email) async {
    // Rate limiting: prevent email enumeration and spam
    final rateLimitKey = 'auth_password_reset_${email.trim().toLowerCase()}';
    if (!RateLimiter.allow(rateLimitKey, interval: const Duration(minutes: 1))) {
      throw const RateLimitException(
        'Terlalu banyak permintaan reset password. Silakan tunggu beberapa saat sebelum mencoba lagi.',
      );
    }
    
    // Validate email format before sending reset email
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      throw Exception('Format email tidak valid.');
    }
    try {
      await _auth.sendPasswordResetEmail(email: email.trim().toLowerCase());
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      // Don't expose internal error details to users
      if (e is RateLimitException) rethrow;
      throw Exception('Terjadi kesalahan saat masuk. Silakan coba lagi.');
    }
  }
  
  // Update user profile
  static Future<void> updateUserProfile({
    String? displayName,
    String? photoURL,
    bool deletePhoto = false,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        if (displayName != null) {
          await user.updateDisplayName(displayName);
        }
        if (deletePhoto) {
          await user.updatePhotoURL(null);
        } else if (photoURL != null) {
          await user.updatePhotoURL(photoURL);
        }
        await user.reload();
      }
    } catch (e) {
      // Don't expose internal error details to users
      throw Exception('Gagal memperbarui profil. Silakan coba lagi.');
    }
  }
  
  // Upload profile picture to Firebase Storage with automatic optimization
  static Future<String> uploadProfilePicture(File imageFile) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }
      
      // Optimize image (converts to JPEG, resizes to max 800px width, quality 80)
      final optimizedFile = await StorageService.optimizeImage(imageFile);
      
      // Create a reference to the location you want to upload to in Firebase Storage
      // Always use .jpg extension since we convert to JPEG
      final ref = _storage.ref().child('profile_pictures/${user.uid}.jpg');
      
      // Upload the optimized file to Firebase Storage
      await ref.putFile(optimizedFile);
      
      // Get the download URL
      final downloadURL = await ref.getDownloadURL();
      
      // Clean up optimized file
      try {
        await optimizedFile.delete();
      } catch (e) {
        // Ignore cleanup errors
      }
      
      return downloadURL;
    } catch (e) {
      // Don't expose internal error details to users
      throw Exception('Gagal mengupload foto profil. Silakan coba lagi.');
    }
  }
  
  // Change password
  static Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }
      
      // Re-authenticate user with current password
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      
      // Update password
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      // Don't expose internal error details to users
      throw Exception('Gagal mengubah password. Silakan coba lagi.');
    }
  }
  
  // Send email verification
  static Future<void> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }
      await user.sendEmailVerification();
    } catch (e) {
      // Don't expose internal error details to users
      throw Exception('Gagal mengirim email verifikasi. Silakan coba lagi.');
    }
  }
  
  // Reload user to get latest data
  static Future<void> reloadUser() async {
    try {
      await _auth.currentUser?.reload();
    } catch (e) {
      // Don't expose internal error details to users
      throw Exception('Gagal memuat ulang data user. Silakan coba lagi.');
    }
  }

  // Delete user account
  static Future<void> deleteAccount(String password) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Re-authenticate user before deletion (security requirement)
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);

      // Delete the user account
      await user.delete();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      // Don't expose internal error details to users
      throw Exception('Gagal menghapus akun. Silakan coba lagi.');
    }
  }
  
  // Get user display name
  static String getUserDisplayName(User? user) {
    if (user == null) {
      return 'Pengguna';
    }
    if (user.displayName != null && user.displayName!.isNotEmpty) {
      return user.displayName!;
    }
    if (user.email != null) {
      return user.email!.split('@')[0];
    }
    return 'Pengguna';
  }
  
  // Handle Firebase Auth exceptions
  static String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Pengguna tidak ditemukan. Periksa email Anda.';
      case 'wrong-password':
        return 'Password salah. Silakan coba lagi.';
      case 'email-already-in-use':
        return 'Email sudah digunakan. Silakan gunakan email lain.';
      case 'weak-password':
        return 'Password terlalu lemah. Gunakan minimal 8 karakter dengan kombinasi huruf dan angka.';
      case 'invalid-email':
        return 'Format email tidak valid.';
      case 'user-disabled':
        return 'Akun ini telah dinonaktifkan.';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan. Silakan coba lagi nanti.';
      case 'operation-not-allowed':
        return 'Operasi tidak diizinkan.';
      case 'invalid-credential':
        return 'Kredensial tidak valid.';
      case 'network-request-failed':
        return 'Koneksi internet bermasalah. Periksa koneksi Anda.';
      default:
        // Don't expose internal error message details
        return 'Terjadi kesalahan autentikasi. Silakan coba lagi.';
    }
  }
}

